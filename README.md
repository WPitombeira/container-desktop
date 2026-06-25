# Container Desktop

Container Desktop is an open-source macOS SwiftUI app that wraps Apple’s `container` CLI in a small GUI, helping developers manage local container workflows without Docker Desktop’s heavier background stack.

This repository currently builds and ships the app target as **Aura** in `Package.swift`; for users and documentation we refer to the product as **Container Desktop**. A compatibility note is included to avoid confusion while the package metadata is aligned.

## Purpose

Container Desktop provides:

- A native macOS control surface for Apple `container` commands
- A lightweight dashboard for command output and local runtime status
- Operational views for containers, images, volumes, networks, logs, converter, and settings
- A conversion workflow for common `docker run` flags and simplified Compose service models
- A low-overhead control plane for teams that want a simpler local container GUI

## Why this is low-resource

Container Desktop is intentionally minimal:

- It is a Swift app plus a CLI bridge, not a VM manager or background daemon suite.
- It does not ship its own orchestrator/runtime.
- The app uses short-lived `Process` calls to execute `container` command invocations.
- It does not run a local UI webserver or polling service by default.

That design is intended to keep memory/CPU overhead lower than Docker Desktop-style stacks because the control plane is only the shell bridge and native app UI. Publish measured benchmark claims only after running a repeatable resource comparison on your target hardware.

## Requirements

- macOS 14.0+
- Swift 5.9+
- Apple **`container` CLI** available (must be reachable by the app)
- Optional: command-line developer tooling (`git`, `swift`) for source builds

The app resolves `container` from common install paths plus the process `PATH` (`/usr/bin`, `/usr/local/bin`, `/opt/homebrew/bin`, `/opt/local/bin`, and PATH-derived candidates).

## Install / Build / Run

```bash
git clone https://github.com/WPitombeira/container-desktop.git
cd container-desktop
swift build --configuration release
```

For a real macOS app bundle during development:

```bash
./script/build_and_run.sh
```

For a local unsigned release archive:

```bash
./script/package_release.sh --zip
```

### Apple Container CLI requirement

Make sure the CLI is installed and accessible:

```bash
container --version
```

If this fails:

```bash
ls -l /usr/local/bin/container
```

then install the CLI to a standard path or launch the app from an environment whose `PATH` includes the binary.

## Usage workflows

### 1) Validate container CLI connectivity

Use **Test Container CLI** from the toolbar. This executes `container --help` and shows command output in the in-app log console.

### 2) Convert a container intent

Go to **Converter**, paste a `docker run ...` command, and use **Convert**.
The app returns an Apple Container command form and surfaces warnings for unsupported flags.

Current converter behavior is MVP-grade. It supports common `docker run` flags (`--name`, `-p/--publish`, `-v/--volume`, `-e/--env`, `-d/--detach`, `--rm`, `--network`) and simplified service models; review generated commands before execution.

### 3) Monitor runtime output

The Dashboard log stream updates from the running process output and errors.

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for full details.

Common issues:

- **`container` not found**: check installation and `/usr/local/bin` resolution.
- **Command exits with non-zero code**: inspect in-app logs and run the equivalent command in Terminal to isolate flags/path/permission issues.
- **No log output**: validate that the command writes to stdout/stderr and that sandbox restrictions are not blocking process execution.
- **Converter output seems wrong**: conversion logic is still evolving; verify every generated command manually.

## Security and privacy

This app is designed with a local-first model:

- No analytics/tracking is built in.
- No remote telemetry is sent by default.
- Logs are captured in-app for transparency and debugging.

See [SECURITY.md](SECURITY.md) for reporting guidance.

## Project structure

- `src/` — SwiftUI app and conversion logic
- `docs/` — documentation set (architecture, usage, troubleshooting, roadmap)
- `Tests/` — SwiftPM tests for conversion, parsing, CLI discovery, and command models
- `Package.swift` — Swift package definition (`Aura` product today)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for issue conventions, coding expectations, and review checklist.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md).

## License

MIT. See [LICENSE](LICENSE).
