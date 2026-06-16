#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/Recapped.app"

cd "$ROOT"
swift build -c release --product Recapped

rm -rf "$APP" "$DIST/Recapped-macOS.zip"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/.build/release/Recapped" "$APP/Contents/MacOS/Recapped"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Recapped</string>
  <key>CFBundleIdentifier</key>
  <string>app.recapped.mac</string>
  <key>CFBundleName</key>
  <string>Recapped</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
</dict>
</plist>
PLIST

cd "$DIST"
zip -qry Recapped-macOS.zip Recapped.app
echo "$DIST/Recapped-macOS.zip"
