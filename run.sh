#!/bin/bash

# Run SudoSodoku in iOS Simulator
# Usage: ./run.sh

set -e

PROJECT_NAME="SudoSodoku"
SCHEME="SudoSodoku"
PROJECT_PATH="SudoSodoku.xcodeproj"
# Try to auto-detect Bundle ID, use default if failed
BUNDLE_ID=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | head -1 | sed 's/.*= *//' | xargs)
if [ -z "$BUNDLE_ID" ]; then
    BUNDLE_ID="com.yourcompany.SudoSodoku"
fi

echo "🚀 Preparing to run $PROJECT_NAME in simulator..."
echo ""

# 1. Find available iPhone simulator
echo "📱 Finding available iPhone simulator..."
SIMULATOR=$(xcrun simctl list devices available | grep -i "iPhone" | head -1 | sed -E 's/.*\(([^)]+)\).*/\1/')

if [ -z "$SIMULATOR" ]; then
    echo "❌ No available iPhone simulator found"
    echo "💡 Tip: Please create a simulator in Xcode, or run: xcrun simctl list devices"
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices available | grep -i "iPhone" | head -1 | sed -E 's/^[[:space:]]*([^(]+).*/\1/' | xargs)
echo "✅ Found simulator: $SIMULATOR_NAME ($SIMULATOR)"
echo ""

# 2. Build project
echo "🔨 Building project..."
BUILD_OUTPUT=$(xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -sdk iphonesimulator \
    -derivedDataPath ./build \
    build 2>&1)

echo "$BUILD_OUTPUT" | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" || echo "$BUILD_OUTPUT" | tail -10

if echo "$BUILD_OUTPUT" | grep -q "BUILD FAILED"; then
    echo "❌ Build failed, please check error messages"
    exit 1
fi

if ! echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
    echo "⚠️  Unable to confirm build status, continuing..."
fi

echo "✅ Build completed"
echo ""

# 3. Find built .app file
APP_PATH=$(find ./build -name "SudoSodoku.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Built app not found"
    exit 1
fi

echo "📦 Found app: $APP_PATH"
echo ""

# 4. Boot simulator (if not running)
echo "🖥️  Booting simulator..."
SIMULATOR_STATUS=$(xcrun simctl list devices | grep "$SIMULATOR" | grep -o "(Booted\|Shutdown)" | head -1)

if [ "$SIMULATOR_STATUS" = "Shutdown" ]; then
    echo "   Booting..."
    xcrun simctl boot "$SIMULATOR" 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ Unable to boot simulator"
        exit 1
    fi
    # Wait for simulator to fully boot
    echo "   Waiting for simulator to boot..."
    sleep 5
else
    echo "✅ Simulator already running"
fi

# Open Simulator app (if not open)
open -a Simulator 2>&1 || true
sleep 2

# 5. Install app
echo "📲 Installing app to simulator..."
xcrun simctl install "$SIMULATOR" "$APP_PATH"

if [ $? -ne 0 ]; then
    echo "❌ Installation failed"
    exit 1
fi

echo "✅ Installation successful"
echo ""

# 6. Launch app
echo "🎮 Launching app..."
xcrun simctl launch "$SIMULATOR" "$BUNDLE_ID" 2>/dev/null || {
    # If Bundle ID doesn't work, try launching by app name
    echo "⚠️  Trying to launch by app name..."
    open -a Simulator
    sleep 1
}

echo ""
echo "✅ Done! The app should be running in the simulator now"
echo "💡 Tip: If the app didn't open automatically, manually tap the app icon in the simulator"
