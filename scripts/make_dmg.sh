#!/bin/bash
# 制作发布用 dmg（包含 App + 应用程序文件夹快捷方式，标准拖拽安装体验）
# 用法: ./scripts/make_dmg.sh [版本号，默认读 Info.plist]
set -euo pipefail
cd "$(dirname "$0")/.."

APP="$HOME/Applications/mactowin.app"
[ -d "$APP" ] || { echo "!! 先运行 ./scripts/build_app.sh"; exit 1; }

VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)}"
DMG="mactowin-$VERSION.dmg"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP" "$STAGE/mactowin.app"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname mactowin -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
echo "==> 完成: $(pwd)/$DMG"
