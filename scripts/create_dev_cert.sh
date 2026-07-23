#!/bin/bash
# 创建本机自签名开发证书「mactowin Local Dev」
# 解决 ad-hoc 签名导致 TCC 授权（Finder 控制 / 辅助功能）每次都重新弹窗的问题
# 一次创建，永久有效；仅用于本机开发，分发仍需 Developer ID + 公证
set -euo pipefail

NAME="mactowin Local Dev"

if security find-certificate -c "$NAME" login.keychain >/dev/null 2>&1; then
    echo "证书已存在: $NAME"
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/openssl.cnf" <<EOF
[ req ]
distinguished_name = dn
x509_extensions = ext
prompt = no
[ dn ]
CN = $NAME
[ ext ]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
subjectKeyIdentifier = hash
EOF

echo "==> 生成自签名证书（10 年有效）"
openssl req -x509 -newkey rsa:2048 \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
    -days 3650 -nodes -sha256 -config "$TMP/openssl.cnf" 2>/dev/null

openssl pkcs12 -export \
    -out "$TMP/cert.p12" \
    -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -passout pass:mactowin-temp

echo "==> 导入登录钥匙串"
security import "$TMP/cert.p12" -k login.keychain \
    -T /usr/bin/codesign -T /usr/bin/security -P "mactowin-temp"

echo "==> 完成: $NAME"
echo "    以后 ./scripts/build_app.sh 会自动使用这个身份签名，TCC 授权只需一次。"
