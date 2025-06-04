#!/bin/bash

# Mac Snap App Icon Generator
# Converts the SVG logo to all required macOS app icon sizes

set -e

# Configuration
LOGO_SVG="logo.svg"
ICON_DIR="MacSnapper/Assets.xcassets/AppIcon.appiconset"
TEMP_DIR=$(mktemp -d)

echo "🎨 Creating Mac Snap app icons from logo.svg..."

# Check if logo exists
if [ ! -f "$LOGO_SVG" ]; then
    echo "❌ Error: logo.svg not found in current directory"
    exit 1
fi

# Check if we have the required tools
if ! command -v rsvg-convert &> /dev/null; then
    echo "📦 Installing librsvg for SVG conversion..."
    brew install librsvg
fi

# Create temporary directory for icon generation
mkdir -p "$TEMP_DIR/icons"

echo "🔄 Converting SVG to PNG icons..."

# Define the sizes we need for macOS app icons
declare -a SIZES=("16" "32" "64" "128" "256" "512" "1024")

# Generate all required icon sizes
for size in "${SIZES[@]}"; do
    echo "  📐 Creating ${size}x${size} icon..."
    rsvg-convert -w $size -h $size "$LOGO_SVG" -o "$TEMP_DIR/icons/icon_${size}x${size}.png"

    # Also create 2x versions for retina displays (except for 1024 which doesn't need 2x)
    if [ $size -lt 1024 ]; then
        size_2x=$((size * 2))
        echo "  📐 Creating ${size}x${size}@2x (${size_2x}x${size_2x}) icon..."
        rsvg-convert -w $size_2x -h $size_2x "$LOGO_SVG" -o "$TEMP_DIR/icons/icon_${size}x${size}@2x.png"
    fi
done

echo "✅ PNG icons generated successfully!"

# Create the proper icon set structure
echo "📁 Creating app icon set..."

# Create iconset directory
ICONSET_DIR="$TEMP_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

# Copy icons with proper naming convention for iconset
cp "$TEMP_DIR/icons/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$TEMP_DIR/icons/icon_16x16@2x.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$TEMP_DIR/icons/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$TEMP_DIR/icons/icon_32x32@2x.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$TEMP_DIR/icons/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$TEMP_DIR/icons/icon_128x128@2x.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$TEMP_DIR/icons/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$TEMP_DIR/icons/icon_256x256@2x.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$TEMP_DIR/icons/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$TEMP_DIR/icons/icon_512x512@2x.png" "$ICONSET_DIR/icon_512x512@2x.png"

# Create .icns file
echo "🔧 Creating .icns file..."
iconutil -c icns "$ICONSET_DIR" -o "$TEMP_DIR/AppIcon.icns"

if [ -f "$TEMP_DIR/AppIcon.icns" ]; then
    echo "✅ AppIcon.icns created successfully!"

    # Copy the .icns file to the project (optional, for direct use)
    cp "$TEMP_DIR/AppIcon.icns" "AppIcon.icns"
    echo "📍 AppIcon.icns saved to project root"
else
    echo "❌ Failed to create .icns file"
    exit 1
fi

# Now copy individual PNG files to the Xcode asset catalog
echo "📂 Updating Xcode asset catalog..."

# Remove existing icon files (but keep Contents.json)
find "$ICON_DIR" -name "*.png" -delete 2>/dev/null || true

# Copy the correctly sized PNGs for Xcode asset catalog
# 16x16
cp "$TEMP_DIR/icons/icon_16x16.png" "$ICON_DIR/icon_16x16.png"
cp "$TEMP_DIR/icons/icon_16x16@2x.png" "$ICON_DIR/icon_16x16@2x.png"

# 32x32
cp "$TEMP_DIR/icons/icon_32x32.png" "$ICON_DIR/icon_32x32.png"
cp "$TEMP_DIR/icons/icon_32x32@2x.png" "$ICON_DIR/icon_32x32@2x.png"

# 128x128
cp "$TEMP_DIR/icons/icon_128x128.png" "$ICON_DIR/icon_128x128.png"
cp "$TEMP_DIR/icons/icon_128x128@2x.png" "$ICON_DIR/icon_128x128@2x.png"

# 256x256
cp "$TEMP_DIR/icons/icon_256x256.png" "$ICON_DIR/icon_256x256.png"
cp "$TEMP_DIR/icons/icon_256x256@2x.png" "$ICON_DIR/icon_256x256@2x.png"

# 512x512
cp "$TEMP_DIR/icons/icon_512x512.png" "$ICON_DIR/icon_512x512.png"
cp "$TEMP_DIR/icons/icon_512x512@2x.png" "$ICON_DIR/icon_512x512@2x.png"

# 1024x1024 (for iOS, but included in Contents.json)
cp "$TEMP_DIR/icons/icon_1024x1024.png" "$ICON_DIR/icon_1024x1024.png"

echo "✅ Xcode asset catalog updated!"

# Update Contents.json to reference the new icon files
echo "📝 Updating Contents.json..."

cat > "$ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_1024x1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "icon_1024x1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "filename" : "icon_1024x1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Contents.json updated with new icon references!"

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 Mac Snap app icon creation complete!"
echo ""
echo "✅ Generated files:"
echo "   📱 Individual PNG icons in MacSnapper/Assets.xcassets/AppIcon.appiconset/"
echo "   🔧 AppIcon.icns in project root"
echo "   📝 Updated Contents.json with proper references"
echo ""
echo "🔄 Next steps:"
echo "   1. Clean and rebuild the project in Xcode"
echo "   2. The new professional logo will appear as the app icon"
echo "   3. Test the app to see the new icon in Dock and Applications"
echo ""
echo "💡 Note: If icons don't update immediately, try:"
echo "   - Clean Build Folder in Xcode (⌘+⇧+K)"
echo "   - Restart Xcode"
echo "   - Clear icon cache: sudo rm -rf /Library/Caches/com.apple.iconservices.store"