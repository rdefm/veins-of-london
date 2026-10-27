# 07 — Profile skill wheel

**What to build:** Replace the Profile app's skills section with a Body/Mind/Soul wheel:
- A circle split into 3 segments, each a different colour from the ui-vision palette, showing the bucket name (Body, Mind, Soul) and its level.
- Initial state: Body segment at the bottom, details collapsed.
- Tapping a segment plays an animation that rotates the circle so that segment sits at the bottom, then a section animates open underneath with details: each sub-skill's name, level, XP (progress to next), and bonuses/feats unlocked (and upcoming) at levels.
- Tapping the already-selected segment collapses the details.
- Reads only the projection from ticket 06; no state mutation, no logic in the screen.
- Gym's Combat (now Body) card unchanged.

**Blocked by:** 06 — Skills restructure: Body / Mind / Soul + feats registry.

**Relevant files:** `scenes/phone_apps/profile_app.gd` (`_build_skills_card()`, `_add_skill_row`), `scenes/components/move_book.gd` (existing move rows/tracks — reuse look for Body sub-skills where sensible), new component under `scenes/components/` (e.g. skill wheel), `docs/ui-vision.md` (palette, visual family, typography), `data/` UI strings file if labels are data-driven, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Wheel renders 3 coloured segments with name + level
- [ ] Opens with Body at bottom, collapsed
- [ ] Tap segment → rotate-to-bottom animation (`create_tween()`), then details panel opens with animation
- [ ] Details list sub-skills with level, XP, feats (unlocked vs locked, by level)
- [ ] Re-tap selected segment collapses details
- [ ] Old skills card removed from Profile
- [ ] Animation durations in data, not hard-coded
- [ ] Headless test: component builds from a projection; tap selection changes selected bucket / expanded state
- [ ] On-device QA list in report (rotation smoothness, colours, layout at phone width)
