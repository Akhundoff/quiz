const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Quiz System Setup Script');
console.log('================================');

// Check Docker installation
try {
    execSync('docker --version', { stdio: 'pipe' });
    execSync('docker compose --version', { stdio: 'pipe' });
    console.log('✅ Docker and Docker Compose are installed');
} catch (error) {
    console.log('❌ Docker is not installed. Please install Docker Desktop first.');
    process.exit(1);
}

// Create directories
console.log('📁 Creating directories...');
const dirs = ['backups', 'logs', 'nginx/ssl'];
dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

// Setup environment files
console.log('⚙️ Setting up environment files...');

const envFiles = [
    { src: '.env.example', dest: '.env' },
    { src: 'backend/.env.example', dest: 'backend/.env' },
    { src: 'frontend/.env.example', dest: 'frontend/.env' }
];

envFiles.forEach(({ src, dest }) => {
    if (!fs.existsSync(dest)) {
        fs.copyFileSync(src, dest);
        console.log(`✅ Created ${dest} file`);
    } else {
        console.log(`⚠️ ${dest} file already exists`);
    }
});

console.log('');
console.log('🎉 Setup completed successfully!');
console.log('');
console.log('📋 Next steps:');
console.log('1. Review and modify .env files if needed');
console.log('2. Run: npm run build');
console.log('3. Run: npm run start');
console.log('');
console.log('🔗 Access URLs:');
console.log('  🌐 Frontend: http://localhost:3000');
console.log('  🔧 Backend: http://localhost:3001');
console.log('  📚 API Docs: http://localhost:3001/api/docs');
console.log('');
console.log('🔑 Admin Login:');
console.log('  Username: admin');
console.log('  Password: admin123');
