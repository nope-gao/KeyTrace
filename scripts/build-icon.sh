#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
destination="${1:?Usage: build-icon.sh destination.icns}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir "$work/AppIcon.iconset"
swift -module-cache-path "${TMPDIR:-/tmp}/keytrace-icon-swift-cache" "$root/scripts/render-icon.swift" "$root/Resources/AppIcon.svg" "$work/master.png"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$work/master.png" --out "$work/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$work/master.png" --out "$work/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$work/AppIcon.iconset" -o "$destination"
