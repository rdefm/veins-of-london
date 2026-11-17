# 02 — Pixel metrics

**Status:** ready-for-agent

**What to build:** Each judgement gains measured pixel-art metrics, which are also passed to the vision model as context:
- estimated grid scale;
- grid regularity, 0–1 (how well the image sits on a true pixel grid);
- colour count after grid-lock;
- mean distance to the reference palette.

Prefactor first: grid-lock (box downscale to native size) and palette snapping currently exist separately in the pixelize script and the plate compositor. Move them into one shared helper that all three tools use, with no change in the existing tools' output.

**Blocked by:** 01 — Judge one draft, end to end.

**Relevant files:**
- `.claude/skills/event-storyboard/scripts/pixelize.py` (`load_palette`, downscale/quantise path)
- `tools/plate_compositor/compose.py` (grid-lock + `snap`, palette median-cut)
- `tools/png_io.py`
- `data/palette.json`
- `docs/ART-BIBLE.md` §1 (genuine pixel grid, limited palette), §2 Reference palette
- `tools/art_judge/`

- [ ] The shared helper is used by pixelize, the compositor and the judge. pixelize and compose output for an existing input is byte-identical before and after the change (checked once on a real plate/draft).
- [ ] Judgement `metrics` has `size`, `gridScale`, `gridRegularity`, `colours` and `paletteDistance`.
- [ ] Tests on generated images: a clean 4× grid with 16 palette colours scores high regularity, low colour count and ~0 palette distance; the same image blurred/anti-aliased scores clearly worse on each.
- [ ] Metrics are informational in v1: they never change the verdict by themselves (size is still the only hard technical check).
