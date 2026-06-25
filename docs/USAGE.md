# Usage Guide

## Overview

Container Desktop is organized around operational macOS views:

- Dashboard: execute and inspect `container` commands
- Containers, Images, Volumes, Networks: resource-oriented lists
- Converter: convert common `docker run` commands into Apple Container args
- Logs: inspect app-side activity
- Settings: local preferences and runtime notes

The app requires an Apple silicon Mac running macOS 26.0 or newer because it wraps Apple `container`.

## Running a command from Dashboard

1. Open Container Desktop.
2. Select **Dashboard**.
3. Click **Test Container CLI** in the toolbar.
4. Check the live log output for `container` usage details.

This path is useful to verify CLI setup before using operational commands.

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
