#!/bin/bash

# Mac Snap DMG Creation Script
# This script creates a professional DMG installer for Mac Snap

set -e  # Exit on any error

# Configuration
APP_NAME="Mac Snap"
DMG_NAME="MacSnap-Installer"
BUNDLE_ID="com.nicksoftware.macsnap"
VERSION=$(defaults read "$(pwd)/MacSnapper/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
BUILD_DIR="build"
DIST_DIR="dist"
APP_PATH="$BUILD_DIR/MacSnapper.app"
DMG_PATH="$DIST_DIR/${DMG_NAME}-${VERSION}.dmg"
TEMP_DMG_PATH="$DIST_DIR/${DMG_NAME}-${VERSION}-temp.dmg"

echo "🚀 Creating DMG installer for $APP_NAME v$VERSION"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Clean previous builds
rm -rf "$APP_PATH"
rm -f "$DMG_PATH"
rm -f "$TEMP_DMG_PATH"

echo "📦 Building Mac Snap..."

# Build the app
xcodebuild -project MacSnapper.xcodeproj \
    -scheme MacSnapper \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -archivePath "$BUILD_DIR/MacSnapper.xcarchive" \
    archive

# Export the app
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/MacSnapper.xcarchive" \
    -exportPath "$BUILD_DIR" \
    -exportOptionsPlist "scripts/ExportOptions.plist"

# Verify app was built
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    exit 1
fi

echo "✅ App built successfully"
echo "📁 Creating DMG structure..."

# Create temporary DMG directory
TEMP_DIR=$(mktemp -d)
DMG_DIR="$TEMP_DIR/dmg"
mkdir -p "$DMG_DIR"

# Copy app to DMG directory
cp -R "$APP_PATH" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Copy additional files
cp README.md "$DMG_DIR/README.txt"
cp LICENSE "$DMG_DIR/LICENSE.txt" 2>/dev/null || echo "License not found, skipping..."

# Create DMG background and styling
mkdir -p "$DMG_DIR/.background"

# Convert logo to background image if needed
if command -v rsvg-convert &> /dev/null; then
    rsvg-convert -w 1024 -h 768 logo.svg -o "$DMG_DIR/.background/background.png" 2>/dev/null || true
fi

echo "💿 Creating DMG..."

# Calculate size needed (in MB, with 20% buffer)
SIZE=$(du -sm "$DMG_DIR" | awk '{print int($1 * 1.2)}')
if [ $SIZE -lt 50 ]; then
    SIZE=50  # Minimum size
fi

# Create DMG
hdiutil create -srcfolder "$DMG_DIR" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${SIZE}m \
    "$TEMP_DMG_PATH"

echo "🎨 Styling DMG..."

# Mount the DMG for styling
MOUNT_DIR=$(mktemp -d)
echo "Mounting DMG at: $MOUNT_DIR"

# Mount the DMG and get the actual volume name
MOUNT_RESULT=$(hdiutil attach "$TEMP_DMG_PATH" -noautoopen -mountpoint "$MOUNT_DIR" 2>&1)
if [ $? -ne 0 ]; then
    echo "❌ Failed to mount DMG: $MOUNT_RESULT"
    exit 1
fi

# Wait a moment for the mount to complete
sleep 2

# Get the actual volume name from the mount point
VOLUME_NAME=$(basename "$MOUNT_DIR")
echo "Volume name: $VOLUME_NAME"

# Check if the mount was successful
if [ ! -d "$MOUNT_DIR" ] || [ ! -e "$MOUNT_DIR/Mac Snap.app" ]; then
    echo "❌ DMG mount failed or app not found"
    hdiutil detach "$MOUNT_DIR" 2>/dev/null || true
    exit 1
fi

# Set DMG window properties using AppleScript with error handling
echo "Applying DMG styling..."
osascript << EOF || echo "⚠️  DMG styling failed, but continuing..."
try
    tell application "Finder"
        activate
        delay 1

        -- Open the volume
        open folder POSIX file "$MOUNT_DIR"
        delay 2

        tell container window of folder POSIX file "$MOUNT_DIR"
            set current view to icon view
            set toolbar visible to false
            set statusbar visible to false
            set the bounds to {100, 100, 900, 600}

            tell icon view options of container window of folder POSIX file "$MOUNT_DIR"
                set arrangement to not arranged
                set icon size to 128
                if (exists file ".background:background.png" of folder POSIX file "$MOUNT_DIR") then
                    set background picture to file ".background:background.png" of folder POSIX file "$MOUNT_DIR"
                end if
            end tell

            -- Position icons with error handling
            try
                set position of item "Mac Snap.app" to {200, 300}
            end try
            try
                set position of item "Applications" to {600, 300}
            end try

            -- Hide background folder
            try
                set the extension hidden of item ".background" to true
            end try

            update without registering applications
            delay 2
            close
        end tell
    end tell
on error errMsg
    display dialog "AppleScript error: " & errMsg
end try
EOF

echo "Unmounting DMG..."
# Unmount the DMG with retries
for i in {1..5}; do
    if hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null; then
        echo "✅ DMG unmounted successfully"
        break
    else
        echo "⏳ Retrying unmount (attempt $i/5)..."
        sleep 2
        # Force unmount if needed
        if [ $i -eq 5 ]; then
            hdiutil detach "$MOUNT_DIR" -force -quiet 2>/dev/null || true
        fi
    fi
done

echo "🔧 Finalizing DMG..."

# Convert to final read-only DMG
hdiutil convert "$TEMP_DMG_PATH" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"

# Clean up
rm -f "$TEMP_DMG_PATH"
rm -rf "$TEMP_DIR"

# Get file size
DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')

echo "✅ DMG created successfully!"
echo "📍 Location: $DMG_PATH"
echo "📏 Size: $DMG_SIZE"
echo ""
echo "🎉 Mac Snap installer is ready for distribution!"

# Verify DMG
if hdiutil verify "$DMG_PATH" > /dev/null 2>&1; then
    echo "✅ DMG verification passed"
else
    echo "⚠️  DMG verification failed"
fi