# Persistent simulated-device frame for the Phone tab. Owns the clipped
# display, decorative status chrome, home wallpaper/widget, and the dark
# opened-app surface. External TopBar/NavBar remain Main-scene siblings.
class_name PhoneDeviceShell
extends Control

const FRAME_MARGIN := 6.0
const BEZEL_WIDTH := 6.0
const FRAME_RADIUS := 30.0
const DISPLAY_RADIUS := 24.0
const STATUS_HEIGHT := 38.0
const HOME_DOCK_CLEARANCE := 136.0

var display: Control
var wallpaper: TextureRect
var wallpaper_path: String
var app_surface: ColorRect
var content_scroll: ScrollContainer
var content: VBoxContainer
var custom_mount: Control

var _built := false


func _ready() -> void:
	ensure_built()


func ensure_built() -> void:
	if _built:
		return
	_built = true

	UI.anchor_below_bars(self)
	offset_left = FRAME_MARGIN
	offset_right = -FRAME_MARGIN
	offset_top += 4.0
	offset_bottom -= FRAME_MARGIN

	var frame := Panel.new()
	frame.name = "DeviceFrame"
	UI.anchor_full_rect(frame)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = _palette("phone_frame")
	frame_style.border_color = _palette("phone_frame_border")
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(int(FRAME_RADIUS))
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)

	display = _RoundedClipDisplay.new(DISPLAY_RADIUS, _palette("phone_bg_home"))
	display.name = "ClippedDisplay"
	UI.anchor_full_rect(display)
	display.offset_left = BEZEL_WIDTH
	display.offset_top = BEZEL_WIDTH
	display.offset_right = -BEZEL_WIDTH
	display.offset_bottom = -BEZEL_WIDTH
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)

	wallpaper = TextureRect.new()
	wallpaper.name = "HomeWallpaper"
	UI.anchor_full_rect(wallpaper)
	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallpaper_path = GameData.PHONE_HOME.get("wallpaper", "")
	wallpaper.texture = load(wallpaper_path) as Texture2D
	# The script runner skips the editor's import scan on a fresh checkout;
	# runtime/export builds use ResourceLoader above, while this source-file
	# fallback keeps headless checks independent of generated .godot imports.
	if wallpaper.texture == null:
		var wallpaper_image := Image.load_from_file(ProjectSettings.globalize_path(wallpaper_path))
		if not wallpaper_image.is_empty():
			wallpaper.texture = ImageTexture.create_from_image(wallpaper_image)
	display.add_child(wallpaper)

	app_surface = ColorRect.new()
	app_surface.name = "AppSurface"
	UI.anchor_full_rect(app_surface)
	app_surface.color = _palette("phone_bg_content")
	app_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.add_child(app_surface)

	custom_mount = Control.new()
	custom_mount.name = "DeviceContentMount"
	UI.anchor_full_rect(custom_mount)
	custom_mount.offset_top = STATUS_HEIGHT
	display.add_child(custom_mount)

	content_scroll = UI.scroll_container()
	content_scroll.name = "SharedContentScroll"
	UI.anchor_full_rect(content_scroll)
	custom_mount.add_child(content_scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	content_scroll.add_child(margin)

	content = UI.vbox(12)
	margin.add_child(content)
	display.add_child(_build_status_bar())
	set_home_mode(true)


func set_home_mode(is_home: bool) -> void:
	ensure_built()
	wallpaper.visible = is_home
	app_surface.visible = not is_home
	content_scroll.offset_bottom = -HOME_DOCK_CLEARANCE if is_home else 0.0


func add_home_widget() -> void:
	content.add_child(_build_home_widget())


func mount_custom_root(root: Control) -> void:
	content_scroll.visible = false
	UI.anchor_full_rect(root)
	custom_mount.add_child(root)


func show_shared_content() -> void:
	content_scroll.visible = true


func _build_status_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.name = "DeviceStatusBar"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 14
	bar.offset_top = 5
	bar.offset_right = -14
	bar.offset_bottom = STATUS_HEIGHT
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 8)

	var status: Dictionary = GameData.PHONE_HOME.get("status", {})
	var time_label := _status_label(status.get("time", ""), 16)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(time_label)
	bar.add_child(_status_label(status.get("cellular", ""), 12))
	bar.add_child(_status_label(status.get("wifi", ""), 20))
	bar.add_child(_status_label(status.get("batteryGlyph", ""), 15))
	bar.add_child(_status_label(status.get("batteryPercent", ""), 16))
	return bar


func _build_home_widget() -> Control:
	var widget := VBoxContainer.new()
	widget.name = "HomeWidget"
	widget.add_theme_constant_override("separation", 3)
	var config: Dictionary = GameData.PHONE_HOME.get("widget", {})

	var date := _widget_label(config.get("date", ""), 28, _palette("phone_text_primary"))
	widget.add_child(date)
	var weather_line := "%s  %s  ·  %s" % [config.get("weather", ""), config.get("temperature", ""), config.get("location", "")]
	widget.add_child(_widget_label(weather_line, 18, _palette("phone_text_primary")))
	widget.add_child(_widget_label(config.get("flavour", ""), 14, _palette("phone_text_muted")))
	return widget


func _status_label(text: String, font_size: int) -> Label:
	var label := _widget_label(text, font_size, _palette("phone_text_primary"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _widget_label(text: String, font_size: int, colour: Color) -> Label:
	var label := UI.label(text)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _palette(id: String) -> Color:
	return GameData.PALETTE[id]


# clip_children uses this item's alpha draw as its mask. Drawing the rounded
# rect explicitly makes the cut-out corners part of the clip, not merely a
# rectangular Control boundary.
class _RoundedClipDisplay extends Control:
	var _style := StyleBoxFlat.new()

	func _init(radius: float, colour: Color) -> void:
		clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		_style.bg_color = colour
		_style.set_corner_radius_all(int(radius))
		resized.connect(queue_redraw)

	func _draw() -> void:
		draw_style_box(_style, Rect2(Vector2.ZERO, size))
