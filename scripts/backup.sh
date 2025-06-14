#!/bin/bash

# Quiz System Backup Script
# Bu script database və faylların backup-ını yaradır

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
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="quiz_backup_${TIMESTAMP}"

# Load environment variables
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${RED}❌ .env faylı tapılmadı!${NC}"
    exit 1
fi

# Functions
print_header() {
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}    Quiz System - Backup Script      ${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if containers are running
check_containers() {
    print_step "Container statusu yoxlanılır..."

    if ! docker-compose -f "$PROJECT_ROOT/docker-compose.yaml" ps | grep -q "quiz_mysql.*Up"; then
        print_error "MySQL container işləmir! Əvvəlcə sistemi başladın: make start"
        exit 1
    fi

    print_success "Containers işləyir"
}

# Create backup directory
create_backup_dir() {
    print_step "Backup qovluğu yaradılır..."

    mkdir -p "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

    print_success "Backup qovluğu yaradıldı: $BACKUP_DIR/$BACKUP_NAME"
}

# Backup database
backup_database() {
    print_step "Database backup yaradılır..."

    # MySQL dump
    docker-compose -f "$PROJECT_ROOT/docker-compose.yaml" exec -T mysql mysqldump \
        -u"$DB_USERNAME" \
        -p"$DB_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --add-drop-database \
        --databases "$DB_DATABASE" > "$BACKUP_DIR/$BACKUP_NAME/database.sql"

    # Check if backup was successful
    if [[ $? -eq 0 ]] && [[ -s "$BACKUP_DIR/$BACKUP_NAME/database.sql" ]]; then
        print_success "Database backup yaradıldı"
    else
        print_error "Database backup xətası!"
        exit 1
    fi
}

# Backup uploaded files
backup_files() {
    print_step "Fayl backup yaradılır..."

    # Backend uploads
    if [[ -d "$PROJECT_ROOT/backend/uploads" ]]; then
        cp -r "$PROJECT_ROOT/backend/uploads" "$BACKUP_DIR/$BACKUP_NAME/"
        print_success "Upload faylları backup edildi"
    else
        print_info "Upload qovluğu tapılmadı"
    fi

    # Environment files
    cp "$PROJECT_ROOT/.env" "$BACKUP_DIR/$BACKUP_NAME/root.env" 2>/dev/null || true
    cp "$PROJECT_ROOT/backend/.env" "$BACKUP_DIR/$BACKUP_NAME/backend.env" 2>/dev/null || true
    cp "$PROJECT_ROOT/frontend/.env" "$BACKUP_DIR/$BACKUP_NAME/frontend.env" 2>/dev/null || true

    print_success "Environment faylları backup edildi"
}

# Backup docker volumes
backup_volumes() {
    print_step "Docker volumes backup yaradılır..."

    # MySQL data volume
    docker run --rm \
        -v quiz-system_mysql_data:/data \
        -v "$BACKUP_DIR/$BACKUP_NAME":/backup \
        alpine tar czf /backup/mysql_volume.tar.gz -C /data .

    print_success "Docker volumes backup edildi"
}

# Create metadata file
create_metadata() {
    print_step "Metadata yaradılır..."

    cat > "$BACKUP_DIR/$BACKUP_NAME/metadata.json" << EOF
{
    "backup_date": "$(date -Iseconds)",
    "backup_name": "$BACKUP_NAME",
    "project_version": "1.0.0",
    "database_name": "$DB_DATABASE",
    "domain_name": "$DOMAIN_NAME",
    "protocol": "$PROTOCOL",
    "environment": "$NODE_ENV",
    "backup_type": "$BACKUP_TYPE",
    "files_included": [
        "database.sql",
        "uploads/",
        "mysql_volume.tar.gz",
        "root.env",
        "backend.env",
        "frontend.env"
    ]
}
EOF

    print_success "Metadata yaradıldı"
}

# Create compressed archive
create_archive() {
    print_step "Sıxılmış arxiv yaradılır..."

    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

    # Remove uncompressed directory
    rm -rf "$BACKUP_NAME"

    # Get file size
    BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)

    print_success "Arxiv yaradıldı: ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"
}

# Cleanup old backups
cleanup_old_backups() {
    print_step "Köhnə backuplar təmizlənir..."

    # Keep only last 7 backups
    cd "$BACKUP_DIR"
    ls -t quiz_backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true

    print_success "Köhnə backuplar təmizləndi"
}

# Full backup (includes logs and additional files)
full_backup() {
    print_step "Tam backup yaradılır..."

    # Backup logs
    if [[ -d "$PROJECT_ROOT/logs" ]]; then
        cp -r "$PROJECT_ROOT/logs" "$BACKUP_DIR/$BACKUP_NAME/"
        print_success "Log faylları backup edildi"
    fi

    # Backup nginx configs
    if [[ -d "$PROJECT_ROOT/nginx" ]]; then
        cp -r "$PROJECT_ROOT/nginx" "$BACKUP_DIR/$BACKUP_NAME/"
        print_success "Nginx konfiqurasiyaları backup edildi"
    fi

    # Backup scripts
    cp -r "$PROJECT_ROOT/scripts" "$BACKUP_DIR/$BACKUP_NAME/"
    print_success "Script faylları backup edildi"

    # Backup docker-compose files
    cp "$PROJECT_ROOT/docker-compose"*.yaml "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null || true
    cp "$PROJECT_ROOT/Makefile" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null || true

    print_success "Konfiqurasiya faylları backup edildi"
}

# Verify backup integrity
verify_backup() {
    print_step "Backup bütövlüyü yoxlanılır..."

    # Check if archive exists and is not empty
    if [[ -f "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" ]] && [[ -s "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" ]]; then
        # Test archive integrity
        if tar -tzf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" >/dev/null 2>&1; then
            print_success "Backup bütövlüyü təsdiqləndi"
        else
            print_error "Backup arxivində xəta var!"
            exit 1
        fi
    else
        print_error "Backup arxivi yaradılmadı və ya boşdur!"
        exit 1
    fi
}

# Send notification (if configured)
send_notification() {
    print_step "Bildiriş göndərilir..."

    # This can be extended to send email, Slack, etc.
    print_info "Bildiriş funksionallığı hələ tətbiq edilməyib"
}

# Display backup summary
show_summary() {
    echo ""
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${PURPLE}        Backup Tamamlandı             ${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo ""

    BACKUP_PATH="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)

    echo -e "${CYAN}📁 Backup faylı: ${NC}$BACKUP_PATH"
    echo -e "${CYAN}📊 Backup ölçüsü: ${NC}$BACKUP_SIZE"
    echo -e "${CYAN}📅 Backup tarixi: ${NC}$(date)"
    echo -e "${CYAN}🏷️  Backup növü: ${NC}$BACKUP_TYPE"
    echo ""

    echo -e "${GREEN}🔄 Restore etmək üçün:${NC}"
    echo "   ./scripts/restore.sh $BACKUP_PATH"
    echo "   və ya: make restore FILE=$BACKUP_PATH"
    echo ""

    echo -e "${YELLOW}📋 Backup məzmunu:${NC}"
    tar -tzf "$BACKUP_PATH" | head -10
    if [[ $(tar -tzf "$BACKUP_PATH" | wc -l) -gt 10 ]]; then
        echo "   ... və digər fayllar"
    fi
}

# Main function
main() {
    print_header

    # Parse arguments
    BACKUP_TYPE="standard"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --full)
                BACKUP_TYPE="full"
                shift
                ;;
            --quick)
                BACKUP_TYPE="quick"
                shift
                ;;
            --help|-h)
                echo "İstifadə: ./scripts/backup.sh [--full|--quick]"
                echo ""
                echo "Parametrlər:"
                echo "  --full   Tam backup (logs, configs daxil)"
                echo "  --quick  Sürətli backup (yalnız database və uploads)"
                echo ""
                exit 0
                ;;
            *)
                print_error "Naməlum parametr: $1"
                echo "Kömək üçün: ./scripts/backup.sh --help"
                exit 1
                ;;
        esac
    done

    print_info "Backup növü: $BACKUP_TYPE"

    # Check containers
    check_containers

    # Create backup directory
    create_backup_dir

    # Perform backup based on type
    case $BACKUP_TYPE in
        "full")
            backup_database
            backup_files
            backup_volumes
            full_backup
            ;;
        "quick")
            backup_database
            backup_files
            ;;
        "standard"|*)
            backup_database
            backup_files
            backup_volumes
            ;;
    esac

    # Create metadata
    create_metadata

    # Create compressed archive
    create_archive

    # Verify backup
    verify_backup

    # Cleanup old backups
    cleanup_old_backups

    # Send notification (if configured)
    # send_notification

    # Show summary
    show_summary
}

# Error handling
trap 'print_error "Backup zamanı xəta baş verdi!"; exit 1' ERR

# Run main function
main "$@"