# Architecture Notes

## Current architecture

Container Desktop follows a simple three-layer structure:

- **UI layer** (`src/AuraView.swift`, `src/Views/`)  
  SwiftUI shell, sidebar sections, resource lists, converter, logs, and settings.
- **Engine layer** (`src/engine/AuraEngine.swift`)  
  Bridges user actions to the container services and keeps UI-visible output state.
- **Service layer** (`src/Services/`, `src/Stores/`)  
  Resolves the `container` CLI, executes commands asynchronously, parses command output, and models local runtime state.
- **Conversion layer** (`src/Services/DockerConversionService.swift`, `src/engine/ConversionService.swift`)  
  Converts common Docker command/service inputs into Apple Container argument arrays.

## CLI contract

At runtime, the app resolves a `container` binary from common install paths and `PATH`, then executes:

`container <arguments>`

The UI writes process output to a local log buffer and updates status flags.

## Data flow

1. User action in UI.
2. Engine executes `container` process.
3. Output is captured to text output (`containerLogs`) and structured models where parsers are available.
4. UI state updates for status/error indicators.

## Non-goals (for now)

- Full replacement of every Docker runtime workflow
- Advanced Compose parser and schema validation
- Remote registry/account orchestration
- Multi-host/container-orchestration federation

## Known implementation constraints

- Resource-list UI is backed by `ContainerStateStore` and parser output from local `container` CLI commands.
- Converter currently covers common `docker run` flags and simplified service rows, not full Compose YAML.
- Packaging scripts produce local unsigned bundles; notarized distribution still needs signing credentials and CI.

These are explicit future work items in [ROADMAP.md](ROADMAP.md).
