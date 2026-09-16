extends Control

const SCREEN_SCRIPTS := {
	"title": preload("res://scenes/screens/title.gd"),
	"intro": preload("res://scenes/screens/placeholder.gd"),
	"contacts": preload("res://scenes/screens/contacts.gd"),
	"factions": preload("res://scenes/screens/factions.gd"),
	"combat": preload("res://scenes/screens/combat.gd"),
	"event": preload("res://scenes/screens/event.gd"),
	"map": preload("res://scenes/screens/map.gd"),
	"hq": preload("res://scenes/screens/hq.gd"),
	"phone": preload("res://scenes/screens/phone.gd"),
	"hq_floorplan": preload("res://scenes/screens/hq_floorplan.gd"),
	"hq_door": preload("res://scenes/screens/hq_door.gd"),
	"vein_list": preload("res://scenes/screens/vein_list.gd"),
	"hq_lab_bench": preload("res://scenes/screens/hq_lab_bench.gd"),
	"hq_dial": preload("res://scenes/screens/hq_dial.gd"),
	"guild_marketplace": preload("res://scenes/screens/guild_marketplace.gd"),
	"combat_prototype": preload("res://scenes/screens/combat_prototype.gd"),
}
const RETIRED_SCREEN_IDS := {
	"home": "phone", "you": "phone", "bag": "phone", "inventory": "phone",
	"lab": "hq",
}
const NAV_HIDDEN_SCREENS := ["title", "intro", "event", "combat", "combat_prototype"]
const TOP_BAR_HIDDEN_SCREENS := ["title", "intro"]

var screen_container: Control
var nav_bar: Control
var top_bar: Control
var modal_layer: Control
var bag_drawer: Control
var current_screen_node: Control = null

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

	UI.anchor_full_rect(self)

	screen_container = Control.new()
	screen_container.name = "ScreenContainer"
	UI.anchor_full_rect(screen_container)
	add_child(screen_container)

	top_bar = TopBar.new()
	add_child(top_bar)

	nav_bar = NavBar.new()
	add_child(nav_bar)

	modal_layer = ModalLayer.new()
	add_child(modal_layer)
	bag_drawer = BagDrawer.new()
	add_child(bag_drawer)
	var time_transition := preload("res://scenes/components/time_transition.gd").new()
	add_child(time_transition)
	var alarm_presentation := preload("res://scenes/components/alarm_presentation.gd").new()
	alarm_presentation.time_transition = time_transition
	add_child(alarm_presentation)

	EventBus.screen_changed.connect(_on_screen_changed)
	_show_screen(GameState.state["currentScreen"])

func _on_screen_changed(screen_id: String) -> void:
	_show_screen(screen_id)
static func resolve_screen_id(screen_id: String) -> String:
	var mapped: String = RETIRED_SCREEN_IDS.get(screen_id, screen_id)
	if SCREEN_SCRIPTS.has(mapped):
		return mapped
	return "title"

func _show_screen(screen_id: String) -> void:
	if current_screen_node != null:
		current_screen_node.queue_free()
		current_screen_node = null

	var resolved_id: String = resolve_screen_id(screen_id)
	var screen_node: Control = SCREEN_SCRIPTS[resolved_id].new()
	current_screen_node = screen_node
	UI.anchor_full_rect(screen_node)
	screen_container.add_child(screen_node)  # may re-enter _show_screen synchronously (e.g. hq.gd's _ready() redirecting straight into an event)
	if current_screen_node != screen_node:
		return

	nav_bar.visible = not NAV_HIDDEN_SCREENS.has(resolved_id)
	top_bar.visible = not TOP_BAR_HIDDEN_SCREENS.has(resolved_id)
