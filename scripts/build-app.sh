#!/usr/bin/env bash
# Evrensel (arm64 + x86_64) "Topnote.app" paketini build/ altına üretir.
# Kullanım: scripts/build-app.sh [--install]   (--install: ~/Applications'a kopyalar)
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Topnote.app"
VERSION="1.0.0"

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Topnote"

[ -f Resources/AppIcon.icns ] || swift scripts/make-icon.swift Resources/AppIcon.icns

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Topnote"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Topnote</string>
    <key>CFBundleDisplayName</key><string>Topnote</string>
    <key>CFBundleIdentifier</key><string>com.yigitbuyukeren.topnote</string>
    <key>CFBundleExecutable</key><string>Topnote</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleDevelopmentRegion</key><string>tr</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>© 2026 Yiğit Eren Büyükeren</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Hazır: $APP"

if [ "${1:-}" = "--install" ]; then
    mkdir -p "$HOME/Applications"
    rm -rf "$HOME/Applications/Topnote.app"
    cp -R "$APP" "$HOME/Applications/"
    echo "Kuruldu: ~/Applications/Topnote.app"
fi
