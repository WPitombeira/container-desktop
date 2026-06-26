#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./script/package_release.sh [--zip|--dmg]

Builds a release SwiftPM app bundle into dist/, then creates:
  --zip   a local zip archive (default)
  --dmg   a local unsigned .dmg archive

Environment overrides:
  CONTAINER_DESKTOP_PRODUCT_NAME       SwiftPM executable product name (default: ContainerDesktop)
  CONTAINER_DESKTOP_BUNDLE_NAME        Bundle name to stage in dist/ (default: Container Desktop)
  CONTAINER_DESKTOP_BUNDLE_ID          Bundle identifier (default: com.wpitombeira.containerdesktop)
  CONTAINER_DESKTOP_MIN_SYSTEM_VERSION Minimum macOS version (default: 26.0)
  CONTAINER_DESKTOP_SWIFTPM_BUILD_PATH Optional SwiftPM build path override
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
PRODUCT_NAME="${CONTAINER_DESKTOP_PRODUCT_NAME:-${AURA_PRODUCT_NAME:-ContainerDesktop}}"
BUNDLE_NAME="${CONTAINER_DESKTOP_BUNDLE_NAME:-${AURA_BUNDLE_NAME:-Container Desktop}}"
BUNDLE_ID="${CONTAINER_DESKTOP_BUNDLE_ID:-${AURA_BUNDLE_ID:-com.wpitombeira.containerdesktop}}"
MIN_SYSTEM_VERSION="${CONTAINER_DESKTOP_MIN_SYSTEM_VERSION:-${AURA_MIN_SYSTEM_VERSION:-26.0}}"
SWIFTPM_BUILD_PATH="${CONTAINER_DESKTOP_SWIFTPM_BUILD_PATH:-${AURA_SWIFTPM_BUILD_PATH:-}}"

DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$BUNDLE_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$PRODUCT_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
RELEASE_DIR="$DIST_DIR/release"
ICON_FILE_NAME="ContainerDesktop.icns"
ICON_SOURCE="$ROOT_DIR/assets/AppIcon/$ICON_FILE_NAME"

VERSION="${CONTAINER_DESKTOP_PACKAGE_VERSION:-${AURA_PACKAGE_VERSION:-$(date -u +%Y%m%d)}}"
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
  <key>CFBundleIconFile</key>
  <string>$ICON_FILE_NAME</string>
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

kill_existing() {
  local names=("$PRODUCT_NAME" "$BUNDLE_NAME" "Container Desktop")
  local name

  for name in "${names[@]}"; do
    /usr/bin/pkill -x "$name" >/dev/null 2>&1 || true
  done
}

SWIFT_BUILD_ARGS=(build --configuration release)
if [[ -n "$SWIFTPM_BUILD_PATH" ]]; then
  SWIFT_BUILD_ARGS+=(--build-path "$SWIFTPM_BUILD_PATH")
fi

/usr/bin/swift "${SWIFT_BUILD_ARGS[@]}"
BUILD_BIN_DIR="$(/usr/bin/swift "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)"
BUILT_BINARY="$BUILD_BIN_DIR/$PRODUCT_NAME"
if [[ ! -x "$BUILT_BINARY" ]]; then
  echo "Release build did not produce executable: $BUILT_BINARY" >&2
  exit 1
fi

kill_existing
rm -rf "$APP_BUNDLE" "$RELEASE_DIR"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$RELEASE_DIR"
/bin/cp "$BUILT_BINARY" "$APP_BINARY"
/bin/chmod +x "$APP_BINARY"
if [[ ! -f "$ICON_SOURCE" ]]; then
  echo "App icon not found: $ICON_SOURCE" >&2
  exit 1
fi
/bin/cp "$ICON_SOURCE" "$APP_RESOURCES/$ICON_FILE_NAME"
write_info_plist
/usr/bin/xattr -cr "$APP_BUNDLE" >/dev/null 2>&1 || true

if [[ "$MODE" == "--zip" ]]; then
  /usr/bin/ditto -c -k --norsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
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
