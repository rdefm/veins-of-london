# 09 — New-game veins in Soho, Hampstead and Notting Hill

**What to build:** Soho, Hampstead and Notting Hill have no `factionPresence`, so a new game starts with no veins there, and nothing appears until the player prospects. Give each of them 3–4 faction-held veins at new game, while no faction controls the district:

| District | Factions |
|---|---|
| Soho | Conclave, Firm |
| Hampstead | Network, Collective |
| Notting Hill | Conclave, Network |

Split each district's veins 2/1 or 2/2 between its two factions. Turf control needs a lead of `controlMargin` (2), so the district stays uncontrolled, with both factions holding a foothold. Ore type and site quality follow the district's `oreBias` and `siteQualityMod`, the same as prospecting. Which factions seed where, and how many, is data.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/factions.gd` (`seed_day_one_veins`), `systems/sites.gd` (`seed_faction_vein`, site creation, siteCap), `systems/turf.gd` (`seed_state`, `controller_of`, `district_entry`), `systems/debug_start.gd`, `data/districts.json` (`factionPresence`, `oreBias`, `siteQualityMod`, `siteCap`), `data/factions.json`, `data/constants.json` (`controlMargin`, `footholdShare`), `tests/test_factions.gd`, `tests/test_turf.gd`; REFERENCE.md §1.8 `data/factions.json`, §3.1a Turf.

**Status:** ready-for-agent

- [ ] New game: Soho, Hampstead, Notting Hill each hold 3–4 faction veins, owned by the factions listed above
- [ ] Each district's split stays within `controlMargin − 1`; after the first turf recompute, no faction controls these districts and both hold a foothold
- [ ] Ore types follow `oreBias`; quality follows `siteQualityMod`; `siteCap` not exceeded
- [ ] Seeding config is in data; REFERENCE.md documents it
- [ ] Debug start / other districts' seeding unchanged
- [ ] Headless test: counts, owners, no controller, foothold tiers for all three districts
