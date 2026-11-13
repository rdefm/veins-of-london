# 06 — XP, levels, training and the Muscle daily tick

**What to build:** Guards grow. Posted guards earn +1 XP/day (Reserve 0; Lazy earns no passive XP); every guard whose weight counted in a successful repel earns +5. XP multipliers apply to all sources: Quick study ×1.5, Slow learner ×0.5. Level thresholds 50/100/200/400 (L2–L5); a level-up sends a notification. A new level's wage applies from the next Monday bill.

**Train ›** on the guard detail sheet: costs £200 × current level, gives +10 XP, and the guard is away 1 day (off post, not counted anywhere), then returns to their post. No player time block, no session cap; the officer's Train boost does not apply. The detail sheet shows XP and next threshold. The Muscle daily tick runs passive XP and the training countdown at a documented point in the daily-tick order.

**Blocked by:** 05 — Weighted resist/repel and Security score.

**Relevant files:**
- `systems/muscle.gd` (`award_xp`, `train`, `daily_tick`), `systems/raiding.gd` and `systems/home.gd` (repel success hooks), `systems/guard_upkeep.gd` (wage at Monday), `systems/notify.gd`
- `systems/time_system.gd` / day rollover (daily-tick order)
- Security screen guard detail sheet
- Tests: `tests/test_muscle.gd`, `tests/test_guard_upkeep.gd`, `tests/test_raiding.gd`
- REFERENCE.md daily-tick order, §1.6

**Status:** ready-for-agent

- [ ] Passive XP only on post; Lazy gets none; Reserve gets none
- [ ] Repel success gives +5 to each guard whose weight counted
- [ ] Quick study / Slow learner multipliers applied to every source
- [ ] Level-ups at 50/100/200/400 with one notification each
- [ ] Mid-week level-up: current week's bill unchanged, next Monday uses the new wage
- [ ] Train charges £200 × level, +10 XP, guard off post for 1 day then back; refused if unaffordable or guard unavailable
- [ ] Tests set day/state directly, no loops on game conditions
- [ ] PROSE-REVIEW flagged: level-up notification, Train strings
- [ ] On-device check listed: XP/next on detail sheet, Train button and away state
