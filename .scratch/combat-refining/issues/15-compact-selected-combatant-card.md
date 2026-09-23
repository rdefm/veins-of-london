# 15 — Keep selected combatant card compact

**What to build:** Selecting a combatant enlarges its turn-order card only enough to show the extra details required for that combatant. It remains clearly selected without dominating the upper scene or moving the Dial. This refines the completed tap-selection ticket.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/turn_order_strip.gd` — focused-card width, height, content wrapping, and reserved band
- `scenes/screens/combat.gd` — strip overlay and fixed region geometry
- `tests/test_turn_order_strip.gd`, `tests/test_combat_screen.gd` — detail visibility, bounds, and stable controls
- `.scratch/combat-refining/spec.md` — selected-card requirements and mockup caveats
- `docs/combat-animation-vision.md` — §2.4 Turn-order cards

**Status:** ready-for-agent

- [ ] Selected cards remain slightly larger than unselected cards and reveal exact HP, statuses, and enemy intent when applicable.
- [ ] Focused width and height use only the space needed for visible detail; the current oversized expansion is removed without truncating canonical names or essential detail.
- [ ] Cards stay inside the reserved upper-region allowance; selecting among short and long content never moves the scene or Dial.
- [ ] Repeated occurrences of the selected combatant share the same selection treatment; scrolling and card/sprite taps still select correctly.
- [ ] Godot 4.7 syntax checks and the project test suite pass; human compares selected-card proportions against the mockup on-device.

