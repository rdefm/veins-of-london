# 02 — Tabs shell: Storyboard / Shots / Comments

**What to build:** The tool gets three tabs. The existing shot briefs / verdicts / prompts / uploads section moves unchanged to the **Shots** tab; **Storyboard** keeps the phone preview (graph + card editor arrive later); **Comments** is an empty placeholder.

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/storyboard.html` (`renderShots`, `saveFeedback`), `.claude/skills/event-storyboard/SKILL.md` (review-round instructions referencing the page layout), `CODEMAP.md` row for `storyboard.html`.

**Status:** ready-for-agent

- [ ] Three tabs, switching without reload; selected tab remembered per viewer (storage in try/catch)
- [ ] Shot review workflow (verdicts, notes, uploads, saveFeedback) behaves exactly as before, inside Shots tab
- [ ] event-storyboard skill text matches the new layout
