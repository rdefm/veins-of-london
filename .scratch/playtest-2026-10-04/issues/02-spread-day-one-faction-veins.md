# 02 — Spread the factions' starting veins thinner

**What to build:** A new game seeds the same total number of faction day-one veins as today, but distributed across more districts (including the new west/SW ones), so each district has fewer established veins and more room for new sites. Faction territory should still read plausibly (e.g. the Firm's "South and West London" description).

**Blocked by:** 01 — Add districts in the west and southwest

**Relevant files:** `systems/factions.gd` (`DAY_ONE_ROSTER`, `seed_day_one_veins`, `_seed_day_one_vein`), `data/districts.json` (siteCap — roster comment says district counts match its siteCap bump), `data/vein_growth.json` (dayOneFaction*), `data/factions.json`, `docs/REFERENCE.md` §1.8 "Day-one roster", day-one seeding tests under `tests/`

**Status:** ready-for-agent

- [ ] Total and per-faction day-one vein counts unchanged
- [ ] No district holds more day-one veins than before; veins spread over more districts
- [ ] siteCap values stay consistent with the roster rule, leaving unclaimed room in every district
- [ ] REFERENCE.md §1.8 updated; tests updated and passing
