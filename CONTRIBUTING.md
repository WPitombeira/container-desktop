# Contributing to Container Desktop

Thanks for taking the time to contribute. This repo keeps scope narrow and practical: docs and implementation should evolve together with a small, maintainable macOS surface.

## Ground rules

- Keep edits focused and incremental.
- Prioritize practical behavior over speculative architecture in initial PRs.
- Update docs when changing user-visible behavior.
- Ensure any security or privacy impact is called out in your PR description.

## Working on this repository

1. Fork and create a short-lived branch.
2. Keep PRs scoped to one objective.
3. Use clear commit messages (`scope: short description`).
4. Attach verification notes for each behavior touched.

## Local setup

Development requires an Apple silicon Mac running macOS 26.0+ with a Swift toolchain that includes the macOS 26 SDK. The app wraps Apple `container`, so lower macOS versions are outside the supported runtime target.

```bash
git clone https://github.com/WPitombeira/container-desktop.git
cd container-desktop
swift build
swift run
```

## PR checklist

Include in every PR:

- What changed and why
- Files touched and affected workflow
- Manual verification steps and results
- Any remaining risks and follow-ups

If you changed docs or workflow:

- Confirm terminology consistency with the product name (Container Desktop)
- Confirm compatibility note if package name remains Aura

## Code style

- Swift naming should be consistent with existing code.
- Prefer clarity and safety over cleverness.
- Keep comments brief and explain intent where behavior is not obvious.

## Tests

There is no strict minimum yet, but PRs should include:

- Build verification (`swift build`)
- If app logic changed, run-time check (`swift run` and basic interaction path)
- A brief note if tests were not added and why

## Issues and discussion

Use issues for:

- Bug reports with reproducible steps and logs
- Conversion edge cases and parser behavior gaps
- UX friction and accessibility concerns

## Security-sensitive contributions

If you touch any process execution or command-building path, include:

- Input validation plan
- Potential injection or command-substitution risks
- Error handling and user feedback updates
