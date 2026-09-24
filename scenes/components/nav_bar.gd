class_name NavBar
extends Control


const BAR_HEIGHT := 64.0

const TABS := [
	{ "screen": "phone", "label": "Phone", "icon": "phone" },
	{ "screen": "map", "label": "Map", "icon": "map" },
	{ "screen": "hq", "label": "HQ", "icon": "hq" },
]

const LOCKED_MAP_LABEL := "Stick close for now — Archie"

const _BG_COLOR := Color(0.976471, 0.976471, 0.972549, 1)
const _DIVIDER_COLOR := Color(0.831373, 0.811765, 0.768627, 1)

const _LOCKED_COLOR := UI.ACTION_DISABLED_COLOUR

var _tiles: Dictionary = {}
var _bg_style: StyleBoxFlat
var _dividers: Array[ColorRect] = []


func _ready() -> void:
	UI.anchor_bottom_wide(self)
	offset_top = -BAR_HEIGHT
	offset_bottom = 0.0

	var bg := Panel.new()
	UI.anchor_full_rect(bg)
	_bg_style = StyleBoxFlat.new()
	_bg_style.border_width_top = 1
	bg.add_theme_stylebox_override("panel", _bg_style)
	add_child(bg)

	var row := HBoxContainer.new()
	UI.anchor_full_rect(row)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	add_child(row)

	for i in TABS.size():
		var tab: Dictionary = TABS[i]
		if i > 0:
			row.add_child(_make_divider())
		var tile := _DockTile.new(tab["screen"], tab["icon"])
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.tile_pressed.connect(_on_tile_pressed)
		row.add_child(tile)
		_tiles[tab["screen"]] = tile

	EventBus.state_changed.connect(_refresh)
	EventBus.alarm_arrived.connect(_pulse_phone_tab)
	_refresh()


func _make_divider() -> ColorRect:
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(1, BAR_HEIGHT * 0.5)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dividers.append(line)
	return line


func _refresh() -> void:
	var current_screen: String = GameState.state["currentScreen"]
	var phone_home: bool = GameState.state["phoneNav"]["app"] == "home"
	# The dock follows the Map palette's dark chrome only while the Map tab
	# shows (map-dark-mode spec, decision 6); everywhere else it keeps its
	# ui-vision.md §5 light look.
	var dark := current_screen == "map" and MapPalette.is_dark()
	var action_color := MapPalette.colour_in("cardAction", true) if dark else UI.action_colour()
	var locked_color := MapPalette.colour_in("muted", true) if dark else _LOCKED_COLOR
	var divider_color := MapPalette.colour_in("chromeBorder", true) if dark else _DIVIDER_COLOR
	_bg_style.bg_color = MapPalette.colour_in("chromePaper", true) if dark else _BG_COLOR
	_bg_style.border_color = divider_color
	for line in _dividers:
		line.color = divider_color

	for tab in TABS:
		var tile: _DockTile = _tiles[tab["screen"]]
		var locked: bool = tab["screen"] == "map" and _map_locked()
		var active: bool
		if tab["screen"] == "phone":
			active = current_screen == "phone" and phone_home
		else:
			active = current_screen == tab["screen"]
		tile.configure(tab["label"], locked, active, action_color, locked_color)
		tile.tooltip_text = LOCKED_MAP_LABEL if locked else ""


func _pulse_phone_tab() -> void:
	var tile: _DockTile = _tiles.get("phone")
	if tile == null or not tile.is_inside_tree():
		return
	var base_x := tile.position.x
	var tween := tile.create_tween()
	tween.tween_property(tile, "position:x", base_x - 4, 0.05)
	tween.tween_property(tile, "position:x", base_x + 4, 0.05)
	tween.tween_property(tile, "position:x", base_x, 0.05)


func _on_tile_pressed(screen_id: String) -> void:
	if screen_id == "map" and _map_locked():
		Notify.push(LOCKED_MAP_LABEL)
		return
	if screen_id == "phone":
		_go_phone_home()
		return
	Nav.go_to(screen_id)


func _map_locked() -> bool:
	return not GameState.state["flags"]["archiePartnerSeen"]


func _go_phone_home() -> void:
	var nav: Dictionary = GameState.state["phoneNav"]
	var already_home: bool = GameState.state["currentScreen"] == "phone" and nav["app"] == "home"
	if already_home:
		return
	if GameState.state["currentScreen"] != "phone":
		Nav.go_to("phone")
	PhoneNav.go_home()


class _DockTile extends Control:
	signal tile_pressed(screen_id: String)

	const ICON_BOX := 26.0
	const ACTIVE_BAR_HEIGHT := 3.0

	var screen_id: String
	var locked: bool = false
	var active: bool = false
	var _icon_kind: String
	var _icon: _TileIcon
	var _label: Label
	var _active_bar: ColorRect
	var _lock_badge: _LockBadge
	var _built := false


	func _init(id: String, icon_kind: String) -> void:
		screen_id = id
		_icon_kind = icon_kind


	func _ready() -> void:
		_ensure_built()


	func _ensure_built() -> void:
		if _built:
			return
		_built = true

		custom_minimum_size = Vector2(0, NavBar.BAR_HEIGHT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		gui_input.connect(_on_gui_input)

		var column := UI.vbox(2)
		UI.anchor_center(column)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(column)

		_icon = _TileIcon.new(_icon_kind)
		_icon.custom_minimum_size = Vector2(ICON_BOX, ICON_BOX)
		_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_icon)

		_lock_badge = _LockBadge.new()
		_lock_badge.custom_minimum_size = Vector2(ICON_BOX, ICON_BOX)
		_lock_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lock_badge.visible = false
		_icon.add_child(_lock_badge)

		_label = UI.label("")
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_label.add_theme_font_size_override("font_size", 11)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_label)

		_active_bar = ColorRect.new()
		_active_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_active_bar.visible = false
		UI.anchor_bottom_wide(_active_bar)
		_active_bar.offset_top = -ACTIVE_BAR_HEIGHT
		_active_bar.offset_bottom = 0.0
		add_child(_active_bar)


	func configure(label_text: String, is_locked: bool, is_active: bool, action_color: Color, locked_color: Color) -> void:
		_ensure_built()
		locked = is_locked
		active = is_active
		_label.text = label_text

		var tint := locked_color if locked else action_color
		_icon.set_colour(tint)
		_label.add_theme_color_override("font_color", tint)
		_active_bar.color = action_color
		_lock_badge.visible = locked
		_lock_badge.set_colour(locked_color)
		_active_bar.visible = active and not locked


	func _on_gui_input(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
			tile_pressed.emit(screen_id)


class _TileIcon extends Control:
	var kind: String
	var colour: Color = Color.BLACK

	func _init(icon_kind: String) -> void:
		kind = icon_kind


	func set_colour(c: Color) -> void:
		colour = c
		queue_redraw()


	func _draw() -> void:
		var center := size / 2.0
		match kind:
			"phone":
				_draw_phone(center)
			"map":
				_draw_map(center)
			"hq":
				_draw_hq(center)


	func _draw_phone(center: Vector2) -> void:
		var s := 7.0
		draw_rect(Rect2(center + Vector2(-s * 0.55, -s), Vector2(s * 1.1, s * 2.0)), colour, false, 1.6)
		draw_line(center + Vector2(-s * 0.25, s * 0.72), center + Vector2(s * 0.25, s * 0.72), colour, 1.6)


	func _draw_map(center: Vector2) -> void:
		var r := 5.5
		var head := center + Vector2(0, -r * 0.9)
		draw_arc(head, r, 0, TAU, 24, colour, 1.6, true)
		var tip := center + Vector2(0, r * 1.3)
		draw_line(head + Vector2(-r * 0.62, r * 0.62), tip, colour, 1.6)
		draw_line(head + Vector2(r * 0.62, r * 0.62), tip, colour, 1.6)
		draw_circle(head, r * 0.32, colour)


	func _draw_hq(center: Vector2) -> void:
		var s := 7.0
		draw_line(center + Vector2(-s, -s * 0.15), center + Vector2(0, -s * 1.15), colour, 1.6)
		draw_line(center + Vector2(0, -s * 1.15), center + Vector2(s, -s * 0.15), colour, 1.6)
		draw_rect(Rect2(center + Vector2(-s * 0.75, -s * 0.15), Vector2(s * 1.5, s * 1.3)), colour, false, 1.6)
		draw_rect(Rect2(center + Vector2(-s * 0.2, s * 0.25), Vector2(s * 0.4, s * 0.9)), colour, false, 1.3)


class _LockBadge extends Control:
	var colour: Color = NavBar._LOCKED_COLOR

	func set_colour(c: Color) -> void:
		colour = c
		queue_redraw()


	func _draw() -> void:
		Icons.draw_padlock(self, size / 2.0, colour, 1.6)
