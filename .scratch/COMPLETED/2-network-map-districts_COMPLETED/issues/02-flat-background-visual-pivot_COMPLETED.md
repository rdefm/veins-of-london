# 02 — Visual pivot: flat background replaces paper texture

**What to build:** Swap the Network map's aged-paper texture background for a flat, clean background colour — locking in the pivot toward a generic modern phone transit-app look instead of a hand-drawn parchment diagram. This ticket only replaces the background fill (today's `_draw_paper()` / `_paper_tile` in `map_canvas.gd`, N6's paper asset). The rest of the current palette — `PAPER_COLOUR`'s other uses (badge fills, pin head fills, etc.) and all line/stop styling — is untouched here; the full palette/line/stop redesign following this pivot is Chunk 3 (Map filters/visuals), not this ticket.

**Blocked by:** None — can start immediately.

**Status:** completed

- [ ] The map canvas's background is a flat solid colour, not the tiled paper-texture asset.
- [ ] Every other existing use of `PAPER_COLOUR` (badge fills, pin head fills, etc.) is unchanged — verified by inspection that only the background draw call changed.
- [ ] The retired paper-tile generation code is either removed or clearly left as dead code per project convention (implementer's call) — no parse errors or dangling references.
- [ ] Visual smoke-check: the map screen renders correctly with the flat background at every supported zoom level, with no regression to line/stop legibility.

