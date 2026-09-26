# 10 — Owen's texts: full first-pass content

**What to build:** Fill ticket 09's text pool with:

- **8 cultivating-question texts:** each with 2–3 replies, one right answer granting XP, and Owen's reaction lines.
- **8 flavour texts:** humour, youth and naivety, humanising, with light tappable replies and no effect.

Flavour tone example from the human: *"Archie said we need to paint the gate on the vein at XYZ, and I should get some striped paint from B&Q. The guy said they're all out of striped paint, do you think plain white would be ok?"*

Use real-vein templating where it fits. Cultivating questions must be correct against REFERENCE.md cultivating/pruning rules (hold-at-target, prune vs cultivate, condition), so the "right" answer really is right. One dry line, no winking at the camera.

**Blocked by:** 09 — Owen's random texts: scheduler and reply choices.

**Relevant files:** the Owen text-pool data file created in ticket 09, `docs/CONTENT-GUIDE.md`, `CONTEXT.md` (terminology), REFERENCE.md §3.4 Cultivating & pruning, §3.10 "Cultivator (per block, hold-at-target)", `tests/test_messages.gd` (pool validates).

**Status:** ready-for-agent

- [ ] 8 cultivating texts plus 8 flavour texts, all passing the pool validator.
- [ ] Every cultivating question's correct answer matches REFERENCE.md mechanics.
- [ ] Vein-templated texts are marked so the scheduler skips them when Owen has no veins.
- [ ] The whole file is flagged `PROSE-REVIEW:` in the report.
