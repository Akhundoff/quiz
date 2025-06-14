#!/bin/bash

# Quiz System Restore Script
# Bu script backup-dan sistem restore edir

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
TEMP_DIR="/tmp/quiz_restore_$$"
RESTORE_LOG="$PROJECT_ROOT/logs/restore_$(date +%Y%m%d_%H%M%S).log"

# Functions
print_header() {
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}    Quiz System - Restore Script     ${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}📋 $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$RESTORE_LOG"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$RESTORE_LOG"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$RESTORE_LOG"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$RESTORE_LOG"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$RESTORE_LOG"
}

# Usage function
show_usage() {
    echo "Quiz System Restore Script"
    echo ""
    echo "İstifadə: ./scripts/restore.sh [backup_file] [options]"
    echo ""
    echo "Parametrlər:"
    echo "  backup_file         Restore ediləcək backup faylı (.tar.gz)"
    echo "  --force            Təsdiq olmadan restore et"
    echo "  --db-only          Yalnız database restore et"
    echo "  --files-only       Yalnız fayllar restore et"
    echo "  --help             Bu kömək məlumatını göstər"
    echo ""
    echo "Nümunələr:"
    echo "  ./scripts/restore.sh backups/quiz_backup_20241214_120000.tar.gz"
    echo "  ./scripts/restore.sh latest --force"
    echo "  ./scripts/restore.sh backup.tar.gz --db-only"
    echo ""
}

# Load environment variables
load_environment() {
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        source "$PROJECT_ROOT/.env"
    else
        print_error ".env faylı tapılmadı!"
        exit 1
    fi
}

# Validate backup file
validate_backup() {
    local backup_file="$1"

    print_step "Backup faylı yoxlanılır..."

    # Handle 'latest' keyword
    if [[ "$backup_file" == "latest" ]]; then
        backup_file=$(ls -t "$PROJECT_ROOT/backups"/quiz_backup_*.tar.gz 2>/dev/null | head -1)
        if [[ -z "$backup_file" ]]; then
            print_error "Heç bir backup faylı tapılmadı!"
            exit 1
        fi
        print_info "Son backup faylı istifadə edilir: $backup_file"
    fi

    # Check if file exists
    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup faylı tapılmadı: $backup_file"
        exit 1
    fi

    # Check if file is readable
    if [[ ! -r "$backup_file" ]]; then
        print_error "Backup faylı oxuna bilmir: $backup_file"
        exit 1
    fi

    # Check file extension
    if [[ "$backup_file" != *.tar.gz ]]; then
        print_error "Backup faylı .tar.gz formatında olmalıdır"
        exit 1
    fi

    # Test archive integrity
    if ! tar -tzf "$backup_file" >/dev/null 2>&1; then
        print_error "Backup arxivi korlanıb və ya düzgün deyil!"
        exit 1
    fi

    print_success "Backup faylı təsdiqləndi: $backup_file"
    echo "$backup_file"
}

# Extract backup archive
extract_backup() {
    local backup_file="$1"

    print_step "Backup arxivi çıxarılır..."

    # Create temporary directory
    mkdir -p "$TEMP_DIR"

    # Extract archive
    tar -xzf "$backup_file" -C "$TEMP_DIR"

    # Find extracted directory
    local extracted_dir=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "quiz_backup_*" | head -1)

    if [[ -z "$extracted_dir" ]]; then
        print_error "Backup strukturu tapılmadı!"
        exit 1
    fi

    print_success "Backup çıxarıldı: $extracted_dir"
    echo "$extracted_dir"
}

# Verify backup contents
verify_backup_contents() {
    local backup_dir="$1"

    print_step "Backup məzmunu yoxlanılır..."

    # Check metadata
    if [[ -f "$backup_dir/metadata.json" ]]; then
        local backup_info=$(cat "$backup_dir/metadata.json")
        print_info "Backup metadata tapıldı"

        # Extract backup info
        local backup_date=$(echo "$backup_info" | grep '"backup_date"' | cut -d'"' -f4)
        local backup_type=$(echo "$backup_info" | grep '"backup_type"' | cut -d'"' -f4)
        local db_name=$(echo "$backup_info" | grep '"database_name"' | cut -d'"' -f4)

        print_info "Backup tarixi: $backup_date"
        print_info "Backup növü: $backup_type"
        print_info "Database adı: $db_name"
    else
        print_warning "Metadata faylı tapılmadı"
    fi

    # Check required files
    local required_files=("database.sql")
    local missing_files=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "$backup_dir/$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Lazımi fayllar tapılmadı: ${missing_files[*]}"
        exit 1
    fi

    print_success "Backup məzmunu təsdiqləndi"
}

# Stop services
stop_services() {
    print_step "Servicelər dayandırılır..."

    local compose_file="docker-compose.yaml"
    if [[ "$NODE_ENV" == "production" ]]; then
        compose_file="docker-compose.prod.yaml"
    fi

    if docker-compose -f "$PROJECT_ROOT/$compose_file" ps -q | grep -q .; then
        docker-compose -f "$PROJECT_ROOT/$compose_file" down --timeout 30
        print_success "Servicelər dayandırıldı"
    else
        print_info "Servicelər artıq dayandırılıb"
    fi
}

# Start services
start_services() {
    print_step "Servicelər başladılır..."

    local compose_file="docker-compose.yaml"
    if [[ "$NODE_ENV" == "production" ]]; then
        compose_file="docker-compose.prod.yaml"
    fi

    docker-compose -f "$PROJECT_ROOT/$compose_file" up -d

    # Wait for services to be ready
    print_info "Servicelərın hazır olması gözlənilir..."
    sleep 30

    # Verify services are running
    if docker-compose -f "$PROJECT_ROOT/$compose_file" ps | grep -q "Up"; then
        print_success "Servicelər başladıldı"
    else
        print_error "Servicelər düzgün başlamadı!"
        return 1
    fi
}

# Restore database
restore_database() {
    local backup_dir="$1"

    print_step "Database restore edilir..."

    local db_backup="$backup_dir/database.sql"

    if [[ ! -f "$db_backup" ]]; then
        print_error "Database backup faylı tapılmadı: $db_backup"
        return 1
    fi

    # Check if MySQL is running
    local compose_file="docker-compose.yaml"
    if [[ "$NODE_ENV" == "production" ]]; then
        compose_file="docker-compose.prod.yaml"
    fi

    # Wait for MySQL to be ready
    local max_attempts=30
    local attempt=0

    while [[ $attempt -lt $max_attempts ]]; do
        attempt=$((attempt + 1))

        if docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" >/dev/null 2>&1; then
            break
        fi

        if [[ $attempt -eq $max_attempts ]]; then
            print_error "MySQL hazır olmadı!"
            return 1
        fi

        echo -n "."
        sleep 2
    done

    # Drop and recreate database
    print_info "Mövcud database silinir..."
    docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS $DB_DATABASE; CREATE DATABASE $DB_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

    # Restore database
    print_info "Database restore edilir..."
    docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" < "$db_backup"

    # Verify restore
    local table_count=$(docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_DATABASE';" 2>/dev/null | tail -1)

    if [[ $table_count -gt 0 ]]; then
        print_success "Database restore edildi ($table_count cədvəl)"
    else
        print_error "Database restore uğursuz!"
        return 1
    fi
}

# Restore files
restore_files() {
    local backup_dir="$1"

    print_step "Fayllar restore edilir..."

    # Restore uploads
    if [[ -d "$backup_dir/uploads" ]]; then
        print_info "Upload faylları restore edilir..."

        # Backup current uploads if they exist
        if [[ -d "$PROJECT_ROOT/backend/uploads" ]]; then
            mv "$PROJECT_ROOT/backend/uploads" "$PROJECT_ROOT/backend/uploads.backup.$(date +%s)" 2>/dev/null || true
        fi

        cp -r "$backup_dir/uploads" "$PROJECT_ROOT/backend/"
        print_success "Upload faylları restore edildi"
    else
        print_warning "Upload qovluğu backup-da tapılmadı"
    fi

    # Restore environment files if requested
    if [[ -f "$backup_dir/root.env" ]]; then
        print_info "Environment faylları tapıldı (restore edilmir, mövcud qalır)"
    fi
}

# Restore docker volumes
restore_volumes() {
    local backup_dir="$1"

    if [[ -f "$backup_dir/mysql_volume.tar.gz" ]]; then
        print_step "Docker volumes restore edilir..."

        # Stop MySQL container specifically
        local compose_file="docker-compose.yaml"
        if [[ "$NODE_ENV" == "production" ]]; then
            compose_file="docker-compose.prod.yaml"
        fi

        docker-compose -f "$PROJECT_ROOT/$compose_file" stop mysql 2>/dev/null || true

        # Restore volume
        docker run --rm \
            -v quiz-system_mysql_data:/data \
            -v "$backup_dir":/backup \
            alpine sh -c "cd /data && rm -rf * && tar xzf /backup/mysql_volume.tar.gz"

        print_success "Docker volumes restore edildi"
    else
        print_warning "Volume backup tapılmadı"
    fi
}

# Cleanup temporary files
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        print_info "Müvəqqəti fayllar təmizləndi"
    fi
}

# Verify restore
verify_restore() {
    print_step "Restore yoxlanılır..."

    # Wait a bit for services to stabilize
    sleep 10

    # Check database connection
    local compose_file="docker-compose.yaml"
    if [[ "$NODE_ENV" == "production" ]]; then
        compose_file="docker-compose.prod.yaml"
    fi

    if docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        print_success "Database bağlantısı təsdiqləndi"
    else
        print_error "Database bağlantısı uğursuz!"
        return 1
    fi

    # Check web services
    local max_attempts=30
    local attempt=0

    while [[ $attempt -lt $max_attempts ]]; do
        attempt=$((attempt + 1))

        if curl -f "http://localhost:3000/health" >/dev/null 2>&1 && curl -f "http://localhost:3001/api/quiz/questions" >/dev/null 2>&1; then
            print_success "Web servicelər təsdiqləndi"
            return 0
        fi

        if [[ $attempt -eq $max_attempts ]]; then
            print_warning "Web servicelər tam hazır deyil, amma restore tamamlandı"
            return 0
        fi

        echo -n "."
        sleep 2
    done
}

# Show restore summary
show_restore_summary() {
    local backup_file="$1"

    echo ""
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${PURPLE}        Restore Tamamlandı            ${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo ""

    # Load environment variables
    source "$PROJECT_ROOT/.env"

    echo -e "${CYAN}📁 Backup faylı: ${NC}$backup_file"
    echo -e "${CYAN}📅 Restore tarixi: ${NC}$(date)"
    echo -e "${CYAN}🌐 Domain: ${NC}${PROTOCOL}://${DOMAIN_NAME}"
    echo ""

    echo -e "${GREEN}✅ Restore uğurla tamamlandı!${NC}"
    echo ""

    echo -e "${YELLOW}📋 Növbəti addımlar:${NC}"
    if [[ "$NODE_ENV" == "production" ]]; then
        echo "   1. Web səhifəni test edin: ${PROTOCOL}://${DOMAIN_NAME}"
        echo "   2. Admin paneli test edin: ${PROTOCOL}://${DOMAIN_NAME}/admin"
    else
        echo "   1. Web səhifəni test edin: http://localhost:3000"
        echo "   2. Admin paneli test edin: http://localhost:3000/admin"
    fi
    echo "   3. Funkcionallığı test edin"
    echo "   4. Yeni backup yaradın: make backup"
    echo ""

    echo -e "${BLUE}📊 Status yoxlama:${NC}"
    echo "   make status        # Servicelər statusu"
    echo "   make health        # Health check"
    echo "   make logs          # Logları yoxla"
    echo ""

    echo -e "${PURPLE}📝 Log fayl: ${NC}$RESTORE_LOG"
}

# Main function
main() {
    print_header

    # Create logs directory
    mkdir -p "$PROJECT_ROOT/logs"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Restore started" > "$RESTORE_LOG"

    # Parse arguments
    local backup_file=""
    local force_restore=false
    local db_only=false
    local files_only=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_restore=true
                shift
                ;;
            --db-only)
                db_only=true
                shift
                ;;
            --files-only)
                files_only=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                print_error "Naməlum parametr: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$backup_file" ]]; then
                    backup_file="$1"
                else
                    print_error "Artıq backup faylı təyin edilib: $backup_file"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Check if backup file is provided
    if [[ -z "$backup_file" ]]; then
        print_error "Backup faylı təyin edilməyib!"
        show_usage
        exit 1
    fi

    # Load environment
    load_environment

    # Validate backup
    backup_file=$(validate_backup "$backup_file")

    # Confirmation (if not forced)
    if [[ "$force_restore" == false ]]; then
        echo -e "${RED}⚠️  XƏBƏRDAR: Bu əməliyyat mövcud məlumatları siləcək!${NC}"
        echo -e "${YELLOW}Backup faylı: $backup_file${NC}"
        echo ""
        read -p "Davam etmək istəyirsiniz? (y/N): " confirm
        [[ "$confirm" != "y" ]] && { echo "Restore ləğv edildi."; exit 0; }
    fi

    # Set trap for cleanup
    trap cleanup EXIT ERR

    # Extract backup
    local backup_dir=$(extract_backup "$backup_file")

    # Verify contents
    verify_backup_contents "$backup_dir"

    # Stop services
    stop_services

    # Perform restore based on options
    if [[ "$files_only" == false ]]; then
        restore_database "$backup_dir"

        if [[ "$db_only" == false ]]; then
            restore_volumes "$backup_dir"
        fi
    fi

    if [[ "$db_only" == false ]]; then
        restore_files "$backup_dir"
    fi

    # Start services
    start_services

    # Verify restore
    verify_restore

    # Show summary
    show_restore_summary "$backup_file"

    print_success "Restore əməliyyatı uğurla tamamlandı! 🎉"
}

# Error handling
trap 'print_error "Restore zamanı xəta baş verdi!"; cleanup; exit 1' ERR

# Run main function
main "$@"