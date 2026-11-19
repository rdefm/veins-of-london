# 03 — Pencil range scales and margin hints

**What to build:** on recipe page 1, replace the grey/green band gauge under each step with a small notebook-styled gauge Control drawn in code.

- **Exact range:** a crisp ink bracket on a thin scale line.
- **Rough (≈) range:** a hatched pencil band.
- **Insight steps:** no gauge.
- **Hints:** step hints (`note`) become pencilled margin notes (muted ink, smaller) beside the step they belong to, with a small arrow or mark tying them to it.
- **Colours:** from RecipeBookPage's ink constants; add a pencil tone if needed.

**Blocked by:** 02

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` (`_add_known_step`)
- `scenes/components/lab_gauges.gd` (`BandGauge`, region-to-pixel logic to reuse)
- `scenes/components/recipe_book_page.gd` (`INK`, `INK_MUTED`)
- `systems/lab.gd` (`step_region`: `low`, `high`, `vague`)
- `docs/ui-vision.md` (palette)

**Status:** ready-for-agent

- [ ] Exact vs rough is distinguishable without reading numbers
- [ ] Gauge spans the same scale as today's band; region maths reused, not duplicated
- [ ] Hints sit beside their step and fit the page alongside the procedure
- [ ] check_all clean; lab screen tests pass
