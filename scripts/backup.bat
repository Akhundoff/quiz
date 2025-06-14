@echo off
echo 💾 Creating database backup...
if not exist "backups" mkdir backups

REM Get current date and time
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set mytime=%mytime: =0%

set backup_file=backups\backup_%mydate%_%mytime%.sql

docker compose exec -T mysql mysqldump -u quiz_user -pquiz_password quiz_system > %backup_file%
echo ✅ Backup created: %backup_file%
pause

# scripts/clean.bat
@echo off
echo 🧹 Cleaning up...
echo ⚠️ WARNING: This will remove all containers, images, and volumes!
set /p "confirm=Are you sure? [y/N]: "
if /i "%confirm%" neq "y" (
    echo ❌ Operation cancelled.
    pause
    exit /b 0
)

docker compose down -v
docker system prune -f
docker volume prune -f
echo ✅ Cleanup completed!
pause