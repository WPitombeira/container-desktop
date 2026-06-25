# Roadmap

## Short term (next milestones)

- Wire all resource-list views to `ContainerStateStore` instead of placeholder rows.
- Add persisted, user-configurable container binary path resolution.
- Add parser-backed Docker Compose conversion (YAML support + validation messages).
- Add explicit command copy-to-clipboard and safe dry-run mode.
- Expand tests for command execution, lifecycle actions, and real CLI output fixtures.
- Document versioned release process.

## Medium term

- Settings screen backed by persisted preferences.
- Structured logging levels and export options.
- Better container lifecycle workflows (start/stop/restart) with explicit UX.
- Accessibility pass for all core controls and status messaging.

# Long term

- Optional remote context support
- Extension points for compose profiles and advanced networking flags
- Hardened packaging and release automation metadata

## Compatibility note

The package/product is currently named `Aura` in `Package.swift`. This is tracked separately from the public-facing product name **Container Desktop**, and will likely be renamed as a follow-up metadata/code change.
