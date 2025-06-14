@echo off
echo 🔨 Building Docker containers...
docker-compose build --no-cache
echo ✅ Build completed!
pause