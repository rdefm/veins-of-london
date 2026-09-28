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

## Implementation plan (discovery done 2026-09-28 — skip re-discovery)

Nothing implemented yet. Placeholder kit values await human OK (flag in report).

### Data — `data/factions.json`
Add per faction after `consumes` (placeholders, sized off `craftTargets.kitUse`):
- collective: `"raidKits": { "attack": { "healingSalve": 1 }, "defend": { "healingSalve": 1 } }`
- firm: `{ "attack": { "blast": 2, "healingBurst": 1 }, "defend": { "shield": 2, "healingBurst": 1 } }`
- guild: `{ "attack": {}, "defend": {} }`
- network: `{ "attack": { "pansPrank": 1 }, "defend": {} }`
- conclave: `{ "attack": {}, "defend": { "failsafe": 1 } }`

### State (pure data), per faction
- `kitBurns`: `[{ day, source: "rivalry"|"raid", kit: "attack"|"defend", items: {recipeKey: qty} }]`. Burns logged since the last consume; fights append, `FactionSim.consume()` applies then clears. Mid-day `leave_undefended` burns wait for the next rollover. Ticket 16 appends here too.
- `shortfall`: `{recipeKey: qty}`, overwritten each consume. Ticket 11 buys from it.
- `consumeAccrued`: `{recipeKey: float}`, the fractional carry so the weekly ÷ 7 draws sum exactly.
- Add to `autoload/GameState.gd` faction dict (~l.411, next to holdings/stockpile) and backfill in `autoload/SaveManager.gd` `_migrate_faction_holdings` (~l.186). `backfill_defaults` does NOT deep-fill faction keys.

### `systems/faction_sim.gd`, new section "Consumption and kit burns (spec §Consumption)"
- `log_kit_burn(faction_id, kit, source)`: reads `GameData.FACTIONS[id].raidKits[kit]`, skips if empty, appends an entry (world.day, duplicated items).
- `consume()`, per faction:
  1. each `consumes` item: `owed = accrued + weekly * Barometer.get_item_demand_mult(recipe) / 7.0`; `draw = floori(owed + 1e-9)`; `accrued = owed - draw`; `need += draw`.
  2. add all `kitBurns` items to `need`; clear `kitBurns`.
  3. `take_items()` (already caps, highest tier first); `shortfall = want - taken` if > 0.

### Burn hooks
- `systems/factions.gd` `apply_rivalry_resolution()` (~l.366): every attempt, success or fail, logs attacker "attack" + defender "defend" (source "rivalry").
- `systems/raiding.gd`:
  - `apply_raid_resolution()` (~l.445): every attempt NOT queued via `_queue_defend_raid` (failed attempts + no-alarm resolves) logs attacker "attack".
  - `_expire_pending_defend_raids()` (~l.534), `leave_undefended()` (~l.628): log attacker "attack" per outcome, guards repel or not.
  - `trigger_defend` / `maybe_trigger_defend` / `resolve_defend_outcome`: no burn (ticket 16).

### Rollover — `systems/time_system.gd` `daily_tick()` (~l.91–98)
```
Sites.roll_npc_claims()              # ⑤b
Factions.apply_rivalry_resolution()  # ⑤c (reads end-of-yesterday cash)
Raiding.apply_raid_resolution()      # ⑤d
MorningAccountsSystem.capture_losses(morning_context, "Raid")
FactionSim.tend_and_prune()          # ⑤e
FactionSim.craft()                   # ⑤f
FactionSim.consume()                 # ⑤g incl. today's kit burns
Factions.apply_passive_income()      # ⑤h (kit alloc = t10, buy/sell = t11 go before this)
NetworkHandler.expire_intel()        # ⑤i before security (security_freeze)
Factions.apply_security_upgrades()   # ⑤j
```
The existing Collective/BusinessQuest ⑤i triggers become ⑤k… after. Inline comments must state the real dependencies.

### Docs
- REFERENCE.md: rewrite the §3.1 daily_tick line (~l.534) and fix the step refs at ~l.238 (⑤b), ~l.242 (⑤c), ~l.254 (⑤c2) and the "Faction tend + prune" bullet (~l.537).
- REFERENCE.md: add a §1.8 `raidKits` + consumption paragraph and a kit-burn note in the raiding/rivalry section.
- CODEMAP faction_sim row: add consumption + kit burns (<400 chars).

### Tests — `tests/test_faction_sim.gd` (helpers `_set_item`, `_stock_at_targets` exist)
- Firm blast 3/wk: 7 × `consume()` draws exactly 3.
- `barometer.political = "war"` (blast itemDemand +0.6): 7 days draws 4.
- A rivalry attempt logs both kits; consume drops holdings.
- Raid no-alarm / expired / leave_undefended / guard-repel each log the attack kit; `trigger_defend` logs none (fixtures in `test_raiding.gd`, `test_raid_alarms.gd`).
- Holdings 0 + logged burn: shortfall = kit qty.
- An old save without the 3 keys backfills defaults.
- Re-run `test_factions`, `test_raiding`, `test_raid_alarms`, `test_time_system` after the reorder.
