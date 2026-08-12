class_name MapScreen
extends Control

# M1.5 ticket 15: swaps M1's plain district-list top-level Map tab view
# (docs/M1-LONDON.md D4) for the real Network diagram (MapCanvas +
# MapControls' filter drawer) — the district panel and site/vein sheet
# below are unchanged from M1 and reused verbatim; only how you reach them
# changes (tapping a stop/tick or a district label/zone on the diagram,
# handled by MapCanvas itself, per M1.5 N5, instead of a "View"/"Open" list
# row here).
#
# _diagram_layer is built once in _ready() and never torn down: MapCanvas
# already rebuilds its own drawing from GameState.state on every
# state_changed (see map_canvas.gd), so recreating it here on every refresh
# would just discard scroll position for no benefit. _refresh() only
# toggles which of _diagram_layer / _district_scroll is visible, based on
# whether a district is selected.
#
# Map-filters ticket 02: the app-wide TopBar (cash/day/bag) is hidden on
# this screen (Main.gd's TOP_BAR_HIDDEN_SCREENS) so the diagram gets the
# full screen above the NavBar — this screen's own top bar (hamburger/
# title/bag, _build_top_bar()) replaces it, and its bag button calls the
# same Bag.open() the global one did, so nothing is lost.

const SHEET_HEIGHT := 480.0

var _content: VBoxContainer
var _district_scroll: ScrollContainer
var _diagram_layer: Control
var _map_controls: MapControls
var _sheet_layer: Control

# Ticket 03: the district bubble overlay -- same "sibling over whatever it
# should float above" shape as _sheet_layer, added last (see _ready()) so it
# draws above the diagram, the filter drawer, and everything else. _map_canvas
# needs to be kept (unlike _build_diagram_layer()'s previous local-only var)
# so _ready() can connect its district_tapped signal and the bubble's
# Prospect handler can call back into it for the result animation.
# _bubble_district_id tracks which district the currently-open bubble belongs
# to, read by _on_bubble_option_selected once the option is picked.
var _map_canvas: MapCanvas
var _bubble: MapBubble
var _bubble_district_id: String = ""


func _ready() -> void:
	UI.anchor_full_rect(self)

	_diagram_layer = _build_diagram_layer()
	add_child(_diagram_layer)
	# _map_controls (the filter drawer) is a full-rect overlay, not a row
	# inside _diagram_layer's VBoxContainer — see map_controls.gd's header
	# comment for why. Built inside _build_diagram_layer() (that's where
	# map_canvas, which it needs a reference to, is created) but added to
	# the tree here so it draws above the whole diagram, not just its margin.
	add_child(_map_controls)

	# M1-LONDON D6's archie_cultivation used to auto-fire here on first
	# Map-tab visit after archiePartnerSeen. M1.5 T13 replaces that with a
	# contact pin on the Network map (systems/map_pins.gd) — the event now
	# starts only when that pin is tapped, matching N2's "contact pin when
	# an event awaits at an address" for any future pin-triggered event,
	# not just this one.
	_content = UI.screen_body(self)
	# UI.screen_body() returns the innermost VBoxContainer; its grandparent
	# is the ScrollContainer it built (content -> margin -> ScrollContainer)
	# — kept here so _refresh() can hide the whole district-panel scroll
	# view (not just empty its content) while the diagram is showing,
	# otherwise its full-rect ScrollContainer sits on top of the diagram
	# and eats every tap.
	_district_scroll = _content.get_parent().get_parent() as ScrollContainer

	_sheet_layer = Control.new()
	UI.anchor_full_rect(_sheet_layer)
	_sheet_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheet_layer)

	# Ticket 03: added last so it draws above _sheet_layer's own site sheet
	# too -- the two are never open at once in practice (a district tap
	# closes/never opens a site sheet), but topmost is the safe default for
	# a popup either way.
	_bubble = MapBubble.new()
	_bubble.option_selected.connect(_on_bubble_option_selected)
	add_child(_bubble)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()
	for child in _sheet_layer.get_children():
		child.queue_free()

	var nav: Dictionary = GameState.state["mapNav"]
	var selected_district = nav.get("selectedDistrict")
	var selected_site_id = nav.get("selectedSiteId")

	_diagram_layer.visible = selected_district == null
	_district_scroll.visible = selected_district != null

	if selected_district != null:
		_build_district_panel(selected_district)

	if selected_site_id != null:
		_build_site_sheet(selected_site_id)


# ── diagram (top-level Network view) ─────────────────────────────────

func _build_diagram_layer() -> Control:
	var layer := VBoxContainer.new()
	UI.anchor_full_rect(layer)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	# The global TopBar is hidden on this screen (see class comment above),
	# so this only needs a small top inset, not room for it.
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 80)  # room above the nav bar
	layer.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	_map_canvas = MapCanvas.new()
	# Ticket 03: fires once a district tap's pan finishes (see
	# MapCanvas._open_district_bubble's own comment) -- this is where the
	# bubble actually gets shown.
	_map_canvas.district_tapped.connect(_on_district_tapped)

	_map_controls = MapControls.new()
	_map_controls.map_canvas = _map_canvas

	content.add_child(_build_top_bar())

	# N3: "map canvas is 3x the 390 column, inside a pan-capable Camera2D/
	# ScrollContainer; pinch-zoom is a stretch goal, pan is required."
	# TouchScrollContainer (not a bare ScrollContainer — see its own class
	# comment) is what actually makes single-finger pan work here: vanilla
	# ScrollContainer has no touch-drag-to-scroll at all, found via
	# on-device playtest (swiping did nothing; only the rendered scrollbar
	# thumb responded to drag). MapCanvas's custom_minimum_size — set from
	# data/map_layout.json's mapSize * zoom_level, kept current by
	# MapCanvas._apply_zoom() on every zoom change — is what keeps this
	# scrollable area's extents matching what's actually drawn. Zoom itself
	# is driven by a real two-finger pinch on MapCanvas (see its
	# _gui_input) rather than a button row here — an earlier +/- button
	# version got replaced after on-device playtest found it overlapped the
	# old inline filter chip row (map_controls.gd, since replaced by ticket
	# 03's drawer) and a pinch is the expected mobile gesture anyway. MapCanvas only
	# accept_event()s during that active pinch, so a single finger's drag
	# still bubbles up to this TouchScrollContainer and pans normally.
	var scroll := TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.add_child(_map_canvas)
	content.add_child(scroll)

	return layer


# Map-filters ticket 02/03: hamburger (left) / "The Network" title (centre)
# / bag icon (right), replacing the old back-button/heading/hint stack and
# the global TopBar this screen hides. Plain HBoxContainer, not a
# separately-anchored bar — it sits in the same content flow the old header
# rows did. Hamburger opens _map_controls' filter drawer; bag calls the same
# Bag.open() the global TopBar's bag button used, since that bar is hidden
# here.
#
# Bugfixes ticket 13: both were plain "☰"/"🎒" text glyphs, invisible (but
# still tappable) on-device because non-ASCII glyphs don't render in the
# exported build's font — same gap icons.gd's draw_home/draw_pin already
# worked around elsewhere. UI.icon_button() draws the Icons vector glyph
# instead, same as those.
func _build_top_bar() -> Control:
	var row := UI.hbox(8)

	row.add_child(UI.icon_button(Icons.draw_hamburger, func(): _map_controls.toggle()))

	var title := UI.heading("The Network")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(title)

	row.add_child(UI.icon_button(Icons.draw_bag, func(): Bag.open()))

	return row


# ── district bubble (ticket 03) ─────────────────────────────────────

# Converts _map_canvas's own local (already-zoomed) anchor into _bubble's
# local space via global_position -- both are plain, unscaled Controls
# sitting in this same screen's tree, so a straight global_position
# subtraction is enough (same idiom MapZoom.to_logical()'s screen-space
# conversions rely on elsewhere in this feature).
func _on_district_tapped(district_id: String, canvas_anchor: Vector2) -> void:
	_bubble_district_id = district_id
	var anchor: Vector2 = _map_canvas.global_position + canvas_anchor - _bubble.global_position
	_bubble.open(anchor, _build_district_bubble_options(district_id))


# DistrictBubble.district_options() (systems/district_bubble.gd) owns the
# disabled/reason gating rules -- this only turns that pure data into the
# label text MapBubble.open() expects, same split _build_district_actions
# already draws between gating and its own button label formatting.
#
# The Prospect label always carries its cost suffix, disabled or not --
# _build_district_actions' own real button (its siteCap/tutorial branches
# swap in a muted label instead of a button, so this only compares against
# its Travel.can_afford-disabled case) keeps the same "Prospect — 1 block"
# text either way and only toggles Button.disabled; dropping the suffix
# specifically while disabled would read as a different, cheaper action
# rather than the same one you currently can't afford.
func _build_district_bubble_options(district_id: String) -> Array:
	var result: Array = []
	for opt in DistrictBubble.district_options(district_id):
		var label := UI.format_block_cost_label("Prospect", 1) if opt["id"] == DistrictBubble.PROSPECT_ID else "View Veins"
		result.append({
			"id": opt["id"],
			"label": label,
			"disabled": opt["disabled"],
			"reason": opt["reason"],
		})
	return result


# MapBubble already closed itself before emitting this (see its own
# _select()), so Prospect's inline result animation never fights the popup
# for the screen. View Veins' MapNav.select_district() call (inside
# DistrictBubble.apply_option) triggers _refresh() via the usual
# EventBus.state_changed round-trip, same as every other state-changing
# button on this screen.
#
# tests/test_map_screen.gd covers the view_veins branch directly (no Node
# access needed -- it's a straight DistrictBubble.apply_option() call). The
# prospect branch's _map_canvas.play_prospect_result() call isn't covered
# the same way: _map_canvas is only ever assigned inside _ready(), and even
# after that its own _playback_layer only exists once ITS _ready() has
# cascaded too (which a manually-invoked, never-added-to-a-live-tree
# screen._ready() doesn't trigger) -- Node/Tween-side, same "isn't exercised
# here" split test_map_events.gd's own comment documents for the rest of
# this feature's animation code. DistrictBubble.apply_option()'s own tests
# (tests/test_district_bubble.gd) already cover that this branch really
# does call Sites.prospect() and report its ok/fail correctly.
func _on_bubble_option_selected(option_id: String) -> void:
	var result := DistrictBubble.apply_option(option_id, _bubble_district_id)
	if option_id == DistrictBubble.PROSPECT_ID:
		_map_canvas.play_prospect_result(_bubble_district_id, result["ok"])


# ── district panel ──────────────────────────────────────────────────

func _build_district_panel(district_id: String) -> void:
	var district: Dictionary = GameData.DISTRICTS[district_id]

	_content.add_child(UI.button("‹ Back to districts", func(): MapNav.back_to_list()))
	_content.add_child(UI.heading(district["name"]))
	_content.add_child(UI.label(district["blurb"]))

	var indicators := Districts.derived_indicators(district_id)
	if not indicators.is_empty():
		_content.add_child(UI.muted_label(" · ".join(indicators)))

	_content.add_child(_build_district_actions(district_id))

	_content.add_child(UI.heading("Sites", 15))
	var sites := Sites.sites_in_district(district_id)
	if sites.is_empty():
		_content.add_child(UI.muted_label("No sites discovered yet. Prospect to find one."))
	else:
		for site in sites:
			_content.add_child(_build_site_row(site))


func _build_district_actions(district_id: String) -> Control:
	var district: Dictionary = GameData.DISTRICTS[district_id]
	var row := UI.hbox()

	var site_cap: int = district.get("siteCap", 0)
	if site_cap <= 0:
		# UI.expand_fill needed: a Label inside an HBoxContainer without it
		# collapses to one character per line instead of wrapping normally
		# (see UI.checklist_row()'s comment for why).
		row.add_child(UI.expand_fill(UI.muted_label("No prospecting here")))
	elif not GameState.state["flags"]["cultivationTutorialSeen"]:
		# M1-LONDON D7: prospecting locked until the cultivating tutorial (D6).
		row.add_child(UI.expand_fill(UI.muted_label("Prospecting — see Archie first")))
	else:
		var prospect_button := UI.button(UI.format_block_cost_label("Prospect", 1), func(): Sites.prospect(district_id))
		prospect_button.disabled = not Travel.can_afford(district_id, 1)
		row.add_child(prospect_button)

	if GameState.state["world"]["currentDistrict"] == district_id:
		row.add_child(UI.expand_fill(UI.muted_label("Travel (already here)")))
	else:
		# D3: travel is free (faction-resource-economy ticket 05) — no block
		# cost to show, so this is a plain button, not a cost-labelled one.
		row.add_child(UI.button("Travel", func(): Travel.travel_to(district_id)))

	return row


func _build_site_row(site: Dictionary) -> Control:
	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	var site_id: String = site["id"]

	var c := UI.card()
	c["content"].add_child(UI.heading("%s — %s %s" % [String(site["tier"]).capitalize(), ore["symbol"], ore["name"]], 14))
	c["content"].add_child(UI.muted_label(_site_claim_state_text(site)))
	c["content"].add_child(UI.button("View", func(): MapNav.select_site(site_id)))
	return c["panel"]


func _site_claim_state_text(site: Dictionary) -> String:
	if site["claimed"]:
		return "Yours"
	if site["factionVein"] != null:
		return "Claimed by %s" % GameData.FACTIONS[site["factionVein"]["factionId"]]["shortName"]
	return "Unclaimed"


# ── site/vein sheet (bottom sheet) ──────────────────────────────────

func _build_site_sheet(site_id: String) -> void:
	var site = Sites.find_site(site_id)
	if site == null:
		return

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	# Bugfixes ticket 03: tap-outside-to-close, same pattern as
	# map_controls.gd's filter drawer — without this, STOP just swallows the
	# tap silently, which reads as broken rather than a way to close the sheet.
	dim.gui_input.connect(_on_sheet_dim_gui_input)
	_sheet_layer.add_child(dim)

	var card := PanelContainer.new()
	UI.anchor_bottom_wide(card)
	card.offset_top = -SHEET_HEIGHT
	card.offset_bottom = 0
	_sheet_layer.add_child(card)

	var scroll := UI.scroll_container()
	card.add_child(scroll)

	# Anchors are ignored for a ScrollContainer's child, and without
	# SIZE_EXPAND_FILL it shrinks to its content's minimum width instead of
	# the sheet's — the same failure mode UI.screen_body()'s own comment
	# documents (a word-wrapped Label's minimum width collapses near 0,
	# breaking mid-word), and the same fix bag_drawer.gd needed for its ore
	# rows.
	var content := UI.vbox(8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	content.add_child(UI.heading("%s — %s %s" % [String(site["tier"]).capitalize(), ore["symbol"], ore["name"]]))
	content.add_child(UI.muted_label(_site_claim_state_text(site)))

	var bonuses: Array = site["bonuses"]
	if not bonuses.is_empty():
		content.add_child(UI.muted_label("Bonuses: %s" % ", ".join(bonuses)))
	if site["hasNaturalVein"] and not site["claimed"]:
		content.add_child(UI.muted_label("A natural vein runs here — claiming grants a free bonus vein."))

	if site["factionVein"] != null:
		_build_faction_vein_content(content, site["factionVein"])
	elif site["claimed"]:
		_build_claimed_site_content(content, site)
	elif site["tier"] == "barren":
		content.add_child(UI.muted_label("Barren — nothing to seed here."))
	else:
		content.add_child(_build_seed_row(site))

	content.add_child(UI.button("Close", func(): MapNav.close_site_sheet()))


func _on_sheet_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		MapNav.close_site_sheet()


# faction-vein-ownership T04: read-only faction ownership display —
# deliberately just facts, no relation-flavoured text or raid-difficulty
# hinting (PRD: "kept plain for now"). No cultivate/charge here (not the
# player's vein). vein-raiding ticket 03 adds the Raid action below, gated
# the same travel/time-block way every other districted action is
# (Travel.can_afford), handing off to the district event-card engine via
# Raiding.begin_raid() rather than a bespoke raid screen.
func _build_faction_vein_content(content: VBoxContainer, vein: Dictionary) -> void:
	var faction: Dictionary = GameData.FACTIONS[vein["factionId"]]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var security: Dictionary = GameData.VEIN_SECURITY[vein["security"]]
	var district: String = vein["district"]

	var c := UI.card()
	c["content"].add_child(UI.tinted_label(faction["name"], Color(faction["colour"])))
	c["content"].add_child(UI.muted_label("%s %s — Lv%d %s" % [ore["symbol"], ore["name"], vein["level"], vein["levelLabel"]]))
	c["content"].add_child(UI.muted_label("🔒 %s" % security["label"]))

	var raid_button := UI.button(UI.format_block_cost_label("Raid", 1), func(): Raiding.begin_raid(vein))
	raid_button.disabled = not Travel.can_afford(district, 1)
	c["content"].add_child(raid_button)

	content.add_child(c["panel"])


func _build_claimed_site_content(content: VBoxContainer, site: Dictionary) -> void:
	var veins := _veins_for_site(site["id"])
	if veins.is_empty():
		content.add_child(UI.muted_label("This site's vein has collapsed. Nothing to do here."))
		return
	for vein in veins:
		content.add_child(_build_vein_action_card(vein))


func _veins_for_site(site_id: String) -> Array:
	var result: Array = []
	for vein in GameState.state["player"]["veins"]:
		if vein.get("siteId") == site_id:
			result.append(vein)
	return result


func _build_seed_row(site: Dictionary) -> Control:
	var player: Dictionary = GameState.state["player"]
	var ore_type: String = site["oreType"]
	var district: String = site["district"]
	var site_id: String = site["id"]

	var cost := { "label": "Seed", "resource": ore_type, "amount": GameData.SEED_ORE_COST }
	var label_text := "%s · %s" % [UI.format_cost_label(cost, player["orichalchum"]), UI.block_cost_suffix(1)]

	var have: int = player["orichalchum"].get(ore_type, 0)
	var b := UI.button(label_text, func(): Sites.attempt_seed(site_id))
	b.disabled = have < GameData.SEED_ORE_COST or not Travel.can_afford(district, 1)
	return b


func _build_vein_action_card(vein: Dictionary) -> Control:
	var c := UI.card()
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
	var security: Dictionary = GameData.VEIN_SECURITY[vein["security"]]
	var district: String = vein["district"]
	var vein_id: String = vein["id"]
	var at_max_level := Cultivating.is_at_max_level(vein)

	c["content"].add_child(UI.heading("%s %s — Lv%d %s" % [ore["symbol"], ore["name"], vein["level"], vein["levelLabel"]], 14))
	c["content"].add_child(UI.muted_label(vein["location"]))
	c["content"].add_child(UI.label(("✅ Ready to harvest" if vein["charged"] else "⏳ Charging") + "   🔒 " + security["label"]))

	var recharge_blocks: int = Cultivating.get_effective_recharge_blocks(vein)
	var charge_label := "Full" if vein["charged"] else "%d/%d blocks" % [vein["chargeBlocks"], recharge_blocks]
	c["content"].add_child(UI.muted_label("Charge: %s" % charge_label))
	c["content"].add_child(UI.bar(recharge_blocks if vein["charged"] else vein["chargeBlocks"], recharge_blocks))

	if at_max_level:
		c["content"].add_child(UI.muted_label("Development: Max level"))
	else:
		c["content"].add_child(UI.muted_label("Development: %d/%d" % [vein["devBar"], level_data["devBarMax"]]))
		c["content"].add_child(UI.bar(vein["devBar"], level_data["devBarMax"]))

	# UI.hflow, not UI.hbox: a charged vein shows all three buttons at once,
	# which overflows a narrow phone's width in a plain HBoxContainer
	# (bugfixes ticket 05) — flow-wrapping keeps every button fully on-screen
	# and tappable instead of clipped past the right edge.
	var actions := UI.hflow()

	var cultivate_label := "Vein at max level" if at_max_level else UI.format_block_cost_label("Cultivate", 1)
	var cultivate_button := UI.button(cultivate_label, func(): Cultivating.cultivate(vein_id))
	cultivate_button.disabled = at_max_level or not Travel.can_afford(district, 1)
	actions.add_child(cultivate_button)

	if vein["charged"]:
		var cautious_button := UI.button(UI.format_block_cost_label("Harvest (cautious)", 1), func(): Cultivating.harvest_cautious(vein_id))
		cautious_button.disabled = not Travel.can_afford(district, 1)
		actions.add_child(cautious_button)

		var full_button := UI.button(UI.format_block_cost_label("Harvest (full)", 1), func(): Cultivating.harvest_full(vein_id))
		full_button.disabled = not Travel.can_afford(district, 1)
		actions.add_child(full_button)

	c["content"].add_child(actions)
	c["content"].add_child(_build_security_row(vein))
	c["content"].add_child(_build_alarm_row(vein))

	return c["panel"]


func _build_security_row(vein: Dictionary) -> Control:
	var next_id = Cultivating.next_security_tier_id(vein["security"])
	if next_id == null:
		return UI.muted_label("Security: maximum (%s)" % GameData.VEIN_SECURITY[vein["security"]]["label"])

	var next_data: Dictionary = GameData.VEIN_SECURITY[next_id]
	var player: Dictionary = GameState.state["player"]
	var cost := { "label": "Upgrade to %s" % next_data["label"], "resource": "cash", "amount": next_data["cost"] }
	var vein_id: String = vein["id"]

	var b := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.upgrade_vein_security(vein_id))
	b.disabled = player["cash"] < next_data["cost"]
	return b


# vein-raiding ticket 05: independent of _build_security_row above — the
# alarm upgrade isn't part of the security tier ladder, per the PRD.
func _build_alarm_row(vein: Dictionary) -> Control:
	var alarm_data: Dictionary = GameData.VEIN_ALARM[Cultivating.ALARM_UPGRADE_ID]
	if vein["alarmUpgrades"].has(Cultivating.ALARM_UPGRADE_ID):
		return UI.muted_label("%s: installed" % alarm_data["label"])

	var player: Dictionary = GameState.state["player"]
	var cost := { "label": "Install %s" % alarm_data["label"], "resource": "cash", "amount": alarm_data["cost"] }
	var vein_id: String = vein["id"]

	var b := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.add_alarm(vein_id))
	b.disabled = player["cash"] < alarm_data["cost"]
	return b
