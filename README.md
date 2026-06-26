# Container Desktop

Container Desktop is an open-source macOS SwiftUI app that wraps Apple's [`container`](https://github.com/apple/container) CLI in a small GUI, helping developers manage local container workflows without Docker Desktop's heavier background stack.

Native macOS GUI for Apple's container CLI. A lightweight Docker Desktop alternative for Apple silicon Macs on macOS 26+.

## Purpose

Container Desktop provides:

- A native macOS control surface for Apple's [`container`](https://github.com/apple/container) commands
- A lightweight dashboard for command output and local runtime status
- Operational views for containers, images, volumes, networks, logs, converter, and settings
- A conversion workflow for common `docker run` flags and simplified Compose service models
- A Settings workflow that checks Apple's GitHub releases, shows the latest changelog, downloads the signed installer package, and opens macOS Installer after user confirmation
- A low-overhead control plane for teams that want a simpler local container GUI

## Why this is low-resource

Container Desktop is intentionally minimal:

- It is a Swift app plus a CLI bridge, not a VM manager or background daemon suite.
- It does not ship its own orchestrator/runtime.
- The app uses short-lived `Process` calls to execute `container` command invocations.
- It does not run a local UI webserver or polling service by default.

That design is intended to keep memory/CPU overhead lower than Docker Desktop-style stacks because the control plane is only the shell bridge and native app UI. Publish measured benchmark claims only after running a repeatable resource comparison on your target hardware.

## Requirements

- Apple silicon Mac running macOS 26.0+
- Xcode / Swift toolchain with the macOS 26 SDK
- Swift 5.9+
- Apple's **[`container` CLI](https://github.com/apple/container)** installed and reachable by the app through a standard path or `PATH`
- Optional: command-line developer tooling (`git`, `swift`) for source builds

Container Desktop inherits Apple's [`container`](https://github.com/apple/container) requirements. It is not intended to run on macOS 25 or earlier because Apple `container` depends on macOS 26 virtualization and networking features.

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

Container Desktop depends on Apple's [`container`](https://github.com/apple/container) tool. You can install it manually from the [Apple Container releases page](https://github.com/apple/container/releases), or use **Settings > Apple Container Runtime** in the app to check the latest GitHub release and open the signed installer package.

After installation, make sure the CLI is accessible:

```bash
container --version
```

If this fails:

```bash
ls -l /usr/local/bin/container
```

then install the CLI to a standard path or launch the app from an environment whose `PATH` includes the binary.

The app does not run privileged installers silently. When an install or update is available, it downloads the selected release asset only after an in-app action or enabled auto-download setting, then opens the `.pkg` in macOS Installer so the user can approve Apple's installer prompts.

## Usage workflows

### 1) Validate container CLI connectivity

Use **Test Container CLI** from the toolbar. This executes `container --help` and shows command output in the in-app log console.

### 2) Install or update Apple Container

Open **Settings > Apple Container Runtime**:

- **Refresh runtime** discovers the local `container` binary and version.
- **Check for updates** reads the latest release metadata from [`apple/container`](https://github.com/apple/container/releases).
- **Auto-check for updates** runs that release check when Settings opens.
- **Auto-download updates** downloads the signed installer package when an update is found; installation still requires user confirmation through macOS Installer.
- The release changelog is shown before installing when GitHub release notes are available.

### 3) Convert a container intent

Go to **Converter**, paste a `docker run ...` command, and use **Convert**.
The app returns an Apple Container command form and surfaces warnings for unsupported flags.

Current converter behavior is MVP-grade. It supports common `docker run` flags (`--name`, `-p/--publish`, `-v/--volume`, `-e/--env`, `-d/--detach`, `--rm`, `--network`) and simplified service models; review generated commands before execution.

### 4) Monitor runtime output

The Dashboard log stream updates from the running process output and errors.

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for full details.

Common issues:

- **`container` not found**: check installation and PATH resolution.
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
- `Package.swift` — Swift package definition (`ContainerDesktop` executable product)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for issue conventions, coding expectations, and review checklist.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md).

## License

MIT. See [LICENSE](LICENSE).
