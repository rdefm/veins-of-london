# 05 — Profile: Move Book–style sub-skill rows under the wheel

**What to build:** On the Profile Skills card, the Body/Mind/Soul wheel stays as it is (tap rotates the segment to the bottom). Underneath it, the selected bucket's sub-skills are listed in the Move Book's visual language instead of the current details panel:

- One collapsible row per sub-skill: level badge, mini XP track, one-line teaser — matching Move Book move rows.
- Opening a row shows its detail: XP line (xp / next threshold) and its feats, unlocked and locked — matching Move Book's open detail styling.
- Sub-skills skipped by the projection (e.g. no Dial) stay hidden.
- Reuse Move Book's row/detail builders rather than duplicating styling. Open-row and selected-bucket state is view state only (kept across refresh, like the wheel's).

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/skill_wheel.gd` (wheel + current details panel)
- `scenes/components/move_book.gd` (row/detail builders to reuse)
- `scenes/phone_apps/profile_app.gd` (`_build_skills_card()`, `_on_wheel_change()`, Move Book card)
- `systems/skill_tree.gd` (`project()` — buckets → sub-skills → feats) — read only
- `data/skill_feats.json` (`wheel` config)
- `CODEMAP.md` rows for touched files

**Status:** ready-for-agent

- [ ] Wheel unchanged; selecting a segment lists that bucket's sub-skills below it as Move Book–style rows
- [ ] Row: level badge, mini XP track, teaser; tap toggles open/closed
- [ ] Open detail: XP line + unlocked/locked feats in Move Book detail style
- [ ] Shared builders reused (no duplicated Move Book styling)
- [ ] View state survives a Profile refresh
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: rows look like the Move Book, wheel → rows interaction, feats readable
