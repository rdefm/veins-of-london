# Perf + robustness pass (from .scratch/perf-robustness/code-review.md)

Status: ready-for-agent

Source of numbers: `.scratch/perf-robustness/code-review.md` (measured, desktop headless). Section refs (§) point there. No formula, data, or mechanic changes.

## Problem Statement

The player's end-of-day on the Map takes ~1.6 s on desktop (est. 3-5x worse on a mid-range phone) because every `state_changed` emit tears down and rebuilds screens, and one rollover emits 24 times. Whole-state deep copies run in slow recursive GDScript on every time block and event card. The APK is 301 MB (was 27 MB) because unused reference art and test/tool folders ship. Save files can corrupt if the app is killed mid-write, and on-disk saves rely on ~600 lines of hand-written int-restoring. 

## Solution

Make the same game faster, smaller and safer with no visible behaviour change: coalesce UI redraws to one per frame, skip Map rebuilds when nothing map-relevant changed, use native copying, trim the export, compress event stills, write saves atomically with a backup fallback, memoise pure lookups in the daily faction sim, store on-disk saves in the type-preserving binary format, and centralise whole-state snapshotting.

## User Stories

1. As a player, I want end-of-day on the Map to finish quickly, so that the game feels responsive on my phone.
2. As a player, I want tapping buy/craft/sell to respond without a visible hitch, so that multi-emit actions don't stall the UI.
3. As a player, I want the Phone app to not reset my scroll position several times per action, so that I keep my place.
4. As a player, I want event cards to advance without a pause, so that story pacing isn't broken by snapshot copying.
5. As a player on a low-storage phone, I want a much smaller download, so that I can install the game.
6. As a player, I want event stills to still look right after compression, so that art quality isn't visibly degraded.
7. As a player, I want my manual save slot to survive the app being killed mid-save, so that I never lose a slot to corruption.
8. As a player, I want a corrupt main save to fall back to its backup and be told so, so that I can keep playing.
9. As a player, I want saved numbers to come back as the same type they went in, so that nothing breaks only after a save/load cycle.
10. As a player with existing JSON saves, I want them to keep loading, so that my progress survives the format change.
11. As a player, I want exported/imported save strings to keep working, so that sharing and backup still work.
12. As a player, I want autosave to stay fast, so that frequent autosaves don't cause stutter.
13. As a developer, I want `mark_changed()` to be the single way systems request a redraw, so that new code can't reintroduce redraw storms.
14. As a developer, I want a lint rule rejecting `state_changed.emit()` in `systems/`, so that the discipline is enforced.
15. As a developer, I want a synchronous `flush_now()`, so that UI tests can assert right after an action.
16. As a developer, I want screens to ignore a flush after they are queued for deletion, so that swapped-out screens don't error.
17. As a developer, I want the Map to expose a cheap layout signature from the system layer, so that the screen stays read-only and rebuilds only when needed.
18. As a developer, I want `deep_copy` to be native and proven isolated from its source, so that Rewind and snapshots stay correct.
19. As a developer, I want one place that builds a whole-state snapshot excluding transient keys, so that three call sites stop repeating the recursion-avoidance dance.
20. As a developer, I want event snapshots copied once, not twice, so that cards cost ~2 ms instead of ~20.
21. As a developer, I want combat's single-copy snapshot left alone, so that no working path regresses.
22. As a developer, I want FactionSim craft-cost lookups cached, so that the daily tick does less repeated work.
23. As a developer, I want a withholding set and per-faction traded-goods computed once per trade pass, so that scans aren't repeated.
24. As a developer, I want a same-seed state hash identical before/after memoisation, so that I know no formula changed.
25. As a developer, I want `tests/`, `tools/`, `scripts/`, `docs/`, `reference/`, `plans/`, `.scratch/`, the debug addon and reference art excluded from release exports, so that the APK only carries runtime assets.
26. As a developer, I want the MCP debug addon inert in release builds, so that it doesn't run per-frame or capture logs in the shipped game.
27. As a developer, I want reference art folders set to not import, so that the editor stops generating textures for them.
28. As a developer, I want import settings for event stills and large HQ backdrops set to lossy, so that APK size drops.
29. As a human QA reviewer, I want a short on-device checklist for compressed art and the trimmed export, so that visual regressions are caught.
30. As a developer, I want a permanent UI refresh profiler script, so that per-listener cost regressions are visible.

## Implementation Decisions

Build order = review §7 (one ticket each); each item is independent unless noted.

1. **Native deep copy (§2.3).** `GameState.deep_copy` delegates to native `duplicate(true)` for Dictionary/Array, returns primitives as-is. State stays pure data.
2. **Single snapshot copy (§2.4).** Event pre-mutation snapshot is copied exactly once. `Snapshots` gains an owned-push path that appends without copying (or callers pass live data and `push` does the one copy). Combat's snapshot path unchanged.
3. **Snapshot helper (§4.7).** One `GameState` snapshot function: shallow-copies state, nulls transient keys (`blockStart`), empties `event.snapshots`, then deep-copies. Used by Rewind block-start, event pre-mutation snapshot and SaveManager's saveable state. The recursion CAUTION note is removed.
4. **Batched redraw (§2.1, §5.2).** EventBus gains `mark_changed()` (sets dirty flag, defers one flush), `flush_now()`, and keeps the `state_changed` signal for listeners. All `state_changed.emit()` calls in systems/autoload become `mark_changed()`. Listener refresh handlers return early if queued for deletion. `CONNECT_DEFERRED` is explicitly not used. `lint_tokens.sh` rejects `state_changed.emit()` in `systems/`. Tests asserting UI immediately after an action call `flush_now()`.
5. **Map rebuild cache (§2.2).** A system-layer layout-signature helper summarises the site/vein ids, owners and growth bands that layout/partition/slot assignment read. Map compares a signature (that plus pending-event ids, active contact pins, dark-mode flag) against the last one and only rebuilds when it differs; otherwise just queues a redraw.
6. **Export trim (§3.1, §4.8).** Both export presets exclude reference-plates, character-references, tests, tools, scripts, docs, reference, plans, .scratch and the debug addon. The MCP helper autoload becomes inert outside debug builds (early return in `_ready`) and/or is removed from release via an export plugin; the autoload path must not go missing at boot. Reference art folders set to do-not-import.
7. **Texture compression (§3.2).** Event stills and large HQ backdrops move from lossless to lossy WebP (~0.85). Icons/sprites stay lossless. VRAM-compressed is deferred unless low-end memory warnings appear. Needs human visual QA.
8. **Atomic saves (§4.1).** Writes go to a temp file, error-checked at open/close, previous main renamed to `.bak`, temp renamed over main; failures return `{ok:false, reason}`. Load falls back to `.bak` when the main fails to parse and tells the player.
9. **FactionSim memoisation (§2.5).** Static cache of craft cost keyed by recipe+skill (return a duplicate if any caller mutates), withholding set built once per `trade()`, traded goods computed once per faction per pass. `held()`/`reserve()` values mutated by trades are NOT cached.
10. **Binary on-disk saves (§4.6).** Saves written via `var_to_bytes`/`store_var`, read with `bytes_to_var` (never the with-objects variant). Loader tries binary first, falls back to the existing JSON path including the legacy int restoration (which is frozen). `export_string()` keeps its JSON+base64 form unless trivially switched to base64 of binary. Verify no code relies on JSON's int→string dictionary-key conversion.
11. **UI profiler (§5.4).** New script boots the main scene, visits each screen, prints per-listener ms alongside the existing block-end profiler.

## Testing Decisions

Good test: asserts externally visible behaviour (state values, emitted-signal counts, files on disk, return values), not internals. Run a new test file alone under `timeout 60` first. Per project rules: no game-state-condition loops, address cards by key, one targeted run per change plus a final `run_tests.sh` + `check_all.sh`.

Seam (one, highest available): the existing headless test harness (`scripts/run_tests.sh` over `tests/test_*.gd`) driving system functions and autoloads, plus the existing profiling/sim scripts for before/after equivalence. No new seams.

- Deep copy / snapshot helper / owned push: extend rewind and snapshot tests — copy equals source, mutating copy leaves source untouched, snapshot excludes transient keys, event snapshot stack has no nested stacks.
- Batched redraw: extend the EventBus test — N `mark_changed()` calls in one frame → exactly 1 `state_changed`; `flush_now()` emits synchronously; no emit when not dirty; queued-for-deletion listener safe.
- Map cache: extend the map canvas test — cash-only change does not rebuild; site/vein/owner/growth change does.
- Atomic saves / binary / backup fallback: extend the save manager test — truncated main falls back to `.bak`; failed write leaves previous file intact; binary round-trip preserves int types and equals original state; legacy JSON save still loads; imported string cannot create objects.
- FactionSim: same-seed run of the faction economy sim produces an identical `JSON.stringify(state).hash()` before and after (record the baseline hash before changing code).
- Export/compression/profiler: no unit tests; verified by APK size check and human on-device list (banding on stills, game boots with addon excluded).
- Lint: `lint_tokens.sh` fails on a planted `state_changed.emit()` in `systems/`.

Prior art: `tests/test_eventbus.gd`, `test_rewind.gd`, `test_savemanager.gd`, `test_map_canvas.gd`, `test_phone_saveload.gd`; `scripts/profile_block_end.gd`, `scripts/sim_faction_economy.gd`.

## Out of Scope

Need a human design decision first (review "Decisions needed"), so not specced here:
- §4.2 save on pause/close (whether a mid-event/mid-combat save resumes there).
- §4.3 Android Back button routing per screen.
- §4.5 persisting the RNG stream (Rewind/reload re-roll rules).
- Counter ids (§4.4): dropped by owner, modest benefit and shifts seeded outcomes.
- §2.9 `stable_unit` value change (balance change).

Also deferred: §2.6 threaded image preload, §2.7 low-processor mode, §2.8 Phone in-place updates, §4.9-4.11, §5.1 god-file splits, §5.3 repo hygiene (git gc/LFS), boot-time trace (§1.4, needs on-device data).

## Further Notes

- Estimated outcome of items 1-5: desktop end-of-day on Map ~1.6 s → ~0.15 s; APK −83 MB from excludes alone.
- Mobile numbers are estimates; on-device measurement is the human's.
- Update `CODEMAP.md` when files are added/renamed/repurposed (new profiler script, any new helper modules).
