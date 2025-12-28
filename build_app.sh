#!/bin/bash
set -e

APP_NAME="SwiftCull"
ICON_SOURCE="AppIcon.svg"
ICON_SET="AppIcon.iconset"
ICON_OUTPUT="AppIcon.icns"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
ZIP_NAME="$APP_NAME-v1.0.0-macOS.zip"

echo "🚀 Starting build process for $APP_NAME..."

# 1. Generate Icons
echo "🎨 Generating icons from $ICON_SOURCE..."
if [ -f "$ICON_SOURCE" ]; then
    # Create high-res PNG from SVG
    # using sips/qlmanage trick or rsvg-convert if available, falling back to qlmanage
    qlmanage -t -s 1024 -o . "$ICON_SOURCE"
    mv "${ICON_SOURCE}.png" AppIcon.png
    
    mkdir -p "$ICON_SET"
    
    sips -z 16 16     AppIcon.png --out "$ICON_SET/icon_16x16.png"
    sips -z 32 32     AppIcon.png --out "$ICON_SET/icon_16x16@2x.png"
    sips -z 32 32     AppIcon.png --out "$ICON_SET/icon_32x32.png"
    sips -z 64 64     AppIcon.png --out "$ICON_SET/icon_32x32@2x.png"
    sips -z 128 128   AppIcon.png --out "$ICON_SET/icon_128x128.png"
    sips -z 256 256   AppIcon.png --out "$ICON_SET/icon_128x128@2x.png"
    sips -z 256 256   AppIcon.png --out "$ICON_SET/icon_256x256.png"
    sips -z 512 512   AppIcon.png --out "$ICON_SET/icon_256x256@2x.png"
    sips -z 512 512   AppIcon.png --out "$ICON_SET/icon_512x512.png"
    sips -z 1024 1024 AppIcon.png --out "$ICON_SET/icon_512x512@2x.png"
    
    iconutil -c icns "$ICON_SET" -o "$ICON_OUTPUT"
    echo "✅ Icons generated."
else
    echo "⚠️  Warning: $ICON_SOURCE not found. Skipping icon generation."
fi

# 2. Build Release
echo "🔨 Building release version..."
swift build -c release

# 3. Create App Bundle
echo "📦 Creating App Bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Copy resources
if [ -f "$ICON_OUTPUT" ]; then
    cp "$ICON_OUTPUT" "$APP_BUNDLE/Contents/Resources/"
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.nginxdev.swiftcull</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.1</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 nginxdev. All rights reserved.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.photography</string>
</dict>
</plist>
EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 5. cleanup
echo "🧹 Cleaning up intermediate files..."
rm -f AppIcon.png
rm -rf "$ICON_SET"

echo "✅ Build complete! Artifact: $APP_BUNDLE"
