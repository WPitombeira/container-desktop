# Usage Guide

## Overview

Container Desktop is organized around operational macOS views:

- Dashboard: execute and inspect `container` commands
- Containers, Images, Volumes, Networks: resource-oriented lists
- Converter: convert common `docker run` commands into Apple Container args
- Logs: inspect app-side activity
- Settings: local preferences, runtime discovery, and Apple Container install/update checks

The app requires an Apple silicon Mac running macOS 26.0 or newer because it wraps Apple `container`.

## Running a command from Dashboard

1. Open Container Desktop.
2. Select **Dashboard**.
3. Click **Test Container CLI** in the toolbar.
4. Check the live log output for `container` usage details.

This path is useful to verify CLI setup before using operational commands.

## Installing or updating Apple Container

1. Select **Settings**.
2. Use **Refresh runtime** to discover the local `container` binary.
3. Use **Check for updates** to fetch the latest release metadata from [apple/container](https://github.com/apple/container/releases).
4. Review the latest release version, changelog, and install plan.
5. Click **Install Apple Container** or **Install update** and confirm the prompt.
6. Complete the installation in macOS Installer.

The app prefers Apple's signed `.pkg` installer asset from the GitHub release. **Auto-check for updates** checks release metadata when Settings opens. **Auto-download updates** can download the installer package when an update is available, but installation still requires user confirmation in macOS Installer.

## Converting Docker workflow definitions

1. Select **Converter**.
2. Paste a `docker run ...` command.
3. Click **Convert**.
4. Review generated command text.
5. Copy/adapt the output and run through the CLI in Terminal first if needed.

Current converter behavior is an MVP helper. It supports common `docker run` flags and simplified service models; it does not claim full Docker or Compose syntax coverage.

## Container logs

- Logs are displayed in the in-app console as plain text.
- Logs include app actions and command output/error text from executed CLI invocations.
- Clear old logs from the dashboard or logs view before testing a new scenario.

## CLI fallback

If needed, copy the generated command or use Terminal directly:

```bash
container --help
```

Use this when validating exact argument behavior.
