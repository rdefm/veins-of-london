# 08 — Content-adaptive downscale (Kopf 2013): maths core

**What to build:** a pure function in the pixelizer's marked maths section that downsizes an image to a given grid (same column/row count the current cell size gives) using Kopf, Shamir & Peers 2013, "Content-adaptive image downscaling" (SIGGRAPH Asia). Each output pixel is a 2D Gaussian kernel in source space with its own centre, covariance and colour; an EM loop (fixed iteration count, ~20–30) alternates assigning source pixels to nearby kernels by weight (normalised across the kernels that compete for each pixel) and re-fitting each kernel's centre, shape and colour. Apply the paper's constraints so the grid stays a grid: centres pulled towards their neighbours (spatial smoothness), clamped to stay near their own cell, covariance eigenvalues clamped. Colour weighting uses OKLab distance. Small high-contrast features (an eye) end up owning a kernel instead of being averaged away. No UI in this ticket — exported for tests only. Work out from the paper's pseudo-code (Algorithm 1) rather than guessing parameters; note any parameter you had to pick in a comment citing the paper section.

**Blocked by:** 07 — Light share that wins a cell

**Relevant files:**
- `tools/pixelizer.html` (marked pure maths section; `cellEdges`/`gridAxes` for grid size, `srgbToOklab`/`oklabToSrgb`)
- `tools/test_pixelizer.js` (add the new function to the exported `names` list)

**Status:** ready-for-agent

- [ ] Pure function: (image, width, height, cell, ox, oy, iterations) → ImageData of the same grid size `gridLock` gives
- [ ] Test: flat single-colour image → every output pixel that colour
- [ ] Test: 2-px dark dot (eye-like) inside a skin-tone area at cell 6 → present in the output where `gridLock` dominant and mean both lose it
- [ ] Test: a hard vertical edge stays one sharp step (no blended middle column)
- [ ] Test: runs on a 512×512 synthetic image at cell 6 in under ~3 s under node
