#!/bin/bash
# 构建 mactowin.app 并安装到 ~/Applications
# 注意：不能输出到项目目录 —— ~/Documents 开启了 iCloud 同步，
# fileprovider 会给 bundle 文件追加 xattr，导致签名被破坏、启动即被 AMFI 杀死
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
APP="$HOME/Applications/mactowin.app"

echo "==> swift build -c $CONFIG"
swift build -c "$CONFIG"
BIN_DIR=$(swift build -c "$CONFIG" --show-bin-path)

echo "==> 打包 $APP"
mkdir -p "$HOME/Applications"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/mactowin" "$APP/Contents/MacOS/mactowin"
cp Resources/Info.plist "$APP/Contents/Info.plist"

if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
else
    echo "    （无 AppIcon.icns，跳过图标。运行 scripts/make_icon.sh 可生成）"
fi

# 本地化资源（en.lproj 等）
for lproj in Resources/*.lproj; do
    [ -d "$lproj" ] || continue
    cp -R "$lproj" "$APP/Contents/Resources/"
done

# 清理扩展属性，否则 codesign 会拒绝（detritus not allowed）
xattr -cr "$APP"

DEV_IDENTITY="mactowin Local Dev"
if security find-certificate -c "$DEV_IDENTITY" login.keychain >/dev/null 2>&1; then
    echo "==> 用本机开发证书签名（TCC 授权可持续）"
    codesign --force --sign "$DEV_IDENTITY" "$APP"
else
    echo "==> 未找到开发证书，ad-hoc 签名（每次构建后 TCC 会重新要求授权）"
    echo "    建议先运行: ./scripts/create_dev_cert.sh"
    codesign --force --sign - "$APP"
fi

# 杀掉旧实例并重启
killall mactowin 2>/dev/null || true

echo "==> 完成: $APP"
echo "    运行: open $APP"
