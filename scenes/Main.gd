extends Control

# ScreenManager: swaps scenes/screens/* on EventBus.screen_changed, per
# R§2.2's screen list. Placeholder scripts stand in for screens T12
# hasn't rebuilt yet; "event" stays a placeholder until T13.

const SCREEN_SCRIPTS := {
	"title": preload("res://scenes/screens/title.gd"),
	"intro": preload("res://scenes/screens/placeholder.gd"),
	"home": preload("res://scenes/screens/home.gd"),
	"veins": preload("res://scenes/screens/veins.gd"),
	"inventory": preload("res://scenes/screens/inventory.gd"),
	"crafting": preload("res://scenes/screens/placeholder.gd"),
	"contacts": preload("res://scenes/screens/placeholder.gd"),
	"sms_archie": preload("res://scenes/screens/placeholder.gd"),
	"sms_archie_2": preload("res://scenes/screens/placeholder.gd"),
	"world": preload("res://scenes/screens/placeholder.gd"),
	"property": preload("res://scenes/screens/placeholder.gd"),
	"factions": preload("res://scenes/screens/placeholder.gd"),
	"barometer": preload("res://scenes/screens/placeholder.gd"),
	"stats": preload("res://scenes/screens/placeholder.gd"),
	"save": preload("res://scenes/screens/placeholder.gd"),
	"combat": preload("res://scenes/screens/placeholder.gd"),
	"event": preload("res://scenes/screens/placeholder.gd"),
}

# R§2.2: "Global bottom nav ... hidden on title, intro, event, combat".
const NAV_HIDDEN_SCREENS := ["title", "intro", "event", "combat"]

var screen_container: Control
var nav_bar: Control
var notification_toast: Control
var modal_layer: Control
var current_screen_node: Control = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	screen_container = Control.new()
	screen_container.name = "ScreenContainer"
	screen_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_container)

	nav_bar = NavBar.new()
	add_child(nav_bar)

	notification_toast = NotificationToast.new()
	add_child(notification_toast)

	modal_layer = ModalLayer.new()
	add_child(modal_layer)

	EventBus.screen_changed.connect(_on_screen_changed)
	_show_screen(GameState.state["currentScreen"])


func _on_screen_changed(screen_id: String) -> void:
	_show_screen(screen_id)


func _show_screen(screen_id: String) -> void:
	if current_screen_node != null:
		current_screen_node.queue_free()
		current_screen_node = null

	var script: GDScript = SCREEN_SCRIPTS.get(screen_id, SCREEN_SCRIPTS["title"])
	current_screen_node = script.new()
	current_screen_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_container.add_child(current_screen_node)

	nav_bar.visible = not NAV_HIDDEN_SCREENS.has(screen_id)
