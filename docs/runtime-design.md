# Refresh scheduling, frame ownership, and diagnostics

## Refresh requests

Call `ClassyMap:RequestRefresh(scope)` after changing settings. Requests combine until the next timer turn and use the latest profile values when executed.

| Scope | Work |
| --- | --- |
| `border` | Create/update ClassyMap's border textures |
| `fonts` | Zone/clock fonts and text colors |
| `visibility` | Minimap clutter/visibility, followed by layout |
| `layout` | Frame positioning and layout |
| `all` | Map setup plus every category above, once |

A full request subsumes narrower requests. Work waits until the addon is enabled, the world is ready, and combat lockdown ends. Settings callbacks and Mechanic tools use this same entry point. `ApplyMinimapChanges`, `ApplyFontStyles`, and `FixLayout` retain compatibility entry points that enqueue work when called outside a scheduled refresh.

Disable invalidates scheduled callbacks, clears pending requests and combat actions, and makes permanent hooks inactive. Re-enable starts a new scheduling generation. Requests raised during a refresh belong to a subsequent batch. Category failures are reported independently so another requested category can still run.

## Frame ownership

`OwnSet` captures observable properties before their first modification and records the values left by ClassyMap. If a subsequent comparison observes a different value, ClassyMap relinquishes that property for the current enable cycle. Matching properties can be restored on disable; properties changed by another participant are left alone.

Restoration determines eligibility before changing anything, then restores properties in a defined order: parents and geometry before styling and visibility. This avoids treating a restoration's own side effects as a new external change. Combat-delayed restoration uses a private frame because AceEvent removes the addon's event registrations after `OnDisable` returns.

Known native zone-color and expansion-button visibility updates have explicit policies that keep ClassyMap's enabled customization working. Ownership is based on observed values, not the identity of the addon making a call. It cannot distinguish another addon invoking the same native update path, or a change to an identical value. This is cooperative behavior, not a guarantee against all minimap-addon conflicts.

The original minimap mask/blob scalar state cannot be queried reliably through matching getters. Disabling therefore stops scheduling and restores eligible geometry/styles, but retains square mask behavior and matching square shape reporting until reload. Hybrid mask behavior follows the same policy. No settings control advertises complete runtime disable; remove/disable the addon and reload for full removal. Another addon replacing the shape function is respected by subsequent setup work.

## Performance measurements

Executed work records six fixed metric names: `CreateBorder`, `HideClutter`, `ApplyFontStyles`, `FixLayout`, `Setup`, and `Refresh`. Independent font/layout refreshes are included. Queued requests that combine into one execution do not inflate invocation counts.

Counts represent executions, including failed attempts; failures are reported through the game's error handler. Measurements describe ClassyMap's instrumented work and do not measure the complete CPU cost of other addons or Blizzard UI.

`ClassyMapMechanic:GetPerformanceStats()` returns a detached snapshot with elapsed seconds and per-metric count, cumulative milliseconds, last duration, maximum duration, mean duration, calls/second, and milliseconds/second. Invalid samples and unknown names are rejected; the number of stored metrics is fixed.

Mechanic's performance table is labeled milliseconds/second, so the exported `ms` value is cumulative measured time divided by elapsed time since collection began or was reset. Descriptions include count/total/mean/maximum/last duration. These are averages over the observation window, not instantaneous rates. No per-frame polling is added.

`Refresh` is the inclusive batch duration. It is available in the snapshot but excluded from the category table, so the consumer cannot count the same work twice. Scheduler/instrumentation overhead can make the inclusive duration larger than the sum of its categories. The **Reset Metrics** tool starts a fresh observation window.

## Offline and live verification

The strict mock exposes explicit methods, records state, and rejects protected mutations during simulated combat. Runtime regressions exercise coalescing, ownership, cancellation, and late loads. The Ace integration suite loads the bundled AceAddon, AceEvent, CallbackHandler, and AceDB implementations to exercise real lifecycle ordering and profile callbacks; UI and client APIs remain mocked.

Run the commands in [CONTRIBUTING.md](../CONTRIBUTING.md). These tests cannot establish client taint safety, rendering correctness, or compatibility with the user's complete addon set. After syncing the checkout, a confirmed `/reload` plus combat, Edit Mode, zone-change, and hide/show checks remains the live release gate.

Follow-up validation (2026-09-06): 26 Core tests pass in both fallback and FenCore modes; runtime, settings, bundled Ace integration, and Mechanic regressions pass. Luacheck reports zero warnings/errors for 15 runtime files, including a separate check without the shared workspace lint configuration. All 87 manifest references exist and all 70 loaded Lua sources compile. Formatting, package exclusions, English locale defaults, and diff whitespace checks pass. The five new diagnostic strings use English fallback in non-English locales. The user subsequently reported successful manual in-game testing; individual scenarios and client build were not recorded. Remote CI results are tracked on the release PR.
