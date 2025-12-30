#!/bin/bash
set -e

echo "Starting deployment process..."

# 1. Build Frontend
echo "Building Frontend..."
cd web
npm install
npm run build
cd ..

# 2. Build Backend
echo "Building Backend..."
go mod tidy
go build -o quiz_master cmd/server/main.go

# 3. Stop running instance (if any)
# pkill -f quiz_master || true

# 4. Start Server
echo "Starting Server..."
# nohup ./quiz_master > server.log 2>&1 &
echo "Server built. Run with: ./quiz_master"
