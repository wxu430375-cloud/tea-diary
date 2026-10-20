#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP_VERSION=$(cat VERSION)
mkdir -p build/module-cache dist
bash scripts/make-icon.sh
export CLANG_MODULE_CACHE_PATH="$PWD/build/module-cache"
export SWIFT_MODULECACHE_PATH="$PWD/build/module-cache"
APP_DIST="$PWD/dist/茶茶手账.app"
# Cloud-synced Desktop folders may attach Finder metadata during signing.
# Build and sign in a clean temporary directory before replacing the output.
STAGE=$(mktemp -d /private/tmp/tea-diary-build.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
APP="$STAGE/茶茶手账.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -module-cache-path "$PWD/build/module-cache" -target "$(uname -m)-apple-macosx13.0" native/TeaDiary.swift -o "$APP/Contents/MacOS/TeaDiary" -framework AppKit -framework WebKit -framework Vision
swiftc -O -module-cache-path "$PWD/build/module-cache" native/OCR.swift -o build/tea-ocr -framework Vision -framework AppKit
ditto --norsrc --noextattr web "$APP/Contents/Resources/web"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleExecutable</key><string>TeaDiary</string><key>CFBundleIdentifier</key><string>studio.teacha.diary</string><key>CFBundleName</key><string>茶茶手账</string><key>CFBundleDisplayName</key><string>茶茶手账</string><key>CFBundleShortVersionString</key><string>$APP_VERSION</string><key>CFBundleVersion</key><string>4</string><key>LSMinimumSystemVersion</key><string>13.0</string><key>NSHighResolutionCapable</key><true/><key>CFBundleIconFile</key><string>TeaDiary.icns</string><key>NSHumanReadableCopyright</key><string>茶茶手账 · MIT License</string></dict></plist>
PLIST
if [ -f build/TeaDiary.icns ]; then cp build/TeaDiary.icns "$APP/Contents/Resources/"; fi
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
rm -rf "$APP_DIST"
ditto --norsrc --noextattr "$APP" "$APP_DIST"
echo "Built: $APP_DIST"
