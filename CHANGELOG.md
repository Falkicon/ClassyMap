# Changelog

All notable changes to ClassyMap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.6.1] - 2026-09-18

### Added

- WoW: Forever beta support. The TOC now declares Interface 16001 alongside Retail 120100.

### Fixed

- The Edit Mode selection box now matches the square map exactly, so the map can be placed flush in a screen corner. Blizzard's minimap cluster is a resize-layout frame that re-sized itself to its hidden native children on every layout pass; ClassyMap now pins the cluster to the map's rendered footprint, follows the Edit Mode "Size" setting, and clamps the cluster to the screen without the old 60px overhang.

## [1.6.0] - 2026-09-06

### Added

- Scoped refresh scheduling that combines pending work and waits for login/combat readiness.
- Observable frame ownership and conditional hooks, with safe partial restoration on disable. Full removal of square mask effects still requires reload.
- Performance invocation counts, cumulative/average/maximum durations, rate reporting, and a Reset Metrics tool.
- Strict offline UI mocks, integration tests using bundled Ace libraries, and automated quality checks.
- AceDB profile controls for creating, copying, resetting, and switching settings profiles.

### Changed

- Updated user and contributor documentation for current settings, runtime behavior, and offline/live validation workflows.

### Fixed

- Combat queue event registration, nested actions, and nil arguments.
- Recursive layout updates, clock text targeting, and zone-color restoration.
- Settings validation and profile refreshes; misleading diagnostic controls and performance units.

## [1.5.0] - 2026-04-30

### Changed
- **Expansion Button**: The minimap expansion button now opens the Adventure Guide (shift-J) — Renowns, Traveler's Log, Dungeons, Raids — instead of the most recently unlocked covenant/garrison landing page (which was stuck on Shadowlands/Venthyr).
- **Expansion Button Icon**: Replaced the static Shadowlands-themed TGA with a dynamic atlas selected from Blizzard's `ExpansionLandingPage` overlay info, falling back through Midnight → War Within → Dragonflight landing-button atlases. The icon now reflects the current expansion automatically.

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
