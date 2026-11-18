# 06 — One palette shared across images

**What to build:** today "Reduce" builds a fresh palette per image, so shots from the same event drift in colour — the opposite of the consistency the tool exists for. Let the user build one palette from several images: add images to a "palette set" (multi-file open), choose a colour count, and the tool clusters across all of them (each image's grid-locked colours, weighted so one large image doesn't dominate). The result is shown as a swatch strip, can be saved as a palette JSON file (same shape as `data/palette.json`'s colour list, so it loads back through the existing palette loader), and becomes the active palette, so every image the user then processes is locked to it.

**Blocked by:** 05 — Perceptual colour (OKLab)

**Relevant files:**
- `tools/pixelizer.html` (Colours fieldset, palette load/remember, colour reduction, save helper)
- `tools/test_pixelizer.js`
- `data/palette.json` (file shape the saved palette must match closely enough to load back)
- `CODEMAP.md` (pixelizer row)

**Status:** ready-for-agent

- [ ] Palette-set UI: add/remove images (names listed), colour count, "Build palette"; swatch strip of the result
- [ ] Clustering across images uses OKLab and per-image weighting (each image contributes equally regardless of size)
- [ ] "Save palette…" writes JSON that the existing "Load palette JSON" reads back to the identical colours; the built palette becomes the active, remembered palette
- [ ] Test: two synthetic images with disjoint colour sets, one 4× larger, built to N = total distinct colours → every colour of both images present (the small image isn't swamped)
- [ ] Test: saved JSON round-trips through the palette parser
- [ ] CODEMAP row updated
