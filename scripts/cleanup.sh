#!/bin/bash

# Quiz System Cleanup Script
# Bu script sistemin təmizlik və optimizasiya əməliyyatlarını yerinə yetirir

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
CLEANUP_LOG="$PROJECT_ROOT/logs/cleanup_$(date +%Y%m%d_%H%M%S).log"

# Functions
print_header() {
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}    Quiz System - Cleanup Script     ${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}📋 $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$CLEANUP_LOG"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$CLEANUP_LOG"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$CLEANUP_LOG"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$CLEANUP_LOG"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$CLEANUP_LOG"
}

# Usage function
show_usage() {
    echo "Quiz System Cleanup Script"
    echo ""
    echo "İstifadə: ./scripts/cleanup.sh [options]"
    echo ""
    echo "Parametrlər:"
    echo "  --docker          Docker resurslarını təmizlə"
    echo "  --logs            Köhnə log fayllarını təmizlə"
    echo "  --backups         Köhnə backup fayllarını təmizlə"
    echo "  --temp            Müvəqqəti faylları təmizlə"
    echo "  --uploads         Köhnə upload fayllarını təmizlə"
    echo "  --database        Database təmizlik və optimizasiya"
    echo "  --all             Bütün təmizlik əməliyyatları"
    echo "  --force           Təsdiq olmadan təmizlə"
    echo "  --dry-run         Yalnız nə silinəcəyini göstər"
    echo "  --help            Bu kömək məlumatını göstər"
    echo ""
    echo "Nümunələr:"
    echo "  ./scripts/cleanup.sh --docker --logs"
    echo "  ./scripts/cleanup.sh --all --force"
    echo "  ./scripts/cleanup.sh --dry-run --all"
    echo ""
}

# Load environment variables
load_environment() {
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        source "$PROJECT_ROOT/.env"
    else
        print_warning ".env faylı tapılmadı, default dəyərlər istifadə edilir"
    fi
}

# Calculate and display size
show_size() {
    local path="$1"
    local description="$2"

    if [[ -e "$path" ]]; then
        local size=$(du -sh "$path" 2>/dev/null | cut -f1)
        print_info "$description: $size"
    fi
}

# Docker cleanup
cleanup_docker() {
    print_step "Docker resursları təmizlənir..."

    local before_size=$(docker system df --format "table {{.Type}}\t{{.Size}}" 2>/dev/null | grep -v "TYPE" | awk '{sum += $2} END {print sum}' || echo "0")

    if [[ "$DRY_RUN" == true ]]; then
        print_info "Docker təmizlik (dry-run):"
        docker system df
        docker image ls --filter "dangling=true"
        docker volume ls --filter "dangling=true"
        return 0
    fi

    # Remove unused images
    print_info "İstifadə edilməyən image-lər silinir..."
    docker image prune -f >/dev/null 2>&1 || true

    # Remove unused volumes (carefully)
    print_info "İstifadə edilməyən volume-lər silinir..."
    docker volume prune -f >/dev/null 2>&1 || true

    # Remove unused networks
    print_info "İstifadə edilməyən network-lər silinir..."
    docker network prune -f >/dev/null 2>&1 || true

    # Remove stopped containers
    print_info "Dayandırılmış container-lər silinir..."
    docker container prune -f >/dev/null 2>&1 || true

    # Remove build cache
    print_info "Build cache təmizlənir..."
    docker builder prune -f >/dev/null 2>&1 || true

    local after_size=$(docker system df --format "table {{.Type}}\t{{.Size}}" 2>/dev/null | grep -v "TYPE" | awk '{sum += $2} END {print sum}' || echo "0")
    local saved=$((before_size - after_size))

    print_success "Docker təmizlik tamamlandı (${saved}MB qənaət)"
}

# Log files cleanup
cleanup_logs() {
    print_step "Log faylları təmizlənir..."

    local logs_dir="$PROJECT_ROOT/logs"

    if [[ ! -d "$logs_dir" ]]; then
        print_info "Log qovluğu tapılmadı"
        return 0
    fi

    show_size "$logs_dir" "Log qovluğu ölçüsü"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "30+ günlük log faylları (dry-run):"
        find "$logs_dir" -name "*.log" -type f -mtime +30 -ls 2>/dev/null || true
        return 0
    fi

    # Remove logs older than 30 days
    local old_logs=$(find "$logs_dir" -name "*.log" -type f -mtime +30 2>/dev/null | wc -l)
    find "$logs_dir" -name "*.log" -type f -mtime +30 -delete 2>/dev/null || true

    # Compress logs older than 7 days
    find "$logs_dir" -name "*.log" -type f -mtime +7 ! -name "*.gz" -exec gzip {} \; 2>/dev/null || true


    print_success "Log təmizlik tamamlandı ($old_logs köhnə fayl silindi)"
}

# Backup files cleanup
cleanup_backups() {
    print_step "Backup faylları təmizlənir..."

    local backups_dir="$PROJECT_ROOT/backups"

    if [[ ! -d "$backups_dir" ]]; then
        print_info "Backup qovluğu tapılmadı"
        return 0
    fi

    show_size "$backups_dir" "Backup qovluğu ölçüsü"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "30+ günlük backup faylları (dry-run):"
        find "$backups_dir" -name "quiz_backup_*.tar.gz" -type f -mtime +30 -ls 2>/dev/null || true
        print_info "Saxlanılacaq son 10 backup:"
        ls -t "$backups_dir"/quiz_backup_*.tar.gz 2>/dev/null | head -10 || true
        return 0
    fi

    # Keep only last 10 backups
    local backup_count=$(ls -t "$backups_dir"/quiz_backup_*.tar.gz 2>/dev/null | wc -l)
    if [[ $backup_count -gt 10 ]]; then
        local to_delete=$((backup_count - 10))
        ls -t "$backups_dir"/quiz_backup_*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
        print_success "Artıq backup faylları silindi ($to_delete fayl)"
    else
        print_info "Backup faylları limitdən azdır ($backup_count/10)"
    fi

    # Remove backups older than 30 days
    local old_backups=$(find "$backups_dir" -name "quiz_backup_*.tar.gz" -type f -mtime +30 2>/dev/null | wc -l)
    find "$backups_dir" -name "quiz_backup_*.tar.gz" -type f -mtime +30 -delete 2>/dev/null || true

    if [[ $old_backups -gt 0 ]]; then
        print_success "$old_backups köhnə backup faylı silindi"
    fi
}

# Temporary files cleanup
cleanup_temp() {
    print_step "Müvəqqəti fayllar təmizlənir..."

    local temp_dirs=(
        "/tmp/quiz_*"
        "$PROJECT_ROOT/backend/node_modules/.cache"
        "$PROJECT_ROOT/frontend/node_modules/.cache"
        "$PROJECT_ROOT/backend/dist"
        "$PROJECT_ROOT/frontend/build"
    )

    if [[ "$DRY_RUN" == true ]]; then
        print_info "Silinəcək müvəqqəti fayllar (dry-run):"
        for pattern in "${temp_dirs[@]}"; do
            ls -la $pattern 2>/dev/null || true
        done
        return 0
    fi

    local cleaned=0

    # Clean temporary directories
    for pattern in "${temp_dirs[@]}"; do
        if ls $pattern >/dev/null 2>&1; then
            rm -rf $pattern 2>/dev/null || true
            cleaned=$((cleaned + 1))
        fi
    done

    # Clean npm cache
    if command -v npm >/dev/null 2>&1; then
        npm cache clean --force >/dev/null 2>&1 || true
        print_info "NPM cache təmizləndi"
    fi

    print_success "Müvəqqəti fayllar təmizləndi ($cleaned mövqe)"
}

# Upload files cleanup
cleanup_uploads() {
    print_step "Upload faylları təmizlənir..."

    local uploads_dir="$PROJECT_ROOT/backend/uploads"

    if [[ ! -d "$uploads_dir" ]]; then
        print_info "Upload qovluğu tapılmadı"
        return 0
    fi

    show_size "$uploads_dir" "Upload qovluğu ölçüsü"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "90+ günlük upload faylları (dry-run):"
        find "$uploads_dir" -type f -mtime +90 -ls 2>/dev/null || true
        return 0
    fi

    # Remove uploads older than 90 days (be careful with this)
    local old_uploads=$(find "$uploads_dir" -type f -mtime +90 2>/dev/null | wc -l)

    if [[ $old_uploads -gt 0 ]]; then
        if [[ "$FORCE_CLEANUP" == true ]]; then
            find "$uploads_dir" -type f -mtime +90 -delete 2>/dev/null || true
            print_success "$old_uploads köhnə upload faylı silindi"
        else
            print_warning "$old_uploads köhnə upload faylı tapıldı (--force ilə silin)"
        fi
    else
        print_info "Silinəcək köhnə upload faylı yoxdur"
    fi

    # Clean empty directories
    find "$uploads_dir" -type d -empty -delete 2>/dev/null || true
}

# Database cleanup and optimization
cleanup_database() {
    print_step "Database təmizlik və optimizasiya..."

    # Check if containers are running
    local compose_file="docker-compose.yaml"
    if [[ "$NODE_ENV" == "production" ]]; then
        compose_file="docker-compose.prod.yaml"
    fi

    if ! docker-compose -f "$PROJECT_ROOT/$compose_file" ps | grep -q "quiz_mysql.*Up"; then
        print_warning "MySQL container işləmir, database təmizlik keçilir"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "Database optimizasiya (dry-run):"
        docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "
            SELECT table_name, table_rows, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
            FROM information_schema.tables
            WHERE table_schema='$DB_DATABASE'
            ORDER BY (data_length + index_length) DESC;" 2>/dev/null || true
        return 0
    fi

    # Clean old quiz sessions (older than 30 days)
    local old_sessions=$(docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "
        SELECT COUNT(*) FROM quiz_sessions
        WHERE started_at < DATE_SUB(NOW(), INTERVAL 30 DAY);" 2>/dev/null | tail -1)

    if [[ $old_sessions -gt 0 ]]; then
        docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "
            DELETE FROM quiz_sessions
            WHERE started_at < DATE_SUB(NOW(), INTERVAL 30 DAY);" 2>/dev/null || true
        print_success "$old_sessions köhnə quiz session silindi"
    fi

    # Optimize all tables
    print_info "Database cədvəlləri optimizasiya edilir..."
    docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "
        SELECT CONCAT('OPTIMIZE TABLE ', table_name, ';')
        FROM information_schema.tables
        WHERE table_schema='$DB_DATABASE';" 2>/dev/null | grep "OPTIMIZE" | while read -r query; do
        docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "$query" >/dev/null 2>&1 || true
    done

    # Update table statistics
    docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "
        ANALYZE TABLE questions, quiz_sessions, user_responses, admin_users;" >/dev/null 2>&1 || true

    print_success "Database optimizasiya tamamlandı"
}

# System cache cleanup
cleanup_system() {
    print_step "Sistem cache təmizlənir..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "Sistem cache təmizlik (dry-run)"
        return 0
    fi

    # Clear system caches (if running as appropriate user)
    if command -v sync >/dev/null 2>&1; then
        sync
    fi

    # Clear DNS cache (if available)
    if command -v systemd-resolve >/dev/null 2>&1; then
        sudo systemd-resolve --flush-caches 2>/dev/null || true
        print_info "DNS cache təmizləndi"
    fi

    print_success "Sistem cache təmizləndi"
}

# Show disk usage before and after
show_disk_usage() {
    local when="$1"

    print_step "Disk istifadəsi ($when):"

    local project_size=$(du -sh "$PROJECT_ROOT" 2>/dev/null | cut -f1)
    local available_space=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    local used_percentage=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}')

    print_info "Layihə ölçüsü: $project_size"
    print_info "Boş sahə: $available_space"
    print_info "İstifadə nisbəti: $used_percentage"

    # Docker usage
    if command -v docker >/dev/null 2>&1; then
        print_info "Docker sistem istifadəsi:"
        docker system df --format "table {{.Type}}\t{{.Total}}\t{{.Size}}\t{{.Reclaimable}}" 2>/dev/null | while read -r line; do
            echo -e "    ${BLUE}$line${NC}"
        done
    fi
}

# Generate cleanup report
generate_report() {
    print_step "Təmizlik hesabatı yaradılır..."

    local report_file="$PROJECT_ROOT/logs/cleanup_report_$(date +%Y%m%d_%H%M%S).json"

    cat > "$report_file" << EOF
{
    "cleanup_date": "$(date -Iseconds)",
    "cleanup_type": "$CLEANUP_TYPE",
    "dry_run": $DRY_RUN,
    "force": $FORCE_CLEANUP,
    "operations_performed": [
        $(echo "$OPERATIONS_PERFORMED" | sed 's/,$//')
    ],
    "project_size_before": "$SIZE_BEFORE",
    "project_size_after": "$SIZE_AFTER",
    "space_freed": "$SPACE_FREED",
    "log_file": "$CLEANUP_LOG"
}
EOF

    print_success "Təmizlik hesabatı yaradıldı: $report_file"
}

# Show cleanup summary
show_cleanup_summary() {
    echo ""
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${PURPLE}        Cleanup Tamamlandı            ${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo ""

    echo -e "${CYAN}📅 Təmizlik tarixi: ${NC}$(date)"
    echo -e "${CYAN}🧹 Təmizlik növü: ${NC}$CLEANUP_TYPE"
    echo -e "${CYAN}📊 Əməliyyatlar: ${NC}$OPERATIONS_PERFORMED"

    if [[ "$DRY_RUN" == false ]]; then
        echo -e "${CYAN}💾 Qənaət: ${NC}$SPACE_FREED"
    else
        echo -e "${CYAN}🔍 Mod: ${NC}Dry-run (yalnız analiz)"
    fi

    echo ""

    if [[ "$DRY_RUN" == false ]]; then
        echo -e "${GREEN}✅ Təmizlik uğurla tamamlandı!${NC}"
    else
        echo -e "${BLUE}ℹ️  Dry-run analizi tamamlandı${NC}"
        echo -e "${YELLOW}Əməliyyatları yerinə yetirmək üçün --dry-run parametrini çıxarın${NC}"
    fi

    echo ""
    echo -e "${PURPLE}📝 Log fayl: ${NC}$CLEANUP_LOG"
}

# Main function
main() {
    print_header

    # Create logs directory
    mkdir -p "$PROJECT_ROOT/logs"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleanup started" > "$CLEANUP_LOG"

    # Parse arguments
    local cleanup_docker=false
    local cleanup_logs=false
    local cleanup_backups=false
    local cleanup_temp=false
    local cleanup_uploads=false
    local cleanup_database=false
    local cleanup_all=false
    DRY_RUN=false
    FORCE_CLEANUP=false

    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --docker)
                cleanup_docker=true
                shift
                ;;
            --logs)
                cleanup_logs=true
                shift
                ;;
            --backups)
                cleanup_backups=true
                shift
                ;;
            --temp)
                cleanup_temp=true
                shift
                ;;
            --uploads)
                cleanup_uploads=true
                shift
                ;;
            --database)
                cleanup_database=true
                shift
                ;;
            --all)
                cleanup_all=true
                shift
                ;;
            --force)
                FORCE_CLEANUP=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
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

    # Load environment
    load_environment

    # Set cleanup type
    if [[ "$cleanup_all" == true ]]; then
        CLEANUP_TYPE="full"
        cleanup_docker=true
        cleanup_logs=true
        cleanup_backups=true
        cleanup_temp=true
        cleanup_uploads=true
        cleanup_database=true
    else
        CLEANUP_TYPE="selective"
    fi

    # Show initial disk usage
    SIZE_BEFORE=$(du -sh "$PROJECT_ROOT" 2>/dev/null | cut -f1)
    show_disk_usage "əvvəl"
    echo ""

    # Confirmation (if not dry-run and not forced)
    if [[ "$DRY_RUN" == false ]] && [[ "$FORCE_CLEANUP" == false ]]; then
        echo -e "${YELLOW}⚠️  Təmizlik əməliyyatı başlayacaq${NC}"
        echo -e "${YELLOW}Növü: $CLEANUP_TYPE${NC}"
        echo ""
        read -p "Davam etmək istəyirsiniz? (y/N): " confirm
        [[ "$confirm" != "y" ]] && { echo "Təmizlik ləğv edildi."; exit 0; }
        echo ""
    fi

    # Initialize operations list
    OPERATIONS_PERFORMED=""

    # Perform cleanup operations
    if [[ "$cleanup_docker" == true ]]; then
        cleanup_docker
        OPERATIONS_PERFORMED+="docker,"
        echo ""
    fi

    if [[ "$cleanup_logs" == true ]]; then
        cleanup_logs
        OPERATIONS_PERFORMED+="logs,"
        echo ""
    fi

    if [[ "$cleanup_backups" == true ]]; then
        cleanup_backups
        OPERATIONS_PERFORMED+="backups,"
        echo ""
    fi

    if [[ "$cleanup_temp" == true ]]; then
        cleanup_temp
        OPERATIONS_PERFORMED+="temp,"
        echo ""
    fi

    if [[ "$cleanup_uploads" == true ]]; then
        cleanup_uploads
        OPERATIONS_PERFORMED+="uploads,"
        echo ""
    fi

    if [[ "$cleanup_database" == true ]]; then
        cleanup_database
        OPERATIONS_PERFORMED+="database,"
        echo ""
    fi

    # System cleanup (always run if not dry-run)
    if [[ "$DRY_RUN" == false ]]; then
        cleanup_system
        OPERATIONS_PERFORMED+="system,"
        echo ""
    fi

    # Show final disk usage
    SIZE_AFTER=$(du -sh "$PROJECT_ROOT" 2>/dev/null | cut -f1)
    show_disk_usage "sonra"

    # Calculate space freed
    if [[ "$DRY_RUN" == false ]]; then
        SPACE_FREED="Hesablanır..."  # Complex calculation, simplified for demo
    else
        SPACE_FREED="N/A"
    fi

    # Generate report
    generate_report

    # Show summary
    show_cleanup_summary

    if [[ "$DRY_RUN" == false ]]; then
        print_success "Təmizlik əməliyyatı uğurla tamamlandı! 🧹"
    else
        print_info "Dry-run analizi tamamlandı! 🔍"
    fi
}

# Error handling
trap 'print_error "Cleanup zamanı xəta baş verdi!"; exit 1' ERR

# Run main function
main "$@"