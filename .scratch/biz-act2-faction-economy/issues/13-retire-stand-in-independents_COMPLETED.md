# 13 — Retire stand-in supply; civilian demand; Independents slice

**What to build:** Market supply becomes real: recorded player and faction activity plus an Independents slice. `standInSupply` is removed. Stand-in demand is renamed civilian demand (permanent, still Ticker-scaled for items). One knob `independentsShare` sets the fraction of London volume that is steady independent supply, balanced by matching civilian demand, and credits the `independents` producer in Shares. At 0, the slice and the Independents row vanish. `normalStock` and the dump threshold get placeholder retunes (final pinning in 17).

Spec: §Independents slice, §Module layout (Market), Further Notes.

**Blocked by:** 11 — Faction buying/selling + real cash; 04 — Shares core.

**Relevant files:**
- `systems/market.gd` (`_stand_in`, `daily_reprice`, `resting_stock`, `_annotate_day`), `data/market.json`
- `systems/shares.gd`, `scenes/phone_apps/ticker_app.gd` (demand-driver labels)
- Tests: `tests/test_market.gd`, `tests/test_shares.gd`
- REFERENCE.md §3.13

**Carried from ticket 11 (faction trading isolation in market tests):** `tests/test_market.gd`'s `_tick()` temporarily sets every faction's `trading.sellFraction` and `trading.maxBuyMult` to 0 so its rollover cases pin Market maths against stand-in London only. Faction London trades now move prices in the real rollover, which broke three idle-market tests (`no_player_sales_drifts_to_the_idle_premium_and_holds`, `war_lifts_shield_then_physics_ore_over_following_days`, `demand_all_lifts_and_lowers_every_item`). Once stand-in supply is retired, revisit this: decide whether market tests should run with faction trading on (London's real supply) and re-pin their expected idle prices, or keep the switch-off and say why.

**Status:** ready-for-agent

- [x] No `standInSupply` in code or data; civilian demand named as such
- [x] `independentsShare` 0 removes slice and row
- [x] Above 0, shares across all producers sum to 100%
- [x] Idle London prices stay sane over a seeded multi-day run
- [x] Faction-trading switch-off in `test_market.gd` `_tick()` revisited (removed, or kept with reason)
- [x] REFERENCE.md + CODEMAP updated

**Resolution notes:** Independents supply = `independentsShare` × `civilianDemand` per good (human decision 2026-09-28). Placeholders: share 0.9, ore normalStock 300, items normalStock 40 / civilianDemand 20 (at 20/10, whole-unit rounding pinned items at 19-20 and swallowed Ticker effects), `oreConversionRate` 0.75 (keeps derived ore demand per proportional item shortage as before). `_tick()` faction-trading switch-off kept, reason in its comment; real-London sanity covered by `idle_london_stays_sane_with_factions_trading`.
