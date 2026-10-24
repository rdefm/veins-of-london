# 02 — Working copy remembers its live source

**What to build:** A proposal imported from a live event records which `data/events/<id>.json` it came from. Choosing "Import live event" for an event that already has a working copy opens that copy instead of creating `-proposal2`. The board list marks working copies as editing a live event. Working copies stay in `.scratch/writing-revamp/` alongside proposals.

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/storyboard.html` (`importBoard`, `proposalFileName`, `parseProposal`, `loadProposals`, New board dialog `nbLive`, board dropdown), `tools/promote_storyboard.js`, `tools/test_storyboard.js`, `.scratch/writing-revamp/*.md`.

**Status:** ready-for-agent

- [ ] Imported proposal stores its live source in the saved file (draft field or heading) and survives Save, reload and Duplicate (Duplicate does not inherit the source)
- [ ] Importing an already-imported live event opens the existing working copy and says so; no `-proposalN` duplicate
- [ ] Board dropdown/summary distinguishes "editing live: <id>" from plain proposals
- [ ] Existing proposals without a source still load and save unchanged
- [ ] Tests cover import twice, source persistence, and legacy proposals
