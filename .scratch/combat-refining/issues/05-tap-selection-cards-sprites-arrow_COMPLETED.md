# 05 — Tap selection: cards + sprites, expanded card, subtle arrow

**What to build:** Tapping any occurrence card or any combatant sprite on the stage selects that combatant — player, ally or enemy — through a single system call that persists the selection per ticket 01's representation (an enemy selection keeps driving the existing focused-enemy semantics). The selected combatant's cards grow slightly and extend down into the reserved detail band from ticket 02, showing exact HP, status effects and, for enemies, telegraphed intent; unselected cards keep name, level where available, HP bar and faction line. The selected sprite is marked with a small arrow above it; the yellow selection rectangle/glow is removed and not replaced by any other cue. Tapping a sprite whose nearest upcoming card is off-screen scrolls the strip so that card is visible. Tapping the stage during playback still fast-forwards the current beat rather than selecting.

**Blocked by:** 01 — Canonical contract amendments; 04 — Occurrence queue cards.

**Relevant files:**
- `systems/combat.gd` — `set_focused_enemy` → generalised selection API, `_clamp_focused_enemy_index`, `push_combat_snapshot`/`_restore_from_snapshot` (selection joins the snapshot)
- `scenes/components/combat_stage.gd` — `StageSlot` (`mouse_filter` is IGNORE today, `is_focused`, `_draw_overlay`), `sync`, `_enemy_display_entries`, `_player_display_entries`, `_sync_band`, `resolve_target_slot`
- `scenes/components/turn_order_strip.gd` — `NameplateCard` (`is_focused`, `shows_exact_hp`, `status_lines`, `telegraph_*`), `_build_card_content`, `_status_lines_for`, expanded-card sizing into the reserved band, reveal-card scroll helper
- `scenes/screens/combat.gd` — `_strip_selected_key`, `_selected_strip_pos`, `_on_strip_selection_changed`, `_on_stage_gui_input`
- `tests/test_combat_screen.gd` — "focused_enemy_index_is_the_only_slot_flagged_for_the_glow", "glow_never_applies_to_the_player_or_ally_band", "swiping_the_strip_to_the_player_card_is_inert…", "strip_selection_survives_a_real_state_changed_refresh…"
- `tests/test_turn_order_strip.gd` — focused-card detail cases
- `tests/test_combat.gd` — selection API cases
- `docs/REFERENCE.md` — §2 selection representation, §3.7a Targeting (as amended by 01)
- `docs/combat-animation-vision.md` — §2.2, §2.4 as amended by 01

**Status:** ready-for-agent

- [ ] Tapping a card and tapping that combatant's sprite leave identical selection state; player, ally and enemy are all selectable
- [ ] Selection is written only via the system API; screen tests confirm no direct state mutation
- [ ] Selected card is taller/wider than unselected and shows exact HP, statuses, enemy intent; unselected cards show no exact HP
- [ ] Expanded card occupies the reserved band; stage and Dial positions unchanged before/after selection (headless rect assertions)
- [ ] Exactly one sprite carries the arrow; no slot draws the old selection rectangle
- [ ] Selecting a sprite whose nearest card is beyond the visible width scrolls the strip until that card is visible
- [ ] Stage tap during director playback fast-forwards and does not change selection
- [ ] Selection survives an unrelated `state_changed` refresh and is restored by Rewind
- [ ] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP rows updated
