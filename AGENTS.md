# ClassyMap – Agent Documentation

Technical reference for AI agents modifying this addon.

For shared patterns, library references, and development guides, see **[Mechanic](../Mechanic/AGENTS.md)**.

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
- Maintains compatibility with other minimap-aware addons

---

## File Structure

| File | Purpose |
|------|---------|
| `Core.lua` | Minimap modification, border creation, shape override |
| `Core/init.lua` | Pure Lua core layer (validation, combat queue) - sandbox-compatible |
| `Settings.lua` | AceConfig settings UI |
| `Mechanic.lua` | Mechanic integration for debugging/testing |
| `Locales/enUS.lua` | Base localization strings |
| `Tests/core_spec.lua` | Unit tests for Core layer |
| `ClassyMap.toc` | Metadata |

---

## Tooling & Workflow

This addon uses **Mechanic** for development tooling:

| Task | Command |
|------|---------|
| Linting | `mech call addon.lint -i '{"addon": "ClassyMap"}'` |
| Formatting | `mech call addon.format -i '{"addon": "ClassyMap"}'` |
| Testing | `mech call sandbox.test -i '{"addon": "ClassyMap"}'` |
| Lib Check | `mech call libs.check -i '{"addon": "ClassyMap"}'` |
| Validation | `mech call addon.validate -i '{"addon": "ClassyMap"}'` |

**Development Loop:**
```bash
# After any code change:
mech call reload.trigger                    # Focus WoW + trigger /reload
mech call addon.output -i '{"agent_mode": true}'  # Get errors/logs
```

### Localization
All user-facing strings must be wrapped in `L["KEY"]`.

---

## FenCore Integration

ClassyMap uses **FenCore** for pure logic in the Core layer:

| Domain | Usage |
|--------|-------|
| `FenCore.Math` | `Clamp()` for settings validation (border size, font size, colors) |

**Pattern:** Core/init.lua delegates to FenCore with graceful fallbacks:
```lua
local FenCore = _G.FenCore
local Math = FenCore and FenCore.Math
local Clamp = Math and Math.Clamp or function(n, min, max) ... end
```

**Libraries:** See `Libs/libs.json` for dependency tracking.

---

## Architecture

### How It Works

1. On load, applies a square mask texture to the minimap
2. Globally overrides `GetMinimapShape()` so other addons know the minimap is square
3. Creates a clean border frame around the minimap
4. Registers with the addon compartment for easy access

### Key Implementation

```lua
-- Square mask
Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")

-- Shape override for other addons
function GetMinimapShape()
    return "SQUARE"
end
```

---

## SavedVariables

- **Root**: `ClassyMapDB`
- Settings stored via AceDB profile system

