class_name NavBar
extends Control

# Bottom nav: 3-slot dock (Phone · Map · HQ), collapsed by 11-phone-os-shell
# ticket 11 from the interim 5-tab bar ticket 07 shipped (Map · HQ · Phone ·
# Bag · You). Bag and You are dropped from the bar entirely — the bag
# drawer (ticket 05) and the Profile/Save-Load/Notifications apps (08-10)
# already hold everything those two tabs carried. Hidden by Main.gd on the
# R§2.2 excluded screens (title, intro, event, combat) — this component
# doesn't know about that list itself, just renders the tabs.
#
# Slots render as AppTile (same icon+label+lock tile the phone home grid
# uses, ticket 02) rather than a plain Button, so a locked dock slot gets
# the exact same greyed-padlock treatment as any other locked app — this
# replaces the old hack of overwriting the tab's label text with a hint.

const BAR_HEIGHT := 64.0

const TABS := [
	{ "screen": "phone", "label": "Phone" },
	{ "screen": "map", "label": "Map" },
	{ "screen": "hq", "label": "HQ" },
]

# M1-LONDON D7: the Map slot is locked (greyed, padlocked) until
# archiePartnerSeen — a new game has nowhere to go there yet. This bar is
# built once by Main.gd and never rebuilt, so it has to react to
# state_changed itself, same as any screen's _refresh(). The hint now
# surfaces as a hover tooltip plus a toast on tap (Notify.push, ticket 04's
# toast layer) instead of the old permanent tab-label overwrite.
const LOCKED_MAP_LABEL := "Stick close for now — Archie"

# Ticket 37: bar chrome -- a real background panel behind the 3 tiles, same
# subdued system-UI colours top_bar.gd's _BG_COLOR/_BORDER_COLOR and
# app_tile.gd's FRAME_BG_COLOUR/FRAME_BORDER_COLOUR already share, so the
# dock reads as chrome cut from the same cloth as the rest of the phone
# shell rather than a new surface. A hairline top border (mirroring
# TopBar's bottom border) is what actually separates the bar from whatever
# screen content scrolls up underneath it -- flat bg_color alone doesn't,
# since screens already sit on the same near-white theme background.
const _BG_COLOR := Color(0.909804, 0.894118, 0.85098, 1)
const _BORDER_COLOR := Color(0.831373, 0.811765, 0.768627, 1)

var _tiles: Dictionary = {}


func _ready() -> void:
	UI.anchor_bottom_wide(self)
	offset_top = -BAR_HEIGHT
	offset_bottom = 0.0

	var bg := Panel.new()
	UI.anchor_full_rect(bg)
	var style := StyleBoxFlat.new()
	style.bg_color = _BG_COLOR
	style.border_width_top = 1
	style.border_color = _BORDER_COLOR
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	var row := HBoxContainer.new()
	UI.anchor_full_rect(row)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	for tab in TABS:
		var tile := AppTile.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.tile_pressed.connect(_on_tile_pressed)
		row.add_child(tile)
		_tiles[tab["screen"]] = tile

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var current_screen: String = GameState.state["currentScreen"]
	# Phone is a home button (see _go_phone_home() below), so it only reads
	# as the active tab while actually parked on the app grid -- once the
	# player is inside a sub-app (phoneNav.app != "home") they've navigated
	# past the dock's own top-level "Phone" destination, same distinction
	# _go_phone_home() already makes for what counts as "already home".
	var phone_home: bool = GameState.state["phoneNav"]["app"] == "home"

	for tab in TABS:
		var tile: AppTile = _tiles[tab["screen"]]
		var locked: bool = tab["screen"] == "map" and _map_locked()
		var active: bool
		if tab["screen"] == "phone":
			active = current_screen == "phone" and phone_home
		else:
			active = current_screen == tab["screen"]
		tile.configure({ "id": tab["screen"], "label": tab["label"], "locked": locked, "active": active })
		tile.tooltip_text = LOCKED_MAP_LABEL if locked else ""


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


# Phone is a home button (spec story 6/7): from anywhere else it returns to
# the app grid; from the grid itself it's a no-op, not a re-navigation.
func _go_phone_home() -> void:
	var nav: Dictionary = GameState.state["phoneNav"]
	var already_home: bool = GameState.state["currentScreen"] == "phone" and nav["app"] == "home"
	if already_home:
		return
	if GameState.state["currentScreen"] != "phone":
		Nav.go_to("phone")
	PhoneNav.go_home()
