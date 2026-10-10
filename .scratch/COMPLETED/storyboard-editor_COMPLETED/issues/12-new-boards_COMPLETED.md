# 12 — New boards

**What to build:** The writer starts a board three ways: import a live `data/events/<id>.json` (flat gotos → named branches), a blank new event, or duplicate an existing proposal. Each produces a new proposal `.md` in `.scratch/writing-revamp/`.

**Blocked by:** 01 — Draft model + test harness; 03 — Save + Undo.

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js`, `data/events/*.json`, `.scratch/writing-revamp/`.

**Status:** ready-for-agent

- [ ] Import converts every live event without error (node test sweeps `data/events/`)
- [ ] Blank event: id prompt, one `main` branch, one card
- [ ] Duplicate: new id, comments optionally kept
- [ ] Never writes under `data/events/`
