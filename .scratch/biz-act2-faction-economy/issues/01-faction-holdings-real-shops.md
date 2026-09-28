# 01 — Faction holdings + real shops (all five lanes)

**What to build:** Every faction gets real holdings — ore per type, items per recipe per quality tier — and every faction's shop sells exactly what it holds. The Collective's random ore restock is gone. Trade lanes exist for all five factions (Firm, Network and Conclave gain lanes beside Guild and Collective; relation spreads still apply; pricing unchanged: London quote ± relation spread). Buying from a faction draws down its holdings, ore and items alike; bought items arrive at the tier held, highest tier first. Selling to a faction adds the goods to its holdings (items at their tier) and pays out of the faction's `resources` (its £ wallet), which never goes below £0 — a sale the faction can't fully afford is scaled down or refused. The Collective questline buy lane and the business's per-contract calc buys keep working against holdings. The old `oreStock` migrates into holdings; old saves backfill holdings at sensible starting stock (placeholder: roughly a week of each faction's `consumes` plus some primary/secondary ore). Faction cash on old saves is unchanged.

Spec: `.scratch/biz-act2-faction-economy/spec.md` §Faction shops, §Faction cash, §State, §Sim start (holdings exist and shops read them from day 1 regardless of `simStart`).

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/economy.gd` (faction lanes: `get_faction_buy_max_qty`, `execute_faction_purchase`, `receive_faction_ore`, `execute_faction_sale`, `can_buy_from_faction`)
- `systems/factions.gd` (`restock_ore` / `maybe_restock_ore` removed), `systems/time_system.gd` (⑤j removed)
- `systems/contracts.gd` (~line 383, calc buys via `get_faction_buy_max_qty`), `systems/collective.gd`
- `systems/crafting.gd` (`inventory_add` tiers)
- `data/faction_trade.json`, `data/factions.json`
- `autoload/GameState.gd` (new-game faction state), `autoload/SaveManager.gd` (migrate `oreStock`, backfill)
- `scenes/modals/sell_menu_view.gd`, `scenes/screens/guild_marketplace.gd` (read-only callers)
- Tests: `tests/test_economy.gd`, `tests/test_ore_stock.gd`, `tests/test_collective.gd`, `tests/test_contracts.gd`, `tests/test_guild_marketplace_screen.gd`, SaveManager backfill tests
- REFERENCE.md §1.8 `data/factions.json`, §3.6 Selling, §6 SAVE FORMAT; CODEMAP rows for economy / factions / faction_trade.json

**Status:** ready-for-agent

- [ ] Each faction's state holds `holdings` (ore per type; items per recipe per tier); `oreStock` no longer exists
- [ ] A faction shop buy draws down that faction's holdings for ore and items, all five factions; can't buy more than held
- [ ] Bought items land in the player's inventory at the held tier, highest first
- [ ] A player sale to a faction shop adds to its holdings and costs its `resources`; `resources` never negative
- [ ] Trade lanes configured for all five factions; relation spreads still apply
- [ ] Random ore restock removed from code and the daily tick
- [ ] Collective questline buy lane still completes; business calc buys still work
- [ ] Old save migrates `oreStock` into holdings and backfills the rest; save/load round-trips holdings
- [ ] REFERENCE.md + CODEMAP updated
