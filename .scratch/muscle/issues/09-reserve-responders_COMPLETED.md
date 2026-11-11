# 09 — Reserve responders

**What to build:** Reserve answers alarms. `claim_responders(place, block)` returns up to `reserveResponders` (2) available Reserve guards, highest level first. Each Reserve guard answers at most one alarm per time block (ledger in state, cleared each block). Priority: the fight the player defends, then HQ, then veins by value order (most valuable first). In a defend fight, claimed responders join at round 3 via the existing reinforcement queue. For an undefended or expired alarm, responders add their repel weight to that place's repel roll; a successful repel gives +5 XP to every guard whose weight counted (posted + responders). The Alarms list shows "Reserve: N responding" or "Reserve: none free" per row.

**Blocked by:** 08 — Player defend fights and injury.

**Relevant files:**
- `systems/muscle.gd` (`claim_responders`), `systems/raid_alarms.gd` (`summary_rows`, `defend`, `leave_undefended`), `systems/home.gd` (`_guards_repel_pending_raid`, `_expire_pending_raid`), `systems/raiding.gd` (`_guards_repel_defend_raid`)
- `systems/combat_rounds.gd` (reinforcement queue), `systems/combat.gd`
- `scenes/phone_apps/alarms_app.gd`, `scenes/components/alarm_presentation.gd`
- Tests: `tests/test_raid_alarms.gd`, `tests/test_combat_rounds.gd`, `tests/test_muscle.gd`, `tests/test_alarm_presentation.gd`
- REFERENCE.md §3.8; CONTEXT.md **Responder**

**Status:** ready-for-agent

- [ ] Max 2 responders, highest level first, injured/training excluded
- [ ] A guard never answers two alarms in the same block
- [ ] Priority order honoured; 3 alarms with 4 Reserve guards: defended fight 2, HQ 2, vein 0
- [ ] Responders enter the defend fight at round 3
- [ ] Undefended/expired alarm repel includes responder repel weight; success XP to all counted guards
- [ ] Alarms rows show the responder line
- [ ] On-device check listed: Alarms responder line, round-3 arrivals
