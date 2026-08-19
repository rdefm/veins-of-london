extends "res://tests/test_base.gd"

# bugfixes-29: same headless-scene pattern as tests/test_hq_screen.gd --
# GuildMarketplaceScreen.new() then _ready(), no live tree needed.


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


static func _find_button_starting_with(root: Node, prefix: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text.begins_with(prefix):
			return b
	return null


func run() -> void:
	run_case("guild_marketplace_shows_locked_state_for_non_members", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = false

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		assert_true(_find_button(screen, "‹ Back") != null, "back button must still render when locked")
		assert_true(_find_button_starting_with(screen, "Buy 1") == null, "no buy buttons for a non-member")
		assert_true(_find_button_starting_with(screen, "Sell 1") == null, "no sell buttons for a non-member")

		screen.free()
	)

	run_case("guild_marketplace_shows_trading_ui_for_members", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		assert_true(_find_button_starting_with(screen, "Buy 1") != null, "buy buttons render for a member")
		assert_true(_find_button_starting_with(screen, "Sell 1") != null, "sell buttons render for a member")

		screen.free()
	)

	run_case("guild_marketplace_consumables_stay_behind_the_same_tutorial_gate_as_the_sell_menu", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["flags"]["canSellConsumables"] = false

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		# timePearl basePrice 120, full 15% spread -> buy 138 (same
		# round_epsilon(120*1.15) math as the ore case's 69).
		assert_true(_find_button(screen, "Buy 1 (£69)") != null, "ore is still tradeable regardless of the consumables gate")
		assert_true(_find_button(screen, "Buy 1 (£138)") == null, "consumables must not appear before flags.canSellConsumables is true")

		GameState.state["flags"]["canSellConsumables"] = true
		screen._refresh()

		assert_true(_find_button(screen, "Buy 1 (£138)") != null, "consumables appear once the tutorial gate is open")

		screen.free()
	)

	run_case("guild_marketplace_price_labels_match_economy_formula", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40  # full 15% spread

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		# time basePrice 60, stable barometer, full spread -> buy 69 / sell 51
		# (same figures tests/test_economy.gd's guild price tests assert).
		var buy_button := _find_button(screen, "Buy 1 (£69)")
		var sell_button := _find_button(screen, "Sell 1 (£51)")
		assert_true(buy_button != null, "buy price label must reflect Economy.get_guild_buy_price()")
		assert_true(sell_button != null, "sell price label must reflect Economy.get_guild_sell_price()")

		screen.free()
	)

	run_case("guild_marketplace_buy_button_updates_cash_and_inventory", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 1000

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		var buy_button := _find_button(screen, "Buy 1 (£69)")
		assert_true(buy_button != null, "sanity: time's buy button must exist")
		buy_button.pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 1000 - 69, "cash reduced by the buy price")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 1, "ore added to inventory")

		screen.free()
	)

	run_case("guild_marketplace_sell_button_updates_cash_and_inventory", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 100
		GameState.state["player"]["orichalchum"]["time"] = 5

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		var sell_button := _find_button(screen, "Sell 1 (£51)")
		assert_true(sell_button != null, "sanity: time's sell button must exist")
		sell_button.pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 100 + 51, "cash increased by the sell price")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 4, "ore removed from inventory")

		screen.free()
	)

	run_case("guild_marketplace_buy_button_disabled_when_cash_cant_cover_it", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 0

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		var buy_button := _find_button(screen, "Buy 1 (£69)")
		assert_true(buy_button != null, "sanity: time's buy button must exist")
		assert_true(buy_button.disabled, "buy must be disabled when cash can't cover the price")

		screen.free()
	)

	run_case("guild_marketplace_sell_button_disabled_with_nothing_held", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		var sell_button := _find_button(screen, "Sell 1 (£51)")
		assert_true(sell_button != null, "sanity: time's sell button must exist")
		assert_true(sell_button.disabled, "sell must be disabled with none held")

		screen.free()
	)

	run_case("guild_marketplace_back_button_routes_to_phone_home", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		PhoneNav.open_app("factions")

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		var back_button := _find_button(screen, "‹ Back")
		assert_true(back_button != null, "screen must render a generic back button")
		back_button.pressed.emit()

		assert_eq(GameState.state["currentScreen"], "phone", "back routes to the phone app grid")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "should land on the grid itself, not the last-open app")

		screen.free()
	)
