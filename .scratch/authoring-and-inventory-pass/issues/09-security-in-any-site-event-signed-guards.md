# 09 — Security in any site event, plus signed guards

**What to build:** Any event with a site in context can use security features. If it has no `securityProfile`, the game builds one from the site's vein, for faction and player veins alike. A site with no vein reads as no security. Security conditions read the guard count after this event's adjustments. Guard adjustment becomes signed and event-scoped: positive adds, negative removes, through the existing event context count, never editing the vein. Existing `reduce_raid_guards` uses keep their behaviour.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/events.gd`, `systems/raiding.gd`, `systems/cultivating.gd`, `autoload/GameData.gd`, `tests/test_events.gd`, `tests/test_raiding.gd`, REFERENCE.md §3.9a Event choice checks, REFERENCE.md §3.12 Security profile, event action list

**Status:** ready-for-agent

- [ ] Security conditions work on faction veins, player veins and sites with no vein
- [ ] Conditions see the guard count after event adjustments
- [ ] Positive and negative guard changes work, and the vein's real guards are unchanged afterwards
- [ ] `reduce_raid_guards` content behaves as before
- [ ] REFERENCE.md is updated
