#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="dist/茶茶手账.app"
if [ ! -d "$APP" ]; then bash scripts/build-mac.sh; fi
mkdir -p build/dmg
# Staging is build-only; never includes user data.
ditto "$APP" "build/dmg/茶茶手账.app"
if [ ! -L build/dmg/Applications ]; then ln -s /Applications build/dmg/Applications; fi
cp docs/安装说明.txt build/dmg/
hdiutil create -volname "茶茶手账" -srcfolder build/dmg -ov -format UDZO "dist/茶茶手账-1.0.0-macos-$(uname -m).dmg"
ditto -c -k --keepParent "$APP" "dist/茶茶手账-1.0.0-macos-$(uname -m).zip"
