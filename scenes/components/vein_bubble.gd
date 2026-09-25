class_name VeinBubble
extends Control

# Compact vein-tap bubble: identity, Lv segments, a slim condition bar with
# a 50 marker and a marked 90+ development zone, compact development-
# eligibility/raised-raid-exposure cues, and two round Harvest/Cultivate
# actions kept separate from the info area. Player-owned vein stops only --
# a faction vein or an unclaimed site has neither action and keeps the
# plain MapBubble list (see map.gd's station-tap branch). Tapping the info
# area emits info_selected(), which map.gd routes into VeinDetailPanel
# instead of the site sheet's Manage view.


signal action_selected(option_id: String)
signal info_selected()
signal closed()

# Wide enough for "Cultivate" on one line; a longer pre-tutorial caption
# ("Cultivate — 1 block") wraps at the word break, not mid-word.
const CAPTION_WIDTH := 88.0

var _pointer: Control
var _dim: ColorRect
var _panel: PanelContainer
var _content: VBoxContainer

var _anchor: Vector2 = Vector2.ZERO
var _bounds_size: Vector2 = Vector2.ZERO
var _stop: Dictionary = {}
var _chooser_open: bool = false
var _dark: bool = false


func _ready() -> void:
	UI.anchor_full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0)
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	_panel.custom_minimum_size.x = 268
	_pointer = Control.new()
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.draw.connect(_draw_pointer)
	add_child(_pointer)
	_content = UI.vbox(12)
	_panel.add_child(_content)
	_dark = MapPalette.is_dark()
	_apply_panel_style()
	EventBus.state_changed.connect(_on_state_changed)


func open(anchor: Vector2, stop: Dictionary, bounds_size: Vector2 = Vector2.ZERO) -> void:
	_anchor = anchor
	_bounds_size = bounds_size if bounds_size != Vector2.ZERO else size
	_stop = stop
	_chooser_open = false
	_rebuild()
	visible = true
	_dim.visible = true
	_panel.visible = true
	_reposition()


func close() -> void:
	if not visible:
		return
	visible = false
	_dim.visible = false
	_panel.visible = false
	closed.emit()


# A Map dark-mode toggle restyles the card and rebuilds an open bubble in
# place, keeping it open (and the Harvest chooser, if showing).
func _on_state_changed() -> void:
	if MapPalette.is_dark() == _dark:
		return
	_dark = MapPalette.is_dark()
	_apply_panel_style()
	_pointer.queue_redraw()
	if visible:
		_rebuild()
		_reposition()


func _apply_panel_style() -> void:
	_panel.add_theme_stylebox_override("panel", MapCardStyle.card_panel(18, 0.13))


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		close()


func _rebuild() -> void:
	# queue_free(), not free(): the Harvest/Back buttons call this from
	# inside their own `pressed` handler (_open_chooser/_close_chooser), so
	# an immediate free() here would free a node while its own signal is
	# still being emitted further up the call stack.
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	var vein: Dictionary = _stop["vein"]
	_content.add_child(_build_info_button(vein))
	if _chooser_open:
		_content.add_child(_build_chooser(vein))
	else:
		_content.add_child(_build_actions_row(vein))


# A Button isn't a Container -- it never reports a child Control's minimum
# size as its own, so wrapping this multi-row content directly in a Button
# starved it to the button's own near-zero minimum height, spilling the
# unclipped content into the actions row below. A PanelContainer IS a
# Container (its minimum size is the max over its children's), so it sizes
# correctly to `inner` while a full-rect transparent Button stacked on top
# catches the tap.
func _build_info_button(vein: Dictionary) -> Control:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var inner := UI.vbox(10)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: Dictionary = GameData.DISTRICTS[vein["district"]]
	var heading_row := UI.hbox(4)
	heading_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading_label := _label("%s · %s" % [district["name"], ore["name"]])
	heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading_label)
	heading_row.add_child(_label("›", 18))
	inner.add_child(heading_row)

	inner.add_child(build_level_row(vein, true))
	inner.add_child(build_condition_column(vein, true))

	var cues: Variant = build_cue_row(vein, true)
	if cues != null:
		inner.add_child(cues)

	wrap.add_child(inner)

	var tap := Button.new()
	tap.flat = true
	tap.pressed.connect(_select_info)
	wrap.add_child(tap)

	return wrap


# Public + static: also reused by vein_detail_panel.gd's identity section
# so the earned-level segments read identically in both places.
static func build_level_row(vein: Dictionary, compact: bool = false) -> Control:
	var row := UI.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var level: int = vein.get("level", 1)
	var cap: int = Cultivating.level_cap(vein)
	row.add_child(_label("Lv %d/%d" % [level, cap], 12) if compact else UI.muted_label("Lv %d/%d" % [level, cap]))

	var pips := UI.hbox(4 if compact else 3)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in cap:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(23, 6) if compact else Vector2(14, 5)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.add_theme_stylebox_override("panel", MapCardStyle.skin((MapCardStyle.ink() if i < level else MapCardStyle.line()) if compact else (MapPalette.colour("player") if i < level else MapPalette.colour("muted")), 2, false))
		pips.add_child(pip)
	row.add_child(pips)

	return row


# Public + static: shared with vein_detail_panel.gd's condition section.
static func build_condition_column(vein: Dictionary, compact: bool = false) -> Control:
	var col := UI.vbox(2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vein_ceiling: int = Cultivating.ceiling(vein)
	var threshold: int = GameData.VEIN_GROWTH["developmentThreshold"]

	var header := UI.hbox(4)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := _label("Condition", 11, MapCardStyle.dim()) if compact else UI.muted_label("Condition")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	header.add_child(_label(str(vein["growth"]), 14) if compact else UI.muted_label("%d/%d" % [vein["growth"], vein_ceiling]))
	col.add_child(header)

	var bar := ConditionBar.new()
	bar.compact = compact
	bar.custom_minimum_size.y = 38 if compact else 10
	bar.set_data(vein["growth"], vein_ceiling, threshold, GameData.VEIN_GROWTH["neutral"])
	col.add_child(bar)

	return col


# Non-colour cues (icon glyph substitute is a plain emoji + word, matching
# the "🔒"/"🌱" text-glyph convention map.gd
# uses) so eligibility and raid exposure never rely on colour alone. Raised
# raid exposure tracks condition alone (a maxed-level vein can still sit at
# 90+ and draw raids), while development eligibility additionally requires
# headroom under the level cap -- the two can and do diverge. Public +
# static: shared with vein_detail_panel.gd's identity section.
static func build_cue_row(vein: Dictionary, compact: bool = false) -> Variant:
	if compact:
		return _compact_cues(vein)
	var threshold: int = GameData.VEIN_GROWTH["developmentThreshold"]
	var parts: Array = []
	if Cultivating.is_development_eligible(vein):
		parts.append("🌱 Developing")
	if vein["growth"] >= threshold:
		parts.append("⚠ Raid risk ↑")
	if parts.is_empty():
		return null

	var row := UI.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UI.muted_label(" · ".join(parts)))
	return row


func _build_actions_row(vein: Dictionary) -> Control:
	var options := StationBubble.station_options(_stop)
	var light_opt := _find_option(options, StationBubble.PRUNE_LIGHT_ID)
	var hard_opt := _find_option(options, StationBubble.PRUNE_HARD_ID)
	var cultivate_opt := _find_option(options, StationBubble.CULTIVATE_ID)
	var harvest_disabled: bool = light_opt["disabled"] and hard_opt["disabled"]

	var row := UI.hbox(40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	row.add_child(_build_action_column(_action_caption("Harvest", not harvest_disabled), Icons.draw_harvest, harvest_disabled, _open_chooser))
	row.add_child(_build_action_column(_action_caption("Cultivate", not cultivate_opt["disabled"]), _draw_sprout, cultivate_opt["disabled"], func(): _select_action(StationBubble.CULTIVATE_ID)))

	return row


# Routine block-cost labels are display-only and drop out once the
# cultivation tutorial has run, on both actions.
func _action_caption(label_text: String, available: bool) -> String:
	if GameState.state["flags"].get("cultivationTutorialSeen", false):
		return label_text
	return UI.format_block_cost_label(label_text, 1, available)


func _build_action_column(caption: String, draw_icon: Callable, disabled: bool, callback: Callable) -> Control:
	var col := UI.vbox(4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	var btn := UI.icon_button(draw_icon, callback, MapCardStyle.dim() if disabled else MapCardStyle.ink())
	btn.custom_minimum_size = Vector2(44, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		if state == "focus":
			var focus_style := MapCardStyle.skin(Color.TRANSPARENT, 22)
			focus_style.border_color = MapCardStyle.gold()
			btn.add_theme_stylebox_override(state, focus_style)
		else:
			btn.add_theme_stylebox_override(state, MapCardStyle.action_circle_style(state))
	btn.disabled = disabled
	col.add_child(btn)

	var cap := _label(caption, 11, MapCardStyle.dim() if disabled else MapCardStyle.ink())
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.custom_minimum_size.x = CAPTION_WIDTH
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cap)

	return col


func _open_chooser() -> void:
	_chooser_open = true
	_rebuild()
	_reposition()


# The chooser previews both depths' actual ore yield and resulting
# condition via the same prune_yield()/prune_resulting_growth() math the
# real action uses -- never a placeholder, and never assuming a harvest
# always exits the development zone.
func _build_chooser(vein: Dictionary) -> Control:
	var col := UI.vbox(4)
	col.add_child(_label("Harvest depth", 12, MapCardStyle.dim()))
	col.add_child(_build_chooser_row("Light", vein, GameData.VEIN_GROWTH["pruneLightDepth"], StationBubble.PRUNE_LIGHT_ID))
	col.add_child(_build_chooser_row("Hard", vein, GameData.VEIN_GROWTH["pruneHardDepth"], StationBubble.PRUNE_HARD_ID))
	col.add_child(MapCardStyle.style_button(UI.button("‹ Back", _close_chooser)))
	return col


func _build_chooser_row(label_text: String, vein: Dictionary, depth: int, option_id: String) -> Control:
	var opt := _find_option(StationBubble.station_options(_stop), option_id)
	var projected_yield: int = Cultivating.prune_yield(vein, depth)
	var resulting: int = Cultivating.prune_resulting_growth(vein, depth)
	var text := "%s · %d ore · %d→%d" % [label_text, projected_yield, vein["growth"], resulting]
	return MapCardStyle.action_button(text, func(): _select_action(option_id), opt["disabled"], opt["reason"])


func _close_chooser() -> void:
	_chooser_open = false
	_rebuild()
	_reposition()


static func _find_option(options: Array, id: String) -> Dictionary:
	for opt in options:
		if opt["id"] == id:
			return opt
	return { "disabled": true, "reason": "" }


func _select_action(option_id: String) -> void:
	close()
	action_selected.emit(option_id)


func _select_info() -> void:
	close()
	info_selected.emit()


func _reposition() -> void:
	_apply_position()
	_apply_position.call_deferred()


func _apply_position() -> void:
	_panel.size = _panel.get_combined_minimum_size()
	var offset := Vector2(-_panel.size.x / 2.0, -_panel.size.y - 12)
	if _anchor.y + offset.y < BubbleLayout.EDGE_MARGIN:
		offset.y = 12
	_panel.position = BubbleLayout.popup_position(_anchor, _panel.size, _bounds_size, offset)
	_pointer.queue_redraw()


# Draws the slim condition bar: a filled track to `growth`, a hairline tick
# at `neutral` (50, the sole stable point a vein's condition never drifts
# past on its own), and a tinted zone from `threshold` (90) to
# `vein_ceiling` -- the latter computed as a fraction of the vein's *actual*
# ceiling so a wildCeiling (120) vein's zone still starts at condition 90,
# not at 90% of the bar. The zone's boundary is also a drawn line, not
# colour alone.
class ConditionBar extends Control:
	var compact: bool = false
	var growth: int = 0
	var vein_ceiling: int = 100
	var threshold: int = 90
	var neutral: int = 50

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 38 if compact else 10)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_data(growth_: int, ceiling_: int, threshold_: int, neutral_: int) -> void:
		growth = growth_
		vein_ceiling = maxi(ceiling_, 1)
		threshold = threshold_
		neutral = neutral_
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 0 or h <= 0:
			return

		if compact:
			var track := Rect2(4, 8, w - 8, 8)
			draw_style_box(MapCardStyle.skin(MapCardStyle.line(), 4, false), track)
			var zone_x := track.position.x + track.size.x * float(threshold) / vein_ceiling
			draw_style_box(MapCardStyle.skin(MapCardStyle.gold(), 3, false), Rect2(zone_x, 8, track.end.x - zone_x, 8))
			var neutral_x := track.position.x + track.size.x * float(neutral) / vein_ceiling
			var needle_x := track.position.x + track.size.x * clampf(float(growth) / vein_ceiling, 0, 1)
			draw_line(Vector2(neutral_x, 5), Vector2(neutral_x, 19), MapCardStyle.dim(), 1, true)
			draw_line(Vector2(needle_x, 4), Vector2(needle_x, 20), MapCardStyle.ink(), 3, true)
			var font := get_theme_default_font()
			for mark in [["0", track.position.x], [str(neutral), neutral_x - font.get_string_size(str(neutral), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x / 2], ["%d+" % threshold, track.end.x - font.get_string_size("%d+" % threshold, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x]]:
				draw_string(font, Vector2(mark[1], 34), mark[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MapCardStyle.dim())
			return

		draw_rect(Rect2(0, 0, w, h), MapPalette.colour("muted").lerp(MapPalette.colour("paper"), 0.5))

		var fill_w: float = w * clampf(float(growth) / float(vein_ceiling), 0.0, 1.0)
		draw_rect(Rect2(0, 0, fill_w, h), MapPalette.colour("player"))

		var zone_x: float = w * clampf(float(threshold) / float(vein_ceiling), 0.0, 1.0)
		draw_rect(Rect2(zone_x, 0, w - zone_x, h), Color(MapPalette.colour("danger"), 0.25))
		draw_line(Vector2(zone_x, 0), Vector2(zone_x, h), MapPalette.colour("ink"), 1.0)

		var neutral_x: float = w * clampf(float(neutral) / float(vein_ceiling), 0.0, 1.0)
		draw_line(Vector2(neutral_x, 0), Vector2(neutral_x, h), MapPalette.colour("ink"), 2.0)


func _draw_pointer() -> void:
	var below := _panel.position.y > _anchor.y
	var x := clampf(_anchor.x, _panel.position.x + 24, _panel.position.x + _panel.size.x - 24)
	var y := _panel.position.y if below else _panel.position.y + _panel.size.y
	var a := Vector2(x - 9, y)
	var b := Vector2(x, y + (-11 if below else 11))
	var c := Vector2(x + 9, y)
	_pointer.draw_colored_polygon(PackedVector2Array([a, b, c]), MapCardStyle.paper())
	_pointer.draw_polyline(PackedVector2Array([a, b, c]), MapCardStyle.line(), 1, true)


static func _label(value: String, font_size: int = 14, colour: Color = MapCardStyle.ink()) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	return label


static func _compact_cues(vein: Dictionary) -> Variant:
	var developing := Cultivating.is_development_eligible(vein)
	var risk: bool = vein["growth"] >= GameData.VEIN_GROWTH["developmentThreshold"]
	if not developing and not risk:
		return null
	var row := UI.hbox(7)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for cue in (["Developing", "Raid risk ↑"] if developing and risk else (["Developing"] if developing else ["Raid risk ↑"])):
		if row.get_child_count() > 0:
			row.add_child(_label("·", 11, MapCardStyle.gold()))
		var glyph := UI.icon_glyph_control(_draw_sprout if cue == "Developing" else _draw_shield, 0.8, MapCardStyle.gold())
		glyph.custom_minimum_size = Vector2(13, 18)
		row.add_child(glyph)
		row.add_child(_label(cue, 11, MapCardStyle.gold()))
	return row


static func _draw_sprout(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var stem := PackedVector2Array([Vector2(-4, 6), Vector2(4, 6), Vector2(0, 6), Vector2(0, -2)])
	for i in range(stem.size()):
		stem[i] = center + stem[i] * scale
	target.draw_polyline(stem, colour, scale, true)
	for side in [-1, 1]:
		var leaf := PackedVector2Array([Vector2(0, 0), Vector2(side * 5, -1), Vector2(side * 6, -5), Vector2(side * 2, -5), Vector2(0, 0)])
		for i in range(leaf.size()):
			leaf[i] = center + leaf[i] * scale
		target.draw_polyline(leaf, colour, scale, true)


static func _draw_shield(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var points := PackedVector2Array([Vector2(0, -7), Vector2(6, -4), Vector2(5, 3), Vector2(0, 7), Vector2(-5, 3), Vector2(-6, -4), Vector2(0, -7)])
	for i in range(points.size()):
		points[i] = center + points[i] * scale
	target.draw_polyline(points, colour, scale, true)
	target.draw_line(center + Vector2(0, -3) * scale, center, colour, scale, true)
	target.draw_circle(center + Vector2(0, 3) * scale, scale * 0.65, colour)
