# 03 — Stockpile location

**What to build:** Each faction keeps its holdings at a stockpile: one district from its home districts (districts whose `factionPresence` is that faction) plus a place name from data, picked once per save with seeded Rng. It also records `revealedTo`, a list of observer ids, empty at start. Nothing reads it in-game yet; it's state for 4b's intel and raids. Old saves get a stockpile picked on load.

Spec: §Stockpile location, §State.

**Blocked by:** 01 — Faction holdings + real shops.

**Relevant files:**
- `data/factions.json` (stockpile place names per faction), `data/districts.json` (`factionPresence`)
- FactionSim or `systems/factions.gd` (pick helper), `autoload/GameState.gd`, `autoload/SaveManager.gd`, `autoload/Rng.gd`
- Tests: `tests/test_factions.gd`, SaveManager backfill tests
- REFERENCE.md §1.8, §6

**Status:** ready-for-agent

- [ ] New game: each faction has `stockpile {district, place, revealedTo: []}`, district from its home districts
- [ ] Pick is seeded and stable across save/load
- [ ] Old save backfills a stockpile
- [ ] PROSE-REVIEW: place names flagged
- [ ] REFERENCE.md + CODEMAP updated
