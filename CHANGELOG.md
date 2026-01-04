# Changelog

All notable changes to ClassyMap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.3.0] - 2026-01-04

### Added
- **Full Localization**: Complete translations for 10 languages
  - German (deDE), French (frFR), Spanish (esES/esMX), Italian (itIT)
  - Portuguese (ptBR), Russian (ruRU), Korean (koKR)
  - Chinese Simplified (zhCN), Chinese Traditional (zhTW)

### Changed
- **Core Layer Refactor**: Renamed Core.lua to ClassyMap.lua; now delegates to Core/init.lua for combat queue and validation
- **FenCore Integration**: Settings validation uses FenCore.Math.Clamp with graceful fallbacks
- Removed duplicated combat queue logic
- Default font changed from custom to standard WoW font (Friz Quadrata TT)

### Removed
- Enable/disable toggle (to disable ClassyMap, disable the addon)

## [1.2.3] - 2025-12-31

### Changed
- Release features

## [1.1.1] - 2025-12-24

### Changed
- Maintenance release: added unit tests, optimized combat queue, and implemented defensive patches for Midnight beta UI crashes.

## [1.1.0] - 2025-12-22

### Changed
- System upgrade for Midnight compatibility. Includes StyLua formatting, full localization (enUS), unit testing infrastructure, and defensive patches for Midnight beta UI crashes.

## [1.0.1] - 2025-12-19

### Added
- **CurseForge Metadata**: Added `## X-License: GPL-3.0` to .toc file
- **CurseForge Integration**: Added project ID and webhook info to AGENTS.md
- **Cursor Ignore**: Added `.cursorignore` to reduce indexing overhead
- **Assets**: Added addon logo

### Changed
- **Documentation**: Consolidated shared documentation to central `ADDON_DEV/AGENTS.md`; trimmed addon-specific AGENTS.md

## [1.0.0] - 2025-12-19

Initial release.

### Added

- Square minimap mask transformation
- Global `GetMinimapShape` override to "SQUARE"
- Custom minimap border with configurable color, width, and opacity
- Blizzard Settings panel integration via AceConfig
- Addon compartment registration for easy access
- Full Ace3 framework integration (AceAddon, AceDB, AceConfig)
- Support for Retail 11.0+ and Midnight (12.0)
