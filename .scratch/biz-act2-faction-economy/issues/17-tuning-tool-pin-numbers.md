# 17 — 60-day tuning tool + pin numbers

**What to build:** A headless dev script (not a test) runs the daily rollover 60 days from a fresh start and prints per-good prices and per-producer shares. Use it to pin every placeholder in JSON and REFERENCE.md against the targets: each producer faction ~30–40% of its primary ore; Guild ~50%+ of crafting for its items; Independents ~20–25%; player at end of Act 1 ~10–15% of their main ore; idle London prices within sub-spec 1's feel targets.

Spec: §Tuning tool.

**Blocked by:** 10 — Per-vein kit allocation; 12 — Conclave arbitrage; 13 — Retire stand-in supply.

**Relevant files:**
- New script under `scripts/`, `data/factions.json`, `data/market.json`
- `.scratch/0-bugfixes/biz-act2-market-sim_COMPLETED/spec.md` (price feel targets)
- REFERENCE.md §1.8, §3.13

**Carried from ticket 11 (faction trading isolation in market tests):** `tests/test_market.gd`'s `_tick()` temporarily sets every faction's `trading.sellFraction` and `trading.maxBuyMult` to 0 so its rollover cases pin Market maths against stand-in London only. Faction London trades now move prices in the real rollover, which broke three idle-market tests (`no_player_sales_drifts_to_the_idle_premium_and_holds`, `war_lifts_shield_then_physics_ore_over_following_days`, `demand_all_lifts_and_lowers_every_item`). Once numbers are pinned, check whether the switch-off in `_tick()` can be removed, i.e. the market tests hold with faction trading on at the pinned values; if not, re-pin the tests' expected values or record why the isolation stays.

**Status:** ready-for-agent (in progress — WIP commit; see Progress below)

- [x] Script runs headless and prints prices + shares
- [~] Targets met — partially; see Results
- [ ] All placeholders pinned in JSON and REFERENCE.md — JSON pinned, **REFERENCE.md not yet updated**
- [x] Faction-trading switch-off in `test_market.gd` `_tick()` revisited — **kept** (human decision), now also disables Conclave arbitrage
- [ ] Full suite + check_all pass — check_all clean; **2 market tests still fail** (see Outstanding)

## Progress (2026-09-28, session 1)

### Tool
`scripts/sim_faction_economy.gd` (+ `_impl.gd`). Usage:
`godot --headless -s scripts/sim_faction_economy.gd -- seed=N player=N playerOre=life days=60 political=war`
Seeds day-one veins like New Game; prints Ticker state, vein timeline (count/mean growth/primary count), vein churn (claimed/died/lostTo/wonFrom), mean ore harvested/day days 31+, London prices (now + range), ore/craft share tables, faction cash/holdings. `player=N` credits N ore/day to player share + London supply. Note: runs `daily_tick`, so it writes autosaves like the tests do.

### Diagnosis that drove the design changes (human-decided, in chat)
- Faction veins made ~1 ore/vein/day: all were level 1 forever (prune at 85 < developmentThreshold 90), ore types random by district (producers owned 0–1 primary veins). London was sized ~190/type/day → factions 0–3% share.
- Vein losses are rivalry transfers, not collapse; total faction veins hold ~26–30 (no NPC claims without player prospecting). Rivalry churn **left to 4a** (human).
- Anchor (human): 3 player level-3 veins (~13 ore/day) ≈ 25% of an ore type → ~52/type/day total harvest; factions need ~143/day.

### Changes made
- `systems/factions.gd` `DAY_ONE_ROSTER`: per-vein pinned `ores` (~2/3 primary, rest secondary), same 30 veins/districts. `_seed_day_one_vein`: growth `dayOneFactionGrowth` 70, terroir tier +`dayOneFactionTierBump` 1, first `dayOneFactionMaxLevelShare` 0.75 (rounded) of each faction's roster at its tier's level cap, rest cap−1. Keys in `data/vein_growth.json`, required by `GameData._validate_vein_growth`.
- `systems/faction_sim.gd`: `maturing_vein(veins)` — highest-growth vein below its level cap is never pruned (grows to develop/level up); then the next. Stateless.
- `data/factions.json`: Firm `pruneFloor` 40 → 51.
- `systems/factions.gd`: `RIVALRY_RESOURCE_DIVISOR` 1000 → 50000 (faction cash now reaches £10k–£300k; odds were saturating).
- `data/market.json`: `independentsShare` 0.9→0.3, `oreConversionRate` 0.75→0.1, `dumpVolumeMult` 0.5→2.0; ore normalStock 300→70, civilianDemand time 14 / physics 32 / life 20 / fate 30 / emotion 34; items normalStock 40→10, civilianDemand 20→3.
- Tests re-pinned: test_factions roster, test_faction_sim (fixture veins at level 3 = fair cap; Firm floor; collapse case uses level 1 — level>1 veins de-level instead of dying; 2 new maturing cases), test_time_system fixture level, test_savemanager rounding, test_market (dump 90 = a week at 13/day, recovery within 10%; ordinary day 13; war/dampen now direction/derived-demand only; boom via stronger override), GameData snapshot fixture regenerated.

### Results (6 seeds, 60 days, means over days 31–60)
- Faction harvest 150–200/day (need ~143) — volume gap closed.
- Ore prices avg ~1.0–1.3×, per-seed 0.6–2.1×; items 1.0–1.7×.
- Player 6/day → 8–22% (mostly 10–15%); 13/day → 15–40% (mostly 22–25%).
- Independents ~8–22% per ore (~15% overall) — a bit low.
- Collective life 41–90% (too high), Firm physics 0–80% (seed/churn-dependent), Guild craft share 25–44% (<50%, **accepted for now** by human).

## Outstanding — look at next
1. **2 failing tests** (test_market): `mixed_recipe_shortage_lifts_both_ingredient_ores` (time doesn't rise from a healingBurst shortage — investigate; derived demand at conv 0.1 may be too small to move integer price, or something else supplies time) and `election_mutes_the_war_shield_effect` (shield price identical, integer item-stock rounding at normalStock 10). Re-pin or rework.
2. **REFERENCE.md** not updated: §1.8 (roster rule, maturing vein, Firm floor, rivalry divisor, placeholder tags), §3.13 pinned values (all market.json numbers above, war feel target **deferred to Ticker work** by human, dump window now "within 10% in 4 days"), §3.12/rivalry divisor. Also check CODEMAP factions.gd row mentions roster levels/ores.
3. **War → physics +50–100% feel target not met** (items too small vs ore volume; would need conv ~1.0–1.5). Human: defer to Ticker work — record as known gap.
4. **Faction cash polarises** (winners £40k–£300k, losers ~£20; Firm usually broke → can't buy ore → crafting stalls). Cash sinks are sub-spec 3/4a; flag in report.
5. Network ends at 0–2 veins in most seeds (rivalry snowball) — 4a.
6. Faction `startingHoldings`, `industryIncome`, trading knobs, craftTargets untouched — still placeholders in REFERENCE; decide whether they stay placeholders or get pinned.
7. Then: /code-review, final full suite + check_all, rename ticket `_COMPLETED`.
