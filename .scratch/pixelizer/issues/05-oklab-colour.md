# 05 — Perceptual colour (OKLab)

**What to build:** colour decisions in the pixelizer use plain RGB distance, which doesn't match how we see colour: darks and skin tones snap to the wrong palette shade, colour reduction wastes slots on differences the eye barely sees, and the outline-priority "dark" test misjudges saturated colours (a deep blue counts as bright). Switch palette snapping, colour reduction (clustering) and the dark test to OKLab (distances in OKLab; "dark" = OKLab lightness below the slider's threshold). The brightness slider keeps a 0–255-style scale or relabels clearly; existing results with default settings change only where perception says they should.

**Blocked by:** 01 — Testable maths core + node tests

**Relevant files:**
- `tools/pixelizer.html` (palette snap, colour reduction, outline-priority dark test, Outline priority fieldset)
- `tools/test_pixelizer.js`
- `data/palette.json` (palette used for snap tests)
- `CODEMAP.md` (pixelizer row)

**Status:** ready-for-agent

- [ ] Palette snap, colour reduction and the dark test all use OKLab; output pixels are still exact palette/cluster colours in sRGB
- [ ] Test: OKLab conversion round-trips sRGB within ±1 per channel
- [ ] Test: a case where RGB-nearest and perceptually-nearest differ (e.g. a dark saturated colour vs. a grey) snaps to the perceptual match
- [ ] Test: a saturated deep blue counts as dark at a threshold where RGB-weighted luminance said it did not (or the documented equivalent)
- [ ] Snapping a ~1536×1024 image stays interactive (per-colour cache kept)
- [ ] CODEMAP row updated
