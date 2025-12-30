#!/bin/bash

VERSION=$(date +%Y%m%d_%H%M)
ARCHIVE_NAME="quiz_master_deploy_${VERSION}.tar.gz"

echo "📦 Packing project into ${ARCHIVE_NAME}..."

# Create archive excluding trash
tar -czvf ${ARCHIVE_NAME} \
    --exclude='node_modules' \
    --exclude='web/node_modules' \
    --exclude='.git' \
    --exclude='tmp' \
    --exclude='bin' \
    --exclude='.tools' \
    --exclude='.cache' \
    --exclude='.modcache' \
    --exclude='.idea' \
    --exclude='.vscode' \
    --exclude='.github' \
    --exclude='.DS_Store' \
    --exclude='*.tar.gz' \
    --exclude='*.tar.xz' \
    --exclude='*.zip' \
    --exclude='quiz-server' \
    --exclude='flutter' \
    .

echo ""
echo "✅ Archive created: ${ARCHIVE_NAME}"
echo "---------------------------------------------------"
echo "👉 How to deploy:"
echo "1. Upload '${ARCHIVE_NAME}' to your server (e.g., using scp)."
echo "   scp ${ARCHIVE_NAME} user@your-server-ip:~/"
echo ""
echo "2. SSH into your server."
echo "   ssh user@your-server-ip"
echo ""
echo "3. Run these commands on the server:"
echo "   tar -xzvf ${ARCHIVE_NAME}"
echo "   chmod +x scripts/*.sh"
echo "   ./scripts/install_deps.sh  # Installs Go, Node, Nginx"
echo "   ./scripts/deploy_server.sh # Builds and deploys app"
echo "---------------------------------------------------"
