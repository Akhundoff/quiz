const { execSync } = require('child_process');

const commands = {
    build: () => {
        console.log('🔨 Building Docker containers...');
        execSync('docker compose build --no-cache', { stdio: 'inherit' });
        console.log('✅ Build completed!');
    },

    start: () => {
        console.log('🚀 Starting Quiz System...');
        execSync('docker compose up -d', { stdio: 'inherit' });
        console.log('✅ Services started!');
        console.log('');
        console.log('📍 Access URLs:');
        console.log('  🌐 Frontend: http://localhost:3000');
        console.log('  🔧 Backend API: http://localhost:3001');
        console.log('  📚 API Documentation: http://localhost:3001/api/docs');
    },

    stop: () => {
        console.log('⏹️ Stopping services...');
        execSync('docker compose down', { stdio: 'inherit' });
        console.log('✅ Services stopped!');
    },

    logs: () => {
        console.log('📝 Showing logs...');
        execSync('docker compose logs -f', { stdio: 'inherit' });
    },

    status: () => {
        console.log('📊 Service Status:');
        execSync('docker compose ps', { stdio: 'inherit' });
    }
};

const command = process.argv[2];
if (commands[command]) {
    commands[command]();
} else {
    console.log('Available commands: build, start, stop, logs, status');
}