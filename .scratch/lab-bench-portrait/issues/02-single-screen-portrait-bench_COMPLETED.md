# 02 — Single-screen portrait bench

**What to build:** The Lab bench is one screen using `assets/hq/lab-bench-with-equipment_portrait.png` (1024×1536). It is width-fit and vertically centred, and the bands above and below are filled with a colour matching the art's wall/floor. There are no stops, no ‹ › arrows, no pan tween and no stop caption. The back button stays top-left.

Tap regions sit on the painted objects:
- Jars left→right: `ore_time` (hourglass), `ore_fate` (dice), `ore_life` (sprout), `ore_physics` (lightning), `ore_emotion` (heart)
- Middle: `apparatus_heat` (burner, left), `apparatus_distilling` (retort + stand + flasks), `apparatus_grinding` (mortar, right)
- Bottom: `notebookRecipes` (orange book), `notebookExperiments` (blue book), `apparatus_compression` (vise, bottom-right)

Use traced polygons where a rect would overlap a neighbour (the retort spans the middle). The HQ region mapper tool and the `polygon` field already exist, see hq-rooms ticket 01. No placeholder boxes are drawn; the art is the visual.

Each jar shows a small numeric count badge (ore held). Selected jars keep the existing gold outline. Jar tap-to-select (max 2) and the jar→gear drag behave as today. Gear taps keep today's behaviour here; ticket 03 replaces it.

Nav state loses its stop concept: `labBenchNav.stop`, `LabBenchNav.STOPS` and `step()` are removed. Old saves carrying `stop` still load. The empty/some/plenty jar-sprite fields are dropped from the plate; the count badge replaces them. The old `assets/hq/lab_bench.png` and landscape `assets/hq/lab-bench-with-equipment.png` (plus `.import`) are deleted.

**Blocked by:** None — can start immediately

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` — `_build()` (stop/pan/arrow code), `_pan_diorama_to()`, `_label_ore_regions()`, `_ore_bucket()`, `_zone_at()`
- `systems/lab_bench_nav.gd` — `STOPS`, `step()`, `open()`
- `scenes/components/hq_diorama.gd` — `region_rects()`, `_draw()`, `_should_draw_placeholder()`, selected outline
- `data/hq_visuals.json` — `labBench` plate (image/width/height/regions) and its `_comment` keys
- `autoload/GameState.gd` — `labBenchNav` default (line ~63)
- `autoload/SaveManager.gd` — save-load tolerance of stale nav keys
- `scenes/screens/hq.gd` — `"lab"` zone → `LabBenchNav.open()`
- tests: `tests/test_hq_lab_bench.gd`, `tests/test_lab_bench_nav.gd`, `tests/test_hq_screen.gd` (~l.216), `tests/test_gamestate.gd` (~l.35)
- `docs/hq-diorama-vision.md` §5.1 Camera, §5.4 Ore containers
- `CODEMAP.md` rows `lab_bench_nav.gd`, `hq_lab_bench.gd`, `hq_visuals.json`

**Status:** ready-for-agent

- [ ] Bench renders the portrait art at full width, centred, filled bands, no arrows or caption
- [ ] Each of the 5 jars, 4 gear and 2 books is tappable on its painted object; the debug overlay shows the shapes
- [ ] Jar count badges show `player.orichalchum[type]`; selection outline works
- [ ] `stop` / `STOPS` / `step()` gone; an old save with `labBenchNav.stop` loads fine
- [ ] Old art files deleted; no remaining references
- [ ] §5.1 rewritten for the single portrait plate; CODEMAP updated
- [ ] Human on-device check: region alignment on jars, gear and books; badge legibility; band colours
