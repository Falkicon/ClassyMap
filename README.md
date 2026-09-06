# ClassyMap

A minimalist square minimap addon for World of Warcraft. Transforms the default circular minimap into a clean, modern square shape.

![Interface](https://img.shields.io/badge/Interface-120100-green)
[![GitHub](https://img.shields.io/badge/GitHub-Falkicon%2FClassyMap-181717?logo=github)](https://github.com/Falkicon/ClassyMap)
[![Sponsor](https://img.shields.io/badge/Sponsor-pink?logo=githubsponsors)](https://github.com/sponsors/Falkicon)

> **Minimal Footprint**: Single-purpose addon focused on doing one thing well, making your minimap look great.

## Features

- **◼️ Square Minimap** – Clean square shape instead of the default circle
- **🖼️ Simple Border** – Thin, customizable border
- **📦 Addon Compartment** – Repositions Blizzard's native addon compartment near the minimap
- **🧹 Clutter Controls** – Hides the compass and blob rings, with optional controls for other minimap elements
- **🗺️ Expansion Shortcut** – Replaces the native expansion button with a compact button that opens the Adventure Guide

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/classymap) or clone this repository
2. Place the `ClassyMap` folder in your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\ClassyMap\
   ```
3. Check that `ClassyMap.toc` is directly inside that folder, then restart WoW for a first installation. Use `/reload` after updating an already loaded installation.

## Usage

The addon applies automatically on login. Use the settings panel to customize.

Settings changes made during combat apply after combat ends. Changes made together are combined into one refresh.

### Slash Commands

| Command | Description |
|---------|-------------|
| `/classymap` or `/cm` | Open settings |

## Configuration

Open settings via `/cm`, the ClassyMap entry in the addon compartment, or the in-game AddOns settings category.

### Settings

| Setting | Description |
|---------|-------------|
| Border Size | Thickness from 0–8; 0 hides the border |
| Border Color | Color of the minimap border |
| Font Face | Font used by the zone text and clock |
| Zone Text Size / Color | Size from 6–24 and optional override color for the zone text |
| Clock Text Size / Color | Size from 6–24 and color for the clock |
| Hide Tracking | Hide the tracking button |
| Hide Zone Text / Clock | Hide either text element |
| Hide Zoom Buttons | Hide the +/- zoom buttons |
| Hide Expansion Button | Hide the replacement expansion shortcut |
| Hide Calendar / Addon Drawer / Instance Difficulty | Hide individual minimap cluster elements |
| Profiles | Create, copy, reset, and switch AceDB profiles |

## Compatibility

- Repositions Blizzard's native addon compartment. The **Hide Addon Drawer** setting hides this compartment; ClassyMap does not collect third-party minimap buttons.
- Reports `"SQUARE"` through `GetMinimapShape()` while managing the minimap shape.
- Leaves detected external changes to tracked frame properties alone. Other addons that also reshape or reposition the minimap still need in-game compatibility testing.

## Requirements

- World of Warcraft Retail. The declared client target is Interface 120100 in [ClassyMap.toc](ClassyMap.toc).
- Required libraries are bundled; Mechanic is optional developer tooling.

## Localization

ClassyMap includes 11 locales:

- English (enUS) - baseline
- German (deDE), French (frFR), Spanish (esES/esMX), Italian (itIT)
- Portuguese (ptBR), Russian (ruRU), Korean (koKR)
- Chinese Simplified (zhCN), Chinese Traditional (zhTW)

New diagnostic strings fall back to English until translated.

## Files

| File | Purpose |
|------|---------|
| `ClassyMap.toc` | Addon manifest |
| `ClassyMap.lua` | Main addon entry, minimap modification, UI |
| `Core/init.lua` | Pure logic layer (validation, combat queue) |
| `Settings.lua` | AceConfig settings UI |
| `Mechanic.lua` | Mechanic integration for debugging |
| `Locales/` | 11 locale files |
| `tests/` | Offline regression, integration, and manifest checks |
| `docs/runtime-design.md` | Runtime contracts and diagnostic reference |

## Technical Notes

- **Ace3 Framework** – Uses AceAddon, AceConfig, AceDB, AceEvent, AceLocale, and AceGUI for settings and lifecycle management
- **Refresh Scheduling** – Applies changes after enable/world readiness and outside combat, combining pending work into scoped refreshes.
- **Border** – Uses four textures on the minimap's ARTWORK layer.
- **Mask Texture** – Uses `Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")`
- **Cooperative Layout** – Tracks observable frame changes and leaves externally changed properties alone. Full removal of square mask effects requires disabling the addon and reloading.
- **Development Reference** – See [runtime-design.md](docs/runtime-design.md) for refresh scheduling, ownership, diagnostics, and integration-test boundaries.

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and offline checks.

## Support

If you find ClassyMap useful, consider [sponsoring on GitHub](https://github.com/sponsors/Falkicon) to support continued development and new addons. Every contribution helps!

## License

GPL-3.0 License – see [LICENSE](LICENSE) for details.
