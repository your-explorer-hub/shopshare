#!/bin/bash
set -e

# Get script directory
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"

echo "=== Building Android App Bundle (AAB) ==="
echo "App directory: $APP_DIR"
echo ""

# Use flutter from PATH
FLUTTER_CMD="flutter"

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter not found in PATH"
    echo "Please install Flutter or add it to your PATH"
    exit 1
fi

echo "Using Flutter: $(which flutter)"
flutter --version
echo ""

echo "=== Step 1: Clean build ==="
flutter clean

echo ""
echo "=== Step 2: Get dependencies ==="
flutter pub get

echo ""
echo "=== Step 3: Build App Bundle ==="
flutter build appbundle --release

echo ""
echo "=== Build complete! ==="
echo "Output: build/app/outputs/bundle/release/app-release.aab"
ls -lh build/app/outputs/bundle/release/app-release.aab

# Success indicator
echo "SUCCESS" > AAB_BUILD_SUCCESS.txt
echo "Build completed at $(date)" >> AAB_BUILD_SUCCESS.txt
