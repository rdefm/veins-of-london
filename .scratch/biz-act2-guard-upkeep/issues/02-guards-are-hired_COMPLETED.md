# 02 — Guards are hired: prorated advance, no purchase price

**What to build:** Guards have no purchase price. Hiring a vein's Hired Guard tier guard, a vein's +1 Guard, or an HQ guard costs only the advance for the rest of this week.

- **Advance:** `round(weeklyWage × daysLeft / 7)`, where `daysLeft` counts today through Sunday inclusive. That's £500 on a Monday, £357 on a Wednesday, £71 on a Sunday. It's the same proration as staff wages.
- **Paying:**
  - The player pays from cash, with a "Guard hire" bank record. The hire is refused if cash is short.
  - The payment is recorded as a guard expense (vein id or `home`) in BusinessStats.
  - It's also written to a new bounded per-day, per-place guard cost history (`guardUpkeep.history`, trimmed to `guardCostHistoryDays`).
- **Unchanged:** locks and ward runes keep their one-off prices, and the HQ guard's `minTier` still applies.
- **Factions:** a faction moving a vein up to `guarded` pays the advance from `resources` instead of the old price.
- **Display:**
  - Hire buttons show today's advance and "then £500/week".
  - Every vein security row (vein detail panel, vein list, map vein card) shows the current weekly guard cost (guard count × weeklyWage).
  - The HQ security screen shows the same weekly cost.

**Blocked by:** 01 — Guard upkeep prefactor.

**Relevant files:**
- `systems/cultivating.gd` (`upgrade_vein_security`, `next_security_upgrade`, `extra_guard_cost` — delete the curve)
- `systems/home.gd` (HQ guard purchase ~L440), `systems/factions.gd` (`apply_security_upgrades`)
- `systems/business.gd` (`prorated_wage`), `systems/calendar.gd` (weekday), `systems/bank.gd`, `systems/business_stats.gd`
- `data/vein_security.json` (`guarded` cost), `data/home.json` (`guard` cost)
- `autoload/GameState.gd`, `autoload/SaveManager.gd` (backfill `guardUpkeep.history`)
- `scenes/components/vein_detail_panel.gd`, `scenes/screens/vein_list.gd`, `scenes/screens/map.gd`, `scenes/screens/hq_door.gd`
- `tests/test_cultivating.gd`, `tests/test_home.gd`, `tests/test_factions.gd`, `tests/test_savemanager.gd`
- Spec §Hiring, §Visibility; REFERENCE.md §1.6, home security (HQ guard), §2

**Status:** ready-for-agent

- [ ] Vein tier guard, +1 Guard and HQ guard hires cost only the advance: Monday £500, Wednesday £357, Sunday £71
- [ ] A hire is refused when cash < advance, with no state change
- [ ] A hire writes a "Guard hire" bank record, a guard expense against the vein id or `home`, and a history entry for that day and place
- [ ] Lock and ward rune prices are unchanged; the extra-guard cost curve is gone from code
- [ ] A faction upgrade to `guarded` deducts the advance from `resources`
- [ ] `guardUpkeep.history` is backfilled empty on old saves, survives save/load, and Rewind restores it
- [ ] Hire buttons show the advance and the weekly wage; security rows and the HQ security screen show the weekly guard cost
- [ ] REFERENCE §1.6, HQ security and §2 updated; CODEMAP updated
- [ ] Any new UI strings flagged PROSE-REVIEW

**Human QA on device:**
- The vein detail panel, vein list and map card security rows show £/week.
- The Hired Guard and +1 Guard buttons show "£X today, then £500/week".
- The HQ door guard row shows the same.
