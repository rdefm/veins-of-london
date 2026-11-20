# 13 — Combat: pre-roll enemy crits; Fate flags them

**What to build:** Spec `.scratch/lenses/spec.md` "Sense L3: combat sight": Fate. In every fight, an enemy Strike's crit is decided when its plan is rolled (stored on the planned action, pure data), not at resolution, lens or no lens, so a Fate lens never changes outcomes. Spilled actions (Stun/Pearl) keep the stored crit. With a Fate lens and Sense >= combat gate, a read critting intent is flagged on the intent strip; unread stays `?`. Rewind restores it. The RNG stream changes: update existing combat test/sim expectations deliberately, not silently.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/combat_rounds.gd`
- `systems/combat.gd`
- `scenes/components/combat_stage.gd`
- `scenes/screens/combat_rounds.gd`
- `tests/test_combat_rounds.gd`
- `docs/REFERENCE.md` §3.7b (Round, Damage, Fog)

**Acceptance:**
- [ ] Crit outcome identical with and without a Fate lens (test).
- [ ] Planned crit equals resolved crit; Be a Lady crit chance still applies (to the pre-roll).
- [ ] Flag only on read intents with lens + gate. Human QA: crit flag on strip.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
