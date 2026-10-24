# 04 — Live events in the board picker

**What to build:** The board dropdown gains a "Live events" group listing every event in `data/events/`. Picking one opens its working copy, or imports one on first open, so editing an existing in-game event is one click instead of New board → Import live event.

**Blocked by:** 02 — Working copy remembers its live source.

**Relevant files:** `tools/storyboard.html` (board selector, `loadProposals`, `importBoard`, `nbLive`, `fileNames`, `LIVE_EVENTS_DIR`), `tools/test_storyboard.js`, `data/events/` (skip `_to_be_coded`).

**Status:** ready-for-agent

- [ ] Dropdown lists all live events not yet imported, grouped separately from Storyboards and Proposals; events with a working copy appear under it as editing-live
- [ ] Selecting an un-imported live event imports it (writes the working copy to `.scratch/writing-revamp/`) and opens it
- [ ] Selecting one with an existing working copy opens that copy (no duplicate)
- [ ] Non-event entries under `data/events/` are ignored
- [ ] Tests cover list building and open-or-import selection
