# 03 — Value-tier consumers

**What to build:** every formula that used to key off `level` (1–5) now keys off `Cultivating.value_tier(vein)` (1–6), so a wild vein is automatically the highest-value raid target, faction income source, and rivalry weight — through formulas that already exist and are already tuned. Plus an explicit continuous growth tilt on raid exposure.

**Blocked by:** 01 (needs `value_tier` to exist).

**Status:** ready-for-agent

- [ ] `Raiding.stealth_success_chance` value term re-pointed at `value_tier`.
- [ ] `Raiding._pick_target_vein` and `Factions._pick_target_vein` re-pointed at `value_tier`.
- [ ] Faction vein income re-pointed at `value_tier`.
- [ ] Rivalry target weighting re-pointed at `value_tier`.
- [ ] `Combat.start_defend_vein` scaling arg re-pointed at `value_tier`.
- [ ] `Combat.generate_raid_enemy`'s `veinLevel` parameter renamed to reflect it's now a value tier (same 1–6 range, no formula change — the parameter name was lying).
- [ ] `Events.start_raid` scaling arg re-pointed at `value_tier`.
- [ ] `Raiding`'s Direction-B daily raid chance gains a continuous growth tilt: `RAID_GROWTH_WEIGHT = 0.15`, `growth_tilt = RAID_GROWTH_WEIGHT * (growth / ceiling)`, added to the existing `RAID_BASE_CHANCE + relation + danger + raidResist` stack.
- [ ] No call site left reading the deleted `level`/`levelLabel` fields — grep clean.
- [ ] `test_raiding.gd`, `test_factions.gd`, `test_combat.gd` updated; `test_cultivating.gd` covers `value_tier` boundaries at 19/20, 99/100, and above 100 for a `wildCeiling` vein (spec §11 item 8).
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean; `scripts/run_tests.sh` green.
