#!/bin/bash

# Production Deployment Script with Environment Setup

echo "🚀 Production Deployment"
echo "========================"

# Get domain from user
read -p "Enter your domain name (e.g., quiz.example.com): " DOMAIN_NAME
read -p "Enter protocol (http/https) [https]: " PROTOCOL
PROTOCOL=${PROTOCOL:-https}

# Validate inputs
if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Domain name is required"
    exit 1
fi

echo "🔧 Setting up production environment for: $PROTOCOL://$DOMAIN_NAME"

# Create production environment file
cat > .env.production << EOF
# Production Environment - Auto-generated
DB_HOST=mysql
DB_PORT=3306
DB_USERNAME=quiz_user
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
DB_DATABASE=quiz_system

JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

NODE_ENV=production
PORT=3001

DOMAIN_NAME=$DOMAIN_NAME
PROTOCOL=$PROTOCOL
FRONTEND_URL=$PROTOCOL://$DOMAIN_NAME
BACKEND_URL=$PROTOCOL://$DOMAIN_NAME
API_URL=$PROTOCOL://$DOMAIN_NAME/api
CORS_ORIGINS=$PROTOCOL://$DOMAIN_NAME

MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
EOF

# Create production docker compose override
cat > docker-compose.production.yml << EOF
version: '3.8'

services:
  mysql:
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_PASSWORD: \${DB_PASSWORD}
    volumes:
      - mysql_prod_data:/var/lib/mysql

  backend:
    environment:
      NODE_ENV: production
      JWT_SECRET: \${JWT_SECRET}
      DB_PASSWORD: \${DB_PASSWORD}
      FRONTEND_URL: \${FRONTEND_URL}
      BACKEND_URL: \${BACKEND_URL}
      CORS_ORIGINS: \${CORS_ORIGINS}

  frontend:
    environment:
      REACT_APP_API_URL: \${API_URL}
      REACT_APP_BACKEND_URL: \${BACKEND_URL}
      REACT_APP_FRONTEND_URL: \${FRONTEND_URL}

  nginx:
    image: nginx:alpine
    container_name: quiz_nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - frontend
      - backend
    networks:
      - quiz-network
    restart: always

volumes:
  mysql_prod_data:
EOF

echo "✅ Production environment configured"
echo "🔧 Deploying with domain: $DOMAIN_NAME"

# Load production environment
source .env.production

# Deploy
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d --build

echo "🎉 Production deployment completed!"
echo "🌐 Your quiz system is available at: $PROTOCOL://$DOMAIN_NAME"