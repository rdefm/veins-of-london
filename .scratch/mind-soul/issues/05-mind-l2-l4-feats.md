# 05 — Mind L2/L4 feats

**What to build:**
- **Observation mod.** At Mind L2/L4, observation reads gain a labelled Mind mod in Σmods (+0.03 / +0.06). It shows with its label in the roll breakdown.
- **Crafting XP.** Player crafting XP gains ×1.10 / ×1.20, stacking multiplicatively with the Guild `craft_xp_mult`.
- **Data.** Values live in data as totals per level; L4 replaces L2.
- **Feats.** Feats are authored in the skill feats registry.

**Blocked by:** 01 — Bucket XP share (the Mind share is taken after this multiplier).

**Relevant files:**
- `systems/observation.gd` (Sense + kit mods)
- `systems/crafting.gd:175`
- `systems/perks.gd:339` (`craft_xp_mult`)
- `data/skill_feats.json`
- `data/constants.json`
- REFERENCE.md §3.9d, Mind section

**Status:** ready-for-agent

- [ ] Mind L1: no mod. L2: +0.03 labelled. L4: +0.06
- [ ] Crafting XP at Mind L2 ×1.10, L4 ×1.20; with Guild, both multiply
- [ ] Projected feat texts are correct at L2/L4
- [ ] PROSE-REVIEW: feat texts, mod label
