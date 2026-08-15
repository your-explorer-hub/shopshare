#!/bin/bash
set -e

# Get script directory
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"

echo "=== Building Android APKs ==="
echo "App directory: $APP_DIR"
echo ""

# Use flutter from PATH
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
echo "=== Step 3: Build Release APK ==="
flutter build apk --release

echo ""
echo "=== Build complete! ==="
echo "Output: build/app/outputs/flutter-apk/app-release.apk"
ls -lh build/app/outputs/flutter-apk/app-release.apk
