# 09 — Dial menu: swap in the real art

**What to build:** Replace the placeholder shapes in the new Dial menu with the assets generated from the 06 art spec. That includes the three section-open strips (hatch, lens iris, canopy cross-section), the lens/movement/complication component sprites, the tag and the bench backdrop. Tune zoom, separation, open beats, float-in and reassembly to the agreed animation beats. Timings, offsets, zoom rects and the anchors measured from the cleaned sprites live in data, not in code constants. Decide **vertical vs horizontal** with the human here (the spec covers both; prompts target vertical).

**Blocked by:** 06 — Dial menu art brainstorm; 08 — New Dial menu: Movement and Complication sections, Craft

**Relevant files:**
- `.scratch/ui-previews-dial/dial-art-spec.md` (file list §2, layouts §3, beats §4)
- `assets/hq/dial/`, `assets/combat/icons/` (sources for the hand-made complication labels)
- `scenes/screens/hq_dial.gd` + the new Dial menu component
- `docs/ui-vision.md`, `docs/ART-BIBLE.md`

**Status:** ready-for-agent

- [ ] All spec assets wired in; no placeholder shapes left
- [ ] Open strips play on zoom-in and reverse on Back; reduced motion jumps to the last frame
- [ ] Animation beats match the spec; timings, offsets and anchors in data
- [ ] Orientation decision recorded in the spec
- [ ] Human on-device check of every section's zoom in/out
