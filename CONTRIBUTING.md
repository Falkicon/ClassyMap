# Contributing to ClassyMap

Thanks for your interest in contributing! ClassyMap is a simple addon that transforms the default circular minimap into a clean square shape. We welcome bug reports, feature suggestions, and code contributions.

## Getting Started

1. **Fork and clone** the repository
2. **Run the offline checks** below after making code changes.
3. **Install or sync the changed addon** to the client you will test. Ensure `ClassyMap.toc` sits directly in:
   ```
   World of Warcraft\_retail_\Interface\AddOns\ClassyMap\
   ```
4. **Test runtime changes in-game**. Restart for a first installation; use `/reload` for updates to an already loaded addon. Documentation-only changes need document checks, not a game reload.

## Development Guidelines

### Read the Docs First

- [AGENTS.md](AGENTS.md) – Addon-specific conventions and validation workflow
- [runtime-design.md](docs/runtime-design.md) – Refresh scheduling, ownership, metrics, and test boundaries
- [Mechanic/AGENTS.md](../Mechanic/AGENTS.md) – Additional tooling guidance when using the shared workspace; not required for standalone offline checks

### Code Style

- **Lua 5.1-compatible** syntax; offline mocks cover only the WoW APIs explicitly modeled by the tests
- **Local variables** – Prefer `local` for performance and scope control
- **Ace3 Framework** – Use the included Ace3 libraries for settings and initialization

### Performance Expectations

This addon prioritizes a minimal footprint:

- Avoid per-frame table allocations or `OnUpdate` polling
- Route changes through `RequestRefresh` with the smallest appropriate scope so repeated requests coalesce
- Use Mechanic's invocation counts and cumulative/peak durations to assess refresh work. Reported ms/s values are observation-window averages, not instantaneous CPU measurements.

### Current Client Compatibility

The declared client targets are Interface 120100 (Retail 12.1.0), 120105 (Retail 12.1.5) and 16001 (WoW: Forever beta) in [ClassyMap.toc](ClassyMap.toc). Forever runs the Retail UI and API, but `GetBuildInfo()` reports 16001, so never gate Retail code paths on a minimum build number. Record the actual client version/build used for live testing. When adding features:

- Ensure modifications are resilient to UI updates
- Follow the `OwnSet` ownership and conditional-restoration contract; preserve combat deferral and stale-callback cancellation
- Keep required library load order in `embeds.xml` aligned with `Libs/libs.json` and packaging rules in `.pkgmeta`
- Wrap user-facing strings in `L["KEY"]`, define the English baseline, and preserve the locale registration guards

## Submitting Changes

### Bug Reports

Open an issue with:

- Addon version, WoW version/build, and client (Retail or Beta)
- Steps to reproduce
- Any Lua errors from BugSack/BugGrabber

### Feature Requests

Open an issue describing:

- What you want to accomplish
- Why it fits the addon's scope (simple square minimap)

### Pull Requests

1. **Create a branch** from `main`
2. **Keep changes focused** – one feature or fix per PR
3. **Run relevant offline checks** and test runtime changes on the target client; record any live testing still outstanding
4. **Update docs** if adding settings or slash commands
5. **Describe your changes** in the PR description

## File Structure

| File | Purpose |
|------|---------|
| `ClassyMap.toc` | Addon manifest |
| `ClassyMap.lua` | Minimap mask, border, shape, and layout logic |
| `Core/init.lua` | Pure validation and combat queue logic |
| `Settings.lua` | AceConfig settings panel |
| `Mechanic.lua` | Optional Mechanic integration and diagnostics |
| `Core/core_spec.lua` / `tests/` | Core tests, strict UI mocks, real Ace integration, and repository checks |
| `.github/workflows/quality.yml` | Automated checks and tool versions |

## Testing Checklist

For runtime changes, exercise the affected behavior in-game after offline checks:

- [ ] Addon loads without errors (`/reload`)
- [ ] Minimap is correctly masked as a square
- [ ] Border, fonts, and visibility settings update correctly; border size 0 hides it
- [ ] Settings persist across reloads and profile switching/copying/resetting refreshes the UI
- [ ] Repeated settings changes in combat apply after combat without Lua errors
- [ ] Affected layouts work with Edit Mode, late-loaded clock/hybrid minimap UI, and other minimap addons

Offline tests cannot establish taint safety, actual rendering, or compatibility with every addon. The Mechanic mask diagnostic requires manual visual confirmation. Fully removing square mask effects requires disabling ClassyMap and reloading.

### Offline Checks

Run these from the repository root with Lua 5.1, Python 3.9+, Luacheck 0.23.0, and StyLua 2.3.1 available, matching [CI](.github/workflows/quality.yml). The commands below use a POSIX shell; substitute executable paths and expand locale file arguments as needed for your shell.

```sh
lua5.1 tests/run_core.lua
lua5.1 tests/run_core.lua --fencore
lua5.1 tests/runtime_regressions.lua
lua5.1 tests/settings_regressions.lua
lua5.1 tests/ace_integration.lua
lua5.1 tests/mechanic_regressions.lua
python3 tests/check_repo.py --lua lua5.1
luacheck . --config .luacheckrc
stylua --check --syntax Lua51 ClassyMap.lua Settings.lua Mechanic.lua Core/init.lua Locales/*.lua
```

The Core suite runs with both fallback math and bundled FenCore. Runtime and settings suites use strict UI mocks; the Ace integration suite loads the bundled lifecycle/profile libraries. Repository checks validate manifest paths, Lua syntax, packaging exclusions, and localization. These checks do not read installed game state.

For documentation-only changes, check descriptions against source, verify local links and command paths, and run `git diff --check`.

## Questions?

Open an issue or check the existing documentation. Thanks for helping make ClassyMap better!

