# ClassyMap – Agent Documentation

Technical reference for AI agents modifying this addon.

For shared patterns, library references, and development guides, see **[ADDON_DEV/AGENTS.md](../ADDON_DEV/AGENTS.md)**.

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
| `Settings.lua` | AceConfig settings UI |
| `Locales/enUS.lua` | Base localization strings |
| `Tests/core_spec.lua` | Unit tests for combat queue and layout |
| `ClassyMap.toc` | Metadata |

---

## Tooling & Workflow

### Formatting
This addon follows the workspace StyLua standard.
```powershell
# Format the addon
powershell -File "_dev_\ADDON_DEV\Tools\Formatter\format.ps1" -Addon "ClassyMap"
```

### Localization
All user-facing strings must be wrapped in `L["KEY"]`.
```powershell
# Extract strings
powershell -File "_dev_\ADDON_DEV\Tools\LocalizationTool\localize.ps1" -Addon "ClassyMap"
```

### Testing
Unit tests are located in `Tests/` and use the Busted framework.
```powershell
# Run tests
powershell -File "_dev_\ADDON_DEV\Tools\TestRunner\run_tests.ps1" -Addon "ClassyMap"
```

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
