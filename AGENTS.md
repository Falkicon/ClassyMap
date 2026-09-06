# ClassyMap – Agent Documentation

Technical reference for AI agents modifying this addon.

In the shared addon workspace, also follow **[Mechanic](../Mechanic/AGENTS.md)** for tooling and diagnostic guidance. Standalone clones can use the offline workflow in [CONTRIBUTING.md](CONTRIBUTING.md) without that sibling checkout.

---

## CurseForge

| Item | Value |
|------|-------|
| **Project ID** | 1409472 |
| **Project URL** | https://www.curseforge.com/wow/addons/classymap |
| **Files** | https://authors.curseforge.com/#/projects/1409472/files |

---

## Project Intent

A simple addon that transforms the default circular minimap into a clean square shape.

- Provides a modern, flat aesthetic for the minimap
- Integrates with Blizzard's addon compartment system
- Reports the square shape and cooperates with observable changes from other addons

---

## File Structure

| File | Purpose |
|------|---------|
| `ClassyMap.lua` | Lifecycle, scoped refresh scheduler, frame ownership, minimap UI |
| `Core/init.lua` | Pure Lua core layer (validation, combat queue) - sandbox-compatible |
| `Core/core_spec.lua` | Busted unit tests for Core layer |
| `Settings.lua` | AceConfig settings UI |
| `Mechanic.lua` | Mechanic integration for debugging/testing |
| `Locales/` | 11 locale files (enUS baseline + 10 translations) |
| `ClassyMap.toc` | Metadata |
| `embeds.xml` / `Libs/libs.json` | Library load order / dependency inventory |
| `tests/` | Standalone offline regression and manifest checks |
| `.github/workflows/quality.yml` | CI commands and tool versions |
| `docs/quality-review.md` | Review findings, resolved issues, and live verification limits |
| `docs/runtime-design.md` | Refresh scopes, ownership policy, metric semantics, and test boundaries |

---

## Tooling & Workflow

Use connected **Mechanic MCP** tools when available. Names below are registry names; inspect current schemas through `commands.list` for exposed tool names and arguments.

| Task | MCP Tool |
|------|----------|
| Linting | `addon.lint` with addon="ClassyMap" |
| Formatting | `addon.format` with addon="ClassyMap" |
| Testing | `sandbox.test` with addon="ClassyMap" |
| Lib Check | `libs.check` with addon="ClassyMap" |
| Validation | `addon.validate` with addon="ClassyMap" |
| Deprecations | `addon.deprecations` with addon="ClassyMap" |
| Locale Check | `locale.validate` with addon="ClassyMap" |

**Development Loop:**

1. Make changes and run the relevant offline checks in [CONTRIBUTING.md](CONTRIBUTING.md).
2. For runtime changes, identify the intended installed client and diagnostic target, then install/sync the changed addon. A development checkout is not automatically installed.
3. Ask the user to `/reload` in that client and wait for confirmation.
4. Only then call `addon.output` with `agent_mode=true` and the same explicit diagnostic target to inspect errors/logs.

Documentation-only changes do not require a game reload. If Mechanic MCP is unavailable, report that limitation and use source inspection and isolated offline checks; do not substitute live CLI operations or claim installed-game verification.

### Localization

All user-facing strings must be wrapped in `L["KEY"]`.

**Coverage:** `Locales/enUS.lua` defines the baseline for 11 locales. New Mechanic diagnostic strings use English fallback until translated in the other 10 locales.

Validate with: `locale.validate` with addon="ClassyMap"

When Mechanic MCP is unavailable, use the isolated offline checks in [CONTRIBUTING.md](CONTRIBUTING.md). These do not validate installed game state.

---

## FenCore Integration

ClassyMap uses **FenCore** for pure logic in the Core layer:

| Domain | Usage |
|--------|-------|
| `FenCore.Math` | `Clamp()` for settings validation (border size, font size, colors) |

**Pattern:** [Core/init.lua](Core/init.lua) validates finite numeric inputs and delegates clamping to `FenCore.Math.Clamp` when available, with a local fallback. Keep this layer independent of WoW UI APIs; run the Core tests both with and without bundled FenCore.

**Libraries:** See `Libs/libs.json` for dependency tracking.

---

## Architecture

See [runtime-design.md](docs/runtime-design.md) for the current scheduling and ownership contract.

- Route UI and profile updates through `ClassyMap:RequestRefresh(scope)`, using `all`, `border`, `fonts`, `visibility`, or `layout`. Full refreshes subsume partial work; visibility also requests layout. Read the active profile when executing queued work.
- Modify observable Blizzard frame properties through `OwnSet`; addon-created textures/buttons may be updated directly inside a refresh. Mask and blob properties without readable originals have explicit restoration limits.
- Preserve generation cancellation, combat deferral, and conditional hooks when changing lifecycle behavior.
- `OnDisable` restores eligible observable geometry/styles. Square mask effects and shape reporting remain until reload; do not advertise complete runtime disable.
- Record executed categories, including independent font/layout work. `Refresh` is an inclusive metric and must not be summed with its components. Mechanic breakdown values are rates in ms/s; see the diagnostic snapshot for cumulative durations and counts.

### How It Works

1. Initializes AceDB, settings, slash commands, and the native addon compartment entry.
2. Schedules changes after enable/world readiness and outside combat.
3. Applies the square mask and manages `GetMinimapShape()` reporting, respecting a detected replacement by another addon.
4. Draws the border with four ARTWORK textures, styles text, and lays out the selected minimap controls.

### Updating Settings

```lua
-- After validating and storing a border setting in the active profile:
ClassyMap:RequestRefresh("border")
```

---

## SavedVariables

- **Root**: `ClassyMapDB`
- **Active settings**: `ns.ClassyMap.db.profile`; do not read a presumed `ClassyMapDB.profile` directly.
- AceDB profile changes, copies, and resets request a full refresh and notify the settings UI.

