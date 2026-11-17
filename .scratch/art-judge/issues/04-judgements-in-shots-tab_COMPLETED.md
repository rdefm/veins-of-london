# 04 — Judgements in the Shots tab

**Status:** ready-for-agent

**What to build:** In the storyboard tool's Shots tab, each draft figure shows:
- its judgement: a verdict badge (pass / fail / unjudged / stale / not judged) and the brief, style and per-cast scores;
- a collapsible list of failed and unsure checks with their one-line reasons.

A shot's drafts are ordered by rank, best first. The tool reads judgement files through its existing `storage` interface, so this works in both folder mode and server mode. The tool only reads judgements here; it never writes them.

Matching judgements to drafts, working out staleness (draft's current version token or sha vs `draftSha`), and badge state go in a new marked pure section, unit-tested.

**Blocked by:** 03 — Batch judging and ranking.

**Relevant files:**
- `tools/storyboard.html`:
  - ~1582 Storage (pure) / ~2287 Draft model (pure) (pure-section conventions)
  - ~5172 board/feedback loading
  - ~5204 `filesFor`
  - ~7179–7197 Shots tab draft figures + verdict block
  - ~121–124 `.drafts` CSS
- `tools/test_storyboard.js`
- `tools/storyboard_server.js` (read paths; no change expected)
- `CODEMAP.md` (storyboard.html rows)

- [ ] Each draft figure shows a badge and scores when a judgement exists, and "not judged" when it doesn't.
- [ ] A judgement whose draft has changed on disk shows as stale.
- [ ] Drafts within a shot are ordered by rank; unjudged and not-judged drafts go last.
- [ ] Failed/unsure checks expand under the figure with their reasons.
- [ ] Works in folder mode and server mode.
- [ ] New pure section tested in `test_storyboard.js`: matching (incl. `_vN` and `_clean` files), stale detection, ordering, badge state. Existing tests still pass.
- [ ] CODEMAP storyboard row updated (current state only, under 400 chars).
