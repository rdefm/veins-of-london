extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# hq-diorama ticket 04, docs/hq-diorama-vision.md §6: the floorplan
# sub-view, reached from hq.gd's "rooms" zone tap (see
# tests/test_hq_screen.gd's own "hq_rooms_zone_tap_navigates_to_the_hq_
# floorplan_screen"). Cases below are the direct port of the old
# modal_layer.gd "hq_rooms_list" modal cases (hq-diorama ticket 02) onto
# this screen -- same system calls, same assertions, minus the
# Modal.open()/Modal.close() plumbing a full-bleed screen doesn't have.
#
# HqFloorplanScreen.new() is safe to call _ready() on directly without
# adding it to a live scene tree, same reasoning tests/test_hq_screen.gd
# already relies on for HqScreen.


func run() -> void:
	run_case("hq_floorplan_bedsit_tier_shows_an_empty_plan_with_every_room_locked", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		# bedsit's own maxRooms is 0 (data/home.json) -- §3.1: "bedsit (empty
		# plan; teaches the object)".

		var screen := HqFloorplanScreen.new()
		screen._ready()

		for room_id in GameData.HOME_ROOMS.keys():
			var room: Dictionary = GameData.HOME_ROOMS[room_id]
			assert_true(NodeQuery.find_button(screen, "£%d" % room["cost"]) == null, "no room should be purchasable at bedsit tier (%s)" % room_id)

		screen.free()
	)

	run_case("hq_floorplan_flat_tapping_room_02_lists_eligible_uses_and_buys_into_the_slot", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"

		var screen := HqFloorplanScreen.new()
		screen._ready()

		assert_true(NodeQuery.find_button(screen, "£800") == null, "no uses are offered until a room is tapped")
		var slot := screen.find_child(FloorplanView.slot_node_name(0), true, false) as Button
		assert_true(slot != null, "room 02 is a touch target on the plan")
		assert_eq(screen.find_child(FloorplanView.slot_node_name(1), true, false), null, "the bedroom is not a selectable slot")
		assert_true(slot.size.x >= 44.0 and slot.size.y >= 44.0, "room 02's touch region is at least a mobile tap target")

		slot.pressed.emit()
		var library := NodeQuery.find_button(screen, "£%d" % GameData.HOME_ROOMS["library"]["cost"])
		assert_true(library != null and library.disabled, "Library is listed but locked at the Flat")
		assert_true(NodeQuery.label_texts(screen).has("Requires Townhouse or better."), "a locked use says why")
		assert_true(NodeQuery.label_texts(screen).has("Crafting success +8%"), "a use shows its effect")

		NodeQuery.find_button(screen, "£800").pressed.emit()
		assert_eq(GameState.state["home"]["rooms"], ["workshop"], "the Workshop occupies room 02")
		assert_eq(GameState.state["player"]["cash"], 99200, "charged once")

		screen.free()
	)

	run_case("hq_floorplan_flat_replacing_room_02_charges_the_new_price_and_swaps_the_use", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 700
		GameState.state["home"]["tier"] = "flat"
		GameState.state["home"]["rooms"] = ["workshop"]

		var screen := HqFloorplanScreen.new()
		screen._ready()
		(screen.find_child(FloorplanView.slot_node_name(0), true, false) as Button).pressed.emit()

		assert_true(NodeQuery.label_texts(screen).has("Installed: Workshop"), "the current use is shown")
		assert_true(NodeQuery.find_button(screen, "Installed").disabled, "the installed use can't be rebought")
		NodeQuery.find_button(screen, "£600").pressed.emit()
		assert_eq(GameState.state["home"]["rooms"], ["homeGym"])
		assert_eq(GameState.state["player"]["cash"], 100)

		screen.free()
	)

	run_case("hq_floorplan_flat_unaffordable_use_is_disabled_with_its_reason", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 700
		GameState.state["home"]["tier"] = "flat"

		var screen := HqFloorplanScreen.new()
		screen._ready()
		(screen.find_child(FloorplanView.slot_node_name(0), true, false) as Button).pressed.emit()

		assert_true(NodeQuery.find_button(screen, "£800").disabled, "Workshop is unaffordable at £700")
		assert_true(not NodeQuery.find_button(screen, "£600").disabled, "Home Gym is affordable")
		assert_true(NodeQuery.label_texts(screen).has("Not enough cash."))

		screen.free()
	)

	# vein-growth-state ticket 09 (spec §6.2): HQ's own entry point into the
	# vein list, once the Vein Station room is installed.
	run_case("hq_floorplan_installed_vein_station_exposes_a_view_all_veins_button_that_opens_the_list", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("veinStation")

		var screen := HqFloorplanScreen.new()
		screen._ready()

		var view_all_button := NodeQuery.find_button(screen, "View all veins")
		assert_true(view_all_button != null, "an installed Vein Station room must expose a way into the unfiltered vein list")

		view_all_button.pressed.emit()

		assert_eq(GameState.state["veinListNav"]["districtId"], null, "HQ's entry point is unfiltered -- every district")
		assert_eq(GameState.state["veinListNav"]["originScreen"], "hq", "the list's own Back button must return to HQ, not the floorplan or the Map tab")
		assert_eq(GameState.state["currentScreen"], "vein_list")

		screen.free()
	)

	run_case("hq_floorplan_installed_lab_room_exposes_a_contact_assignment_row", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("lab")
		var contacts: Dictionary = GameState.state["contacts"]
		var some_contact_id: String = "des"
		contacts[some_contact_id]["recruited"] = true

		var screen := HqFloorplanScreen.new()
		screen._ready()

		var assign_button := NodeQuery.find_button(screen, "Assign %s" % Contacts.display_name(some_contact_id))
		assert_true(assign_button != null, "an installed lab room must expose an Assign row for a recruited, unassigned contact")

		assign_button.pressed.emit()
		assert_eq(Contacts.get_contact_in_room("lab"), some_contact_id, "tapping Assign must assign the contact to the room, unchanged from the old direct row")

		screen.free()
	)

	# 21-contact-roles-sales-skill: the Operations Room ("ops") is the Sales
	# gate, assignable the same way as lab/veinStation.
	run_case("hq_floorplan_installed_ops_room_exposes_a_contact_assignment_row", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("ops")
		var contacts: Dictionary = GameState.state["contacts"]
		var some_contact_id: String = "des"
		contacts[some_contact_id]["recruited"] = true

		var screen := HqFloorplanScreen.new()
		screen._ready()

		var assign_button := NodeQuery.find_button(screen, "Assign %s" % Contacts.display_name(some_contact_id))
		assert_true(assign_button != null, "an installed ops room must expose an Assign row for a recruited, unassigned contact")

		assign_button.pressed.emit()
		assert_eq(Contacts.get_contact_in_room("ops"), some_contact_id, "tapping Assign must assign the contact to Sales (ops), same mechanism as lab/veinStation")

		screen.free()
	)

	run_case("hq_floorplan_room_assignment_row_omits_founders", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("lab")
		Contacts.force_recruit("archie")

		var screen := HqFloorplanScreen.new()
		screen._ready()
		assert_eq(NodeQuery.find_button(screen, "Assign Archie"), null, "founders take room-free roles, not rooms")
		screen.free()
	)

	run_case("hq_floorplan_unassign_button_vacates_the_room", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("lab")
		var contacts: Dictionary = GameState.state["contacts"]
		var some_contact_id: String = "des"
		contacts[some_contact_id]["recruited"] = true
		Contacts.assign_to_room(some_contact_id, "lab")

		var screen := HqFloorplanScreen.new()
		screen._ready()

		var unassign_button := NodeQuery.find_button(screen, "Unassign")
		assert_true(unassign_button != null, "an assigned lab room must expose an Unassign button")

		unassign_button.pressed.emit()
		assert_eq(Contacts.get_contact_in_room("lab"), null, "tapping Unassign must vacate the room")

		screen.free()
	)

	# ticket 28: the "review/override" half of the default-then-review
	# payroll model -- an assigned role that came up unpaid at rollover
	# exposes a manual "Pay now" catch-up button here.
	run_case("hq_floorplan_unpaid_role_exposes_a_pay_now_button_that_clears_it", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("lab")
		var contacts: Dictionary = GameState.state["contacts"]
		var some_contact_id: String = "des"
		contacts[some_contact_id]["recruited"] = true
		Contacts.assign_to_room(some_contact_id, "lab")
		GameState.state["player"]["cash"] = 0
		Payroll.pay_wages()
		assert_true(not Payroll.is_paid_today("lab"))

		var poor_screen := HqFloorplanScreen.new()
		poor_screen._ready()
		var disabled_button := NodeQuery.find_button(poor_screen, "Pay now (£100)")
		assert_true(disabled_button != null, "an unpaid role must expose a Pay now catch-up button")
		assert_true(disabled_button.disabled, "Pay now should be disabled while cash is still short")
		poor_screen.free()

		GameState.state["player"]["cash"] = 100
		var funded_screen := HqFloorplanScreen.new()
		funded_screen._ready()
		var pay_button := NodeQuery.find_button(funded_screen, "Pay now (£100)")
		assert_true(not pay_button.disabled, "Pay now should enable once cash covers the wage")
		pay_button.pressed.emit()

		assert_true(Payroll.is_paid_today("lab"), "tapping Pay now must clear today's unpaid wage")
		assert_eq(GameState.state["player"]["cash"], 0)

		funded_screen.free()
	)

	run_case("hq_floorplan_back_button_returns_to_hq", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq_floorplan"

		var screen := HqFloorplanScreen.new()
		screen._ready()

		NodeQuery.find_button(screen, "‹ Back").pressed.emit()
		assert_eq(GameState.state["currentScreen"], "hq", "Back must return to the HQ room, not the phone home grid")

		screen.free()
	)
