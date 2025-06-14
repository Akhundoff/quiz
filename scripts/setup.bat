@echo off
echo 🚀 Quiz System Setup Script
echo ================================

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

echo ✅ Docker and Docker Compose are installed

REM Create necessary directories
echo 📁 Creating directories...
if not exist "backups" mkdir backups
if not exist "logs" mkdir logs
if not exist "nginx\ssl" mkdir nginx\ssl

REM Setup environment files
echo ⚙️ Setting up environment files...

if not exist ".env" (
    copy .env.example .env
    echo ✅ Created .env file
) else (
    echo ⚠️ .env file already exists
)

if not exist "backend\.env" (
    copy backend\.env.example backend\.env
    echo ✅ Created backend\.env file
) else (
    echo ⚠️ backend\.env file already exists
)

if not exist "frontend\.env" (
    copy frontend\.env.example frontend\.env
    echo ✅ Created frontend\.env file
) else (
    echo ⚠️ frontend\.env file already exists
)

echo.
echo 🎉 Setup completed successfully!
echo.
echo 📋 Next steps:
echo 1. Review and modify .env files if needed
echo 2. Run: npm run build
echo 3. Run: npm run start
echo.
echo 🔗 Access URLs:
echo   🌐 Frontend: http://localhost:3000
echo   🔧 Backend: http://localhost:3001
echo   📚 API Docs: http://localhost:3001/api/docs
echo.
echo 🔑 Admin Login:
echo   Username: admin
echo   Password: admin123
echo.
pause