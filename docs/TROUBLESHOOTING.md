# Troubleshooting

## `container` is not found

**Symptoms:** dashboard buttons fail and error says command missing.

**Checks:**

- confirm you are on an Apple silicon Mac running macOS 26.0 or newer
- run `container --version`
- verify the binary is reachable by the app through a standard path or `PATH`
- open **Settings > Apple Container Runtime** and use **Check for updates** to download/open the latest Apple Container installer from GitHub
- ensure the binary is executable:

```bash
which container
```

## Apple Container update check fails

- Confirm network access to [apple/container releases](https://github.com/apple/container/releases).
- Retry **Check for updates** from Settings.
- If GitHub is reachable in a browser but the app still fails, install the latest signed `.pkg` manually from the releases page.
- After installation, run **Refresh runtime** or restart Container Desktop.

## App is not opening or crashes immediately

- Confirm the Mac is running macOS 26.0 or newer. Earlier releases are outside the supported runtime floor for Apple `container`.
- Rebuild in release mode:

```bash
swift build --configuration release
```

- Launch through the app-bundle script:

```bash
./script/build_and_run.sh --verify
```

## Converter output is unexpected

The current converter path is explicitly marked MVP and simplified.

- Verify input parsing manually.
- Run resulting commands stepwise in Terminal.
- open an issue with the input sample and generated output.

## Command executes but returns a non-zero code

- Capture and inspect full output in Dashboard logs.
- retry with equivalent command from Terminal to isolate app/UI factors.
- check `container` command permissions and context (resource limits, daemon state, image availability).

## Logs are empty

- Confirm the command writes to standard output/error.
- check that the command path and working directory are accessible.
- if using third-party wrappers, run the same command directly in Terminal first.

## SwiftPM tests fail during codesign on external volumes

On some external or migrated volumes, macOS may attach `com.apple.provenance`
metadata to generated `.xctest` bundles. If `swift test` fails with
`resource fork, Finder information, or similar detritus not allowed`, build the
test bundle in a temporary local path:

```bash
CLANG_MODULE_CACHE_PATH=/private/tmp/containerdesktop-module-cache \
  swift test --jobs 1 --build-path /private/tmp/containerdesktop-swiftpm-test-build
```
