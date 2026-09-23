# 17 — Apply street-sign art to combatant cards

**What to build:** Combatant cards use the approved reusable sign frame from ticket 16 while retaining live text, faction-coloured health bars, selected details, and damage states. The frame scales cleanly across collapsed and selected cards, and the cards remain legible and tappable throughout combat.

**Blocked by:** 16 — Produce reusable street-sign card art.

**Relevant files:**
- `scenes/components/turn_order_strip.gd` — card frame, content, selection, and damage overlays
- `data/combat_visuals.json` or established theme data — asset reference if configuration is needed
- `assets/combat/` — approved frame asset
- `tests/test_turn_order_strip.gd`, `tests/test_combat_screen.gd` — card content and interaction regression checks
- `.scratch/combat-refining/spec.md` — street-sign card requirements
- `docs/ui-vision.md` — §5 combat UI family, §6 colour rules, §7 typography

**Status:** ready-for-agent

- [ ] Collapsed and selected cards use the approved sign frame without distorted corners or borders.
- [ ] Names, levels, health bars, faction information, exact HP, statuses, and intent remain readable in their applicable states; none are baked into artwork.
- [ ] Existing faction colour mapping and damage thresholds remain unchanged; damage cues do not cover live information.
- [ ] Card and sprite selection, scrolling, repeated occurrences, and touch targets still work.
- [ ] Godot 4.7 syntax checks and the project test suite pass; human confirms the sign treatment on-device.

