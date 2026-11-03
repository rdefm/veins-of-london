# 09 — Storyboard pack editing

**What to build:** the writer can edit prose packs in storyboard. Prose cards' event cards are edited with the existing card editor; condition and weight are editable; prose cards (and replies) can be added, duplicated and deleted. Save writes straight to the live pack file (git is the undo). "For Claude" comments work as on proposals and are stored in the pack under `_comments`, which GameData lint ignores. The sandbox reflects edits right away.

**Blocked by:** 08 — Storyboard Prose pack mode: viewer + sandbox

**Relevant files:**
- `tools/storyboard.html` — card editor, save path, comments (`_comments`)
- `tools/test_storyboard.js`
- `autoload/GameData.gd` (ignore `_comments` in packs), `tests/test_gamedata.gd`
- `.claude/skills/implement-storyboard-event` (check whether it needs a pack note; only update if trivial)
- Spec: `.scratch/board-prose-cards/spec.md`

**Status:** ready-for-agent

- [ ] Load → edit → save round trip keeps the pack valid and its other fields and order unchanged
- [ ] Add / duplicate (new unique id) / delete work for prose cards and replies
- [ ] Comments save and reload; a pack with `_comments` passes GameData lint
- [ ] On-device check list for the human in the report
