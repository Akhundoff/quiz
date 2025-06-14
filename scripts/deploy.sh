#!/bin/bash

# Quiz System Production Deployment Script
# Bu script production mühitində deployment edir

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOYMENT_LOG="$PROJECT_ROOT/logs/deployment_$(date +%Y%m%d_%H%M%S).log"

# Functions
print_header() {
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}   Quiz System - Deploy Script       ${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}📋 $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$DEPLOYMENT_LOG"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$DEPLOYMENT_LOG"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$DEPLOYMENT_LOG"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$DEPLOYMENT_LOG"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$DEPLOYMENT_LOG"
}

# Show usage
show_usage() {
    echo "Quiz System Production Deployment Script"
    echo ""
    echo "İstifadə: ./scripts/deploy.sh [options]"
    echo ""
    echo "Parametrlər:"
    echo "  --skip-backup   Pre-deployment backup yaratma"
    echo "  --skip-tests    Deployment tests keç"
    echo "  --force         Təsdiq olmadan deploy et"
    echo "  --help          Bu kömək məlumatını göstər"
    echo ""
    echo "Nümunələr:"
    echo "  ./scripts/deploy.sh                    # Normal deployment"
    echo "  ./scripts/deploy.sh --skip-backup     # Backup olmadan"
    echo "  ./scripts/deploy.sh --force           # Təsdiq olmadan"
    echo ""
}

# Pre-deployment checks
pre_deployment_checks() {
    print_step "Pre-deployment yoxlamalar..."

    # Check if we're in production environment
    if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
        print_error ".env faylı tapılmadı!"
        exit 1
    fi

    source "$PROJECT_ROOT/.env"

    if [[ "$NODE_ENV" != "production" ]]; then
        print_warning "NODE_ENV production deyil: $NODE_ENV"
        if [[ "$FORCE_DEPLOY" != true ]]; then
            read -p "Davam etmək istəyirsiniz? (y/N): " confirm
            [[ "$confirm" != "y" ]] && exit 1
        fi
    fi

    # Check required commands
    command -v docker >/dev/null 2>&1 || { print_error "Docker tapılmadı!"; exit 1; }
    command -v docker-compose >/dev/null 2>&1 || { print_error "Docker Compose tapılmadı!"; exit 1; }
    command -v git >/dev/null 2>&1 || { print_error "Git tapılmadı!"; exit 1; }
    command -v curl >/dev/null 2>&1 || { print_error "curl tapılmadı!"; exit 1; }

    # Check disk space (minimum 2GB free)
    AVAILABLE_SPACE=$(df "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    if [[ $AVAILABLE_SPACE -lt 2097152 ]]; then  # 2GB in KB
        print_error "Kifayət qədər disk sahəsi yoxdur! (minimum 2GB lazımdır)"
        exit 1
    fi

    # Check if git repo is clean
    if ! git diff --quiet; then
        print_warning "Git repository-də commit edilməmiş dəyişikliklər var"
        if [[ "$FORCE_DEPLOY" != true ]]; then
            read -p "Davam etmək istəyirsiniz? (y/N): " confirm
            [[ "$confirm" != "y" ]] && exit 1
        fi
    fi

    print_success "Pre-deployment yoxlamalar tamamlandı"
}

# Create backup before deployment
create_pre_deployment_backup() {
    print_step "Deployment əvvəli backup yaradılır..."

    if [[ -f "$PROJECT_ROOT/scripts/backup.sh" ]]; then
        if "$PROJECT_ROOT/scripts/backup.sh" --full; then
            print_success "Pre-deployment backup yaradıldı"
        else
            print_error "Backup yaradılarkən xəta baş verdi!"
            if [[ "$FORCE_DEPLOY" != true ]]; then
                exit 1
            fi
        fi
    else
        print_warning "Backup script tapılmadı, backup yaradılmadı"
    fi
}

# Update source code
update_source_code() {
    print_step "Source code yenilənir..."

    # Get current branch
    CURRENT_BRANCH=$(git branch --show-current)
    print_info "Current branch: $CURRENT_BRANCH"

    # Stash any local changes
    if ! git diff --quiet; then
        print_warning "Local dəyişikliklər tapıldı, stash edilir..."
        git stash push -m "Pre-deployment stash $(date)"
    fi

    # Pull latest changes
    print_info "Git remote-dan yenilik çəkilir..."
    git fetch origin
    git pull origin "$CURRENT_BRANCH"

    # Show latest commit
    LATEST_COMMIT=$(git log -1 --pretty=format:"%h - %s (%cr) <%an>")
    print_info "Latest commit: $LATEST_COMMIT"

    print_success "Source code yeniləndi"
}

# Check docker-compose files
check_compose_files() {
    print_step "Docker compose faylları yoxlanılır..."

    if [[ ! -f "$PROJECT_ROOT/docker-compose.prod.yaml" ]]; then
        print_error "docker-compose.prod.yaml faylı tapılmadı!"
        exit 1
    fi

    # Validate compose file
    if ! docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" config >/dev/null 2>&1; then
        print_error "docker-compose.prod.yaml faylında xəta var!"
        exit 1
    fi

    print_success "Docker compose faylları düzgündür"
}

# Build and deploy containers
build_and_deploy() {
    print_step "Production containers build edilir..."

    # Stop existing containers
    if docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" ps -q 2>/dev/null | grep -q .; then
        print_info "Mövcud containers dayandırılır..."
        docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" down --timeout 30
    fi

    # Pull latest base images
    print_info "Base image-lər yenilənir..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" pull --ignore-pull-failures || true

    # Build new images
    print_info "Containers build edilir..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" build --no-cache --pull

    # Start new containers
    print_info "Containers başladılır..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" up -d

    print_success "Production containers deploy edildi"
}

# Wait for services to be healthy
wait_for_services() {
    print_step "Servicelərın hazır olmasını gözləyir..."

    # Load environment variables
    source "$PROJECT_ROOT/.env"

    # Wait for MySQL
    print_info "MySQL gözlənilir..."
    local max_attempts=60
    local attempt=0

    while [[ $attempt -lt $max_attempts ]]; do
        attempt=$((attempt + 1))

        if docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" exec -T mysql mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" >/dev/null 2>&1; then
            print_success "MySQL hazırdır"
            break
        fi

        if [[ $attempt -eq $max_attempts ]]; then
            print_error "MySQL hazır olmadı!"
            return 1
        fi

        echo -n "."
        sleep 2
    done

    # Wait a bit more for backend to start
    print_info "Backend gözlənilir..."
    sleep 15

    # Check backend health
    attempt=0
    while [[ $attempt -lt 30 ]]; do
        attempt=$((attempt + 1))

        if curl -f "http://localhost:3001/api/quiz/questions" >/dev/null 2>&1; then
            print_success "Backend hazırdır"
            break
        fi

        if [[ $attempt -eq 30 ]]; then
            print_error "Backend hazır olmadı!"
            return 1
        fi

        echo -n "."
        sleep 2
    done

    # Check frontend health
    print_info "Frontend gözlənilir..."
    attempt=0
    while [[ $attempt -lt 20 ]]; do
        attempt=$((attempt + 1))

        if curl -f "http://localhost:3000/health" >/dev/null 2>&1; then
            print_success "Frontend hazırdır"
            break
        fi

        if [[ $attempt -eq 20 ]]; then
            print_error "Frontend hazır olmadı!"
            return 1
        fi

        echo -n "."
        sleep 2
    done

    print_success "Bütün servicelər hazırdır"
}

# Run database migrations
run_migrations() {
    print_step "Database migrations işə salınır..."

    # Check if backend container is running
    if ! docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" ps backend | grep -q "Up"; then
        print_warning "Backend container işləmir, migration keçilir"
        return 0
    fi

    # Check if backend has migration commands
    if docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" exec -T backend sh -c "npm run migration:run" >/dev/null 2>&1; then
        print_success "Database migrations tamamlandı"
    else
        print_info "Migration komandası tapılmadı və ya artıq tətbiq edilib"
    fi
}

# Verify deployment
verify_deployment() {
    print_step "Deployment yoxlanılır..."

    # Load environment variables
    source "$PROJECT_ROOT/.env"

    # Test endpoints
    local errors=0

    # Test frontend
    print_info "Frontend test edilir..."
    if ! curl -f "http://localhost:3000/health" >/dev/null 2>&1; then
        print_error "Frontend health check uğursuz"
        errors=$((errors + 1))
    else
        print_success "Frontend sağlamdır"
    fi

    # Test backend API
    print_info "Backend API test edilir..."
    if ! curl -f "http://localhost:3001/api/quiz/questions" >/dev/null 2>&1; then
        print_error "Backend API health check uğursuz"
        errors=$((errors + 1))
    else
        print_success "Backend API sağlamdır"
    fi

    # Test database connection
    print_info "Database bağlantısı test edilir..."
    if ! docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" exec -T mysql mysqladmin ping -h localhost -u "$DB_USERNAME" -p"$DB_PASSWORD" >/dev/null 2>&1; then
        print_error "Database connection uğursuz"
        errors=$((errors + 1))
    else
        print_success "Database bağlantısı sağlamdır"
    fi

    # Test phpMyAdmin
    print_info "phpMyAdmin test edilir..."
    if ! curl -f "http://localhost:8082/" >/dev/null 2>&1; then
        print_warning "phpMyAdmin health check uğursuz (kritik deyil)"
    else
        print_success "phpMyAdmin sağlamdır"
    fi

    # Test API endpoints
    print_info "API endpoints test edilir..."
    local api_endpoints=(
        "http://localhost:3001/api/quiz/questions"
        "http://localhost:3001/api/docs"
    )

    for endpoint in "${api_endpoints[@]}"; do
        if curl -f "$endpoint" >/dev/null 2>&1; then
            print_success "✓ $endpoint"
        else
            print_warning "✗ $endpoint"
        fi
    done

    if [[ $errors -eq 0 ]]; then
        print_success "Deployment verification tamamlandı"
        return 0
    else
        print_error "Deployment verification uğursuz ($errors xəta)"
        return 1
    fi
}

# Setup SSL certificates (if needed)
setup_ssl() {
    print_step "SSL sertifikatları yoxlanılır..."

    # Load environment variables
    source "$PROJECT_ROOT/.env"

    if [[ "$PROTOCOL" == "https" ]]; then
        # Check if SSL certificates exist
        local ssl_cert="/home/admin/conf/web/ssl.${DOMAIN_NAME}.pem"
        local ssl_key="/home/admin/conf/web/ssl.${DOMAIN_NAME}.key"

        if [[ -f "$ssl_cert" ]] && [[ -f "$ssl_key" ]]; then
            print_success "SSL sertifikatları mövcuddur"

            # Check certificate expiry
            local expiry_date=$(openssl x509 -in "$ssl_cert" -noout -enddate 2>/dev/null | cut -d= -f2)
            if [[ -n "$expiry_date" ]]; then
                print_info "SSL sertifikat bitmə tarixi: $expiry_date"
            fi
        else
            print_warning "SSL sertifikatları tapılmadı!"
            print_info "Sertifikat yolları:"
            print_info "  Cert: $ssl_cert"
            print_info "  Key:  $ssl_key"
            print_info "Əl ilə sertifikatları quraşdırın və ya Let's Encrypt istifadə edin"
        fi
    else
        print_info "HTTP protokol istifadə edilir, SSL lazım deyil"
    fi
}

# Check system resources
check_system_resources() {
    print_step "Sistem resursları yoxlanılır..."

    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}' 2>/dev/null || echo "0")
    print_info "CPU istifadəsi: ${cpu_usage}%"

    # Memory usage
    local memory_info=$(free -h | grep "Mem:")
    local memory_used=$(echo $memory_info | awk '{print $3}')
    local memory_total=$(echo $memory_info | awk '{print $2}')
    print_info "Memory istifadəsi: $memory_used / $memory_total"

    # Disk usage
    local disk_usage=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
    print_info "Disk istifadəsi: ${disk_usage}%"

    if [[ $disk_usage -gt 90 ]]; then
        print_warning "Disk istifadəsi kritik səviyyədə!"
    fi

    # Docker stats
    print_info "Container resource istifadəsi:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | head -5
}

# Cleanup old images and containers
cleanup_old_resources() {
    print_step "Köhnə Docker resursları təmizlənir..."

    # Remove unused images
    local removed_images=$(docker image prune -f 2>/dev/null | grep "Total reclaimed space" | awk '{print $4$5}' || echo "0B")
    print_info "Silinən image-lər: $removed_images"

    # Remove unused volumes (carefully)
    docker volume prune -f >/dev/null 2>&1 || true

    # Remove unused networks
    docker network prune -f >/dev/null 2>&1 || true

    print_success "Köhnə resurslar təmizləndi"
}

# Send deployment notification
send_deployment_notification() {
    print_step "Deployment bildirişi göndərilir..."

    # Load environment variables
    source "$PROJECT_ROOT/.env"

    # Create deployment summary
    DEPLOYMENT_TIME=$(date)
    DEPLOYMENT_STATUS="SUCCESS"

    # This can be extended to send email, Slack, webhook notifications
    cat > "$PROJECT_ROOT/logs/deployment_summary.json" << EOF
{
    "deployment_date": "$(date -Iseconds)",
    "status": "$DEPLOYMENT_STATUS",
    "domain": "$DOMAIN_NAME",
    "protocol": "$PROTOCOL",
    "environment": "$NODE_ENV",
    "version": "1.0.0",
    "git_commit": "$(git log -1 --pretty=format:'%h')",
    "git_branch": "$(git branch --show-current)",
    "services": [
        "frontend",
        "backend",
        "mysql",
        "phpmyadmin"
    ],
    "deployment_log": "$DEPLOYMENT_LOG"
}
EOF

    print_success "Deployment bildirişi yaradıldı"
}

# Display deployment summary
show_deployment_summary() {
    echo ""
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${PURPLE}      Deployment Tamamlandı          ${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo ""

    # Load environment variables
    source "$PROJECT_ROOT/.env"

    echo -e "${CYAN}🌐 Domain: ${NC}${PROTOCOL}://${DOMAIN_NAME}"
    echo -e "${CYAN}🔧 Backend API: ${NC}${PROTOCOL}://${DOMAIN_NAME}/api"
    echo -e "${CYAN}📚 API Docs: ${NC}${PROTOCOL}://${DOMAIN_NAME}/api/docs"
    echo -e "${CYAN}🗄️  phpMyAdmin: ${NC}${PROTOCOL}://${DOMAIN_NAME}/phpmyadmin"
    echo -e "${CYAN}📅 Deployment tarixi: ${NC}$(date)"
    echo -e "${CYAN}🔧 Git commit: ${NC}$(git log -1 --pretty=format:'%h - %s')"
    echo ""

    echo -e "${GREEN}✅ Deployment uğurlu tamamlandı!${NC}"
    echo ""

    echo -e "${YELLOW}📋 Növbəti addımlar:${NC}"
    echo "   1. Web səhifəni test edin: ${PROTOCOL}://${DOMAIN_NAME}"
    echo "   2. Admin paneli test edin: ${PROTOCOL}://${DOMAIN_NAME}/admin"
    echo "   3. API endpoints test edin: ${PROTOCOL}://${DOMAIN_NAME}/api/docs"
    echo "   4. Monitoring quraşdırın: ./scripts/monitor.sh"
    echo ""

    echo -e "${BLUE}📊 Monitoring üçün:${NC}"
    echo "   make logs          # Logları izlə"
    echo "   make status        # Status yoxla"
    echo "   make health        # Health check"
    echo "   make monitor       # Continuous monitoring"
    echo ""

    echo -e "${PURPLE}📝 Log faylları:${NC}"
    echo "   Deployment: $DEPLOYMENT_LOG"
    echo "   Summary: $PROJECT_ROOT/logs/deployment_summary.json"
}

# Rollback function (in case of failure)
rollback_deployment() {
    print_error "Deployment uğursuz oldu, rollback edilir..."

    # Stop failed containers
    print_info "Uğursuz containers dayandırılır..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.prod.yaml" down --timeout 30 || true

    # Try to restore from latest backup
    LATEST_BACKUP=$(ls -t "$PROJECT_ROOT/backups"/quiz_backup_*.tar.gz 2>/dev/null | head -1)

    if [[ -n "$LATEST_BACKUP" ]] && [[ -f "$PROJECT_ROOT/scripts/restore.sh" ]]; then
        print_info "Son backup-dan restore edilir: $LATEST_BACKUP"
        if "$PROJECT_ROOT/scripts/restore.sh" "$LATEST_BACKUP" --force; then
            print_success "Rollback tamamlandı"
        else
            print_error "Rollback uğursuz oldu!"
        fi
    else
        print_warning "Rollback üçün backup və ya restore script tapılmadı"
    fi

    print_error "Rollback prosesi tamamlandı. Lütfən problemləri araşdırın."
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Rollback completed" >> "$DEPLOYMENT_LOG"
}

# Main deployment function
main() {
    print_header

    # Create logs directory
    mkdir -p "$PROJECT_ROOT/logs"

    # Parse arguments
    SKIP_BACKUP=false
    SKIP_TESTS=false
    FORCE_DEPLOY=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --force)
                FORCE_DEPLOY=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Naməlum parametr: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Start deployment
    print_info "Production deployment başlayır..."
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Deployment started" > "$DEPLOYMENT_LOG"

    # Set trap for rollback on failure
    trap 'rollback_deployment; exit 1' ERR

    # Deployment confirmation
    if [[ "$FORCE_DEPLOY" != true ]]; then
        source "$PROJECT_ROOT/.env" 2>/dev/null || true
        echo -e "${YELLOW}⚠️  Production deployment başlayacaq${NC}"
        echo -e "${YELLOW}Domain: ${DOMAIN_NAME:-quiz.findex.az}${NC}"
        echo ""
        read -p "Davam etmək istəyirsiniz? (y/N): " confirm
        [[ "$confirm" != "y" ]] && { echo "Deployment ləğv edildi."; exit 0; }
        echo ""
    fi

    # Deployment steps
    pre_deployment_checks
    update_source_code
    check_compose_files

    if [[ "$SKIP_BACKUP" == false ]]; then
        create_pre_deployment_backup
    fi

    build_and_deploy
    wait_for_services
    run_migrations

    if [[ "$SKIP_TESTS" == false ]]; then
        verify_deployment
    fi

    setup_ssl
    check_system_resources
    cleanup_old_resources
    send_deployment_notification

    # Remove error trap
    trap - ERR

    # Show summary
    show_deployment_summary

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Deployment completed successfully" >> "$DEPLOYMENT_LOG"
    print_success "Deployment uğurla tamamlandı! 🎉"
}

# Error handling with rollback
set +e  # Disable immediate exit on error for main function

# Run main function
main "$@"

# Check exit status
if [[ $? -ne 0 ]]; then
    print_error "Deployment zamanı xəta baş verdi!"
    exit 1
fi