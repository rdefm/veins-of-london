# 10 — Fallback: "Kopf-inspired" downscale if the paper-faithful one disappoints

**What to build:** only if testing 08/09 on real cards shows the paper-faithful `kopfDownscale` doesn't work for us: swap its core back to the Kopf-inspired version from commit `c901c858` (`git show c901c858:tools/pixelizer.html`, function `kopfDownscale`), keep the paper-faithful one available (e.g. as `kopfDownscalePaper`) so the two can be compared, and restore that commit's tests (dot kept in its own cell, edge as one sharp step, 512² in < 3 s). Label it "Kopf-inspired" in its comment and list the departures below.

**Blocked by:** 09 — Content-adaptive cell colour mode in the tool (need real-card results first)

**Relevant files:**
- `tools/pixelizer.html` (`kopfDownscale` in the maths section)
- `tools/test_pixelizer.js` (kopfDownscale tests)
- Paper: https://johanneskopf.de/publications/downscaling/paper/downscaling.pdf; pseudocode: https://johanneskopf.de/publications/downscaling/paper/pseudocode.pdf

**Status:** needs-triage

## How the Kopf-inspired version (c901c858) differs from the paper (current code)

| | Paper (current) | Kopf-inspired (c901c858) |
|---|---|---|
| Starting colour ν | middle grey, OKLab (0.5, 0, 0) (eq. 6) | the cell's pixel farthest from the cell mean |
| Colour sigma | per kernel, starts 1e-4, ×1.1 when a §4.2 rule fires | fixed 0.08 (OKLab), never changes |
| Kernel pixel range R_k | \|x − x_k\| < 2 cells (pseudocode Fig. 1) | own cell + 8 neighbour cells, then only ±3σ_max around the centre |
| Pixel coordinates | integer source coords (pseudocode) | pixel centres (x + 0.5) |
| Centre smoothing | halfway to the mean of the 4 neighbours' positions (eq. 11) | halfway to the mean of the neighbours' offsets from their own cell centres (no inward pull at borders) |
| Centre clamp | cell centre ± ¼ cell (eq. 11) | anywhere inside its own cell |
| Initial covariance | r/3 (eq. 6), clamped from the first C-step | r/3, clamped at once |
| Shape rules (§4.2) | locality (eq. 13) always on; edge orientation behind `opts.edgeOrientation`, off by default | none |
| Stopping | until nothing changes, `iterations` (default 50) as a cap | always exactly `iterations` (default 25) |
| Per-kernel normalisation | log-space, can't underflow at σ = 1e-4 | weights below e^-60 dropped, rerun shifted if all are |

Shared by both: OKLab instead of the paper's CIELAB; the eq. 12 clamp [0.05, 0.1] read in cells²; transparent pixels left out, mostly transparent cells give a transparent pixel.

Readings in the paper-faithful version that the paper doesn't settle (worth revisiting before falling back):
- Eq. 13 offsets read in cells. At cell ≥ 5 a kernel that just owns its own cell already scores over 0.2·r (≈ r²/24), so the rule fires everywhere and σ keeps growing.
- σ growth applied once per kernel per step (paper text), not once per neighbour pair (pseudocode — that sent σ to ~7.7e6 and gave a plain blur).
- Edge-orientation angle compared as lines (undirected); the summed gradient points back towards k, so a directed angle would always be > 25°.

## Observed at cell 6 (synthetic tests, 2026-11-19)

| | Paper, 50 rounds (default) | Paper, run to convergence (~100+) | Kopf-inspired, 25 rounds |
|---|---|---|---|
| 2-px dark dot in skin | kept, but spreads to a 2×2 block of output pixels | blurred to ≈ the cell mean | kept in its own cell only |
| Red/blue edge 2 px into a cell | no blending, but the all-red cell next to the edge turns blue | middle column blended | one sharp step in the right place |
| 512² time | ~15 s | — | ~1.5 s |

- [ ] Real-card comparison done in 09 and recorded here
- [ ] If falling back: Kopf-inspired core restored, paper version kept alongside, tests from c901c858 back, comment lists the departures above
