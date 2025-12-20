# ClassyMap – Agent Documentation

Technical reference for AI agents modifying this addon.

For shared patterns, documentation requirements, and library management, see **[ADDON_DEV/AGENTS.md](../../ADDON_DEV/AGENTS.md)**.

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
| `ClassyMap.toc` | Metadata |

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
