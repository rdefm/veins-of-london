# 02 — Combat and HQ art prefetch; shaders preloaded

**What to build:** Opening combat prep starts background loads of the fight's backdrop and the fighters' sprite sheets/posed frames, so the fight stage opens without a load stall. HQ diorama backdrop/sprites and the floorplan texture load the same way (request on screen entry, threaded get at draw, sync fallback). The combat stage's runtime shader `load()` calls become `preload` constants. No visible change. Source: code review 2026-11-21 item 9 (`.scratch/code-review/recommendations.md`).

Zero gameplay change: presentation only. Which backdrop/sprites a fight uses must be read from state/data exactly as combat_stage does today — reuse its existing path-resolution logic rather than duplicating it (extract to a small shared static func if needed).

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/combat_stage.gd` (shader loads ~431, 469, 2171, 2684; sprite/posed loads ~2778–2783; backdrop ~2811)
- `scenes/screens/combat_prep.gd` (entry point to kick off prefetch)
- `scenes/screens/combat_rounds.gd`
- `scenes/components/hq_diorama.gd` (~50, ~70)
- `scenes/components/floorplan_view.gd` (~45)
- `scenes/screens/hq.gd`, `scenes/screens/hq_floorplan.gd`

**Status:** ready-for-agent

- [ ] The four shader `load("res://shaders/...")` calls in combat_stage are `preload` constants
- [ ] Combat prep requests the upcoming fight's backdrop + sprite textures via `load_threaded_request`; combat_stage consumes them via `load_threaded_get`, sync `load` fallback when not requested/ready
- [ ] HQ diorama and floorplan textures use the same request/get/fallback pattern
- [ ] Path resolution is not duplicated between prep and stage
- [ ] Syntax check clean on touched files; full suite passes
- [ ] Report lists on-device checks: start a fight from prep (backdrop, all fighters, stun/VCR/rewind/black-hole shader effects look as before); open HQ and floorplan (art as before, no stall)
