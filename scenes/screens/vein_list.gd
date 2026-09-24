class_name VeinListScreen
extends Control

var _content: VBoxContainer

func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	var nav: Dictionary = GameState.state["veinListNav"]
	var district_id: Variant = nav.get("districtId")
	var band_filter: Variant = nav.get("bandFilter")

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MapCardStyle.card_panel(18, 0.12))
	_content.add_child(panel)
	var body := UI.vbox(10)
	panel.add_child(body)

	var back := MapCardStyle.style_button(UI.back_button(nav.get("originScreen", "map")))
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	body.add_child(back)
	body.add_child(MapCardStyle.label(_title(district_id), 20, MapCardStyle.ink()))
	body.add_child(_build_band_filter_row(band_filter))

	var veins := VeinList.veins(district_id, band_filter)
	if veins.is_empty():
		body.add_child(_dim_label("No veins match this filter." if band_filter != null else "No veins here yet."))
		return

	for vein in veins:
		body.add_child(_build_vein_row(vein))

func _dim_label(text: String) -> Label:
	return MapCardStyle.label(text, 12, MapCardStyle.dim())

func _title(district_id: Variant) -> String:
	if district_id == null:
		return "All veins"
	return GameData.DISTRICTS[district_id]["name"]
func _build_band_filter_row(active_band: Variant) -> Control:
	var row := UI.hflow()

	var all_button := UI.button("All", func(): VeinListNav.set_band_filter(null))
	all_button.disabled = active_band == null
	row.add_child(_style_filter_button(all_button))

	for band in GameData.VEIN_GROWTH["bands"]:
		var band_id: String = band["id"]
		var b := UI.button(band["label"], func(): VeinListNav.set_band_filter(band_id))
		b.disabled = active_band == band_id
		row.add_child(_style_filter_button(b))

	return row

# The active filter is the disabled one; it reads as selected (ink on sage),
# not as unavailable.
func _style_filter_button(b: Button) -> Button:
	if not b.disabled:
		return MapCardStyle.style_button(b)
	UI.style_action_button(b, MapCardStyle.ink())
	b.add_theme_stylebox_override("disabled", UI.action_button_style(MapCardStyle.ink(), 0.12, 0.5))
	return b

func _build_vein_row(vein: Dictionary) -> Control:
	var c := UI.card()
	(c["panel"] as PanelContainer).add_theme_stylebox_override("panel", MapCardStyle.inset_panel())
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: Dictionary = GameData.DISTRICTS[vein["district"]]
	var tier: String = vein.get("hospitability", {}).get("tier", "fair")
	var band: Dictionary = Cultivating.growth_band(vein)
	var vein_ceiling: int = Cultivating.ceiling(vein)
	var collapsed: bool = band["id"] == "collapsed"

	c["content"].add_child(MapCardStyle.tint_symbols(UI.symbol_row(["%s — " % district["name"], { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s" % ore["name"]], { "heading_size": 14 }), MapCardStyle.ink()))
	var terroir_row := UI.hbox(5)
	terroir_row.add_child(_dim_label("%s terroir ·" % String(tier).capitalize()))
	var padlock := UI.icon_glyph_control(Icons.draw_padlock, 0.8, MapCardStyle.dim())
	padlock.custom_minimum_size = Vector2(18, 18)
	terroir_row.add_child(padlock)
	terroir_row.add_child(_dim_label(Cultivating.security_label(vein)))
	c["content"].add_child(terroir_row)

	c["content"].add_child(_dim_label("Growth: %d/%d — %s" % [vein["growth"], vein_ceiling, band["label"]]))
	c["content"].add_child(MapCardStyle.style_bar(UI.bar(vein["growth"], vein_ceiling)))
	if collapsed:
		c["content"].add_child(MapCardStyle.label(Cultivating.COLLAPSED_VEIN_WARNING, 12, MapPalette.colour("danger")))
	else:
		c["content"].add_child(_dim_label(Cultivating.days_to_wall_text(vein)))
	var station_text: Variant = Rooms.vein_station_target_text(vein["id"])
	if station_text != null:
		c["content"].add_child(_dim_label(String(station_text)))

	c["content"].add_child(_build_actions_row(vein))

	return c["panel"]
func _build_actions_row(vein: Dictionary) -> Control:
	var actions := UI.hflow()
	for gate in VeinList.actions_for(vein):
		actions.add_child(_build_action_button(vein, gate))
	return actions

func _build_action_button(vein: Dictionary, gate: Dictionary) -> Control:
	var vein_id: String = vein["id"]
	var option_id: String = gate["id"]

	match option_id:
		VeinList.CULTIVATE_ID:
			var at_ceiling: bool = vein["growth"] >= Cultivating.ceiling(vein)
			var label := "Vein at ceiling" if at_ceiling else UI.format_block_cost_label("Cultivate", 1, not gate["disabled"])
			return MapCardStyle.action_button(label, func(): VeinList.apply_option(option_id, vein_id), gate["disabled"], gate["reason"])
		VeinList.PRUNE_LIGHT_ID:
			return _build_prune_button("Prune (light)", vein, GameData.VEIN_GROWTH["pruneLightDepth"], gate)
		VeinList.PRUNE_HARD_ID:
			return _build_prune_button("Prune (hard)", vein, GameData.VEIN_GROWTH["pruneHardDepth"], gate)
		VeinList.SELL_ID:
			var price: int = VeinTrade.quote(vein)
			return MapCardStyle.style_button(UI.button("Sell — £%d" % price, func(): VeinList.apply_option(option_id, vein_id)))
		_:  # MANAGE_ID
			return MapCardStyle.style_button(UI.button("Manage", func(): VeinList.apply_option(option_id, vein_id)))
func _build_prune_button(action_label: String, vein: Dictionary, depth: int, gate: Dictionary) -> Control:
	var vein_id: String = vein["id"]
	var option_id: String = gate["id"]
	var projected: int = Cultivating.prune_yield(vein, depth)
	var label_text := "%s · %d ore" % [UI.format_block_cost_label(action_label, 1, not gate["disabled"]), projected]
	return MapCardStyle.action_button(label_text, func(): VeinList.apply_option(option_id, vein_id), gate["disabled"], gate["reason"])
