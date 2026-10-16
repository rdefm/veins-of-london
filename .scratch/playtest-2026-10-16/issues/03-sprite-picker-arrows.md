# 03 — Sprite picker arrows visible

**What to build:** In the New Game / Debug Start sprite picker, the two white circles above Select are empty — the ◀ / ▶ glyphs no longer render. Restore visible left/right arrows inside the circles (drawn icons rather than font glyphs if the font lacks them).

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/title.gd` (sprite picker overlay), `theme/main_theme.tres`, `fonts/` used by the theme

**Status:** ready-for-agent

- [ ] Both circles show a clearly visible arrow, dark on the light circle
- [ ] Arrows still cycle sprites
- [ ] On-device check listed in report
