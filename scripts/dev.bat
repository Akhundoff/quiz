@echo off
echo 🔧 Starting development servers...
echo Backend: http://localhost:3001
echo Frontend: http://localhost:3000
echo API Docs: http://localhost:3001/api/docs
echo.
echo Press Ctrl+C to stop
start "Backend" cmd /k "cd backend && npm run start:dev"
start "Frontend" cmd /k "cd frontend && npm start"