# 15 — Physics lens: flat damage dealt/taken

**What to build:** Spec `.scratch/lenses/spec.md` "Sense L3": Physics. With a Physics lens + Sense >= combat gate, the player's damage dealt is +N and taken -N (`physicsFlatByTier`, placeholder `[0,1,2,3,4,5]`), applied after crit and anger scaling, before Shield; taken floored at 1. A contact with a Physics lens gets the same on its ally combatant (no Sense gate for contacts). Item damage (Blast, Black Hole, Heavy Metal): apply the dealt bonus to Strikes only unless the human says otherwise; flag it in the report.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/combat_rounds.gd`
- `systems/combat.gd`
- `systems/lenses.gd`
- `data/dial.json`
- `tests/test_combat_rounds.gd`
- `docs/REFERENCE.md` §3.7b Damage

**Acceptance:**
- [ ] Strike damage +N dealt / -N taken, floor 1, ordering per spec (tests incl. chip, crit, Shield).
- [ ] Contact Physics lens applies to that ally only.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
