# ClassyMap

A minimalist square minimap addon for World of Warcraft. Transforms the default circular minimap into a clean, modern square shape.

![WoW Version](https://img.shields.io/badge/WoW-11.0%2B-blue)
![Interface](https://img.shields.io/badge/Interface-120001-green)
[![GitHub](https://img.shields.io/badge/GitHub-Falkicon%2FClassyMap-181717?logo=github)](https://github.com/Falkicon/ClassyMap)
[![Sponsor](https://img.shields.io/badge/Sponsor-pink?logo=githubsponsors)](https://github.com/sponsors/Falkicon)

> **Minimal Footprint**: Single-purpose addon focused on doing one thing well, making your minimap look great.

## Features

- **◼️ Square Minimap** – Clean square shape instead of the default circle
- **🖼️ Simple Border** – Thin, customizable border
- **📦 Button Drawer** – Collects addon minimap buttons into a tidy row
- **🧹 Clutter Free** – Hides compass, zoom buttons, and blob rings
- **🔌 Addon Compartment** – Integrates with Blizzard's native addon compartment frame

## Installation

1. Download or clone this repository
2. Place the `ClassyMap` folder in your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. Restart WoW or type `/reload` if already running

## Usage

The addon applies automatically on login. Use the settings panel to customize.

### Slash Commands

| Command | Description |
|---------|-------------|
| `/classymap` or `/cm` | Open settings |
| `/classymap toggle` | Enable/disable the addon |

## Configuration

Open settings via `/cm` or `Esc` → `Options` → `AddOns` → `ClassyMap`.

### Settings

| Setting | Description |
|---------|-------------|
| Border Size | Thickness of the minimap border |
| Border Color | Color of the minimap border |
| Hide Compass | Remove the compass ring |
| Hide Zoom Buttons | Remove the +/- zoom buttons |
| Button Drawer Position | Position of collected addon buttons (bottom, left, right) |

## Compatibility

- Works with LibDBIcon minimap buttons from other addons
- Properly reports `"SQUARE"` via `GetMinimapShape()` for addon compatibility

## Requirements

- World of Warcraft Retail 11.0+ or Midnight Beta

## Localization

ClassyMap supports 11 languages:
- English (enUS) - baseline
- German (deDE), French (frFR), Spanish (esES/esMX), Italian (itIT)
- Portuguese (ptBR), Russian (ruRU), Korean (koKR)
- Chinese Simplified (zhCN), Chinese Traditional (zhTW)

## Files

| File | Purpose |
|------|---------|
| `ClassyMap.toc` | Addon manifest |
| `ClassyMap.lua` | Main addon entry, minimap modification, UI |
| `Core/init.lua` | Pure logic layer (validation, combat queue) |
| `Settings.lua` | AceConfig settings UI |
| `Mechanic.lua` | Mechanic integration for debugging |
| `Locales/` | 11 locale files |

## Technical Notes

- **Ace3 Framework** – Uses AceAddon, AceConfig for settings
- **Shape Override** – Globally overrides `GetMinimapShape` to return `"SQUARE"` for other addon compatibility
- **Mask Texture** – Uses `Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")`

## Support

If you find ClassyMap useful, consider [sponsoring on GitHub](https://github.com/sponsors/Falkicon) to support continued development and new addons. Every contribution helps!

## License

GPL-3.0 License – see [LICENSE](LICENSE) for details.
