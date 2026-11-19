# 07 — Light share that wins a cell

**What to build:** at cell 4–6, eye whites, catchlights and other small bright details get averaged or outvoted into the surrounding colour (faces in AI art are drawn finer than the rest of the image). Add a light-side counterpart to outline priority: a "Light share that wins a cell" slider (off by default) and a "Counts as light above brightness" slider, both judged on OKLab lightness on the same 0–255 grey scale as the dark controls. A cell whose opaque pixels are at least that share light takes the light pixels' colour (most common light colour in Dominant, mean of light pixels in Average), just as dark share does today. When a cell passes both the dark and light tests, whichever makes up more of the cell wins; dark wins a tie. Works with palette snap and edge-following exactly as dark share does. Settings are remembered like the other sliders.

**Blocked by:** None — can start immediately

**Relevant files:**
- `tools/pixelizer.html` (Outline priority fieldset, `gridLock`, `darkLevel`/`oklabL`, `go()` where the outline options are built, slider wiring/remember)
- `tools/test_pixelizer.js` (existing "outline priority keeps a thin dark line" test as the pattern)
- `CODEMAP.md` (pixelizer row)

**Status:** ready-for-agent

- [ ] Two new sliders in the Outline priority fieldset; light share off by default, so output is unchanged until it's switched on
- [ ] Dominant and Average both honour light share; palette-snapped path too
- [ ] Both thresholds pass → larger share wins, tie → dark
- [ ] Test: 6×6 brown cell with a 2-px white fleck → lost with light share off, kept (white) with it on, both modes
- [ ] Test: a cell with a dark pupil and a larger white area → white wins; equal areas → dark wins
- [ ] Test: a cell with no light pixels is identical with the control on or off
- [ ] CODEMAP row updated
