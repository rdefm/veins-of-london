extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# 03-property-app-phone-tab: Harrow's -- HQ tier stats and the upgrade
# action, relocated off the HQ tab (docs/hq-diorama-vision.md §7). Same
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

	run_case("property_shows_the_next_tier_up_with_its_own_stats_and_upgrade_cost", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Flat"), "next tier's name (flat, the tier above bedsit) renders")
		var raid_pct: int = int(round(Home.get_raid_chance_for_tier("flat") * 100))
		var expected: String = "Daily cost: £80 · Raid risk: %d%% · Rooms 1" % raid_pct
		assert_true(texts.has(expected), "next tier's own stats line renders, not the current tier's")
		assert_true(NodeQuery.find_button(phone, "Move for £1200") != null, "upgrade action shows flat's upgradeCost")

		phone.free()
	)

	run_case("property_upgrade_button_is_disabled_without_enough_cash_and_calls_upgrade_tier_when_enabled", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		GameState.state["phoneNav"]["app"] = "property"

		var poor_phone := PhoneScreen.new()
		poor_phone._ready()
		var poor_button := NodeQuery.find_button(poor_phone, "Move for £1200")
		assert_true(poor_button != null, "upgrade button still renders when unaffordable")
		assert_true(poor_button.disabled, "upgrade button is disabled without enough cash")
		assert_true(NodeQuery.label_texts(poor_phone).has("Not enough cash."), "shows the reason it's disabled")
		poor_phone.free()

		GameState.state["player"]["cash"] = 5000
		var rich_phone := PhoneScreen.new()
		rich_phone._ready()
		var rich_button := NodeQuery.find_button(rich_phone, "Move for £1200")
		assert_true(not rich_button.disabled, "upgrade button is enabled with enough cash")
		rich_button.pressed.emit()
		assert_eq(GameState.state["home"]["tier"], "flat", "pressing the button calls Home.upgrade_tier() unchanged")
		rich_phone.free()
	)

	run_case("property_shows_a_max_tier_message_and_no_upgrade_button_at_the_top_tier", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "mansion"
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(NodeQuery.label_texts(phone).has("Top of the ladder. Nowhere further to move."), "max-tier message renders")
		assert_true(NodeQuery.find_button(phone, "Move for £150000") == null, "no upgrade button at the top tier")

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
