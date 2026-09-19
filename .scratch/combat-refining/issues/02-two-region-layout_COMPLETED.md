# 02 — Two-region layout recomposition

**What to build:** Below the unchanged shared top bar, the combat screen becomes two roughly equal regions. Upper: the stage spans the full 390 logical width with no side margins, grey page framing or scroll inset, with the turn-order strip over it and a fixed reserved band for the selected card's expanded details (empty for now) so nothing below moves when a card expands later. Lower: one continuous near-white surface holding the existing Dial widget on the left at its current rendered size and hit geometry, and the existing command column on the right. Heading/context label and the pacing toggle remain reachable. Existing strip, dock and stage behaviour is otherwise unchanged in function — this is recomposition only, no restyling of cards or rows yet.

Dial usability wins over mathematical equality: if equal halves would force the Dial smaller, the lower region takes the space.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/combat.gd` — `_ready` (drops `UI.screen_body` scroll/margin flow for the stage), `_sync`, `_sync_footer`
- `scenes/components/combat_command_dock.gd` — `_init` anchors/offsets, `COMMAND_DOCK_*` constants, near-white surface background
- `scenes/components/combat_stage.gd` — `STAGE_WIDTH`, `STAGE_HEIGHT`, `STAGE_BORDER_WIDTH`, `_build` (inset/border drawing), `_build_vignette`
- `scenes/components/dial_widget.gd` — read only: `WIDGET_SIZE`, `HANDLE_DISPLAY_SIZE`, `RENDERED_WIDTH` are the baseline that must not change
- `scenes/components/ui.gd` — `screen_body`, `anchor_below_bars`, `anchor_full_rect`
- `tests/test_combat_screen.gd` — "command_deck_is_fully_on_screen…", "stage_sits_in_a_recessed_dark_inset…", "action_card_buttons_keep_their_own_compact_size…"
- `tests/test_dial_widget.gd` — baseline dimension/hit-region assertions
- `docs/ui-vision.md` §5 Family 4 — field-kit chrome rules for the command surface
- `.scratch/combat-refining/spec.md` — "Composition and appearance" items 1–3, 6–7

**Status:** ready-for-agent

- [ ] At 390×844 the stage's left and right edges coincide with the screen edges; no grey page framing visible
- [ ] Upper region (strip + stage + reserved detail band) and lower region (command surface) are within ~10% of each other in height, or the Dial's baseline size is the reason they are not
- [ ] Dial widget rendered size and touch regions are identical to the pre-change baseline (headless test asserts the constants and slot rects)
- [ ] Reserved detail band has a fixed height; toggling its content in a headless test moves neither the stage nor the Dial
- [ ] Lower region background is one continuous surface (no per-card panels visible behind the Dial)
- [ ] Heading/context label and pacing toggle still present and functional
- [ ] Top bar height/content untouched (no edits to shared bar components)
- [ ] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP rows for `combat.gd`, `combat_command_dock.gd`, `combat_stage.gd` updated if responsibility moved
