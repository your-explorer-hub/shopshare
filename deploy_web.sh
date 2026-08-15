#!/bin/bash
set -e

# Get script directory
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"

echo "=== Deploying to Firebase Hosting ==="
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
echo "=== Step 3: Build Flutter Web (release) ==="
flutter build web --release

echo ""
echo "=== Step 4: Deploy to Firebase Hosting ==="
if ! command -v firebase &> /dev/null; then
    echo "Error: Firebase CLI not found in PATH"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi

firebase deploy --only hosting

echo ""
echo "=== Deployment complete! ==="
