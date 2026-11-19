# 09 — Content-adaptive cell colour mode in the tool

**What to build:** expose 08 as a third "Cell colour" option ("Detail", alongside Dominant / Average) in the pixelizer. Choosing it runs the content-adaptive downscale for the current cell size and offset, then the existing pipeline steps after grid-lock (palette reduce/snap, clean-up filters, outline thinning) as usual. Dark/light share and sample-core don't apply in this mode; their controls are visibly disabled while it is selected. A full 1024×1536 card is ~43k kernels, so processing runs without freezing the page (Web Worker or chunked) with a progress readout, and a new setting change cancels a run in progress. Optional iteration-count slider. The mode is remembered like the other settings.

**Blocked by:** 08 — Content-adaptive downscale (Kopf 2013): maths core

**Relevant files:**
- `tools/pixelizer.html` (Cell colour fieldset/`modeSeg`, `go()` pipeline, settings remember, maths section)
- `tools/test_pixelizer.js`
- `CODEMAP.md` (pixelizer row)

**Status:** ready-for-agent

- [ ] "Detail" mode button; output grid size matches Dominant/Average for the same cell/offset
- [ ] Palette snap and post-grid clean-up still apply after it
- [ ] Share and core controls disabled in this mode
- [ ] Page stays responsive on a 1024×1536 image at cell 4; progress shown; changing a setting mid-run cancels and restarts
- [ ] Human QA: col_a1_nadia_meet_card2 at cell 6 in Detail mode keeps both eyes readable
- [ ] CODEMAP row updated
