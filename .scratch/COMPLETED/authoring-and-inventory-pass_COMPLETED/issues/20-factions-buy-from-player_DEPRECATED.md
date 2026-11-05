# 20 — Factions buy from the player

**What to build:** Once the player owns the base recipe rung, Root Feed joins other factions' demand in sell lanes and sales offers. Stock comes from the shared pool only and enters the faction's real holdings. These factions get no `consumes` entry for it, so nothing is burned abstractly.

**Blocked by:** 18

**Relevant files:** `systems/offers.gd`, `systems/overlaps.gd`, `systems/faction_ai.gd`, `systems/recipe_knowledge.gd`, `systems/faction_sim.gd`, `scenes/modals/sell_menu_view.gd`, `data/factions.json`, `tests/test_faction_sim.gd`, REFERENCE.md §1.8 `data/factions.json`

**Status:** wontfix

- [ ] No Root Feed demand appears before the base rung is owned
- [ ] Sold feed enters real holdings and factions then use it
- [ ] Stashed feed cannot be sold
- [ ] Factions at war with the player follow existing sale rules
- [ ] The Collective is not a buyer
- [ ] No new `consumes` entries are added

## Comments

Replaced by `.scratch/london-market/issues/06-root-feed-offers.md`. Differences: sell lanes stay ungated, and the Collective may buy like any other faction.
