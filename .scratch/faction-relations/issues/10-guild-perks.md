# 10 — Guild perks

**What to build:** Friendly: a craft XP multiplier. Partner: the internship programme, giving free bonus cultivation actions and one bonus craft attempt per day on veins in Guild turf (quantities TBD). Sworn: high-margin commission-crafting offers through the existing offers/contracts path.

**Blocked by:** 07 — Perks core

**Relevant files:** `systems/perks.gd`, `data/faction_perks.json`, `systems/crafting.gd`, `systems/progression.gd`, `systems/cultivating.gd`, `systems/offers.gd`, `systems/contracts.gd`, `data/offers.json`, tests: crafting, cultivating, offers, `test_perks`. REFERENCE.md Perks §.

**Status:** ready-for-agent

- [ ] Craft XP multiplied while Friendly or above
- [ ] Internship: bonus cultivation actions (no block cost) and one bonus craft attempt per day for Guild-turf veins, reset daily
- [ ] Sworn: commission offers appear via the offers system with a Guild counterparty
- [ ] Tests through public crafting/cultivating/offer functions
