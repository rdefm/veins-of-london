class_name MapScreen
extends Control

# M1.5 ticket 15: swaps M1's plain district-list top-level Map tab view
# (docs/M1-LONDON.md D4) for the real Network diagram (MapCanvas +
# MapControls' filter chip row) — the district panel and site/vein sheet
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

const SHEET_HEIGHT := 480.0

var _content: VBoxContainer
var _district_scroll: ScrollContainer
var _diagram_layer: Control
var _sheet_layer: Control


func _ready() -> void:
	UI.anchor_full_rect(self)

	_diagram_layer = _build_diagram_layer()
	add_child(_diagram_layer)

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
	margin.add_theme_constant_override("margin_top", 72)  # room below the top bar (TopBar.BAR_HEIGHT + 16)
	margin.add_theme_constant_override("margin_bottom", 80)  # room above the nav bar
	layer.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	content.add_child(UI.back_button("home"))
	content.add_child(UI.heading("The Network"))
	content.add_child(UI.muted_label("Tap a stop to work a site. Tap a district to prospect or travel."))

	var map_canvas := MapCanvas.new()

	var controls := MapControls.new()
	controls.map_canvas = map_canvas
	content.add_child(controls)

	content.add_child(_build_zoom_row(map_canvas))

	# N3: "map canvas is 3x the 390 column, inside a pan-capable Camera2D/
	# ScrollContainer; pinch-zoom is a stretch goal, pan is required." A
	# plain ScrollContainer gives free two-axis pan/drag for both mouse and
	# touch with no extra wiring, and MapCanvas's custom_minimum_size — set
	# from data/map_layout.json's mapSize * zoom_level, kept current by
	# MapCanvas._apply_zoom() on every zoom change — is exactly what keeps
	# that scrollable area's extents matching what's actually drawn.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.add_child(map_canvas)
	content.add_child(scroll)

	return layer


# N3 only requires pan ("pinch-zoom is a stretch goal") — a plain
# ScrollContainer at 1:1 gave that, but playtest screenshots showed it's not
# usable on a real phone width: mapSize is 1170x1560 (3x the 390 column), so
# almost the whole diagram sat off-screen and had to be pieced together by
# scrolling. +/- buttons cover the stretch goal without needing a pinch
# gesture, which can't be exercised or verified headless anyway. Button
# state is refreshed inline after each press rather than by rebuilding the
# row, since only the disabled flags at MapZoom's MIN/MAX ends change.
#
# `buttons` is a Dictionary, not two plain locals: GDScript lambdas capture
# outer locals by value at the *lambda's own creation* time, not live, so a
# `refresh` closure created before the "in" button was assigned would keep
# seeing null forever even after the assignment (caught by a runtime smoke
# test, not the type checker). A Dictionary's captured "value" is a
# reference to the same object, so filling in `buttons["in"]` after the
# fact is visible to every closure that already captured `_buttons`.
func _build_zoom_row(map_canvas: MapCanvas) -> Control:
	var row := UI.hbox(8)
	var buttons := {}

	var refresh := func():
		buttons["out"].disabled = map_canvas.zoom_level <= MapZoom.MIN
		buttons["in"].disabled = map_canvas.zoom_level >= MapZoom.MAX

	buttons["out"] = UI.button("− Zoom out", func():
		map_canvas.zoom_out()
		refresh.call()
	)
	row.add_child(buttons["out"])

	buttons["in"] = UI.button("+ Zoom in", func():
		map_canvas.zoom_in()
		refresh.call()
	)
	row.add_child(buttons["in"])

	refresh.call()
	return row


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
		row.add_child(UI.muted_label("No prospecting here"))
	elif not GameState.state["flags"]["cultivationTutorialSeen"]:
		# M1-LONDON D7: prospecting locked until the cultivating tutorial (D6).
		row.add_child(UI.muted_label("Prospecting — see Archie first"))
	else:
		var prospect_button := UI.button(UI.format_block_cost_label("Prospect", Travel.blocks_needed(district_id), 1), func(): Sites.prospect(district_id))
		prospect_button.disabled = not Travel.can_afford(district_id, 1)
		row.add_child(prospect_button)

	if GameState.state["world"]["currentDistrict"] == district_id:
		row.add_child(UI.muted_label("Travel (already here)"))
	else:
		var travel_button := UI.button(UI.format_block_cost_label("Travel", Travel.blocks_needed(district_id), 0), func(): Travel.travel_to(district_id))
		travel_button.disabled = not Travel.can_afford(district_id, 0)
		row.add_child(travel_button)

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
	if site["npcClaimed"]:
		return "Claimed by someone else"
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
	_sheet_layer.add_child(dim)

	var card := PanelContainer.new()
	UI.anchor_bottom_wide(card)
	card.offset_top = -SHEET_HEIGHT
	card.offset_bottom = 0
	_sheet_layer.add_child(card)

	var scroll := UI.scroll_container()
	card.add_child(scroll)

	var content := UI.vbox(8)
	scroll.add_child(content)

	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	content.add_child(UI.heading("%s — %s %s" % [String(site["tier"]).capitalize(), ore["symbol"], ore["name"]]))
	content.add_child(UI.muted_label(_site_claim_state_text(site)))

	var bonuses: Array = site["bonuses"]
	if not bonuses.is_empty():
		content.add_child(UI.muted_label("Bonuses: %s" % ", ".join(bonuses)))
	if site["hasNaturalVein"] and not site["claimed"]:
		content.add_child(UI.muted_label("A natural vein runs here — claiming grants a free bonus vein."))

	if site["npcClaimed"]:
		content.add_child(UI.muted_label("Someone's already working this site. Nothing to do here (for now)."))
	elif site["claimed"]:
		_build_claimed_site_content(content, site)
	elif site["tier"] == "barren":
		content.add_child(UI.muted_label("Barren — nothing to seed here."))
	else:
		content.add_child(_build_seed_row(site))

	content.add_child(UI.button("Close", func(): MapNav.close_site_sheet()))


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
	var label_text := "%s · %s" % [UI.format_cost_label(cost, player["orichalchum"]), UI.block_cost_suffix(Travel.blocks_needed(district), 1)]

	var have: int = player["orichalchum"].get(ore_type, 0)
	var b := UI.button(label_text, func(): Sites.attempt_seed(site_id))
	b.disabled = have < GameData.SEED_ORE_COST or not Travel.can_afford(district, 1)
	return b


func _build_vein_action_card(vein: Dictionary) -> Control:
	var c := UI.card()
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
	var security: Dictionary = GameData.VEIN_SECURITY[vein["security"]]
	var level_cap: int = Cultivating.get_level_cap(vein)
	var district: String = vein["district"]
	var vein_id: String = vein["id"]

	c["content"].add_child(UI.heading("%s %s — Lv%d %s" % [ore["symbol"], ore["name"], vein["level"], vein["levelLabel"]], 14))
	c["content"].add_child(UI.muted_label(vein["location"]))
	c["content"].add_child(UI.label(("✅ Ready to harvest" if vein["charged"] else "⏳ Charging") + "   🔒 " + security["label"]))

	var recharge_blocks: int = Cultivating.get_effective_recharge_blocks(vein)
	var charge_label := "Full" if vein["charged"] else "%d/%d blocks" % [vein["chargeBlocks"], recharge_blocks]
	c["content"].add_child(UI.muted_label("Charge: %s" % charge_label))
	c["content"].add_child(UI.bar(recharge_blocks if vein["charged"] else vein["chargeBlocks"], recharge_blocks))

	if vein["level"] < level_cap:
		c["content"].add_child(UI.muted_label("Development: %d/%d" % [vein["devBar"], level_data["devBarMax"]]))
		c["content"].add_child(UI.bar(vein["devBar"], level_data["devBarMax"]))
	else:
		c["content"].add_child(UI.muted_label("Development: Max level"))

	var travel_blocks: int = Travel.blocks_needed(district)
	var actions := UI.hbox()

	var cultivate_button := UI.button(UI.format_block_cost_label("Cultivate", travel_blocks, 1), func(): Cultivating.cultivate(vein_id))
	cultivate_button.disabled = not Travel.can_afford(district, 1)
	actions.add_child(cultivate_button)

	if vein["charged"]:
		var cautious_button := UI.button(UI.format_block_cost_label("Harvest (cautious)", travel_blocks, 1), func(): Cultivating.harvest_cautious(vein_id))
		cautious_button.disabled = not Travel.can_afford(district, 1)
		actions.add_child(cautious_button)

		var full_button := UI.button(UI.format_block_cost_label("Harvest (full)", travel_blocks, 1), func(): Cultivating.harvest_full(vein_id))
		full_button.disabled = not Travel.can_afford(district, 1)
		actions.add_child(full_button)

	c["content"].add_child(actions)
	c["content"].add_child(_build_security_row(vein))

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
