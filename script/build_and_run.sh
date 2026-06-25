#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./script/build_and_run.sh [run|--debug|--logs|--telemetry|--verify]

Builds the SwiftPM GUI product and launches it as a packaged .app via `open -n`.

Optional overrides:
  CONTAINER_DESKTOP_PRODUCT_NAME        SwiftPM executable product name (default: ContainerDesktop)
  CONTAINER_DESKTOP_BUNDLE_NAME         Bundle name to stage in dist/ (default: Container Desktop)
  CONTAINER_DESKTOP_BUNDLE_ID           Bundle identifier (default: com.wpitombeira.containerdesktop)
  CONTAINER_DESKTOP_MIN_SYSTEM_VERSION  Minimum macOS version (default: 14.0)
  CONTAINER_DESKTOP_BUILD_CONFIGURATION Swift build configuration: debug|release (default: debug)
USAGE
}

MODE="${1:-run}"

case "$MODE" in
  run|--run|--debug|--logs|--telemetry|--verify|--help|-h)
    ;;
  *)
    usage
    exit 2
    ;;
esac

if [[ "$MODE" == "--help" || "$MODE" == "-h" ]]; then
  usage
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="${CONTAINER_DESKTOP_PRODUCT_NAME:-${AURA_PRODUCT_NAME:-ContainerDesktop}}"
BUNDLE_NAME="${CONTAINER_DESKTOP_BUNDLE_NAME:-${AURA_BUNDLE_NAME:-Container Desktop}}"
BUNDLE_ID="${CONTAINER_DESKTOP_BUNDLE_ID:-${AURA_BUNDLE_ID:-com.wpitombeira.containerdesktop}}"
MIN_SYSTEM_VERSION="${CONTAINER_DESKTOP_MIN_SYSTEM_VERSION:-${AURA_MIN_SYSTEM_VERSION:-14.0}}"
SWIFT_CONFIGURATION="${CONTAINER_DESKTOP_BUILD_CONFIGURATION:-${AURA_BUILD_CONFIGURATION:-debug}}"

DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$BUNDLE_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$PRODUCT_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

kill_existing() {
  local names=("$PRODUCT_NAME" "$BUNDLE_NAME" "Container Desktop")
  local name

  for name in "${names[@]}"; do
    /usr/bin/pkill -x "$name" >/dev/null 2>&1 || true
  done
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

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

build_and_stage() {
  local build_bin_dir
  local built_binary

  /usr/bin/swift build --configuration "$SWIFT_CONFIGURATION"
  build_bin_dir="$(/usr/bin/swift build --show-bin-path --configuration "$SWIFT_CONFIGURATION")"
  built_binary="$build_bin_dir/$PRODUCT_NAME"

  if [[ ! -x "$built_binary" ]]; then
    echo "SwiftPM build did not produce executable: $built_binary" >&2
    exit 1
  fi

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS"
  /bin/cp "$built_binary" "$APP_BINARY"
  /bin/chmod +x "$APP_BINARY"
  write_info_plist
}

kill_existing
build_and_stage

case "$MODE" in
  run)
    open_app
    ;;
  --logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$PRODUCT_NAME\""
    ;;
  --telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify)
    open_app
    /bin/sleep 1
    if /usr/bin/pgrep -x "$PRODUCT_NAME" >/dev/null; then
      /usr/bin/pgrep -x "$PRODUCT_NAME" | /usr/bin/xargs -n 1 echo
      exit 0
    fi
    echo "Process '$PRODUCT_NAME' did not start." >&2
    exit 1
    ;;
  --debug)
    /usr/bin/lldb -- "$APP_BINARY"
    ;;
esac
