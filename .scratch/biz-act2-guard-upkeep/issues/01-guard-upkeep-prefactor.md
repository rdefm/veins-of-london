# 01 — Guard upkeep prefactor: shared value order, guard slots, data block, expense kinds

**What to build:** Groundwork only; the player sees no change.

1. **Shared value order.** Move the faction kit-allocation vein value order (combined magnitude, ties by site id) into one helper that player and faction veins share. Faction kit allocation must give identical results.
2. **Guard slot helpers.**
   - Guard count for a vein: 1 if the tier is `guarded`, plus `extraGuards`.
   - Guard count for HQ: `home.guardCount`.
   - A drop-one-guard helper for veins that removes the last slot: newest extra first, tier guard last. Losing the tier guard sets `guarded` → `warded`. Lock and ward are never lost.
   - An HQ drop that just decrements `guardCount`.
3. **Data block.** Add a `guardUpkeep` block in JSON, loaded and validated by GameData:
   - `weeklyWage` 500
   - `graceDays` 1
   - `guardCostHistoryDays` 28
   - `faction.maxExtraGuardsPerVein` 3
   - `faction.wageReserveWeeks` 2
4. **Expense kinds.** The BusinessStats daily tally records expenses split by kind (`staff`, `guard`, `calc`). The existing expense total and charts stay the same.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/faction_sim.gd` (`_value_order`, kit allocation), `systems/cultivating.gd` (`combined_magnitude`, `vein_raid_resist`, `security_label`)
- `systems/home.gd` (guardCount reads), `autoload/GameData.gd`, `data/constants.json` (or a new `data/guard_upkeep.json`)
- `systems/business_stats.gd`, `systems/business.gd` (staff wage + `pay_calc_purchase` expense lines)
- `tests/test_faction_sim.gd`, `tests/test_cultivating.gd`, `tests/test_home.gd`, `tests/test_business.gd`
- CODEMAP.md (new data file / helper ownership)
- Spec: `.scratch/biz-act2-guard-upkeep/spec.md` §Guard counting, §Data
- REFERENCE.md §1.6, §1.8 (value order), §2 (businessStats)

**Status:** ready-for-agent

- [ ] One shared vein value-order helper exists; faction kit allocation uses it and its tests still pass unchanged
- [ ] Vein guard count and HQ guard count helpers exist
- [ ] Dropping a guard from a vein with extras removes an extra. From a vein with 0 extras it sets `guarded` → `warded`. Lock, ward and alarm upgrades are never touched
- [ ] HQ drop decrements `guardCount`; `home.security` is unchanged
- [ ] `guardUpkeep` JSON block is loaded into GameData; no guard wage numbers in code
- [ ] BusinessStats daily tally has per-kind expenses that sum to the existing total; old saves and old day records backfill safely
- [ ] Syntax check clean, all tests pass, CODEMAP updated
