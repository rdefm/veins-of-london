# 05 — Terroir amplification

**What to build:** widen the terroir spread so which sites you hold carries the mid/late-game progression that `level` used to. Hard requirement of the design, not polish — without it a day-80 vein plays identically to a day-5 vein.

**Blocked by:** 01 (uses `ceiling(vein)` and `terroir_yield_mult` plumbing landed there).

**Status:** ready-for-agent

- [ ] `terroirYieldMult` in `data/vein_growth.json` drives prune yield directly: poor 0.6 / fair 1.0 / rich 1.6 / saturated 2.4 (4× spread, worst to best seedable land). Barren tiers remain unseedable.
- [ ] `data/sites.json` `discoveryBonusPool` becomes `["vigour", "wildCeiling", "yield"]` — confirmed renames: `recharge`→`vigour`, `maxLevel`→`wildCeiling`.
- [ ] `vigour` effect: `+1` to rightward drift, `-1` to leftward drift (min 0). Stacks with the King's Cross district special, which becomes the same effect (`data/districts.json` special text updated from the old `rechargeBlocks −1` wording to the drift equivalent).
- [ ] `wildCeiling` effect: raises this vein's growth ceiling from 100 to 120 (`Cultivating.ceiling()` already accepts this from ticket 01 — this ticket is what actually grants the bonus).
- [ ] `yield` bonus unchanged (`max(rolled + 1, round(rolled × 1.15))`).
- [ ] A saturated + `wildCeiling` vein's maximum single hard-prune yield is at least 5× a poor vein's (spec §11 item 9 — assert this, it's the number the requirement lives or dies on).
- [ ] `docs/M1-LONDON.md` updated: D1 King's Cross special, D2 hospitability application + bonus pool + natural vein starting growth.
- [ ] `test_sites.gd`, `test_cultivating.gd` updated/added for the yield-mult spread and the vigour/wildCeiling bonus effects.
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean; `scripts/run_tests.sh` green.
