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

By default, the bundle is staged to `dist/Container Desktop.app`.

## Local release artifacts (`./script/package_release.sh`)

- `--zip` (default): creates a release zip in `dist/release/`.
- `--dmg`: creates a local unsigned dmg in `dist/release/`.

Examples:

```bash
./script/package_release.sh --zip
./script/package_release.sh --dmg
```

Override metadata with:

- `CONTAINER_DESKTOP_PRODUCT_NAME` — SwiftPM executable name (default `ContainerDesktop`)
- `CONTAINER_DESKTOP_BUNDLE_NAME` — staged `.app` name (default `Container Desktop`)
- `CONTAINER_DESKTOP_BUNDLE_ID` — `Info.plist` `CFBundleIdentifier`
- `CONTAINER_DESKTOP_MIN_SYSTEM_VERSION` — minimum macOS version
- `CONTAINER_DESKTOP_PACKAGE_VERSION` — release version suffix (defaults to UTC date)

Legacy `AURA_*` environment variables are still accepted as fallbacks for local scripts.

No notarization credentials are required for either output.
