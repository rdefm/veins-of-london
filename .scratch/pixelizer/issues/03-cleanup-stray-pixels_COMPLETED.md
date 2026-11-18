# 03 — Cleanup pass: stray pixels

**What to build:** real pixel art gets a hand cleanup after drawing; the pixelizer's output doesn't yet. Add a "Cleanup" section that works on the native-size result (after grid lock and colour snapping). The first cleanup is "Remove stray pixels": an isolated pixel that matches none of its neighbours is recoloured to its neighbours' most common colour. It protects small intentional details — a pixel that is clearly darker or brighter than all its neighbours (an eye, a highlight) is kept, with a protection strength control. The after pane, colour count and saved image all reflect the cleanup.

**Blocked by:** 01 — Testable maths core + node tests

**Relevant files:**
- `tools/pixelizer.html` (pipeline after grid lock/palette snap; sidebar fieldsets)
- `tools/test_pixelizer.js`
- `CODEMAP.md` (pixelizer row)

**Status:** ready-for-agent

- [ ] Cleanup fieldset with a "Remove stray pixels" toggle (off by default) and a detail-protection control
- [ ] Runs on the native result only (fast); transparent pixels are left alone
- [ ] Test: a lone off-colour pixel inside a flat area is removed; a lone high-contrast dark pixel (eye) inside a light area survives with protection on and goes with it off; 2+ connected same-colour pixels are never touched
- [ ] Only colours already present in the result appear after cleanup (no new colours)
- [ ] CODEMAP row updated
