# Quiz System

Modern, responsive quiz sistemi - NestJS, React, MySQL və Docker ilə hazırlanmışdır.

## 🚀 Xüsusiyyətləri

- **Modern UI/UX**: Responsive dizayn, smooth animasiyalar
- **Admin Panel**: Sualları idarə etmək və cavabları analiz etmək
- **Real-time Data**: Hər cavab dərhal saxlanılır
- **Export Functionality**: CSV formatında məlumat ixracı
- **Docker Support**: Asan quraşdırma və deployment
- **API Documentation**: Swagger ilə tam dokumentasiya
- **Security**: JWT authentication, CORS qorunması
- **Auto Backup**: Avtomatik backup və restore sistemi

## 📋 Tələblər

- Docker və Docker Compose
- Node.js 18+ (development üçün)
- Git

## 🏁 Tez Başlanğıc

### 1. Repository-ni klonlayın
```bash
git clone <repository-url>
cd quiz-system
```

### 2. Avtomatik quraşdırma
```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

**və ya manual olaraq:**
```bash
cp .env.example .env
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

### 3. Sistemi başladın
```bash
make quick-start
```

**və ya addım-addım:**
```bash
make install  # Dependencies yükləyin
make build    # Docker containers build edin
make start    # Sistemi başladın
```

## 🔗 Əlaqələr

Sistem işə düşdükdən sonra:

- **🌐 Frontend**: http://localhost:3000
- **🔧 Backend API**: http://localhost:3001
- **📚 API Docs**: http://localhost:3001/api/docs
- **🗄️ MySQL**: localhost:3306

## 🔑 Admin Girişi

- **Username**: `admin`
- **Password**: `admin123`

Admin paneli: http://localhost:3000/admin

## 📁 Layihə Strukturu

```
quiz-system/
├── backend/               # NestJS API
│   ├── src/
│   │   ├── modules/      # Quiz, Admin, Auth modulları
│   │   ├── entities/     # Database entities
│   │   └── dto/          # Data transfer objects
│   └── Dockerfile
├── frontend/             # React UI
│   ├── src/
│   │   ├── components/   # UI komponentləri
│   │   ├── pages/        # Səhifələr
│   │   └── services/     # API xidmətləri
│   └── Dockerfile
├── scripts/              # Automation scripts
│   ├── setup.sh         # Initial setup
│   ├── backup.sh        # Database backup
│   ├── deploy.sh        # Production deployment
│   ├── restore.sh       # Restore from backup
│   ├── monitor.sh       # System monitoring
│   └── cleanup.sh       # System cleanup
├── nginx/               # Reverse proxy config
├── database/            # DB initialization
├── docker-compose.yml   # Docker konfiqurasiyası
├── Makefile            # Əməliyyat komandaları
└── README.md
```

## 🛠️ Development

### Development mode başladın
```bash
make dev
```

Bu komanda:
- Backend-i http://localhost:3001 ünvanında işə salır
- Frontend-i http://localhost:3000 ünvanında işə salır
- Hot reload aktivləşdirir

### Test etmək
```bash
make test-backend    # Backend testləri
make test-frontend   # Frontend testləri
```

## 🔧 Sistem İdarəetməsi

### Database əməliyyatları
```bash
make db-connect    # MySQL-ə qoşul
make db-backup     # Backup yarat
make db-reset      # Database-i sıfırla (XƏBƏRDAR!)
```

### Backup və Restore
```bash
./scripts/backup.sh                                    # Manual backup
./scripts/restore.sh backups/quiz_backup_YYYYMMDD.tar.gz  # Restore
```

### Monitoring
```bash
make logs          # Bütün servislərın logları
make status        # Servislərin statusu
make health        # Health check
./scripts/monitor.sh  # Detailed monitoring
```

### Production Deployment
```bash
make prod                 # Start in production mode
./scripts/deploy.sh       # Full deployment with backup
```

## 🔧 Əməliyyat Komandaları

Bütün mövcud komandaları görmək üçün:
```bash
make help
```

### Əsas komandalar:
- `make quick-start` - Tam quraşdırma və başlatma
- `make start` - Sistemi işə sal
- `make stop` - Sistemi dayandır
- `make restart` - Sistemi yenidən başlat
- `make build` - Docker containers build et
- `make clean` - Docker cache təmizlə
- `make update` - Sistemi yenilə

### Script komandaları:
- `./scripts/setup.sh` - İlk quraşdırma
- `./scripts/backup.sh` - Database backup
- `./scripts/deploy.sh` - Production deployment
- `./scripts/restore.sh` - Backup-dan bərpa
- `./scripts/monitor.sh` - Sistem monitoring
- `./scripts/cleanup.sh` - Tam təmizlik

## 📊 API Endpoints

### Quiz API (Public)
- `GET /api/quiz/questions` - Sualları əldə et
- `POST /api/quiz/start` - Quiz başlat
- `POST /api/quiz/answer` - Cavab göndər
- `POST /api/quiz/complete` - Quiz tamamla
- `GET /api/quiz/session/:id` - Session məlumatı

### Admin API (Authentication lazım)
- `POST /api/admin/login` - Admin girişi
- `GET /api/admin/questions` - Sualları idarə et
- `POST /api/admin/questions` - Yeni sual əlavə et
- `PUT /api/admin/questions/:id` - Sualı yenilə
- `DELETE /api/admin/questions/:id` - Sualı sil
- `GET /api/admin/responses` - Cavabları gör
- `GET /api/admin/statistics` - Statistika
- `GET /api/admin/responses/export` - CSV export

Tam API dokumentasiyası: http://localhost:3001/api/docs

## 🗄️ Database Schema

### MySQL Cədvəlləri

**questions** - Quiz sualları
- `id` - Primary key
- `text` - Sual mətni
- `type` - Sual növü (radio/checkbox/text)
- `options` - JSON array (radio/checkbox üçün)
- `required` - Məcburi sual
- `order_number` - Sual sırası
- `is_active` - Aktiv status

**quiz_sessions** - Quiz sessionları
- `id` - UUID
- `user_name` - İstifadəçi adı (optional)
- `is_completed` - Tamamlanma statusu
- `completed_at` - Tamamlanma tarixi

**user_responses** - İstifadəçi cavabları
- `id` - Primary key
- `session_id` - Quiz session ID
- `question_id` - Sual ID
- `answer_text` - Cavab mətni

**admin_users** - Admin istifadəçiləri
- `id` - Primary key
- `username` - İstifadəçi adı
- `password_hash` - Şifrə hash

## 🔒 Təhlükəsizlik

### Tətbiq edilən təhlükəsizlik tədbirləri:
- JWT token authentication
- Password hashing (bcrypt)
- CORS qorunması
- Input validation (class-validator)
- SQL injection qorunması (TypeORM)
- Rate limiting (Nginx)
- Security headers
- Environment variables for sensitive data

### Rate Limiting:
- API endpoints: 10 requests/second
- Admin login: 5 requests/minute

## 🚀 Performance

### Frontend optimizasiyaları:
- Code splitting
- Lazy loading
- Image optimization
- Gzip compression
- CDN ready

### Backend optimizasiyaları:
- Database indexing
- Connection pooling
- Caching strategies
- API response optimization

## 🔄 Backup Strategy