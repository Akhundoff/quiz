#!/bin/bash

# Quiz System Setup Script
echo "🚀 Quiz System Setup Script"
echo "================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p backups
mkdir -p logs
mkdir -p nginx/ssl

# Setup environment files
echo "⚙️ Setting up environment files..."

if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ Created .env file"
else
    echo "⚠️ .env file already exists"
fi

if [ ! -f backend/.env ]; then
    cp backend/.env.example backend/.env
    echo "✅ Created backend/.env file"
else
    echo "⚠️ backend/.env file already exists"
fi

if [ ! -f frontend/.env ]; then
    cp frontend/.env.example frontend/.env
    echo "✅ Created frontend/.env file"
else
    echo "⚠️ frontend/.env file already exists"
fi

# Generate JWT secret
echo "🔐 Generating JWT secret..."
JWT_SECRET=$(openssl rand -base64 32)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/your-super-secret-jwt-key-change-this-in-production/$JWT_SECRET/g" .env
    sed -i '' "s/your-super-secret-jwt-key-change-this-in-production/$JWT_SECRET/g" backend/.env
else
    # Linux
    sed -i "s/your-super-secret-jwt-key-change-this-in-production/$JWT_SECRET/g" .env
    sed -i "s/your-super-secret-jwt-key-change-this-in-production/$JWT_SECRET/g" backend/.env
fi
echo "✅ JWT secret generated and updated"

# Generate random database passwords
echo "🔑 Generating database passwords..."
DB_PASSWORD=$(openssl rand -base64 16)
ROOT_PASSWORD=$(openssl rand -base64 16)

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/quiz_password/$DB_PASSWORD/g" .env
    sed -i '' "s/quiz_password/$DB_PASSWORD/g" backend/.env
    sed -i '' "s/rootpassword/$ROOT_PASSWORD/g" .env
else
    # Linux
    sed -i "s/quiz_password/$DB_PASSWORD/g" .env
    sed -i "s/quiz_password/$DB_PASSWORD/g" backend/.env
    sed -i "s/rootpassword/$ROOT_PASSWORD/g" .env
fi
echo "✅ Database passwords generated and updated"

# Set file permissions
echo "🔒 Setting file permissions..."
chmod 600 .env backend/.env frontend/.env
chmod +x scripts/setup.sh
chmod +x scripts/backup.sh
chmod +x scripts/deploy.sh
chmod +x scripts/restore.sh

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Review and modify .env files if needed"
echo "2. Run: make build"
echo "3. Run: make start"
echo ""
echo "🔗 Access URLs:"
echo "  🌐 Frontend: http://localhost:3000"
echo "  🔧 Backend: http://localhost:3001"
echo "  📚 API Docs: http://localhost:3001/api/docs"
echo ""
echo "🔑 Admin Login:"
echo "  Username: admin"
echo "  Password: admin123"