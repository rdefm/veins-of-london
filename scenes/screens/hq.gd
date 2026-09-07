class_name HqScreen
extends Control

# hq-diorama ticket 02, docs/hq-diorama-vision.md §3: the HQ tab is now the
# single room plate (data/hq_visuals.json's "rooms" table, rendered by
# scenes/components/hq_diorama.gd) instead of hq.gd's old scrolling card
# stack. Tapping a zone opens today's existing destination unchanged --
# diegetic replacements for each (Dial view, Lab bench, floorplan, door) are
# later tickets (04/05/06/09); this ticket only makes the room navigable.
# Security/Rooms/Ore-store/Dial/Gym destinations that used to be inline
# cards now live in scenes/components/modal_layer.gd (types
# "hq_security_list", "hq_rooms_list", "hq_ore_readout", "hq_dial",
# "hq_gym") -- moved, not rewritten, so every button/system call inside
# them is the exact same code that used to render inline here.
#
# Gym is wired into the bedsit plate (data/hq_visuals.json's "gym" region)
# despite §3.1's own "First tier present" column putting it at "flat", one
# tier above bedsit -- v1 (§10) ships only the bedsit plate, so a strict
# reading would leave Gym unreachable until a Flat-tier art ticket ships.
# Ticket 02's own prose lists Gym among the zones to wire up regardless;
# the human maintainer confirmed wiring it into bedsit now over leaving it
# dark (see data/hq_visuals.json's own "gymDeviation" meta note). The Gym
# zone tap still just opens the destination modal -- no gym furniture art
# is implied by this, same "empty image -> placeholder box" rule every
# other region already follows.
#
# The old HQ-screen "Defend" shortcut is deliberately kept out of the
# normal room view -- §8's hostile-door state is ticket 5's job: a pending
# raid stays reachable via the Notifications app's own Defend button in the
# meantime (phone.gd), so no mechanic is actually lost. Confirmed with the
# human maintainer rather than assumed.

var _diorama: HqDiorama
var _debug_overlay_enabled: bool = false


func _ready() -> void:
	UI.anchor_full_rect(self)

	# 11-phone-os-shell-06: mirrors home.gd's _ready() check — checked once
	# per visit, before building the normal HQ UI or connecting _refresh,
	# since starting the event navigates away and this node is about to be
	# freed by Main.gd's screen swap.
	var flags: Dictionary = GameState.state["flags"]
	if flags["homeRaidEventPending"] and not flags["homeRaidEventSeen"]:
		Events.start_event("home_raid_intro")
		return

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in get_children():
		child.queue_free()
	_diorama = null

	if not GameState.state["flags"]["homeUnlocked"]:
		_build_locked_view()
		return

	_build_room_view()


# Rest must always be reachable, even before homeUnlocked -- the room plate
# itself only exists once HQ is unlocked, so this fallback keeps the one
# always-available action (and the raid-pending Defend shortcut, unchanged
# from the old Actions card) working in the meantime.
func _build_locked_view() -> void:
	var content := UI.screen_body(self)
	content.add_child(UI.back_to_home_button())

	var c := UI.card()
	c["content"].add_child(UI.heading("Actions", 14))
	c["content"].add_child(UI.button("Rest", func(): TimeSystem.do_rest()))
	if Home.has_pending_raid():
		c["content"].add_child(UI.button("Defend", func(): Home.trigger_defend()))
	content.add_child(c["panel"])

	content.add_child(UI.heading("Locked"))
	content.add_child(UI.muted_label("HQ unlocks as you progress. Keep sourcing. Keep your head down."))


func _build_room_view() -> void:
	var home: Dictionary = GameState.state["home"]
	var rooms_visuals: Dictionary = GameData.HQ_VISUALS["rooms"]
	# v1 (docs/hq-diorama-vision.md §10) ships only the bedsit plate -- a
	# player already past bedsit tier falls back to it rather than crash,
	# same "anything not drawn is unreachable" cost §1 names for any object
	# whose tier hasn't shipped yet. Forward-compatible with zero code
	# change once a later art ticket adds that tier's own key.
	var plate: Dictionary = rooms_visuals.get(home["tier"], rooms_visuals["bedsit"])

	_diorama = HqDiorama.new()
	_diorama.build(plate)
	_diorama.set_debug_overlay_enabled(_debug_overlay_enabled)
	_diorama.position = Vector2(0.0, UI.top_bar_clearance())
	_diorama.gui_input.connect(_on_diorama_gui_input)
	add_child(_diorama)

	# ticket 01's debug region overlay needs a runtime toggle for the human
	# to actually see it -- a small corner button, not a card, so it doesn't
	# reintroduce the card stack this ticket removes.
	var debug_toggle := UI.button("Debug regions" if not _debug_overlay_enabled else "Debug regions ✓", _on_debug_toggle_pressed)
	debug_toggle.position = Vector2(4.0, UI.top_bar_clearance() + 4.0)
	add_child(debug_toggle)


func _on_debug_toggle_pressed() -> void:
	_debug_overlay_enabled = not _debug_overlay_enabled
	_refresh()


func _on_diorama_gui_input(event: InputEvent) -> void:
	var is_press: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if not is_press:
		return

	var rects: Dictionary = _diorama.region_rects()
	for zone_id in rects:
		if (rects[zone_id] as Rect2).has_point(event.position):
			_on_zone_tapped(zone_id)
			return


# §3.2: overlapping regions share one region id and open a chooser
# (map_bubble.gd pattern) -- data/hq_visuals.json's bedsit regions don't
# overlap (GameData._validate_hq_visuals() enforces it), so no chooser is
# needed for this manifest; a future overlapping region would need one
# here.
func _on_zone_tapped(zone_id: String) -> void:
	match zone_id:
		"dial":
			Modal.open("hq_dial")
		"lab":
			BenchNav.go_home()
			Nav.go_to("lab")
		"security":
			Modal.open("hq_security_list")
		"rest":
			TimeSystem.do_rest()
		"rooms":
			Modal.open("hq_rooms_list")
		"oreStore":
			Modal.open("hq_ore_readout")
		"gym":
			Modal.open("hq_gym")
