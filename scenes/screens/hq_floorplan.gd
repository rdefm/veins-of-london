class_name HqFloorplanScreen
extends Control
const ASSIGNABLE_ROOMS := ["lab", "veinStation", "ops"]

const GRID_COLUMNS := 2
const TILE_MIN_WIDTH := 160.0
const TILE_LABEL_MAX_WIDTH := 130.0

# Selected plan slot is view-only state, never game state; -1 = none.
var _selected_slot: int = -1

func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in get_children():
		child.queue_free()
	# Off the Map tab: light card family (MapCardStyle).
	MapPalette.build_light(_build)


func _build() -> void:
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
	if FloorplanView.has_plan(home["tier"]):
		content.add_child(UI.heading(tier["name"], 14))
		content.add_child(UI.muted_label(tier["description"]))
	content.add_child(UI.muted_label("Rooms: %d/%d" % [home["rooms"].size(), tier["maxRooms"]]))

	if FloorplanView.has_plan(home["tier"]):
		_build_plan(content, home["tier"])
		return

	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)

	for room_id in GameData.HOME_ROOMS.keys():
		grid.add_child(_build_room_slot(room_id))

# Tiers with a plan asset (data/floorplans.json): rooms are chosen per
# physical slot on the plan (.scratch/flat-floorplan/spec.md).
func _build_plan(content: VBoxContainer, tier_id: String) -> void:
	content.add_child(FloorplanView.build(tier_id, _on_slot_pressed, _selected_slot))
	# PROSE-REVIEW: UI hint, drafted against CONTENT-GUIDE.md.
	content.add_child(UI.muted_label("Tap a marked room to choose its use. The bedroom stays a bedroom."))
	if _selected_slot >= 0 and _selected_slot < Home.get_room_slot_count():
		content.add_child(_build_slot_card(tier_id, _selected_slot))

func _on_slot_pressed(slot: int) -> void:
	_selected_slot = slot
	_refresh()

func _build_slot_card(tier_id: String, slot: int) -> Control:
	var current_id: String = Home.get_room_in_slot(slot)
	var c := MapCardStyle.card()
	c["content"].add_child(UI.muted_label("ROOM %s" % FloorplanView.slot_label(tier_id, slot)))
	c["content"].add_child(UI.heading("Change room use" if current_id != "" else "Choose room use", 14))
	if current_id != "":
		c["content"].add_child(UI.label("Installed: %s" % GameData.HOME_ROOMS[current_id]["name"]))
		# PROSE-REVIEW: replacement warning, drafted against CONTENT-GUIDE.md.
		c["content"].add_child(UI.muted_label("Changing it removes the current upgrade. No refund; the new use costs full price."))
		if ASSIGNABLE_ROOMS.has(current_id):
			c["content"].add_child(_build_room_contact_row(current_id))
		if current_id == "veinStation":
			c["content"].add_child(_build_vein_station_list_row())

	for room_id in _listed_room_ids():
		c["content"].add_child(_build_use_row(slot, room_id, current_id))

	c["content"].add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func():
		_selected_slot = -1
		_refresh()
	)]))
	return c["panel"]

# Rooms unlocked at this tier, plus those the next tier up would unlock.
func _listed_room_ids() -> Array:
	var order: Array = GameData.HOME_TIER_ORDER
	var horizon: int = order.find(GameState.state["home"]["tier"]) + 1
	var ids: Array = []
	for room_id in GameData.HOME_ROOMS.keys():
		if order.find(GameData.HOME_ROOMS[room_id]["minTier"]) <= horizon:
			ids.append(room_id)
	return ids

func _build_use_row(slot: int, room_id: String, current_id: String) -> Control:
	var room: Dictionary = GameData.HOME_ROOMS[room_id]
	var box := UI.vbox(2)
	box.add_child(UI.label(room["name"]))
	var effect := _effect_text(room)
	if effect != "":
		box.add_child(UI.muted_label(effect))
	box.add_child(UI.muted_label(room["description"]))

	if room_id == current_id:
		box.add_child(MapCardStyle.text_button("Installed", func(): pass, true))
		return box

	var reason := Home.room_use_block_reason(slot, room_id)
	box.add_child(MapCardStyle.action_button("£%d" % room["cost"], func(): _buy(slot, room_id), reason != "", reason))
	return box

func _buy(slot: int, room_id: String) -> void:
	if Home.set_room_use(slot, room_id)["ok"]:
		_selected_slot = -1
		_refresh()

func _effect_text(room: Dictionary) -> String:
	match room["bonus"]:
		"crafting":
			return "Crafting success +%d%%" % int(round(room["bonusValue"] * 100))
		"body":
			return "Max HP +%d" % int(room["bonusValue"])
	return ""

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

	var c := MapCardStyle.card(12)
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
		c["content"].add_child(MapCardStyle.text_button("£%d" % room["cost"], func(): Home.add_room(room_id), GameState.state["player"]["cash"] < room["cost"]))

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
		box.add_child(MapCardStyle.text_button("Pay now (£%d)" % wage, func(): Payroll.pay_now(room_id), GameState.state["player"]["cash"] < wage))

	var row := UI.hflow(4)
	for contact_id in contacts.keys():
		var c: Dictionary = contacts[contact_id]
		if not c["recruited"] or c["assignedRoom"] == room_id:
			continue
		var captured_id: String = contact_id
		row.add_child(MapCardStyle.text_button("Assign %s" % Contacts.display_name(contact_id), func(): Contacts.assign_to_room(captured_id, room_id)))
	if assigned_id != null:
		row.add_child(MapCardStyle.text_button("Unassign", func(): Contacts.assign_to_room("none", room_id)))
	if row.get_child_count() > 0:
		box.add_child(row)

	return box
func _build_vein_station_list_row() -> Control:
	return MapCardStyle.text_button("View all veins", func():
		VeinListNav.open_all()
		Nav.go_to("vein_list")
	)
