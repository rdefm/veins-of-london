# 03 — Des sites quest: guaranteed finds

**What to build:** While the "Find ground for the Collective" objective is active, the player's 2nd prospect action finds a fate site and their 4th finds a physics site — each fair tier or better, unclaimed, in the district being prospected. Counting starts when the quest activates. Other prospects behave normally. The count lives in pure state so save/Rewind stay deterministic.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/sites.gd` (`prospect`, `_create_site`), `systems/collective.gd` (`report_des_site`, `_find_qualifying_des_site`, `maybe_trigger_weather_beat`), `systems/objectives.gd` (`site_matches_discovery_params`), `data/objectives.json` (`col_a1_des_sites`), `data/events/col_a1_prospecting.json`, `docs/REFERENCE.md` §2 (state schema)

**Status:** ready-for-agent

- [ ] Prospect count since quest activation tracked in state
- [ ] 2nd prospect → fate site, tier ≥ fair, unclaimed; 4th → physics site, tier ≥ fair, unclaimed
- [ ] A forced find is skipped if that ore type is already reported
- [ ] Defined behaviour when the district is at siteCap (ask human if unclear)
- [ ] Coexists with the Des weather beats
- [ ] Headless tests cover both forced finds and normal 1st/3rd prospects
