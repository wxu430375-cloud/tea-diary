#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP_VERSION=$(cat VERSION)
if [ ! -f .local/update-ed25519.key ]; then
  echo "Missing local release signing key. Restore .local/update-ed25519.key; do not rotate the trust root."
  exit 1
fi
mkdir -p updates build
swiftc -module-cache-path build/module-cache scripts/sign-update.swift -o build/sign-update
python3 - "$APP_VERSION" <<'PY'
import hashlib, json, pathlib, shutil, sys
version = sys.argv[1]
archive = pathlib.Path(f'dist/\u8336\u8336\u624b\u8d26-{version}-macos-arm64.zip')
destination = pathlib.Path(f'updates/TeaDiary-{version}-macos-arm64.zip')
shutil.copyfile(archive, destination)
release = dict(version=version, notes=pathlib.Path(f'docs/releases/{version}.txt').read_text().strip(),
    url=f'https://raw.githubusercontent.com/wxu430375-cloud/tea-diary/main/{destination}',
    sha256=hashlib.sha256(destination.read_bytes()).hexdigest(), size=destination.stat().st_size,
    minimumSystem='13.0', architecture='arm64')
pathlib.Path('build/update-payload.json').write_text(json.dumps(release, ensure_ascii=False, indent=2))
PY
build/sign-update build/update-payload.json updates/stable.json
echo "Prepared signed update feed; publish the archive before or together with stable.json."
