# 05 — Development eligibility & streak tracking

**What to build:** A vein below its terroir level cap becomes "development eligible" once its condition is ≥90, and stays eligible across consecutive nights as long as it never dips below 90 in between (using ticket 04's shared streak-clear hook). Eligibility for a given night's check is evaluated using the condition the player left the vein in — before that night's drift is applied, so a drift-driven dip from 89 to 90 does not qualify a vein for that same night's check.

**Blocked by:** 01, 03, 04 (needs the level field, and both mutation paths — cultivate and harvest — wired into the shared streak-clear hook).

**Relevant files:**
- `systems/cultivating.gd` (eligibility check + streak counter, called from `drift_veins()` before drift is applied)
- `systems/time_system.gd` (`daily_tick()` step ④ — no reordering, this logic extends the existing `Cultivating.drift_veins()` call in place)

**Status:** ready-for-agent

- [ ] Eligibility = `condition >= 90 AND level < terroir_cap`, checked using the pre-drift (as-left) condition value
- [ ] Streak persists across nights only if condition never dropped below 90 on any day in between (relies on ticket 04's invariant)
- [ ] A drift-only dip from 89→90 does not make the vein eligible for that same night's check
- [ ] Streak counter is persistent per-vein state, survives save/load and Rewind
- [ ] Test: vein left at 89 fails eligibility before drift; left at 90 qualifies
- [ ] Test: a temporary within-day dip below 90 (even if cultivated back above 90 same day) resets the streak
- [ ] Test: remaining at 90+ after a harvest preserves the streak
