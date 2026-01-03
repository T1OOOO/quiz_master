#!/bin/bash
set -e

echo "🚀 Building Quiz Master for deployment..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get version from git or use timestamp
VERSION=$(git describe --tags --always 2>/dev/null || echo "dev-$(date +%Y%m%d-%H%M%S)")

echo -e "${BLUE}📦 Version: ${VERSION}${NC}"

# Create build directory
BUILD_DIR="build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$BUILD_DIR/scripts"

echo -e "${BLUE}🔨 Building Go backend (optional, will rebuild on server)...${NC}"
# Optionally build binary (will be rebuilt on server anyway)
# Build binary for Linux (cross-compile)
# We use modernc.org/sqlite which is pure Go, so CGO_ENABLED=0 should work fine.
echo "Attempting to cross-compile for Linux..."
if GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-w -s" -o "$BUILD_DIR/quiz-server" ./cmd/api/main.go; then
    echo -e "${GREEN}✅ Local cross-compilation successful!${NC}"
else
    echo -e "${BLUE}⚠️  Local build failed. Continuing without binary (will build on server).${NC}"
    # Ensure strict mode doesn't kill the script here
    true
fi

echo -e "${BLUE}📁 Copying files...${NC}"
# Copy essential files
cp -r quizzes "$BUILD_DIR/"
cp quiz-master.service "$BUILD_DIR/"
cp nginx_quiz_master.conf "$BUILD_DIR/"
cp go.mod "$BUILD_DIR/"
cp go.sum "$BUILD_DIR/"

# Copy source code for building on server
cp -r cmd "$BUILD_DIR/"
cp -r internal "$BUILD_DIR/"

# Copy mobile directory for Expo web build (excluding unnecessary files)
echo -e "${BLUE}📱 Copying mobile directory (excluding node_modules and cache)...${NC}"
mkdir -p "$BUILD_DIR/mobile"
# Copy with exclusions using rsync if available, otherwise use find+cp
if command -v rsync &> /dev/null; then
    rsync -av --exclude='node_modules' \
          --exclude='.expo' \
          --exclude='android/build' \
          --exclude='android/app/build' \
          --exclude='android/.gradle' \
          --exclude='android/app/.cxx' \
          --exclude='android/.kotlin' \
          --exclude='*.log' \
          --exclude='*.txt' \
          --exclude='.cache' \
          --exclude='.next' \
          --exclude='build' \
          --exclude='.DS_Store' \
          --exclude='Thumbs.db' \
          --exclude='*.tmp' \
          --exclude='.vscode' \
          mobile/ "$BUILD_DIR/mobile/"
else
    # Fallback: copy and then clean
    cp -r mobile "$BUILD_DIR/"
    # Comprehensive cleanup - use more aggressive removal
    find "$BUILD_DIR/mobile" -type d -name "node_modules" -prune -exec rm -rf {} \; 2>/dev/null || true
    # Also try direct removal if it exists
    [ -d "$BUILD_DIR/mobile/node_modules" ] && rm -rf "$BUILD_DIR/mobile/node_modules" 2>/dev/null || true
    find "$BUILD_DIR/mobile" -type d -name ".expo" -exec rm -rf {} + 2>/dev/null || true
    find "$BUILD_DIR/mobile" -type d -name ".cache" -exec rm -rf {} + 2>/dev/null || true
    find "$BUILD_DIR/mobile" -type d -name "build" -exec rm -rf {} + 2>/dev/null || true
    # find "$BUILD_DIR/mobile" -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true
    find "$BUILD_DIR/mobile" -type d -name ".next" -exec rm -rf {} + 2>/dev/null || true
    find "$BUILD_DIR/mobile/android" -type d -name ".gradle" -exec rm -rf {} + 2>/dev/null || true
    find "$BUILD_DIR/mobile/android" -type d -name ".cxx" -exec rm -rf {} + 2>/dev/null || true
    find "$BUILD_DIR/mobile/android" -type d -name ".kotlin" -exec rm -rf {} + 2>/dev/null || true
    find "$BUILD_DIR/mobile" -type d -name ".vscode" -exec rm -rf {} + 2>/dev/null || true
    find "$BUILD_DIR/mobile" -name "*.log" -delete 2>/dev/null || true
    find "$BUILD_DIR/mobile" -name "*.txt" -not -path "*/quizzes/*" -delete 2>/dev/null || true
    find "$BUILD_DIR/mobile" -name "*.tmp" -delete 2>/dev/null || true
    find "$BUILD_DIR/mobile" -name ".DS_Store" -delete 2>/dev/null || true
    find "$BUILD_DIR/mobile" -name "Thumbs.db" -delete 2>/dev/null || true
    find "$BUILD_DIR/mobile" -name "*.map" -delete 2>/dev/null || true
fi

# Create install_deps.sh script
cat > "$BUILD_DIR/scripts/install_deps.sh" << 'INSTALL_SCRIPT'
#!/bin/bash
set -e

echo "📦 Installing dependencies for Quiz Master..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Cannot detect OS"
    exit 1
fi

echo "Detected OS: $OS"

# Install/Update Go to required version
GO_VERSION="1.24.11"
GO_REQUIRED_MIN="1.24"
ARCH="amd64"

# Check if Go is installed and if version is correct
NEED_GO_UPDATE=false
if ! command -v go &> /dev/null; then
    echo "📥 Go not found, installing..."
    NEED_GO_UPDATE=true
else
    CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    CURRENT_MAJOR=$(echo "$CURRENT_GO_VERSION" | cut -d. -f1)
    CURRENT_MINOR=$(echo "$CURRENT_GO_VERSION" | cut -d. -f2)
    REQUIRED_MAJOR=$(echo "$GO_REQUIRED_MIN" | cut -d. -f1)
    REQUIRED_MINOR=$(echo "$GO_REQUIRED_MIN" | cut -d. -f2)
    
    echo "Current Go version: go$CURRENT_GO_VERSION"
    
    # Compare versions: need at least 1.24
    if [ "$CURRENT_MAJOR" -lt "$REQUIRED_MAJOR" ] || \
       ([ "$CURRENT_MAJOR" -eq "$REQUIRED_MAJOR" ] && [ "$CURRENT_MINOR" -lt "$REQUIRED_MINOR" ]); then
        echo "⚠️  Go version go$CURRENT_GO_VERSION is too old, need go$GO_REQUIRED_MIN or newer"
        NEED_GO_UPDATE=true
    fi
fi

if [ "$NEED_GO_UPDATE" = true ]; then
    echo "📥 Installing/Updating Go to version $GO_VERSION..."
    cd /tmp
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" || {
        echo "❌ Failed to download Go. Trying alternative URL..."
        wget -q "https://golang.org/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" || {
            echo "❌ Failed to download Go from both URLs"
            exit 1
        }
    }
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-${ARCH}.tar.gz"
    rm "go${GO_VERSION}.linux-${ARCH}.tar.gz"
    
    # Add Go to PATH
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    export PATH=$PATH:/usr/local/go/bin
    
    echo "✅ Go installed: $(/usr/local/go/bin/go version)"
else
    echo "✅ Go version is sufficient: $(go version)"
fi

# Install Node.js
if ! command -v node &> /dev/null; then
    echo "📥 Installing Node.js..."
    NODE_VERSION="20"
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
        apt-get install -y nodejs
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
        yum install -y nodejs || dnf install -y nodejs
    fi
    echo "✅ Node.js installed: $(node --version)"
else
    echo "✅ Node.js already installed: $(node --version)"
fi

# Install Nginx
if ! command -v nginx &> /dev/null; then
    echo "📥 Installing Nginx..."
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get update
        apt-get install -y nginx
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
        yum install -y nginx || dnf install -y nginx
    fi
    systemctl enable nginx
    systemctl start nginx
    echo "✅ Nginx installed"
else
    echo "✅ Nginx already installed"
fi

echo "✅ All dependencies installed!"
INSTALL_SCRIPT

chmod +x "$BUILD_DIR/scripts/install_deps.sh"

# Create deploy_server.sh script
cat > "$BUILD_DIR/scripts/deploy_server.sh" << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

echo "🚀 Deploying Quiz Master..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Web rendering mode (static = slower build but faster runtime, single = faster build but slower runtime)
# For weak servers, use single (dynamic) mode by default
USE_STATIC_RENDERING="${USE_STATIC_RENDERING:-false}"
if [ "$USE_STATIC_RENDERING" = "true" ]; then
    echo "📦 Using static rendering mode (slower build, faster runtime)"
    export USE_STATIC_RENDERING=true
else
    echo "⚡ Using dynamic rendering mode (faster build, recommended for weak servers)"
    echo "   Set USE_STATIC_RENDERING=true to enable static rendering"
    export USE_STATIC_RENDERING=false
fi

# Ensure Go and Node are in PATH (prioritize /usr/local/go/bin)
export PATH=/usr/local/go/bin:$PATH

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Create application directory
APP_DIR="/var/www/quiz_master"
mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/data"

# Clean old web files before deploying new version (only quiz_master dist, not entire web dir)
echo "🧹 Cleaning old quiz_master web files..."
rm -rf "$APP_DIR/web/dist" 2>/dev/null || true
mkdir -p "$APP_DIR/web"

# Build Expo web version
# Default: dynamic/SPA mode (faster build, recommended for weak servers)
# Set USE_STATIC_RENDERING=true to enable static rendering
USE_STATIC_RENDERING="${USE_STATIC_RENDERING:-false}"

# Check if we have pre-built web assets
if [ -d "$PROJECT_ROOT/mobile/dist" ] && [ -f "$PROJECT_ROOT/mobile/dist/index.html" ]; then
    echo "📦 Found pre-built web assets in mobile/dist, skipping Expo build..."
    mkdir -p "$APP_DIR/web/dist"
    cp -r "$PROJECT_ROOT/mobile/dist/"* "$APP_DIR/web/dist/"
    echo "✅ Pre-built web assets deployed."
else
    if [ "$USE_STATIC_RENDERING" = "true" ]; then
        echo "🌐 Building Expo web version (static rendering, slower build but faster runtime)..."
    else
        echo "🌐 Building Expo web version (dynamic/SPA mode - faster build, default)..."
        echo "💡 To enable static rendering, set USE_STATIC_RENDERING=true"
    fi

    if [ -d "$PROJECT_ROOT/mobile" ]; then
        cd "$PROJECT_ROOT/mobile"
        
        # Clean up old platform-specific icon files if they exist
        echo "🧹 Cleaning up old icon files..."
        rm -f src/components/icons.web.tsx 2>/dev/null || true
        rm -f src/components/icons.native.tsx 2>/dev/null || true
        # Ensure universal icons.tsx exists
        if [ ! -f "src/components/icons.tsx" ]; then
            echo "❌ ERROR: src/components/icons.tsx not found!"
            exit 1
        fi
        
        # Clean Metro cache to avoid stale module resolution
        echo "🧹 Cleaning Metro cache..."
        rm -rf .expo 2>/dev/null || true
        rm -rf node_modules/.cache 2>/dev/null || true
        rm -rf .metro 2>/dev/null || true
        
        # Temporarily modify app.json if static rendering is enabled
        if [ "$USE_STATIC_RENDERING" = "true" ]; then
            echo "📝 Configuring for static rendering..."
            # Backup original app.json
            cp app.json app.json.backup 2>/dev/null || true
            # Change output to static instead of single
            if command -v sed &> /dev/null; then
                sed -i.bak 's/"output": "single"/"output": "static"/' app.json 2>/dev/null || \
                sed -i 's/"output": "single"/"output": "static"/' app.json 2>/dev/null || true
            fi
        fi
        # Always install dependencies (node_modules are excluded from archive)
        echo "📦 Installing Expo dependencies..."
        # Remove node_modules if exists to ensure clean install
        rm -rf node_modules 2>/dev/null || true
        
        # Check if package.json exists
        if [ ! -f "package.json" ]; then
            echo "❌ ERROR: package.json not found in mobile directory!"
            ls -la | head -10
            exit 1
        fi
        
        # Install all dependencies including lucide-react for web
        echo "Running: npm install --legacy-peer-deps"
        # Clear npm cache to ensure fresh install
        npm cache clean --force 2>/dev/null || true
        npm install --legacy-peer-deps
        
        # Verify critical dependencies are installed
        if [ ! -d "node_modules/lucide-react" ]; then
            echo "❌ lucide-react installation failed!"
            echo "Attempting to install lucide-react directly..."
            npm install lucide-react@^0.468.0 --legacy-peer-deps --force
        fi
        if [ ! -d "node_modules/lucide-react-native" ]; then
            echo "⚠️  lucide-react-native not found (may be OK for web-only build)"
        fi
        if [ ! -d "node_modules/react-native-svg" ]; then
            echo "⚠️  react-native-svg not found (required for lucide-react-native)"
            echo "Installing react-native-svg..."
            npm install react-native-svg@^15.15.1 --legacy-peer-deps
        fi
        
        # Verify installation
        if [ -d "node_modules/lucide-react" ]; then
            echo "✅ lucide-react installed successfully"
        else
            echo "❌ ERROR: lucide-react still not found after installation!"
            echo "Package.json contents:"
            grep -A 2 "lucide-react" package.json || echo "  (not found in package.json)"
            echo "Node modules directory:"
            ls -la node_modules/ | head -20 || echo "  (node_modules not found)"
        fi
        
        if [ "$USE_STATIC_RENDERING" = "true" ]; then
            echo "🔨 Building static web export..."
        else
            echo "🔨 Building dynamic web export (SPA mode)..."
        fi
        EXPORT_LOG="/tmp/expo_export.log"
        EXPORT_SUCCESS=false
        
        if command -v npx &> /dev/null; then
            # Create output directory first
            mkdir -p "$APP_DIR/web/dist"
            
            # Try expo export (with static output configured in app.json)
            echo "Trying: npx expo export..."
            if npx expo export 2>&1 | tee "$EXPORT_LOG"; then
                # Check where files were exported
                if [ -d "dist" ] && [ -f "dist/index.html" ]; then
                    echo "✅ Found dist/ directory with index.html"
                    rm -rf "$APP_DIR/web/dist" 2>/dev/null || true
                    mkdir -p "$APP_DIR/web/dist"
                    cp -r dist/* "$APP_DIR/web/dist/" 2>/dev/null || true
                    EXPORT_SUCCESS=true
                elif [ -d ".output" ] && [ -f ".output/index.html" ]; then
                    echo "✅ Found .output/ directory with index.html"
                    rm -rf "$APP_DIR/web/dist" 2>/dev/null || true
                    mkdir -p "$APP_DIR/web/dist"
                    cp -r .output/* "$APP_DIR/web/dist/" 2>/dev/null || true
                    EXPORT_SUCCESS=true
                else
                    echo "⚠️  Export completed but no dist/ or .output/ found"
                    echo "Contents of current directory:"
                    ls -la | head -20
                fi
            else
                EXPORT_EXIT_CODE=${PIPESTATUS[0]}
                echo "⚠️  expo export failed with exit code: $EXPORT_EXIT_CODE"
            fi
            
            # If first attempt failed, try with --platform web
            if [ "$EXPORT_SUCCESS" = false ]; then
                echo "Trying: npx expo export --platform web..."
                if npx expo export --platform web 2>&1 | tee -a "$EXPORT_LOG"; then
                    if [ -d "dist" ] && [ -f "dist/index.html" ]; then
                        echo "✅ Found dist/ directory with index.html"
                        rm -rf "$APP_DIR/web/dist" 2>/dev/null || true
                        mkdir -p "$APP_DIR/web/dist"
                        cp -r dist/* "$APP_DIR/web/dist/" 2>/dev/null || true
                        EXPORT_SUCCESS=true
                    fi
                fi
            fi
            
            # Clean up temporary export directories (but keep for debugging if failed)
            if [ "$EXPORT_SUCCESS" = true ]; then
                rm -rf dist web-build .output 2>/dev/null || true
            else
                echo "⚠️  Keeping export directories for debugging:"
                ls -la | grep -E "(dist|output|web-build)" || echo "  (none found)"
            fi
            
            # Restore original app.json if we modified it
            if [ -f "app.json.backup" ]; then
                mv app.json.backup app.json
                rm -f app.json.bak 2>/dev/null || true
            fi
        else
            echo "❌ npx not found, cannot build web version"
        fi
        
        if [ "$EXPORT_SUCCESS" = false ]; then
            echo "❌ Expo web export failed!"
            echo "📋 Last 50 lines of export log:"
            tail -50 "$EXPORT_LOG" 2>/dev/null || echo "  (log file not found)"
            echo ""
            echo "Creating minimal web directory..."
            mkdir -p "$APP_DIR/web/dist"
            cat > "$APP_DIR/web/dist/index.html" << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quiz Master - Build Error</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        h1 { color: #e74c3c; }
        pre { background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>⚠️ Web Build Error</h1>
    <p>The web build failed. Please check server logs:</p>
    <pre>tail -50 /tmp/expo_export.log</pre>
    <p>Or check deployment logs:</p>
    <pre>journalctl -u quiz-master -n 100</pre>
</body>
</html>
HTML
        else
            echo "✅ Expo web export completed successfully"
            echo "📦 Files copied to: $APP_DIR/web/dist/"
            if [ -f "$APP_DIR/web/dist/index.html" ]; then
                echo "✅ index.html found"
            else
                echo "⚠️  Warning: index.html not found in dist/"
            fi
        fi
        cd "$PROJECT_ROOT"
        
        # Restore app.json if we modified it and haven't restored yet
        if [ "$USE_STATIC_RENDERING" != "true" ] && [ -f "$PROJECT_ROOT/mobile/app.json.backup" ]; then
            mv "$PROJECT_ROOT/mobile/app.json.backup" "$PROJECT_ROOT/mobile/app.json"
        fi
    else
        echo "⚠️  Mobile directory not found, skipping web build"
        mkdir -p "$APP_DIR/web/dist"
        echo "<!DOCTYPE html><html><body><h1>Web build not available</h1></body></html>" > "$APP_DIR/web/dist/index.html"
    fi
fi

# Build the Go application
if [ -f "$PROJECT_ROOT/quiz-server" ] && [ -x "$PROJECT_ROOT/quiz-server" ]; then
     echo "📦 Found pre-built Go binary, using it..."
     cp "$PROJECT_ROOT/quiz-server" "$APP_DIR/quiz-server"
else
    echo "🔨 Building Go application..."
    cd "$PROJECT_ROOT"
    go mod download
    go build -ldflags="-w -s" -o "$APP_DIR/quiz-server" ./cmd/api/main.go
fi

# Copy files
echo "📁 Copying files..."
# Remove old quizzes if they exist, then copy new ones
rm -rf "$APP_DIR/quizzes" 2>/dev/null || true
cp -r quizzes "$APP_DIR/"
chmod +x "$APP_DIR/quiz-server"

# Setup systemd service
echo "⚙️  Setting up systemd service..."
cp "$PROJECT_ROOT/quiz-master.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable quiz-master.service
systemctl restart quiz-master.service

# Setup nginx
if command -v nginx &> /dev/null; then
    echo "⚙️  Setting up nginx..."
    cp "$PROJECT_ROOT/nginx_quiz_master.conf" /etc/nginx/sites-available/quiz_master
    ln -sf /etc/nginx/sites-available/quiz_master /etc/nginx/sites-enabled/
    nginx -t
    
    # Clear nginx cache if it exists
    if [ -d "/var/cache/nginx" ]; then
        echo "🧹 Clearing nginx cache..."
        rm -rf /var/cache/nginx/* 2>/dev/null || true
    fi
    
    # Reload nginx to apply changes
    systemctl reload nginx
    echo "✅ Nginx configured and reloaded. Don't forget to update server_name in nginx_quiz_master.conf"
fi

echo "✅ Deployment complete!"
echo "📊 Check status: systemctl status quiz-master"
echo "📝 Check logs: journalctl -u quiz-master -f"
DEPLOY_SCRIPT

chmod +x "$BUILD_DIR/scripts/deploy_server.sh"

# Final cleanup - remove any remaining cache and temporary files
echo -e "${BLUE}🧹 Final cleanup...${NC}"
find "$BUILD_DIR" -type d -name ".git" -exec rm -rf {} + 2>/dev/null || true
find "$BUILD_DIR" -type d -name ".vscode" -exec rm -rf {} + 2>/dev/null || true
find "$BUILD_DIR" -type d -name ".idea" -exec rm -rf {} + 2>/dev/null || true
find "$BUILD_DIR" -name "*.db" -delete 2>/dev/null || true
find "$BUILD_DIR" -name "*.db-shm" -delete 2>/dev/null || true
find "$BUILD_DIR" -name "*.db-wal" -delete 2>/dev/null || true
find "$BUILD_DIR" -name ".DS_Store" -delete 2>/dev/null || true
find "$BUILD_DIR" -name "Thumbs.db" -delete 2>/dev/null || true
find "$BUILD_DIR" -name "*.pyc" -delete 2>/dev/null || true
find "$BUILD_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Calculate size
BUILD_SIZE=$(du -sh "$BUILD_DIR" 2>/dev/null | cut -f1 || echo "unknown")

echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "${BLUE}📦 Build directory: ${BUILD_DIR} (size: ${BUILD_SIZE})${NC}"
echo ""
echo "Next steps:"
echo "  1. Create archive: ./create-deploy-archive.sh"
echo "  2. Upload to server: scp quiz_master_deploy_*.tar.gz user@server:~"
echo "  3. On server: tar -xzf quiz_master_deploy_*.tar.gz"
echo "  4. On server: chmod +x scripts/*.sh"
echo "  5. On server: ./scripts/install_deps.sh"
echo "  6. On server: ./scripts/deploy_server.sh"

