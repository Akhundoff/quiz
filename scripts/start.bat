@echo off
echo 🚀 Starting Quiz System...
docker-compose up -d
echo ✅ Services started!
echo.
echo 📍 Access URLs:
echo   🌐 Frontend: http://localhost:3000
echo   🔧 Backend API: http://localhost:3001
echo   📚 API Documentation: http://localhost:3001/api/docs
echo   🗄️ MySQL: localhost:3306
echo.
echo 🔑 Admin Login:
echo   Username: admin
echo   Password: admin123
pause