# Troubleshooting

## `container` is not found

**Symptoms:** dashboard buttons fail and error says command missing.

**Checks:**

- run `container --version`
- verify the binary is reachable by the app through a standard path or `PATH`
- ensure the binary is executable:

```bash
which container
```

## App is not opening or crashes immediately

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

## SwiftPM tests fail during codesign

On some external or migrated volumes, macOS may attach `com.apple.provenance`
metadata to generated `.xctest` bundles. If `swift test` fails with
`resource fork, Finder information, or similar detritus not allowed`, clear the
attribute from the generated bundle and run the already-built tests:

```bash
xattr -rd com.apple.provenance .build/out/Products/Debug/AuraTests.xctest
codesign --force --sign - --timestamp=none .build/out/Products/Debug/AuraTests.xctest
swift test --skip-build
```
