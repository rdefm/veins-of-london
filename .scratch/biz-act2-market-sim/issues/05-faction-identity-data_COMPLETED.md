# 05 — Faction economic identity data

**What to build:** Each faction gains its economic identity in data: `archetype`, `primaryOre`, `secondaryOre`, `crafts` (recipe keys), `consumes` (recipe key → base weekly qty, placeholder). No mechanic uses it yet beyond read helpers; 06 uses it for counterparty weighting, sub-spec 2 for FactionSim. Draft table (spec §Faction identity data):

| Faction | Archetype | Ore (primary / secondary) | Crafts | Consumes |
|---|---|---|---|---|
| Collective | producer | life / emotion | healingSalve, enhancementPowder | healingSalve |
| Firm | producer | physics / life | blast, shield, healingBurst | blast, shield, healingBurst, enhancementPowder |
| Guild | crafter | time / physics | timePearl, rewind, wormhole, prophetsBreath, rejuvenation | little |
| Network | information broker | emotion / fate | pansPrank | prophetsBreath |
| Conclave | manipulator | fate / time | failsafe | failsafe, rejuvenation |

"little" = small placeholder quantities; pin them. Stances and pressure are out of scope.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `data/factions.json`, `systems/factions.gd` (read helpers: factions crafting with an ore, factions consuming an item)
- `data/recipes.json` (validate referenced recipe keys exist)
- Faction tests (data validation)
- `docs/REFERENCE.md` §1.8 `data/factions.json`

**Status:** ready-for-agent

- [ ] All five factions carry the identity fields; every referenced recipe key exists
- [ ] Read helpers return factions crafting with a given ore and consuming a given item
- [ ] REFERENCE.md §1.8 updated
