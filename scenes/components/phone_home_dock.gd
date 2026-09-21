class_name PhoneHomeDock
extends PanelContainer

const DESTINATIONS: Array[Dictionary] = [
	{ "id": "dialer", "label": "Phone" },
	{ "id": "messages", "label": "Messages" },
	{ "id": "settings", "label": "Settings" },
]
const DOCK_HEIGHT := 116.0
const SIDE_MARGIN := 18.0
const BOTTOM_MARGIN := 14.0

var tiles: Array[AppTile] = []
var _built := false


func _ready() -> void:
	ensure_built()


func ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = SIDE_MARGIN
	offset_right = -SIDE_MARGIN
	offset_top = -DOCK_HEIGHT - BOTTOM_MARGIN
	offset_bottom = -BOTTOM_MARGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.063, 0.075, 0.88)
	style.set_corner_radius_all(24)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	for destination in DESTINATIONS:
		var tile := AppTile.new(true)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.configure({
			"id": destination["id"],
			"label": destination["label"],
			"locked": false,
			"badge": Messages.total_unread_count() if destination["id"] == "messages" else 0,
		})
		tile.tile_pressed.connect(PhoneNav.open_app)
		tiles.append(tile)
		row.add_child(tile)


func refresh_badges() -> void:
	ensure_built()
	for tile in tiles:
		if tile._app_id == "messages":
			tile.configure({ "id": "messages", "label": "Messages", "locked": false, "badge": Messages.total_unread_count() })
