#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="dist/茶茶手账.app"
if [ ! -d "$APP" ]; then bash scripts/build-mac.sh; fi
# Stage outside cloud-synced folders so Finder metadata cannot invalidate signing.
STAGE=$(mktemp -d /private/tmp/tea-diary-package.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/image"
ditto --norsrc --noextattr "$APP" "$STAGE/image/茶茶手账.app"
xattr -cr "$STAGE/image/茶茶手账.app"
codesign --force --deep --sign - "$STAGE/image/茶茶手账.app"
codesign --verify --deep --strict "$STAGE/image/茶茶手账.app"
ln -s /Applications "$STAGE/image/Applications"
cp docs/安装说明.txt "$STAGE/image/"
hdiutil create -volname "茶茶手账" -srcfolder "$STAGE/image" -ov -format UDZO "dist/茶茶手账-1.0.0-macos-$(uname -m).dmg"
ditto --norsrc --noextattr -c -k --keepParent "$STAGE/image/茶茶手账.app" "dist/茶茶手账-1.0.0-macos-$(uname -m).zip"
