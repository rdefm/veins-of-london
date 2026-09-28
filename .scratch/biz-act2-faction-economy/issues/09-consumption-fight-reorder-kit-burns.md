# 09 — Consumption, fight reorder, kit burns

**What to build:** Factions use items. Weekly consumption per item (`consumes`) is drawn a seventh per day, scaled by the Ticker's `demandAll` / `itemDemand` multipliers. Raid kits (attack and defend contents, per faction in data) burn from holdings. Rivalry resolution and faction raid resolution move to right after NPC claims, so the day's fights run before FactionSim and their kits burn in the same day's consume step:

drift/collapse → NPC claims → rivalry → faction raids → tend/prune → craft → consume (incl. today's kit burns) → kit allocation → buy/sell → industry income → security upgrades.

Rivalry attempts burn the attacker's attack kit and the defender's defend kit. A faction raid on the player that resolves without a played fight — no alarm, left undefended/expired, or repelled by guards — burns the attacker's full attack kit. A raid the player defends in combat burns nothing here (ticket 16 handles it). Burns are capped by holdings; today's burns are listed in faction state; anything short becomes today's shortfall for buying.

Spec: §Consumption, §Rollover order, §State. Decision from ticketing: fights reordered ahead of FactionSim (rivalry now reads end-of-yesterday cash).

**Blocked by:** 08 — FactionSim: crafting toward target.

**Relevant files:**
- `systems/time_system.gd` (⑤g / ⑤h move), `systems/faction_sim.gd`, `systems/factions.gd` (`apply_rivalry_resolution`, `resolve_rivalry_outcome`)
- `systems/raiding.gd` (`apply_raid_resolution`, `_queue_defend_raid`, `leave_undefended`, `_expire_pending_defend_raids`, `_guards_repel_defend_raid`)
- `systems/barometer.gd` (`get_item_demand_mult`), `data/factions.json` (kits)
- Tests: `tests/test_faction_sim.gd`, `tests/test_factions.gd`, `tests/test_raiding.gd`, `tests/test_raid_alarms.gd`, `tests/test_time_system.gd`
- REFERENCE.md §3.1, §3.12, rivalry section, §1.8

**Status:** ready-for-agent

- [ ] Weekly consumption draws holdings down
- [ ] A Ticker item-demand effect raises consumption
- [ ] A rivalry attempt burns both kits
- [ ] An undefended / expired / guard-repelled raid burns the attacker's full attack kit; a defended raid burns nothing here
- [ ] Shortfall recorded when holdings can't cover
- [ ] Existing rivalry/raid tests still pass after reorder
- [ ] REFERENCE.md §3.1 step letters updated
