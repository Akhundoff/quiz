#!/bin/bash

# Quiz System Restore Script
if [ -z "$1" ]; then
    echo "Usage: ./scripts/restore.sh <backup_file.tar.gz>"
    echo ""
    echo "Available backups:"
    ls -la backups/quiz_backup_*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"
RESTORE_DIR="restore_temp"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "🔄 Restoring from: $BACKUP_FILE"

# Create temporary restore directory
mkdir -p $RESTORE_DIR

# Extract backup
echo "📦 Extracting backup..."
tar -xzf "$BACKUP_FILE" -C $RESTORE_DIR

# Stop services
echo "⏹️ Stopping services..."
docker compose down

# Restore database
echo "📊 Restoring database..."
docker compose up -d mysql
sleep 10

# Find the database file
DB_FILE=$(find $RESTORE_DIR -name "*_database.sql" | head -1)
if [ -f "$DB_FILE" ]; then
    docker compose exec -T mysql mysql -u quiz_user -pquiz_password quiz_system < "$DB_FILE"
    echo "✅ Database restored"
else
    echo "❌ Database backup file not found"
fi

# Restore environment files (optional - ask user)
echo ""
read -p "Do you want to restore environment files? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ENV_FILE=$(find $RESTORE_DIR -name "*_env" | grep -v backend | grep -v frontend | head -1)
    BACKEND_ENV_FILE=$(find $RESTORE_DIR -name "*_backend_env" | head -1)
    FRONTEND_ENV_FILE=$(find $RESTORE_DIR -name "*_frontend_env" | head -1)

    [ -f "$ENV_FILE" ] && cp "$ENV_FILE" .env && echo "✅ Main .env restored"
    [ -f "$BACKEND_ENV_FILE" ] && cp "$BACKEND_ENV_FILE" backend/.env && echo "✅ Backend .env restored"
    [ -f "$FRONTEND_ENV_FILE" ] && cp "$FRONTEND_ENV_FILE" frontend/.env && echo "✅ Frontend .env restored"
fi

# Start all services
echo "▶️ Starting all services..."
docker compose up -d

# Clean up
rm -rf $RESTORE_DIR

echo ""
echo "🎉 Restore completed!"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend: http://localhost:3001"