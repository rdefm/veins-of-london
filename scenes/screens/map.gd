class_name MapScreen
extends Control

const SHEET_HEIGHT := 480.0
const TOP_ROW_MARGIN := 8.0

static func top_row_clearance() -> float:
	return TOP_ROW_MARGIN + UI.ICON_BUTTON_SIZE + UI.safe_area_top_inset()
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

	_diagram_layer.visible = selected_district == null
	_district_scroll.visible = selected_district != null

	if selected_district != null:
		_build_district_panel(selected_district)

	if selected_site_id != null:
		_build_site_sheet(selected_site_id)

func _build_diagram_layer() -> Control:
	var layer := VBoxContainer.new()
	UI.anchor_full_rect(layer)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", int(TOP_ROW_MARGIN) + int(UI.safe_area_top_inset()))
	margin.add_theme_constant_override("margin_bottom", 80)  # room above the nav bar
	layer.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	_map_canvas = MapCanvas.new()
	_map_canvas.district_tapped.connect(_on_district_tapped)
	_map_canvas.station_tapped.connect(_on_station_tapped)

	_map_controls = MapControls.new()
	_map_controls.map_canvas = _map_canvas

	content.add_child(_build_top_bar())
	var diagram_area := Control.new()
	diagram_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(diagram_area)

	var scroll := TouchScrollContainer.new()
	UI.anchor_full_rect(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.add_child(_map_canvas)
	diagram_area.add_child(scroll)

	_map_legend = MapLegend.new()
	diagram_area.add_child(_map_legend)
	_map_zoom_buttons = MapZoomButtons.new()
	_map_zoom_buttons.map_canvas = _map_canvas
	diagram_area.add_child(_map_zoom_buttons)

	return layer
func _build_top_bar() -> Control:
	var row := UI.hbox(8)

	row.add_child(UI.icon_button(Icons.draw_hamburger, func(): _map_controls.toggle()))

	var title := UI.heading("The Network")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(title)

	row.add_child(UI.icon_button(Icons.draw_bag, func(): Bag.open()))

	return row
func _on_district_tapped(district_id: String, canvas_anchor: Vector2) -> void:
	_vein_bubble.close()
	_bubble_mode = BUBBLE_MODE_DISTRICT
	_bubble_district_id = district_id
	var anchor: Vector2 = _map_canvas.global_position + canvas_anchor - _bubble.global_position
	_bubble.open(anchor, _build_district_bubble_options(district_id))
func _build_district_bubble_options(district_id: String) -> Array:
	var result: Array = []
	for opt in DistrictBubble.district_options(district_id):
		result.append({
			"id": opt["id"],
			"label": _district_bubble_option_label(opt["id"], not opt["disabled"]),
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
	_map_canvas.play_action_result(_bubble_stop["position"], result["ok"])
func _on_vein_bubble_info_selected() -> void:
	StationBubble.apply_option(StationBubble.MANAGE_ID, _bubble_stop)
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
	var row := UI.hflow()

	var site_cap: int = district.get("siteCap", 0)
	if site_cap <= 0:
		row.add_child(UI.expand_fill(UI.muted_label("No prospecting here")))
	elif not GameState.state["flags"]["cultivationTutorialSeen"]:
		row.add_child(UI.expand_fill(UI.muted_label("Prospecting — see Archie first")))
	else:
		var prospect_button := UI.button(UI.format_block_cost_label("Prospect", 1, Travel.can_afford(district_id, 1)), func(): Sites.prospect(district_id))
		prospect_button.disabled = not Travel.can_afford(district_id, 1)
		row.add_child(prospect_button)

	if GameState.state["world"]["currentDistrict"] == district_id:
		row.add_child(UI.expand_fill(UI.muted_label("Travel (already here)")))
	else:
		row.add_child(UI.button("Travel", func(): Travel.travel_to(district_id)))
		if Crafting.inventory_qty("wormhole") > 0:
			row.add_child(UI.symbol_button([{ "symbol": GameData.RECIPES["wormhole"]["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " Wormhole"], func(): Travel.travel_via_wormhole(district_id)))

	return row

func _build_site_row(site: Dictionary) -> Control:
	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	var site_id: String = site["id"]

	var c := UI.card()
	c["content"].add_child(UI.symbol_row(["%s — " % String(site["tier"]).capitalize(), { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(site["oreType"]) }, " %s" % ore["name"]], { "heading_size": 14 }))
	c["content"].add_child(UI.muted_label(_site_claim_state_text(site)))

	var actions := UI.hflow()
	actions.add_child(UI.button("View", func(): MapNav.select_site(site_id)))
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
	return button

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
	dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_sheet_dim_gui_input)
	_sheet_layer.add_child(dim)

	var card := PanelContainer.new()
	UI.anchor_bottom_wide(card)
	card.offset_top = -SHEET_HEIGHT
	card.offset_bottom = 0
	_sheet_layer.add_child(card)

	var scroll := UI.scroll_container()
	card.add_child(scroll)
	var content := UI.vbox(8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	content.add_child(UI.symbol_row(["%s — " % String(site["tier"]).capitalize(), { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(site["oreType"]) }, " %s" % ore["name"]], { "heading_size": 20 }))
	content.add_child(UI.muted_label(_site_claim_state_text(site)))

	var bonuses: Array = site["bonuses"]
	if not bonuses.is_empty():
		content.add_child(UI.muted_label("Bonuses: %s" % ", ".join(bonuses)))
	if site["hasNaturalVein"] and not site["claimed"]:
		content.add_child(UI.muted_label("A natural vein runs here — claiming grants a free bonus vein."))

	if site["factionVein"] != null:
		_build_faction_vein_content(content, site["factionVein"], site_id)
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
func _build_faction_vein_content(content: VBoxContainer, vein: Dictionary, site_id: String) -> void:
	var faction: Dictionary = GameData.FACTIONS[vein["factionId"]]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: String = vein["district"]

	if _raid_bring_archie_site_id != site_id:
		_raid_bring_archie_site_id = site_id
		_raid_bring_archie = false

	var band: Dictionary = Cultivating.growth_band(vein)

	var c := UI.card()
	c["content"].add_child(UI.tinted_label(faction["name"], Color(faction["colour"])))
	c["content"].add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s — %s" % [ore["name"], band["label"]]], { "muted": true }))
	c["content"].add_child(UI.muted_label("🔒 %s" % Cultivating.security_label(vein)))

	if Contacts.can_assist_raid("archie"):
		var archie_toggle := Button.new()
		archie_toggle.clip_text = true
		archie_toggle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		archie_toggle.text = _archie_raid_toggle_label()
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
	actions.add_child(raid_button)
	if GameState.state["flags"].get("veinSaleUnlocked", false):
		actions.add_child(_build_buy_vein_button(vein))

	c["content"].add_child(actions)

	content.add_child(c["panel"])
func _archie_raid_toggle_label() -> String:
	return "✓ Archie's coming" if _raid_bring_archie else "Bring Archie"

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
	var label_text := UI.format_block_cost_label(UI.format_cost_label(cost, player["orichalchum"]), 1, player["orichalchum"].get(ore_type, 0) >= GameData.SEED_ORE_COST and Travel.can_afford(district, 1))

	var have: int = player["orichalchum"].get(ore_type, 0)
	var b := UI.button(label_text, func(): Sites.attempt_seed(site_id))
	b.disabled = have < GameData.SEED_ORE_COST or not Travel.can_afford(district, 1)
	return b

func _build_vein_action_card(vein: Dictionary) -> Control:
	var c := UI.card()
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var band: Dictionary = Cultivating.growth_band(vein)
	var district: String = vein["district"]
	var vein_id: String = vein["id"]
	var vein_ceiling: int = Cultivating.ceiling(vein)
	var at_ceiling: bool = vein["growth"] >= vein_ceiling
	var collapsed: bool = band["id"] == "collapsed"

	c["content"].add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s — %s" % [ore["name"], band["label"]]], { "heading_size": 14 }))
	c["content"].add_child(UI.muted_label(vein["location"]))
	c["content"].add_child(UI.label("🔒 %s" % Cultivating.security_label(vein)))
	if Raiding.has_pending_defend(vein_id):
		c["content"].add_child(UI.tinted_label("Under raid — defend now or lose it at the next tick.", MapStyle.DANGER_COLOUR))
		c["content"].add_child(UI.button("Defend", func(): Raiding.trigger_defend(vein_id)))

	c["content"].add_child(UI.muted_label("Growth: %d/%d" % [vein["growth"], vein_ceiling]))
	c["content"].add_child(UI.bar(vein["growth"], vein_ceiling))
	if collapsed:
		c["content"].add_child(UI.tinted_label(Cultivating.COLLAPSED_VEIN_WARNING, MapStyle.DANGER_COLOUR))
	else:
		c["content"].add_child(UI.muted_label(Cultivating.days_to_wall_text(vein)))
	var actions := UI.hflow()

	var cultivate_label := "Vein at ceiling" if at_ceiling else UI.format_block_cost_label("Cultivate", 1, Travel.can_afford(district, 1))
	var cultivate_button := UI.button(cultivate_label, func(): Cultivating.cultivate(vein_id))
	cultivate_button.disabled = at_ceiling or not Travel.can_afford(district, 1)
	actions.add_child(cultivate_button)

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
	return UI.action_button(label_text, func(): Cultivating.prune(vein_id, depth), gate["disabled"], gate["reason"])
func _build_vein_station_row(_vein: Dictionary) -> Variant:
	if not GameState.state["home"]["rooms"].has("veinStation"):
		return null
	return UI.muted_label("Vein Station assignment: see BizBrief → Manage → Procurement.")
func _build_security_row(vein: Dictionary) -> Control:
	var upgrade: Dictionary = Cultivating.next_security_upgrade(vein)
	var player: Dictionary = GameState.state["player"]
	var vein_id: String = vein["id"]

	var label: String = upgrade["label"] if upgrade["tierId"] == null else "Upgrade to %s" % upgrade["label"]
	var cost := { "label": label, "resource": "cash", "amount": upgrade["cost"] }

	var b := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.upgrade_vein_security(vein_id))
	b.disabled = player["cash"] < upgrade["cost"]
	return b
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
