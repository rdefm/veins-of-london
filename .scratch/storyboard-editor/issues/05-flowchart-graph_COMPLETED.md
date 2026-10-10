# 05 — Flowchart graph (elkjs)

**What to build:** The Storyboard tab shows the draft as a flowchart (elkjs layered, left→right, SVG pan/zoom). Toggle the whole graph between branch-as-node (title, card count, first line) and card-as-node; expand a single branch inline. Edges show card/outcome gotos and branch `then` (conditional edges labelled). Clicking a node selects that card/branch for preview + editor.

**Blocked by:** 01 — Draft model + test harness.

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js` (graph-building pure function), spec § Branch view, § Open points.

**Status:** ready-for-agent

- [ ] elkjs from CDN at an exact pinned version
- [ ] Graph data (nodes/edges) built by a pure, node-tested function for both modes
- [ ] Collapsed / expanded toggle; per-branch expand re-lays the graph
- [ ] Pan/zoom; click selects; selection highlighted
- [ ] Graph re-renders after edits
