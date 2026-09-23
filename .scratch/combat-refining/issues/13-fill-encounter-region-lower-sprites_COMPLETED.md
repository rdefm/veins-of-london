# 13 — Fill encounter region and lower combatants

**What to build:** The animated combat scene reaches the white command surface, removing the exposed grey gap in the current view. Combatants sit lower within the taller scene while the turn-order strip remains at the top. The existing Dial, controls, departure board, target taps, and outcome flow remain usable. This follows up the completed two-region layout ticket and coordinates with the pending full-squad staging ticket.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/combat.gd` — upper-region, stage, footer, and detail-band sizing
- `scenes/components/combat_stage.gd` — stage size, backdrop extent, and combatant placement
- `scenes/components/combat_command_dock.gd` — command-surface top edge (read only unless needed)
- `tests/test_combat_screen.gd` — stage bounds, sprite targets, and stable Dial position
- `.scratch/combat-refining/spec.md` — composition and full-squad staging
- `docs/combat-animation-vision.md` — §2.2, §2.5

**Status:** ready-for-agent

- [ ] At the 390 × 844 logical portrait size, the stage fills the full width and reaches the command surface with no exposed grey band.
- [ ] Combatants stand visibly lower than in the current view; the turn-order strip and selected-card details do not cover them.
- [ ] One-enemy and full-squad scenes keep every living sprite visible and individually tappable, with no sprite or selection arrow clipped by the command surface.
- [ ] Dial size, hit regions, and command position stay fixed during selection, animation, and outcome changes.
- [ ] Backdrop fill or image covers the newly exposed stage area; stage effects and taps still use the complete stage bounds.
- [ ] Godot 4.7 syntax checks and the project test suite pass; human checks the scene on-device.

