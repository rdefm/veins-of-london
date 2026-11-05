# 06 — Root Feed offers

**What to build:** Once the player owns the base Root Feed rung, sales offers for it appear, weighted towards factions that want it. The "which factions consume this" read now includes wanting factions, so offers and overlaps both see them. Sell lanes stay ungated. Feed sold to a faction enters its real holdings and gets used on its veins.

Replaces authoring-and-inventory-pass ticket 20.

Spec: `.scratch/london-market/spec.md`, "Root Feed", delivery step 5. Stories 80-83.

**Blocked by:** 05

**Relevant files:** `systems/factions.gd`, `systems/offers.gd`, `systems/overlaps.gd`, `systems/recipe_knowledge.gd`, `systems/faction_sim.gd`, `tests/test_offers.gd`, `tests/test_faction_sim.gd`, REFERENCE.md §1.8 `data/factions.json`

**Status:** ready-for-agent

- [ ] No Root Feed offers appear before the base rung is owned
- [ ] Offers appear after the base rung, weighted by faction want
- [ ] Overlaps treat wanting factions as consumers of Root Feed
- [ ] Sell lanes accept Root Feed with no rung gate
- [ ] Feed sold to a faction reaches its holdings and is applied to its veins
- [ ] Existing `consumes` reads for other goods are unchanged
- [ ] REFERENCE.md is updated
