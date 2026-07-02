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
- **MCP layer** (`src/MCP/`, `mcp/main.swift`)  
  Provides the `AuraMCP` stdio server, JSON-RPC tool handling, Agent connection config generation, project-local skill installation, and Docker Compose project provisioning.

## CLI contract

At runtime, the app resolves Apple's `container` CLI from common install paths and `PATH`, then executes:

`container <arguments>`

The UI writes process output to a local log buffer and updates status flags.
Because Apple's `container` CLI is supported only on Apple silicon Macs running macOS 26 or newer, Container Desktop uses macOS 26 as its package, bundle, and CI deployment floor.

## Data flow

1. User action in UI.
2. Engine executes `container` process.
3. Output is captured to text output (`containerLogs`) and structured models where parsers are available.
4. UI state updates for status/error indicators.

## Agent MCP flow

1. User opens **Settings > Agents MCP**.
2. The app generates an MCP config that runs `/usr/bin/swift run --package-path <path> AuraMCP`.
3. An Agent connects over stdio and calls `initialize`, `tools/list`, and `tools/call`.
4. `AuraMCPKit` dispatches calls to local tools:
   - `aura_install_skill` writes `.agents/skills/<skill>/SKILL.md`.
   - `aura_generate_compose_project` returns generated Compose files without writing them.
   - `aura_provision_compose_project` writes a Compose project and only starts it when `start: true`.
   - `aura_container_standards` returns the Docker/Compose standards Agents should follow.

The MCP server is intentionally local-first. It does not run a background daemon, expose a network port, or start containers unless the Agent explicitly requests startup.

## Non-goals (for now)

- Full replacement of every Docker runtime workflow
- Advanced Compose parser and schema validation
- Remote registry/account orchestration
- Multi-host/container-orchestration federation

## Known implementation constraints

- Runtime support starts at Apple silicon + macOS 26. Older macOS releases are intentionally unsupported.
- Resource-list UI is backed by `ContainerStateStore` and parser output from local `container` CLI commands.
- Converter currently covers common `docker run` flags and simplified service rows, not full Compose YAML.
- MCP Compose provisioning generates maintainable Compose project files, but it is not a full Compose schema parser.
- Packaging scripts produce local unsigned bundles; notarized distribution still needs signing credentials and CI.

These are explicit future work items in [ROADMAP.md](ROADMAP.md).
