class_name HqScreen
extends Control

var _diorama: HqDiorama
var _debug_overlay_enabled: bool = false

func _ready() -> void:
	UI.anchor_full_rect(self)
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

	# Off the Map tab: light card family (MapCardStyle).
	MapPalette.build_light(func():
		if not GameState.state["flags"]["homeUnlocked"]:
			_build_locked_view()
		else:
			_build_room_view()
	)
func _build_locked_view() -> void:
	_build_locked_background()

	var content := UI.screen_body(self)
	content.add_child(UI.back_to_home_button())

	var c := MapCardStyle.card()
	c["content"].add_child(MapCardStyle.section_label("Actions", 14))
	c["content"].add_child(MapCardStyle.text_button(GameData.DAY_CLOCK["restLabel"], func(): TimeSystem.do_rest()))
	if Home.has_pending_raid():
		c["content"].add_child(MapCardStyle.text_button("Defend", func(): Home.trigger_defend()))
	content.add_child(c["panel"])
func _build_locked_background() -> void:
	var bedsit_plate: Dictionary = GameData.HQ_VISUALS["rooms"]["bedsit"].duplicate(true)
	bedsit_plate["regions"] = {}
	var background := HqDiorama.new()
	background.build(bedsit_plate)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.position = Vector2(0.0, UI.top_bar_clearance())
	add_child(background)

func _build_room_view() -> void:
	var home: Dictionary = GameState.state["home"]
	var rooms_visuals: Dictionary = GameData.HQ_VISUALS["rooms"]
	var plate: Dictionary = rooms_visuals.get(home["tier"], rooms_visuals["bedsit"])
	plate = _security_lock_installed_plate(plate, home).duplicate(true)
	if plate["regions"].has("rest"):
		plate["regions"]["rest"]["caption"] = GameData.DAY_CLOCK["restLabel"]

	_diorama = HqDiorama.new()
	_diorama.build(plate)
	_diorama.set_debug_overlay_enabled(_debug_overlay_enabled)
	_diorama.position = Vector2(0.0, UI.top_bar_clearance())
	_diorama.gui_input.connect(_on_diorama_gui_input)
	add_child(_diorama)
	var debug_toggle := MapCardStyle.chip_button("Debug regions" if not _debug_overlay_enabled else "Debug regions ✓", _on_debug_toggle_pressed)
	debug_toggle.position = Vector2(4.0, UI.top_bar_clearance() + 4.0)
	add_child(debug_toggle)
func _security_lock_installed_plate(plate: Dictionary, home: Dictionary) -> Dictionary:
	if not home["security"].has("lock"):
		return plate
	var security_region: Dictionary = plate.get("regions", {}).get("security", {})
	var installed_image: String = security_region.get("installedImage", "")
	if installed_image.is_empty():
		return plate
	var installed_plate: Dictionary = plate.duplicate(true)
	installed_plate["regions"]["security"]["image"] = installed_image
	return installed_plate

func _on_debug_toggle_pressed() -> void:
	_debug_overlay_enabled = not _debug_overlay_enabled
	_refresh()

func _on_diorama_gui_input(event: InputEvent) -> void:
	var is_press: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if not is_press:
		return

	var zone_id := _diorama.zone_at(event.position)
	if zone_id != "":
		_on_zone_tapped(zone_id)
func _on_zone_tapped(zone_id: String) -> void:
	match zone_id:
		"dial":
			Nav.go_to("hq_dial")
		"lab":
			LabBenchNav.open()
			Nav.go_to("hq_lab_bench")
		"security":
			if Home.has_pending_raid():
				Home.trigger_defend()
			else:
				Nav.go_to("hq_door")
		"rest":
			TimeSystem.do_rest()
		"rooms":
			Nav.go_to("hq_floorplan")
		"oreStore":
			Modal.open("hq_ore_readout")
		"gym":
			Modal.open("hq_gym")
