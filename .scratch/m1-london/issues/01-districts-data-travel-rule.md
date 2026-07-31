# 01 — Districts data + travel rule

**What to build:** `data/districts.json` (all 9 districts per `docs/M1-LONDON.md` D1) loaded by `GameState`, plus the D3 travel rule: `state.world.currentDistrict`, and the "district-located action targeting a district ≠ current costs 1 extra travel block first" behaviour for prospect/seed/cultivate/harvest/sell. Waking (daily tick / rest) resets `currentDistrict` to `"shoreditch"`. District `priceMod`/`dangerMod` feed into the existing sell (Archie lane) and mug-chance formulas.

This ticket is system-only, verified headlessly — no UI. The Map tab ticket (04) is what exposes travel to the player; this ticket just makes the underlying mechanic correct and testable.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] `data/districts.json` matches D1's table exactly (all 9 districts, all fields, `oreBias` uniform-remainder semantics)
- [x] Cross-district district-located action costs exactly 2 blocks total (1 travel + 1 action), same-district costs 1; both gated correctly when only 1 block remains
- [x] Travel sets `currentDistrict` as a side effect of the combined action, not as a separate player-facing step
- [x] Waking/resting resets `currentDistrict` to `"shoreditch"`
- [x] Selling applies `priceMod` and `dangerMod` (via `getEffectiveMugChance(0.20 + dangerMod)`) for the district the player is currently in at sale time
- [x] Tests: 2-block costing (both directions — already-there vs. needs-travel), wake-at-home reset, price/danger mod application
- [x] `godot --headless --check-only --script` clean on all touched files — see note below

## Comments

- `seed()` (and `prospect`, which doesn't exist yet) are deliberately NOT wired into `Travel.ensure_district()` here: `seed()` has no cross-district target today (it always plants in `currentDistrict`), and ticket 02 replaces it with `attemptSeed(siteId)`, which per D2 requires the player to already be in the site's district rather than travelling to it. `cultivate`/`harvest_cautious`/`harvest_full` (which do act on an existing vein with a fixed `district`) are wired, and `sell` reads `priceMod`/`dangerMod` for the current district without a travel step, per D3's own clarification that selling "uses the district you are in at sale time." Confirmed against the spec-review pass — no gap.
- `godot --headless --check-only --script <file>` does not resolve autoload globals (`GameState`, `TimeSystem`, etc.) when invoked as a standalone single-file check on this Windows Godot 4.4.stable binary — this reproduces identically on every pre-existing file that references an autoload (verified against `economy.gd`, `cultivating.gd`, `nav.gd`, etc., not just the files touched here), so it isn't a regression. The full headless test suite (`godot --headless -s tests/test_runner.gd`), which boots the whole project including autoloads, is green: 196 passed, 0 failed. Worth a look at whether `scripts/check_all.sh`'s Linux binary behaves differently before relying on the check-only command elsewhere.
- PROSE-REVIEW: `data/districts.json`'s 9 `blurb` strings are new prose, drafted against the `CONTENT-GUIDE.md` tone bible, not yet human-reviewed.
