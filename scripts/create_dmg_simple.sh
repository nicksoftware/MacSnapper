#!/bin/bash

# Mac Snap Simple DMG Creation Script
# This script creates a basic DMG installer without complex styling

set -e  # Exit on any error

# Configuration
APP_NAME="Mac Snap"
DMG_NAME="MacSnap-Installer"
VERSION=$(defaults read "$(pwd)/MacSnapper/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
BUILD_DIR="build"
DIST_DIR="dist"
APP_PATH="$BUILD_DIR/MacSnapper.app"
DMG_PATH="$DIST_DIR/${DMG_NAME}-${VERSION}.dmg"

echo "🚀 Creating simple DMG installer for $APP_NAME v$VERSION"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Clean previous builds
rm -f "$DMG_PATH"

echo "📦 Building Mac Snap..."

# Build the app if it doesn't exist
if [ ! -d "$APP_PATH" ]; then
    xcodebuild -project MacSnapper.xcodeproj \
        -scheme MacSnapper \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        clean build

    # Copy the built app
    cp -R "$BUILD_DIR/DerivedData/Build/Products/Release/MacSnapper.app" "$APP_PATH"
fi

# Verify app was built
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    exit 1
fi

echo "✅ App found at $APP_PATH"
echo "📁 Creating simple DMG..."

# Create temporary DMG directory
TEMP_DIR=$(mktemp -d)
DMG_DIR="$TEMP_DIR/dmg"
mkdir -p "$DMG_DIR"

# Copy app to DMG directory and rename it
cp -R "$APP_PATH" "$DMG_DIR/Mac Snap.app"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Copy additional files
cp README.md "$DMG_DIR/README.txt" 2>/dev/null || echo "README not found, skipping..."
cp LICENSE "$DMG_DIR/LICENSE.txt" 2>/dev/null || echo "License not found, skipping..."

echo "💿 Creating DMG..."

# Calculate size needed (in MB, with 50% buffer for safety)
SIZE=$(du -sm "$DMG_DIR" | awk '{print int($1 * 1.5)}')
if [ $SIZE -lt 100 ]; then
    SIZE=100  # Minimum size
fi

echo "DMG size will be: ${SIZE}MB"

# Create final DMG directly (no styling)
hdiutil create -srcfolder "$DMG_DIR" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -size ${SIZE}m \
    "$DMG_PATH"

# Clean up
rm -rf "$TEMP_DIR"

# Get file size
DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')

echo "✅ Simple DMG created successfully!"
echo "📍 Location: $DMG_PATH"
echo "📏 Size: $DMG_SIZE"
echo ""
echo "🎉 Mac Snap installer is ready for distribution!"

# Verify DMG
if hdiutil verify "$DMG_PATH" > /dev/null 2>&1; then
    echo "✅ DMG verification passed"
    echo ""
    echo "📋 Installation instructions:"
    echo "1. Double-click the DMG file"
    echo "2. Drag 'Mac Snap.app' to the Applications folder"
    echo "3. Launch Mac Snap from Applications"
else
    echo "⚠️  DMG verification failed"
    exit 1
fi