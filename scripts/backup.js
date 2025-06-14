const { execSync } = require('child_process');
const fs = require('fs');

console.log('💾 Creating database backup...');

// Create backup directory if it doesn't exist
if (!fs.existsSync('backups')) {
    fs.mkdirSync('backups');
}

// Get current date and time
const now = new Date();
const timestamp = now.toISOString().replace(/[:.]/g, '-').slice(0, 19);
const backupFile = `backups/backup_${timestamp}.sql`;

try {
    // Check if Docker containers are running
    execSync('docker-compose ps', { stdio: 'pipe' });

    // Create database backup
    execSync(`docker-compose exec -T mysql mysqldump -u quiz_user -pquiz_password quiz_system > ${backupFile}`, { stdio: 'inherit' });

    console.log(`✅ Backup created: ${backupFile}`);

    // Keep only last 10 backups
    const backupFiles = fs.readdirSync('backups')
        .filter(file => file.startsWith('backup_') && file.endsWith('.sql'))
        .sort()
        .reverse();

    if (backupFiles.length > 10) {
        const filesToDelete = backupFiles.slice(10);
        filesToDelete.forEach(file => {
            fs.unlinkSync(path.join('backups', file));
            console.log(`🗑️ Deleted old backup: ${file}`);
        });
    }

} catch (error) {
    console.error('❌ Backup failed:', error.message);
    console.log('Make sure Docker containers are running: npm run start');
}