# 02 — Cell borders follow the image

**What to build:** AI-generated "pixel art" doesn't sit on one perfect grid — its fake pixels stretch and drift, so a single fixed grid falls out of step partway across the image and produces doubled, broken or stair-stepped lines. After the grid is set (by hand or auto-detect), the user can turn on "Follow image edges": each column and row border is nudged up to ±N source px (slider) onto the nearest strong edge in the source, keeping borders in order and cells at least 1 px. The before-pane grid overlay draws the adjusted borders, so the user can see the grid hugging the fake pixels. Off by default; with it off, output is unchanged.

**Blocked by:** 01 — Testable maths core + node tests

**Relevant files:**
- `tools/pixelizer.html` (cell-edge computation, grid lock, grid overlay drawing, Grid fieldset)
- `tools/test_pixelizer.js`
- `CODEMAP.md` (pixelizer row)

**Status:** ready-for-agent

- [ ] Toggle + max-shift slider in the Grid section; the overlay shows the adjusted borders
- [ ] Borders use the same per-column/per-row edge-strength profile as auto-detect; adjusted borders stay strictly increasing and never leave the image
- [ ] Test: a synthetic image whose fake-pixel width drifts across the image (e.g. 5.0 px at the left to 5.6 px at the right) locked with one fixed cell size has clearly more mismatched cells than the same lock with edge-following on, which recovers (near-)all cells
- [ ] Test: on a clean, perfectly regular grid, edge-following changes nothing
- [ ] Interactive at slider speed on a ~1536×1024 image (no multi-second stalls)
- [ ] CODEMAP row updated
