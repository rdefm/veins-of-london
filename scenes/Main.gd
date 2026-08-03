extends Control

# ScreenManager: swaps scenes/screens/* on EventBus.screen_changed, per
# R§2.2's screen list. "intro" is never actually navigated to (Events.
# start_event("intro") sends the player straight to "event" instead) but
# stays mapped for registry completeness.

const SCREEN_SCRIPTS := {
	"title": preload("res://scenes/screens/title.gd"),
	"intro": preload("res://scenes/screens/placeholder.gd"),
	"home": preload("res://scenes/screens/home.gd"),
	"veins": preload("res://scenes/screens/veins.gd"),
	"inventory": preload("res://scenes/screens/inventory.gd"),
	"contacts": preload("res://scenes/screens/contacts.gd"),
	"sms_archie": preload("res://scenes/screens/sms_archie.gd"),
	"sms_archie_2": preload("res://scenes/screens/sms_archie_2.gd"),
	"world": preload("res://scenes/screens/world.gd"),
	"factions": preload("res://scenes/screens/factions.gd"),
	"barometer": preload("res://scenes/screens/barometer.gd"),
	"stats": preload("res://scenes/screens/stats.gd"),
	"save": preload("res://scenes/screens/save.gd"),
	"combat": preload("res://scenes/screens/combat.gd"),
	"event": preload("res://scenes/screens/event.gd"),

	# D4's 5-tab nav (map/hq/phone/bag/you). phone/you are stubs until
	# ticket 07 builds them out; bag reuses the already-complete inventory
	# screen (D4: "Bag — full inventory management"). map is ticket 04's
	# district list -> district panel -> site/vein sheet. hq is ticket 06's
	# merge of the old M0 property + crafting screens (both deleted).
	"map": preload("res://scenes/screens/map.gd"),
	"hq": preload("res://scenes/screens/hq.gd"),
	"phone": preload("res://scenes/screens/placeholder.gd"),
	"bag": preload("res://scenes/screens/inventory.gd"),
	"you": preload("res://scenes/screens/placeholder.gd"),
}

# R§2.2: "Global bottom nav ... hidden on title, intro, event, combat".
const NAV_HIDDEN_SCREENS := ["title", "intro", "event", "combat"]

# D4's persistent top bar is up on every screen except the two with no game
# session to show cash/day/blocks for — unlike NAV_HIDDEN_SCREENS, it stays
# visible through event/combat so the bag button keeps working there (D4.4).
const TOP_BAR_HIDDEN_SCREENS := ["title", "intro"]

var screen_container: Control
var nav_bar: Control
var top_bar: Control
var notification_toast: Control
var modal_layer: Control
var bag_drawer: Control
var current_screen_node: Control = null


func _ready() -> void:
	UI.anchor_full_rect(self)

	screen_container = Control.new()
	screen_container.name = "ScreenContainer"
	UI.anchor_full_rect(screen_container)
	add_child(screen_container)

	top_bar = TopBar.new()
	add_child(top_bar)

	nav_bar = NavBar.new()
	add_child(nav_bar)

	notification_toast = NotificationToast.new()
	add_child(notification_toast)

	modal_layer = ModalLayer.new()
	add_child(modal_layer)

	# Topmost: D4.4's bag drawer has to open over any modal, mid-event or
	# mid-combat, from any screen.
	bag_drawer = BagDrawer.new()
	add_child(bag_drawer)

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
	UI.anchor_full_rect(current_screen_node)
	screen_container.add_child(current_screen_node)

	nav_bar.visible = not NAV_HIDDEN_SCREENS.has(screen_id)
	top_bar.visible = not TOP_BAR_HIDDEN_SCREENS.has(screen_id)
