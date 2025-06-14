#!/bin/bash

# Quiz System Cleanup Script
echo "🧹 Quiz System Cleanup"
echo "====================="

# Warning
echo "⚠️  WARNING: This will remove all containers, images, and volumes!"
echo "⚠️  Make sure you have backups before proceeding!"
echo ""
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

# Stop all services
echo "⏹️ Stopping all services..."
docker compose down

# Remove containers
echo "🗑️ Removing containers..."
docker compose rm -f

# Remove images
echo "🖼️ Removing images..."
docker rmi quiz-system_backend quiz-system_frontend 2>/dev/null || true

# Remove volumes (be careful!)
echo "💽 Removing volumes..."
read -p "Do you want to remove database volumes? (This will delete all data!) [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker compose down -v
    docker volume prune -f
    echo "✅ Volumes removed"
else
    echo "⏭️ Volumes preserved"
fi

# Clean Docker system
echo "🧽 Cleaning Docker system..."
docker system prune -f

# Clean build artifacts
echo "🔨 Cleaning build artifacts..."
rm -rf backend/dist/
rm -rf frontend/build/
rm -rf backend/node_modules/.cache/
rm -rf frontend/node_modules/.cache/

# Clean logs
echo "📝 Cleaning logs..."
rm -rf logs/*.log

echo ""
echo "✅ Cleanup completed!"
echo "📋 To start fresh:"
echo "1. Run: make install"
echo "2. Run: make build"
echo "3. Run: make start"