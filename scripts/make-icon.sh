#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/TeaDiary.iconset
for size in 16 32 64 128 256 512 1024; do
 sips -z "$size" "$size" web/assets/apple-tea.png --out "build/TeaDiary.iconset/$size.png" >/dev/null
done
python3 - <<'PY'
import pathlib,struct
p=pathlib.Path('build/TeaDiary.iconset')
chunks=[]
for size,kind in [(16,b'icp4'),(32,b'icp5'),(64,b'icp6'),(128,b'ic07'),(256,b'ic08'),(512,b'ic09'),(1024,b'ic10')]:
 data=(p/f'{size}.png').read_bytes();chunks.append(kind+struct.pack('>I',len(data)+8)+data)
body=b''.join(chunks)
pathlib.Path('build/TeaDiary.icns').write_bytes(b'icns'+struct.pack('>I',len(body)+8)+body)
PY
