#!/bin/bash
set -e

echo "📦 Creating deployment archive..."

# Run build first
./build.sh

# Create archive with exclusions
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="quiz_master_deploy_${TIMESTAMP}.tar.gz"

cd build

# Create archive excluding any remaining cache/temp files
tar -czf "../${ARCHIVE_NAME}" \
    --exclude='node_modules' \
    --exclude='.expo' \
    --exclude='.cache' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='*.tmp' \
    --exclude='*.db' \
    --exclude='.DS_Store' \
    --exclude='Thumbs.db' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    .

cd ..

# Calculate archive size
if command -v du &> /dev/null; then
    ARCHIVE_SIZE=$(du -h "../${ARCHIVE_NAME}" | cut -f1)
    echo "✅ Archive created: ${ARCHIVE_NAME} (size: ${ARCHIVE_SIZE})"
else
    echo "✅ Archive created: ${ARCHIVE_NAME}"
fi

echo ""
echo "📋 Archive contents summary:"
echo "  ✅ Go source code (cmd/, internal/)"
echo "  ✅ Mobile Expo project (mobile/ - without node_modules, cache, build artifacts)"
echo "  ✅ Quizzes (quizzes/)"
echo "  ✅ Deployment scripts (scripts/)"
echo "  ✅ Configuration files (go.mod, go.sum, *.service, *.conf)"
echo ""
echo "🧹 Excluded from archive:"
echo "  ❌ node_modules/"
echo "  ❌ .expo/ cache"
echo "  ❌ build/ artifacts"
echo "  ❌ *.log, *.tmp files"
echo "  ❌ Database files (*.db)"
echo "  ❌ OS files (.DS_Store, Thumbs.db)"
echo "  ❌ Python cache (__pycache__)"
echo ""
echo "To deploy on server:"
echo "  1. Upload archive: scp ${ARCHIVE_NAME} user@server:~/"
echo "  2. SSH to server: ssh user@server"
echo "  3. Extract: tar -xzf ${ARCHIVE_NAME}"
echo "  4. Make scripts executable: chmod +x scripts/*.sh"
echo "  5. Install dependencies: ./scripts/install_deps.sh"
echo "  6. Deploy: ./scripts/deploy_server.sh"

