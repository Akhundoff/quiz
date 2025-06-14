# Usage: make [target]

.PHONY: help install build start stop restart clean logs status health
.PHONY: dev prod quick-start update
.PHONY: db-connect db-backup db-restore db-reset
.PHONY: test-backend test-frontend test
.PHONY: backup restore deploy monitor cleanup

# Default target
.DEFAULT_GOAL := help

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[0;37m
RESET := \033[0m

# Environment detection
ENV_FILE := .env
ifeq ($(wildcard $(ENV_FILE)),)
    $(error .env file not found. Run 'make setup' first)
endif

# Load environment variables
include $(ENV_FILE)

# Docker compose files
COMPOSE_FILE := docker-compose.yaml
COMPOSE_PROD_FILE := docker-compose.prod.yaml

# Project name
PROJECT_NAME := quiz-system

help: ## 📋 Bütün mövcud komandaları göstər
	@echo "$(CYAN)Quiz System - Docker Management$(RESET)"
	@echo "$(YELLOW)================================$(RESET)"
	@echo ""
	@echo "$(GREEN)🚀 Əsas Komandalar:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  $(BLUE)%-15s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST) | grep -E "🚀|📦|🔧|🗄️|🧪|📊|🛠️|🔄"
	@echo ""
	@echo "$(PURPLE)📝 İstifadə nümunəsi:$(RESET)"
	@echo "  make quick-start    # Tam quraşdırma və başlatma"
	@echo "  make dev           # Development mode"
	@echo "  make prod          # Production mode"
	@echo "  make logs          # Logları izlə"
	@echo ""

# 🚀 Quick Start Commands
quick-start: ## 🚀 Tam quraşdırma və başlatma (yeni istifadəçilər üçün)
	@echo "$(GREEN)🚀 Quiz System - Tez Başlanğıc$(RESET)"
	@make setup
	@make install
	@make build
	@make start
	@echo "$(GREEN)✅ Sistem hazırdır!$(RESET)"
	@make show-urls

setup: ## 🚀 İlk quraşdırma (environment faylları)
	@echo "$(YELLOW)📁 Environment faylları yaradılır...$(RESET)"
	@./scripts/setup.sh
	@echo "$(GREEN)✅ Setup tamamlandı$(RESET)"

install: ## 📦 Dependencies yüklə
	@echo "$(YELLOW)📦 Dependencies yüklənir...$(RESET)"
	@cd backend && npm install
	@cd frontend && npm install
	@echo "$(GREEN)✅ Dependencies yükləndi$(RESET)"

# 🔧 Docker Operations
build: ## 🔧 Docker containers build et
	@echo "$(YELLOW)🔨 Docker containers build edilir...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) build --no-cache
	@echo "$(GREEN)✅ Build tamamlandı$(RESET)"

build-prod: ## 🔧 Production containers build et
	@echo "$(YELLOW)🔨 Production containers build edilir...$(RESET)"
	@docker compose -f $(COMPOSE_PROD_FILE) build --no-cache
	@echo "$(GREEN)✅ Production build tamamlandı$(RESET)"

start: ## 🚀 Sistemi başlat (detached mode)
	@echo "$(YELLOW)▶️  Sistem başladılır...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)✅ Sistem başladıldı$(RESET)"
	@make show-urls

stop: ## ⏹️  Sistemi dayandır
	@echo "$(YELLOW)⏹️  Sistem dayandırılır...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✅ Sistem dayandırıldı$(RESET)"

restart: ## 🔄 Sistemi yenidən başlat
	@echo "$(YELLOW)🔄 Sistem yenidən başladılır...$(RESET)"
	@make stop
	@sleep 2
	@make start

# 🛠️ Environment Specific Commands
dev: ## 🛠️ Development mode başlat
	@echo "$(CYAN)🛠️  Development mode başladılır...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) up --build
	@echo "$(GREEN)✅ Development mode$(RESET)"

prod: ## 🚀 Production mode başlat
	@echo "$(RED)🚀 Production mode başladılır...$(RESET)"
	@docker compose -f $(COMPOSE_PROD_FILE) up -d --build
	@echo "$(GREEN)✅ Production mode$(RESET)"
	@make show-urls-prod

prod-stop: ## ⏹️  Production sistemi dayandır
	@echo "$(YELLOW)⏹️  Production sistem dayandırılır...$(RESET)"
	@docker compose -f $(COMPOSE_PROD_FILE) down
	@echo "$(GREEN)✅ Production sistem dayandırıldı$(RESET)"

# 📊 Monitoring Commands
logs: ## 📊 Bütün servislərın loglarını göstər
	@docker compose -f $(COMPOSE_FILE) logs -f

logs-backend: ## 📊 Backend logları
	@docker compose -f $(COMPOSE_FILE) logs -f backend

logs-frontend: ## 📊 Frontend logları
	@docker compose -f $(COMPOSE_FILE) logs -f frontend

logs-mysql: ## 📊 MySQL logları
	@docker compose -f $(COMPOSE_FILE) logs -f mysql

status: ## 📊 Servislərin statusunu göstər
	@echo "$(CYAN)📊 Servis Statusu:$(RESET)"
	@docker compose -f $(COMPOSE_FILE) ps

health: ## 📊 Health check
	@echo "$(CYAN)🏥 Health Check:$(RESET)"
	@./scripts/monitor.sh

monitor: ## 📊 Sistem monitoring başlat
	@echo "$(CYAN)📊 Sistem monitoring...$(RESET)"
	@./scripts/monitor.sh --continuous

# 🗄️ Database Operations
db-connect: ## 🗄️ MySQL-ə qoşul
	@echo "$(YELLOW)🗄️  MySQL-ə qoşulur...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) exec mysql mysql -u$(DB_USERNAME) -p$(DB_PASSWORD) $(DB_DATABASE)

db-backup: ## 🗄️ Database backup yarat
	@echo "$(YELLOW)💾 Database backup yaradılır...$(RESET)"
	@./scripts/backup.sh
	@echo "$(GREEN)✅ Backup yaradıldı$(RESET)"

db-restore: ## 🗄️ Database restore et (Usage: make db-restore FILE=backup.sql)
	@echo "$(YELLOW)📥 Database restore edilir...$(RESET)"
	@./scripts/restore.sh $(FILE)
	@echo "$(GREEN)✅ Restore tamamlandı$(RESET)"

db-reset: ## 🗄️ Database-i sıfırla (XƏBƏRDAR!)
	@echo "$(RED)⚠️  XƏBƏRDAR: Database silinəcək!$(RESET)"
	@read -p "Davam etmək istəyirsiniz? (y/N): " confirm && [ "$$confirm" = "y" ]
	@docker compose -f $(COMPOSE_FILE) exec mysql mysql -u$(DB_USERNAME) -p$(DB_PASSWORD) -e "DROP DATABASE IF EXISTS $(DB_DATABASE); CREATE DATABASE $(DB_DATABASE);"
	@echo "$(GREEN)✅ Database sıfırlandı$(RESET)"

# 🧪 Testing Commands
test: ## 🧪 Bütün testləri işə sal
	@make test-backend
	@make test-frontend

test-backend: ## 🧪 Backend testləri
	@echo "$(YELLOW)🧪 Backend testləri...$(RESET)"
	@cd backend && npm test

test-frontend: ## 🧪 Frontend testləri
	@echo "$(YELLOW)🧪 Frontend testləri...$(RESET)"
	@cd frontend && npm test -- --watchAll=false

# 🔄 Maintenance Commands
update: ## 🔄 Sistemi yenilə
	@echo "$(YELLOW)🔄 Sistem yenilənir...$(RESET)"
	@git pull origin main
	@make install
	@make build
	@make restart
	@echo "$(GREEN)✅ Sistem yeniləndi$(RESET)"

clean: ## 🧹 Docker cache və volumes təmizlə
	@echo "$(YELLOW)🧹 Docker cache təmizlənir...$(RESET)"
	@docker system prune -f
	@docker volume prune -f
	@echo "$(GREEN)✅ Cache təmizləndi$(RESET)"

clean-all: ## 🧹 Tam təmizlik (volumes daxil)
	@echo "$(RED)🧹 Tam təmizlik başladılır...$(RESET)"
	@read -p "Bütün data silinəcək! Davam etmək istəyirsiniz? (y/N): " confirm && [ "$$confirm" = "y" ]
	@make stop
	@docker compose -f $(COMPOSE_FILE) down -v --remove-orphans
	@docker system prune -af --volumes
	@echo "$(GREEN)✅ Tam təmizlik tamamlandı$(RESET)"

# 🛠️ Advanced Operations
backup: ## 💾 Tam sistem backup
	@echo "$(YELLOW)💾 Tam sistem backup...$(RESET)"
	@./scripts/backup.sh --full
	@echo "$(GREEN)✅ Backup tamamlandı$(RESET)"

restore: ## 📥 Backup-dan restore (Usage: make restore FILE=backup.tar.gz)
	@echo "$(YELLOW)📥 Sistem restore edilir...$(RESET)"
	@./scripts/restore.sh $(FILE)
	@echo "$(GREEN)✅ Restore tamamlandı$(RESET)"

deploy: ## 🚀 Production deployment
	@echo "$(RED)🚀 Production deployment...$(RESET)"
	@./scripts/deploy.sh
	@echo "$(GREEN)✅ Deployment tamamlandı$(RESET)"

cleanup: ## 🧹 Sistem təmizlik
	@echo "$(YELLOW)🧹 Sistem təmizlik...$(RESET)"
	@./scripts/cleanup.sh
	@echo "$(GREEN)✅ Təmizlik tamamlandı$(RESET)"

# 📋 Information Commands
show-urls: ## 📋 Development URL-ləri göstər
	@echo "$(CYAN)🌐 Development URL-ləri:$(RESET)"
	@echo "  🌐 Frontend:    $(PROTOCOL)://$(DOMAIN_NAME):3000"
	@echo "  🔧 Backend:     $(PROTOCOL)://$(DOMAIN_NAME):3001"
	@echo "  📚 API Docs:    $(PROTOCOL)://$(DOMAIN_NAME):3001/api/docs"
	@echo "  🗄️  phpMyAdmin: $(PROTOCOL)://$(DOMAIN_NAME):8082"
	@echo ""
	@echo "$(YELLOW)🔑 Admin Giriş:$(RESET)"
	@echo "  Username: admin"
	@echo "  Password: admin123"

show-urls-prod: ## 📋 Production URL-ləri göstər
	@echo "$(CYAN)🌐 Production URL-ləri:$(RESET)"
	@echo "  🌐 Frontend:    $(PROTOCOL)://$(DOMAIN_NAME)"
	@echo "  🔧 Backend:     $(PROTOCOL)://$(DOMAIN_NAME)/api"
	@echo "  📚 API Docs:    $(PROTOCOL)://$(DOMAIN_NAME)/api/docs"
	@echo "  🗄️  phpMyAdmin: $(PROTOCOL)://$(DOMAIN_NAME)/phpmyadmin"

env-check: ## 📋 Environment dəyişənləri yoxla
	@echo "$(CYAN)🔍 Environment konfiqurasiyası:$(RESET)"
	@echo "  DOMAIN_NAME: $(DOMAIN_NAME)"
	@echo "  PROTOCOL: $(PROTOCOL)"
	@echo "  NODE_ENV: $(NODE_ENV)"
	@echo "  DB_HOST: $(DB_HOST)"
	@echo "  DB_PORT: $(DB_PORT)"
	@echo "  DB_DATABASE: $(DB_DATABASE)"

# 🎯 Shortcuts
up: start ## ⚡ Shortcut: start
down: stop ## ⚡ Shortcut: stop
ps: status ## ⚡ Shortcut: status
rebuild: ## ⚡ Tam rebuild
	@make stop
	@make build
	@make start