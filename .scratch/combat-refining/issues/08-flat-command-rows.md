# 08 — Flat command rows restyle

**What to build:** The right side of the white command surface becomes a column of equally weighted icon-and-label rows separated by fine horizontal rules: the selected Complication (or "Empty" / "No Dial") first, then Attack, Item, Leg it. No individual rounded cards, enamel borders, weathering, screws or extra emphasis on Attack. Available rows use the existing pillar-box red accent for icon and label; disabled rows recede clearly (muted colour, no rule change). Every row has visible pressed and focus states. Complication details, the pacing toggle and the context label remain reachable. Text uses the shared UI sans; icons are the existing vector glyphs.

**Blocked by:** 02 — Two-region layout.

**Relevant files:**
- `scenes/components/combat_command_dock.gd` — `_build_action_deck`, `_build_complication_detail`, `_build_action_card`, `_build_card_bar`, `_ACTION_CARD_ICON_SIZE`
- `scenes/components/ui.gd` — `action_colour`, `ACTION_DISABLED_COLOUR`, `ACTION_CARD_FILL`, `action_card_panel_style`, `style_action_button`, `icon_glyph_control`, `card`
- `scenes/components/icons.gd` — `draw_attack`, `draw_bag`, `draw_run`
- `data/palette.json` — `ui_action_red`, any new rule/surface tokens
- `tests/test_combat_screen.gd` — "command_deck_renders_attack_item_and_run_as_cards…", "attack_card_uses_ui_action_red…", "disabled_item_card_reads_muted_grey…", "action_card_buttons_keep_their_own_compact_size…"
- `docs/ui-vision.md` — §5 Family 4 field-kit HUD chrome, §6 Colour rules, §7 Typography
- `docs/combat-animation-vision.md` — §2.5 as amended by 01

**Status:** ready-for-agent

- [ ] Four rows present with the labels Complication-or-Empty / Attack / Item / Leg it; each row's height and label size are equal
- [ ] Rows are separated by 1px rules; no row draws its own rounded panel or border
- [ ] Available rows use `ui_action_red` for icon and label; disabled rows use the muted colour (existing tests re-pointed at the new nodes)
- [ ] Pressed and focus stylebox states differ visibly from normal (headless: stylebox overrides exist and differ)
- [ ] Complication detail, pacing toggle and context label still exist and respond
- [ ] New colour/spacing values live in `palette.json` or `ui.gd` constants, not inline literals
- [ ] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP row for `combat_command_dock.gd` updated
- [ ] Report lists on-device checks: equal visual weight, disabled legibility, thumb-sized hit areas
