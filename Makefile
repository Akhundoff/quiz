# Makefile - Updated with Environment Support
.PHONY: help build start stop restart logs clean install dev prod backup

# Default target
help: ## Show this help message
	@echo "🚀 Quiz System - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🌍 Environment Commands:"
	@echo "  \033[36msetup-dev\033[0m           Setup development environment"
	@echo "  \033[36msetup-prod\033[0m          Setup production environment"
	@echo "  \033[36mswitch-env ENV=<env>\033[0m Switch to specific environment"

# Development Commands
install: ## Install dependencies for both frontend and backend
	@echo "📦 Installing dependencies..."
	cd backend && npm install
	cd frontend && npm install
	@echo "✅ Dependencies installed!"

dev: ## Start development servers (backend and frontend separately)
	@echo "🔧 Starting development servers..."
	@echo "Backend: http://localhost:3001"
	@echo "Frontend: http://localhost:3000"
	@echo "API Docs: http://localhost:3001/api/docs"
	cd backend && npm run start:dev &
	cd frontend && npm start

# Environment Setup Commands
setup-dev: ## Setup development environment
	@echo "🔧 Setting up development environment..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env file"; \
	else \
		echo "⚠️ .env file already exists"; \
	fi
	@if [ ! -f backend/.env ]; then \
		cp backend/.env.example backend/.env; \
		echo "✅ Created backend/.env file"; \
	else \
		echo "⚠️ backend/.env file already exists"; \
	fi
	@if [ ! -f frontend/.env ]; then \
		cp frontend/.env.example frontend/.env; \
		echo "✅ Created frontend/.env file"; \
	else \
		echo "⚠️ frontend/.env file already exists"; \
	fi
	@echo "✅ Development environment ready!"

setup-prod: ## Setup production environment (interactive)
	@echo "🏭 Setting up production environment..."
	@read -p "Enter your domain name (e.g., quiz.example.com): " domain; \
	read -p "Enter protocol (http/https) [https]: " protocol; \
	protocol=$${protocol:-https}; \
	echo "Creating production environment for: $$protocol://$$domain"; \
	sed "s/localhost/$$domain/g; s/http:/$$protocol:/g" .env.example > .env.production; \
	sed "s/localhost/$$domain/g; s/http:/$$protocol:/g" backend/.env.example > backend/.env.production; \
	sed "s/localhost/$$domain/g; s/http:/$$protocol:/g" frontend/.env.example > frontend/.env.production; \
	echo "JWT_SECRET=$$(openssl rand -base64 64 | tr -d '=+/' | cut -c1-50)" >> .env.production; \
	echo "DB_PASSWORD=$$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-25)" >> .env.production; \
	echo "✅ Production environment created!"

switch-env: ## Switch environment (usage: make switch-env ENV=production)
	@if [ -z "$(ENV)" ]; then \
		echo "❌ Please specify environment: make switch-env ENV=production"; \
		exit 1; \
	fi
	@if [ ! -f .env.$(ENV) ]; then \
		echo "❌ Environment file .env.$(ENV) not found"; \
		exit 1; \
	fi
	@cp .env.$(ENV) .env
	@if [ -f backend/.env.$(ENV) ]; then cp backend/.env.$(ENV) backend/.env; fi
	@if [ -f frontend/.env.$(ENV) ]; then cp frontend/.env.$(ENV) frontend/.env; fi
	@echo "✅ Switched to $(ENV) environment"

# Docker Commands
build: ## Build all Docker containers
	@echo "🔨 Building Docker containers..."
	@if [ -f docker-compose.$(ENV).yml ]; then \
		docker compose -f docker-compose.yml -f docker-compose.$(ENV).yml build --no-cache; \
	else \
		docker compose build --no-cache; \
	fi
	@echo "✅ Build completed!"

start: ## Start all services with Docker
	@echo "🚀 Starting Quiz System..."
	@if [ -f docker-compose.production.yml ] && [ "$(ENV)" = "production" ]; then \
		docker compose -f docker-compose.yml -f docker-compose.production.yml up -d; \
	else \
		docker compose up -d; \
	fi
	@echo "✅ Services started!"
	@echo ""
	@$(MAKE) show-urls

show-urls: ## Show access URLs based on environment
	@if [ -f .env ]; then \
		export $$(cat .env | grep -v '^#' | xargs) && \
		echo "📍 Access URLs:"; \
		echo "  🌐 Frontend: $${FRONTEND_URL:-http://localhost:3000}"; \
		echo "  🔧 Backend API: $${BACKEND_URL:-http://localhost:3001}"; \
		echo "  📚 API Documentation: $${BACKEND_URL:-http://localhost:3001}/api/docs"; \
		if [ "$${NODE_ENV}" != "production" ]; then \
			echo "  🗄️  MySQL: localhost:3306"; \
		fi; \
	else \
		echo "📍 Access URLs:"; \
		echo "  🌐 Frontend: http://localhost:3000"; \
		echo "  🔧 Backend API: http://localhost:3001"; \
		echo "  📚 API Documentation: http://localhost:3001/api/docs"; \
		echo "  🗄️  MySQL: localhost:3306"; \
	fi
	@echo ""
	@echo "🔑 Admin Login:"
	@echo "  Username: admin"
	@echo "  Password: admin123"

stop: ## Stop all services
	@echo "⏹️  Stopping services..."
	@if [ -f docker-compose.production.yml ] && [ "$(ENV)" = "production" ]; then \
		docker compose -f docker-compose.yml -f docker-compose.production.yml down; \
	else \
		docker compose down; \
	fi
	@echo "✅ Services stopped!"

restart: ## Restart all services
	@echo "🔄 Restarting services..."
	@$(MAKE) stop
	@$(MAKE) start
	@echo "✅ Services restarted!"

# Production Commands
prod: setup-prod ## Setup and start production environment
	@echo "🏭 Starting production environment..."
	@$(MAKE) switch-env ENV=production
	@$(MAKE) build ENV=production
	@$(MAKE) start ENV=production
	@echo "✅ Production environment started!"

deploy-prod: ## Full production deployment with domain setup
	@echo "🚀 Production Deployment"
	@echo "========================"
	@read -p "Enter your domain name (e.g., quiz.example.com): " domain; \
	read -p "Enter protocol (http/https) [https]: " protocol; \
	protocol=${protocol:-https}; \
	if [ -z "$domain" ]; then \
		echo "❌ Domain name is required"; \
		exit 1; \
	fi; \
	echo "🔧 Setting up production environment for: $protocol://$domain"; \
	sed "s/localhost/$domain/g; s|http://localhost:3000|$protocol://$domain|g; s|http://localhost:3001|$protocol://$domain|g" .env.example > .env.production; \
	sed "s/localhost/$domain/g; s|http://localhost:3000|$protocol://$domain|g; s|http://localhost:3001|$protocol://$domain|g" backend/.env.example > backend/.env.production; \
	sed "s|http://localhost:3001/api|$protocol://$domain/api|g; s|http://localhost:3000|$protocol://$domain|g; s|http://localhost:3001|$protocol://$domain|g" frontend/.env.example > frontend/.env.production; \
	echo "" >> .env.production; \
	echo "# Auto-generated secrets" >> .env.production; \
	echo "JWT_SECRET=$(openssl rand -base64 64 | tr -d '=+/' | cut -c1-50)" >> .env.production; \
	echo "DB_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-25)" >> .env.production; \
	echo "MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-25)" >> .env.production; \
	echo "DOMAIN_NAME=$domain" >> .env.production; \
	echo "PROTOCOL=$protocol" >> .env.production; \
	echo "FRONTEND_URL=$protocol://$domain" >> .env.production; \
	echo "BACKEND_URL=$protocol://$domain" >> .env.production; \
	echo "API_URL=$protocol://$domain/api" >> .env.production; \
	echo "CORS_ORIGINS=$protocol://$domain" >> .env.production; \
	cp .env.production backend/.env.production; \
	echo "✅ Production environment configured for: $protocol://$domain"; \
	$(MAKE) switch-env ENV=production; \
	$(MAKE) build ENV=production; \
	$(MAKE) start ENV=production; \
	echo "🎉 Production deployment completed!"; \
	echo "🌐 Your quiz system is available at: $protocol://$domain"

# Monitoring Commands
logs: ## Show logs from all services
	docker compose logs -f

logs-backend: ## Show backend logs only
	docker compose logs -f backend

logs-frontend: ## Show frontend logs only
	docker compose logs -f frontend

logs-mysql: ## Show MySQL logs only
	docker compose logs -f mysql

status: ## Show status of all services
	@echo "📊 Service Status:"
	docker compose ps

# Database Commands
db-reset: ## Reset database (WARNING: This will delete all data!)
	@echo "⚠️  WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		echo "🗑️  Resetting database..."; \
		docker compose down -v; \
		docker volume prune -f; \
		docker compose up -d mysql; \
		sleep 10; \
		docker compose up -d; \
		echo "✅ Database reset completed!"; \
	else \
		echo ""; \
		echo "❌ Operation cancelled."; \
	fi

db-backup: ## Create database backup
	@echo "💾 Creating database backup..."
	@mkdir -p backups
	@if [ -f .env ]; then \
		export $$(cat .env | grep -v '^#' | xargs) && \
		docker compose exec mysql mysqldump -u $${DB_USERNAME} -p$${DB_PASSWORD} $${DB_DATABASE} > backups/backup_$$(date +%Y%m%d_%H%M%S).sql; \
	else \
		docker compose exec mysql mysqldump -u quiz_user -pquiz_password quiz_system > backups/backup_$$(date +%Y%m%d_%H%M%S).sql; \
	fi
	@echo "✅ Backup created in backups/ directory"

db-connect: ## Connect to MySQL database
	@if [ -f .env ]; then \
		export $$(cat .env | grep -v '^#' | xargs) && \
		docker compose exec mysql mysql -u $${DB_USERNAME} -p$${DB_PASSWORD} $${DB_DATABASE}; \
	else \
		docker compose exec mysql mysql -u quiz_user -pquiz_password quiz_system; \
	fi

# Maintenance Commands
clean: ## Clean up Docker containers, images, and volumes
	@echo "🧹 Cleaning up..."
	docker compose down -v
	docker system prune -f
	docker volume prune -f
	@echo "✅ Cleanup completed!"

update: ## Pull latest changes and restart services
	@echo "⬆️  Updating system..."
	git pull
	docker compose down
	docker compose build --no-cache
	docker compose up -d
	@echo "✅ Update completed!"

# Health Check
health: ## Check health of all services
	@echo "🏥 Health Check:"
	@if [ -f .env ]; then \
		export $$(cat .env | grep -v '^#' | xargs) && \
		echo "Frontend: $$(curl -s -o /dev/null -w "%%{http_code}" $${FRONTEND_URL:-http://localhost:3000} || echo "❌ DOWN")"; \
		echo "Backend: $$(curl -s -o /dev/null -w "%%{http_code}" $${BACKEND_URL:-http://localhost:3001}/api/quiz/questions || echo "❌ DOWN")"; \
	else \
		echo "Frontend: $$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:3000 || echo "❌ DOWN")"; \
		echo "Backend: $$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:3001/api/quiz/questions || echo "❌ DOWN")"; \
	fi
	@echo "MySQL: $$(docker compose exec mysql mysqladmin ping -h localhost 2>/dev/null && echo "✅ UP" || echo "❌ DOWN")"

# Quick Development Setup
quick-start: setup-dev install build start ## Complete setup: install dependencies, build, and start
	@echo ""
	@echo "🎉 Quiz System is ready!"
	@$(MAKE) show-urls

# Testing Commands
test-backend: ## Run backend tests
	cd backend && npm test

test-frontend: ## Run frontend tests
	cd frontend && npm test

# Security scan
security-check: ## Run security checks
	@echo "🔒 Running security checks..."
	cd backend && npm audit
	cd frontend && npm audit

# Environment info
env-info: ## Show current environment information
	@echo "🌍 Environment Information:"
	@echo "Current environment files:"
	@ls -la .env* 2>/dev/null || echo "No environment files found"
	@if [ -f .env ]; then \
		echo ""; \
		echo "Active environment variables:"; \
		grep -E "^(NODE_ENV|FRONTEND_URL|BACKEND_URL|API_URL|DOMAIN_NAME)" .env 2>/dev/null || echo "No environment variables found"; \
	fi