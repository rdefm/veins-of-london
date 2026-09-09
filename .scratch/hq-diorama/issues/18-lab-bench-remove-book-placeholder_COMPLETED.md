# 18 — HQ lab bench: remove placeholder box over recipe/experiments notebooks

**What to build:** The `notebookRecipes`/`notebookExperiments` regions on the
lab bench plate stop rendering `HqDiorama`'s generic labelled placeholder
box. Ticket 12's desk art already depicts both books at exactly those region
rects, so the box is now a redundant grey rectangle sitting over finished
art — the region stays tappable (unchanged hit-test/tap behaviour), it just
no longer draws the placeholder fill/border/label on top of the art. Since
`HqDiorama` is a generic renderer shared by every plate (most of which still
have no art and still need the placeholder), this needs an opt-out at the
region level in the `data/hq_visuals.json` schema (e.g. a `"placeholder":
false` field), read generically by `HqDiorama`'s `_draw()` — not a
notebook-specific special case in the renderer.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `data/hq_visuals.json` region schema gains an opt-out field suppressing the placeholder box for a region with finished background art
- [ ] `notebookRecipes`/`notebookExperiments` regions use it; no other region's rendering changes
- [ ] `HqDiorama._draw()` reads the field generically, no per-region-id special case
- [ ] Tapping the (now invisible-box) notebook regions still works exactly as before
- [ ] Debug overlay (region outlines) is unaffected — still shows the hit rect for every region regardless of this flag
- [ ] Tests updated/added covering the opt-out
