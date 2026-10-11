#!/bin/bash
set -e

echo "📦 Installing dependencies for Quiz Master..."

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Cannot detect OS"
    exit 1
fi

echo "Detected OS: $OS"

# Install/Update Go
GO_VERSION="1.24.11"
GO_REQUIRED_MIN="1.24"
ARCH="amd64"
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
    
    if [ "$CURRENT_MAJOR" -lt "$REQUIRED_MAJOR" ] || \
       ([ "$CURRENT_MAJOR" -eq "$REQUIRED_MAJOR" ] && [ "$CURRENT_MINOR" -lt "$REQUIRED_MINOR" ]); then
        echo "⚠️  Go version go$CURRENT_GO_VERSION is too old"
        NEED_GO_UPDATE=true
    else
        echo "✅ Go version is sufficient: $(go version)"
    fi
fi

if [ "$NEED_GO_UPDATE" = true ]; then
    echo "📥 Installing/Updating Go to version $GO_VERSION..."
    cd /tmp
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" || exit 1
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-${ARCH}.tar.gz"
    export PATH=$PATH:/usr/local/go/bin
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    echo "✅ Go installed: $(/usr/local/go/bin/go version)"
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
fi

# Install Nginx
if ! command -v nginx &> /dev/null; then
    echo "📥 Installing Nginx..."
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get update && apt-get install -y nginx
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
        yum install -y nginx || dnf install -y nginx
    fi
    systemctl enable nginx
    systemctl start nginx
fi

echo "✅ All dependencies installed!"
