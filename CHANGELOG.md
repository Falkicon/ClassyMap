# Changelog

All notable changes to ClassyMap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).


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
