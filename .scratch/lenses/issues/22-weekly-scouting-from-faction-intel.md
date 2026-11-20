# 22 — Weekly scouting from faction intel

**What to build:** Good intel on a faction feeds the player vein security without spending blocks. Every Monday rollover, for each faction:
- **Count:** the player gets 1 free scout per 5 points of intel on that faction, rounded down (intel 24 → 4 scouts; intel 4 → none).
- **Target:** each scout lands on a random vein of that faction. Several can land on the same vein.
- **Rules:** each uses the same rolls, snapshots and 7-day freshness as a manual scout.
- **Free:** these scouts cost no block and give no intel gain.
- **No veins:** a faction with no veins gets nothing.
- **Notification:** one Monday notification sums up what was found, per faction. There is none if nothing was found.

The points-per-scout value goes in data. Rolls draw from the game RNG stream, so Rewind replays them. Record the step's place in the rollover order in REFERENCE.

**Blocked by:** 19

**Relevant files:**
- `systems/intel.gd`: shared scout roll, `decay`
- `systems/time_system.gd`: rollover order (⑥.5i, beside `Intel.decay`)
- `systems/calendar.gd`: `is_monday`
- `systems/sites.gd`: `sites_with_faction_vein`
- `systems/notify.gd`, `systems/daily_brief.gd`
- `data/constants.json`: `intel.scout`
- `tests/test_intel.gd`, `tests/test_time_system.gd`
- `CODEMAP.md`
- REFERENCE.md §3.1 "Intel", rollover order table

**Status:** ready-for-agent

- [ ] Runs on Mondays only. The scout count is intel ÷ 5, rounded down. Targets are random veins of that faction, and repeats are allowed.
- [ ] No block spent and no intel gain. Deterministic under Rewind.
- [ ] A faction with no veins gets nothing. No notification when nothing was found.
- [ ] Human QA: Monday notification text. PROSE-REVIEW: notification strings.
- [ ] Syntax check clean, tests pass, REFERENCE/CODEMAP updated.
