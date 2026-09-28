# 16 — Raider kits in defended raids

**What to build:** When a faction raids a player vein and the player defends it in combat, the raiders spawn carrying the attacking faction's attack kit (capped by its holdings). Enemies can use those items in combat (blast, shield, healing — whatever the kit holds) via new enemy item-use behaviour. After the fight, only the items the raiders actually used are deducted from the faction's holdings (and logged to its kit burns / shortfall for next day's buy). Undefended raids keep ticket 09's full-kit burn.

Decision from ticketing (not in the original spec).

**Blocked by:** 09 — Consumption, fight reorder, kit burns.

**Relevant files:**
- `systems/combat.gd` (enemy turn; item effects the player already uses: blast, shield, healing), `systems/raiding.gd` (`trigger_defend`, `resolve_defend_outcome`)
- `systems/faction_sim.gd`, `data/factions.json` (attack kit), `data/enemies.json`
- Tests: combat tests, `tests/test_raiding.gd`
- REFERENCE.md §3.12, combat section

**Status:** ready-for-agent

- [ ] Defended-raid enemies carry the attack kit, capped by holdings
- [ ] Enemies use kit items in combat
- [ ] Only used items deducted from faction holdings after the fight
- [ ] A defended raid does not also trigger ticket 09's full-kit burn
- [ ] PROSE-REVIEW: enemy item-use combat log lines
- [ ] Human on-device check listed in the report (enemy uses items in a defend fight)
