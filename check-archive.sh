#!/bin/bash

# Script to check what will be included in the archive

echo "🔍 Checking build directory contents..."
echo ""

if [ ! -d "build" ]; then
    echo "❌ Build directory not found. Run ./build.sh first."
    exit 1
fi

echo "📊 Directory sizes:"
du -sh build/* 2>/dev/null | sort -h

echo ""
echo "🔍 Checking for unwanted files:"

# Check for node_modules
NODE_MODULES=$(find build -type d -name "node_modules" 2>/dev/null | wc -l)
if [ "$NODE_MODULES" -gt 0 ]; then
    echo "⚠️  Found $NODE_MODULES node_modules directories:"
    find build -type d -name "node_modules" 2>/dev/null
else
    echo "✅ No node_modules found"
fi

# Check for .expo
EXPO_CACHE=$(find build -type d -name ".expo" 2>/dev/null | wc -l)
if [ "$EXPO_CACHE" -gt 0 ]; then
    echo "⚠️  Found $EXPO_CACHE .expo cache directories"
    find build -type d -name ".expo" 2>/dev/null
else
    echo "✅ No .expo cache found"
fi

# Check for build artifacts
BUILD_DIRS=$(find build -type d -name "build" 2>/dev/null | grep -v "build$" | wc -l)
if [ "$BUILD_DIRS" -gt 0 ]; then
    echo "⚠️  Found $BUILD_DIRS build artifact directories"
    find build -type d -name "build" 2>/dev/null | grep -v "^build$"
else
    echo "✅ No build artifacts found"
fi

# Check for log files
LOG_FILES=$(find build -name "*.log" 2>/dev/null | wc -l)
if [ "$LOG_FILES" -gt 0 ]; then
    echo "⚠️  Found $LOG_FILES log files"
    find build -name "*.log" 2>/dev/null | head -5
else
    echo "✅ No log files found"
fi

# Check for database files
DB_FILES=$(find build -name "*.db" -o -name "*.db-shm" -o -name "*.db-wal" 2>/dev/null | wc -l)
if [ "$DB_FILES" -gt 0 ]; then
    echo "⚠️  Found $DB_FILES database files"
    find build \( -name "*.db" -o -name "*.db-shm" -o -name "*.db-wal" \) 2>/dev/null
else
    echo "✅ No database files found"
fi

# Calculate total size
TOTAL_SIZE=$(du -sh build 2>/dev/null | cut -f1)
echo ""
echo "📦 Total build directory size: $TOTAL_SIZE"

