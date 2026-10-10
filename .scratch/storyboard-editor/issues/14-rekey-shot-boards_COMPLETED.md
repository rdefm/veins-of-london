# 14 — Re-key shot boards to branch+card

**What to build:** Shot boards key shots on branch+card (card `key`) instead of flat one-based card numbers, so draft edits don't break them. Existing boards migrated; tool and event-storyboard skill updated.

**Blocked by:** 01 — Draft model + test harness; 02 — Tabs shell.

**Relevant files:** `.scratch/event-art/{intro,intro-proposal2,biz_a1_proposition,col_a2_handler_meet}/board.json`, `.claude/skills/event-storyboard/SKILL.md`, `.claude/skills/event-storyboard/reference/board-schema.md`, `.claude/skills/event-storyboard/scripts/event_digest.py`, `tools/storyboard.html`.

**Status:** ready-for-agent

- [ ] Board schema documents branch+card keys
- [ ] All four boards migrated; tool shows the same shot↔card mapping as before
- [ ] event_digest.py / skill emit the new keys
