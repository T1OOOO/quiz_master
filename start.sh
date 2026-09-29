#!/bin/bash
export PATH=$PWD/.tools/go/bin:$PWD/.tools/node-v23.5.0-linux-x64/bin:$PATH
export GOCACHE=$PWD/.cache
export GOMODCACHE=$PWD/.modcache

echo "Using Go: $(which go)"
echo "Using Node: $(which node)"

# 1. Install Frontend Dependencies
echo "Installing frontend dependencies..."
cd web
npm install --legacy-peer-deps

# 2. Build Frontend
echo "Building frontend..."
npm run build
cd ..

# 3. Run Backend
echo "Starting backend..."
fuser -k -9 8080/tcp || true
sleep 1
export PATH=$PWD/.tools/go/bin:$PATH
go mod tidy
go run cmd/api/main.go
