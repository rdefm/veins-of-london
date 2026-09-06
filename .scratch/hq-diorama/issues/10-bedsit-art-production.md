# 10 — Bedsit art production

**What to build:** Real pixel-art plates for the bedsit tier, dropped in
file-by-file over ticket 01's placeholder renderer with zero code change:
the room plate, the bench plate (all three stops), ore container sprites
(5 types × 3 states = 15 sprites), door fixture variants, and apparatus/
Train animation frames. Follows ART-BIBLE §1–§4 (overcast daylight, muted,
top-left key light, genuine pixel grid, no anti-aliasing) and §11's rules:
outlines baked into the art, state variants produced as variant plates with
manually cropped/spliced differing regions, fixed integer scale + nearest
filtering throughout.

**Blocked by:** 02, 03, 04, 05, 07, 08, 09

**Status:** ready-for-agent

- [ ] Room plate produced with baked tappable-object outlines for every bedsit-tier zone
- [ ] Bench plate produced for all three stops with baked apparatus/container outlines
- [ ] 15 ore container sprites (5 types × empty/some/plenty) produced
- [ ] Door fixture variant plates (installed/empty per slot) produced and registered/cropped per §11
- [ ] Apparatus and Train animation frames produced
- [ ] `data/hq_visuals.json` image paths updated to point at the new assets; hit regions in the manifest verified against the finished plates using ticket 01's debug overlay
- [ ] Any unverified region flagged `ART-REVIEW:` in the task report
