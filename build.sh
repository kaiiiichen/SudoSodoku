#!/bin/bash

# SudoSodoku iOS Project Build Script
# Usage:
#   ./build.sh          # Build Debug version (default)
#   ./build.sh release  # Build Release version
#   ./build.sh clean    # Clean build artifacts

set -e

PROJECT_NAME="SudoSodoku"
SCHEME="SudoSodoku"
PROJECT_PATH="SudoSodoku.xcodeproj"

# Default build configuration
BUILD_CONFIG="${1:-debug}"

case "$BUILD_CONFIG" in
    debug|Debug|DEBUG)
        CONFIGURATION="Debug"
        ;;
    release|Release|RELEASE)
        CONFIGURATION="Release"
        ;;
    clean|Clean|CLEAN)
        echo "🧹 Cleaning build artifacts..."
        xcodebuild clean -project "$PROJECT_PATH" -scheme "$SCHEME" 2>&1 | grep -E "(error|warning|Clean Succeeded|Clean Failed)" || true
        exit 0
        ;;
    *)
        echo "❌ Unknown build configuration: $BUILD_CONFIG"
        echo "Usage: ./build.sh [debug|release|clean]"
        exit 1
        ;;
esac

echo "🔨 Building $PROJECT_NAME ($CONFIGURATION)..."
echo ""

# Build project (similar to Xcode's Cmd+B)
# Build and display key information
BUILD_OUTPUT=$(xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphonesimulator \
    build 2>&1)

# Display build output (filter redundant information)
echo "$BUILD_OUTPUT" | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED|Compiling|Linking)" || echo "$BUILD_OUTPUT" | tail -20

BUILD_STATUS=$?

echo ""
if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ Build succeeded! (Similar to Xcode's Cmd+B)"
else
    echo "❌ Build failed! Please check the error messages above"
    exit 1
fi
