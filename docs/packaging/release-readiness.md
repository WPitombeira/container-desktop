# Packaging Readiness (Local, Unsigned)

These scripts keep release prep local and low-friction for development.

## Development run (`./script/build_and_run.sh`)

Build + kill + run loop for the SwiftPM GUI app:

```bash
./script/build_and_run.sh                 # default: build and open app
./script/build_and_run.sh --verify         # build, open, and verify process is running
./script/build_and_run.sh --logs           # open + follow process logs
./script/build_and_run.sh --telemetry      # open + follow logs filtered by subsystem
./script/build_and_run.sh --debug          # launch binary under LLDB
```

By default, the bundle is staged to `dist/Aura.app`.
To stage a legacy `dist/Container Desktop.app` locally, set:

```bash
AURA_BUNDLE_NAME="Container Desktop" ./script/build_and_run.sh
```

## Local release artifacts (`./script/package_release.sh`)

- `--zip` (default): creates a release zip in `dist/release/`.
- `--dmg`: creates a local unsigned dmg in `dist/release/`.

Examples:

```bash
./script/package_release.sh --zip
./script/package_release.sh --dmg
```

Override metadata with:

- `AURA_PRODUCT_NAME` — SwiftPM executable name (default `Aura`)
- `AURA_BUNDLE_NAME` — staged `.app` name
- `AURA_BUNDLE_ID` — `Info.plist` `CFBundleIdentifier`
- `AURA_MIN_SYSTEM_VERSION` — minimum macOS version
- `AURA_PACKAGE_VERSION` — release version suffix (defaults to UTC date)

No notarization credentials are required for either output.
