#!/bin/bash

# Quiz System Backup Script
BACKUP_DIR="backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="quiz_backup_$TIMESTAMP"

echo "💾 Creating backup: $BACKUP_FILE"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Database backup
echo "📊 Backing up database..."
docker compose exec -T mysql mysqldump -u quiz_user -pquiz_password quiz_system > "$BACKUP_DIR/${BACKUP_FILE}_database.sql"

# Environment files backup
echo "⚙️ Backing up configuration..."
cp .env "$BACKUP_DIR/${BACKUP_FILE}_env"
cp backend/.env "$BACKUP_DIR/${BACKUP_FILE}_backend_env"
cp frontend/.env "$BACKUP_DIR/${BACKUP_FILE}_frontend_env"

# Create tar archive
echo "📦 Creating archive..."
tar -czf "$BACKUP_DIR/${BACKUP_FILE}.tar.gz" -C $BACKUP_DIR "${BACKUP_FILE}_database.sql" "${BACKUP_FILE}_env" "${BACKUP_FILE}_backend_env" "${BACKUP_FILE}_frontend_env"

# Clean up individual files
rm "$BACKUP_DIR/${BACKUP_FILE}_database.sql" "$BACKUP_DIR/${BACKUP_FILE}_env" "$BACKUP_DIR/${BACKUP_FILE}_backend_env" "$BACKUP_DIR/${BACKUP_FILE}_frontend_env"

echo "✅ Backup completed: $BACKUP_DIR/${BACKUP_FILE}.tar.gz"

# Keep only last 10 backups
echo "🧹 Cleaning old backups..."
cd $BACKUP_DIR
ls -t quiz_backup_*.tar.gz | tail -n +11 | xargs -r rm
cd ..

echo "📈 Backup statistics:"
echo "  Size: $(du -h $BACKUP_DIR/${BACKUP_FILE}.tar.gz | cut -f1)"
echo "  Location: $BACKUP_DIR/${BACKUP_FILE}.tar.gz"
echo "  Total backups: $(ls $BACKUP_DIR/quiz_backup_*.tar.gz 2>/dev/null | wc -l)"
