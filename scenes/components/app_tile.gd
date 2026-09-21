class_name AppTile
extends Control


const ICON_DIR := "res://assets/icons/apps/"
const TILE_SIZE := Vector2(76, 92)
const FRAME_SIZE := 56.0
const BADGE_HEIGHT := 18.0
const BADGE_MIN_WIDTH := 18.0
const NAME_FONT_SIZE := 12
const FALLBACK_FONT_SIZE := 10

const FRAME_CORNER_RADIUS := 16
const LARGE_FRAME_CORNER_RADIUS := 22

const LARGE_TILE_SIZE := Vector2(78, 96)
const LARGE_FRAME_SIZE := 64.0
const LARGE_BADGE_HEIGHT := 20.0
const LARGE_BADGE_MIN_WIDTH := 20.0
const LARGE_NAME_FONT_SIZE := 12
const LARGE_FALLBACK_FONT_SIZE := 13

const BADGE_OVERFLOW_THRESHOLD := 99

const LOCKED_TINT := Color(0.541176, 0.541176, 0.541176, 1)
const NORMAL_TINT := Color(1, 1, 1, 1)

const BADGE_COLOUR := Color("#c8102e")

const FRAME_BG_COLOUR := Color("#1b1b1d")
const FRAME_BORDER_COLOUR := Color("#1b1b1d")

const ACTIVE_BG_COLOUR := Color(0.870588, 0.717647, 0.535294, 1)
const ACTIVE_BORDER_COLOUR := Color(0.784314, 0.529412, 0.227451, 1)
const ACTIVE_BORDER_WIDTH := 2

const _PHONE_BG_HOME := "phone_bg_home"
const _PHONE_TEXT_PRIMARY := "phone_text_primary"
const _FALLBACK_TEXT_PRIMARY := Color("#ededee")

static func _palette(id: String, fallback: Color) -> Color:
	return GameData.PALETTE.get(id, fallback)


static var _icon_mask_shader: Shader


signal tile_pressed(app_id: String)

var _app_id: String = ""
var _frame: Control
var _background: Panel
var _frame_style: StyleBoxFlat
var _icon_rect: TextureRect
var _icon_mask_material: ShaderMaterial
var _fallback_label: Label
var _lock_overlay: _LockOverlay
var _badge: _CountBadge
var _name_label: Label
var _built := false
var _large: bool = false


func _init(large: bool = false) -> void:
	_large = large


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var frame_size := LARGE_FRAME_SIZE if _large else FRAME_SIZE
	var badge_height := LARGE_BADGE_HEIGHT if _large else BADGE_HEIGHT
	var badge_min_width := LARGE_BADGE_MIN_WIDTH if _large else BADGE_MIN_WIDTH
	var name_font_size := LARGE_NAME_FONT_SIZE if _large else NAME_FONT_SIZE
	var fallback_font_size := LARGE_FALLBACK_FONT_SIZE if _large else FALLBACK_FONT_SIZE
	var frame_corner_radius := LARGE_FRAME_CORNER_RADIUS if _large else FRAME_CORNER_RADIUS

	custom_minimum_size = LARGE_TILE_SIZE if _large else TILE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

	var column := UI.vbox(4)
	UI.anchor_full_rect(column)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	_frame = Control.new()
	_frame.custom_minimum_size = Vector2(frame_size, frame_size)
	_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_frame)

	_background = Panel.new()
	UI.anchor_full_rect(_background)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_style = StyleBoxFlat.new()
	_frame_style.bg_color = FRAME_BG_COLOUR
	_frame_style.border_width_left = 1
	_frame_style.border_width_top = 1
	_frame_style.border_width_right = 1
	_frame_style.border_width_bottom = 1
	_frame_style.border_color = FRAME_BORDER_COLOUR
	_frame_style.corner_radius_top_left = frame_corner_radius
	_frame_style.corner_radius_top_right = frame_corner_radius
	_frame_style.corner_radius_bottom_right = frame_corner_radius
	_frame_style.corner_radius_bottom_left = frame_corner_radius
	_background.add_theme_stylebox_override("panel", _frame_style)
	_frame.add_child(_background)

	_icon_rect = TextureRect.new()
	UI.anchor_full_rect(_icon_rect)
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.visible = false
	_frame.add_child(_icon_rect)

	if _icon_mask_shader == null:
		_icon_mask_shader = Shader.new()
		_icon_mask_shader.code = "shader_type canvas_item;\nuniform vec2 mask_size = vec2(1.0, 1.0);\nuniform float corner_radius = 0.0;\nvarying vec2 local_pos;\nvoid vertex() {\n\tlocal_pos = VERTEX;\n}\nfloat rounded_rect_sdf(vec2 p, vec2 size, float radius) {\n\tvec2 q = abs(p - size * 0.5) - (size * 0.5 - vec2(radius));\n\treturn length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;\n}\nvoid fragment() {\n\tfloat d = rounded_rect_sdf(local_pos, mask_size, corner_radius);\n\tCOLOR = texture(TEXTURE, UV);\n\tCOLOR.a *= 1.0 - smoothstep(-1.0, 1.0, d);\n}"
	_icon_mask_material = ShaderMaterial.new()
	_icon_mask_material.shader = _icon_mask_shader
	_icon_mask_material.set_shader_parameter("mask_size", Vector2(frame_size, frame_size))
	_icon_mask_material.set_shader_parameter("corner_radius", float(frame_corner_radius))
	_icon_rect.material = _icon_mask_material

	var text_colour := _palette(_PHONE_TEXT_PRIMARY, _FALLBACK_TEXT_PRIMARY)

	_fallback_label = Label.new()
	UI.anchor_full_rect(_fallback_label)
	_fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fallback_label.add_theme_font_size_override("font_size", fallback_font_size)
	_fallback_label.add_theme_color_override("font_color", text_colour)
	_fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback_label.visible = false
	_frame.add_child(_fallback_label)

	_lock_overlay = _LockOverlay.new()
	UI.anchor_full_rect(_lock_overlay)
	_lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.visible = false
	_frame.add_child(_lock_overlay)

	_badge = _CountBadge.new()
	_badge.custom_minimum_size = Vector2(badge_min_width, badge_height)
	_badge.size = Vector2(badge_min_width, badge_height)
	_badge.position = Vector2(frame_size - badge_min_width * 0.72, -badge_height * 0.28)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.visible = false
	_frame.add_child(_badge)

	_name_label = UI.label("")
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", name_font_size)
	_name_label.add_theme_color_override("font_color", text_colour)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_name_label)


func configure(data: Dictionary) -> void:
	_ensure_built()
	_app_id = data.get("id", "")
	var label_text: String = data.get("label", _app_id)
	var locked: bool = data.get("locked", false)
	var badge_count := maxi(int(data.get("badge", 0)), 0)
	var active: bool = data.get("active", false)
	var icon_override: Texture2D = data.get("icon")

	_name_label.text = label_text

	var texture: Texture2D = icon_override if icon_override != null else load_icon(_app_id)
	var has_real_art := texture != null
	if has_real_art:
		_icon_rect.texture = texture
		_icon_rect.visible = true
		_fallback_label.visible = false
	else:
		_icon_rect.visible = false
		_fallback_label.text = label_text
		_fallback_label.visible = true

	_lock_overlay.visible = locked
	_badge.set_count(badge_count)

	_background.visible = active or not has_real_art

	if not has_real_art or active:
		_frame_style.bg_color = ACTIVE_BG_COLOUR if active else _palette(_PHONE_BG_HOME, FRAME_BG_COLOUR)
		_frame_style.border_color = ACTIVE_BORDER_COLOUR if active else FRAME_BORDER_COLOUR
		var border_width := ACTIVE_BORDER_WIDTH if active else 0
		_frame_style.border_width_left = border_width
		_frame_style.border_width_top = border_width
		_frame_style.border_width_right = border_width
		_frame_style.border_width_bottom = border_width

	var tint := LOCKED_TINT if locked else NORMAL_TINT
	_background.modulate = tint
	_icon_rect.modulate = tint
	_fallback_label.modulate = tint
	_name_label.modulate = tint


static func icon_path(app_id: String) -> String:
	return ICON_DIR + app_id + ".png"


static func load_icon(app_id: String) -> Texture2D:
	var path := icon_path(app_id)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		tile_pressed.emit(_app_id)


class _LockOverlay extends Control:
	func _draw() -> void:
		Icons.draw_padlock(self, size / 2.0, LOCKED_TINT, 2.0)


class _CountBadge extends Control:
	var count := 0
	var display_text := ""
	var _label: Label

	func _ready() -> void:
		_ensure_label()

	func set_count(value: int) -> void:
		count = maxi(value, 0)
		display_text = "%d+" % BADGE_OVERFLOW_THRESHOLD if count > BADGE_OVERFLOW_THRESHOLD else str(count)
		visible = count > 0
		_ensure_label()
		_label.text = display_text
		var required_width := maxf(custom_minimum_size.x, 10.0 + display_text.length() * 7.0)
		size.x = required_width
		queue_redraw()

	func _ensure_label() -> void:
		if _label != null:
			return
		_label = Label.new()
		UI.anchor_full_rect(_label)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 11)
		_label.add_theme_color_override("font_color", Color.WHITE)
		_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		_label.add_theme_constant_override("shadow_offset_y", 1)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)

	func _draw() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = BADGE_COLOUR
		style.set_corner_radius_all(int(size.y / 2.0))
		draw_style_box(style, Rect2(Vector2.ZERO, size))
