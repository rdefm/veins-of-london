# 07 — ART-BIBLE, master palette, `tools/pixelize.py`

**What to build:** Per §6, the pipeline discipline that must exist **before
any real combat asset is generated** — this is what makes AI-generated
pixel art read as one authored game instead of a mood board of three
different palettes.

1. **Lock a master palette.** 32–48 colours, committed as
   `data/palette.json` plus a swatch PNG. This is authored (by the human, or
   drafted here and approved by them), consistent with §1's locked
   direction: overcast daylight, muted/desaturated (brick red, weathered
   pastel, grey sky), damp-pavement-reflecting-sky rather than neon/rain.
2. **`tools/pixelize.py`.** Detects native cell size → downsamples nearest →
   quantises to `data/palette.json` → strips anti-aliased fringe → trims to
   a fixed canvas (canvas sizes per §6.1: combatant ~64×104, backdrop plate
   390×360, effect frame 96×96, large effect 160×160). Run on everything, no
   exceptions — every ticket from 08 on depends on this existing and
   working.
3. **`docs/ART-BIBLE.md`** holding the palette, canvas sizes, the lighting
   rule (all three direction references are top-left key light — keep it),
   and the generation prompt template, so the art is reproducible later
   without re-deriving these decisions.

**Blocked by:** None — can start immediately, in parallel with every UI
ticket above.

**Assets needed:** **the palette itself is this ticket's deliverable** —
32–48 authored colours + a swatch PNG. No external art generation is
required to complete this ticket; `tools/pixelize.py` can be validated
against any placeholder or test image, real combat art isn't needed to
prove the pipeline works.

**Status:** ready-for-agent

- [ ] `data/palette.json` exists with 32–48 colours, consistent with §1's
      locked overcast-daylight/muted direction
- [ ] A swatch PNG rendering the palette exists alongside it
- [ ] `tools/pixelize.py` runs end-to-end on a test image: detects cell
      size, downsamples nearest, quantises to the palette, strips fringe,
      trims to a specified fixed canvas size
- [ ] `docs/ART-BIBLE.md` documents the palette, all four canvas sizes from
      §6.1, the top-left key-light rule, and a generation prompt template
- [ ] Render/import settings from §7 (Lossless import off compression,
      Nearest texture filter, one pixel-snap rule) are documented in
      ART-BIBLE.md even though the settings themselves are applied in
      ticket 08 (this ticket documents the rule; 08 flips the project
      settings)
