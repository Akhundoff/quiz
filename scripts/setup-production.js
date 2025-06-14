const fs = require('fs');
const { execSync } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

console.log('🚀 Production Setup Script');
console.log('==========================');

rl.question('Enter your domain name (e.g., quiz.example.com): ', (domain) => {
    if (!domain) {
        console.log('❌ Domain name is required');
        rl.close();
        return;
    }

    rl.question('Enter protocol (http/https) [https]: ', (protocol) => {
        protocol = protocol || 'https';

        console.log(`🔧 Setting up production environment for: ${protocol}://${domain}`);

        // Generate secrets
        const jwtSecret = execSync('node -e "console.log(require(\'crypto\').randomBytes(32).toString(\'base64\'))"', { encoding: 'utf8' }).trim();
        const dbPassword = execSync('node -e "console.log(require(\'crypto\').randomBytes(16).toString(\'base64\').replace(/[^a-zA-Z0-9]/g, \'\').slice(0, 16))"', { encoding: 'utf8' }).trim();
        const rootPassword = execSync('node -e "console.log(require(\'crypto\').randomBytes(16).toString(\'base64\').replace(/[^a-zA-Z0-9]/g, \'\').slice(0, 16))"', { encoding: 'utf8' }).trim();

        // Create production environment
        const prodEnv = `# Production Environment - Auto-generated
DB_HOST=mysql
DB_PORT=3306
DB_USERNAME=quiz_user
DB_PASSWORD=${dbPassword}
DB_DATABASE=quiz_system

JWT_SECRET=${jwtSecret}

NODE_ENV=production
PORT=3001

DOMAIN_NAME=${domain}
PROTOCOL=${protocol}
FRONTEND_URL=${protocol}://${domain}
BACKEND_URL=${protocol}://${domain}
API_URL=${protocol}://${domain}/api
CORS_ORIGINS=${protocol}://${domain}

MYSQL_ROOT_PASSWORD=${rootPassword}
`;

        // Write production environment files
        fs.writeFileSync('.env.production', prodEnv);
        fs.writeFileSync('backend/.env.production', prodEnv);

        const frontendProdEnv = `REACT_APP_API_URL=${protocol}://${domain}/api
REACT_APP_BACKEND_URL=${protocol}://${domain}
REACT_APP_FRONTEND_URL=${protocol}://${domain}
REACT_APP_NAME=Quiz System
REACT_APP_VERSION=1.0.0
`;
        fs.writeFileSync('frontend/.env.production', frontendProdEnv);

        console.log('✅ Production environment files created!');
        console.log(`🌐 Your quiz system will be available at: ${protocol}://${domain}`);
        console.log('');
        console.log('📋 Next steps:');
        console.log('1. Copy .env.production to .env');
        console.log('2. Copy backend/.env.production to backend/.env');
        console.log('3. Copy frontend/.env.production to frontend/.env');
        console.log('4. Run: npm run build');
        console.log('5. Run: npm run start');

        rl.close();
    });
});