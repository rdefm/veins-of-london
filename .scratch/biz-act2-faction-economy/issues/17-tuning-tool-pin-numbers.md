# 17 — 60-day tuning tool + pin numbers

**What to build:** A headless dev script (not a test) runs the daily rollover 60 days from a fresh start and prints per-good prices and per-producer shares. Use it to pin every placeholder in JSON and REFERENCE.md against the targets: each producer faction ~30–40% of its primary ore; Guild ~50%+ of crafting for its items; Independents ~20–25%; player at end of Act 1 ~10–15% of their main ore; idle London prices within sub-spec 1's feel targets.

Spec: §Tuning tool.

**Blocked by:** 10 — Per-vein kit allocation; 12 — Conclave arbitrage; 13 — Retire stand-in supply.

**Relevant files:**
- New script under `scripts/`, `data/factions.json`, `data/market.json`
- `.scratch/0-bugfixes/biz-act2-market-sim_COMPLETED/spec.md` (price feel targets)
- REFERENCE.md §1.8, §3.13

**Carried from ticket 11 (faction trading isolation in market tests):** `tests/test_market.gd`'s `_tick()` temporarily sets every faction's `trading.sellFraction` and `trading.maxBuyMult` to 0 so its rollover cases pin Market maths against stand-in London only. Faction London trades now move prices in the real rollover, which broke three idle-market tests (`no_player_sales_drifts_to_the_idle_premium_and_holds`, `war_lifts_shield_then_physics_ore_over_following_days`, `demand_all_lifts_and_lowers_every_item`). Once numbers are pinned, check whether the switch-off in `_tick()` can be removed, i.e. the market tests hold with faction trading on at the pinned values; if not, re-pin the tests' expected values or record why the isolation stays.

**Status:** ready-for-agent

- [ ] Script runs headless and prints prices + shares
- [ ] Targets met (paste final run summary in report)
- [ ] All placeholders pinned in JSON and REFERENCE.md
- [ ] Faction-trading switch-off in `test_market.gd` `_tick()` revisited (removed, or kept with reason)
- [ ] Full suite + check_all pass
