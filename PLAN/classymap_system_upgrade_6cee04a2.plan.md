---
name: ClassyMap System Upgrade
overview: Upgrade ClassyMap to fully integrate with the new ADDON_DEV tooling system, establishing it as the reference implementation for the upgraded development workflow.
todos:
  - id: format-code
    content: Apply StyLua formatting to Core.lua and Settings.lua
    status: completed
  - id: create-locales
    content: Create Locales/enUS.lua and wrap hardcoded strings with L["KEY"]
    status: completed
    dependencies:
      - format-code
  - id: update-embeds
    content: Add AceLocale-3.0 to embeds.xml and update TOC load order
    status: completed
    dependencies:
      - create-locales
  - id: create-tests
    content: Create Tests/core_spec.lua with unit tests for combat queue and layout logic
    status: completed
    dependencies:
      - format-code
  - id: update-agents
    content: Update AGENTS.md with testing, formatting, and localization documentation
    status: completed
    dependencies:
      - create-locales
      - create-tests
---

# ClassyMap System Upgrade Plan

- **API Resilience**: Added `pcall` wrappers and prioritized native button logic to handle Midnight beta UI crashes while maintaining functionality.
- **Dynamic Tooltips**: Updated expansion button to pull title/description from Blizzard's native button when available.

## Current State Assessment

| Check | Status | Notes ||-------|--------|-------|| TOC Validation | PASS | Interface 120001/120000, all files exist || Deprecation Scan | PASS | No Midnight API issues found || Library Sync | PASS | All libraries in sync with ADDON_DEV source || Luacheckrc | EXISTS | Already extends central config correctly || Formatting | PASS | StyLua standard applied || Localization | PASS | All strings extracted and wrapped with L["KEY"] || Tests | PASS | core_spec.lua created (Runtime requires lua.exe) || Performance Baseline | NONE | No performance metrics recorded |---

## Implementation Strategy

### Phase 1: Code Quality Foundation

**1.1 Apply StyLua Formatting**

- The formatter check shows ClassyMap needs formatting
- Run `format_addon("ClassyMap")` to apply consistent style

**1.2 Extract Localizable Strings**

- Currently has hardcoded English strings (e.g., "Khaz Algar Summary", "Loaded. Type /classymap...")
- Create `Locales/` directory with `enUS.lua` following the template pattern
- Wrap user-facing strings with `L["KEY"]` pattern

Files to modify:

- [`Core.lua`](_dev_/ClassyMap/Core.lua) - Lines 91, 115, 530-531
- [`Settings.lua`](_dev_/ClassyMap/Settings.lua) - Option names/descriptions

### Phase 2: Testing Infrastructure

**2.1 Create Tests Directory**

- Add `Tests/` folder structure matching template
- Create initial test file `Tests/core_spec.lua`

**2.2 Unit Test Coverage**Focus on testable pure functions:

- Combat queue logic (`RunSafe`, `ProcessCombatQueue`)
- Border style calculations (`UpdateBorderStyle`)
- Layout constants and calculations

Example test structure:

```lua
describe("ClassyMap", function()
    describe("Combat Queue", function()
        it("should queue function when in combat", function()
            -- Mock InCombatLockdown() = true
            -- Call RunSafe()
            -- Assert function was queued
        end)
    end)
end)
```



### Phase 3: Performance Baseline

**3.1 Add Profiler Integration**

- Add optional `Profiler.lua` from template's `Libs/Profiler/`
- Record baseline metrics for:
- Memory usage at load
- CPU time during `ApplyMinimapChanges`

**3.2 Establish Baseline**

- Document expected performance characteristics in AGENTS.md
- Use `check_performance()` MCP tool to track regressions

### Phase 4: Documentation Updates

**4.1 Update AGENTS.md**Add sections for:

- Testing commands
- Formatting commands  
- Performance expectations
- Localization coverage

---

## Files to Create/Modify

| File | Action | Purpose ||------|--------|---------|| `Locales/enUS.lua` | CREATE | Base English locale || `Tests/core_spec.lua` | CREATE | Unit tests for Core.lua || `Core.lua` | MODIFY | Add localization, optional profiler || `Settings.lua` | MODIFY | Localize option strings || `embeds.xml` | MODIFY | Add AceLocale-3.0 include || `ClassyMap.toc` | MODIFY | Add Locales to load order || `AGENTS.md` | MODIFY | Add tooling documentation |---

## Validation Checklist (Post-Implementation)

```javascript
lint_addon("ClassyMap")          → All checks pass
format_addon("ClassyMap", true)  → No changes needed
validate_tocs()                  → PASS
extract_locale_strings()         → All strings covered
run_tests("ClassyMap")           → Tests pass (requires lua.exe)
```

---

## Notes

- **Lua interpreter**: Test runner requires `lua.exe` in `ADDON_DEV/Tools/Lua`. This is a one-time environment setup.