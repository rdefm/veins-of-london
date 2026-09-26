# 07 — Menu restyle, part 1: audit, shared style, Map drawer + HQ stash

**What to build:** Audit every menu still using the old placeholder aesthetic (orange rectangular buttons, flat panels) and record the list in this ticket. Build shared UI pieces matching the Map vein popover aesthetic: cream rounded card with soft shadow, muted grey labels, dark text, round icon buttons / quiet text buttons. Convert the Map controls drawer (Filters / Other / Legend / Close) and the HQ ore-store / personal-stash modal to it.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/ui.gd` (`button`), `scenes/components/vein_bubble.gd` (style source), `scenes/components/map_controls.gd`, `scenes/modals/hq_ore_readout_modal.gd`, `docs/ui-vision.md` §4–§7, `CODEMAP.md`.

**Status:** ready-for-agent

- [x] Audit list of all placeholder-styled menus added to this ticket (feeds 08)
- [x] Shared card/button pieces matching the vein popover, colours from palette tokens
- [x] Map controls drawer converted
- [x] HQ ore-store / stash modal converted
- [x] No behaviour change; existing map-controls and HQ tests pass

## Audit — placeholder-styled menus (feeds 08)

Placeholder = theme default orange `Button` (`theme/main_theme.tres`) or a plain theme `PanelContainer` via `UI.card()`. Shared pieces to convert with: `MapCardStyle.card()/section_label()/text_button()/option_row()/round_button()/style_check_button()`; off-map callers build inside `MapPalette.build_light()`.

Already fine: phone apps (Phone-OS chrome pass via `ContactCards.apply_phone_os_chrome`), map.gd, vein_list, vein_detail_panel, vein_bubble, map_legend, map_zoom_buttons, floorplan_view slots, combat_command_dock, event.gd, sell_menu_view. Converted here: map_controls.gd, hq_ore_readout_modal.gd.

**Modal shell**
- [ ] `scenes/components/modal_layer.gd` — dialog card is theme PanelContainer (flat, no shadow) + fallback Close. Biggest lever: restyles every modal card at once.

**Modals** (unstyled `UI.button` / `UI.symbol_button`)
- [ ] `archie_deal_result_modal.gd` — "Back to it"
- [ ] `combat_setup_modal.gd` — Fight, Cancel, ☐ toggle rows
- [ ] `craft_batch_result_modal.gd` — "Got it"
- [ ] `craft_components_menu_modal.gd` — Craft, Close
- [ ] `craft_result_modal.gd` — "Got it"
- [ ] `cultivate_result_modal.gd` — "Got it"
- [ ] `dial_load_complication_modal.gd` — recipe symbol_buttons, Cancel
- [ ] `hq_gym_modal.gd` — Close only
- [ ] `james_job_complete_modal.gd` — "Good."
- [ ] `james_job_offer_modal.gd` — Accept, Decline
- [ ] `james_job_short_modal.gd` — "Back to it"
- [ ] `lab_bench_modal_helpers.gd` — "Refine to tier N"
- [ ] `lab_bench_notes_modal.gd` — Close, `UI.card`
- [ ] `lab_bench_probe_result_modal.gd` — "Got it"
- [ ] `lab_bench_recipe_book_modal.gd` — Close, −/+ stepper, "Craft ×N", `UI.card`s
- [ ] `movement_craft_modal.gd` — ore symbol_buttons, Cancel
- [ ] `movement_swap_modal.gd` — movement symbol_buttons, Cancel
- [ ] `nadia_supply_modal.gd` — supply + cancel buttons
- [ ] `network_reference_modal.gd` — Close (Legend, opened from Map drawer)
- [ ] `network_sourcing_modal.gd` — Place order, Close
- [ ] `network_targets_modal.gd` — "Is it soft? £N", "Delay guards £N", Close
- [ ] `sale_result_modal.gd` — "Back to it"
- [ ] `seed_result_modal.gd` — "Got it"
- [ ] `sell_vein_quote_modal.gd` — Confirm sale, Cancel

**Screens**
- [ ] `hq.gd` — Defend (+ dev-only "Debug regions"), `UI.card`
- [ ] `hq_dial.gd` — Craft Components, "Seed as…", Unseat, Craft new Movement, Swap, Empty, `UI.card`
- [ ] `hq_door.gd` — "£N" buy, `UI.card`
- [ ] `hq_floorplan.gd` — Close, Installed, "£N", "Pay now (£N)", Assign/Unassign, "View all veins", 2 `UI.card`s
- [ ] `hq_lab_bench.gd` — ‹ › pager buttons
- [ ] `guild_marketplace.gd` — Buy ×N, Sell ×N, −/+ stepper, `UI.card`
- [ ] `combat.gd` — pacing button, post-combat Continue
- [ ] `title.gd` — New game, Load game, Debug, per-slot Load, `UI.card` slot panels
- [ ] `combat_prototype.gd` — 12 buttons, 8 `UI.card` (dev-only)

**Components**
- [ ] `bag_drawer.gd` — Close, item symbol_buttons, Equip/Unequip, `UI.card` weapon panel
- [ ] `map_bubble.gd` — text-only option rows (`UI.button`) and `_build_icon_label_button` (bare `Button.new()`); round circles already styled
- [ ] `contact_cards.gd` — only if a card ever renders outside the phone (today always Phone-OS-passed; nothing to convert)
