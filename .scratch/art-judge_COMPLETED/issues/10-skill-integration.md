# 10 — Skill integration

**Status:** ready-for-agent

**What to build:** The event-storyboard skill uses the judge:
- **Phase 4 draft QA:** the skill runs `judge --board` instead of its manual QA checklist. It reports one line per draft (verdict, lowest score, top failure) and points the user at the Shots tab for details and correction prompts. Pixelize stays available as an optional cleanup step.
- **Prompt writing (Phase 4 `prompts.md` and delta prompts):** accepted in-scope art rules are added to each shot prompt, scoped by the shot's cast and plate.
- **When the user says "reviewed":** the skill runs `propose-rules` and tells the user how many rules are waiting in the Rules panel.

ART-BIBLE §4 currently says there is no automated pipeline tool. Draft new wording describing the judge and the rules store, **show it to the user and wait for approval** before writing it.

**Blocked by:** 02 — Pixel metrics; 05 — Correction prompts; 08 — Rules store applied in judging. (`propose-rules` step also needs 09.)

**Relevant files:**
- `.claude/skills/event-storyboard/SKILL.md` §Phase 3, §Phase 4
- `.claude/skills/event-storyboard/reference/prompt-pack.md` (§Shot prompt (pose), §Delta prompt)
- `.claude/skills/event-storyboard/reference/board-schema.md` (rules about short prompts)
- `docs/ART-BIBLE.md` §4 Generation discipline
- `CODEMAP.md`

- [ ] SKILL.md Phase 4 tells the agent to run the judge and report one line per draft; the manual checklist is gone or points at the judge's categories.
- [ ] Prompt-pack guidance includes in-scope accepted rules while keeping prompts short (rules after the cast lines, before the fixed tail).
- [ ] ART-BIBLE §4 wording approved by the user, then written.
- [ ] Dry run of the skill's Phase 4 on `intro-proposal2` produces the one-line reports.
