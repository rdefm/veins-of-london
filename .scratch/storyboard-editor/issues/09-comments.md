# 09 — Comments

**What to build:** Writers attach comments of two kinds — **for Claude** (actionable, open/resolved) and **note** (memory only) — to a card, choice/outcome, branch or the whole board. Stored inside the draft JSON (`_comments` / per-anchor), so one file = whole draft. The Comments tab lists all, filterable by kind, status, anchor; clicking one jumps to its anchor. Proposal logline/intro and "Open points" prose surface as board-level comments.

**Blocked by:** 02 — Tabs shell; 03 — Save + Undo.

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js`, `.scratch/writing-revamp/*-proposal*.md` (logline / Open points sections), spec § Decisions (Comments, Comment storage, Proposal md prose).

**Status:** ready-for-agent

- [ ] Add / edit / delete / resolve comments on every anchor type
- [ ] Comment badges on graph nodes and in card editor
- [ ] Comments tab filters (kind, status, anchor) and jump-to-anchor
- [ ] Logline and Open points shown as board comments
- [ ] Comments survive card reorder (anchored by key); round-trip node test
