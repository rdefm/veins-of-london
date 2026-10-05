# 01 — Replace Pan's Prank with four Pan recipes

**What to build:** `pansPrank` is removed and replaced by Panic (fear, vice/compression), Panger (anger, pestle & mortar/grinding), Pandemonium (fury, Bunsen/heat) and Pan's Rapture (joy, distilling), each discovered via emotion calc on that lab approach. New ids; every reference to the old id updated. Items exist, craftable, sellable, but inert in combat until tickets 02/03.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/recipes.json`, `data/factions.json` (network `craftTargets`, `giftPrefs`, `raidKits`), `data/market.json`, `data/objectives.json` (starter craft objective), `assets/combat/icons/pansPrank.png`, `docs/REFERENCE.md` (recipe table ~line 82, faction tables), `docs/M3-CALC-DISCOVERY.md` (~line 434), `docs/calc-effects.txt`, `tests/test_col_a2_nadia_ledger.gd`, `tests/fixtures/gamedata_pre_manifest_snapshot.gdvar`. Old saves holding `pansPrank` inventory: decide migration (ask).

**Status:** ready-for-agent

- [ ] Four recipes with discovery cells; old id gone everywhere
- [ ] Faction/market/objective data re-pointed; sims still balanced
- [ ] Icon placeholders noted for human art
- [ ] PROSE-REVIEW: names + descriptions flagged
- [ ] Tests, check_all pass; CODEMAP/REFERENCE updated
