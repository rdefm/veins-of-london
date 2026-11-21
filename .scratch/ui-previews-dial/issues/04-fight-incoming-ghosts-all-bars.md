# 04 — Fight: incoming attack ghosts on every bar

**What to build:** Every HP bar on the stage (player, allies, enemies) **always** shows ghost slices for the attacks it's due to take this round, from intents the player can actually see — enemies attacking the player or allies, allies attacking enemies. Hidden/unread intents (fog) produce no ghost; Glimpse and Emotion Lens target sight reveal what they normally reveal; furious/`targetUnread` actions ghost nothing. Ghosts from several attackers stack. When an action is armed (02), the projection reruns with it in place: arming Guard shrinks the player's incoming ghost to what Guard lets through; arming a stun removes the stunned combatant's ghosts; the armed attack's own ghost (03) adds on. Crit rule as in 03.

**Blocked by:** 03 — Fight: outgoing damage preview ghost

**Relevant files:**
- `systems/combat_rounds.gd` (`enemy_intents`, `guard_preview`, `_planned_guard`, `has_glimpse`, `has_sight`, AI ally plans, the 03 projection)
- `scenes/components/combat_stage.gd`
- `scenes/screens/combat_rounds.gd`
- `data/combat_visuals.json`
- REFERENCE §3.7b (fog, sight, Glimpse) + Table 5
- tests: `tests/test_combat_rounds.gd`

**Status:** ready-for-agent

- [ ] Nothing armed: visible incoming attacks ghost on every bar they hit, incl. ally → enemy
- [ ] Fogged/unread intents produce no ghost; Glimpse/Emotion sight cases tested
- [ ] Arming Guard visibly shrinks the player's ghost to the guarded amount
- [ ] Arming a stun/disable removes that combatant's outgoing ghosts
- [ ] Ghosts refresh after each beat/round and after Rewind
- [ ] Tests: projection with/without sight; armed-Guard delta
