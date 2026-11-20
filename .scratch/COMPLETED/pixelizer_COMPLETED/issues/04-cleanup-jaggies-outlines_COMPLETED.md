# 04 — Cleanup pass: jagged edges + thick outlines

**What to build:** two more cleanups in the Cleanup section, each its own toggle, run on the native result after stray-pixel removal. "Smooth jagged edges" removes the extra corner pixels that make a diagonal or curve step irregularly (L-shaped "doubles" along a 1-px line), so lines read as clean pixel-art steps. "Thin outlines" brings dark outlines that came out 2 px thick back to 1 px, keeping the pixel on the outer side, without breaking the line or merging separate lines. Dark means the same threshold the outline-priority control uses.

**Blocked by:** 03 — Cleanup pass: stray pixels

**Relevant files:**
- `tools/pixelizer.html` (Cleanup fieldset and post-lock pipeline from ticket 03)
- `tools/test_pixelizer.js`
- `CODEMAP.md` (pixelizer row)

**Status:** ready-for-agent

- [ ] Two toggles, both off by default; order in the pipeline is stray pixels → jaggies → outline thinning
- [ ] Test: a 1-px diagonal line with L-shaped doubles comes out as a single connected 1-px staircase
- [ ] Test: a 2-px-thick dark outline around a shape comes out 1 px thick and still closed (no gaps); a genuine 2-px gap between two separate lines is not merged
- [ ] No new colours introduced; transparent pixels untouched
- [ ] CODEMAP row updated
