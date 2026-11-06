# 03 — Daily auto-sell pass

**What to build:** With someone in the Sales role (Archie once the business is unlocked), surplus stock of produced items sells by itself each morning, so the player earns passive income without hand-selling. This ticket makes the rule work end to end from state to the Morning report. The player-facing controls are ticket 04, so tests set the per-item rule directly.

Each recipe gets a rule: a `sellAbove` amount and a mood. The rollover sells stock above the protected floor while London's price meets the mood's minimum, up to the mood's daily limit.

**Rule**

- **Protected floor:** `max(sellAbove, Keep + contract need)`. Keep is the Production target. Contract need counts whenever the item covers contracts. Auto-sell never sells at or below this floor.
- **Mood values (user-approved, all in `data/market.json`):**

| Mood | Minimum London price | Max price drop from a day's on-market sales |
|---|---|---|
| Off (default) | never sells | — |
| Careful | 110% of base | 3% |
| Steady | 100% of base | 6% |
| Eager | 85% of base | 12% |

- **On-market daily limit:** the extra stock that would lower the price by the mood's percentage on the market curve, from today's stock: `stock × ((1 − drop)^(−1 / curveExponent) − 1)`, rounded down. With `curveExponent` 1.5 and stock 210, that's about 4, 9 and 19 units.
- **Payment:** London quote × quality multiplier per unit, lowest tier first. Archie takes no cut, and there's no mugging roll.
- **Off-market volume** is ticket 05.

**Also approved:** revenue goes wherever contract settlements go (business pot when active, else cash). Each day with at least one auto-sale awards the Sales role holder a small flat 2 Sales XP (data-driven; a completed contract gives 20). Auto-sales give no relation gain. Only recipes on the Production list are covered, not raw ore.

Add the rule to `docs/REFERENCE.md` in the same commit. It's a new human-approved mechanic and REFERENCE is canonical.

**Blocked by:** None — can start immediately.

**Relevant files:** new `systems/auto_sell.gd`, `systems/time_system.gd` (rollover around `ContractsSystem.process_daily_sales`), `systems/market.gd` (`quote`, `record_supply`, `_normal_stock`), `systems/rooms.gd` (`effective_lab_target`, `production_recipes`, `lab_covers_contracts`, `contract_need`), `systems/contracts.gd` (`has_staffed_sales`, `_shared_stock`), `systems/economy.gd` (`execute_sale`, quality multiplier), `systems/business.gd` (`receive`), `systems/morning_accounts.gd`, `data/market.json`, `autoload/GameState.gd`, `autoload/SaveManager.gd`, `CODEMAP.md`; REFERENCE §3.6 Selling, §3.13

**Status:** ready-for-agent

- [ ] State stays pure data, old saves load with every item Off, and new saves default to Off
- [ ] With no one in the Sales role, nothing sells
- [ ] Mood Off never sells
- [ ] Stock never falls to or below the protected floor, including when contract need raises it above `sellAbove`
- [ ] Below the mood's minimum price, nothing sells that day
- [ ] A day's on-market volume never exceeds the mood's limit or the surplus
- [ ] On-market sales go through the normal supply record, so the price responds
- [ ] Morning report shows item, quantity and income
- [ ] A day with auto-sales awards the small Sales XP once; a day without awards none
- [ ] All mood numbers come from data, not code
- [ ] `tests/test_auto_sell.gd` covers the above through state and the rollover
- [ ] REFERENCE and CODEMAP are updated
