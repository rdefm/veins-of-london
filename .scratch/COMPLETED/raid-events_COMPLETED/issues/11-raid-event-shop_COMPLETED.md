# 11 — The Shop: build as a stage tree with placeholder prose

**What to build:** The Shop raid event (event id `raid_shop`) from the approved proposal (§5), built as data: a late-opening shopfront with the vein in the cellar. Three routes (customer, yard door, pavement cellar flap) diverge after the perimeter and meet at the vein room, plus the shared cards. Staff and passers-by are witnesses, not fighters: their windows offer talk, duck or run, never a fight. The till camera always sits on the customer route when the site has cameras. Panic's cover base is 0.35. The reinforcement clock runs at 2 cards. Includes observations with security-profile text variants, observation gates, item effects (rolled and no-roll), alert raises and cover rolls, the ward on the cellar stairs, Back out / Run for it, and per-route calibration from §1.4. Cards link by key. All prose is placeholder. Off-licence, Tesco Metro and bookies veins raid as this event (09).

**Blocked by:** 08 — Proposal (approved); 09 — Raid event by location; 13 — Card links by key; 14 — Fight presets; 15 — Item options without a roll; 16 — Raid alert level; 17 — Cover roll on alert; 18 — Mid-raid guard bookkeeping; 20 — Site security profile; 21 — Wards; 22 — Item tier scaling; 23 — Reinforcement clock; 24 — siteWary; 25 — Observation text variants.

**Relevant files:** `.scratch/raid-events/raid-variants-proposal.md` §1–2, §5, `data/events/vein_raid.json` (pattern, after 19 if done), `data/events/raid_shop.json` (new), suffix map from 09, `tests/test_raiding.gd`, `tests/test_event_content_lint.gd`, `CODEMAP.md`, REFERENCE.md §3.9a Event choice checks, §3.9d Observation, §3.7b Open/Guarded round combat, §3.12 Vein raiding.

**Status:** ready-for-agent

- [ ] Event matches proposal §5: routes, cards, gates, item effects, alert rules, witness windows, 2-card clock
- [ ] Shop-suffix veins start it; content lint passes; all links are key links
- [ ] Tests (seeded): each gated choice locked/unlocked as designed; each route reaches claim/loot on a clean run; witness windows offer no fight; the clock fires after 2 cards; an alert raise changes later odds/options; a mid-raid fight win continues with fewer guards
- [ ] CODEMAP updated for the new data file
- [ ] Human on-device check: play the event via debug start through each route, clean and noisy
