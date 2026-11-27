# 16 — Sense L4: Glimpse

**What to build:** Spec `.scratch/lenses/spec.md` "Sense L4 / L5": Glimpse. Once per event and once per fight, free, at Sense >= glimpse gate with at least one lens loaded. Event: from the Action menu, re-roll one already-read observation ore that matches a loaded lens (keep the better level, like the Rewind re-roll in R§3.9d; tier effects only for newly reached tiers). Combat: at a player pause, reveal one enemy's full plan this round (Prophet's Breath sight, one enemy, this round). Used flag in `state.event` / `state.combat` (pure data; Rewind restores). Strings PROSE-REVIEW.

**Blocked by:** 01, 14

**Status:** ready-for-agent

**Relevant files:**
- `systems/observation.gd`
- `systems/events.gd`
- `systems/event_items.gd`
- `systems/combat_rounds.gd`
- `systems/lenses.gd`
- `scenes/screens/event.gd`
- `scenes/components/combat_command_dock.gd`
- `tests/test_observation.gd`
- `tests/test_combat_rounds.gd`
- `docs/REFERENCE.md` §3.9d, §3.7b Fog

**Acceptance:**
- [ ] One use per event/fight; refused below gate, without a matching lens, or already used.
- [ ] Event re-roll keeps the better level; combat reveal reads that enemy's whole plan.
- [ ] Rewind before use restores availability. Human QA: Action menu entry + combat command row.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
