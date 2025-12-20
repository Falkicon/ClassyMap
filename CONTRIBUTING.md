# Contributing to ClassyMap

Thanks for your interest in contributing! ClassyMap is a simple addon that transforms the default circular minimap into a clean square shape. We welcome bug reports, feature suggestions, and code contributions.

## Getting Started

1. **Fork and clone** the repository
2. **Place the addon** in your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\ClassyMap\
   ```
3. **Test in-game** with `/reload` after making changes

## Development Guidelines

### Read the Docs First

- [AGENTS.md](AGENTS.md) – Project intent, conventions, and technical reference
- [ADDON_DEV/AGENTS.md](../../ADDON_DEV/AGENTS.md) – Shared development library index

### Code Style

- **Lua 5.1** syntax (WoW's embedded Lua version)
- **Local variables** – Prefer `local` for performance and scope control
- **Ace3 Framework** – Use the included Ace3 libraries for settings and initialization

### Performance Expectations

This addon prioritizes a minimal footprint:

- **CPU**: Minimal impact as it primarily modifies frame masks and applies a border
- Avoid per-frame table allocations or `OnUpdate` polling

### Midnight Compatibility

The addon targets Interface 120001 (Midnight). When adding features:

- Ensure modifications are resilient to UI updates
- Use established patterns for frame hijacking and mask application

## Submitting Changes

### Bug Reports

Open an issue with:

- WoW version and client (Retail/Beta)
- Steps to reproduce
- Any Lua errors from BugSack/BugGrabber

### Feature Requests

Open an issue describing:

- What you want to accomplish
- Why it fits the addon's scope (simple square minimap)

### Pull Requests

1. **Create a branch** from `main`
2. **Keep changes focused** – one feature or fix per PR
3. **Test in-game** on both Retail and Beta if possible
4. **Update docs** if adding settings or slash commands
5. **Describe your changes** in the PR description

## File Structure

| File | Purpose |
|------|---------|
| `ClassyMap.toc` | Addon manifest |
| `Core.lua` | Minimap mask, border, and shape logic |
| `Settings.lua` | AceConfig settings panel |

## Testing Checklist

Before submitting:

- [ ] Addon loads without errors (`/reload`)
- [ ] Minimap is correctly masked as a square
- [ ] Border appears and updates correctly via settings
- [ ] Settings persist across sessions
- [ ] No Lua errors in combat

## Questions?

Open an issue or check the existing documentation. Thanks for helping make ClassyMap better!
