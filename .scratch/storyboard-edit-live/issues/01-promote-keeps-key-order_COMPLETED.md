# 01 — Promote keeps original key order

**What to build:** Importing a live event into the storyboard tool and promoting it unedited reproduces the live file exactly, so Promote reports "No change". After an edit, git shows only the lines that were edited, not a reshuffle of keys. Today 86 of 92 live events come back with the same content but different key order (top-level and per card).

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/storyboard.html` (`importBoard`, `legacyToDraft`, `promoteDraft`, `serialiseEvent`, `promoteSummary`), `tools/test_storyboard.js`, `tools/promote_storyboard.js`, `data/events/*.json` (house style: one top-level key per line, one card per line).

**Status:** ready-for-agent

- [ ] Draft keeps enough information (e.g. key order) for promote to emit top-level and per-card keys in the imported order; new/blank events keep the current default order
- [ ] Test imports then promotes every `data/events/*.json` and asserts byte-identical output (fix `serialiseEvent` formatting if any file differs on whitespace)
- [ ] Editing one card's text then promoting changes only that card's line in the output
- [ ] `node tools/test_storyboard.js` has no new failures
