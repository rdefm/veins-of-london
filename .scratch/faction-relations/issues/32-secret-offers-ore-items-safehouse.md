# 32 — Secret offers: ore/items and safehouse-tip prizes

**What to build:** Extends 31's secret offers with two more prize kinds, chosen per member in data: ore/items taken from the faction's holdings to the player, or a safehouse tip that reveals a faction stockpile so the player can raid it (existing stockpile raid). If the faction lacks the chosen asset, the offer falls back to the next kind.

**Blocked by:** 31 — Secret offers rework.

**Relevant files:** `systems/key_members.gd`, `systems/faction_sim.gd` (holdings), `systems/raiding.gd` (stockpile raid), `systems/intel.gd`, `systems/map_pins.gd` (raidable stockpile pins), `data/factions.json`, `data/events/inc_defection.json`, `tests/test_key_members.gd`, `CODEMAP.md`. REFERENCE.md key members § "Defection", stockpile raid §.

**Status:** ready-for-agent

- [ ] Per-member data selects vein, ore/items or safehouse tip
- [ ] Ore/items move from faction holdings to the player
- [ ] Safehouse tip reveals a stockpile and makes it raidable via the existing raid flow
- [ ] Missing asset falls back to the next kind; nothing granted only if all are unavailable
- [ ] Tests, REFERENCE and CODEMAP updated
