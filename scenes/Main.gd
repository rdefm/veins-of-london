extends Control

# ScreenManager: swaps scenes/screens/* on EventBus.screen_changed, per
# R§2.2's screen list. "intro" is never actually navigated to (Events.
# start_event("intro") sends the player straight to "event" instead) but
# stays mapped for registry completeness.

const SCREEN_SCRIPTS := {
	"title": preload("res://scenes/screens/title.gd"),
	"intro": preload("res://scenes/screens/placeholder.gd"),
	"contacts": preload("res://scenes/screens/contacts.gd"),
	"sms_archie": preload("res://scenes/screens/sms_archie.gd"),
	"sms_archie_2": preload("res://scenes/screens/sms_archie_2.gd"),
	"factions": preload("res://scenes/screens/factions.gd"),
	"combat": preload("res://scenes/screens/combat.gd"),
	"event": preload("res://scenes/screens/event.gd"),

	# D4's nav bar, collapsed to a 3-slot dock (Phone/Map/HQ) by ticket 11.
	# map is ticket 04's district list -> district panel -> site/vein sheet.
	# hq is ticket 06's merge of the old M0 property + crafting screens
	# (both deleted). phone is ticket 07's PhoneScreen (contact list/SMS/
	# James jobs/notes/faction directory/Ticker/Profile/Save-Load/
	# Notifications, state.phoneNav-driven) — the old M0 `world`/
	# `barometer` screens it replaces are deleted. Ticket 12 retires the
	# standalone `home`/`you`/`bag`/`inventory` screens entirely — the bag
	# drawer (ticket 05) and phone's Profile/Save-Load apps (08/09) had
	# already absorbed everything they carried — so none of the four have
	# a SCREEN_SCRIPTS entry or a remaining Nav.go_to call site.
	"map": preload("res://scenes/screens/map.gd"),
	"hq": preload("res://scenes/screens/hq.gd"),
	"phone": preload("res://scenes/screens/phone.gd"),

	# calc-discovery ticket 06: the Lab, reached from HQ's third card. Its
	# own internal drill-down (home/picker/pairing/notes) is state.benchNav-
	# driven inside lab.gd, same pattern as phoneNav inside phone.gd.
	"lab": preload("res://scenes/screens/lab.gd"),
}

# Ticket 12: home/you/bag/inventory are retired screen ids, fully absorbed
# into the phone app grid + bag drawer (see the SCREEN_SCRIPTS comment
# above). A stale currentScreen carrying one of these -- an old save
# (SaveManager migrates the persisted value too, but this is the last-line
# fallback) or any other stray reference -- must land on the phone app
# grid, not fall through to the "unknown id" title fallback below, which
# stays reserved for ids that were never valid at all.
const RETIRED_SCREEN_IDS := {
	"home": "phone", "you": "phone", "bag": "phone", "inventory": "phone",
}

# R§2.2: "Global bottom nav ... hidden on title, intro, event, combat".
const NAV_HIDDEN_SCREENS := ["title", "intro", "event", "combat"]

# D4's persistent top bar is up on every screen except the two with no game
# session to show cash/day/blocks for — unlike NAV_HIDDEN_SCREENS, it stays
# visible through event/combat so the bag button keeps working there (D4.4).
# Map-filters ticket 02 adds a third exception: the Network diagram wants
# the full screen above the NavBar, and has its own local top bar (hamburger/
# title/bag, map.gd's _build_top_bar()) whose bag button already covers what
# the global one did there.
const TOP_BAR_HIDDEN_SCREENS := ["title", "intro", "map"]

var screen_container: Control
var nav_bar: Control
var top_bar: Control
var notification_toast: Control
var modal_layer: Control
var bag_drawer: Control
var current_screen_node: Control = null


func _ready() -> void:
	# Godot's Android export template hardcodes screenOrientation="landscape"
	# in the manifest regardless of the project's handheld orientation
	# setting (confirmed in export_templates' android_source.zip) -- force
	# portrait explicitly at boot rather than relying on that setting alone.
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


# Split out from _show_screen so tests can drive the retired-id/unknown-id
# fallback logic without booting the full Main scene tree (same reasoning
# phone.gd's _build_app_grid split documents for its own testability).
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

	# If a nested _show_screen already ran during that add_child (a screen's
	# _ready() navigating elsewhere, per above), current_screen_node no longer
	# points at screen_node -- the nested call already set nav_bar/top_bar for
	# the real final screen, and finishing with this call's now-stale
	# resolved_id would clobber that with the wrong screen's visibility.
	if current_screen_node != screen_node:
		return

	nav_bar.visible = not NAV_HIDDEN_SCREENS.has(resolved_id)
	top_bar.visible = not TOP_BAR_HIDDEN_SCREENS.has(resolved_id)
