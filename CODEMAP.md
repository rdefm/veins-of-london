# CODEMAP

Generated index of what lives where. Update this alongside any file you add/remove/repurpose under systems/, screens/, scenes/, autoload/, or data/ (see CLAUDE.md workflow step 7).

## autoload/*.gd — global singletons

| File | Purpose |
|---|---|
| EventBus.gd | Central signal bus (`state_changed`, `screen_changed`) — systems emit, screens redraw |
| GameData.gd | Loads/validates every `data/*.json` table once at boot into typed consts |
| GameState.gd | The pure state tree (Dicts/Arrays/primitives only) — systems read/write, screens read only |
| Rng.gd | Seeded RNG — every probabilistic system must draw from here, never randi/randf directly |
| SaveManager.gd | Save/load/autosave/export-import (3 manual slots + 3 rotating autosaves) |
| Snapshots.gd | Generic bounded snapshot-stack helper backing combat rewind + event rewind |

## systems/*.gd — static-func systems

| File | Domain | Data source |
|---|---|---|
| approaches.gd | Which physical approaches (heat/grinding/compression/distilling) player knows | approaches.json, home.json |
| archie_deals.gd | Archie's daily "tag along on his sale" side-deal roll | districts.json, ore_types.json |
| bag.gd | Global bag-drawer open/closed toggle | — |
| bank.gd | Cash transaction log (Reynard's phone app) | — |
| barometer.gd | Economic/social/political barometer state + faction preferences | barometer.json |
| bench.gd | Lab discovery engine — (type-set × approach) cells | recipes.json |
| bench_nav.gd | Lab screen drill-down nav state | — |
| bubble_layout.gd | Pure popup-position math for MapBubble | — |
| collective.gd | Collective faction's 3 vendor doors (Des/Nadia/Hakim) trade + Act 1 triggers | collective_barks.json, districts.json, objectives.json, sites.json |
| combat.gd | Turn-based combat + rewind | enemies.json, items.json, recipes.json |
| consumables.gd | Out-of-combat healing item effects (salve/burst) | — |
| contacts.gd | Relation, recruiting, room assignment, contact XP | vein_growth.json, recipes.json (xp level ladders) |
| crafting.gd | Recipe crafting (not time-block gated) | recipes.json |
| cultivating.gd | Vein growth / cultivate / prune | vein_growth.json, vein_security.json, vein_alarm.json, ore_types.json |
| debug_start.gd | Maximal-unlock debug state | factions.json, ore_types.json, vein_growth.json |
| debug_tools.gd | Debug phone-app state adjusters | — |
| dial.gd | Dial device mechanic (seed/craft Movements, charge economy) | dial.json, recipes.json, ore_types.json |
| district_bubble.gd | Map district tap-bubble decision layer (Prospect / View Veins) | districts.json |
| district_deck.gd | Weighted per-district event deck picker | data/events/*.json (via GameData.EVENTS) |
| districts.gd | Derived district info for Map tab's district list | districts.json |
| economy.gd | Selling (Archie lane + generic faction lane) | districts.json, faction_trade.json, ore_types.json, recipes.json (consumable prices) |
| equipment.gd | Weapon equip/unequip | — |
| events.gd | Event-card runner + rewind (narration/speaker/tension/resolution/craft/choice cards) | data/events/*.json, vein_growth.json |
| factions.gd | Faction joining | districts.json, factions.json, ore_types.json, vein_growth.json, vein_security.json |
| home.gd | Home tier/security/rooms/raid | home.json |
| jobs.gd | James's jobs, trust bands | recipes.json, constants.json (trust bands) |
| map_events.gd | Map event queue + playback sequencing | — |
| map_hit_test.gd | Tap-hit-testing geometry for the Network diagram | map_layout.json |
| map_layout.gd | Resolves map_layout.json stop slots against live sites/veins | map_layout.json, districts.json |
| map_nav.gd | Map tab drill-down nav state (district list → panel → site/vein sheet) | — |
| map_pins.gd | Contact map-pins for events awaiting at an address | data/events/*.json |
| map_routing.gd | Pure deterministic octilinear line-routing geometry | — |
| map_style.gd | Filter-chip re-styling math (Ownership/Type/Growth/Security/Faction isolate) | — |
| map_view.gd | Persists Network map camera (zoom + scroll) across navigations | — |
| map_zoom.gd | Pure zoom-level math for the Network diagram | — |
| messages.gd | Messages phone-app data layer (threads + pending follow-ups) | — |
| modal.gd | Modal open/close state | — |
| nav.gd | Screen navigation (currentScreen) | — |
| notify.gd | Notifications-list append/evict helpers | — |
| objectives.gd | Objective/questline evaluator engine (flag_true + 4 others) | objectives.json, sites.json |
| phone_apps.gd | Phone home-grid app registry | — |
| phone_nav.gd | Phone tab drill-down nav state (apps, Ticker detail view) | — |
| progression.gd | Shared "award XP against a levels table" loop | — |
| raiding.gd | Vein stealth-check + raid resolution | districts.json, factions.json, ore_types.json, stealth.json |
| relation_accrual.gd | Capped, remainder-carrying £-denominated trade-relation meter | — |
| rooms.gd | Daily processing for lab/veinStation rooms | ore_types.json, recipes.json |
| sites.gd | Sites & prospecting (land, seeding into a vein) | districts.json, factions.json, ore_types.json, sites.json, vein_growth.json |
| station_bubble.gd | Map site/vein-stop tap-bubble decision layer | vein_growth.json |
| time_system.gd | Time blocks, rest, daily tick | constants.json (time blocks) |
| todo.gd | Notes-app checklist, driven by objectives | objectives.json |
| travel.gd | District travel (free) | — |
| vein_list.gd | Vein-portfolio list decision layer | vein_growth.json |
| vein_list_nav.gd | Vein list screen nav state | — |
| vein_trade.gd | Selling a vein outright to a faction (quote + sell) | ore_types.json, vein_growth.json |

## scenes/screens/*.gd — UI screens

| File | Renders |
|---|---|
| combat.gd | Combat screen (turn UI over systems/combat.gd); stage backdrop reads combat_visuals.json (image or palette.json fallback fill) per combat context; StageSlot idle animation and attack (3 keyposes)/hit (1 pose)/ko (2 poses) one-shots all read combat_visuals.json's per-subject templates.<key> entries (key resolved by CombatScreen.enemy_template_key()/ally contactId/"player"), falling back to the shared templates.default stand-in (Gangsters_2-sourced) when a subject's own entry is empty -- the ticket-01 placeholder box is now a defensive-only fallback, not expected in normal play; attack/hit/ko each play via a transform tween (lunge/recoil/fall+fade) between keyposes, not a flipbook; Archie's self-patch pose and prophetsBreath's ghost-next-pose effect (§5) are wired the same way, both still art-deferred (no default fallback for either) |
| contacts.gd | Contacts tab, flag-gated actions |
| event.gd | Generic event-card screen driven by state.event |
| factions.gd | Factions tab |
| guild_marketplace.gd | Faction trading UI (buy/sell lanes, per-faction) |
| hq.gd | HQ tab: property (tier/security/rooms/stored ore) + devices |
| lab.gd | HQ's Lab card: crafting/workbench + discovery bench |
| map.gd | Map tab: Network diagram (MapCanvas) + district panel + site/vein sheet |
| phone.gd | Phone tab: contact list, SMS threads, James jobs, apps grid |
| placeholder.gd | Stand-in for any not-yet-built screen |
| title.gd | Title screen + load-game slot list |
| vein_list.gd | Vein-portfolio list (district-scoped or global) |

## scenes/components/*.gd — reusable UI components

| File | Purpose |
|---|---|
| app_tile.gd | Icon+label+badge+lock tile used by phone app grid + dock |
| bag_drawer.gd | Global bottom-sheet bag drawer, openable from any screen |
| contact_cards.gd | Shared Archie/James/faction contact-card builders |
| icons.gd | 8 drawn icon glyphs (home/pin/padlock/market/phone/bag/legend/news) |
| map_bubble.gd | Popup anchored at a map point listing tappable options |
| map_canvas.gd | Network diagram draw pass (paper → zones → river → lines → stops → badges) |
| map_controls.gd | Filter-chip drawer + legend button |
| map_legend.gd | Persistent faction-colour key, tube-map line-key style |
| map_zoom_buttons.gd | Floating +/- zoom control over the Network diagram |
| modal_layer.gd | Dim background + centred card, dispatches on modal.type |
| nav_bar.gd | Bottom 3-slot nav dock (Phone · Map · HQ) |
| notification_toast.gd | Auto-fading unseen-notification toasts |
| ore_glyphs.gd | Ore-symbol font glyph rendering + coverage check |
| top_bar.gd | Persistent top bar: cash, day/time-blocks, bag button |
| touch_scroll_container.gd | ScrollContainer with touch drag-to-scroll |
| ui.gd | Small shared Control-building helpers |

## data/*.json

| File | Consumed by |
|---|---|
| approaches.json | systems/approaches.gd |
| barometer.json | systems/barometer.gd |
| collective_barks.json | systems/collective.gd |
| combat_visuals.json | autoload/GameData.gd (COMBAT_VISUALS) → scenes/screens/combat.gd, scenes/components/turn_order_strip.gd. `backdrops`: Combat.CANONICAL_CONTEXTS context → `{image, fallbackColor}` (validated, `fallbackColor` a palette.json colour id via GameData.PALETTE). `templates`: per cast-subject key (ticket 09/10, unvalidated), `idle`/`attack`/`hit`/`ko` sheets each `{image, frameCount, fps}` -- all four fall back to the shared `default` stand-in (Gangsters_2-sourced) when a subject's own is empty; the ticket-01 placeholder box only shows if even `default` is missing/broken. `tell` (ability-telegraph pose) and `selfPatch` (Archie-only heal pose) have no `default` fallback. `territorialScrapper`/`orichalchumDealer` have real (asset-pack sourced, not final) idle/attack/hit/ko art; every other subject and every `tell` entry is still an empty stub, showing `default`'s art instead |
| constants.json | systems/time_system.gd, systems/jobs.gd, scenes/components/top_bar.gd, scenes/screens/phone.gd (timeBlocks, archieOreGoal, contacts defaults, James trust bands) |
| dial.json | systems/dial.gd |
| districts.json | systems/districts.gd, district_bubble.gd, sites.gd, economy.gd, factions.gd, raiding.gd, map_layout.gd, archie_deals.gd |
| enemies.json | systems/combat.gd |
| faction_trade.json | systems/economy.gd |
| factions.json | systems/factions.gd, sites.gd, raiding.gd, debug_start.gd |
| home.json | systems/home.gd, systems/approaches.gd |
| items.json | systems/combat.gd, scenes/screens/phone.gd, scenes/components/bag_drawer.gd |
| map_layout.json | systems/map_layout.gd, systems/map_hit_test.gd |
| objectives.json | systems/objectives.gd, systems/todo.gd, systems/collective.gd |
| ore_types.json | widely read — economy.gd, cultivating.gd, sites.gd, factions.gd, raiding.gd, dial.gd, rooms.gd, vein_trade.gd, debug_start.gd, archie_deals.gd |
| palette.json | tools/pixelize.py, tools/make_palette_swatch.py, autoload/GameData.gd (PALETTE, colour id → Color) — master 42-colour combat-art palette. Swatch render sits alongside it at `data/palette_swatch.png` |
| recipes.json | systems/crafting.gd, bench.gd, combat.gd, dial.gd, jobs.gd, rooms.gd, economy.gd (consumable prices), contacts.gd (crafting xp levels) |
| sites.json | systems/sites.gd, collective.gd, objectives.gd |
| stealth.json | systems/raiding.gd |
| vein_alarm.json | systems/cultivating.gd |
| vein_growth.json | systems/cultivating.gd, events.gd, sites.gd, factions.gd, station_bubble.gd, vein_list.gd, vein_trade.gd, debug_start.gd, contacts.gd |
| vein_security.json | systems/cultivating.gd, systems/factions.gd |

## data/events/*.json (43 files, not listed individually)

One JSON per event id, loaded by autoload/GameData.gd into `EVENTS` (roster is the `EVENT_IDS` + `DISTRICT_EVENT_IDS` consts in GameData.gd — check there for the current id list, not this file). Each is the cards/on_complete event schema systems/events.gd runs. Two naming families: `col_a1_*` / `col_hakim_intel` / `archie_*` / `james_*` / `home_raid_*` etc. are directly-triggered tutorial/Collective-Act-1 story beats; district-named files (`busker_greenwich.json`, `city_suit.json`, ...) are weighted district-deck entries drawn by systems/district_deck.gd and also carry a `deck` sub-object (district/weight/excludeIfFlag/barometerState).

## tests/*.gd

Mirrors systems/ and screens/ 1:1 by filename: `tests/test_<name>.gd` tests `systems/<name>.gd` or the matching screen/component. `tests/support/` holds shared test helpers (e.g. draw_spy.gd). Run via `scripts/run_tests.sh`.

## scripts/*.sh and scripts/*.gd — tooling

| File | Purpose |
|---|---|
| check_all.sh | Syntax-checks every .gd file in the project via check_runner.gd |
| run_tests.sh | Runs the full headless test suite (tests/test_runner.gd discovers test_*.gd) |
| setup_godot.sh | Idempotent Godot 4.4 headless binary setup, symlinked as `godot` |
| soak.sh | Runs the playthrough test 20x as separate `godot --headless` invocations |
| check_runner.gd | SceneTree script backing check_all.sh — boots normally so autoloads resolve |
| verify_map_camera_persistence.gd | Live-tree regression check for map-camera-persistence bug |

## tools/*.py — asset pipeline tooling

| File | Purpose |
|---|---|
| pixelize.py | Combat pixel-art pipeline: detect cell size → downsample nearest → strip AA fringe → quantise to `data/palette.json` → trim to a fixed canvas. Run on every generated combat asset, no exceptions — see `docs/ART-BIBLE.md` |
| png_io.py | Pure-stdlib PNG read/write (8-bit RGB/RGBA, non-interlaced) backing pixelize.py — no Pillow dependency |
| make_palette_swatch.py | Renders `data/palette.json` to `data/palette_swatch.png`; re-run after editing the palette |
| test_pixelize.py | Self-test for the pixelize pipeline (`python3 tools/test_pixelize.py`) — no external test framework |

## docs/*.md and docs/adr/

See CLAUDE.md source-of-truth table for: REFERENCE.md, M0-PORT.md, M1-LONDON.md, M1.5-NETWORK-MAP.md, CONTENT-GUIDE.md, reference/london-orichalchum.html, CONTEXT.md, docs/adr/ (as a category). Not in that table:

| File | Purpose |
|---|---|
| VISION.md | Game vision & dev plan (v1.1) |
| M3-CALC-DISCOVERY.md | Lab/Calc-effect-discovery vision doc — provisional, not yet spec/canon |
| device-plan-spec.md | Dial device mechanic design log — draft, not yet promoted to REFERENCE.md |
| combat-animation-vision.md | Combat animation & art direction vision draft |
| ART-BIBLE.md | Combat pixel-art canon: palette, canvas sizes, lighting rule, generation prompt template, render/import settings — see also `tools/pixelize.py` |
| BUGS.md | Known-bugs log (as of 2026-07-24) |
| BUGHUNT-2026-07-17.md | Write-up of a 2026-07-17 headless bug-hunting session |
| android-setup.md | One-time machine setup + build steps for an installable Android APK |
| agents/domain.md | How engineering skills should consume this repo's domain docs |
| agents/issue-tracker.md | Local-markdown issue tracker convention (issues live under .scratch/) |
| agents/triage-labels.md | Maps the 5 canonical triage roles to this repo's actual label strings |
| adr/0001-defer-network-map-renderer.md | Why the Network Map renderer was split out of M1's exit criteria |
| adr/0002-site-lifecycle-and-npc-claims.md | siteCap / NPC-claim eligibility / abandonment interaction rules |
| adr/0003-app-icon-asset-contract.md | Fixed contract for app-tile icon assets |
| adr/0004-remove-npc-vein-abandonment.md | Removed NPC-vein abandonment; retuned claim rate + prune-back target |
