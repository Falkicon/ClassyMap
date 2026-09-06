# Repository quality review — 2026-09-06

Follow-up implementation: [runtime-design.md](runtime-design.md) documents the unified refresh scheduler, frame ownership and partial restoration, cumulative diagnostics, and strict tests against bundled Ace libraries. The findings below describe the original review; its lack of a restoration foundation has since been addressed within the limits described there.

Scope: all first-party runtime code, Core tests, locales, documentation, packaging, dependency declarations, and the TOC/XML load graph. Bundled libraries were checked for load integrity and relevant API contracts; they were not rewritten or upgraded. No release or game installation was performed.

## Findings addressed

| Priority | Finding and impact | Resolution |
| --- | --- | --- |
| P1 | `RunSafe` registered `PLAYER_REGEN_ENABLED` without naming its handler. AceEvent then looked for a nonexistent method, so combat-deferred changes could fail. Settings could also call protected layout changes directly during combat. | Explicit handler registration; full refreshes and layout requests defer and coalesce during combat. |
| P1 | The Core and runtime queue implementations disagreed. Errors interrupted Core drains, nested work could disappear, and trailing nil arguments were lost. | One detached-batch Core drain with error isolation, preserved argument counts, and subsequent runtime drains for nested actions. |
| P2 | `FixLayout` called a hooked `SetWidth`; the hook could repeat layout synchronously. Height changes were not covered, and error paths could leave guards stuck. | Coalesced next-frame width/height invalidation, guarded layout execution, and guard cleanup after failure. |
| P2 | Clock styling assumed the first region was a FontString. It can be a texture. Late-loaded Blizzard components also missed styling. | Target `TimeManagerClockTicker` and refresh on relevant Blizzard addon load events. |
| P2 | Disabling custom zone color left the old color applied; Blizzard could overwrite an enabled override. A hidden zone heading also left the clock anchored beneath it. | Restore color through Blizzard's `Minimap_Update`, apply custom color after native updates, and anchor the clock to the map when the heading is hidden. |
| P2 | A minimap addon replaced a global covenant-renown mixin method to work around an old beta issue, altering unrelated Blizzard UI behavior. | Removed that replacement. The current shortcut opens the Adventure Guide. |
| P2 | Non-finite saved sizes and colors passed through validation. Color getters could index malformed values. | Reject non-finite values and normalize settings at display/write boundaries. |
| P2 | Mechanic debug logging inspected `ClassyMapDB.profile`, which is not the active AceDB profile. The throttle table grew with every unique message. | Read `ns.ClassyMap.db.profile`, bound throttle entries to retained history, and clear both together. |
| P2 | Mechanic's toggle changed an unused `enabled` field. Border diagnostics ignored missing edges/visibility, and the mask check passed based on that field alone. | Replace toggle with Reapply, inspect all four borders, and leave the visual mask check pending for manual verification. |
| P2 | Profiling reported seconds as milliseconds and included a total alongside its components, causing the consumer to count work twice. | Report milliseconds and a non-overlapping remainder bucket. |
| P3 | Font/color edits rebuilt the full minimap; profile changes did not refresh the UI. | Apply font styles alone for those edits; register AceDB change/copy/reset callbacks. |
| P3 | README advertised unsupported commands/settings and third-party button collection. Lint relied on a sibling checkout; packages included development material and dependency metadata listed unused libraries. | Align docs with implementation, provide a standalone lint configuration, and clean package exclusions and dependency declarations. |

## Architecture assessment and remaining work

The existing split between pure Core logic, WoW frame integration, settings, and optional diagnostics is appropriate for this addon's size. Centralizing queue processing and refresh scheduling addresses the most consequential coupling without a large module rewrite.

The follow-up now captures observable frame state, makes hooks conditional, cancels pending refreshes on disable, and restores eligible properties without overwriting observed external changes. Complete removal still requires reload because original mask/blob state is not observable. Square mask behavior and matching shape reporting remain consistent until then. No control claims complete runtime disable. See [runtime-design.md](runtime-design.md) for the precise contract.

Edit Mode and other minimap addons can also modify the same frames. Offline mocks cannot prove freedom from taint, protected-frame failures, visual overlap, or conflicts with competing layout owners. Validate in the intended client with the user's actual addon set before release. Existing client assumptions are documented by the TOC interface target; this review does not certify future-client compatibility.

New diagnostic strings have English locale defaults; the ten other locales use AceLocale fallback for those strings. Existing translations are preserved. Human translations remain a follow-up.

## Validation

Reproducible offline commands are in [CONTRIBUTING.md](../CONTRIBUTING.md). The regression suites cover Core validation/queues, runtime combat/layout/font behavior, settings callbacks, and Mechanic diagnostics. `tests/check_repo.py` checks the complete TOC/XML graph, compiles every loaded Lua source, and verifies English defaults for all used locale keys. These checks do not execute the game client.

Final results: 26 Core tests pass both with the fallback clamp and with the bundled FenCore domain; runtime, settings, and Mechanic regression suites pass. Luacheck reports zero warnings/errors across 15 runtime files. All 87 load-graph files exist, all 70 loaded Lua files compile, and all 72 used locale keys have English defaults. Formatting and `git diff --check` pass. Forty diagnostic keys fall back to English in each non-English locale.

Mechanic MCP was unavailable in this session, so no `addon.output`, live sandbox command, installed-client inspection, or game-state assertion was made. Complete offline checks first, install/sync this checkout, then `/reload` and confirm completion before collecting diagnostic output through an available Mechanic connection.

In-game checks: square normal/hybrid maps; border size zero and nonzero; every hide toggle; font/color changes and restoration; changes during two consecutive combats; zone changes; clock load; and Edit Mode resizing/positioning.
