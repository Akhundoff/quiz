Write-Host "🚀 Quiz System Setup Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Check Docker installation
try {
    docker --version | Out-Null
    docker-compose --version | Out-Null
    Write-Host "✅ Docker and Docker Compose are installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not installed. Please install Docker Desktop first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create directories
Write-Host "📁 Creating directories..." -ForegroundColor Blue
New-Item -ItemType Directory -Force -Path "backups", "logs", "nginx/ssl" | Out-Null

# Setup environment files
Write-Host "⚙️ Setting up environment files..." -ForegroundColor Blue

if (!(Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "✅ Created .env file" -ForegroundColor Green
} else {
    Write-Host "⚠️ .env file already exists" -ForegroundColor Yellow
}

if (!(Test-Path "backend/.env")) {
    Copy-Item "backend/.env.example" "backend/.env"
    Write-Host "✅ Created backend/.env file" -ForegroundColor Green
} else {
    Write-Host "⚠️ backend/.env file already exists" -ForegroundColor Yellow
}

if (!(Test-Path "frontend/.env")) {
    Copy-Item "frontend/.env.example" "frontend/.env"
    Write-Host "✅ Created frontend/.env file" -ForegroundColor Green
} else {
    Write-Host "⚠️ frontend/.env file already exists" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Blue
Write-Host "1. Review and modify .env files if needed"
Write-Host "2. Run: npm run build"
Write-Host "3. Run: npm run start"
Write-Host ""
Write-Host "🔗 Access URLs:" -ForegroundColor Blue
Write-Host "  🌐 Frontend: http://localhost:3000"
Write-Host "  🔧 Backend: http://localhost:3001"
Write-Host "  📚 API Docs: http://localhost:3001/api/docs"
Write-Host ""
Write-Host "🔑 Admin Login:" -ForegroundColor Blue
Write-Host "  Username: admin"
Write-Host "  Password: admin123"
Read-Host "Press Enter to continue"