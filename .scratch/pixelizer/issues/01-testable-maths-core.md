# 01 — Testable maths core + node tests

**What to build:** the pixelizer's pure image maths (cell edges, grid lock incl. outline priority, colour reduction, palette snap/parse, contrast/saturation, Kuwahara flatten, grid detection, colour count) lives in one marked "pure" section of the page with no DOM access, and a node test file extracts that section straight from the shipped HTML and tests it — the same pattern the storyboard tool's tests use. The behaviour of the tool does not change; this makes the checks that were run by hand during the tool's build permanent, so later tickets can add tests cheaply.

**Blocked by:** None — can start immediately

**Relevant files:**
- `tools/pixelizer.html` (pure maths currently sits above the `// ---------- pipeline` comment)
- `tools/test_pixelizer.js` (new)
- `tools/test_storyboard.js` (pattern: extracts a section between `/* ---------- X (pure) ---------- */` / `/* ---------- End X ---------- */` markers, shims what it needs)
- `CODEMAP.md` (§ tools/*.py, *.html, *.js — asset/content pipeline tooling)

**Status:** ready-for-agent

- [ ] Pure maths is between explicit start/end markers and touches no `document`/`window`/`localStorage`; `ImageData` is the only browser type it needs (shimmed in the test)
- [ ] `node tools/test_pixelizer.js` passes and covers at least: dominant lock recovers a clean grid exactly; dominant takes the majority where mean blends; fractional cell + offset recovers a synthetic noisy grid (auto-detect → 0 mismatched cells with colour reduction); outline priority keeps a thin dark line that plain dominant loses (dominant and mean); Kuwahara cuts texture noise while keeping a hard edge; palette JSON parse finds every `#rrggbb` in `data/palette.json`
- [ ] Tool behaves identically in the browser (no UI change)
- [ ] CODEMAP row mentions the test file; `scripts/lint_tokens.sh` clean
