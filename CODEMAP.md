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
| home.gd | Home tier/security/rooms/raid. `get_raid_chance_for_tier(tier_id)`/`get_next_tier_id(tier_id)` (03-property-app-phone-tab) factor `get_home_raid_chance()`/`upgrade_tier()`'s formulas out so the Phone tab's Harrow's app can preview a tier the player hasn't moved into yet | home.json |
| jobs.gd | James's jobs, trust bands | recipes.json, constants.json (trust bands) |
| lab_bench_nav.gd | hq-diorama ticket 06 — Lab bench sub-view nav: which of the 3 focal stops (books/ore/apparatus) is in frame, and which notebook mode (recipes/experiments/null) is held for the session. Ticket 07 adds selectedOre (up to 2 ore-type ids picked at the ore stop) and select_ore() — this is now the Lab's only nav state; the old BenchNav (systems/bench_nav.gd) picker/pairing/confirm drill-down and the lab.gd screen it drove are both deleted | — |
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
| phone_apps.gd | Phone home-grid app registry (03-property-app-phone-tab added the "property"/"Harrow's" entry) | — |
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
| combat.gd | Combat screen (turn UI over systems/combat.gd); stage backdrop reads combat_visuals.json (image or palette.json fallback fill) per combat context; StageSlot idle animation and attack (3 keyposes)/hit (1 pose)/ko (2 poses) one-shots all read combat_visuals.json's per-subject templates.<key> entries (key resolved by CombatScreen.enemy_template_key()/ally contactId/"player"), falling back to the shared templates.default stand-in (Gangsters_2-sourced) when a subject's own entry is empty -- the ticket-01 placeholder box is now a defensive-only fallback, not expected in normal play; attack/hit/ko each play via a transform tween (lunge/recoil/fall+fade) between keyposes, not a flipbook; Archie's self-patch pose and prophetsBreath's ghost-next-pose effect (§5) are wired the same way, both still art-deferred (no default fallback for either). Ticket 11: beats carrying an `effectKey` extra field (systems/combat.gd's use_*()/cast_complication() branches, keyed by consumable id) play combat_visuals.json's `effects.<key>` sheet (art-deferred, empty today) via StageSlot.play_effect_sheet()/set_shield_loop(); art-independent flourishes ride alongside regardless of art status -- StageSlot.spawn_afterimage() (enhancementPowder, per rapid attack beat while motionTurns>0), play_wormhole_vanish() (fold-and-fade transform), set_frozen_visual()/set_time_scale() (timePearl desaturate + 10% idle speed, re-synced from combat.frozenTurns every _sync_stage()), flash_shield_crack() (shieldAbsorbed beat field). EventBus.combat_beats_played/combat_rewind_played bridge the direct bag-item use_*() path (bag_drawer.gd, a global overlay with no direct handoff to this screen) and combat_rewind()'s reverse-beat replay (_on_rewind_beat_played(), a trimmed pose/flash/shake-only playback -- no log-reveal or ghost-drain) back into this screen's own CombatDirector. Ticket 18 (human direction, 2026-09-09): STAGE_HEIGHT shrunk 360→220 to free room for a new command-deck furniture row -- `_build_dial_and_actions_row()` docks the (rewritten, see dial_widget.gd) Dial widget left and a new `_build_complication_detail()` rectangle + the action row (back to horizontal, 3 EXPAND_FILL blocks -- see `_build_action_card()`) right, replacing ticket 03/13's docked-right full-height Dial + vertical action stack. |
| contacts.gd | Contacts tab, flag-gated actions |
| event.gd | Generic event-card screen driven by state.event |
| factions.gd | Factions tab |
| guild_marketplace.gd | Faction trading UI (buy/sell lanes, per-faction) |
| hq.gd | HQ tab: hq-diorama ticket 02 — the single bedsit room plate (hq_diorama.gd rendering data/hq_visuals.json), no more card stack. Tapping a zone dispatches to today's existing destination (bag/rest direct, one of modal_layer.gd's "hq_*" modals for Ore-store/Gym, `Nav.go_to("hq_floorplan")` for Rooms — ticket 04, `Nav.go_to("hq_door")` for Security — ticket 05, `LabBenchNav.open()` + `Nav.go_to("hq_lab_bench")` for Lab — ticket 06, or `Nav.go_to("hq_dial")` for the Dial — ticket 09); a locked-HQ fallback (no room plate yet) still exposes Rest/Defend. Debug region-overlay toggle button lives here too. Gym is wired into the bedsit plate despite docs/hq-diorama-vision.md §3.1 listing its first tier as "flat" — a deliberate, human-approved deviation (see data/hq_visuals.json's "gymDeviation" meta note). Ticket 05, §8: while Home.has_pending_raid() is true, the "security" zone tap calls Home.trigger_defend() directly instead of navigating to hq_door.gd, and _build_room_view() renders a deep-copied plate whose "security" region label reads "Security — RAID" (no hostile-variant art exists yet, so the label is the only hostile signal available with zero art). Ticket 10: real bedsit art landed, and _security_lock_installed_plate() applies the same deep-copy-and-swap trick to the security region's "image" (swapping in its "installedImage") once `state.home.security` contains "lock" — the first HQ visual driven by real per-save state rather than tier alone |
| hq_floorplan.gd | hq-diorama ticket 04, §6: the Rooms zone's diegetic destination — an estate agent's plan of the property (filled/locked/purchasable room slots, plus lab/veinStation contact assignment), moved verbatim off modal_layer.gd's deleted "hq_rooms_list" modal. First HQ sub-view built as its own screen id (registered in scenes/Main.gd, full-bleed — both TopBar and NavBar hidden for this id per §3.3) rather than a Modal; Back returns to "hq". No hq_visuals.json entry — slot count is data-driven off GameData.HOME_ROOMS/HOME_TIERS, not fixed pixel-art regions |
| hq_door.gd | hq-diorama ticket 05, §8: the Security zone's diegetic destination — installed/empty security slots (lock/cameras/reinforcedDoor/alarm/guard/ward), content moved verbatim off modal_layer.gd's deleted "hq_security_list" modal, rendered as a 2-column grid of slot tiles (same shape hq_floorplan.gd settled on for Rooms, after a single-column list first pass read as the "list-style" bucket §3.1 says the door is unlike). Full-bleed screen (registered in scenes/Main.gd, TopBar/NavBar hidden per §3.3); Back returns to "hq". No hq_visuals.json entry — slot roster is data-driven off GameData.HOME_SECURITY, not fixed pixel-art regions. Raid-pending "hostile door" branching (opening Defend instead of this screen) lives entirely in hq.gd's zone-tap handler, not here |
| hq_dial.gd | hq-diorama ticket 09, docs/hq-diorama-vision.md §4: the Dial's diegetic loadout sub-view — now the sole entry point to loadout adjustment (bag_drawer.gd's old management mode for it is deleted). Content (unseeded gift-gate/seed buttons, Movement seat/unseat/wind, Complication load/unload) moved verbatim off modal_layer.gd's deleted "hq_dial" modal and bag_drawer.gd's deleted `_build_dial_management()`; "Craft Components" still opens the unchanged "craft_components_menu"/"movement_craft" modals. Renders `assets/hq/dial/dial_device_base.png` + a rotating `dial-needle.png` charge-reserve overlay (AtlasTexture-cropped, pivoted at the dial face) purely as decoration — deliberately NOT the hit-test surface: the source art's screws sit only ~55-80 native px apart, well under docs/hq-diorama-vision.md §3.2's 44×44 no-overlap hit-region minimum at any width that fits a 390px screen. The Movement card and the 4 Complication-housing tiles (a human-set display cap "for now", independent of the Dial's real `capacityMax`, which can reach 16 — R§1.4) are separate, generously-sized UI below the art instead, same reasoning hq_door.gd's own grid-of-tiles gives. No hq_visuals.json entry — this plate isn't reached through HqDiorama/region hit-testing at all, unlike every other HQ sub-view. Full-bleed screen (registered in scenes/Main.gd, TopBar/NavBar hidden per §3.3); Back returns to "hq" |
| hq_lab_bench.gd | hq-diorama ticket 06, §5: the Lab zone's diegetic destination — one wide plate (data/hq_visuals.json's "labBench", 1170×844, 3 stops × the 390-wide screen) reused via hq_diorama.gd unmodified and panned by offsetting its position inside a 390-wide clipping frame, arrow-stepped only (state.labBenchNav.stop, LabBenchNav.step()) — no swipe/scroll. Books stop carries the two notebook regions (Recipes/Experiments); tapping one calls LabBenchNav.tap_notebook() (state.labBenchNav.mode), reflected back into the held region's own label ("<Name> (open)"). Ticket 07, §5.3/§5.4: the ore stop's five "ore_<oreTypeId>" regions (tap toggles LabBenchNav.select_ore(), label carries the empty/some/plenty count bucket + selection + cost preview) and the apparatus stop's up-to-four "apparatus_<approachId>" regions (deleted from this screen's own render-time copy of the plate when Approaches.is_known() is false — §3.2's "no region for an object not present at this tier" — labelled with the armed recipe's name in Recipes/manual mode, or a spoiler-free "ready" in Experiments mode). Tapping an apparatus runs _run_apparatus() (Bench.probe()/Crafting.attempt_craft() per mode, feedback via modal_layer.gd's "lab_bench_probe_result"/"craft_result"). A press on an ore container followed by a release on a different apparatus region additionally runs that apparatus with the just-pressed selection — the drag-and-drop flourish, never the only route (a plain tap already fires on press, unchanged). "Recipe book"/"Notebook" buttons (plain UI, not diorama regions) open modal_layer.gd's "lab_bench_recipe_book"/"lab_bench_notes" once a mode is held. This is now the Lab's only screen — lab.gd, its state.benchNav drill-down, and systems/bench_nav.gd are all deleted. Full-bleed screen (registered in scenes/Main.gd, TopBar/NavBar hidden per §3.3); Back returns to "hq" |
| map.gd | Map tab: Network diagram (MapCanvas) + district panel + site/vein sheet |
| phone.gd | Phone tab: contact list, SMS threads, James jobs, apps grid. 03-property-app-phone-tab added the "Harrow's" app (HQ tier stats + Home.upgrade_tier(), relocated off the HQ tab per docs/hq-diorama-vision.md §7) |
| placeholder.gd | Stand-in for any not-yet-built screen |
| title.gd | Title screen + load-game slot list |
| vein_list.gd | Vein-portfolio list (district-scoped or global) |

## scenes/components/*.gd — reusable UI components

| File | Purpose |
|---|---|
| app_tile.gd | Icon+label+badge+lock tile used by phone app grid + dock |
| bag_drawer.gd | Global bottom-sheet bag drawer, openable from any screen |
| contact_cards.gd | Shared Archie/James/faction contact-card builders |
| dial_widget.gd | Combat's in-fight Dial-casting widget (`scenes/screens/combat.gd`'s command deck). combat-presentation ticket 18: renders the real `assets/hq/dial/dial_device_base.png` umbrella-handle prop (reused verbatim from `hq_dial.gd`'s loadout screen, not separate art) inside a fixed-size clipped box, plus a charge-reserve needle. Interaction is direct tap, not the old rotate/press-anywhere gesture: `handle_select(index)` fires when one of the 4 screws ringing the clock face is tapped (one per loaded Complication, `MAX_DOTS`-capped same as `hq_dial.gd`'s flanking sockets), `handle_trigger()` fires only from a dedicated hit-region over the oval switch below the grip (a drawn "⇄" glyph overlaid there, since the art has no icon baked in). Renders whenever the player has a seeded Dial at all (even empty) — CombatScreen only omits the node entirely when there's no Dial. Screw/button positions are ART-REVIEW consts, not yet confirmed on-device (see the file's own top comment and `.scratch/combat-presentation/issues/18-umbrella-handle-tap-select_COMPLETED.md`) |
| hq_diorama.gd | Renders one data/hq_visuals.json room-plate entry: background (image or palette.json fallback fill) + a labelled placeholder box per empty-image region + an optional debug overlay (every region rect + id). Pure renderer — region_rects() hands the caller (hq.gd) rects to do its own tap hit-testing; never touches GameState or does navigation itself |
| icons.gd | 8 drawn icon glyphs (home/pin/padlock/market/phone/bag/legend/news) |
| map_bubble.gd | Popup anchored at a map point listing tappable options |
| map_canvas.gd | Network diagram draw pass (paper → zones → river → lines → stops → badges) |
| map_controls.gd | Filter-chip drawer + legend button |
| map_legend.gd | Persistent faction-colour key, tube-map line-key style |
| map_zoom_buttons.gd | Floating +/- zoom control over the Network diagram |
| modal_layer.gd | Dim background + centred card, dispatches on modal.type. hq-diorama ticket 02 added HQ's zone-destination modals here ("hq_dial", "hq_security_list", "hq_ore_readout", "hq_gym") — hq.gd's old always-inline Security/Ore-store/Dial/Gym cards, moved verbatim. Ticket 04 pulled "hq_rooms_list" back out again — Rooms is now the full-bleed hq_floorplan.gd screen, not a modal. Ticket 05 pulled "hq_security_list" out the same way — Security/the door is now the full-bleed hq_door.gd screen. Ticket 09 pulled "hq_dial" out the same way — the Dial is now the full-bleed hq_dial.gd screen; "craft_components_menu"/"movement_craft" stay here, unchanged, still reached from that screen. Ticket 07 adds the Lab bench's own modals (lab.gd's old screen-level content, moved here near-verbatim): "lab_bench_recipe_book" (Recipes-mode book path — pick a known recipe + quantity, craft, plus refine per §5.6), "lab_bench_notes" (Experiments-mode pairings-tried/recipe-levels panel), "lab_bench_probe_result" (found/hot/inert feedback the instant Bench.probe() resolves) |
| nav_bar.gd | Bottom 3-slot nav dock (Phone · Map · HQ) |
| notification_toast.gd | Auto-fading unseen-notification toasts |
| ore_glyphs.gd | Ore-symbol font glyph rendering + coverage check |
| symbol_glyph.gd | Reusable Label-or-vector-fallback Control for any symbol a font may not cover (helper only — not yet wired into any screen; ticket 114) |
| top_bar.gd | Persistent top bar: cash, day/time-blocks, bag button |
| touch_scroll_container.gd | ScrollContainer with touch drag-to-scroll |
| ui.gd | Small shared Control-building helpers |

## data/*.json

| File | Consumed by |
|---|---|
| approaches.json | systems/approaches.gd |
| barometer.json | systems/barometer.gd |
| collective_barks.json | systems/collective.gd |
| combat_visuals.json | autoload/GameData.gd (COMBAT_VISUALS) → scenes/screens/combat.gd, scenes/components/turn_order_strip.gd. `backdrops`: Combat.CANONICAL_CONTEXTS context → `{image, fallbackColor}` (validated, `fallbackColor` a palette.json colour id via GameData.PALETTE). `templates`: per cast-subject key (ticket 09/10, unvalidated), `idle`/`attack`/`hit`/`ko` sheets each `{image, frameCount, fps}` -- all four fall back to the shared `default` stand-in (Gangsters_2-sourced) when a subject's own is empty; the ticket-01 placeholder box only shows if even `default` is missing/broken. `tell` (ability-telegraph pose) and `selfPatch` (Archie-only heal pose) have no `default` fallback. `territorialScrapper`/`orichalchumDealer` have real (asset-pack sourced, not final) idle/attack/hit/ko art; every other subject and every `tell` entry is still an empty stub, showing `default`'s art instead. `effects` (ticket 11, unvalidated): flat (not per-subject) table, one entry per consumable with a signature *sheet* effect (`timePearl`/`blast`/`shield`/`healingBurst`/`blackHole`), each `{image, frameCount, fps}` at 96×96 native (blackHole 160×160) -- no `default` fallback (an effect sheet has nothing generic to fall back to); every entry is still an empty stub (no art produced yet). enhancementPowder/wormhole/rewind/failsafe have no `effects` entry at all -- their effects are transform-only (no new art, per the ticket's own asset list) |
| constants.json | systems/time_system.gd, systems/jobs.gd, scenes/components/top_bar.gd, scenes/screens/phone.gd (timeBlocks, archieOreGoal, contacts defaults, James trust bands) |
| dial.json | systems/dial.gd |
| districts.json | systems/districts.gd, district_bubble.gd, sites.gd, economy.gd, factions.gd, raiding.gd, map_layout.gd, archie_deals.gd |
| enemies.json | systems/combat.gd |
| faction_trade.json | systems/economy.gd |
| factions.json | systems/factions.gd, sites.gd, raiding.gd, debug_start.gd |
| home.json | systems/home.gd, systems/approaches.gd, scenes/screens/phone.gd (03-property-app-phone-tab: Harrow's reads HOME_TIERS/HOME_TIER_ORDER directly for its listing) |
| hq_visuals.json | autoload/GameData.gd (HQ_VISUALS) → scenes/components/hq_diorama.gd, scenes/screens/hq.gd, scenes/screens/hq_lab_bench.gd. `rooms`: room-plate id (v1: only `bedsit`) → `{image, fallbackColor, width, height, regions}`; `regions`: zone id → `{x, y, width, height, label, image}` in the plate's own display-resolution coordinate space, doubling as both hit region and sprite rect. hq-diorama ticket 06 adds a sibling top-level `labBench` plate (same `{image, fallbackColor, width, height, regions}` shape, one plate not a table — it's the Lab bench sub-view, not a property tier) for the bench's 3-stop pan (§5.1). Ticket 07 fills its ore/apparatus stops: `ore_<oreTypeId>` (5, one per data/ore_types.json type — hq_lab_bench.gd derives the type from the region id) carry optional `emptyImage`/`someImage`/`plentyImage` fields alongside `image`, following the `security` region's `installedImage` deep-copy-and-swap convention, for the count-driven visual state once art exists (all four still empty today, rendering as a labelled placeholder box whose text carries the state instead); `apparatus_<approachId>` (4, one per data/approaches.json approach) have no such variants — hq_lab_bench.gd deletes an apparatus's region from its own render-time copy entirely when its approach isn't known yet, rather than swapping its image. Read entirely generically (no hardcoded room/zone roster) so a later tier's plate or a new region needs a manifest edit only. `image` empty renders a labelled placeholder box (docs/hq-diorama-vision.md §9). Validated by GameData._validate_hq_visuals() (factored into the per-plate `_validate_hq_plate()`, called once per room plus once for `labBench`) — every region ≥44×44px, no overlaps within the same plate. Ticket 10 lands real bedsit art (`assets/hq/bedsit_room.png` + per-region crops under `assets/hq/regions/`) and an optional `installedImage` on the `security` region (`bedsit_security_installed.png`) — a second full-region plate hq.gd swaps in at render time (never read by hq_diorama.gd itself) once `state.home.security` has `"lock"`; `oreStore` still has no art (`image: ""`, placeholder box) since no fixture was ever drawn for it |
| items.json | systems/combat.gd, scenes/screens/phone.gd, scenes/components/bag_drawer.gd |
| map_layout.json | systems/map_layout.gd, systems/map_hit_test.gd |
| objectives.json | systems/objectives.gd, systems/todo.gd, systems/collective.gd |
| ore_types.json | widely read — economy.gd, cultivating.gd, sites.gd, factions.gd, raiding.gd, dial.gd, rooms.gd, vein_trade.gd, debug_start.gd, archie_deals.gd |
| palette.json | tools/make_palette_swatch.py, autoload/GameData.gd (PALETTE, colour id → Color) — reference 42-colour combat-art palette; not enforced on generated art. Swatch render sits alongside it at `data/palette_swatch.png` |
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
| debug_combat_dial_screenshot.gd | Dev-only visual harness (run windowed, `godot -s scripts/debug_combat_dial_screenshot.gd`, real GPU required): boots CombatScreen with a loaded/empty Dial, dumps PNGs + a full Control-rect tree to `.scratch/combat-presentation/dial-screenshots/`. Same pattern as the pre-existing (also unlisted here) `debug_combat_fan_screenshot.gd`/`debug_hq_dial_screenshot.gd` — written for combat-presentation ticket 18 to verify `dial_widget.gd`'s tap-region geometry actually lands on the art |

## tools/*.py — asset pipeline tooling

| File | Purpose |
|---|---|
| pixelize.py | Combat pixel-art pipeline: detect cell size → downsample nearest → strip AA fringe → trim to a fixed canvas. Run on every generated combat asset, no exceptions — see `docs/ART-BIBLE.md` |
| png_io.py | Pure-stdlib PNG read/write (8-bit RGB/RGBA, non-interlaced) backing pixelize.py — no Pillow dependency |
| make_palette_swatch.py | Renders `data/palette.json` to `data/palette_swatch.png`; re-run after editing the palette |
| test_pixelize.py | Self-test for the pixelize pipeline (`python3 tools/test_pixelize.py`) — no external test framework |

## tools/quest-editor.html — local quest browser + prose editor

Single static HTML file, open directly in Chrome (no server/build step). Uses the File System
Access API to open `data/events/`, list every quest JSON, and edit prose fields (`text`, `label`,
`speaker`, `result_text`) inline while showing `effects`/`on_complete`/`deck`/`pin` read-only.
Saves by splicing only the edited string literals back into the original file text (via a
custom position-tracking JSON parser), so untouched keys, values, and formatting are preserved
byte-for-byte. A "+ New quest" builder lets you assemble a fresh quest's card/choice list from
scratch and writes it as an inert, unregistered `data/events/<id>.json` (`effects: []`, no
`deck` key). Every open quest (existing or newly built) also shows an "Author intent notes"
panel — free text describing what the mechanical fields should do, saved alongside quest saves
as a sidecar `data/events/drafts/<id>.notes.md`, fully independent of the real event JSON.
`test_quest_editor.js` (`node tools/test_quest_editor.js`) unit-tests the parser, splice logic,
builder schema, and notes-sidecar naming against every real file in `data/events/`.

## tools/quest-editor-mobile.html — offline draft builder (phone)

Single static HTML file with no dependency on the File System Access API, so it works in mobile
browsers (desktop `quest-editor.html` needs `showDirectoryPicker`, which iOS/Android browsers
don't support). Same card/choice builder UI as `quest-editor.html`'s "+ New quest" flow, but
touch-sized and with no connection to `data/events/` at all — no folder access, no id-collision
check. "Save draft" downloads a single bundle `<id>.draft.json` (`{format: "vein-quest-draft/v1",
id, cards, notes}`); "Open draft…" re-loads one of those (or a plain exported quest JSON) via
`<input type=file>` to keep editing. "Copy JSON" puts the same bundle on the clipboard as a
paste-into-chat alternative to file transfer. The round trip: write on phone → get the
`.draft.json` to a computer (AirDrop/email/clipboard) → hand it to Claude, which creates the real
`data/events/<id>.json` (+ `drafts/<id>.notes.md` sidecar) and does the registration/wiring pass,
same as it would for a desktop-built draft.

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
