# 01 — Day-1 faction vein rosters

**What to build:** At new-game initialization, pre-populate each of the 5 factions with a starting roster of faction-claimed sites+veins (via the existing `factionVein`/site mechanism `docs/M1-LONDON.md` §D2's daily NPC-claim tick already uses), per the rosters in `spec.md`. The ongoing daily NPC-claim tick is untouched — this only changes what exists at the moment a new game starts.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] New-game init creates: Collective 8 veins (levels 1–3, fixed roll, 4/4 split Shoreditch/Whitechapel); Firm 4 veins (levels 2–3, fixed roll, 2/2 split Camden/Battersea); Guild 5 veins levels 2–3 + 2 veins level 4 in Greenwich; Network 4 veins levels 3–4 in King's Cross; Conclave 4 veins levels 2–4 + 3 veins level 5 in City.
- [ ] The specific level values for the non-exact rosters (Collective, Firm, Network) are hardcoded constants — identical across every new game, not re-rolled at runtime.
- [ ] District assignment beyond the even split (for Collective/Firm), location, oreType, security tier, and bonuses for every starting vein are generated using the existing site/vein procedural generation logic — verified to differ across repeated new-game starts (i.e., not accidentally also hardcoded).
- [ ] Every district that receives starting faction veins has its `siteCap` increased by exactly the count of starting faction veins placed there, so a fresh game's normal (non-faction) prospecting capacity in that district matches what it was before this ticket.
- [ ] `docs/REFERENCE.md`/`docs/M1-LONDON.md` updated to document this day-1 seeding step as canonical.
- [ ] Test coverage: a fresh `GameState` new-game init produces the correct per-faction vein counts and levels, and district `siteCap` values reflect the bump.
