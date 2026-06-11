#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
APP_NAME="TorrServerMacInstaller"
DMG_APP_NAME="TorrServer"
BUNDLE_ID="com.dancheskus.TorrServerMacInstaller"
APP_VERSION="${APP_VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
VOLUME_NAME="TorrServer Installer"
DMG_FINAL="$DIST_DIR/$APP_NAME.dmg"
DMG_RW="$DIST_DIR/$APP_NAME-rw.dmg"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"
DMG_BACKGROUND_DIR="$DIST_DIR/dmg-background"
DMG_MOUNT_POINT="$DIST_DIR/dmg-mount"

cleanup_dmg_mount() {
  if mount | grep -q " on $DMG_MOUNT_POINT "; then
    hdiutil detach "$DMG_MOUNT_POINT" -quiet || true
  fi
}

trap cleanup_dmg_mount EXIT

cd "$ROOT_DIR"

swift build -c release --product "$APP_NAME" --triple arm64-apple-macosx13.0
swift build -c release --product "$APP_NAME" --triple x86_64-apple-macosx13.0

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

lipo -create \
  ".build/arm64-apple-macosx/release/$APP_NAME" \
  ".build/x86_64-apple-macosx/release/$APP_NAME" \
  -output "$MACOS_DIR/$APP_NAME"
chmod 755 "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/Resources/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"

ICONSET_DIR="$DIST_DIR/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
sips -z 16 16 "$ROOT_DIR/Resources/AppIcon.png" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$ROOT_DIR/Resources/AppIcon.png" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ROOT_DIR/Resources/AppIcon.png" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$ROOT_DIR/Resources/AppIcon.png" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ROOT_DIR/Resources/AppIcon.png" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$ROOT_DIR/Resources/AppIcon.png" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ROOT_DIR/Resources/AppIcon.png" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$ROOT_DIR/Resources/AppIcon.png" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ROOT_DIR/Resources/AppIcon.png" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>ru</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>bg</string>
    <string>en</string>
    <string>fr</string>
    <string>ro</string>
    <string>ru</string>
    <string>uk</string>
  </array>
  <key>CFBundleName</key>
  <string>TorrServer</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
  </dict>
</dict>
</plist>
PLIST

echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

rm -f "$DIST_DIR/$APP_NAME.zip"
ditto -c -k --keepParent "$APP_DIR" "$DIST_DIR/$APP_NAME.zip"

cleanup_dmg_mount
rm -rf "$DMG_STAGING_DIR" "$DMG_BACKGROUND_DIR" "$DMG_MOUNT_POINT" "$DMG_RW" "$DMG_FINAL"
mkdir -p "$DMG_STAGING_DIR/.background" "$DMG_BACKGROUND_DIR" "$DMG_MOUNT_POINT"

cp -R "$APP_DIR" "$DMG_STAGING_DIR/$DMG_APP_NAME.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

cat > "$DMG_BACKGROUND_DIR/background.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="660" height="660" viewBox="0 0 660 660">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#10202a"/>
      <stop offset="0.5" stop-color="#122733"/>
      <stop offset="1" stop-color="#0a131a"/>
    </linearGradient>
    <linearGradient id="accent" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#4ee6b4"/>
      <stop offset="1" stop-color="#68a8ff"/>
    </linearGradient>
    <filter id="softShadow" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="16" stdDeviation="20" flood-color="#000000" flood-opacity="0.36"/>
    </filter>
  </defs>

  <rect width="660" height="660" rx="0" fill="url(#bg)"/>
  <path d="M0 350 C135 300 228 392 368 330 C480 280 542 286 660 234 L660 420 L0 420 Z" fill="#102936" opacity="0.75"/>
  <path d="M0 68 C140 105 205 46 325 66 C459 88 526 154 660 102 L660 0 L0 0 Z" fill="#1d3844" opacity="0.58"/>
  <g opacity="0.1" stroke="#ffffff" stroke-width="1">
    <path d="M62 0 V420"/>
    <path d="M150 0 V420"/>
    <path d="M238 0 V420"/>
    <path d="M326 0 V420"/>
    <path d="M414 0 V420"/>
    <path d="M502 0 V420"/>
    <path d="M590 0 V420"/>
    <path d="M0 92 H660"/>
    <path d="M0 180 H660"/>
    <path d="M0 268 H660"/>
    <path d="M0 356 H660"/>
  </g>

  <text x="330" y="58" text-anchor="middle" fill="#f5fbff" font-family="-apple-system, BlinkMacSystemFont, 'SF Pro Display', Helvetica, Arial, sans-serif" font-size="24" font-weight="700">TorrServer для macOS</text>
  <text x="330" y="86" text-anchor="middle" fill="#b9c9d3" font-family="-apple-system, BlinkMacSystemFont, Helvetica, Arial, sans-serif" font-size="14">Перетащите приложение в папку Applications</text>

  <g filter="url(#softShadow)">
    <rect x="120" y="154" width="120" height="120" rx="26" fill="#f4fbff" opacity="0.09" stroke="#ffffff" stroke-opacity="0.14"/>
    <rect x="420" y="154" width="120" height="120" rx="26" fill="#f4fbff" opacity="0.09" stroke="#ffffff" stroke-opacity="0.14"/>
    <rect x="96" y="272" width="168" height="32" rx="13" fill="#edf6f8" opacity="0.58"/>
    <rect x="428" y="272" width="104" height="32" rx="13" fill="#edf6f8" opacity="0.58"/>
  </g>
  <path d="M266 222 H334" fill="none" stroke="url(#accent)" stroke-width="5.2" stroke-linecap="round"/>
  <path d="M318 204 L342 222 L318 240" fill="none" stroke="#d7fff1" stroke-width="5.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M270 244 C291 257 313 257 335 244" fill="none" stroke="#d7fff1" stroke-width="1.5" opacity="0.32" stroke-linecap="round"/>
</svg>
SVG

qlmanage -t -s 660 -o "$DMG_BACKGROUND_DIR" "$DMG_BACKGROUND_DIR/background.svg" >/dev/null 2>&1
mv "$DMG_BACKGROUND_DIR/background.svg.png" "$DMG_STAGING_DIR/.background/background.png"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDRW \
  -fs HFS+ \
  "$DMG_RW" >/dev/null

hdiutil attach "$DMG_RW" -readwrite -noverify -noautoopen -mountpoint "$DMG_MOUNT_POINT" >/dev/null

osascript <<APPLESCRIPT || echo "Warning: Finder DMG layout step failed; continuing without custom Finder window layout." >&2
set dmgFolder to POSIX file "$DMG_MOUNT_POINT" as alias
set bgFile to POSIX file "$DMG_MOUNT_POINT/.background/background.png" as alias
tell application "Finder"
  open dmgFolder
  delay 1
  set containerWindow to container window of dmgFolder
  set current view of containerWindow to icon view
  try
    set toolbar visible of containerWindow to false
    set statusbar visible of containerWindow to false
  end try
  set bounds of containerWindow to {100, 100, 760, 520}
  set theViewOptions to the icon view options of containerWindow
  set arrangement of theViewOptions to not arranged
  set icon size of theViewOptions to 104
  set background picture of theViewOptions to bgFile
  set position of item "$DMG_APP_NAME.app" of dmgFolder to {180, 220}
  set position of item "Applications" of dmgFolder to {480, 220}
  update dmgFolder without registering applications
  delay 1
  try
    close containerWindow
  end try
end tell
APPLESCRIPT

sync
hdiutil detach "$DMG_MOUNT_POINT" -quiet
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL" >/dev/null
rm -rf "$DMG_STAGING_DIR" "$DMG_BACKGROUND_DIR" "$DMG_MOUNT_POINT" "$DMG_RW"

echo "Built $APP_DIR"
echo "Created $DIST_DIR/$APP_NAME.zip"
echo "Created $DMG_FINAL"
