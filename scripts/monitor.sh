#!/bin/bash

# Quiz System Monitoring Script
# Bu script sistemin statusunu izləyir və performans metrikalarını göstərir

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MONITOR_INTERVAL=5
CONTINUOUS_MODE=false

# Load environment variables
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${RED}❌ .env faylı tapılmadı!${NC}"
    exit 1
fi

# Functions
print_header() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                Quiz System - System Monitor                   ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}$(date '+%Y-%m-%d %H:%M:%S') | Domain: ${DOMAIN_NAME} | Environment: ${NODE_ENV}${NC}"
    echo ""
}

print_section() {
    echo -e "${PURPLE}▶ $1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_status() {
    local status=$1
    local message=$2

    case $status in
        "UP"|"HEALTHY")
            echo -e "  ${GREEN}✅ $message${NC}"
            ;;
        "DOWN"|"UNHEALTHY")
            echo -e "  ${RED}❌ $message${NC}"
            ;;
        "WARNING")
            echo -e "  ${YELLOW}⚠️  $message${NC}"
            ;;
        "INFO")
            echo -e "  ${BLUE}ℹ️  $message${NC}"
            ;;
        *)
            echo -e "  ${WHITE}• $message${NC}"
            ;;
    esac
}

# Show usage
show_usage() {
    echo "Quiz System Monitoring Script"
    echo ""
    echo "İstifadə: ./scripts/monitor.sh [options]"
    echo ""
    echo "Parametrlər:"
    echo "  -c, --continuous    Davamlı monitoring modu"
    echo "  -i, --interval N    Yeniləmə intervalı (saniyə, default: 5)"
    echo "  --json              JSON formatında output"
    echo "  --save-report       Monitoring hesabatını saxla"
    echo "  -h, --help          Bu kömək məlumatını göstər"
    echo ""
    echo "Nümunələr:"
    echo "  ./scripts/monitor.sh                    # Bir dəfə status yoxla"
    echo "  ./scripts/monitor.sh --continuous       # Davamlı monitoring"
    echo "  ./scripts/monitor.sh -c -i 10          # 10 saniyə interval ilə"
    echo "  ./scripts/monitor.sh --json            # JSON formatında"
    echo ""
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_status "DOWN" "Docker daemon işləmir"
        return 1
    fi
    print_status "UP" "Docker daemon işləyir"
    return 0
}

# Check container status
check_containers() {
    print_section "🐳 Container Status"

    local compose_file="docker-compose.yaml"
    if [[ "$NODE_ENV" == "production" ]]; then
        compose_file="docker-compose.prod.yaml"
    fi

    # Check if compose file exists
    if [[ ! -f "$PROJECT_ROOT/$compose_file" ]]; then
        print_status "WARNING" "Docker compose faylı tapılmadı: $compose_file"
        return 1
    fi

    # Get container status
    local containers=$(docker-compose -f "$PROJECT_ROOT/$compose_file" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null)

    if [[ -z "$containers" ]]; then
        print_status "WARNING" "Heç bir container işləmir"
        return 1
    fi

    # Parse container status
    echo "$containers" | tail -n +2 | while read -r line; do
        if [[ -n "$line" ]]; then
            local name=$(echo "$line" | awk '{print $1}')
            local status=$(echo "$line" | awk '{print $2}')
            local ports=$(echo "$line" | awk '{print $3}')

            case $status in
                *"Up"*|*"running"*)
                    if [[ "$CONTINUOUS_MODE" == true ]]; then
                        print_status "UP" "$name: Running"
                    else
                        print_status "UP" "$name: Running | Ports: $ports"
                    fi
                    ;;
                *"Exit"*|*"exited"*)
                    print_status "DOWN" "$name: Stopped"
                    ;;
                *)
                    print_status "WARNING" "$name: $status"
                    ;;
            esac
        fi
    done

    # Show container resource usage
    if [[ "$CONTINUOUS_MODE" == false ]]; then
        echo ""
        print_status "INFO" "Container resource istifadəsi:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null | while read -r line; do
            if [[ "$line" != *"NAME"* ]] && [[ -n "$line" ]]; then
                echo -e "    ${BLUE}$line${NC}"
            fi
        done
    fi
}

# Check service health
check_service_health() {
    print_section "🏥 Service Health"

    # Frontend health check
    if curl -f -m 5 "http://localhost:3000/health" >/dev/null 2>&1; then
        print_status "HEALTHY" "Frontend (port 3000)"
    else
        print_status "UNHEALTHY" "Frontend (port 3000)"
    fi

    # Backend health check
    if curl -f -m 5 "http://localhost:3001/api/quiz/questions" >/dev/null 2>&1; then
        print_status "HEALTHY" "Backend API (port 3001)"
    else
        print_status "UNHEALTHY" "Backend API (port 3001)"
    fi

    # Database health check
    local compose_file="docker-compose.yaml"
    if [[ "$NODE_ENV" == "production" ]]; then
        compose_file="docker-compose.prod.yaml"
    fi

    if docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" >/dev/null 2>&1; then
        print_status "HEALTHY" "MySQL Database"
    else
        print_status "UNHEALTHY" "MySQL Database"
    fi

    # phpMyAdmin health check
    if curl -f -m 5 "http://localhost:8082/" >/dev/null 2>&1; then
        print_status "HEALTHY" "phpMyAdmin (port 8082)"
    else
        print_status "UNHEALTHY" "phpMyAdmin (port 8082)"
    fi

    # Additional API endpoint checks
    if [[ "$CONTINUOUS_MODE" == false ]]; then
        echo ""
        print_status "INFO" "API endpoint testləri:"

        local api_endpoints=(
            "http://localhost:3001/api/docs:Swagger Docs"
            "http://localhost:3001/api/quiz/questions:Quiz Questions"
        )

        for endpoint_info in "${api_endpoints[@]}"; do
            local endpoint=$(echo "$endpoint_info" | cut -d: -f1)
            local name=$(echo "$endpoint_info" | cut -d: -f2)

            if curl -f -m 3 "$endpoint" >/dev/null 2>&1; then
                echo -e "    ${GREEN}✓${NC} $name"
            else
                echo -e "    ${RED}✗${NC} $name"
            fi
        done
    fi
}

# Check resource usage
check_resources() {
    print_section "📊 Resource Usage"

    # System resources
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}' 2>/dev/null || echo "0")
    local memory_info=$(free -h | grep "Mem:")
    local memory_used=$(echo $memory_info | awk '{print $3}')
    local memory_total=$(echo $memory_info | awk '{print $2}')
    local memory_percent=$(free | grep Mem | awk '{printf("%.1f"), $3/$2 * 100.0}')
    local disk_usage=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
    local disk_avail=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}')

    # CPU status
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        print_status "WARNING" "CPU Usage: ${cpu_usage}% (Yüksək)"
    else
        print_status "INFO" "CPU Usage: ${cpu_usage}%"
    fi

    # Memory status
    if (( $(echo "$memory_percent > 85" | bc -l) )); then
        print_status "WARNING" "Memory: $memory_used / $memory_total (${memory_percent}% - Yüksək)"
    else
        print_status "INFO" "Memory: $memory_used / $memory_total (${memory_percent}%)"
    fi

    # Disk status
    if [[ $disk_usage -gt 90 ]]; then
        print_status "WARNING" "Disk Usage: ${disk_usage}% (Kritik səviyyə!) - Boş: $disk_avail"
    elif [[ $disk_usage -gt 80 ]]; then
        print_status "WARNING" "Disk Usage: ${disk_usage}% (Yüksək) - Boş: $disk_avail"
    else
        print_status "INFO" "Disk Usage: ${disk_usage}% - Boş: $disk_avail"
    fi

    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{ print $2 }')
    print_status "INFO" "Load Average:$load_avg"

    # Docker resource usage (detailed)
    if [[ "$CONTINUOUS_MODE" == false ]]; then
        echo ""
        print_status "INFO" "Docker sistem istifadəsi:"
        docker system df --format "table {{.Type}}\t{{.Total}}\t{{.Active}}\t{{.Size}}\t{{.Reclaimable}}" 2>/dev/null | while read -r line; do
            echo -e "    ${BLUE}$line${NC}"
        done
    fi
}

# Check network connectivity
check_network() {
    print_section "🌐 Network Connectivity"

    # Network connectivity test (Docker container adı ilə)
    if docker exec quiz_backend ping -c 1 quiz_mysql >/dev/null 2>&1; then
        print_status "UP" "Backend ↔ MySQL şəbəkə bağlantısı"
    else
        print_status "DOWN" "Backend ↔ MySQL şəbəkə bağlantısı"
    fi

    # Port connectivity (netcat)
    if docker exec quiz_backend nc -z quiz_mysql 3306 >/dev/null 2>&1; then
        print_status "UP" "Backend ↔ MySQL port bağlantısı"
    else
        print_status "DOWN" "Backend ↔ MySQL port bağlantısı"
    fi

    # MySQL-dən birbaşa test
    if docker exec quiz_mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        print_status "UP" "MySQL database əlçatan"
    else
        print_status "DOWN" "MySQL database əlçatan deyil"
    fi

    # Test external connectivity
    if curl -f -m 5 "https://www.google.com" >/dev/null 2>&1; then
        print_status "UP" "İnternet bağlantısı"
    else
        print_status "DOWN" "İnternet bağlantısı"
    fi

    # Test domain resolution (production only)
    if [[ "$NODE_ENV" == "production" ]] && [[ "$DOMAIN_NAME" != "localhost" ]]; then
        if nslookup "$DOMAIN_NAME" >/dev/null 2>&1; then
            print_status "UP" "Domain resolution: $DOMAIN_NAME"
        else
            print_status "DOWN" "Domain resolution: $DOMAIN_NAME"
        fi

        # Test HTTPS if enabled
        if [[ "$PROTOCOL" == "https" ]]; then
            if curl -f -m 5 "https://$DOMAIN_NAME" >/dev/null 2>&1; then
                print_status "UP" "HTTPS bağlantısı: $DOMAIN_NAME"
            else
                print_status "DOWN" "HTTPS bağlantısı: $DOMAIN_NAME"
            fi
        fi
    fi

    # Network ports test
    if [[ "$CONTINUOUS_MODE" == false ]]; then
        echo ""
        print_status "INFO" "Port connectivity testləri:"

        local ports=("3000:Frontend" "3001:Backend" "3307:MySQL" "8082:phpMyAdmin")
        for port_info in "${ports[@]}"; do
            local port=$(echo "$port_info" | cut -d: -f1)
            local service=$(echo "$port_info" | cut -d: -f2)

            if nc -z localhost "$port" 2>/dev/null; then
                echo -e "    ${GREEN}✓${NC} Port $port ($service)"
            else
                echo -e "    ${RED}✗${NC} Port $port ($service)"
            fi
        done
    fi
}

# Check log files
check_logs() {
    print_section "📋 Recent Logs"

    # Backend logs
    if [[ -d "$PROJECT_ROOT/logs/backend" ]]; then
        local backend_errors=$(find "$PROJECT_ROOT/logs/backend" -name "*.log" -mtime -1 -exec grep -i "error" {} \; 2>/dev/null | wc -l)
        if [[ $backend_errors -gt 0 ]]; then
            print_status "WARNING" "Backend: $backend_errors error(s) son 24 saatda"
        else
            print_status "INFO" "Backend: Error yoxdur"
        fi
    fi

    # Docker logs errors
    local compose_file="docker-compose.yaml"
    if [[ "$NODE_ENV" == "production" ]]; then
        compose_file="docker-compose.prod.yaml"
    fi

    local docker_errors=$(docker-compose -f "$PROJECT_ROOT/$compose_file" logs --since=24h 2>/dev/null | grep -i "error\|fatal\|critical" | wc -l)
    if [[ $docker_errors -gt 0 ]]; then
        print_status "WARNING" "Docker: $docker_errors error(s) son 24 saatda"
    else
        print_status "INFO" "Docker: Kritik error yoxdur"
    fi

    # Show recent critical errors
    if [[ "$CONTINUOUS_MODE" == false ]]; then
        echo ""
        print_status "INFO" "Son kritik loglar:"
        docker-compose -f "$PROJECT_ROOT/$compose_file" logs --since=2h --tail=5 2>/dev/null | grep -i "error\|fatal\|critical" | tail -3 | while read -r line; do
            echo -e "    ${RED}$(echo "$line" | cut -c1-100)...${NC}"
        done

        # Log file sizes
        echo ""
        print_status "INFO" "Log fayl ölçüləri:"
        if [[ -d "$PROJECT_ROOT/logs" ]]; then
            du -sh "$PROJECT_ROOT/logs"/* 2>/dev/null | while read -r size path; do
                echo -e "    ${BLUE}$size\t$(basename "$path")${NC}"
            done
        fi
    fi
}

# Check database status
check_database() {
    print_section "🗄️ Database Status"

    local compose_file="docker-compose.yaml"
    if [[ "$NODE_ENV" == "production" ]]; then
        compose_file="docker-compose.prod.yaml"
    fi

    # Database connection
    if docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        print_status "UP" "Database bağlantısı"

        # Get database size
        local db_size=$(docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'Size_MB' FROM information_schema.tables WHERE table_schema='$DB_DATABASE';" 2>/dev/null | tail -1)
        print_status "INFO" "Database ölçüsü: ${db_size} MB"

        # Get connection count
        local connections=$(docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | tail -1 | awk '{print $2}')
        print_status "INFO" "Aktiv bağlantılar: $connections"

        # Get table counts and recent activity
        if [[ "$CONTINUOUS_MODE" == false ]]; then
            echo ""
            print_status "INFO" "Cədvəl statistikaları:"
            docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "
                SELECT table_name as 'Table', table_rows as 'Rows',
                       ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size_MB'
                FROM information_schema.tables
                WHERE table_schema='$DB_DATABASE'
                ORDER BY table_rows DESC;" 2>/dev/null | tail -n +2 | while read -r line; do
                if [[ -n "$line" ]]; then
                    echo -e "    ${BLUE}$line${NC}"
                fi
            done

            # Recent quiz sessions
            local recent_sessions=$(docker-compose -f "$PROJECT_ROOT/$compose_file" exec -T mysql mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM quiz_sessions WHERE started_at > DATE_SUB(NOW(), INTERVAL 24 HOUR);" 2>/dev/null | tail -1)
            print_status "INFO" "Son 24 saatda quiz sessionları: $recent_sessions"
        fi

    else
        print_status "DOWN" "Database bağlantısı uğursuz"
    fi
}

# Check SSL certificates (production only)
check_ssl() {
    if [[ "$NODE_ENV" == "production" ]] && [[ "$PROTOCOL" == "https" ]]; then
        print_section "🔒 SSL Certificate Status"

        local ssl_cert="/home/admin/conf/web/ssl.${DOMAIN_NAME}.pem"
        local ssl_key="/home/admin/conf/web/ssl.${DOMAIN_NAME}.key"

        if [[ -f "$ssl_cert" ]] && [[ -f "$ssl_key" ]]; then
            # Check certificate expiry
            local expiry_date=$(openssl x509 -in "$ssl_cert" -noout -enddate 2>/dev/null | cut -d= -f2)
            if [[ -n "$expiry_date" ]]; then
                local expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
                local current_timestamp=$(date +%s)
                local days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))

                if [[ $days_left -gt 30 ]]; then
                    print_status "UP" "SSL sertifikat aktiv ($days_left gün qalıb)"
                elif [[ $days_left -gt 7 ]]; then
                    print_status "WARNING" "SSL sertifikat tezliklə bitir ($days_left gün qalıb)"
                else
                    print_status "DOWN" "SSL sertifikat kritik vəziyyətdə ($days_left gün qalıb)"
                fi

                # Certificate details
                if [[ "$CONTINUOUS_MODE" == false ]]; then
                    local issuer=$(openssl x509 -in "$ssl_cert" -noout -issuer 2>/dev/null | cut -d= -f2-)
                    print_status "INFO" "Sertifikat verən: $issuer"
                fi
            else
                print_status "WARNING" "SSL sertifikat məlumatları oxuna bilmir"
            fi
        else
            print_status "DOWN" "SSL sertifikat faylları tapılmadı"
        fi
    fi
}

# Show URLs and access information
show_access_info() {
    print_section "🔗 Access Information"

    if [[ "$NODE_ENV" == "production" ]]; then
        print_status "INFO" "🌐 Frontend: ${PROTOCOL}://${DOMAIN_NAME}"
        print_status "INFO" "🔧 Backend API: ${PROTOCOL}://${DOMAIN_NAME}/api"
        print_status "INFO" "📚 API Docs: ${PROTOCOL}://${DOMAIN_NAME}/api/docs"
        print_status "INFO" "🗄️  phpMyAdmin: ${PROTOCOL}://${DOMAIN_NAME}/phpmyadmin"
    else
        print_status "INFO" "🌐 Frontend: http://localhost:3000"
        print_status "INFO" "🔧 Backend API: http://localhost:3001"
        print_status "INFO" "📚 API Docs: http://localhost:3001/api/docs"
        print_status "INFO" "🗄️  phpMyAdmin: http://localhost:8082"
    fi

    if [[ "$CONTINUOUS_MODE" == false ]]; then
        echo ""
        print_status "INFO" "🔑 Admin Giriş: username=admin, password=admin123"
    fi
}

# Show quick actions
show_quick_actions() {
    print_section "⚡ Quick Actions"

    echo -e "  ${CYAN}1.${NC} make logs          - Logları izlə"
    echo -e "  ${CYAN}2.${NC} make restart       - Sistemi yenidən başlat"
    echo -e "  ${CYAN}3.${NC} make db-backup     - Database backup yarat"
    echo -e "  ${CYAN}4.${NC} make clean         - Cache təmizlə"
    echo -e "  ${CYAN}5.${NC} make status        - Container statusu"
    echo -e "  ${CYAN}6.${NC} make health        - Health check"
    echo ""
    echo -e "  ${YELLOW}Ctrl+C${NC} - Monitoring-dən çıx"

    if [[ "$CONTINUOUS_MODE" == true ]]; then
        echo ""
        echo -e "  ${PURPLE}Növbəti yeniləmə: $MONITOR_INTERVAL saniyə...${NC}"
    fi
}

# Generate monitoring report
generate_monitoring_report() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="$PROJECT_ROOT/logs/monitoring_report_${timestamp}.json"

    # Create monitoring report
    cat > "$report_file" << EOF
{
    "monitoring_date": "$(date -Iseconds)",
    "domain": "$DOMAIN_NAME",
    "environment": "$NODE_ENV",
    "protocol": "$PROTOCOL",
    "system_info": {
        "cpu_usage": "$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}' 2>/dev/null || echo "0")",
        "memory_usage": "$(free | grep Mem | awk '{printf("%.1f"), $3/$2 * 100.0}')",
        "disk_usage": "$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')",
        "load_average": "$(uptime | awk -F'load average:' '{ print $2 }' | xargs)"
    },
    "services": {
        "frontend": "$(curl -f -m 3 "http://localhost:3000/health" >/dev/null 2>&1 && echo "UP" || echo "DOWN")",
        "backend": "$(curl -f -m 3 "http://localhost:3001/api/quiz/questions" >/dev/null 2>&1 && echo "UP" || echo "DOWN")",
        "database": "$(docker-compose -f "$PROJECT_ROOT/docker-compose.yaml" exec -T mysql mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" >/dev/null 2>&1 && echo "UP" || echo "DOWN")",
        "phpmyadmin": "$(curl -f -m 3 "http://localhost:8082/" >/dev/null 2>&1 && echo "UP" || echo "DOWN")"
    },
    "containers": {
        "running": "$(docker-compose -f "$PROJECT_ROOT/docker-compose.yaml" ps -q 2>/dev/null | wc -l)",
        "total": "$(docker-compose -f "$PROJECT_ROOT/docker-compose.yaml" config --services 2>/dev/null | wc -l)"
    }
}
EOF

    echo "$report_file"
}

# JSON output mode
json_output() {
    local report_file=$(generate_monitoring_report)
    cat "$report_file"
    rm -f "$report_file"
}

# Main monitoring function
run_monitor() {
    if ! check_docker; then
        echo -e "${RED}Docker məsələləri səbəbindən monitoring dayandırılır${NC}"
        exit 1
    fi

    check_containers
    echo ""

    check_service_health
    echo ""

    check_resources
    echo ""

    check_network
    echo ""

    check_database
    echo ""

    check_ssl
    echo ""

    check_logs
    echo ""

    show_access_info
    echo ""

    if [[ "$CONTINUOUS_MODE" == true ]]; then
        show_quick_actions
    fi
}

# Continuous monitoring mode
continuous_monitor() {
    CONTINUOUS_MODE=true

    echo -e "${CYAN}🔄 Davamlı monitoring modu başladılır...${NC}"
    echo -e "${YELLOW}Interval: $MONITOR_INTERVAL saniyə${NC}"
    echo ""

    while true; do
        print_header
        run_monitor

        sleep $MONITOR_INTERVAL
    done
}

# Main function
main() {
    # Parse arguments
    local json_mode=false
    local save_report=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --continuous|-c)
                continuous_monitor
                exit 0
                ;;
            --interval|-i)
                MONITOR_INTERVAL="$2"
                if ! [[ "$MONITOR_INTERVAL" =~ ^[0-9]+$ ]] || [[ "$MONITOR_INTERVAL" -lt 1 ]]; then
                    echo -e "${RED}Interval müsbət tam ədəd olmalıdır${NC}"
                    exit 1
                fi
                shift 2
                ;;
            --json)
                json_mode=true
                shift
                ;;
            --save-report)
                save_report=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}Naməlum parametr: $1${NC}"
                echo "Kömək üçün: ./scripts/monitor.sh --help"
                exit 1
                ;;
        esac
    done

    # Handle different output modes
    if [[ "$json_mode" == true ]]; then
        json_output
        exit 0
    fi

    # Single run mode
    print_header
    run_monitor

    # Save report if requested
    if [[ "$save_report" == true ]]; then
        mkdir -p "$PROJECT_ROOT/logs"
        local report_file=$(generate_monitoring_report)
        echo ""
        echo -e "${GREEN}📝 Monitoring hesabatı saxlanıldı: $report_file${NC}"
    fi
}

# Error handling
trap 'echo -e "\n${RED}Monitoring dayandırıldı${NC}"; exit 0' INT TERM

# Run main function
main "$@"