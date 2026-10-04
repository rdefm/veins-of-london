# 06 — Combat: HP and KO in sync with hits

**What to build:** In combat, a combatant's HP bar drops at the moment the hit that caused it plays — not in a lump right after the player's turn that also includes damage from later turns (e.g. Archie's follow-up in the next round). The KO animation plays only when the final blow lands on that combatant.

**Blocked by:** None — can start immediately

**Relevant files:** `scenes/screens/combat.gd` (band sync, turn flow), `scenes/components/combat_director.gd` (beat queue playback), `scenes/components/combat_stage.gd` (`play_ko`, hit/shake), `scenes/components/turn_order_strip.gd`, `systems/combat.gd` (`turnCursor`, `prime_`/`conclude_decision_point`, `project_queue`), `docs/REFERENCE.md` §3.7a

**Status:** ready-for-agent

- [ ] Each beat carries its target's HP-after value; bar animates on that beat
- [ ] No bar reflects damage from a beat that hasn't played
- [ ] KO plays on the killing beat only
- [ ] Headless test on beat data proving per-beat HP values; human checks visuals
