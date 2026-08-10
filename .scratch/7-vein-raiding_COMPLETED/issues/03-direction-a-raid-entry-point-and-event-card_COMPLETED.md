# 03 — Direction A: Raid entry point + first raid event card

**What to build:** The player-facing end of Direction A. Add a "Raid" action to the faction-vein site sheet (`scenes/screens/map.gd`'s `_build_faction_vein_content` — currently has a comment explicitly noting "no raid button (Chunk 6 isn't built yet)", which this ticket resolves) that, after the existing travel/time-block check (unchanged, no new travel mechanic), starts a raid event card/chain on the district event-card engine, built from ticket 02's ops: stealth check → clean success or caught-into-combat → claim/loot choice UI. Write **one representative raid event card** exercising this full path end-to-end (one faction/district/ore-type combination is enough) — this ticket is the tracer bullet proving the mechanism works, not a content pass. Per the PRD's own open question ("how many/which raid event cards get written first... left to the content pass"), further raid event cards for other factions/districts/circumstances are explicitly deferred to a later content pass, not part of this ticket.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] "Raid" button/action added to the faction-vein site sheet content, gated the same way other districted actions are (existing `Travel`/time-block rules)
- [ ] Starting a raid launches an event card/chain on the existing district event-card engine (reused content/choice/branching system, not a bespoke raid screen)
- [ ] One representative raid event card is authored, driving: stealth check (ticket 02) → clean success routes to claim/loot choice; caught routes into `Combat.start_raid` → win routes to claim/loot choice, loss fails the raid
- [ ] Claim/loot choice is presented to the player on a successful raid (clean stealth or won combat) and invokes ticket 02's claim/loot resolution ops
- [ ] PROSE-REVIEW flag on the new event card's new prose, per `docs/CONTENT-GUIDE.md`
- [ ] Tests cover: the event card's branch structure (stealth success path, caught→combat-win path, caught→combat-loss path) each reach the correct end state; the Raid action is unavailable/absent on sites with no `factionVein`
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes

Demoable end-to-end: travel to the district holding the authored raid's target vein, open its site sheet, tap Raid, play through the event, either sneak clean or fight the guards, then choose claim or loot and see the outcome (ownership/relation/payoff) reflected in state.
