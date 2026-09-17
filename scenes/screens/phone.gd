# Phone tab shell: paints the OS background, owns the home app grid and
# tile routing, and dispatches any open app (state.phoneNav.app) to its
# PhoneApp from scenes/phone_apps/phone_app_registry.gd. Each app's view
# lives in its own script under scenes/phone_apps/.
class_name PhoneScreen
extends Control

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")
const GRID_COLUMNS := 3

var _content: VBoxContainer
var _background: Panel
var _background_style: StyleBoxFlat
var _apps: Dictionary = {}
var _active_app: PhoneApp = null


func _ready() -> void:
	UI.anchor_full_rect(self)
	_paint_family2_background()
	_content = UI.screen_body(self)
	Barometer.ensure_progress()
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _paint_family2_background() -> void:
	_background = Panel.new()
	UI.anchor_full_rect(_background)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_style = StyleBoxFlat.new()
	_background.add_theme_stylebox_override("panel", _background_style)
	add_child(_background)


func _refresh() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if _active_app != null:
		_active_app.teardown()
		_active_app = null
	_content.get_parent().visible = true

	var nav: Dictionary = GameState.state["phoneNav"]
	var app_id: String = nav["app"]
	if app_id == "home":
		_background_style.bg_color = GameData.PALETTE.get("phone_bg_home", Color("#1b1b1d"))
	else:
		_background_style.bg_color = GameData.PALETTE.get("phone_bg_content", Color("#252528"))

	if PhoneAppRegistry.REGISTRY.has(app_id):
		_active_app = app_instance(app_id)
		_active_app.build(_content)
	else:
		_build_home()
	ContactCards.apply_phone_os_chrome(_content)


# One PhoneApp per id, created on first open and kept for the screen's
# lifetime so an app's own view state survives refreshes.
func app_instance(app_id: String) -> PhoneApp:
	if not _apps.has(app_id):
		var app: PhoneApp = PhoneAppRegistry.REGISTRY[app_id].new()
		app.shell = self
		_apps[app_id] = app
	return _apps[app_id]


func _build_home() -> void:
	_content.add_child(UI.heading("Phone"))
	_content.add_child(_build_app_grid(PhoneApps.apps()))


func _build_app_grid(apps_list: Array[Dictionary]) -> Control:
	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	for config in PhoneApps.build_tile_configs(apps_list, _badge_for):
		var tile := AppTile.new(true)
		grid.add_child(tile)
		tile.configure(config)
		tile.tile_pressed.connect(_on_app_tile_pressed)
	var wrapper := CenterContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_child(grid)
	return wrapper


func _on_app_tile_pressed(app_id: String) -> void:
	if app_id == "vfl":
		if _vfl_locked():
			Notify.push(NavBar.LOCKED_MAP_LABEL)
		else:
			Nav.go_to("map")
		return
	if app_id == "contacts":
		Nav.go_to("contacts")
		return
	PhoneNav.open_app(app_id)


func _vfl_locked() -> bool:
	return not GameState.state["flags"]["archiePartnerSeen"]


func _badge_for(app_id: String) -> bool:
	match app_id:
		"alarms":
			return RaidAlarmsSystem.has_unresolved()
		"ticker":
			return _has_ticker_rumblings()
		_:
			return false


func _has_ticker_rumblings() -> bool:
	for section in Barometer.SECTIONS:
		if Barometer.trend_hint_state(section) != null:
			return true
	return false
