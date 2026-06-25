# Security Policy

## Reporting a vulnerability

If you discover a security issue in Container Desktop:

1. Open a private report in the GitHub Security tab (or equivalent repo security mechanism).
2. Include a clear description, reproduction steps, and impact assessment.
3. If possible, include command outputs or logs (redact secrets and machine identifiers).

Please do **not** open public issues for unpatched vulnerabilities.

## Security focus areas

Container Desktop is a local-first app, but security attention is still required in:

- Command execution path to `container` (`Process` calls)
- Input used by conversion output generation
- Local log handling and path handling for CLI output
- Package/dependency trust chain and supply-chain integrity

## Hardening expectations

- Validate user input before interpolation into command arguments where future parser work is introduced.
- Keep sensitive values out of logs where possible.
- Prefer explicit allowlists for CLI flags and container arguments in parser pipelines.
- Follow principle of least privilege for any future helper processes.

## Supported versions

Security fixes are prioritized in active tracked branches. When a critical issue is fixed, patch notes will reference the minimum supported branch/tag to update.

