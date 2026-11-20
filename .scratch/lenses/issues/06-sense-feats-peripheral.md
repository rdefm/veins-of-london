# 06 — Sense feats list lens unlocks; Peripheral sight (L5)

**What to build:** Spec `.scratch/lenses/spec.md` "Sense L4 / L5" and Sense gating. `data/skill_feats.json` Sense feats gain entries naming each lens unlock (L2 world sight, L3 combat sight, L4 Glimpse, L5 Peripheral sight), keeping the existing flat observation feats. Implement **Peripheral sight**: at Sense >= `senseGates.peripheral`, each owned-but-unloaded lens whose ore isn't loaded gives half its attunement bonus (through `Dial.attunement_bonus`); not its Fate all-rolls bonus, not world/combat sight. Player only. Feat strings PROSE-REVIEW.

**Blocked by:** 02

**Status:** ready-for-agent

**Relevant files:**
- `data/skill_feats.json`
- `systems/skill_tree.gd`
- `systems/dial.gd`
- `systems/lenses.gd`
- `tests/test_skill_tree.gd`
- `tests/test_lenses.gd`
- `docs/REFERENCE.md` §1.4

**Acceptance:**
- [ ] Skill tree projection lists the four lens feats at the right Sense levels.
- [ ] At L5 an unloaded owned lens gives half its tier's attunement; below L5 nothing; a loaded lens of the same ore wins (no stacking).
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
