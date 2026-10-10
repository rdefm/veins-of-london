# CODEMAP

What lives where. Update alongside any add/remove/repurpose (CLAUDE.md step 7). Each row: what a
file owns today, no history.

## autoload/*.gd — global singletons

| File | Purpose |
|---|---|
| EventBus.gd | Central signal bus — systems emit, screens redraw |
| GameData.gd | Loads/validates every `data/*.json` table at boot; scans `assets/combat/territorial<N>/` folders into `TERRITORIAL_VARIANTS` and builds their sprite sets in `combat_templates()` |
| GameState.gd | Pure state tree (Dicts/Arrays/primitives); screens read only |
| Rng.gd | Seeded RNG for every probabilistic system; `stable_unit()` keyed hash rolls + `fresh_seed()` off the global stream |
| SaveManager.gd | Save/load/autosave/export-import; backfills missing keys (pre-tenure homes load owned, bedsit rented), restores JSON ints, KO-clamps a loaded fight's selection, founder fix-ups (room→role, Archie recruited past home raid), strips unowned veins from cultivator lists |
| Snapshots.gd | Bounded snapshot-stack helper backing rewind |

## systems/*.gd — static-func systems

Data file per system: see `data/*.json` below.

| File | Domain |
|---|---|
| approaches.gd | Unlocked physical approaches |
| archie_deals.gd | Archie's daily side-deal roll |
| bag.gd | Bag-drawer toggle |
| bank.gd | Cash transaction log |
| barometer.gd | Economic/social/political barometer (Ticker) + faction prefs; active-state change recency and News order; merged effects incl. item-demand multipliers; structured faction headlines (`push_headline`) and dated wire-article text (`wire_article`); one-off queued faction pushes (`queue_push`) |
| business_quest.gd | business_empire questline side effects (state.businessQuest): Beat 1/3/5/6/7/8 trigger texts, Beat 2 starter-offer chain, recurring offers (ore from Beat 3, Time Pearl from Beat 6; reissued a day after lapse), Beat 8 closing payload from the latest payday record, James's crafting-skill set, Owen's crafting-event trigger. Rules: REFERENCE.md "Business Empire questline" |
| business_stats.gd | BizBrief Stats tab's daily tally (revenue, expenses split by kind staff/guard/calc, cultivator/player ore); rollover snapshot with productionLog items into `businessStats.days`, 10-day trim, zero-filled chart series |
| business.gd | Business pot (contract settlements; Sales calc purchases as `calc` expenses), float (donate/withdraw; backs wages and calc, never split), hire first-week prepay (`paidThroughDay`), weekly payday (staff wages, then Monday guard bill from pot+float or a reserve when short, 3-way split, ledger), owed wages + float top-up, Staff tab pay labels |
| bench.gd | Lab discovery engine (type-set × approach); per-cell item tier (1–5) + progress bar, `experiment()` roll (room `progressBonus` adds to each success), `item_tier()` |
| bubble_layout.gd | Popup-position math for MapBubble |
| collective.gd | Collective faction doors, Nadia settlement, Collective questline beat triggers + Act 2 scripted vein losses + Nadia defend raid, Hakim retake gate + site ruin (ruinedByFirm), T7 Firm provocation (timed Firm-targeting weight), Act 2 relation awards (T8 missions, alarm-defend daily cap), Act 2 gate + T14 spine reward (Hakim intel's weak-enemy-vein branch) + T15 closer delivery |
| combat_prep.gd | CombatPrep: `state.combatPrep` request/cancel/commit for every combat entry (planned raids/defences cancellable, forced encounters not), replaying the existing Raiding/Home/Combat entries on Fight; lists participants + equipped units; empty-slot warning + Change loadout (`loadoutEdit` round-trip to Profile); recruit pool/toggle/reorder for planned raids and vein/HQ defences |
| combat.gd | Turn-based combat engine + rewind. Resumable `combat.turnCursor` + `prime_`/`conclude_decision_point()`; pure `project_queue()` (R§3.7a). Selection + `selection_block_reason()`. `enemyQueue`/`allyQueue` reinforcements. Raider/guard kit items. Stamps `locationKey`. Home raid opening mods (hp mult, `enemyFirst`); `resolve_home_raid()` = outcome + debrief, fought or not |
| network_handler.gd | Network handler Targets (timed `collective.networkIntel` claim_bonus/security_freeze), Sourcing (site delivered by handler text), the intel menu (relation- and gouge-priced, gated products: raid/market intel, raid warnings, boost, privacy, disinformation, reduction), and factions' daily budgeted buys of the same products |
| combat_pacing.gd | Persisted normal/quick pacing toggle |
| combat_prototype.gd | Bounded combat experiment, Debug-app |
| consumables.gd | Healing Salve (out-of-combat) + Healing Burst (in or out); in-combat use_healing_burst() resolves the parked player turn-cursor entry (R§3.7a) and heals an ally target instead of the player (R§3.7) |
| contacts.gd | Relation, recruiting (incl. story `force_recruit`), seat-capped room assignment (`contacts_in_room`/`assign_to_room`), room→role lookup from hiring.json (`room_roles`), founder staff roles (`set_role`/`role_of`/`available_roles`), capped XP (`skill_cap`, `xp_levels`), ally combat kit (Dial grant on recruit via `Dial.grant_contact_dial`), display names, directory order |
| contact_texts.gd | Per-contact random texts: rollover scheduling, gated selection, vein templating, reply rewards, and ticker notices; content from contact_texts.json |
| contracts.gd | Block-end Sales auto-delivery (full, then partials by priority; goods to buyer holdings + supplier share), settlement to pot; recurring periods pay on fill, lock (`periodFilled`) until Monday renewal, expire at term end; per-contract `buyCalc` calc buys from the pot; unattended-proof taint (`playerAssisted`) and `qualified` settlements; `cancel()` (unpaid, hurts counterparty) |
| crafting.gd | Recipe crafting; tiered inventory buckets; multi-target variant (from tier 3, `<recipe>_multi` inventory key, `craftMulti` checkbox state) |
| cultivating.gd | Vein growth / cultivate / prune; security tiers (lock/ward prices, guard tiers hired via GuardUpkeep) + raid resist; shared vein `value_order`; vein guard count + `drop_vein_guard` |
| debug_start.gd | Maximal-unlock debug state; `apply(model)` keeps a picked `player.model` through its reset |
| debug_tools.gd | Debug phone-app state adjusters; `fire_event()` preps any event (state-path veins/sites, addressed contacts, raid/reveal site context) then starts it |
| dial.gd | Per-owner Dial mechanic (`dial_of(owner_id)`: player or contact): Movements, charge economy, Complications (single or multi-target variant), casts/XP; `build_granted_dial`/`grant_contact_dial` for contact grants |
| diplomacy.gd | Diplomacy (R§3.10 "Favours", "Gifts"): faction favour requests as key-member pending messages; accept (goods favours sign a one-off contract via Offers), decline, guard/sit-out watches, keep/fail effects; cash/item gifts to key members (cooldown, diminishing returns, prefs) |
| partners.gd | Partners (R§3.10 "Partners"): player price favour on a partner's shop; partner trouble asks (sell/contract/buy/send) as pending messages; partner-faction discounted trades; warnings of planned moves; defence-fight helpers and faction raid odds cut; intel leaks |
| district_bubble.gd | District tap-bubble decision |
| district_deck.gd | Weighted district event deck picker |
| districts.gd | Derived district info for Map tab |
| economy.gd | Selling (Archie lane — ore at London quote, records supply — + faction lanes), faction-lane buying/selling for all five factions against FactionSim holdings and the faction's £ `resources` wallet (pricing incl. Network gouge, lane access via unlockFlag, R§3.6a); `complete_shop_trade` settles a faction shop's Trade-menu cart |
| event_items.gd | Registry of items usable from an event's Item button (Rewind consumable + Dial Rewind): eligibility, counts, effect |
| events.gd | Event-card runner + rewind, auto-discovers art, choice memory (`flags.choices`, `choice_record()`), choice checks (`check_odds()`, seeded `check_roll()`, multi-attempt, item mods + `toggle_item()`), `requires` gating (`option_gate()`, shared `condition_met()`), forward `goto` (R§3.9a), `at` start-time advance (R§3.9b), card-label tokens (R§3.9c) |
| faction_sim.gd | FactionSim: holdings (ore, items by tier); stockpile pick, guards; vein tend + prune (`fieldwork`); crafting toward targets; consumption + kit burns → shortfall; `vein_kit`, roster-capped `raider_kit` + `settle_raider_kit`; London trade vs reserve + smart boosts, Conclave arbitrage; flood/undercut/deny/stabilise/stock-up/position moves; raid harvest; is_weak bonus |
| faction_ai.gd | FactionAI (R§3.1 stances through Conclave positions): stances + matrix, flip headlines, activity log; pressure drift, Collective–Firm hold; escalation moves (Network intel, stockpile raids, raid bias, shortfall steal); wars, weariness, nags; truces, peace talks, truce payments; Conclave stabiliser + stockpile; war squeeze; Conclave positions + Ticker push; move forecast |
| intel.gd | Intel (R§3.1 "Intel"): observer → target intel meters for player and factions, level reads, scout/raid gains, daily decay, stockpile relocation cap; privacy/raid-warning/disinformation timers; intel's raid-odds shift and target scoring |
| factions.gd | Faction joining |
| guard_kit.gd | Guard kit: allowlisted items by tier on a vein's or HQ's (`home.guardKit`) kit; capacity (2 × guards), active units, `stock`/`unstock` and `*_hq` twins; repel boost/spend; post-defence `refill_*` (spent recipes only, highest tier first, capped) and `return_overflow`; kit-dict helpers (incl. `remove_units`); target helpers (vein/hq), summary/status text, `kit_veins` |
| guard_upkeep.gd | Guard wages: hire advance, weekly cost/labels, per-day per-place `guardUpkeep.history`, pre-pot Monday bill from cash, faction Monday bill (vein + stockpile guards) and wage-reserve gate, pending guard shortfall (grace, auto-resolve drop order, short-pay quote/confirm), place labels, Guard Costs reads (history window, per-place series, places, next Monday bill) |
| home.gd | Home tier/tenure/security/rooms/raid chance; per-day and weekly bill base (rent or utilities); arrears countdown to Monday; tier moves via shared `change_tier` (room carryover, security loss); HQ `drop_guard`; per-slot room purchase/replacement (`set_room_use`), seat upgrades; daily raid roll, alarm queue/expiry + guard (kit) repel, and alarm-defend win/loss resolution (R§3.8) |
| lodedinnit_directory.gd | LodedInnit People projection: role groups in roster order, Role/ore-specialism filters, per-group wage sort (roster → desc → asc alternating), filter option lists |
| lodedinnit_profile.gd | LodedInnit profile projection: role-skill experience (xp / next-level threshold), role-room seat line (built, seats free), cultivator speciality-bonus text |
| lodedinnit_feed.gd | LodedInnit Feed: per-block post roll (weighted author, no repeat until pool spent, likes, 0-2 canned comments, cap 50), templated hire-status posts (`post_status`: hired/let go/poached/market flip), unseen badge count, `mark_seen`, card display model (R§3.10 "LodedInnit Feed") |
| hiring.gd | LodedInnit roster + `state.hiring` status, rollover market flips; profile level/cap/wage; `hire()` (or poach: ×premium, relation cost) into a free role-room seat, first week prepaid pot→float or float top-up ask; wage refresh; `let_go()`; weekly faction poach offers on hires (`daily_poach_tick`, `match_poach`, `decline_poach`) (R§3.10 "Hiring") |
| jobs.gd | James's jobs, trust bands |
| key_members.gd | Faction key members (R§3.10): member/faction lookup, `speaker_for`, `send` (unlocks + intro on first message, or waits for a quest-gated member's questline) |
| lab_bench_nav.gd | Lab bench nav: selected ore; gear confirm variant (probe/craft/inert) + readiness |
| map_events.gd | Map event queue + playback |
| market.gd | London market (R§3.13): per-good stock/price/history, quotes, price lots (ore per 10: line_total, affordable_qty), supply/demand + faction move recording (`MOVE_SIDES`), civilian demand + Independents slice, daily reprice (⑥.6), bounded annotations, 7-day sales history, contract-delivery log, Stock Market reads (series, ore demand drivers, demand modifiers) |
| map_hit_test.gd | Tap-hit geometry, Network diagram |
| map_layout.gd | Resolves stops vs. live sites/veins |
| map_nav.gd | Map drill-down nav (list → panel → site sheet or vein detail panel, mutually exclusive) |
| map_pins.gd | Contact map-pins for waiting events; which faction shop pins are open (faction_trade.json mapShopPin + unlock); raidable stockpile pins (stockpile-location intel) |
| map_routing.gd | Octilinear line-routing geometry |
| map_style.gd | Filter-chip re-styling math |
| map_view.gd | Persists Network camera |
| map_zoom.gd | Zoom-level math for the diagram |
| messages.gd | Messages data layer + conversation-index projections, total unread count, per-contact clear (read + contact notifications seen) |
| modal.gd | Modal open/close state; holds an event deferred behind a modal flow (`followEvent`) and starts it on close; `returnTo` reopens a parked modal on close |
| morning_accounts.gd | Rollover capture (incl. arrears exceptions and countdown, payday statement, wage shortfalls, Monday guard wages, guard shortfall/walk-offs), per-block staff output accumulation, BizBrief routing, arrears/payday/wage-prompt/guard-wage labels |
| nav.gd | Screen navigation |
| notify.gd | Notifications append/evict; per-contact dismiss via contactId meta |
| objectives.gd | Objective/questline evaluator; all_of live-condition, template_periods_completed (Beat 6) and recurring_proof (Beat 7) objectives + their ToDo checklist rows |
| offers.gd | Sales offers: quoting (price fixed at issue), counterparty faction pick (authored / identity-weighted / Collective-Firm fit), acceptance (quote → contract `signedQuote`, recurring term), renewal offers, random-only pending cap, poach match/lapse, 2-day expiry |
| payroll.gd | `role_skill_keys()` (room → skill field, from the role registry); `is_working()` gate for staff actions (false while the business owes them a wage) |
| phone_apps.gd | Phone main-grid roster/order/labels (LodedInnit absent until James joins) + badge-config projection |
| phone_nav.gd | Phone app/index/thread drill-down nav; BizBrief short-pay and Guard Costs sub-view deep links |
| player_model.gd | `set_model()`: validates a key against `GameData.TERRITORIAL_VARIANTS` and writes `player.model` |
| preferences.gd | Saved presentation prefs in `meta` (reduced motion, vibration, Map dark mode) + carry_forward() so event Rewind never flips them |
| progression.gd | Shared "award XP" ladder loop |
| raid_alarms.gd | Summaries + dispatch for raid alarms |
| raiding.gd | Vein stealth-check + raid resolution; player stockpile raids (stealth, guard fight settlement, loot share, relation/war/relocation); faction-vs-faction stockpile raid resolution + Ticker headline; queued faction raids on the player (FactionAI raid rung) incl. alarm/scripted defend fights + kit burns; shared guard repel roll (player missed-defend, faction rivalry) |
| relation_accrual.gd | Capped £ relation meter |
| rooms.gd | Per-block staff step (one action per cultivator, then producers take turns crafting until targets met or ore short), which recipes each crafter's `specialities` allow and the Production list, writes/trims `productionLog`, Production targets/priority and when they are settable, per-cultivator vein lists (`cultivatorVeins`) and per-vein targets; cultivator speciality yield bonus |
| shares.gd | Shares: 14-day daily buckets per producer (player, factions, independents) of ore harvested, ore spent on successful crafts, contract deliveries and faction London buys; Independents slice crediting (⑥.5e); pure ore/crafting share, overview, delivery and supplier-share reads (split + intake) (R§3.14) |
| sites.gd | Sites & prospecting |
| loadout.gd | Two personal consumable slots for the player (`player.loadout`) and combat recruits (`contacts[id].loadout`): equip/unequip (refused in combat; allies refuse Wormhole), consume, settlement refill (player, then recruits in roster order), equippable stock; multi-target units (`multi` flag, refilled as the same variant) |
| stash.gd | Personal stash vs. shared pools |
| station_bubble.gd | Site/vein-stop tap-bubble decision |
| calendar.gd | Pure `world.day` → calendar date (`MON 3 JAN`, `Y2`+ suffix) per R§3.1 "Calendar"; day 1's weekday from `calendar.startWeekday`; every player-facing date string uses `Calendar.format_day`; weekday/Monday helpers for the weekly cadence |
| time_system.gd | Time blocks (each runs the staff block step + LodedInnit post), forward-only `advance_to_block()` for event `at` timing (R§3.9b), rest, daily tick (Monday-only tenure-aware weekly home bill, weekly arrears clock + interest, forced one-tier downgrade per ADR 0006) |
| todo.gd | ToDo-app sections per questline (Tutorial, Collective, Business Empire) with active/done/placeholder status + default expansion, "n of N" detail for count objectives, all_of checklist sub-items; Collective section carries the ledger read from state.world.sites |
| travel.gd | District travel (free) |
| vein_list.gd | Vein-portfolio list decision layer |
| vein_list_nav.gd | Vein list screen nav state |
| vein_trade.gd | Selling a vein outright to a faction (at quote, a forced handback price, or a faction's named price), buying one back, and a no-price handover from a faction (truce vein swap) |

## scenes/screens/*.gd — UI screens

`scenes/Main.gd` (scene root) boots autoloads/first screen, mounts the time-transition + alarm
overlays.

| File | Renders |
|---|---|
| combat_prep.gd | Preparation sheet (screen `combat_prep`) on the Trade sheet chrome: empty-slot warning + Change loadout, recruit picker (tick + ▲▼ order), participants with equipped units, opposition, Cancel (planned only) / Fight footer |
| combat.gd | Combat screen: orchestrator over CombatStage (fills the upper region)/CombatCommandDock -- owns turn flow, director bridging, band sync. Keeps one persistent strip and steps its queue beat by beat during (and Rewind) playback. `_select_target()` is the sole tap->`Combat.set_selection()` route; a stage tap during playback fast-forwards |
| combat_prototype.gd | Minimal combat-prototype screen, Debug-app only |
| contacts.gd | Contacts app inside PhoneDeviceShell; directory of unlocked contacts by display name (`Contacts.directory_ids`) with inline flag-gated actions; generic key-member card |
| event.gd | Event-card screen (VN and non-VN layouts); Item button + popup over EventItems; choices row, or stack full-width when they don't fit; check options show tries + odds/hint, info sheet, optional-item toggles; gated options hidden or greyed with reason; outcome marker on resolution; Leave-only fallback when state.event's id has no definition |
| factions.gd | Factions tab |
| hq.gd | HQ tab: renders the home tier's room plate (bedsit fallback), routes zone taps to sub-screens |
| hq_dial.gd | HQ Dial sub-view: embeds DialLoadoutMenu (no complication rows) above the device art with flanking Complication sockets |
| dial_loadout_menu.gd | `DialLoadoutMenu.build(owner_id, with_complication_rows)`: shared Dial loadout card (readouts, seat/unseat/swap, wind, load/unload); null when owner has no Dial (owner = "" player or a contact id, e.g. James). Used by Profile and HQ Dial |
| hq_door.gd | Security zone (lock/cameras/door/alarm/guard/ward); guard tile shows hire advance and weekly guard cost (links to Guard Costs); HQ kit row opens the HQ stocking sheet; Guard kits row opens hq_guard_kit |
| hq_guard_kit.gd | Guard Kit list: HQ kit row on top (`build_hq_row`, shared with hq_door), then one row per player vein with guards or a non-empty kit (name, n/cap, summary, idle); a row opens that kit's stocking sheet |
| hq_floorplan.gd | Noticeboard: tiers with a plan show FloorplanView (tap slot → choose/replace use); others show the room-tile grid. Contact assignment, Let go for hires, seats used/total and seat upgrade for staffed rooms |
| hq_lab_bench.gd | Lab zone: single portrait bench plate, jar count badges, ready-gear outline, status line; gear tap opens confirm modal |
| map.gd | Map tab: full-bleed diagram (top board to nav dock) with floating menu button, legend and zoom pill in Map chrome tokens; district panel + sheet |
| phone.gd | Phone tab controller: mounts PhoneDeviceShell, owns four-column home grid + home-only Phone/Messages/Settings dock, live badge-count projections + tile routing, dispatches apps through phone_app_registry.gd |
| placeholder.gd | Stand-in for a not-yet-built screen |
| title.gd | Title screen + load-game slot list; sprite picker overlay (idle preview, ◀/▶, Select, Back) that New Game and Debug Start open first |
| vein_list.gd | Vein-portfolio list (map_card_style.gd-skinned, always light via MapPalette.build_light) |

## scenes/components/*.gd — reusable UI components

| File | Purpose |
|---|---|
| alarm_presentation.gd | Detects raid alarms; Phone pulse + vibration |
| app_tile.gd | Normalised icon+label+numeric-count-badge+lock tile for phone launchers |
| bag_drawer.gd | Global bottom-sheet bag drawer; read-only stock/consumable listing (also during combat; no use buttons, no loadout change); out-of-combat heal buttons in management mode |
| combat_command_dock.gd | Combat's lower command region: full-width near-white surface Panel holding the Dial beside flat 1px-ruled command rows (Complication readout, Attack, two loadout item rows, Leg it), anchored to the true screen bottom; rows disabled per `Combat.selection_block_reason`/`slot_block_reason` |
| combat_director.gd | Combat beat-queue playback director; holds a data-driven pause (combat_visuals pacing.turnPause) between combatants' turns; emits `playing_changed` so CombatScreen locks its commands during playback |
| combat_stage.gd | Combat pixel stage: backdrop (location->context->palette); slots in two receding diagonal groups (enemies back/smaller), depth-sorted; up to 3 small reserve sprites per side (queue order) + `+N`, sliding in on entry; keypose one-shots, effects, juice layer. `StageSlot` taps emit `subject_tapped`; selected slot gets an arrow |
| contact_cards.gd | Shared contact/faction card builders (incl. handler card, Owen card, Targets/Sourcing, Nadia's ledger + "Go with Nadia", key-member card, pending-message actions incl. lowball Accept/Decline, peace offer Talk terms/Decline, favour Accept/Decline), inline Contacts action-row layout, OS chrome repaint |
| contract_card.gd | Draggable BizBrief Sales card |
| line_chart.gd | `_draw` line chart (palette-id or app accent colour, optional overlaid series on a shared scale, max label, first/last day, optional counted event markers); opt-in touch/drag history-point inspection for Ticker, compact chart for BizBrief Stats |
| price_move.gd | ▲/▼ + £ delta text and colour for a Market day move (Stock Market rows, sell lanes) |
| floorplan_view.gd | Estate-agent plan for a home tier from floorplans.json; static, or with tappable slot overlays showing current use |
| departure_board_casing.gd | Top board's sign housing: code-drawn metal frame, corner bolts, recessed bezel; optional nine-patch `assets/ui/departure_board_frame.png` slot |
| dial_widget.gd | Combat's Dial-casting widget |
| dot_matrix_board.gd | Amber-on-black dot-matrix board renderer |
| dot_matrix_font.gd | Bitmap font for dot_matrix_board.gd |
| haptics.gd | Adapter over `Input.vibrate_handheld()` |
| hq_diorama.gd | Generic plate/region artwork renderer; outlines regions flagged `selected`; owns the region hit rule (`zone_at`/`regions_at`: traced polygon else rect), the debug hit-shape overlay, and caption placement (polygon-centred for traced regions) |
| icons.gd | 13 drawn icon glyphs |
| map_bubble.gd | Popup listing tappable map options; paper-card frame and round action-icon states come from map_card_style.gd |
| map_card_style.gd | Shared vein-popover card family: card tokens (via map_palette.gd), card/inset/action-circle styleboxes, card()/style_panel(), section_label(), text/symbol_text/chip buttons, option rows, round_button()/stepper()/quantity_slider(), footer(), check-button + symbol tinting. The one button/card look for every non-phone menu; off-map callers build inside MapPalette.build_light |
| map_canvas.gd | Network diagram: layout/stops/lines, hit-testing (shop pins open the Trade menu, stockpile pins start a stockpile raid), static draw pass; tweens a vein's fullness ring on EventBus.vein_cultivated; delegates persistent halos and event-playback animations to map_halos.gd |
| map_halos.gd | Persistent vein-charge halo + the five event-playback animations (discover ripple, seed/claim ring, charge burst, drain collapse, join-line growth); owned by map_canvas.gd |
| map_controls.gd | Map controls drawer (map_card_style.gd-skinned): filters, faction isolate, pacing, Dark map toggle, legend button |
| map_palette.gd | MapPalette: resolves Map palette tokens (data/map_palette.json) for the current light/dark mode (`meta.mapDarkMode`), plus faction/ore colours with optional dark-only overrides; every Map-tab colour reads through it; build_light() scopes a light-only build for off-Map reusers |
| map_legend.gd | Persistent faction-colour key; restyles in place on a dark-mode toggle |
| map_zoom_buttons.gd | Floating +/- zoom control; restyles in place on a dark-mode toggle |
| modal_layer.gd | Dim background + light map_card_style.gd card (content built inside MapPalette.build_light), with navy/red chrome for BizBrief contract cancellation; mounts full-screen sheets for sell_menu (Trade) and guard_kit, and dispatches other content through modal_registry.gd; draws the recipe book full-bleed (no card) with recipe detail as a card above it; tap-outside dismiss |
| notification_ticker.gd | Top board's one-message notice row: presentation-only queue, roll-up from below, marquee for overflow, 4s hold; latest stays when empty; transient (combat-log) or keyed (notification id) queued entries droppable |
| nav_bar.gd | Bottom nav dock (Phone·Map·HQ); swaps to MapPalette dark chrome tokens while the Map tab shows with Map dark mode on |
| ore_glyphs.gd | Five canonical ore silhouettes as hand-drawn vectors; bundled-font coverage probe for non-map symbol fallback |
| recipe_book_page.gd | Aspect-fit recipe-book page art (assets/hq/recipe-book-side-tabs-blank.png) placing children by 1024x1536 art-space rects; owns the book-only Pixelify Sans font loader |
| phone_device_shell.gd | Persistent rounded simulated-phone frame: clipped display, approved London wallpaper, game-clock status time + widget date (live on state_changed), fixed weather/battery chrome, dark opened-app surface + shared/custom content mounts |
| phone_home_dock.gd | Home-only translucent three-destination Phone/Messages/Settings dock |
| symbol_glyph.gd | Label-or-vector fallback for a symbol; draws an optional `icon` texture instead when set |
| item_icons.gd | `ItemIcons`: recipe key -> pixel-art icon texture (from recipes.json `icon`) and symbol-row part dict; shared by Bag, Dial, trade, events, combat |
| time_transition.gd | Transient time queue, input guard, dimmed circular park/sky/sun/moon presentation |
| top_bar.gd | Top departure board: casing + status lines + NotificationTicker; feeds new notifications (combat hold, combat lines dropped when fight ends, raid-alarm line, reset on load/Rewind); tap opens Notifications app (short-pay menu if latest line is the pending guard shortfall) except in combat |
| touch_input.gd | `TouchInput.is_emulated_mouse(event)`: true for the mouse twin Godot emits for every touch; touch+mouse handlers skip it so one tap acts once |
| touch_scroll_container.gd | ScrollContainer, touch drag-scroll |
| tap_button.gd | Button behind UI.button/symbol_button/icon_button and card taps; shows pressed style while held, fires pressed only on a still release (TAP_SLOP), lets drags bubble to the scroller |
| turn_order_strip.gd | Combat turn-order strip: one card per projected turn occurrence. Tap selects; drag scrolls (offset survives re-configure). Selected card grows into a reserved band on the decision turn only; uniform during playback. Nine-slice sign frame per damage tier (cardFrames), HP ghost drain, `_reveal_pos()`, and playback reflow via `playback_occurrences()` + `advance_to()` |
| ui.gd | Shared Control builders, time-cost labels, lot price text ("£75/10"), ui_action_red accent + bordered-panel/action-button StyleBoxFlat helpers |
| vein_bubble.gd | Compact player-vein tap bubble: pin-anchored card, Lv segments, condition needle with 50/90+ scale, outline development/raid cues, round Harvest (light/hard chooser)/Cultivate actions, cultivator picker + hold-target stepper (via Rooms) while anyone holds Cultivation; tapping the info area opens vein_detail_panel.gd instead of running an action |
| vein_detail_panel.gd | Floating map_card_style.gd-skinned vein detail (mapNav.selectedVeinId): compact level/location, condition, drift/development/raid/security cues, three icon action tiles, security/guard kit row/alarm/Defend; reuses VeinBubble's level/condition builders |

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
| guard_kit_modal.gd | guard_kit modal registry adapter (data.target is a GuardKit kit target) |
| guard_kit_view.gd | Guard kit stocking sheet on the Trade pattern: Stock/Return tabs, grouped tiers with steppers, sticky slots/capacity totals, review; confirm calls GuardKit stock/unstock per line |
| sell_menu_view.gd | Trade-only sheet: sell/buy and category tabs, Map ore glyphs, grouped item tiers, sticky totals and review; three modes: Archie, Collective contact, faction shop (no contact); invokes existing trade systems |
| nadia_supply_modal.gd | Nadia ore-supply objective card |
| network_targets_modal.gd | Handler Targets picker: faction veins, soft/freeze questions |
| network_sourcing_modal.gd | Handler Sourcing order: ore type + minimum tier |
| network_intel_modal.gd | Handler intel menu: product rows at relation price, gate lock, faction/disinformation pickers, running timers |
| sell_vein_quote_modal.gd | Single-vein sale confirmation card |
| craft_components_menu_modal.gd | Movement-archetype picker; Craft hands off to movement_craft |
| movement_craft_modal.gd | Pick a calc type to attempt a Movement craft; pushes success/fail notices |
| movement_swap_modal.gd | Seat a Movement from movementInventory into the Dial |
| dial_load_complication_modal.gd | Load a crafted complication into the Dial |
| combat_setup_modal.gd | Debug combat setup: fight type (`Combat.DEBUG_SETUP_CONTEXTS`), location override for backdrop preview, enemy template/count/tier + ally toggles; calls `Combat.start_debug_combat()` |
| network_reference_modal.gd | Network Map legend |
| hq_ore_readout_modal.gd | Ore-store slip with raid-risk stamp + personal-stash move controls, map_card_style.gd-skinned (always light) |
| hq_gym_modal.gd | Combat skill card (level, XP bar, current + next-level HP/ATK/SPD via `Combat.skill_summary()`) + Train action card |
| lab_bench_modal_helpers.gd | Tier + progress-bar block, experiment controls, batch total text + outcome headings shared by the lab-bench modals |
| lab_bench_recipe_book_modal.gd | Recipe notebook page: five ore side tabs (live glyphs), found recipes filtered by ingredient ore, four entries per page with Prev/Next; tab+page live in modal data; an entry raises lab_bench_recipe_detail |
| lab_bench_recipe_detail_modal.gd | One found recipe above the book: description, ingredients, chance/effect/stock, batch slider + Craft (result returns to the book via `Modal.set_return`), Experiment, Back to book |
| lab_bench_notes_modal.gd | Per-pairing survey notes with found-recipe tier + experiment rows |
| lab_bench_probe_result_modal.gd | Probe outcome card |
| lab_bench_confirm_modal.gd | Gear-tap confirm: probe, craft ×N (batch slider, max = affordable) or inert warning, by cell state |
| contract_cancel_modal.gd | Navy BizBrief contract cancel confirm (Keep / Confirm → `Contracts.cancel`) |
| gift_modal.gd | Gift sheet for one faction: key members with relation, likes and cooldown; pick a member, give a cash option or one held consumable via `Diplomacy`; a landed gift opens the member's thread |
| negotiation_modal.gd | Peace talks sheet: the faction's standing terms + Accept, the player's draft (truce days, cash/weekly each way, vein toggles), Propose / Walk away (not when binding); all via FactionAI |

## scenes/phone_apps/*.gd — phone app views, one script per app

| File | Purpose |
|---|---|
| phone_app.gd | PhoneApp base: shell ref, build(content)/teardown() hooks, shared back button + refresh |
| phone_app_registry.gd | app id -> PhoneApp script table; the only dispatch path phone.gd uses |
| alarms_app.gd | Raid alarm rows: defend / leave undefended (two-tap) / decide later |
| bizbrief_app.gd | Navy BizBrief shell and tabs; Brief accounts, attention and shares; Manage Sales, production and procurement; gated Staff roster; pot-gated Stats (10-day trend, expense totals, ore source, items); hosts Short Pay and Guard Costs; staff poach alerts (Match / Let them go) |
| messages_app.gd | Conversation inbox (fixed-height rows: bold name, one-line `…` preview, unread pill, per-contact Clear) + single-thread staged bubble reveal/action bar (incl. Owen's text reply choices); thread opens scrolled to the newest message |
| todo_app.gd | ToDo app: collapsible questline sections from Todo, all_of checks as indented sub-rows; session-only expand/collapse overrides in a static var |
| factions_app.gd | London share table (ore/crafting toggle), London's politics (stance per pair, war/truce markers) and faction cards: archetype, ores, crafts, share bars, stance, pressure, peace talks at war, Gift, favour asked/owed (`Diplomacy`), partner price ask and trouble asks (`Partners`), intel level and what it reveals (`Intel`), activity log. |
| ticker_app.gd | Ticker News: state stories by recency, newest-first wires, full state and wire articles, live impact, same-axis Influence sheet. Stock Market: filters, Ore/Items lists, demand modifiers, price detail and chart, annotations and demand drivers |
| profile_app.gd | Stats, skills, equipment, and a two-slot Loadout card (equip/unequip) for the player and each recruited combat contact, plus the shared Dial loadout card; during prep Change loadout shows only participants' Loadout + Dial cards |
| dialer_app.gd | Phone recent-calls placeholder; no telephony state/actions |
| settings_app.gd | Reduced-motion and alarm-vibration preference controls |
| saveload_app.gd | Save slots, export/import (with copy-to-clipboard), New Game confirm |
| notifications_app.gd | Notification log with pending Defend / guard short-pay buttons |
| short_pay_view.gd | BizBrief short-pay sub-view: per-place guard keep steppers, live cost/reserve/cash needed, Confirm |
| guard_costs_view.gd | BizBrief Guard Costs sub-view (pot or not): next Monday bill + pending shortfall header, per-place guard payment chart over the history window, multi-select HQ/vein filter |
| bank_app.gd | Reynard's: oxblood-gradient balance panel (branded header, calc_gold figure) + day-grouped hairline transaction ledger, newest first |
| lodedinnit_app.gd | LodedInnit on its own plum/copper root (logo brand bar, Feed/People tabs): social-card Feed; People role groups with Role/ore/Wage controls (view state kept across profile trips); compact candidate profile (role, Lv/cap, wage, experience, room seats, ore pips) with a pinned hire area: Hire/Poach, block reason, float top-up Yes/No via `Hiring.hire` |
| property_app.gd | Harrow's: listings + particulars on own mounted root in brand chrome (ui-vision §10 exception), every tier in ladder order with its `image` photo; current tier is YOUR PLACE card (tenure, cost, risk, rooms, arrears, buy-out, plan). Particulars: hero, terms, copy, static plan if any, rent/buy (`Home.rent_to`/`buy_to`), losses |
| debug_app.gd | Debug Start-only tools: cash/calc/site spawners, combat launchers, one relation block (dropdown over every contact + faction, shows current relation, applies a delta), any-event trigger picker |

## data/*.json

| File | Consumed by |
|---|---|
| approaches.json | approaches.gd |
| barometer.json | barometer.gd (states/actions/prefs and wire article templates); ticker_app.gd (News branding, state-article headline/deck/body, per-category columnist byline + author note (`categoryBylines`), article/impact labels and category copy; Stock Market list/detail labels and empty states) |
| collective_barks.json | collective.gd |
| combat_prototype.json | combat_prototype.gd |
| combat_visuals.json | combat_stage.gd (locationBackdrops, backdrops, pose sheets, stage.spriteScale, stage.reserve); GameData.gd (territorialVariant pose spec); combat_director.gd (pacing.turnPause); turn_order_strip.gd (cardFrames) |
| contact_texts.json | contact_texts.gd (per-contact gate, interval, hold, vein source, rewards, text pool: Owen, Archie, Hakim, James, Nadia, Des; Nadia opens after her vein-sale closing beat, Des after meeting) |
| constants.json | calendar.gd (calendar), time_system.gd, jobs.gd, GameState.gd, contacts.gd (roster, roleFlags, skillCaps), rooms.gd (specialities), business.gd (weekly wages), rooms.gd (productionLogDays), business_stats.gd (businessStatsDays), shares.gd (sharesDays, sharesWindowDays), guardUpkeep, guard_kit.gd (guardKit), loadout.gd (loadout), events.gd (eventChecks, eventLabels) |
| constants.json (faction politics) | factions.gd (factionRivalry), faction_sim.gd (factionFloor), faction_ai.gd (factionStances, factionPressure, factionEscalation, factionWar, factionConclave), intel.gd (intel), raiding.gd (stockpileRaid), network_handler.gd (networkMenu), diplomacy.gd (factionFavours, factionGifts), partners.gd (partners), barometer.gd (factionEscalation.headlineCap) |
| daily_cycle.json | time_transition.gd (circle layout, sky clips, colours, timing) |
| dial.json | dial.gd |
| districts.json | widely read (sites, economy, factions, raiding) |
| enemies.json | combat.gd |
| faction_trade.json | economy.gd |
| factions.json | factions.gd, sites.gd, raiding.gd, debug_start.gd, faction_sim.gd (`startingHoldings`, `stockpilePlaces`, `stockpileGuards`, `cultivateSkill`, `fieldwork`, `craftSkill`, `craftTargets`, `raidKits`, `consumes`, `trading`, `industryIncome`), key_members.gd (`keyMembers`, `speaker`), diplomacy.gd (`sampleFavours`, `giftPrefs`), faction_ai.gd (`aggressionPersonality`, `weariness`) |
| lodedinnit.json | GameData.gd (`LODEDINNIT_*`), lodedinnit_feed.gd: feed cap/likes/author weights, per-candidate post voices (trait variants), shared canned comments, hire-status templates |
| hiring.json | contacts.gd (`roles` → `room_roles`), payroll.gd (`roles` → `role_skill_keys`): staff role registry; hiring.gd (`candidates`, merged into contact defaults by GameData.gd; `market`, `traits`): LodedInnit roster, flip/poach numbers, trait skip chance / role-XP mult |
| home.json | home.gd, approaches.gd, contacts.gd, property_app.gd (tier `image` listing photos) |
| floorplans.json | GameData.gd + floorplan_view.gd (per-tier plan asset, size, slot rects) |
| hq_visuals.json | hq_diorama.gd, hq*.gd screens |
| map_layout.json | map_layout.gd, map_hit_test.gd |
| market.json | market.gd (constants, sim start, priceLot, ore conversion rate, annotation cap/thresholds, delivery-log cap, Independents shares + buy cover, per-good normalStock/civilianDemand); shares.gd (via Market.independents_share) |
| map_palette.json | GameData.gd (validated) + map_palette.gd (Map tab light/dark colour tokens, faction/ore dark overrides) + map_controls.gd (`darkModeLabel`) |
| objectives.json | objectives.gd, todo.gd, collective.gd, business_quest.gd |
| offers.json | offers.gd (synthetic catalogue, scripted counterparties, offer expiry days, recurring term weeks, random-offer daily chance curve + qty bands, small-offer threshold, cancel relation hit), business_quest.gd (biz_starter_* chain + Archie nudge text, biz_recurring_* from Beat 3/6) |
| ore_types.json | widely read (economy, cultivating, sites, factions) |
| palette.json | GameData.gd (reference combat-art palette; `lodedinnit_*` brand tokens read by lodedinnit_app.gd) |
| phone_home.json | GameData.gd + phone_device_shell.gd (wallpaper, per-block status clock times, widget date format + fixed weather/battery copy; shell renders time/date from world.day/timeBlock) |
| recipes.json | widely read (crafting, bench, combat, dial, jobs, rooms) |
| sites.json | sites.gd, collective.gd, objectives.gd |
| stealth.json | raiding.gd |
| vein_alarm.json | cultivating.gd |
| vein_growth.json | widely read (cultivating, events, sites, vein_trade, faction_sim) |
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
live-tree check. `sim_combat_balance.gd` (+ `_impl.gd`) is the headless itemless-combat win-rate
sim behind R§3.7a's balance numbers.

## tools/*.py, *.html, *.js — asset/content pipeline tooling

`png_io.py` is a pure-stdlib PNG reader/writer. `make_palette_swatch.py` renders
the palette swatch; `pack_daily_cycle.py` preserves the retired cycle-atlas pipeline.
`quest-editor.html`/`quest-editor-mobile.html`
are the desktop/mobile quest content editors (`data/events/*.json`), sharing a byte-identical "Choice mechanics" section (option id/check/requires/goto, event `at`); `test_quest_editor.js`
unit-tests both, incl. lossless round-trips. `storyboard.html` is the local event-art storyboard review tool (boards in `.scratch/event-art/`, uploads into `assets/reference-plates/`; tabs Storyboard = elkjs flowchart (branch or card nodes, pan/zoom, click selects) + preview + cut list, Shots = plate/shot review, Comments); it also previews writing proposals (`.scratch/writing-revamp/*.md` JSON blocks: named-branch drafts, or flat events converted to branches), with a card editor (text/speaker/label/type; insert, delete with dangling-link warning, loop-safe reorder; card goto picker), a branch editor (new/rename/delete, `then` end/go-to/conditional over `condition_met` kinds; cycle-creating links refused), Undo and a manual Save that splices only the JSON block, following outcome/card goto and branch `then`. Its marked "Draft model (pure)" section is unit-tested by `test_storyboard.js`.
`plate_compositor/`: `compose.py` composites sprite or cut-out actors onto a blank reference plate (grid/palette lock, perspective scale, shadow, light tint, occluders) from `plates/*.json` + `shots/*.json`; `extract.py` cuts an AI-posed character off an AI-on-plate image (`poses/*.json`). See its README.
`hq_region_mapper.tscn` (+ `_logic.gd`, Godot) traces per-tier HQ zone hit polygons on `assets/hq/<tier>_room.png` and saves them into `data/hq_visuals.json` "rooms".

## docs/*.md and docs/adr/

See CLAUDE.md's source-of-truth table for REFERENCE.md, M0-PORT.md, M1-LONDON.md,
M1.5-NETWORK-MAP.md, CONTENT-GUIDE.md, CONTEXT.md, docs/adr/. Not in that table: `VISION.md`,
`M3-CALC-DISCOVERY.md`/`device-plan-spec.md` (provisional drafts),
`hq-diorama-vision.md`/`combat-animation-vision.md`/`ART-BIBLE.md` (screen/art direction),
`BUGS.md`, `BUGHUNT-2026-07-17.md`, `android-setup.md`, `agents/*.md` (see CLAUDE.md's Agent
skills section). `docs/adr/0001`–`0005`: Network Map deferral, site/NPC-claim rules, app-icon
contract, NPC-vein abandonment removal, event-image contract.
