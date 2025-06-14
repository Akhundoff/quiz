#!/bin/bash

# Quiz System Deployment Script
echo "🚀 Quiz System Deployment"
echo "========================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found. Please run this script from the project root."
    exit 1
fi

# Backup before deployment
echo "💾 Creating backup before deployment..."
./scripts/backup.sh

# Pull latest changes (if using git)
if [ -d ".git" ]; then
    echo "📥 Pulling latest changes..."
    git pull origin main
fi

# Build new images
echo "🔨 Building new images..."
docker compose build --no-cache

# Stop current services
echo "⏹️ Stopping current services..."
docker compose down

# Start services
echo "▶️ Starting services..."
docker compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Health check
echo "🏥 Performing health check..."
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend is healthy"
else
    echo "❌ Frontend health check failed"
fi

if curl -f http://localhost:3001/api/quiz/questions > /dev/null 2>&1; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend health check failed"
fi

# Show status
echo "📊 Service status:"
docker compose ps

echo ""
echo "🎉 Deployment completed!"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend: http://localhost:3001"