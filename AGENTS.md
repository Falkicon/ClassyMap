# ClassyMap – Agent Documentation

Technical reference for AI agents modifying this addon.

## External References

### Development Documentation
For comprehensive addon development guidance, consult these resources:

- **[ADDON_DEV/AGENTS.md](../../ADDON_DEV/AGENTS.md)** – Library index, automation scripts, dependency chains
- **[Addon Development Guide](../../ADDON_DEV/Addon_Dev_Guide/)** – Full documentation covering:
  - Core principles, project structure, TOC best practices
  - UI engineering, configuration UI, combat lockdown
  - Performance optimization, API resilience
  - Debugging, packaging/release workflow
  - Midnight (12.0) compatibility and secret values

### Blizzard UI Source Code
For reverse-engineering, hijacking, or modifying official Blizzard UI frames:

- **[wow-ui-source-live](../../wow-ui-source-live/)** – Official Blizzard UI addon code
  - Use this to understand Minimap frame structure and mask textures
  - Essential reference for `GetMinimapShape` and addon compartment APIs
  - Reference for understanding how other addons interact with the minimap

---

## Project Intent

A simple addon that transforms the default circular minimap into a clean square shape.

- Provides a modern, flat aesthetic for the minimap
- Integrates with Blizzard's addon compartment system
- Maintains compatibility with other minimap-aware addons

## Constraints

- Must work on Retail 11.0+
- **Interface Version**: Currently targeting **120001** (Midnight expansion, due January 20th, 2026)
- Uses Ace3 framework (AceAddon, AceConfig)
- Minimal footprint – single-purpose addon

## File Structure

| File | Purpose |
|------|---------|
| `Core.lua` | Minimap modification, border creation, shape override |
| `Settings.lua` | AceConfig settings UI |
| `ClassyMap.toc` | Metadata |

## Architecture

### Key Features

- **Square Minimap**: Uses `Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")`
- **Shape Override**: Overrides `GetMinimapShape` globally to return `"SQUARE"` for interactions with other addons
- **Addon Compartment**: Registers itself in Blizzard's native addon compartment frame

### How It Works

1. On load, applies a square mask texture to the minimap
2. Globally overrides `GetMinimapShape()` so other addons know the minimap is square
3. Creates a clean border frame around the minimap
4. Registers with the addon compartment for easy access

## SavedVariables

- **Root**: `ClassyMapDB`
- Settings stored via AceDB profile system

## Documentation Requirements

**Always update documentation when making changes:**

### CHANGELOG.md
Update the changelog for any change that:
- Adds new features or functionality
- Fixes bugs or issues
- Changes existing behavior
- Modifies settings or configuration options

**Format** (Keep a Changelog style):
```markdown
## [Version] - YYYY-MM-DD
### Added
- New features

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes

### Removed
- Removed features
```

### README.md
Update the README when:
- Adding new features that users should know about
- Changing slash commands or settings
- Modifying installation or usage instructions

**Key sections to review**: Features, Slash Commands, Settings

## Library Management

This addon manages its libraries using `update_libs.ps1` located in `Interface\ADDON_DEV`.
**DO NOT** manually update libraries in `Libs`.
Instead, if you need to update libraries, run:
`powershell -File "c:\Program Files (x86)\World of Warcraft\_retail_\Interface\ADDON_DEV\update_libs.ps1"`
