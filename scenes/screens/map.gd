class_name MapScreen
extends Control

const SHEET_HEIGHT := 480.0
const MENU_BUTTON_MARGIN := 8.0
const BUBBLE_MODE_DISTRICT := "district"
const BUBBLE_MODE_STATION := "station"

var _content: VBoxContainer
var _district_scroll: ScrollContainer
var _diagram_layer: Control
var _map_controls: MapControls
var _sheet_layer: Control
var _map_canvas: MapCanvas
var _map_legend: MapLegend
var _map_zoom_buttons: MapZoomButtons
var _bubble: MapBubble
var _vein_bubble: VeinBubble
var _diagram_paper: ColorRect
var _menu_button: Button
var _bubble_district_id: String = ""
var _bubble_mode: String = ""
var _bubble_stop: Dictionary = {}
var _raid_bring_archie: bool = false
var _raid_bring_archie_site_id: String = ""

func _ready() -> void:
	UI.anchor_full_rect(self)

	_diagram_layer = _build_diagram_layer()
	add_child(_diagram_layer)
	add_child(_map_controls)
	_content = UI.screen_body(self)
	_district_scroll = _content.get_parent().get_parent() as ScrollContainer

	_sheet_layer = Control.new()
	UI.anchor_full_rect(_sheet_layer)
	_sheet_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheet_layer)
	_bubble = MapBubble.new()
	_bubble.option_selected.connect(_on_bubble_option_selected)
	add_child(_bubble)
	_vein_bubble = VeinBubble.new()
	_vein_bubble.action_selected.connect(_on_vein_bubble_action_selected)
	_vein_bubble.info_selected.connect(_on_vein_bubble_info_selected)
	add_child(_vein_bubble)

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
	var selected_vein_id = nav.get("selectedVeinId")

	_diagram_layer.visible = selected_district == null
	_district_scroll.visible = selected_district != null

	if selected_district != null:
		_build_district_panel(selected_district)

	if selected_vein_id != null:
		var vein = Cultivating.find_vein(selected_vein_id)
		if vein != null:
			_sheet_layer.add_child(VeinDetailPanel.build(vein))
	elif selected_site_id != null:
		_build_site_sheet(selected_site_id)

	_style_diagram_chrome()

# The diagram fills everything between the top board and the nav dock; the
# menu button floats over it like the legend and zoom pill (M1.5 §Map palette
# chrome tokens, both modes).
func _build_diagram_layer() -> Control:
	var layer := Control.new()
	UI.anchor_below_bars(layer)

	_diagram_paper = ColorRect.new()
	UI.anchor_full_rect(_diagram_paper)
	_diagram_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_diagram_paper)

	_map_canvas = MapCanvas.new()
	_map_canvas.district_tapped.connect(_on_district_tapped)
	_map_canvas.station_tapped.connect(_on_station_tapped)

	_map_controls = MapControls.new()
	_map_controls.map_canvas = _map_canvas

	var scroll := TouchScrollContainer.new()
	UI.anchor_full_rect(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.add_child(_map_canvas)
	layer.add_child(scroll)

	_map_legend = MapLegend.new()
	layer.add_child(_map_legend)
	_map_zoom_buttons = MapZoomButtons.new()
	_map_zoom_buttons.map_canvas = _map_canvas
	layer.add_child(_map_zoom_buttons)

	_menu_button = UI.icon_button(Icons.draw_hamburger, func(): _map_controls.toggle())
	_menu_button.tooltip_text = "Map options"
	_menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_menu_button.offset_left = -UI.ICON_BUTTON_SIZE - MENU_BUTTON_MARGIN
	_menu_button.offset_right = -MENU_BUTTON_MARGIN
	_menu_button.offset_top = MENU_BUTTON_MARGIN
	_menu_button.offset_bottom = MENU_BUTTON_MARGIN + UI.ICON_BUTTON_SIZE
	layer.add_child(_menu_button)

	return layer


# Re-read from MapPalette on every refresh so a dark-mode toggle restyles the
# paper and menu button in place.
func _style_diagram_chrome() -> void:
	_diagram_paper.color = MapPalette.colour("paper")
	var glyph: Control = _menu_button.get_child(0)
	glyph.set("colour_override", MapPalette.colour("chromeInk"))
	glyph.queue_redraw()
	for state in ["normal", "hover", "pressed", "focus"]:
		_menu_button.add_theme_stylebox_override(state, _menu_button_style(state))


func _menu_button_style(state: String) -> StyleBoxFlat:
	var ink := MapPalette.colour("chromeInk")
	var fill := MapPalette.colour("chromePaper")
	match state:
		"hover", "focus":
			fill = fill.lerp(ink, 0.06)
		"pressed":
			fill = fill.lerp(ink, 0.12)
	var style := UI.bordered_panel_style(fill, MapPalette.colour("chromeBorder"), MapZoomButtons.PILL_RADIUS, 0, 0)
	style.shadow_color = Color(MapPalette.colour("shadow"), 0.13)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _on_district_tapped(district_id: String, canvas_anchor: Vector2) -> void:
	_vein_bubble.close()
	_bubble_mode = BUBBLE_MODE_DISTRICT
	_bubble_district_id = district_id
	var anchor: Vector2 = _map_canvas.global_position + canvas_anchor - _bubble.global_position
	_bubble.open(anchor, _build_district_bubble_options(district_id), Vector2.ZERO, true)
func _build_district_bubble_options(district_id: String) -> Array:
	var result: Array = []
	for opt in DistrictBubble.district_options(district_id):
		result.append({
			"id": opt["id"],
			"label": _district_bubble_option_label(opt["id"], not opt["disabled"]),
			"icon": _district_bubble_option_icon(opt["id"]),
			"disabled": opt["disabled"],
			"reason": opt["reason"],
		})
	return result
func _district_bubble_option_label(option_id: String, available: bool = true) -> String:
	match option_id:
		DistrictBubble.PROSPECT_ID:
			return UI.format_block_cost_label("Prospect", 1, available)
		DistrictBubble.LIST_ID:
			return "List view"
		_:
			return "View Veins"
func _district_bubble_option_icon(option_id: String) -> Callable:
	match option_id:
		DistrictBubble.PROSPECT_ID:
			return Icons.draw_prospect
		DistrictBubble.LIST_ID:
			return Icons.draw_hamburger
		_:
			return Icons.draw_search
func _on_bubble_option_selected(option_id: String) -> void:
	if _bubble_mode == BUBBLE_MODE_STATION:
		_on_station_bubble_option_selected(option_id)
		return

	var result := DistrictBubble.apply_option(option_id, _bubble_district_id)
	if option_id == DistrictBubble.PROSPECT_ID:
		_map_canvas.play_prospect_result(_bubble_district_id, result["ok"])
func _on_station_tapped(stop: Dictionary, canvas_anchor: Vector2) -> void:
	if stop["kind"] == "vein" and stop.get("owner") == "player":
		_bubble.close()
		_bubble_stop = stop
		var vein_anchor: Vector2 = _map_canvas.global_position + canvas_anchor - _vein_bubble.global_position
		_vein_bubble.open(vein_anchor, stop)
		return

	_vein_bubble.close()
	_bubble_mode = BUBBLE_MODE_STATION
	_bubble_stop = stop
	var anchor: Vector2 = _map_canvas.global_position + canvas_anchor - _bubble.global_position
	_bubble.open(anchor, _build_station_bubble_options(stop))
func _on_vein_bubble_action_selected(option_id: String) -> void:
	var result := StationBubble.apply_option(option_id, _bubble_stop)
	# A successful cultivate plays the canvas's own ring tween instead of the pulse.
	if option_id == StationBubble.CULTIVATE_ID and result["ok"]:
		return
	_map_canvas.play_action_result(_bubble_stop["position"], result["ok"])
func _on_vein_bubble_info_selected() -> void:
	MapNav.select_vein_detail(_bubble_stop["vein"]["id"])
func _build_station_bubble_options(stop: Dictionary) -> Array:
	var result: Array = []
	for opt in StationBubble.station_options(stop):
		result.append({
			"id": opt["id"],
			"label": _station_option_label(opt["id"], stop, not opt["disabled"]),
			"disabled": opt["disabled"],
			"reason": opt["reason"],
		})
	return result
func _station_option_label(option_id: String, stop: Dictionary, available: bool = true) -> String:
	match option_id:
		StationBubble.CULTIVATE_ID:
			var vein: Dictionary = stop["vein"]
			if vein["growth"] >= Cultivating.ceiling(vein):
				return "Vein at ceiling"
			return UI.format_block_cost_label("Cultivate", 1, available)
		StationBubble.PRUNE_LIGHT_ID:
			return _prune_option_label("Prune (light)", stop["vein"], GameData.VEIN_GROWTH["pruneLightDepth"])
		StationBubble.PRUNE_HARD_ID:
			return _prune_option_label("Prune (hard)", stop["vein"], GameData.VEIN_GROWTH["pruneHardDepth"])
		StationBubble.MANAGE_ID:
			return _manage_option_label(stop)
		_:
			return ""

func _prune_option_label(action_label: String, vein: Dictionary, depth: int) -> String:
	var projected: int = Cultivating.prune_yield(vein, depth)
	return "%s · %d ore" % [UI.format_block_cost_label(action_label, 1, not Cultivating.prune_gate(vein, depth, vein["district"])["disabled"]), projected]
func _manage_option_label(stop: Dictionary) -> String:
	if stop["kind"] != "vein" or stop.get("owner") != "player":
		return "Manage"
	var vein: Dictionary = stop["vein"]
	var band: Dictionary = Cultivating.growth_band(vein)
	if band["id"] == "collapsed":
		return "Manage — %s, may vanish any day" % band["label"]
	return "Manage — %s, %s" % [band["label"], Cultivating.days_to_wall_text(vein)]
func _on_station_bubble_option_selected(option_id: String) -> void:
	var result := StationBubble.apply_option(option_id, _bubble_stop)
	if option_id != StationBubble.MANAGE_ID:
		_map_canvas.play_action_result(_bubble_stop["position"], result["ok"])

func _build_district_panel(district_id: String) -> void:
	var district: Dictionary = GameData.DISTRICTS[district_id]

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MapCardStyle.card_panel(18, 0.12))
	_content.add_child(panel)
	var body := UI.vbox(10)
	panel.add_child(body)

	var back := MapCardStyle.style_button(UI.button("‹ Back to districts", func(): MapNav.back_to_list()))
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	body.add_child(back)
	body.add_child(MapCardStyle.label(district["name"], 20, MapCardStyle.ink()))
	body.add_child(MapCardStyle.label(district["blurb"], 14, MapCardStyle.ink()))

	var indicators := Districts.derived_indicators(district_id)
	if not indicators.is_empty():
		body.add_child(MapCardStyle.label(" · ".join(indicators), 12, MapCardStyle.dim()))

	body.add_child(_build_district_actions(district_id))

	body.add_child(MapCardStyle.label("Sites", 15, MapCardStyle.ink()))
	var sites := Sites.sites_in_district(district_id)
	if sites.is_empty():
		body.add_child(MapCardStyle.label("No sites discovered yet. Prospect to find one.", 12, MapCardStyle.dim()))
	else:
		for site in sites:
			body.add_child(_build_site_row(site))

func _map_card() -> Dictionary:
	var c := UI.card()
	(c["panel"] as PanelContainer).add_theme_stylebox_override("panel", MapCardStyle.inset_panel())
	return c

func _dim_label(text: String) -> Label:
	return MapCardStyle.label(text, 12, MapCardStyle.dim())

func _build_district_actions(district_id: String) -> Control:
	var district: Dictionary = GameData.DISTRICTS[district_id]
	var row := UI.hflow()

	var site_cap: int = district.get("siteCap", 0)
	if site_cap <= 0:
		row.add_child(UI.expand_fill(_dim_label("No prospecting here")))
	elif not GameState.state["flags"]["cultivationTutorialSeen"]:
		row.add_child(UI.expand_fill(_dim_label("Prospecting — see Archie first")))
	else:
		var prospect_button := UI.button(UI.format_block_cost_label("Prospect", 1, Travel.can_afford(district_id, 1)), func(): Sites.prospect(district_id))
		prospect_button.disabled = not Travel.can_afford(district_id, 1)
		row.add_child(MapCardStyle.style_button(prospect_button))

	if GameState.state["world"]["currentDistrict"] == district_id:
		row.add_child(UI.expand_fill(_dim_label("Travel (already here)")))
	else:
		row.add_child(MapCardStyle.style_button(UI.button("Travel", func(): Travel.travel_to(district_id))))
		if Crafting.inventory_qty("wormhole") > 0:
			var wormhole := MapCardStyle.style_button(UI.symbol_button([{ "symbol": GameData.RECIPES["wormhole"]["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " Wormhole"], func(): Travel.travel_via_wormhole(district_id)))
			MapCardStyle.tint_symbols(wormhole, MapCardStyle.action())
			row.add_child(wormhole)

	return row

func _build_site_row(site: Dictionary) -> Control:
	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	var site_id: String = site["id"]

	var c := _map_card()
	c["content"].add_child(MapCardStyle.tint_symbols(UI.symbol_row(["%s — " % String(site["tier"]).capitalize(), { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(site["oreType"]) }, " %s" % ore["name"]], { "heading_size": 14 }), MapCardStyle.ink()))
	c["content"].add_child(_dim_label(_site_claim_state_text(site)))

	var actions := UI.hflow()
	actions.add_child(MapCardStyle.style_button(UI.button("View", func(): MapNav.select_site(site_id))))
	if site["factionVein"] != null and GameState.state["flags"].get("veinSaleUnlocked", false):
		actions.add_child(_build_buy_vein_button(site["factionVein"]))
	c["content"].add_child(actions)
	return c["panel"]
func _build_buy_vein_button(faction_vein: Dictionary) -> Button:
	var price: int = VeinTrade.quote(faction_vein)
	var vein_id: String = faction_vein["id"]
	var faction_id: String = faction_vein["factionId"]
	var button := UI.button("Buy — £%d" % price, func(): VeinTrade.buy_from_faction(vein_id, faction_id))
	button.disabled = GameState.state["player"]["cash"] < price
	return MapCardStyle.style_button(button)

func _site_claim_state_text(site: Dictionary) -> String:
	if site["claimed"]:
		return "Yours"
	if site["factionVein"] != null:
		return "Claimed by %s" % GameData.FACTIONS[site["factionVein"]["factionId"]]["shortName"]
	return "Unclaimed"

func _build_site_sheet(site_id: String) -> void:
	var site = Sites.find_site(site_id)
	if site == null:
		return

	var dim := ColorRect.new()
	dim.color = Color(MapPalette.colour("scrim"), 0.5)
	UI.anchor_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_sheet_dim_gui_input)
	_sheet_layer.add_child(dim)

	var card := PanelContainer.new()
	UI.anchor_bottom_wide(card)
	card.offset_top = -SHEET_HEIGHT
	card.offset_bottom = 0
	var sheet_style := MapCardStyle.card_panel(18, 0.18)
	sheet_style.corner_radius_bottom_left = 0
	sheet_style.corner_radius_bottom_right = 0
	card.add_theme_stylebox_override("panel", sheet_style)
	_sheet_layer.add_child(card)

	var scroll := UI.scroll_container()
	card.add_child(scroll)
	var content := UI.vbox(8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	content.add_child(MapCardStyle.tint_symbols(UI.symbol_row(["%s — " % String(site["tier"]).capitalize(), { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(site["oreType"]) }, " %s" % ore["name"]], { "heading_size": 20 }), MapCardStyle.ink()))
	content.add_child(_dim_label(_site_claim_state_text(site)))

	var bonuses: Array = site["bonuses"]
	if not bonuses.is_empty():
		content.add_child(_dim_label("Bonuses: %s" % ", ".join(bonuses)))
	if site["hasNaturalVein"] and not site["claimed"]:
		content.add_child(_dim_label("A natural vein runs here — claiming grants a free bonus vein."))

	if site["factionVein"] != null:
		_build_faction_vein_content(content, site["factionVein"], site_id)
	elif site["claimed"]:
		_build_claimed_site_content(content, site)
	elif site["tier"] == "barren":
		content.add_child(_dim_label("Barren — nothing to seed here."))
	else:
		content.add_child(_build_seed_row(site))

	content.add_child(MapCardStyle.style_button(UI.button("Close", func(): MapNav.close_site_sheet())))

func _on_sheet_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		MapNav.close_site_sheet()
func _build_faction_vein_content(content: VBoxContainer, vein: Dictionary, site_id: String) -> void:
	var faction: Dictionary = GameData.FACTIONS[vein["factionId"]]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: String = vein["district"]

	if _raid_bring_archie_site_id != site_id:
		_raid_bring_archie_site_id = site_id
		_raid_bring_archie = false

	var band: Dictionary = Cultivating.growth_band(vein)

	var c := _map_card()
	c["content"].add_child(MapCardStyle.label(faction["name"], 14, MapPalette.faction_colour(faction["id"])))
	c["content"].add_child(MapCardStyle.tint_symbols(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s — %s" % [ore["name"], band["label"]]]), MapCardStyle.dim()))
	c["content"].add_child(_security_line(vein, MapCardStyle.dim()))

	if Contacts.can_assist_raid("archie"):
		var archie_toggle := Button.new()
		archie_toggle.clip_text = true
		archie_toggle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		archie_toggle.text = _archie_raid_toggle_label()
		UI.style_action_button(archie_toggle, MapCardStyle.ink())
		archie_toggle.pressed.connect(func():
			_raid_bring_archie = not _raid_bring_archie
			archie_toggle.text = _archie_raid_toggle_label()
		)
		c["content"].add_child(archie_toggle)

	var actions := UI.hflow()

	var raid_button := UI.button(UI.format_block_cost_label("Raid", 1, Travel.can_afford(district, 1)), func():
		Raiding.begin_raid(vein, ["archie"] if _raid_bring_archie else [])
	)
	raid_button.disabled = not Travel.can_afford(district, 1)
	actions.add_child(MapCardStyle.style_button(raid_button))
	if GameState.state["flags"].get("veinSaleUnlocked", false):
		actions.add_child(_build_buy_vein_button(vein))

	c["content"].add_child(actions)

	content.add_child(c["panel"])
func _archie_raid_toggle_label() -> String:
	return "✓ Archie's coming" if _raid_bring_archie else "Bring Archie"

func _build_claimed_site_content(content: VBoxContainer, site: Dictionary) -> void:
	var veins := _veins_for_site(site["id"])
	if veins.is_empty():
		# collective-act2 spec §11.3 item 4: a ruined site says nothing about why.
		content.add_child(_dim_label("Nothing to do here." if site.get("ruinedByFirm", false) else "This site's vein has collapsed. Nothing to do here."))
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
	var label_text := UI.format_block_cost_label(UI.format_cost_label(cost, player["orichalchum"]), 1, player["orichalchum"].get(ore_type, 0) >= GameData.SEED_ORE_COST and Travel.can_afford(district, 1))

	var have: int = player["orichalchum"].get(ore_type, 0)
	var b := UI.button(label_text, func(): Sites.attempt_seed(site_id))
	b.disabled = have < GameData.SEED_ORE_COST or not Travel.can_afford(district, 1)
	return MapCardStyle.style_button(b)

func _build_vein_action_card(vein: Dictionary) -> Control:
	var c := _map_card()
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var band: Dictionary = Cultivating.growth_band(vein)
	var district: String = vein["district"]
	var vein_id: String = vein["id"]
	var vein_ceiling: int = Cultivating.ceiling(vein)
	var at_ceiling: bool = vein["growth"] >= vein_ceiling
	var collapsed: bool = band["id"] == "collapsed"

	c["content"].add_child(MapCardStyle.tint_symbols(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s — %s" % [ore["name"], band["label"]]], { "heading_size": 14 }), MapCardStyle.ink()))
	c["content"].add_child(_dim_label(vein["location"]))
	c["content"].add_child(_security_line(vein, MapCardStyle.ink()))
	if Raiding.has_pending_defend(vein_id):
		c["content"].add_child(MapCardStyle.label("Under raid — defend now or lose it at the next tick.", 12, MapPalette.colour("danger")))
		var defend := UI.button("Defend", func(): Raiding.trigger_defend(vein_id))
		UI.style_action_button(defend, MapPalette.colour("danger"))
		c["content"].add_child(defend)

	c["content"].add_child(_dim_label("Growth: %d/%d" % [vein["growth"], vein_ceiling]))
	c["content"].add_child(MapCardStyle.style_bar(UI.bar(vein["growth"], vein_ceiling)))
	if collapsed:
		c["content"].add_child(MapCardStyle.label(Cultivating.COLLAPSED_VEIN_WARNING, 12, MapPalette.colour("danger")))
	else:
		c["content"].add_child(_dim_label(Cultivating.days_to_wall_text(vein)))
	var actions := UI.hflow()

	var cultivate_label := "Vein at ceiling" if at_ceiling else UI.format_block_cost_label("Cultivate", 1, Travel.can_afford(district, 1))
	var cultivate_button := UI.button(cultivate_label, func(): Cultivating.cultivate(vein_id))
	cultivate_button.disabled = at_ceiling or not Travel.can_afford(district, 1)
	actions.add_child(MapCardStyle.style_button(cultivate_button))

	actions.add_child(_build_prune_button("Prune (light)", vein, GameData.VEIN_GROWTH["pruneLightDepth"], district))
	actions.add_child(_build_prune_button("Prune (hard)", vein, GameData.VEIN_GROWTH["pruneHardDepth"], district))

	c["content"].add_child(actions)
	c["content"].add_child(_build_security_row(vein))
	c["content"].add_child(_build_alarm_row(vein))
	var vein_station_row: Variant = _build_vein_station_row(vein)
	if vein_station_row != null:
		c["content"].add_child(vein_station_row)

	return c["panel"]
func _build_prune_button(action_label: String, vein: Dictionary, depth: int, district: String) -> Control:
	var vein_id: String = vein["id"]
	var label_text := _prune_option_label(action_label, vein, depth)
	var gate: Dictionary = Cultivating.prune_gate(vein, depth, district)
	return MapCardStyle.action_button(label_text, func(): Cultivating.prune(vein_id, depth), gate["disabled"], gate["reason"])
func _security_line(vein: Dictionary, colour: Color) -> Control:
	var row := UI.hbox(5)
	var glyph := UI.icon_glyph_control(Icons.draw_padlock, 0.8, colour)
	glyph.custom_minimum_size = Vector2(18, 18)
	row.add_child(glyph)
	row.add_child(MapCardStyle.label(Cultivating.security_label(vein), 12, colour))
	return row
func _build_vein_station_row(_vein: Dictionary) -> Variant:
	if not GameState.state["home"]["rooms"].has("veinStation"):
		return null
	return _dim_label("Vein Station assignment: see BizBrief → Manage → Procurement.")
func _build_security_row(vein: Dictionary) -> Control:
	var upgrade: Dictionary = Cultivating.next_security_upgrade(vein)
	var player: Dictionary = GameState.state["player"]
	var vein_id: String = vein["id"]

	var label: String = upgrade["label"] if upgrade["tierId"] == null else "Upgrade to %s" % upgrade["label"]
	var cost := { "label": label, "resource": "cash", "amount": upgrade["cost"] }

	var b := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.upgrade_vein_security(vein_id))
	b.disabled = player["cash"] < upgrade["cost"]
	return MapCardStyle.style_button(b)
func _build_alarm_row(vein: Dictionary) -> Control:
	var alarm_data: Dictionary = GameData.VEIN_ALARM[Cultivating.ALARM_UPGRADE_ID]
	if vein["alarmUpgrades"].has(Cultivating.ALARM_UPGRADE_ID):
		return _dim_label("%s: installed" % alarm_data["label"])

	var player: Dictionary = GameState.state["player"]
	var cost := { "label": "Install %s" % alarm_data["label"], "resource": "cash", "amount": alarm_data["cost"] }
	var vein_id: String = vein["id"]

	var b := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.add_alarm(vein_id))
	b.disabled = player["cash"] < alarm_data["cost"]
	return MapCardStyle.style_button(b)
