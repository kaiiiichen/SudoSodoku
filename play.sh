#!/bin/bash

# Run SudoSodoku app in iOS Simulator
# Usage: ./play.sh

set -e

PROJECT_NAME="SudoSodoku"
SCHEME="SudoSodoku"
PROJECT_PATH="SudoSodoku.xcodeproj"

echo "🎮 Preparing to run $PROJECT_NAME in simulator..."
echo ""

# 1. Find available iPhone simulator
echo "📱 Finding available iPhone simulator..."
# Get full information of first iPhone from available devices list
SIMULATOR_LINE=$(xcrun simctl list devices available | grep -i "iPhone" | head -1)
if [ -z "$SIMULATOR_LINE" ]; then
    echo "❌ No available iPhone simulator found"
    exit 1
fi

# Extract simulator ID (UUID in parentheses)
SIMULATOR_ID=$(echo "$SIMULATOR_LINE" | grep -oE '\([A-F0-9-]+\)' | head -1 | tr -d '()')
# Extract simulator name (part before parentheses)
SIMULATOR_NAME=$(echo "$SIMULATOR_LINE" | sed -E 's/^[[:space:]]*([^(]+).*/\1/' | xargs)

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ Unable to parse simulator ID"
    exit 1
fi

echo "✅ Using simulator: $SIMULATOR_NAME ($SIMULATOR_ID)"
echo ""

# 2. Boot simulator
echo "🖥️  Booting simulator..."
SIMULATOR_STATUS=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -oE "(Booted|Shutdown)" | head -1)

if [ "$SIMULATOR_STATUS" = "Shutdown" ] || [ -z "$SIMULATOR_STATUS" ]; then
    echo "   Booting..."
    xcrun simctl boot "$SIMULATOR_ID" 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ Simulator booted successfully"
        sleep 4
    else
        echo "   ⚠️  Simulator may already be booting"
        sleep 2
    fi
else
    echo "   ✅ Simulator already running"
fi

# Open Simulator app
open -a Simulator 2>&1
sleep 2
echo ""

# 3. Build and run
echo "🔨 Building and running app..."
echo "   (This may take some time, please wait...)"
echo ""

xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    build \
    -quiet

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# 4. Install and launch
APP_PATH=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration Debug -sdk iphonesimulator -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | head -1 | sed 's/.*= *//' | xargs)/SudoSodoku.app

if [ ! -d "$APP_PATH" ]; then
    # Try to find in DerivedData
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "SudoSodoku.app" -type d | head -1)
fi

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Built app not found"
    exit 1
fi

echo "📲 Installing app..."
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

# Get Bundle ID
BUNDLE_ID=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | head -1 | sed 's/.*= *//' | xargs)

if [ -z "$BUNDLE_ID" ]; then
    BUNDLE_ID="com.kaichen.SudoSodoku"
fi

echo "🚀 Launching app..."
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID" 2>&1 || true

echo ""
echo "✅ Done! The app should be running in the simulator now"
echo "💡 If the app didn't open automatically, tap the SudoSodoku app icon in the simulator"
