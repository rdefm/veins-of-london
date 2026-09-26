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
| SaveManager.gd | Save/load/autosave/export-import; backfills missing keys (pre-tenure homes load owned, bedsit rented), restores JSON ints, KO-clamps a loaded fight's selection, founder fix-ups (room→role, Archie recruited past home raid) |
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
| business_quest.gd | business_empire questline side effects (state.businessQuest): Beat 1/3/5/6/7/8 trigger texts, Beat 2 starter-offer chain, recurring offers (ore from Beat 3, Time Pearl from Beat 6; held open, reissued), Beat 8 closing payload from the latest payday record, James's crafting-skill set, Owen's crafting-event trigger. Rules: REFERENCE.md "Business Empire questline" |
| business_stats.gd | BizBrief Stats tab's daily tally (revenue, expenses, cultivator/player ore); rollover snapshot with productionLog items into `businessStats.days`, 10-day trim, zero-filled chart series |
| business.gd | Business pot (contract settlements while active; pays Sales calc purchases as `calc` expenses), weekly payday (Owen's wage, 3-way split, ledger), owed wages + pay-from-cash, Staff tab pay-terms/status labels |
| bench.gd | Lab discovery engine (type-set × approach) |
| bubble_layout.gd | Popup-position math for MapBubble |
| collective.gd | Collective faction doors, Nadia settlement, Collective questline beat triggers + Act 2 scripted vein losses, Hakim retake gate + site ruin (ruinedByFirm), T7 Firm provocation (timed Firm-targeting weight), Act 2 relation awards (T8 missions, alarm-defend daily cap), Act 2 gate + T14 spine reward (Hakim intel's weak-enemy-vein branch) + T15 closer delivery |
| combat.gd | Turn-based combat engine + rewind. Resumable progression via `combat.turnCursor` + `prime_`/`conclude_decision_point()`; pure `project_queue()` (no koed slots, empty after outcome; R§3.7a). Beats carry `occurrence` tags. `combat.selection` via `set_selection()`, `clamp_selection()` on KO/Rewind/load; `selection_block_reason()` gates commands. Stamps `combat.locationKey` |
| network_handler.gd | Network handler Targets (timed `collective.networkIntel` claim_bonus/security_freeze) and Sourcing (site delivered by handler text); pricing off `VeinTrade.quote()` |
| combat_pacing.gd | Persisted normal/quick pacing toggle |
| combat_prototype.gd | Bounded combat experiment, Debug-app |
| consumables.gd | Healing Salve (out-of-combat) + Healing Burst (in or out); in-combat use_healing_burst() resolves the parked player turn-cursor entry (R§3.7a) and heals an ally target instead of the player (R§3.7) |
| contacts.gd | Relation, recruiting (incl. story `force_recruit`), room assignment, founder staff roles (`set_role`/`role_of`/`available_roles`), capped XP, ally combat kit + per-day ally Dial charges (`daily_dial_regen()`) |
| contracts.gd | Sales contract delivery, priority, settlement (paid to the business pot while active); per-contract `buyCalc` shortfall purchases from the cheapest open faction lanes, paid from the pot; unattended-proof taint (`playerAssisted`) and `qualified` settlements |
| crafting.gd | Recipe crafting |
| cultivating.gd | Vein growth / cultivate / prune |
| debug_start.gd | Maximal-unlock debug state |
| debug_tools.gd | Debug phone-app state adjusters; `fire_event()` preps any event (state-path veins/sites, addressed contacts, raid/reveal site context) then starts it |
| dial.gd | Dial mechanic (Movements, charge economy) |
| district_bubble.gd | District tap-bubble decision |
| district_deck.gd | Weighted district event deck picker |
| districts.gd | Derived district info for Map tab |
| economy.gd | Selling (Archie lane + faction lane), faction-lane buying (pricing, lane access, ore receipt) |
| equipment.gd | Weapon equip/unequip |
| events.gd | Event-card runner + rewind, auto-discovers art |
| factions.gd | Faction joining |
| home.gd | Home tier/tenure/security/rooms/raid chance; daily bill base (rent or utilities); arrears countdown; rent/buy/buy-out/downgrade tier moves via shared `change_tier` (room wipe, security loss); per-slot room purchase/replacement (`set_room_use`); daily raid roll, alarm queue/expiry, and alarm-defend win/loss resolution (R§3.8) |
| jobs.gd | James's jobs, trust bands |
| lab_bench_nav.gd | Lab bench nav: stop, notebook, ore |
| map_events.gd | Map event queue + playback |
| map_hit_test.gd | Tap-hit geometry, Network diagram |
| map_layout.gd | Resolves stops vs. live sites/veins |
| map_nav.gd | Map drill-down nav (list → panel → site sheet or vein detail panel, mutually exclusive) |
| map_pins.gd | Contact map-pins for waiting events |
| map_routing.gd | Octilinear line-routing geometry |
| map_style.gd | Filter-chip re-styling math |
| map_view.gd | Persists Network camera |
| map_zoom.gd | Zoom-level math for the diagram |
| messages.gd | Messages data layer + conversation-index projections and total unread count |
| modal.gd | Modal open/close state; holds an event deferred behind a modal flow (`followEvent`) and starts it on close |
| morning_accounts.gd | Rollover capture (incl. arrears exceptions and countdown, payday statement, wage shortfalls), per-block staff output accumulation, BizBrief routing, arrears/payday/wage-prompt labels |
| nav.gd | Screen navigation |
| notify.gd | Notifications append/evict |
| objectives.gd | Objective/questline evaluator; all_of live-condition, template_periods_completed (Beat 6) and recurring_proof (Beat 7) objectives + their ToDo checklist rows |
| offers.gd | Sales offers: quoting, acceptance, expiry |
| owen_texts.gd | Owen's random texts: rollover scheduler (2-3 day interval, paused while he isn't working), unplayed-then-LRU pick, vein templating from his cultivator list, reply choices granting cultivating XP on a correct answer |
| payroll.gd | Daily wage payment for room-staffed hires (founders exempt); `is_working()` gate for staff actions (false while the business owes wages) |
| phone_apps.gd | Phone main-grid roster/order/labels + badge-config projection |
| phone_nav.gd | Phone app/index/thread drill-down nav |
| preferences.gd | Saved presentation prefs in `meta` (reduced motion, vibration, Map dark mode) + carry_forward() so event Rewind never flips them |
| progression.gd | Shared "award XP" ladder loop |
| raid_alarms.gd | Summaries + dispatch for raid alarms |
| raiding.gd | Vein stealth-check + raid resolution |
| relation_accrual.gd | Capped £ relation meter |
| rooms.gd | Per-block staff step (one action per cultivator, then producers take turns crafting until targets met or ore short), writes/trims `productionLog`, Production targets/priority and when they are settable, per-cultivator vein lists (`cultivatorVeins`) and per-vein targets |
| sites.gd | Sites & prospecting |
| stash.gd | Personal stash vs. shared pools |
| station_bubble.gd | Site/vein-stop tap-bubble decision |
| time_system.gd | Time blocks (each runs the staff block step), rest, daily tick (tenure-aware home bill, arrears + interest, forced one-tier downgrade per ADR 0006) |
| todo.gd | ToDo-app sections per questline (Tutorial, Collective, Business Empire) with active/done/placeholder status + default expansion, "n of N" detail for count objectives, all_of checklist sub-items; Collective section carries the ledger read from state.world.sites |
| travel.gd | District travel (free) |
| vein_list.gd | Vein-portfolio list decision layer |
| vein_list_nav.gd | Vein list screen nav state |
| vein_trade.gd | Selling a vein outright to a faction |

## scenes/screens/*.gd — UI screens

`scenes/Main.gd` (scene root) boots autoloads/first screen, mounts the time-transition + alarm
overlays.

| File | Renders |
|---|---|
| combat.gd | Combat screen: orchestrator over CombatStage (fills the upper region)/CombatCommandDock -- owns turn flow, director bridging, band sync. Keeps one persistent strip and steps its queue beat by beat during (and Rewind) playback. `_select_target()` is the sole tap->`Combat.set_selection()` route; a stage tap during playback fast-forwards |
| combat_prototype.gd | Minimal combat-prototype screen, Debug-app only |
| contacts.gd | Contacts app inside PhoneDeviceShell; alphabetic directory with inline flag-gated actions |
| event.gd | Event-card screen (VN and non-VN layouts) |
| factions.gd | Factions tab |
| guild_marketplace.gd | Faction trading UI |
| hq.gd | HQ tab: bedsit plate, routes taps to sub-screens |
| hq_dial.gd | Dial loadout sub-view (Movements, Complications) |
| hq_door.gd | Security zone (lock/cameras/door/alarm/guard/ward) |
| hq_floorplan.gd | Noticeboard: tiers with a plan show FloorplanView (tap slot → choose/replace use); others show the room-tile grid. Contact assignment for staffed rooms |
| hq_lab_bench.gd | Lab zone: notebook/ore/apparatus regions |
| map.gd | Map tab: full-bleed diagram (top board to nav dock) with floating menu button, legend and zoom pill in Map chrome tokens; district panel + sheet |
| phone.gd | Phone tab controller: mounts PhoneDeviceShell, owns four-column home grid + home-only Phone/Messages/Settings dock, live badge-count projections + tile routing, dispatches apps through phone_app_registry.gd |
| placeholder.gd | Stand-in for a not-yet-built screen |
| title.gd | Title screen + load-game slot list |
| vein_list.gd | Vein-portfolio list (map_card_style.gd-skinned, always light via MapPalette.build_light) |

## scenes/components/*.gd — reusable UI components

| File | Purpose |
|---|---|
| alarm_presentation.gd | Detects raid alarms; Phone pulse + vibration |
| app_tile.gd | Normalised icon+label+numeric-count-badge+lock tile for phone launchers |
| bag_drawer.gd | Global bottom-sheet bag drawer; in combat, item buttons disable (with reason) per `Combat.selection_block_reason()` |
| combat_command_dock.gd | Combat's lower command region: full-width near-white surface Panel holding the Dial beside flat 1px-ruled command rows (Complication readout, Attack, Item, Leg it), anchored to the true screen bottom; Attack/Item disabled per the current selection |
| combat_director.gd | Combat beat-queue playback director; holds a data-driven pause (combat_visuals pacing.turnPause) between combatants' turns |
| combat_stage.gd | Combat pixel stage: backdrop (location -> context -> palette); slots in two receding diagonal groups (enemies back/smaller), fitted to each sprite's visible figure, depth-sorted; keypose one-shots (sheet, `images` list, or random attack `variants`; player = `templates[player.model]`), effects, juice layer. `StageSlot` taps emit `subject_tapped`; selected slot draws an arrow |
| contact_cards.gd | Shared contact/faction card builders (incl. handler card, Owen card, Targets/Sourcing, Nadia's ledger + "Go with Nadia"), inline Contacts action-row layout, OS chrome repaint |
| contract_card.gd | Draggable BizBrief Sales card |
| line_chart.gd | One-series `_draw` line chart (palette-id colour, max label, first/last day) for BizBrief Stats |
| floorplan_view.gd | Estate-agent plan for a home tier from floorplans.json; static, or with tappable slot overlays showing current use |
| dial_widget.gd | Combat's Dial-casting widget |
| dot_matrix_board.gd | Amber-on-black dot-matrix board renderer |
| dot_matrix_font.gd | Bitmap font for dot_matrix_board.gd |
| haptics.gd | Adapter over `Input.vibrate_handheld()` |
| hq_diorama.gd | Generic plate/region artwork renderer; outlines regions flagged `selected` |
| icons.gd | 13 drawn icon glyphs |
| map_bubble.gd | Popup listing tappable map options; paper-card frame and round action-icon states come from map_card_style.gd |
| map_card_style.gd | Shared vein-popover card family: card tokens (via map_palette.gd), card/inset/action-circle styleboxes, card()/style_panel(), section_label(), text/symbol_text/chip buttons, option rows, round_button()/stepper(), footer(), check-button + symbol tinting. The one button/card look for every non-phone menu; off-map callers build inside MapPalette.build_light |
| map_canvas.gd | Network diagram: layout/stops/lines, hit-testing, static draw pass; tweens a vein's fullness ring on EventBus.vein_cultivated; delegates persistent halos and event-playback animations to map_halos.gd |
| map_halos.gd | Persistent vein-charge halo + the five event-playback animations (discover ripple, seed/claim ring, charge burst, drain collapse, join-line growth); owned by map_canvas.gd |
| map_controls.gd | Map controls drawer (map_card_style.gd-skinned): filters, faction isolate, pacing, Dark map toggle, legend button |
| map_palette.gd | MapPalette: resolves Map palette tokens (data/map_palette.json) for the current light/dark mode (`meta.mapDarkMode`), plus faction/ore colours with optional dark-only overrides; every Map-tab colour reads through it; build_light() scopes a light-only build for off-Map reusers |
| map_legend.gd | Persistent faction-colour key; restyles in place on a dark-mode toggle |
| map_zoom_buttons.gd | Floating +/- zoom control; restyles in place on a dark-mode toggle |
| modal_layer.gd | Dim background + light map_card_style.gd card (content built inside MapPalette.build_light); mounts the dedicated Trade sheet for sell_menu, and dispatches other content through modal_registry.gd; tap-outside dismiss |
| nav_bar.gd | Bottom nav dock (Phone·Map·HQ); swaps to MapPalette dark chrome tokens while the Map tab shows with Map dark mode on |
| ore_glyphs.gd | Five canonical ore silhouettes as hand-drawn vectors; bundled-font coverage probe for non-map symbol fallback |
| phone_device_shell.gd | Persistent rounded simulated-phone frame: clipped display, approved London wallpaper, fixed status/widget chrome, dark opened-app surface + shared/custom content mounts |
| phone_home_dock.gd | Home-only translucent three-destination Phone/Messages/Settings dock |
| symbol_glyph.gd | Label-or-vector fallback for a symbol |
| time_transition.gd | Transient time queue, input guard, dimmed circular park/sky/sun/moon presentation |
| top_bar.gd | Header: day/phase, cash, notices |
| touch_scroll_container.gd | ScrollContainer, touch drag-scroll |
| turn_order_strip.gd | Combat turn-order strip: one card per projected turn occurrence. Tap selects; drag scrolls (offset survives re-configure). Selected card grows into a reserved band on the decision turn only; uniform during playback. Street-sign styling, damage decals, HP ghost drain, `_reveal_pos()`, and playback reflow via `playback_occurrences()` + `advance_to()` |
| ui.gd | Shared Control builders, time-cost labels, ui_action_red accent + bordered-panel/action-button StyleBoxFlat helpers |
| vein_bubble.gd | Compact player-vein tap bubble: pin-anchored card, Lv segments, condition needle with 50/90+ scale, outline development/raid cues, round Harvest (light/hard chooser)/Cultivate actions, cultivator picker + hold-target stepper (via Rooms) while anyone holds Cultivation; tapping the info area opens vein_detail_panel.gd instead of running an action |
| vein_detail_panel.gd | Floating map_card_style.gd-skinned vein detail (mapNav.selectedVeinId): compact level/location, condition, drift/development/raid/security cues, three icon action tiles, security/alarm/Defend; reuses VeinBubble's level/condition builders |

## scenes/modals/*.gd — modal content, one script per type

| File | Purpose |
|---|---|
| modal_registry.gd | type id -> content script table; the only content path modal_layer.gd dispatches through |
| seed_result_modal.gd | Seed-attempt result card |
| craft_result_modal.gd | Single-craft result card |
| craft_batch_result_modal.gd | Batch-craft result card, per-attempt list |
| sale_result_modal.gd | Archie/faction sale result card; close plays a deferred quest event if one is queued, else routes to Phone home |
| archie_deal_result_modal.gd | Archie deal-vein result card; close routes to Phone home |
| james_job_offer_modal.gd | James job offer card; Accept/Decline hand off to Jobs |
| james_job_short_modal.gd | James job "not enough stock" card |
| james_job_complete_modal.gd | James job payout card |
| sell_menu_modal.gd | Trade modal registry adapter and Cancel action that clears sellState |
| sell_menu_view.gd | Trade-only sheet: sell/buy and category tabs, Map ore glyphs, grouped item tiers, sticky totals and review; invokes existing trade systems |
| nadia_supply_modal.gd | Nadia ore-supply objective card |
| network_targets_modal.gd | Handler Targets picker: faction veins, soft/freeze questions |
| network_sourcing_modal.gd | Handler Sourcing order: ore type + minimum tier |
| sell_vein_quote_modal.gd | Single-vein sale confirmation card |
| craft_components_menu_modal.gd | Movement-archetype picker; Craft hands off to movement_craft |
| movement_craft_modal.gd | Pick a calc type to attempt a Movement craft; pushes success/fail notices |
| movement_swap_modal.gd | Seat a Movement from movementInventory into the Dial |
| dial_load_complication_modal.gd | Load a crafted complication into the Dial |
| combat_setup_modal.gd | Debug combat setup: fight type (`Combat.DEBUG_SETUP_CONTEXTS`), location override for backdrop preview, enemy template/count/tier + ally toggles; calls `Combat.start_debug_combat()` |
| network_reference_modal.gd | Network Map legend |
| hq_ore_readout_modal.gd | Ore-store slip with raid-risk stamp + personal-stash move controls, map_card_style.gd-skinned (always light) |
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
| bizbrief_app.gd | BizBrief tabs: Brief (bank, payday, wage prompt, operations, attention); Manage (offers, delegation, buy-calc, production targets + log, cultivator procurement); Staff once `bizStaffTabOpen` (role, skills, pay terms, status, role picker, Pay now); Stats while pot active (4 line charts, ore source toggle) |
| messages_app.gd | Conversation master list + single-thread staged bubble reveal/action bar (incl. Owen's text reply choices) |
| todo_app.gd | ToDo app: collapsible questline sections from Todo, all_of checks as indented sub-rows; session-only expand/collapse overrides in a static var |
| factions_app.gd | Faction cards |
| ticker_app.gd | Barometer headlines + axis detail (push/pull, influence actions) |
| profile_app.gd | Stats, skills, equipment |
| dialer_app.gd | Phone recent-calls placeholder; no telephony state/actions |
| settings_app.gd | Reduced-motion and alarm-vibration preference controls |
| saveload_app.gd | Save slots, export/import (with copy-to-clipboard), New Game confirm |
| notifications_app.gd | Notification log with pending Defend buttons |
| bank_app.gd | Reynard's: oxblood-gradient balance panel (branded header, calc_gold figure) + day-grouped hairline transaction ledger, newest first |
| property_app.gd | Harrow's: every tier as a listing in ladder order, each led by its `image` photo (placeholder if empty/unloadable); the current tier is the YOUR PLACE card (daily cost, buy-out, floorplan, arrears). Other listings open particulars (floorplan, copy, rent/buy to that tier via `Home.rent_to`/`buy_to`, bill previews, losses) |
| debug_app.gd | Debug Start-only tools: cash/calc/site spawners, combat launchers, one relation block (dropdown over every contact + faction, shows current relation, applies a delta), any-event trigger picker |

## data/*.json

| File | Consumed by |
|---|---|
| approaches.json | approaches.gd |
| barometer.json | barometer.gd |
| collective_barks.json | collective.gd |
| combat_prototype.json | combat_prototype.gd |
| combat_visuals.json | combat_stage.gd (locationBackdrops, backdrops, pose sheets, stage.spriteScale); combat_director.gd (pacing.turnPause) |
| constants.json | time_system.gd, jobs.gd, GameState.gd, contacts.gd (contacts roster incl. handler/owen; founder roleFlags, skillCaps), business.gd (payday interval, weekly wages), rooms.gd (productionLogDays), business_stats.gd (businessStatsDays) |
| daily_cycle.json | time_transition.gd (circle layout, sky clips, colours, timing) |
| dial.json | dial.gd |
| districts.json | widely read (sites, economy, factions, raiding) |
| enemies.json | combat.gd |
| faction_trade.json | economy.gd |
| factions.json | factions.gd, sites.gd, raiding.gd, debug_start.gd |
| home.json | home.gd, approaches.gd, contacts.gd, property_app.gd (tier `image` listing photos) |
| floorplans.json | GameData.gd + floorplan_view.gd (per-tier plan asset, size, slot rects) |
| hq_visuals.json | hq_diorama.gd, hq*.gd screens |
| items.json | combat.gd, profile_app.gd, bag_drawer.gd |
| map_layout.json | map_layout.gd, map_hit_test.gd |
| map_palette.json | GameData.gd (validated) + map_palette.gd (Map tab light/dark colour tokens, faction/ore dark overrides) + map_controls.gd (`darkModeLabel`) |
| objectives.json | objectives.gd, todo.gd, collective.gd, business_quest.gd |
| offers.json | offers.gd (synthetic catalogue), business_quest.gd (biz_starter_* chain + Archie nudge text, biz_recurring_* from Beat 3/6) |
| ore_types.json | widely read (economy, cultivating, sites, factions) |
| owen_texts.json | owen_texts.gd (text pool, reply options, interval days) |
| palette.json | GameData.gd (reference combat-art palette) |
| phone_home.json | GameData.gd + phone_device_shell.gd (fixed wallpaper/status/widget presentation; no GameState or host-service data) |
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

`data/events/_to_be_coded/col_hakim_intel_*.json` holds five unregistered Hakim intel
prose variants generated with the quest editor builder. Implementation briefs are in
`data/events/_to_be_coded/drafts/*.notes.md`; these drafts are not loaded by the game.

## assets/phone/

| File | Purpose |
|---|---|
| phone-wallpaper.jpg | Approved runtime Phone-home wallpaper, aspect-filled inside PhoneDeviceShell's clipped display |
| icons/<app_id>.png | 128×128 alpha PNG launcher icons keyed by exact app id, loaded via `AppTile.load_icon()` (ADR 0003); regenerated by `tools/make_phone_app_icons.ps1` |
| source/ | Supplied logo artwork the icon tool normalises; `.gdignore`d, never loaded at runtime |

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

`png_io.py` is a pure-stdlib PNG reader/writer. `make_palette_swatch.py` renders
the palette swatch; `pack_daily_cycle.py` preserves the retired cycle-atlas pipeline.
`quest-editor.html`/`quest-editor-mobile.html`
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
