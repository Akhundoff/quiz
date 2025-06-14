Write-Host "🚀 Starting Quiz System..." -ForegroundColor Green
docker-compose up -d
Write-Host "✅ Services started!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Access URLs:" -ForegroundColor Blue
Write-Host "  🌐 Frontend: http://localhost:3000"
Write-Host "  🔧 Backend API: http://localhost:3001"
Write-Host "  📚 API Documentation: http://localhost:3001/api/docs"
Write-Host "  🗄️ MySQL: localhost:3306"
Write-Host ""
Write-Host "🔑 Admin Login:" -ForegroundColor Blue
Write-Host "  Username: admin"
Write-Host "  Password: admin123"
Read-Host "Press Enter to continue"