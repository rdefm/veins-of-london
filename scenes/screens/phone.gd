# Phone tab shell: owns the persistent simulated device, home app grid and
# tile routing, and dispatches any open app (state.phoneNav.app) to its
# PhoneApp from scenes/phone_apps/phone_app_registry.gd. Each app's view
# lives in its own script under scenes/phone_apps/.
class_name PhoneScreen
extends Control

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")
const PhoneDeviceShellScript := preload("res://scenes/components/phone_device_shell.gd")
const PhoneHomeDockScript := preload("res://scenes/components/phone_home_dock.gd")
const GRID_COLUMNS := 4

var _content: VBoxContainer
var device_shell: PhoneDeviceShellScript
var _apps: Dictionary = {}
var _active_app: PhoneApp = null
var _home_dock: PhoneHomeDock = null


func _ready() -> void:
	UI.anchor_full_rect(self)
	device_shell = PhoneDeviceShellScript.new()
	add_child(device_shell)
	device_shell.ensure_built()
	_content = device_shell.content
	_home_dock = PhoneHomeDockScript.new()
	device_shell.display.add_child(_home_dock)
	_home_dock.ensure_built()
	Barometer.ensure_progress()
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if _active_app != null:
		_active_app.teardown()
		_active_app = null
	device_shell.show_shared_content()

	var nav: Dictionary = GameState.state["phoneNav"]
	var app_id: String = nav["app"]
	device_shell.set_home_mode(app_id == "home")
	_set_home_dock_visible(app_id == "home")

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
	device_shell.add_home_widget()
	_content.add_child(_build_app_grid(PhoneApps.apps()))


func _set_home_dock_visible(is_home: bool) -> void:
	_home_dock.visible = is_home
	if is_home:
		_home_dock.refresh_badges()


func mount_custom_root(root: Control) -> void:
	device_shell.mount_custom_root(root)


func _build_app_grid(apps_list: Array[Dictionary]) -> Control:
	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	for config in PhoneApps.build_tile_configs(apps_list, _badge_count_for):
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


func _badge_count_for(app_id: String) -> int:
	match app_id:
		"alarms":
			return RaidAlarmsSystem.count()
		"bizbrief":
			return MorningAccounts.attention_items().size()
		"ticker":
			return _ticker_rumblings_count()
		"notifications":
			return _unseen_notification_count()
		"messages":
			return Messages.total_unread_count()
		_:
			return 0


func _ticker_rumblings_count() -> int:
	var count := 0
	for section in Barometer.SECTIONS:
		if Barometer.trend_hint_state(section) != null:
			count += 1
	return count


func _unseen_notification_count() -> int:
	var count := 0
	for notification in GameState.state["notifications"]:
		if not notification.get("seen", false):
			count += 1
	return count
