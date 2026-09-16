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
| combat.gd | Turn-based combat engine + rewind |
| combat_pacing.gd | Persisted normal/quick pacing toggle |
| combat_prototype.gd | Bounded combat experiment, Debug-app |
| consumables.gd | Out-of-combat healing effects |
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
| todo.gd | Notes checklist, driven by objectives |
| travel.gd | District travel (free) |
| vein_list.gd | Vein-portfolio list decision layer |
| vein_list_nav.gd | Vein list screen nav state |
| vein_trade.gd | Selling a vein outright to a faction |

## scenes/screens/*.gd — UI screens

`scenes/Main.gd` (scene root) boots autoloads/first screen, mounts the time-transition + alarm
overlays.

| File | Renders |
|---|---|
| combat.gd | Combat screen |
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
| phone.gd | Phone app grid, incl. BizBrief |
| placeholder.gd | Stand-in for a not-yet-built screen |
| title.gd | Title screen + load-game slot list |
| vein_list.gd | Vein-portfolio list |

## scenes/components/*.gd — reusable UI components

| File | Purpose |
|---|---|
| alarm_presentation.gd | Detects raid alarms; Phone pulse + vibration |
| app_tile.gd | Icon+label+badge+lock tile for the app grid |
| bag_drawer.gd | Global bottom-sheet bag drawer |
| combat_director.gd | Combat beat-queue playback director |
| contact_cards.gd | Shared card builders + OS chrome repaint |
| contract_card.gd | Draggable BizBrief Sales card |
| dial_widget.gd | Combat's Dial-casting widget |
| dot_matrix_board.gd | Amber-on-black dot-matrix board renderer |
| dot_matrix_font.gd | Bitmap font for dot_matrix_board.gd |
| haptics.gd | Adapter over `Input.vibrate_handheld()` |
| hq_diorama.gd | Generic plate/region artwork renderer |
| icons.gd | 8 drawn icon glyphs |
| map_bubble.gd | Popup listing tappable map options |
| map_canvas.gd | Network diagram draw pass |
| map_controls.gd | Filter-chip drawer + legend button |
| map_legend.gd | Persistent faction-colour key |
| map_zoom_buttons.gd | Floating +/- zoom control |
| modal_layer.gd | Dim background + card, dispatches on modal type |
| nav_bar.gd | Bottom nav dock (Phone·Map·HQ) |
| ore_glyphs.gd | Ore-symbol font glyph rendering |
| symbol_glyph.gd | Label-or-vector fallback for a symbol |
| time_transition.gd | Presentation queue (day/night atlas) |
| top_bar.gd | Header: day/phase, cash, notices |
| touch_scroll_container.gd | ScrollContainer, touch drag-scroll |
| turn_order_strip.gd | Combat turn-order display strip |
| ui.gd | Shared Control builders, time-cost labels |

## data/*.json

| File | Consumed by |
|---|---|
| approaches.json | approaches.gd |
| barometer.json | barometer.gd |
| collective_barks.json | collective.gd |
| combat_prototype.json | combat_prototype.gd |
| combat_visuals.json | combat.gd screen (backdrops, pose sheets) |
| constants.json | time_system.gd, jobs.gd |
| daily_cycle.json | time_transition.gd (day/night atlas) |
| dial.json | dial.gd |
| districts.json | widely read (sites, economy, factions, raiding) |
| enemies.json | combat.gd |
| faction_trade.json | economy.gd |
| factions.json | factions.gd, sites.gd, raiding.gd, debug_start.gd |
| home.json | home.gd, approaches.gd, contacts.gd |
| hq_visuals.json | hq_diorama.gd, hq*.gd screens |
| items.json | combat.gd, phone.gd, bag_drawer.gd |
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

Loaded by `GameData.gd` into `EVENTS` (`EVENT_IDS` + `DISTRICT_EVENT_IDS`). Each is the
cards/on_complete schema `systems/events.gd` runs — directly triggered story beats vs. weighted
district-deck entries (`systems/district_deck.gd`, a `deck` sub-object).

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
