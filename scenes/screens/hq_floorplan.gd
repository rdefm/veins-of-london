class_name HqFloorplanScreen
extends Control

# hq-diorama ticket 04, docs/hq-diorama-vision.md §6: the pinned noticeboard
# zone's diegetic destination -- an estate agent's plan of the property:
# filled room slots, empty (locked/purchasable) slots, and contact
# assignment for the lab/veinStation rooms. Reached from hq.gd's "rooms"
# zone tap; Back returns to "hq" specifically, not the phone home grid.
#
# §3.3: sub-views are full-bleed -- the persistent TopBar and NavBar hide
# for this screen id (scenes/Main.gd's TOP_BAR_HIDDEN_SCREENS/
# NAV_HIDDEN_SCREENS), the first sub-view that actually needs this (every
# earlier HQ destination is still a Modal, which draws over both bars
# rather than needing them gone).
#
# §3.1 groups the floorplan with the door/bench as "diegetic", explicitly
# against "list-style panels" (Train, vein list) -- a first pass here was a
# plain single-column card list (the old hq_rooms_list modal's own shape,
# just full-bleed) and a human review call flagged that as reading like the
# list-style bucket it's supposed to be unlike. Rendered instead as a
# 2-column GRID of room-slot tiles (a floor-plan's own visual grammar --
# side-by-side rooms, not a stacked list), still with zero baked art: no
# hq_visuals.json manifest entry exists for this view, because unlike the
# room plate/door/bench, the floorplan's slot count is data-driven off
# GameData.HOME_ROOMS/HOME_TIERS (0-12 rooms across tiers) rather than a
# fixed pixel-art layout -- there's nothing fixed-position to bake a plate
# for. TILE_MIN_WIDTH/TILE_LABEL_MAX_WIDTH below keep each tile's text
# wrapping inside its own column instead of UI.label()'s normal full-text-
# width reservation forcing the grid wider than the 390px screen.
#
# Content (room slots + Home.add_room()/Contacts.assign_to_room()/
# Contacts.get_contact_in_room() calls) is moved from modal_layer.gd's
# deleted "hq_rooms_list" modal (hq-diorama ticket 02) -- every system call
# is unchanged, per the vision doc's own §2 "Out" list. Only the rendering
# shape (grid of tiles vs. single-column cards) is new.
#
# PROSE-REVIEW: "Floorplan" heading is new copy; everything else (room
# names/descriptions, "Installed"/"Locked"/"No room"/"Assigned: no one")
# carries over unchanged from the old modal.

# Moved here from modal_layer.gd's ASSIGNABLE_ROOMS (hq-diorama ticket 02's
# own comment): the lab/veinStation rooms are the only ones a contact can
# be assigned to.
const ASSIGNABLE_ROOMS := ["lab", "veinStation"]

const GRID_COLUMNS := 2

# Screen is 390px logical wide; margin(16)*2 + grid h_separation(8) leaves
# 350px for 2 columns -- 160 each plus a little slack to expand into.
const TILE_MIN_WIDTH := 160.0

# Narrower than UI.label()'s own MAX_LABEL_TEXT_WIDTH (220) -- a room
# description at that width alone would force a grid column wider than the
# tile has room for. Labels autowrap word-smart regardless of their
# reserved minimum, so clamping this down just makes long text wrap onto
# more lines instead of blowing out the column.
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
	# No persistent TopBar/NavBar to clear here (both hidden for this screen
	# id) -- just the notch/home-indicator safe areas plus normal breathing
	# room, same shape map.gd's own top-row margin uses for the top inset.
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


# A narrow-width label for use inside a grid tile -- see TILE_LABEL_MAX_WIDTH
# above for why this clamps rather than using UI.label()/muted_label() bare.
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


# R§3.10: lab/veinStation each run daily processing for whichever recruited
# contact is assigned to them (Contacts.assign_to_room). One contact per
# room; assigning a contact elsewhere vacates their old room automatically.
# hflow (not hbox) so assign buttons wrap inside the narrow grid tile
# instead of overflowing its column.
func _build_room_contact_row(room_id: String) -> Control:
	var contacts: Dictionary = GameState.state["contacts"]
	var assigned_id: Variant = Contacts.get_contact_in_room(room_id)

	var box := UI.vbox(4)
	var assigned_text: String = "Assigned: %s" % Contacts.display_name(assigned_id) if assigned_id != null else "Assigned: no one"
	box.add_child(_tile_label(assigned_text, true))

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


# vein-growth-state ticket 09 (spec §6.2): HQ's own entry point into the
# vein list, unfiltered -- the district bubble's "List view" (systems/
# district_bubble.gd's LIST_ID) is the other. VeinListNav.open_all() sets
# state.veinListNav.originScreen to "hq" so the list's Back button returns
# to HQ, not this floorplan sub-view or the Map tab. Unlike the old modal
# version, there's no Modal.close() needed here -- this is a screen
# navigation, not an overlay stacked on top of one.
func _build_vein_station_list_row() -> Control:
	return UI.button("View all veins", func():
		VeinListNav.open_all()
		Nav.go_to("vein_list")
	)
