extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# Harrow's -- HQ tier stats and the rent/buy/buy-out/move-down
# actions, relocated off the HQ tab (docs/hq-diorama-vision.md §7). Same
# screen-level-tested-against-a-real-PhoneScreen-instance pattern as
# tests/test_phone_bank.gd.


func run() -> void:
	run_case("property_shows_the_current_tiers_stats", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 50 }  # nudges raid risk off the floor, deterministic
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()

		var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
		var expected: String = "Daily cost: £50 · Raid risk: %d%% · Rooms 0/0" % raid_pct
		assert_true(NodeQuery.label_texts(phone).has(expected), "current tier's stats line matches bedsit's daily cost/raid risk/rooms")

		phone.free()
	)

	run_case("property_shows_arrears_balance_and_countdown_only_while_in_arrears", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "flat"
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(not NodeQuery.label_texts(phone).any(func(t: String): return t.begins_with("Arrears")), "no arrears line when paid up")
		phone.free()

		GameState.state["home"]["arrears"] = 320
		GameState.state["home"]["arrearsDays"] = 5
		var before: Dictionary = GameState.deep_copy(GameState.state)
		phone = PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		for expected in ["Arrears: £320", "Interest compounds daily.", "Lose the Flat in 5 days."]:
			assert_true(texts.has(expected), "missing %s" % expected)
		assert_eq(GameState.state["home"], before["home"], "rendering only reads state")
		phone.free()

		GameState.state["home"]["tier"] = "bedsit"
		phone = PhoneScreen.new()
		phone._ready()
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("Arrears: £320"))
		assert_true(not texts.any(func(t: String): return t.begins_with("Lose the")), "no downgrade countdown at the bedsit")
		phone.free()
	)

	run_case("property_current_daily_cost_follows_tenure", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "townhouse"
		GameState.state["phoneNav"]["app"] = "property"
		var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))

		GameState.state["home"]["tenure"] = "owned"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(NodeQuery.label_texts(phone).has("Daily cost: £65 · Raid risk: %d%% · Rooms 0/3" % raid_pct), "owned townhouse shows utilities (65)")
		phone.free()

		GameState.state["home"]["tenure"] = "rented"
		phone = PhoneScreen.new()
		phone._ready()
		assert_true(NodeQuery.label_texts(phone).has("Daily cost: £150 · Raid risk: %d%% · Rooms 0/3" % raid_pct), "rented townhouse shows rent (150)")
		phone.free()
	)

	run_case("property_shows_the_next_tier_up_with_rent_and_buy_offers", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Flat"), "next tier's name (flat, the tier above bedsit) renders")
		var raid_pct: int = int(round(Home.get_raid_chance_for_tier("flat") * 100))
		assert_true(texts.has("Raid risk: %d%% · Rooms 1" % raid_pct), "next tier's own stats line")
		assert_true(NodeQuery.find_button(phone, "Rent for £80/day") != null, "rent offer previews flat's rent")
		assert_true(NodeQuery.find_button(phone, "Buy for £200000") != null, "buy offer shows flat's buyPrice")
		assert_true(texts.has("Then £58/day in utilities."), "buy offer previews flat's owned bill")
		assert_true(texts.has("Moving clears every installed room. No refunds."))

		phone.free()
	)

	run_case("property_flat_listing_shows_a_static_floorplan_with_no_room_controls", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()

		var plans := phone.find_children("*", "TextureRect", true, false).filter(func(t): return t.texture == load("res://assets/floorplans/flat.svg"))
		assert_eq(plans.size(), 1, "the Flat listing (next tier from bedsit) shows its plan")
		assert_eq(phone.find_child(FloorplanView.slot_node_name(0), true, false), null, "the listing plan is static: no selectable slot")
		for room_id in GameData.HOME_ROOMS.keys():
			assert_true(NodeQuery.find_button(phone, "£%d" % GameData.HOME_ROOMS[room_id]["cost"]) == null, "Harrow's sells no room upgrades (%s)" % room_id)

		phone.free()
	)

	run_case("property_buy_is_disabled_without_cash_and_rent_calls_rent_up", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()
		var buy_button := NodeQuery.find_button(phone, "Buy for £200000")
		assert_true(buy_button.disabled, "buy disabled without enough cash")
		assert_true(NodeQuery.label_texts(phone).has("Not enough cash."))
		var rent_button := NodeQuery.find_button(phone, "Rent for £80/day")
		assert_true(not rent_button.disabled, "renting needs no cash up front")
		rent_button.pressed.emit()
		assert_eq(GameState.state["home"]["tier"], "flat")
		assert_eq(GameState.state["home"]["tenure"], "rented")
		phone.free()

		GameState.reset()
		GameState.state["player"]["cash"] = 200000
		GameState.state["phoneNav"]["app"] = "property"
		phone = PhoneScreen.new()
		phone._ready()
		NodeQuery.find_button(phone, "Buy for £200000").pressed.emit()
		assert_eq(GameState.state["home"]["tenure"], "owned", "buy button calls Home.buy_up")
		phone.free()
	)

	run_case("property_offers_buy_out_only_on_a_rented_buyable_tier", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_eq(NodeQuery.find_button(phone, "Buy out for £0"), null, "no buy-out at the bedsit")
		phone.free()

		GameState.state["home"]["tier"] = "flat"
		GameState.state["player"]["cash"] = 200000
		phone = PhoneScreen.new()
		phone._ready()
		assert_true(NodeQuery.label_texts(phone).has("Then £58/day in utilities. Rooms stay."))
		NodeQuery.find_button(phone, "Buy out for £200000").pressed.emit()
		assert_eq(GameState.state["home"]["tenure"], "owned")
		assert_eq(GameState.state["home"]["tier"], "flat")
		phone.free()

		phone = PhoneScreen.new()
		phone._ready()
		assert_eq(NodeQuery.find_button(phone, "Buy out for £200000"), null, "gone once owned")
		assert_true(NodeQuery.label_texts(phone).has("Owned outright."))
		phone.free()
	)

	run_case("property_move_down_offers_rent_only_to_the_bedsit_and_lists_lost_security", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(not NodeQuery.label_texts(phone).has("MOVE DOWN"), "no move-down card at the bedsit")
		phone.free()

		GameState.state["home"]["tier"] = "flat"
		GameState.state["home"]["security"] = ["lock", "cameras"]
		phone = PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("MOVE DOWN"))
		assert_true(texts.has("Left behind: CCTV."))
		assert_eq(NodeQuery.find_button(phone, "Buy for £0"), null, "the bedsit can't be bought")
		NodeQuery.find_button(phone, "Rent for £50/day").pressed.emit()
		assert_eq(GameState.state["home"]["tier"], "bedsit")
		assert_eq(GameState.state["home"]["security"], ["lock"])
		phone.free()
	)

	run_case("property_shows_a_max_tier_message_and_no_upgrade_button_at_the_top_tier", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "mansion"
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(NodeQuery.label_texts(phone).has("Top of the ladder. Nowhere further to move."), "max-tier message renders")
		assert_true(NodeQuery.find_button(phone, "Rent for £1500/day") == null, "no mansion rent offer at the top tier")

		phone.free()
	)

	run_case("property_is_reachable_from_the_app_grid_via_the_harrows_tile", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var property_tile: AppTile = null
		for t in phone.find_children("", "AppTile", true, false):
			if (t as AppTile)._app_id == "property":
				property_tile = t
		assert_true(property_tile != null, "the app grid must include a Harrow's tile")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		property_tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "property", "tapping the tile opens the property app via PhoneNav")

		phone.free()
	)
