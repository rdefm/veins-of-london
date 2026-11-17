# 09 — Proposed rules from notes, plus a Rules panel

**Status:** ready-for-agent

**What to build:** `propose-rules` reads per-draft notes newer than its last run (a watermark is stored in `_judge`). For each note it asks the model for 0–n scoped rule proposals, drops ones that duplicate existing rules (any status), and adds the rest as `proposed`, with `source` pointing at the note and draft.

A Rules panel in the storyboard tool lists rules grouped by status and scope. The user can:
- accept, reject or edit (text, scope) a proposed rule;
- retire an accepted rule;
- jump from a rule to its source draft.

Only the user's action in the tool makes a rule `accepted`.

**Blocked by:** 07 — Per-draft verdicts, agreement report and benchmark; 08 — Rules store applied in judging.

**Relevant files:**
- `tools/art_judge/`
- `.scratch/event-art/_judge/rules.json`
- `tools/storyboard.html` (new panel; tab/panel conventions; storage `write` with version check)
- `tools/test_storyboard.js`
- `tools/storyboard_server.js` (`WRITE_DIRS` covers `.scratch/`)
- `CODEMAP.md`

- [ ] `propose-rules` only processes new notes; a re-run with no new notes makes zero model calls.
- [ ] Duplicates of existing rules aren't proposed again.
- [ ] Panel: accept / reject / edit / retire update the file with a version-checked write; editing keeps `source`.
- [ ] A rule links to its source draft in the Shots tab.
- [ ] Tests: watermark, dedupe, `proposed` status only (fake backend); tool pure-section status changes.
- [ ] CODEMAP rows updated.
