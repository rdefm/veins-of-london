# 04 — Faction vein daily behavior

**What to build:** faction veins drift like any other vein (already true after ticket 01), but need their own daily upkeep so they don't all park at the ceiling within a month, and their day-one starting strengths need re-expressing in growth terms.

**Blocked by:** 01 (needs drift/growth in place). Independent of 03 — can run in parallel.

**Status:** ready-for-agent

- [ ] `Sites.roll_faction_vein_growth()` replaced: the vein drifts on the normal daily pass (no change needed there — that's ticket 01's `drift_veins()`), **and** if `growth >= 85`, `chance(0.40)` that the faction prunes it back to ~55. No ore granted to anyone — off-screen world simulation only.
- [ ] `Factions.DAY_ONE_ROSTER`'s hardcoded per-faction-vein level (1–5) re-expressed as starting `growth` via `growth = 20n - 10` (Lv1→10, Lv2→30, Lv3→50, Lv4→70, Lv5→90). These stay hardcoded constants — not fresh rolls at load time.
- [ ] `Factions.create_faction_vein` takes `growth` instead of `level`.
- [ ] Confirm collapse-roll outcome for a faction vein at 0 was already implemented as delete-outright in ticket 01's `collapse_vein()` — this ticket does not re-touch that branch, only the prune-back-at-85 behavior and roster re-expression.
- [ ] `test_factions.gd`, `test_sites.gd` updated: prune-back fires only at growth ≥ 85 and only 40% of the time (seeded soak, plausible window not a fixed day); `DAY_ONE_ROSTER` growth values match the `20n-10` mapping.
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean; `scripts/run_tests.sh` green.
