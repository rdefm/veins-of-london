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

var _dim: ColorRect
var _panel: PanelContainer
var _content: VBoxContainer

var _anchor: Vector2 = Vector2.ZERO
var _bounds_size: Vector2 = Vector2.ZERO
var _stop: Dictionary = {}
var _chooser_open: bool = false


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

	_content = UI.vbox(6)
	_panel.add_child(_content)


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

	var inner := UI.vbox(4)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: Dictionary = GameData.DISTRICTS[vein["district"]]
	var heading_row := UI.hbox(4)
	heading_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading_label := UI.label("%s · %s" % [district["name"], ore["name"]])
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading_label)
	heading_row.add_child(UI.muted_label("›"))
	inner.add_child(heading_row)

	inner.add_child(build_level_row(vein))
	inner.add_child(build_condition_column(vein))

	var cues: Variant = build_cue_row(vein)
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
static func build_level_row(vein: Dictionary) -> Control:
	var row := UI.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var level: int = vein.get("level", 1)
	var cap: int = Cultivating.level_cap(vein)
	row.add_child(UI.muted_label("Lv %d/%d" % [level, cap]))

	var pips := UI.hbox(3)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in cap:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 5)
		pip.color = MapCanvas.PLAYER_COLOUR if i < level else MapStyle.MUTED_COLOUR
		pips.add_child(pip)
	row.add_child(pips)

	return row


# Public + static: shared with vein_detail_panel.gd's condition section.
static func build_condition_column(vein: Dictionary) -> Control:
	var col := UI.vbox(2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vein_ceiling: int = Cultivating.ceiling(vein)
	var threshold: int = GameData.VEIN_GROWTH["developmentThreshold"]

	var header := UI.hbox(4)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UI.muted_label("Condition")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	header.add_child(UI.muted_label("%d/%d" % [vein["growth"], vein_ceiling]))
	col.add_child(header)

	var bar := ConditionBar.new()
	bar.set_data(vein["growth"], vein_ceiling, threshold, GameData.VEIN_GROWTH["neutral"])
	col.add_child(bar)

	return col


# Non-colour cues (icon glyph substitute is a plain emoji + word, matching
# the "🔒"/"🌱" text-glyph convention map.gd/cultivate_result_modal.gd both
# use) so eligibility and raid exposure never rely on colour alone. Raised
# raid exposure tracks condition alone (a maxed-level vein can still sit at
# 90+ and draw raids), while development eligibility additionally requires
# headroom under the level cap -- the two can and do diverge. Public +
# static: shared with vein_detail_panel.gd's identity section.
static func build_cue_row(vein: Dictionary) -> Variant:
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

	var row := UI.hbox(28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	row.add_child(_build_action_column(_action_caption("Harvest", not harvest_disabled), Icons.draw_harvest, harvest_disabled, _open_chooser))
	row.add_child(_build_action_column(_action_caption("Cultivate", not cultivate_opt["disabled"]), Icons.draw_cultivate, cultivate_opt["disabled"], func(): _select_action(StationBubble.CULTIVATE_ID)))

	return row


# Routine block-cost labels are display-only and drop out once the
# cultivation tutorial has run, on both actions.
func _action_caption(label_text: String, available: bool) -> String:
	if GameState.state["flags"].get("cultivationTutorialSeen", false):
		return label_text
	return UI.format_block_cost_label(label_text, 1, available)


func _build_action_column(caption: String, draw_icon: Callable, disabled: bool, callback: Callable) -> Control:
	var col := UI.vbox(2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	var btn := UI.icon_button(draw_icon, callback)
	btn.disabled = disabled
	col.add_child(btn)

	var cap := UI.muted_label(caption)
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
	col.add_child(UI.muted_label("Harvest depth"))
	col.add_child(_build_chooser_row("Light", vein, GameData.VEIN_GROWTH["pruneLightDepth"], StationBubble.PRUNE_LIGHT_ID))
	col.add_child(_build_chooser_row("Hard", vein, GameData.VEIN_GROWTH["pruneHardDepth"], StationBubble.PRUNE_HARD_ID))
	col.add_child(UI.button("‹ Back", _close_chooser))
	return col


func _build_chooser_row(label_text: String, vein: Dictionary, depth: int, option_id: String) -> Control:
	var opt := _find_option(StationBubble.station_options(_stop), option_id)
	var projected_yield: int = Cultivating.prune_yield(vein, depth)
	var resulting: int = Cultivating.prune_resulting_growth(vein, depth)
	var text := "%s · %d ore · %d→%d" % [label_text, projected_yield, vein["growth"], resulting]
	return UI.action_button(text, func(): _select_action(option_id), opt["disabled"], opt["reason"])


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
	_panel.position = BubbleLayout.popup_position(_anchor, _panel.size, _bounds_size)


# Draws the slim condition bar: a filled track to `growth`, a hairline tick
# at `neutral` (50, the sole stable point a vein's condition never drifts
# past on its own), and a tinted zone from `threshold` (90) to
# `vein_ceiling` -- the latter computed as a fraction of the vein's *actual*
# ceiling so a wildCeiling (120) vein's zone still starts at condition 90,
# not at 90% of the bar. The zone's boundary is also a drawn line, not
# colour alone.
class ConditionBar extends Control:
	var growth: int = 0
	var vein_ceiling: int = 100
	var threshold: int = 90
	var neutral: int = 50

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 10)
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

		draw_rect(Rect2(0, 0, w, h), MapStyle.MUTED_COLOUR.lerp(Color.WHITE, 0.5))

		var fill_w: float = w * clampf(float(growth) / float(vein_ceiling), 0.0, 1.0)
		draw_rect(Rect2(0, 0, fill_w, h), MapCanvas.PLAYER_COLOUR)

		var zone_x: float = w * clampf(float(threshold) / float(vein_ceiling), 0.0, 1.0)
		draw_rect(Rect2(zone_x, 0, w - zone_x, h), Color(MapStyle.DANGER_COLOUR, 0.25))
		draw_line(Vector2(zone_x, 0), Vector2(zone_x, h), MapStyle.INK_COLOUR, 1.0)

		var neutral_x: float = w * clampf(float(neutral) / float(vein_ceiling), 0.0, 1.0)
		draw_line(Vector2(neutral_x, 0), Vector2(neutral_x, h), MapStyle.INK_COLOUR, 2.0)
