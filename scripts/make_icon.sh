#!/bin/bash
# 生成 Resources/AppIcon.icns
set -euo pipefail
cd "$(dirname "$0")/.."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "==> 绘制 1024px 图标"
swift scripts/make_icon.swift "$TMP/icon_1024.png"

echo "==> 生成 iconset"
ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
for spec in "16x16:16" "16x16@2x:32" "32x32:32" "32x32@2x:64" "128x128:128" "128x128@2x:256" "256x256:256" "256x256@2x:512" "512x512:512" "512x512@2x:1024"; do
    name="${spec%%:*}"
    px="${spec##*:}"
    sips -z "$px" "$px" "$TMP/icon_1024.png" --out "$ICONSET/icon_${name}.png" >/dev/null
done

echo "==> iconutil"
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
echo "==> 完成: Resources/AppIcon.icns"
