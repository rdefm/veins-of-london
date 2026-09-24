# 01 — Vein level, terroir cap & neutral-50 drift rework

**What to build:** Every vein gains a persistent earned `level` (starts at 1, capped by its site's terroir tier: poor=2, fair=3, rich=4, saturated=5). The existing condition axis (`growth`) drops its 45–55 no-drift band and old distance-scaled band table entirely: exactly 50 is the sole stable point, and every night a vein's condition drifts one step further from 50 (down if below, up if above) by a magnitude that scales with the vein's level and a per-night random component. The ordinary ceiling (100) and special `wildCeiling` ceiling (120) are unchanged.

Resolved formula (from the cultivation-refining grilling session, `.scratch/cultivation-refining/spec.md` §8.3):
`drift_magnitude = level + randi_range(1, 5)`, re-rolled every night per vein, applied toward whichever side of 50 the vein's condition currently sits on. A vein exactly at 50 does not drift.

Also resolve the harvest-depth conflict in REFERENCE.md §1.2 (data constants say light=9/hard=24, prose paragraph says 15/40): the data constants win — correct the prose in the same change.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/cultivating.gd` (`drift_veins()`, `value_tier()` — level field lives alongside `growth`)
- `data/vein_growth.json` (new level-cap-by-terroir table; verify/fix `pruneLightDepth`/`pruneHardDepth`)
- `systems/sites.gd` (terroir tier lookup)
- `docs/REFERENCE.md` §1.2 (update band table removal, drift formula, harvest depth prose fix — this is a production doc, update only once this ticket's mechanics are implemented and approved, per spec §7)

**Status:** ready-for-agent

- [ ] New veins seed at level 1; level is stored as persistent per-vein state (survives save/load, Rewind)
- [ ] Level is capped per terroir tier (poor=2, fair=3, rich=4, saturated=5) everywhere it can change
- [ ] Old 45–55 no-drift band and distance-scaled band table are removed; only condition==50 is stable
- [ ] Drift magnitude = `level + randi_range(1,5)`, re-rolled nightly, direction toward whichever wall the condition currently leans
- [ ] 100/120 ceilings unchanged; `wildCeiling` bonus still applies where it does today
- [ ] `pruneLightDepth`/`pruneHardDepth` confirmed as 9/24 in data; stale "15/40" prose in REFERENCE.md §1.2 corrected
- [ ] Unit tests cover: level-cap enforcement per terroir, seed-at-1, drift direction/magnitude at several levels, neutral-50 stability
