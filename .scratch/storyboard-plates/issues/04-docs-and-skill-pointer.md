# 04 — Docs and skill pointer

**What to build:** The docs say the storyboard tool can create, edit and delete plates, and that the plate's compositor config is still written by the plate-compositor skill, not the tool.

**Blocked by:** 03 — New and delete plate buttons.

**Relevant files:**
- `CODEMAP.md` (storyboard.html rows; keep each row under 400 chars, current state only)
- `.claude/skills/event-storyboard/SKILL.md` (Phase 2 Board, Phase 4)
- `.claude/skills/event-storyboard/reference/board-schema.md`
- `tools/plate_compositor/README.md` §D (plate config)

**Status:** ready-for-agent

- [ ] CODEMAP row updated, under 400 chars, no ticket-history wording
- [ ] Skill and board-schema mention hand-made plates and the compositor config hand-off
- [ ] `scripts/lint_tokens.sh` clean for touched files
