#!/bin/bash

# Quiz System Monitoring Script
echo "📊 Quiz System Monitor"
echo "====================="

# Function to check service health
check_service() {
    local service_name=$1
    local url=$2
    local expected_code=${3:-200}

    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)

    if [ "$response_code" = "$expected_code" ]; then
        echo "✅ $service_name: Healthy ($response_code)"
        return 0
    else
        echo "❌ $service_name: Unhealthy ($response_code)"
        return 1
    fi
}

# Function to check Docker container status
check_container() {
    local container_name=$1
    local status=$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null)

    if [ "$status" = "running" ]; then
        echo "✅ Container $container_name: Running"
        return 0
    else
        echo "❌ Container $container_name: $status"
        return 1
    fi
}

# Check Docker containers
echo "🐳 Docker Container Status:"
check_container "quiz_frontend"
check_container "quiz_backend"
check_container "quiz_mysql"

echo ""

# Check HTTP services
echo "🌐 HTTP Service Health:"
check_service "Frontend" "http://localhost:3000"
check_service "Backend API" "http://localhost:3001/api/quiz/questions"
check_service "API Documentation" "http://localhost:3001/api/docs"

echo ""

# Check database connectivity
echo "🗄️ Database Connectivity:"
if docker-compose exec mysql mysqladmin -u quiz_user -pquiz_password ping -h localhost >/dev/null 2>&1; then
    echo "✅ MySQL: Connected"
else
    echo "❌ MySQL: Connection failed"
fi

echo ""

# System resources
echo "💻 System Resources:"
echo "Memory Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" quiz_frontend quiz_backend quiz_mysql

echo ""

# Disk usage
echo "💾 Disk Usage:"
echo "Total disk usage: $(df -h . | awk 'NR==2{print $3"/"$2" ("$5")"}')"
echo "Docker volumes:"
docker system df

echo ""

# Recent logs (last 10 lines)
echo "📝 Recent Activity (Last 10 log entries):"
echo "--- Backend ---"
docker-compose logs --tail=5 backend 2>/dev/null | tail -5
echo "--- Frontend ---"
docker-compose logs --tail=5 frontend 2>/dev/null | tail -5

echo ""
echo "✅ Monitoring completed at $(date)"