class_name HqFloorplanScreen
extends Control
const ASSIGNABLE_ROOMS := ["lab", "veinStation", "ops"]

const GRID_COLUMNS := 2
const TILE_MIN_WIDTH := 160.0
const TILE_LABEL_MAX_WIDTH := 130.0

func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in get_children():
		child.queue_free()

	var sc := UI.scroll_container()
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", int(UI.safe_area_top_inset()) + 16)
	margin.add_theme_constant_override("margin_bottom", int(UI.safe_area_bottom_inset()) + 16)
	sc.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	content.add_child(UI.back_button("hq"))
	content.add_child(UI.heading("Floorplan"))

	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	content.add_child(UI.muted_label("Rooms: %d/%d" % [home["rooms"].size(), tier["maxRooms"]]))

	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)

	for room_id in GameData.HOME_ROOMS.keys():
		grid.add_child(_build_room_slot(room_id))
func _tile_label(text: String, muted: bool = false) -> Label:
	var l: Label = UI.muted_label(text) if muted else UI.label(text)
	l.custom_minimum_size.x = minf(l.custom_minimum_size.x, TILE_LABEL_MAX_WIDTH)
	return l

func _build_room_slot(room_id: String) -> Control:
	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var room: Dictionary = GameData.HOME_ROOMS[room_id]
	var installed: bool = home["rooms"].has(room_id)
	var order: Array = GameData.HOME_TIER_ORDER
	var available: bool = order.find(home["tier"]) >= order.find(room["minTier"])
	var full: bool = home["rooms"].size() >= tier["maxRooms"] and not installed

	var c := UI.card()
	c["panel"].custom_minimum_size.x = TILE_MIN_WIDTH
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var prefix := "✅ " if installed else ("🔒 " if not available else "")
	c["content"].add_child(_tile_label(prefix + room["name"]))
	var desc: String = room["description"]
	if not available:
		desc += " Requires %s." % GameData.HOME_TIERS[room["minTier"]]["name"]
	c["content"].add_child(_tile_label(desc, true))

	if installed:
		c["content"].add_child(_tile_label("Installed", true))
		if ASSIGNABLE_ROOMS.has(room_id):
			c["content"].add_child(_build_room_contact_row(room_id))
		if room_id == "veinStation":
			c["content"].add_child(_build_vein_station_list_row())
	elif not available:
		c["content"].add_child(_tile_label("Locked", true))
	elif full:
		c["content"].add_child(_tile_label("No room", true))
	else:
		var b := UI.button("£%d" % room["cost"], func(): Home.add_room(room_id))
		b.disabled = GameState.state["player"]["cash"] < room["cost"]
		c["content"].add_child(b)

	return c["panel"]
func _build_room_contact_row(room_id: String) -> Control:
	var contacts: Dictionary = GameState.state["contacts"]
	var assigned_id: Variant = Contacts.get_contact_in_room(room_id)

	var box := UI.vbox(4)
	var assigned_text: String = "Assigned: %s" % Contacts.display_name(assigned_id) if assigned_id != null else "Assigned: no one"
	box.add_child(_tile_label(assigned_text, true))
	if assigned_id != null and not Payroll.is_paid_today(room_id):
		var wage: int = Payroll.wage_for_room(room_id)
		box.add_child(_tile_label("Unpaid today -- £%d owed" % wage, true))
		var pay_button := UI.button("Pay now (£%d)" % wage, func(): Payroll.pay_now(room_id))
		pay_button.disabled = GameState.state["player"]["cash"] < wage
		box.add_child(pay_button)

	var row := UI.hflow(4)
	for contact_id in contacts.keys():
		var c: Dictionary = contacts[contact_id]
		if not c["recruited"] or c["assignedRoom"] == room_id:
			continue
		var captured_id: String = contact_id
		row.add_child(UI.button("Assign %s" % Contacts.display_name(contact_id), func(): Contacts.assign_to_room(captured_id, room_id)))
	if assigned_id != null:
		row.add_child(UI.button("Unassign", func(): Contacts.assign_to_room("none", room_id)))
	if row.get_child_count() > 0:
		box.add_child(row)

	return box
func _build_vein_station_list_row() -> Control:
	return UI.button("View all veins", func():
		VeinListNav.open_all()
		Nav.go_to("vein_list")
	)
