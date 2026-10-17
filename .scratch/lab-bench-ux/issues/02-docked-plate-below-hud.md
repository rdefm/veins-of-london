# 02 — Docked plate below HUD, dock starts at press bottom

**What to build:** In a docked run the Lab plate is top-aligned at the safe-area top, so the ticker HUD covers its top and the jars are cut off. Instead, while crafting:
- the plate's top edge sits just below the ticker HUD, fully visible;
- the docked book's top edge sits at the Press apparatus region's bottom edge (scaled), so jars, still, burner, mortar, notebooks and press all stay visible and the book overlaps only the plate below the press;
- on a short screen where that leaves less than the current dock minimum height, the dock keeps its minimum height and rises over the press;
- the apparatus gauge popup centres in the visible plate area above the dock.

Undocked (not crafting) layout is unchanged: plate stays vertically centred.

**Blocked by:** 01 — Finish always visible (same layout function; dock bottom must already respect the nav bar).

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` — `_build_plate` (docked origin), `_build_run` (`dock_top`, `_DOCK_MIN_HEIGHT`, gauge `CenterContainer`)
- `data/hq_visuals.json` — `labBench.regions.apparatus_compression` (Press region; bottom = y + height in plate px). Derive from data, don't hardcode
- the ticker HUD's owning screen — find its height / bottom edge
- `docs/hq-diorama-vision.md` §5.1 — update the docked-layout note
- `tests/test_hq_lab_bench.gd`

**Status:** ready-for-agent

- [ ] Docked plate top = HUD bottom; no part of plate under the HUD
- [ ] Dock top = scaled Press region bottom when room allows
- [ ] Short screen: dock height = minimum, overlapping press
- [ ] Gauge popup centred between HUD bottom and dock top
- [ ] Undocked layout unchanged (existing tests still pass)
- [ ] Tests cover normal and short-screen dock_top
- [ ] §5.1 doc note updated; on-device check listed in report
