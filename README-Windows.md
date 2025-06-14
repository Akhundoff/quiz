# Quiz System - Windows Setup Guide

## Tez Başlanğıc

### 1. Prerequisites
- Docker Desktop for Windows yükləyin: https://docs.docker.com/desktop/windows/install/
- Node.js yükləyin: https://nodejs.org/

### 2. Method 1: NPM Scripts (Tövsiyə edilir)

```bash
# Repository klonlayın
git clone <repository-url>
cd quiz-system

# Root directory-də package.json yaradın (yuxarıdakı kontent ilə)
# Dependencies yükləyin
npm install

# Quick start
npm run quick-start
```

### 3. Method 2: Batch Scripts

```cmd
# Setup
scripts\setup.bat

# Build və Start
scripts\build.bat
scripts\start.bat

# Logs görmək
scripts\logs.bat

# Dayandırmaq
scripts\stop.bat
```

### 4. Method 3: PowerShell Scripts

```powershell
# Setup
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1

# Start
powershell -ExecutionPolicy Bypass -File scripts\start.ps1
```

### 5. Method 4: Manual Commands

```cmd
# Environment setup
copy .env.example .env
copy backend\.env.example backend\.env
copy frontend\.env.example frontend\.env

# Docker commands
docker compose build
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

## Development Mode

```bash
# Terminal 1 - Backend
cd backend
npm install
npm run start:dev

# Terminal 2 - Frontend  
cd frontend
npm install
npm start
```

## Troubleshooting

### Docker Issues:
- Docker Desktop işə salın
- Hyper-V aktivləşdirin (Windows Pro)
- WSL2 backend istifadə edin

### Port Issues:
- Port 3000 və 3001 boş olduğundan əmin olun
- `netstat -ano | findstr :3000` ilə yoxlayın

### Permission Issues:
- PowerShell scriptləri üçün execution policy dəyişin:
  `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`