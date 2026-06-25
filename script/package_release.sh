#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./script/package_release.sh [--zip|--dmg]

Builds a release SwiftPM app bundle into dist/, then creates:
  --zip   a local zip archive (default)
  --dmg   a local unsigned .dmg archive

Environment overrides:
  AURA_PRODUCT_NAME     SwiftPM executable product name (default: Aura)
  AURA_BUNDLE_NAME      Bundle name to stage in dist/ (default: Aura)
  AURA_BUNDLE_ID        Bundle identifier for Info.plist (default: com.container.desktop.aura)
  AURA_MIN_SYSTEM_VERSION Minimum macOS version for Info.plist (default: 14.0)
USAGE
}

MODE="${1:---zip}"
if [[ "$MODE" == "--help" || "$MODE" == "-h" ]]; then
  usage
  exit 0
fi

if [[ "$MODE" != "--zip" && "$MODE" != "--dmg" ]]; then
  usage
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="${AURA_PRODUCT_NAME:-Aura}"
BUNDLE_NAME="${AURA_BUNDLE_NAME:-$PRODUCT_NAME}"
BUNDLE_ID="${AURA_BUNDLE_ID:-com.container.desktop.aura}"
MIN_SYSTEM_VERSION="${AURA_MIN_SYSTEM_VERSION:-14.0}"

DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$BUNDLE_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$PRODUCT_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
RELEASE_DIR="$DIST_DIR/release"

VERSION="${AURA_PACKAGE_VERSION:-$(date -u +%Y%m%d)}"
ARCHIVE_BASENAME="${BUNDLE_NAME}-macos-${VERSION}"
ZIP_PATH="$RELEASE_DIR/${ARCHIVE_BASENAME}.zip"
DMG_PATH="$RELEASE_DIR/${ARCHIVE_BASENAME}.dmg"

write_info_plist() {
  cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$PRODUCT_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$BUNDLE_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST
}

/usr/bin/swift build --configuration release
BUILD_BIN_DIR="$(/usr/bin/swift build --show-bin-path --configuration release)"
BUILT_BINARY="$BUILD_BIN_DIR/$PRODUCT_NAME"
if [[ ! -x "$BUILT_BINARY" ]]; then
  echo "Release build did not produce executable: $BUILT_BINARY" >&2
  exit 1
fi

rm -rf "$APP_BUNDLE" "$RELEASE_DIR"
mkdir -p "$APP_MACOS" "$RELEASE_DIR"
/bin/cp "$BUILT_BINARY" "$APP_BINARY"
/bin/chmod +x "$APP_BINARY"
write_info_plist

if [[ "$MODE" == "--zip" ]]; then
  /usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
  echo "Created $ZIP_PATH"
  exit 0
fi

if /usr/bin/command -v hdiutil >/dev/null 2>&1; then
  /usr/bin/hdiutil create -srcfolder "$APP_BUNDLE" -volname "$BUNDLE_NAME" -ov -format UDZO "$DMG_PATH"
  echo "Created $DMG_PATH"
else
  echo "hdiutil not available; cannot build dmg on this host." >&2
  exit 1
fi
