# 03 — Cold open post-rewind: pearl throw + Nick frozen

**What to build:** After the Rewind, the player sees Archie play the time pearl (a throw/use cue on stage, plus a transcript line), and Nick visibly frozen/slowed (freeze state/badge on his slot) until the fight resolves into the escape.

**Blocked by:** 02 — Scripted Rewind plays backwards fast.

**Relevant files:** `data/events/cold_open.json` (`post.allyPlans` timePearl slot 0), `scenes/components/combat_stage.gd` (keypose one-shots, freeze/status badges), `scenes/screens/combat_rounds.gd` (`_play_cue`), `systems/combat_rounds.gd` (item play beats), `systems/combat.gd`; REFERENCE.md §3.7b Items.

**Status:** ready-for-agent

- [ ] Archie's post-Rewind timePearl play shows a visible use/throw cue on stage
- [ ] Nick's slot shows a freeze state after the pearl lands, and it stays until the fight ends
- [ ] The transcript line says what the pearl did
- [ ] Headless test: the pearl beat fires from Archie's slot 0 and Nick carries the frozen status afterwards
