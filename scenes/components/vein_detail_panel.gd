class_name VeinDetailPanel
extends RefCounted

# Floating player-vein card. Presentation stays local; actions still dispatch
# through the same StationBubble/Cultivating/Raiding seams as other surfaces.

const CARD_WIDTH := 354.0
const CARD_HEIGHT := 596.0


static func build(vein: Dictionary) -> Control:
	var root := Control.new()
	UI.anchor_full_rect(root)
	var dim := ColorRect.new()
	dim.color = Color(MapPalette.colour("scrim"), 0.42)
	UI.anchor_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
			MapNav.close_vein_detail()
	)
	root.add_child(dim)

	var card := PanelContainer.new()
	card.name = "VeinDetailCard"
	card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-CARD_WIDTH / 2.0, -CARD_HEIGHT / 2.0)
	card.add_theme_stylebox_override("panel", MapCardStyle.card_panel(18, 0.18))
	root.add_child(card)
	var content := UI.vbox(9)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(content)
	content.add_child(_build_header(vein))
	content.add_child(_build_level_and_location(vein))
	content.add_child(VeinBubble.build_condition_column(vein, true))
	content.add_child(_build_status_row(vein))
	content.add_child(_divider())
	content.add_child(_build_detail_note(vein))
	var collapse_row: Variant = _build_collapse_warning(vein)
	if collapse_row != null:
		content.add_child(collapse_row)
	var defend_row: Variant = _build_defend_row(vein)
	if defend_row != null:
		content.add_child(defend_row)
	content.add_child(_divider())
	content.add_child(_build_actions_section(vein))
	content.add_child(_build_security_button(vein))
	content.add_child(_divider())
	content.add_child(_build_alarm_button(vein))
	return root


static func _build_header(vein: Dictionary) -> Control:
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: Dictionary = GameData.DISTRICTS[vein["district"]]
	var row := UI.hbox(6)
	row.name = "Header"
	var glyph := SymbolGlyph.new()
	glyph.symbol = ore["symbol"]
	glyph.draw_fallback = SymbolGlyph.ore_fallback(vein["oreType"])
	glyph.custom_minimum_size = Vector2(22, 22)
	glyph.glyph_radius = 7.5
	glyph.color = MapCardStyle.ink()
	row.add_child(glyph)
	var heading := _label("%s · %s" % [district["name"], ore["name"]], 16, MapCardStyle.ink())
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(heading)
	var close := Button.new()
	close.name = "CloseButton"
	close.text = "Close"
	close.tooltip_text = "Close"
	close.custom_minimum_size = Vector2(32, 32)
	close.pressed.connect(func(): MapNav.close_vein_detail())
	UI.style_action_button(close, MapCardStyle.ink())
	_make_text_invisible(close)
	var chevron := _label("›", 22, MapCardStyle.ink())
	chevron.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(chevron)
	close.add_child(chevron)
	row.add_child(close)
	return row


static func _build_level_and_location(vein: Dictionary) -> Control:
	var col := UI.vbox(3)
	col.add_child(VeinBubble.build_level_row(vein, true))
	col.add_child(_label(vein["location"], 12, MapCardStyle.dim()))
	var ceiling: int = Cultivating.ceiling(vein)
	if ceiling > GameData.VEIN_GROWTH["ceiling"]:
		col.add_child(_label("Wild-ceiling · %d maximum condition" % ceiling, 11, MapCardStyle.dim()))
	return col


static func _build_status_row(vein: Dictionary) -> Control:
	var row := UI.hbox(8)
	row.name = "StatusRow"
	row.add_child(_status_item(SymbolGlyph.ore_fallback("time"), Cultivating.days_to_wall_text(vein)))
	row.add_child(_status_item(Icons.draw_padlock, _raid_status_text(vein)))
	return row


static func _status_item(draw_icon: Callable, text: String) -> Control:
	var row := UI.hbox(5)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var glyph := UI.icon_glyph_control(draw_icon, 0.9, MapCardStyle.gold())
	glyph.custom_minimum_size = Vector2(19, 19)
	row.add_child(glyph)
	var status := _label(text, 11, MapCardStyle.gold())
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status)
	return row


static func _raid_status_text(vein: Dictionary) -> String:
	return "Raised raid risk" if vein["growth"] >= GameData.VEIN_GROWTH["developmentThreshold"] else "Standard raid risk"


static func _build_detail_note(vein: Dictionary) -> Control:
	var col := UI.vbox(2)
	var level: int = vein.get("level", 1)
	var cap: int = Cultivating.level_cap(vein)
	var threshold: int = GameData.VEIN_GROWTH["developmentThreshold"]
	if level >= cap:
		col.add_child(_label("Max level (%d/%d) · Harvestable · Raid exposure applies" % [level, cap], 11, MapCardStyle.dim()))
	elif vein["growth"] < threshold:
		col.add_child(_label("Not developing · Needs condition %d+" % threshold, 11, MapCardStyle.dim()))
	else:
		var streak: int = vein.get("developmentStreak", 0)
		var chance: float = minf(1.0, GameData.VEIN_GROWTH["levelUpChancePerDay"] * streak)
		col.add_child(_label("Developing · Day %d · About %d%% tonight" % [streak + 1, roundi(chance * 100)], 11, MapCardStyle.dim()))
	col.add_child(_label("Cultivating skill: %d" % GameState.state["player"]["cultivatingSkill"], 10, MapCardStyle.dim()))
	col.add_child(_label("%s · resist %d" % [Cultivating.security_label(vein), Cultivating.vein_raid_resist(vein)], 10, MapCardStyle.dim()))
	return col


static func _build_defend_row(vein: Dictionary) -> Variant:
	var vein_id: String = vein["id"]
	if not Raiding.has_pending_defend(vein_id):
		return null
	var row := UI.hbox(6)
	var warning := _label("Under raid — defend before next tick.", 11, MapPalette.colour("danger"))
	warning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(warning)
	var defend := UI.button("Defend", func(): Raiding.trigger_defend(vein_id))
	UI.style_action_button(defend, MapPalette.colour("danger"))
	row.add_child(defend)
	return row


static func _build_collapse_warning(vein: Dictionary) -> Variant:
	if vein["growth"] > 0:
		return null
	var level: int = vein.get("level", 1)
	if level <= 1:
		var pct: int = roundi(GameData.VEIN_GROWTH["collapseChancePerDay"] * 100)
		return _label("Empty · about %d%% chance to collapse and vanish tonight" % pct, 10, MapPalette.colour("danger"))
	return _label("Empty · will deplete to level %d tonight" % (level - 1), 10, MapPalette.colour("danger"))


static func _build_actions_section(vein: Dictionary) -> Control:
	var stop: Dictionary = { "kind": "vein", "vein": vein, "owner": "player", "site": { "id": vein.get("siteId") } }
	var options: Array = StationBubble.station_options(stop)
	var row := UI.hbox(5)
	row.name = "ActionTiles"
	var cultivate_opt: Dictionary = _find_option(options, StationBubble.CULTIVATE_ID)
	var skill: int = GameState.state["player"]["cultivatingSkill"]
	var cultivate_caption := "+%d–%d condition" % [Cultivating.cultivate_min_gain(skill), Cultivating.cultivate_max_gain(skill)]
	if vein["growth"] >= Cultivating.ceiling(vein):
		cultivate_caption = "At ceiling"
	row.add_child(_action_tile(_cultivate_label(vein, cultivate_opt["disabled"]), "Cultivate", cultivate_caption, Icons.draw_cultivate, func(): StationBubble.apply_option(StationBubble.CULTIVATE_ID, stop), cultivate_opt))
	var light_opt: Dictionary = _find_option(options, StationBubble.PRUNE_LIGHT_ID)
	row.add_child(_action_tile(_harvest_label("Harvest (light)", vein, GameData.VEIN_GROWTH["pruneLightDepth"], not light_opt["disabled"]), "Light harvest", _harvest_caption(vein, GameData.VEIN_GROWTH["pruneLightDepth"]), Icons.draw_harvest, func(): StationBubble.apply_option(StationBubble.PRUNE_LIGHT_ID, stop), light_opt))
	var hard_opt: Dictionary = _find_option(options, StationBubble.PRUNE_HARD_ID)
	row.add_child(_action_tile(_harvest_label("Harvest (hard)", vein, GameData.VEIN_GROWTH["pruneHardDepth"], not hard_opt["disabled"]), "Hard harvest", _harvest_caption(vein, GameData.VEIN_GROWTH["pruneHardDepth"]), Icons.draw_harvest, func(): StationBubble.apply_option(StationBubble.PRUNE_HARD_ID, stop), hard_opt, 1.25))
	return row


static func _action_tile(hidden_text: String, title: String, caption: String, draw_icon: Callable, callback: Callable, gate: Dictionary, icon_scale: float = 1.0) -> Control:
	var button := Button.new()
	button.name = title.replace(" ", "") + "Button"
	button.text = hidden_text
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text = gate["reason"] if gate["disabled"] and gate["reason"] != "" else title
	button.disabled = gate["disabled"]
	button.custom_minimum_size = Vector2(102, 112)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	_make_text_invisible(button)
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_stylebox_override("hover", _tile_hover_style())
	button.add_theme_stylebox_override("pressed", _tile_hover_style())
	var col := UI.vbox(3)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(col)
	var circle := PanelContainer.new()
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.custom_minimum_size = Vector2(58, 58)
	circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	circle.add_theme_stylebox_override("panel", _circle_style(button.disabled))
	var glyph_colour: Color = MapCardStyle.dim() if button.disabled else MapCardStyle.ink()
	var glyph := UI.icon_glyph_control(draw_icon, icon_scale, glyph_colour)
	glyph.custom_minimum_size = Vector2(58, 58)
	circle.add_child(glyph)
	col.add_child(circle)
	var title_label := _label(title, 11, glyph_colour)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title_label)
	var caption_label := _label(caption, 9, MapCardStyle.dim())
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(caption_label)
	button.add_child(col)
	return button


static func _circle_style(disabled: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MapCardStyle.sage(), 0.38 if disabled else 0.7)
	style.border_color = Color(MapCardStyle.line(), 0.55 if disabled else 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(29)
	return style


static func _tile_hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MapCardStyle.gold(), 0.08)
	style.set_corner_radius_all(10)
	return style


static func _harvest_caption(vein: Dictionary, depth: int) -> String:
	return "%d ore · %d→%d" % [Cultivating.prune_yield(vein, depth), vein["growth"], Cultivating.prune_resulting_growth(vein, depth)]


static func _find_option(options: Array, id: String) -> Dictionary:
	for opt in options:
		if opt["id"] == id:
			return opt
	return { "disabled": true, "reason": "" }


static func _cultivate_label(vein: Dictionary, disabled: bool) -> String:
	if vein["growth"] >= Cultivating.ceiling(vein):
		return "Cultivate -- vein at ceiling"
	var skill: int = GameState.state["player"]["cultivatingSkill"]
	var base: String = "Cultivate -- roughly +%d to +%d condition (skill %d)" % [Cultivating.cultivate_min_gain(skill), Cultivating.cultivate_max_gain(skill), skill]
	return UI.format_block_cost_label(base, 1, not disabled)


static func _harvest_label(label_text: String, vein: Dictionary, depth: int, available: bool) -> String:
	var projected_yield: int = Cultivating.prune_yield(vein, depth)
	var resulting: int = Cultivating.prune_resulting_growth(vein, depth)
	var base: String = "%s -- %d ore, %d→%d" % [label_text, projected_yield, vein["growth"], resulting]
	return UI.format_block_cost_label(base, 1, available)


static func _build_security_button(vein: Dictionary) -> Control:
	var upgrade: Dictionary = Cultivating.next_security_upgrade(vein)
	var player: Dictionary = GameState.state["player"]
	var vein_id: String = vein["id"]
	var label_text: String = upgrade["label"] if upgrade["tierId"] == null else "Upgrade to %s" % upgrade["label"]
	var cost := { "label": label_text, "resource": "cash", "amount": upgrade["cost"] }
	var button := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.upgrade_vein_security(vein_id))
	button.name = "SecurityButton"
	button.disabled = player["cash"] < upgrade["cost"]
	button.custom_minimum_size.y = 40
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.style_action_button(button, MapCardStyle.dim() if button.disabled else MapCardStyle.action())
	return button


static func _build_alarm_button(vein: Dictionary) -> Control:
	var alarm_data: Dictionary = GameData.VEIN_ALARM[Cultivating.ALARM_UPGRADE_ID]
	var row := UI.hbox(8)
	var glyph := UI.icon_glyph_control(Icons.draw_news, 0.8, MapCardStyle.ink())
	glyph.custom_minimum_size = Vector2(24, 24)
	row.add_child(glyph)
	if vein["alarmUpgrades"].has(Cultivating.ALARM_UPGRADE_ID):
		row.add_child(_label("%s: installed" % alarm_data["label"], 11, MapCardStyle.ink()))
		return row
	var player: Dictionary = GameState.state["player"]
	var cost := { "label": "Install %s" % alarm_data["label"], "resource": "cash", "amount": alarm_data["cost"] }
	var vein_id: String = vein["id"]
	var button := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.add_alarm(vein_id))
	button.disabled = player["cash"] < alarm_data["cost"]
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.style_action_button(button, MapCardStyle.dim() if button.disabled else MapCardStyle.action())
	row.add_child(button)
	return row


static func _divider() -> HSeparator:
	var line := HSeparator.new()
	line.modulate = Color(MapCardStyle.line(), 0.7)
	return line


static func _label(text: String, size: int, colour: Color) -> Label:
	var label := UI.label(text)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label


static func _make_text_invisible(button: Button) -> void:
	var clear := Color.TRANSPARENT
	button.add_theme_color_override("font_color", clear)
	button.add_theme_color_override("font_hover_color", clear)
	button.add_theme_color_override("font_pressed_color", clear)
	button.add_theme_color_override("font_disabled_color", clear)
