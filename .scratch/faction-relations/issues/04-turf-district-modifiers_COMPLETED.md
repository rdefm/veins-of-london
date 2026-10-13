# 04 — Turf district modifiers

**What to build:** A district's effective danger and price modifiers shift with the player's relation to its controller: friendly ground is safer and better for business, hostile ground is the opposite. The shift is halved for Foothold factions. When the player controls a district, danger there drops and raid odds against player veins there fall. Every faction also gains a pressure term per player-controlled district. One query serves all existing `dangerMod`/`priceMod` readers.

**Blocked by:** 01 — Turf core

**Relevant files:** `systems/districts.gd`, `systems/economy.gd`, `systems/raiding.gd`, `systems/archie_deals.gd`, `scenes/modals/sell_menu_view.gd`, `autoload/GameData.gd` (dangerMod/priceMod readers), `systems/faction_ai.gd` (`factionPressure.weights`), turf config in data (relation-band table, TBD), `tests/test_turf.gd`, `tests/test_raiding.gd`, `tests/test_faction_ai.gd`. REFERENCE.md Turf §, §1.11.

**Status:** ready-for-agent

- [ ] One effective-modifier query = district base + controller-relation adjustment per relation band; halved at foothold
- [ ] Every existing reader of `dangerMod`/`priceMod` goes through the query (grep shows no direct reads left)
- [ ] Player control: danger reduction and a raid-odds penalty against player veins there (TBD values in data)
- [ ] New pressure weight per player-controlled district, applied for every faction
- [ ] Tests for friendly/hostile/foothold/player-controlled cases
