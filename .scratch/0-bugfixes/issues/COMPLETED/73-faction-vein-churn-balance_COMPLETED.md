# 73 — Faction vein churn: stop factions disappearing off the map

**What to build:** Other factions currently lose veins too quickly and too often, to the point of vanishing from the map without player interference. There's an existing, never-actioned ticket (40) to remove the independent NPC-abandonment mechanic (a second, separate death roll stacked on top of the growth-collapse roll every vein already faces) — execute that first. Then, since removing abandonment means faction veins will die much less often, retune how often factions claim new veins and how their growth gets reset, so faction vein counts fluctuate around a rough steady state instead of trending sharply in either direction.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] NPC-abandonment (the independent daily chance that deletes a faction's site outright, separate from growth-collapse) is removed entirely. Faction veins now only die via the same growth-collapse-at-zero roll player veins already use.
- [ ] Daily-tick ordering and any documentation referencing NPC-abandonment is updated to reflect its removal.
- [ ] NPC-claim rate (how often factions pick up new veins) is retuned downward from its current level to roughly match the new, lower death rate (**needs balance sign-off** — propose specific revised numbers).
- [ ] The faction-vein growth prune-back mechanic (resets a faction vein's growth once it gets very high) is retuned as part of the same balance pass if needed to keep counts steady (**needs balance sign-off**).
- [ ] `docs/REFERENCE.md` updated with the removed mechanic and the new claim/prune-back numbers.
- [ ] Tests updated/removed for the deleted abandonment mechanic; new test confirms faction veins survive many days absent the abandonment roll and still die via collapse-at-zero.
- [ ] Manual check noted for the human: play many in-game days and confirm faction vein counts fluctuate rather than trending toward zero or toward unbounded growth.
