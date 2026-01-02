#!/bin/bash
set -e

echo "🚀 Deploying Quiz Master..."

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

export PATH=/usr/local/go/bin:$PATH
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="/var/www/quiz_master"

mkdir -p "$APP_DIR/data" "$APP_DIR/web"

# Build Web
USE_STATIC_RENDERING="${USE_STATIC_RENDERING:-false}"
if [ -d "$PROJECT_ROOT/mobile" ]; then
    cd "$PROJECT_ROOT/mobile"
    echo "📦 Installing Expo dependencies..."
    rm -rf node_modules
    npm install --legacy-peer-deps
    
    echo "🌐 Building Web..."
    npx expo export --platform web 2>/dev/null || true
    
    if [ -d "dist" ]; then
        rm -rf "$APP_DIR/web/dist"
        mkdir -p "$APP_DIR/web/dist"
        cp -r dist/* "$APP_DIR/web/dist/"
        echo "✅ Web build deployed"
    else
        echo "❌ Web build failed or no dist/ found"
    fi
    cd "$PROJECT_ROOT"
fi

# Build Go
echo "🔨 Building Go application..."
cd "$PROJECT_ROOT"
go mod download
go build -ldflags="-w -s" -o "$APP_DIR/quiz-server" ./cmd/api/main.go
chmod +x "$APP_DIR/quiz-server"

# Copy resources
rm -rf "$APP_DIR/quizzes"
cp -r quizzes "$APP_DIR/"
cp "$PROJECT_ROOT/quiz-master.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable quiz-master.service
systemctl restart quiz-master.service

if command -v nginx &> /dev/null; then
    cp "$PROJECT_ROOT/nginx_quiz_master.conf" /etc/nginx/sites-available/quiz_master
    ln -sf /etc/nginx/sites-available/quiz_master /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
fi

echo "✅ Deployment complete!"
