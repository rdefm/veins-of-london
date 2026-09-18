# 23 — Lab bench: full-table backdrop asset integration

**What to build:** A new borderless (transparent-background, verified via
alpha channel) single full-table image, 612x408px, has been supplied and
already copied into `assets/hq/lab_bench.png`, replacing the old
780x844px asset. It's ONE image representing the full two-stop plate
(both "books_ore" and "apparatus" stops combined), shown at half-width per
stop via the existing pan/arrow-tween mechanism
(`LabBenchNav.step()`/`_pan_diorama_to()` in `hq_lab_bench.gd`) — same
role the old asset played, just at new dimensions.

Resize `data/hq_visuals.json`'s `labBench` plate from width 780/height 844
to width 612/height 408 (stop width goes from 390 to 306). Re-author every
region's x/y/width/height in `labBench.regions`
(`notebookRecipes`, `notebookExperiments`, the 5 `ore_*` containers, the
`apparatus_*` slots) to match the new image's actual layout — place
`notebookRecipes`/`notebookExperiments` by eye against the visible book
art; the other regions have no visible art yet, so proportionally rescale
their existing 780x844-space rects into the new 612x408 space as a
starting point and flag them `ART-REVIEW` for placement confirmation once
their own art exists.

Note: the off-white placeholder-box border noticeable around the ore/
apparatus regions (`HqDiorama._draw_placeholder_box()` in
`scenes/components/hq_diorama.gd`) is not a bug and needs no fix here —
`_should_draw_placeholder()` already skips it the moment a region's own
`image` field points to a loaded texture. It resolves on its own once
per-region art is supplied and wired in; no separate ticket for it.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `labBench` plate width/height updated to 612/408 in `data/hq_visuals.json`
- [ ] `notebookRecipes`/`notebookExperiments` region rects placed against the new art's actual book positions
- [ ] `ore_*` and `apparatus_*` region rects proportionally rescaled into the new coordinate space, flagged `ART-REVIEW`
- [ ] Pan/arrow-step between the two stops still lands cleanly on each half of the new image (no partial/misaligned pan)
- [ ] `tests/test_hq_lab_bench.gd` and any plate-dimension assertions updated to the new size
