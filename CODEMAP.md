# CODEMAP

What lives where. Update alongside any add/remove/repurpose (CLAUDE.md step 7). Each row: what a
file owns today, no history.

## autoload/*.gd — global singletons

| File | Purpose |
|---|---|
| EventBus.gd | Central signal bus — systems emit, screens redraw |
| GameData.gd | Loads/validates every `data/*.json` table at boot |
| GameState.gd | Pure state tree (Dicts/Arrays/primitives); screens read only |
| Rng.gd | Seeded RNG for every probabilistic system |
| SaveManager.gd | Save/load/autosave/export-import |
| Snapshots.gd | Bounded snapshot-stack helper backing rewind |

## systems/*.gd — static-func systems

Data file per system: see `data/*.json` below.

| File | Domain |
|---|---|
| approaches.gd | Unlocked physical approaches |
| archie_deals.gd | Archie's daily side-deal roll |
| bag.gd | Bag-drawer toggle |
| bank.gd | Cash transaction log |
| barometer.gd | Economic/social/political barometer + faction prefs |
| bench.gd | Lab discovery engine (type-set × approach) |
| bubble_layout.gd | Popup-position math for MapBubble |
| collective.gd | Collective faction doors, Nadia settlement |
| combat.gd | Turn-based combat engine + rewind. Resumable per-decision-point progression via `combat.turnCursor` + `advance_to_next_decision()`/`prime_decision_point()`/`conclude_decision_point()`, and a pure `project_queue()` read for the turn-order strip's occurrence horizon -- see REFERENCE.md §3.7a |
| combat_pacing.gd | Persisted normal/quick pacing toggle |
| combat_prototype.gd | Bounded combat experiment, Debug-app |
| consumables.gd | Healing Salve (out-of-combat) + Healing Burst (in or out); in-combat use_healing_burst() resolves the parked player turn-cursor entry via Combat.prime_decision_point()/conclude_decision_point() (R§3.7a) |
| contacts.gd | Relation, recruiting, room assignment, XP |
| contracts.gd | Sales contract delivery, priority, settlement |
| crafting.gd | Recipe crafting |
| cultivating.gd | Vein growth / cultivate / prune |
| debug_start.gd | Maximal-unlock debug state |
| debug_tools.gd | Debug phone-app state adjusters |
| dial.gd | Dial mechanic (Movements, charge economy) |
| district_bubble.gd | District tap-bubble decision |
| district_deck.gd | Weighted district event deck picker |
| districts.gd | Derived district info for Map tab |
| economy.gd | Selling (Archie lane + faction lane) |
| equipment.gd | Weapon equip/unequip |
| events.gd | Event-card runner + rewind, auto-discovers art |
| factions.gd | Faction joining |
| home.gd | Home tier/security/rooms/raid chance |
| jobs.gd | James's jobs, trust bands |
| lab_bench_nav.gd | Lab bench nav: stop, notebook, ore |
| map_events.gd | Map event queue + playback |
| map_hit_test.gd | Tap-hit geometry, Network diagram |
| map_layout.gd | Resolves stops vs. live sites/veins |
| map_nav.gd | Map drill-down nav (list → panel) |
| map_pins.gd | Contact map-pins for waiting events |
| map_routing.gd | Octilinear line-routing geometry |
| map_style.gd | Filter-chip re-styling math |
| map_view.gd | Persists Network camera |
| map_zoom.gd | Zoom-level math for the diagram |
| messages.gd | Messages data layer |
| modal.gd | Modal open/close state |
| morning_accounts.gd | Rollover capture, BizBrief routing |
| nav.gd | Screen navigation |
| notify.gd | Notifications append/evict |
| objectives.gd | Objective/questline evaluator |
| offers.gd | Sales offers: quoting, acceptance, expiry |
| payroll.gd | Daily wage payment (3 staff roles) |
| phone_apps.gd | Phone app-grid registry, incl. BizBrief |
| phone_nav.gd | Phone drill-down nav |
| preferences.gd | Saved accessibility prefs |
| progression.gd | Shared "award XP" ladder loop |
| raid_alarms.gd | Summaries + dispatch for raid alarms |
| raiding.gd | Vein stealth-check + raid resolution |
| relation_accrual.gd | Capped £ relation meter |
| rooms.gd | Daily lab/veinStation processing |
| sites.gd | Sites & prospecting |
| stash.gd | Personal stash vs. shared pools |
| station_bubble.gd | Site/vein-stop tap-bubble decision |
| time_system.gd | Time blocks, rest, daily tick |
| todo.gd | Notes checklist, driven by objectives; also reads state.world.sites directly for the Collective ledger section |
| travel.gd | District travel (free) |
| vein_list.gd | Vein-portfolio list decision layer |
| vein_list_nav.gd | Vein list screen nav state |
| vein_trade.gd | Selling a vein outright to a faction |

## scenes/screens/*.gd — UI screens

`scenes/Main.gd` (scene root) boots autoloads/first screen, mounts the time-transition + alarm
overlays.

| File | Renders |
|---|---|
| combat.gd | Combat screen: orchestrator over CombatStage/CombatCommandDock -- owns turn flow (turn-order strip), director bridging, and when a band sync happens |
| combat_prototype.gd | Minimal combat-prototype screen, Debug-app only |
| contacts.gd | Contacts tab, flag-gated actions |
| event.gd | Event-card screen (VN and non-VN layouts) |
| factions.gd | Factions tab |
| guild_marketplace.gd | Faction trading UI |
| hq.gd | HQ tab: bedsit plate, routes taps to sub-screens |
| hq_dial.gd | Dial loadout sub-view (Movements, Complications) |
| hq_door.gd | Security zone (lock/cameras/door/alarm/guard/ward) |
| hq_floorplan.gd | Rooms zone: room slots + contact assignment |
| hq_lab_bench.gd | Lab zone: notebook/ore/apparatus regions |
| map.gd | Map tab: diagram + district panel + sheet |
| phone.gd | Phone tab shell: OS background, home app grid + tile routing; dispatches open apps through scenes/phone_apps/phone_app_registry.gd |
| placeholder.gd | Stand-in for a not-yet-built screen |
| title.gd | Title screen + load-game slot list |
| vein_list.gd | Vein-portfolio list |

## scenes/components/*.gd — reusable UI components

| File | Purpose |
|---|---|
| alarm_presentation.gd | Detects raid alarms; Phone pulse + vibration |
| app_tile.gd | Icon+label+badge+lock tile for the app grid |
| bag_drawer.gd | Global bottom-sheet bag drawer |
| combat_command_dock.gd | Combat's lower command region: full-width near-white surface Panel holding the Dial/Complication-detail/action-card row, anchored to the true screen bottom |
| combat_director.gd | Combat beat-queue playback director |
| combat_stage.gd | Combat's full-width pixel stage: backdrop, subject slots, keypose one-shots, effect sheets, juice layer |
| contact_cards.gd | Shared card builders + OS chrome repaint |
| contract_card.gd | Draggable BizBrief Sales card |
| dial_widget.gd | Combat's Dial-casting widget |
| dot_matrix_board.gd | Amber-on-black dot-matrix board renderer |
| dot_matrix_font.gd | Bitmap font for dot_matrix_board.gd |
| haptics.gd | Adapter over `Input.vibrate_handheld()` |
| hq_diorama.gd | Generic plate/region artwork renderer |
| icons.gd | 8 drawn icon glyphs |
| map_bubble.gd | Popup listing tappable map options |
| map_canvas.gd | Network diagram: layout/stops/lines, hit-testing, static draw pass; delegates persistent halos and event-playback animations to map_halos.gd |
| map_halos.gd | Persistent vein-charge halo + the five event-playback animations (discover ripple, seed/claim ring, charge burst, drain collapse, join-line growth); owned by map_canvas.gd |
| map_controls.gd | Filter-chip drawer + legend button |
| map_legend.gd | Persistent faction-colour key |
| map_zoom_buttons.gd | Floating +/- zoom control |
| modal_layer.gd | Dim background + card; chrome + tap-outside dismiss. All content dispatched by type through scenes/modals/modal_registry.gd; unknown types get a placeholder card |
| nav_bar.gd | Bottom nav dock (Phone·Map·HQ) |
| ore_glyphs.gd | Ore-symbol font glyph rendering |
| symbol_glyph.gd | Label-or-vector fallback for a symbol |
| time_transition.gd | Presentation queue (day/night atlas) |
| top_bar.gd | Header: day/phase, cash, notices |
| touch_scroll_container.gd | ScrollContainer, touch drag-scroll |
| turn_order_strip.gd | Combat turn-order strip: one card per turn *occurrence* (Combat.project_queue(), R§3.7a), not per combatant -- repeated occurrences of the same combatant share the selected treatment. Drag scrolls the viewport only; a tap selects the tapped card's combatant (`handle_tap`/`handle_drag`) |
| ui.gd | Shared Control builders, time-cost labels, ui_action_red accent + bordered-panel/action-button StyleBoxFlat helpers |

## scenes/modals/*.gd — modal content, one script per type

| File | Purpose |
|---|---|
| modal_registry.gd | type id -> content script table; the only content path modal_layer.gd dispatches through |
| seed_result_modal.gd | Seed-attempt result card |
| cultivate_result_modal.gd | Cultivate-attempt result card |
| craft_result_modal.gd | Single-craft result card |
| craft_batch_result_modal.gd | Batch-craft result card, per-attempt list |
| sale_result_modal.gd | Archie/faction sale result card; close routes to Phone home |
| archie_deal_result_modal.gd | Archie deal-vein result card; close routes to Phone home |
| james_job_offer_modal.gd | James job offer card; Accept/Decline hand off to Jobs |
| james_job_short_modal.gd | James job "not enough stock" card |
| james_job_complete_modal.gd | James job payout card |
| sell_menu_modal.gd | Archie and faction sell/buy menus; Cancel clears sellState |
| sell_row_builders.gd | Row widgets shared by sell_menu_modal.gd (sell/buy-ore/vein rows, collapsible Ore/Items/Assets sections) |
| nadia_supply_modal.gd | Nadia ore-supply objective card |
| sell_vein_quote_modal.gd | Single-vein sale confirmation card |
| craft_components_menu_modal.gd | Movement-archetype picker; Craft hands off to movement_craft |
| movement_craft_modal.gd | Pick a calc type to attempt a Movement craft; pushes success/fail notices |
| movement_swap_modal.gd | Seat a Movement from movementInventory into the Dial |
| dial_load_complication_modal.gd | Load a crafted complication into the Dial |
| combat_setup_modal.gd | Debug raid setup: enemy template/count/tier + ally toggles |
| network_reference_modal.gd | Network Map legend |
| hq_ore_readout_modal.gd | Ore-store slip with raid-risk stamp + personal-stash move controls |
| hq_gym_modal.gd | Combat skill readout + Train action card |
| lab_bench_modal_helpers.gd | Refine controls + outcome headings shared by the lab-bench modals |
| lab_bench_recipe_book_modal.gd | Found recipes: cost/chance, batch qty, Craft, Refine |
| lab_bench_notes_modal.gd | Per-pairing survey notes with found-recipe refine rows |
| lab_bench_probe_result_modal.gd | Probe outcome card |

## scenes/phone_apps/*.gd — phone app views, one script per app

| File | Purpose |
|---|---|
| phone_app.gd | PhoneApp base: shell ref, build(content)/teardown() hooks, shared back button + refresh |
| phone_app_registry.gd | app id -> PhoneApp script table; the only dispatch path phone.gd uses |
| alarms_app.gd | Raid alarm rows: defend / leave undefended (two-tap) / decide later |
| bizbrief_app.gd | BizBrief: Brief tab (bank, operations, attention) + Manage tab (sales, production, procurement) |
| messages_app.gd | Single conversation: staged bubble reveal + contact action bar |
| notes_app.gd | Active questline checklists + Collective ledger section |
| factions_app.gd | Faction cards |
| ticker_app.gd | Barometer headlines + axis detail (push/pull, influence actions) |
| profile_app.gd | Stats, skills, equipment, motion/vibration toggles |
| saveload_app.gd | Save slots, export/import, New Game confirm |
| notifications_app.gd | Notification log with pending Defend buttons |
| bank_app.gd | Reynard's: balance + transaction log |
| property_app.gd | Harrow's: current HQ tier + next-tier upgrade |
| debug_app.gd | Debug Start-only tools: cash/calc/site spawners, combat launchers, relation adjusters |

## data/*.json

| File | Consumed by |
|---|---|
| approaches.json | approaches.gd |
| barometer.json | barometer.gd |
| collective_barks.json | collective.gd |
| combat_prototype.json | combat_prototype.gd |
| combat_visuals.json | combat_stage.gd (backdrops, pose sheets) |
| constants.json | time_system.gd, jobs.gd |
| daily_cycle.json | time_transition.gd (day/night atlas) |
| dial.json | dial.gd |
| districts.json | widely read (sites, economy, factions, raiding) |
| enemies.json | combat.gd |
| faction_trade.json | economy.gd |
| factions.json | factions.gd, sites.gd, raiding.gd, debug_start.gd |
| home.json | home.gd, approaches.gd, contacts.gd |
| hq_visuals.json | hq_diorama.gd, hq*.gd screens |
| items.json | combat.gd, profile_app.gd, bag_drawer.gd |
| map_layout.json | map_layout.gd, map_hit_test.gd |
| objectives.json | objectives.gd, todo.gd, collective.gd |
| offers.json | offers.gd (synthetic catalogue) |
| ore_types.json | widely read (economy, cultivating, sites, factions) |
| palette.json | GameData.gd (reference combat-art palette) |
| recipes.json | widely read (crafting, bench, combat, dial, jobs, rooms) |
| sites.json | sites.gd, collective.gd, objectives.gd |
| stealth.json | raiding.gd |
| vein_alarm.json | cultivating.gd |
| vein_growth.json | widely read (cultivating, events, sites, vein_trade) |
| vein_security.json | cultivating.gd, factions.gd |

## data/events/*.json (one file per event id, not listed individually)

Auto-discovered by `GameData.gd` into `EVENTS` — every `*.json` file under the directory is
loaded, keyed by filename; no id-list const to keep in sync. Each is the cards/on_complete schema
`systems/events.gd` runs — directly triggered story beats vs. weighted district-deck entries
(`systems/district_deck.gd`, a `deck` sub-object).

## tests/*.gd

Mirrors systems/ and screens/ 1:1: `tests/test_<name>.gd`. `tests/support/` holds shared helpers,
run via `scripts/run_tests.sh`. `test_runner.gd`/`test_base.gd` (entry + base class) are
infrastructure, excluded from discovery.

## scripts/*.sh and scripts/*.gd — tooling

`check_all.sh` syntax-checks .gd files, then runs `lint_tokens.sh` (row-cap + comment-vocab ban).
`run_tests.sh` runs the headless suite. `setup_godot.sh`/`setup_godot_ai.sh` set up the headless
binary and the godot-ai MCP server; `soak.sh` repeats the playthrough test. The two
`debug_combat_*_screenshot.gd` files are windowed dev screenshot harnesses;
`diagnose_115_timing.gd` is a hang-timing probe; `verify_map_camera_persistence.gd` is a
live-tree check.

## tools/*.py, *.html, *.js — asset/content pipeline tooling

`png_io.py` is a pure-stdlib PNG reader/writer. `make_palette_swatch.py`/`pack_daily_cycle.py`
render the palette swatch and daily-cycle atlas. `quest-editor.html`/`quest-editor-mobile.html`
are the desktop/mobile quest content editors (`data/events/*.json`); `test_quest_editor.js`
unit-tests the desktop editor.

## docs/*.md and docs/adr/

See CLAUDE.md's source-of-truth table for REFERENCE.md, M0-PORT.md, M1-LONDON.md,
M1.5-NETWORK-MAP.md, CONTENT-GUIDE.md, CONTEXT.md, docs/adr/. Not in that table: `VISION.md`,
`M3-CALC-DISCOVERY.md`/`device-plan-spec.md` (provisional drafts),
`hq-diorama-vision.md`/`combat-animation-vision.md`/`ART-BIBLE.md` (screen/art direction),
`BUGS.md`, `BUGHUNT-2026-07-17.md`, `android-setup.md`, `agents/*.md` (see CLAUDE.md's Agent
skills section). `docs/adr/0001`–`0005`: Network Map deferral, site/NPC-claim rules, app-icon
contract, NPC-vein abandonment removal, event-image contract.
