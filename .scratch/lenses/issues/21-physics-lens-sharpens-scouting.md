# 21 — Physics lens sharpens scouting

**What to build:** A Physics lens is now the scouting lens. It follows the standard lens pattern:
- **Gate:** a Physics lens loaded in the Dial plus Sense ≥ L2 (world sight).
- **Effect:** every scout fact chance rises by a bonus set by the **lens tier**. Placeholder `physicsScoutBonusByTier` `[0, 0.05, 0.10, 0.15, 0.20, 0.25]`, in the dial data beside the other `...ByTier` curves.
- **Cap:** chances are capped at 100%.
- **Scope:** applies to both manual scouts and weekly scouts.
- **Text:** the Physics lens world-effect text in the Dial and Lens Details is rewritten to describe this.

**Blocked by:** 19, 20

**Relevant files:**
- `systems/lenses.gd`: `tier_for`, `sense_unlocked`; follow the `physics_flat` / `life_prospect_shift` shape
- `systems/intel.gd`: the scout roll
- `data/dial.json`: new tier curve, `effects.physics.world`
- `tests/test_intel.gd`, `tests/test_lenses.gd` (if present)
- `.scratch/lenses/spec.md`: Physics row, "Physics — security read"
- REFERENCE.md §1.4 Lenses

**Status:** ready-for-agent

- [ ] No bonus without a loaded Physics lens, or below Sense L2.
- [ ] Bonus equals the curve value at the loaded Physics lens's tier. Chances are capped at 100%.
- [ ] Applies to manual and weekly scouts alike.
- [ ] Human QA: Dial / Lens Details Physics text. PROSE-REVIEW: `effects.physics.world`.
- [ ] Syntax check clean, tests pass, REFERENCE/spec updated.
