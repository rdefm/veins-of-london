# 11 — Receding full-squad staging

**What to build:** All six combatants of a full-squad fight are visible on the edge-to-edge stage in two receding diagonal groups: enemies farther back (higher, smaller), player and allies nearer the viewer (lower, larger), with every sprite a distinct tap target. Depth ordering is consistent (nearer sprites draw over farther ones) and no sprite is more than partly occluded. The one-enemy common case still composes sensibly. Sprite sizes stay proportional to the stage so the scene reads at 390 wide without the old two-column band split.

**Blocked by:** 10 — Location-keyed backdrop (needs the full-width stage with a real plate to compose against); 05 — Tap selection (sprite hit areas must remain valid targets).

**Relevant files:**
- `scenes/components/combat_stage.gd` — `PLAYER_BAND_WIDTH`, `ENEMY_BAND_WIDTH`, `COLUMN_GAP`, `FAN_*` constants, `_fan_local_rects`, `_sync_band`, `_build`, `_build_vignette`, `StageSlot.set_side`/mirroring
- `data/combat_visuals.json` — any staging anchors if made data-driven
- `tests/test_combat_screen.gd` — "stage_renders_every_living_enemy_up_to_squad_max", "fan_layout_is_diagonal_not_a_flat_row", "single_enemy_fight_still_fans_correctly…", "a_surviving_combatants_stage_slot_survives_a_kill…"
- `docs/combat-animation-vision.md` — §2.2 Squad roster and stage composition, §3 cast frame budget, §6.1 canvas sizes

**Status:** ready-for-agent

- [ ] Fixture with 3 enemies + player + 2 allies: six slots, each with a non-empty rect fully inside the stage
- [ ] Every enemy slot's bottom edge is above every friendly slot's bottom edge; enemy slot sizes are smaller than friendly ones
- [ ] Slots within a group step diagonally (x and y both change between neighbours)
- [ ] Pairwise overlap between any two slot rects is under 50% of the smaller rect's area
- [ ] Draw order puts nearer (lower) slots above farther ones
- [ ] Sprite tap hit areas from ticket 05 still resolve to the right combatant for all six
- [ ] Single-enemy and no-ally fixtures still place sprites plausibly (no sprite centred in empty space at the edge)
- [ ] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP row for `combat_stage.gd` updated
- [ ] Report lists on-device checks: crowded-target accuracy, readability against the plate
