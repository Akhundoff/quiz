const { execSync } = require('child_process');

console.log('🏥 Health Check:');

// Function to check HTTP endpoint
function checkEndpoint(name, url) {
    try {
        const command = process.platform === 'win32'
            ? `powershell -Command "(Invoke-WebRequest -Uri '${url}' -UseBasicParsing).StatusCode"`
            : `curl -s -o /dev/null -w "%{http_code}" ${url}`;

        const statusCode = execSync(command, { encoding: 'utf8' }).trim();

        if (statusCode === '200') {
            console.log(`✅ ${name}: Healthy (${statusCode})`);
            return true;
        } else {
            console.log(`❌ ${name}: Unhealthy (${statusCode})`);
            return false;
        }
    } catch (error) {
        console.log(`❌ ${name}: DOWN`);
        return false;
    }
}
// Function to check Docker container
function checkContainer(containerName) {
    try {
        const status = execSync(`docker inspect -f '{{.State.Status}}' ${containerName}`, { encoding: 'utf8' }).trim();

        if (status === 'running') {
            console.log(`✅ Container ${containerName}: Running`);
            return true;
        } else {
            console.log(`❌ Container ${containerName}: ${status}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ Container ${containerName}: Not found`);
        return false;
    }
}

// Check Docker containers
console.log('\n🐳 Docker Container Status:');
const frontendOk = checkContainer('quiz_frontend');
const backendOk = checkContainer('quiz_backend');
const mysqlOk = checkContainer('quiz_mysql');

// Check HTTP services
console.log('\n🌐 HTTP Service Health:');
const frontendHttpOk = checkEndpoint('Frontend', 'http://localhost:3000');
const backendHttpOk = checkEndpoint('Backend API', 'http://localhost:3001/api/quiz/questions');
const docsOk = checkEndpoint('API Documentation', 'http://localhost:3001/api/docs');

// Check database connectivity
console.log('\n🗄️ Database Connectivity:');
try {
    execSync('docker compose exec mysql mysqladmin -u quiz_user -pquiz_password ping -h localhost', { stdio: 'pipe' });
    console.log('✅ MySQL: Connected');
} catch (error) {
    console.log('❌ MySQL: Connection failed');
}

// Summary
console.log('\n📊 Summary:');
const allHealthy = frontendOk && backendOk && mysqlOk && frontendHttpOk && backendHttpOk;

if (allHealthy) {
    console.log('🎉 All services are healthy!');
    console.log('\n📍 Access URLs:');
    console.log('  🌐 Frontend: http://localhost:3000');
    console.log('  🔧 Backend API: http://localhost:3001');
    console.log('  📚 API Documentation: http://localhost:3001/api/docs');
    console.log('\n🔑 Admin Login:');
    console.log('  Username: admin');
    console.log('  Password: admin123');
} else {
    console.log('⚠️ Some services have issues. Try:');
    console.log('  npm run restart');
    console.log('  npm run logs');
}