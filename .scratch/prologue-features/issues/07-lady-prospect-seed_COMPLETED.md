# 07 — Be A Lady: prospecting + seeding

**What to build:** Be A Lady helps with anything that has luck in it. While Lady is active, a prospect's site-quality roll takes the best of two, and seed success chance gets +X per Lady level (placeholder, data). The odds/result UI shows the "(Lady)" tag as cultivating does. Des's prospecting/seeding lesson depends on this being true. Source: `docs/story-restructure.md` "Early Act 1 beats", "Features to build" item 4.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/sites.gd` (`prospect` L232, `seed_success_chance` L380), `systems/active_effects.gd` (`lady_active`, `lady_level`, `LADY_TAG`), `systems/cultivating.gd` (existing Lady pattern), `data/constants.json`, prospect/seed UI. REFERENCE prospecting/seeding sections, §3.7 "Active effects".

**Status:** ready-for-agent

- [ ] Under Lady, prospecting rolls site quality twice and keeps the better one. Without Lady it's unchanged.
- [ ] Under Lady, seed chance gets `+bonusPerLevel × level`, clamped by existing caps, with the value in data.
- [ ] The UI shows the Lady boost wherever prospect/seed odds or results are shown.
- [ ] Faction seeding (`seed_faction_vein`) is unaffected.
- [ ] REFERENCE is updated. Tests use seeded RNG for both paths.
