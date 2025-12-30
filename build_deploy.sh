#!/bin/bash
set -e

# Support local tools if not in path
export PATH=$PATH:$(pwd)/.tools/go/bin:$(pwd)/.tools/node-v23.5.0-linux-x64/bin

echo "🚀 Starting Build Process..."

# 1. Build Frontend
echo "📦 Building Frontend..."
cd web
npm install
npm run build
cd ..

# 2. Build Backend
echo "🔨 Building Backend..."
go build -o quiz-server cmd/api/main.go

echo "✅ Build Complete!"
echo ""
echo "Deployment Instructions:"
echo "1. Copy the 'web/dist' folder to /var/www/quiz_master/dist"
echo "2. Copy the 'quiz-server' binary to /var/www/quiz_master/"
echo "3. Copy the 'quizzes' directory to /var/www/quiz_master/quizzes"
echo "4. Copy 'quiz-master.service' to /etc/systemd/system/ and enable it"
echo "5. Copy 'nginx_quiz_master.conf' to /etc/nginx/sites-available/ and link it"
