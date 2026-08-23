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


static func _find_label(root: Node, text: String) -> Label:
	for l in root.find_children("", "Label", true, false):
		if (l as Label).text == text:
			return l
	return null


# Ticket 66: same card-scoping trick as tests/test_lab_screen.gd's
# _find_button_in_card -- finds the goods row's heading Label, then
# searches its content VBoxContainer (the heading's parent) recursively so
# nested rows (the qty stepper's own hbox, the buy/sell hbox) are covered
# too, unlike a direct-sibling-only search.
static func _find_button_in_card(root: Node, heading_text: String, button_text: String) -> Button:
	for l in root.find_children("", "Label", true, false):
		if (l as Label).text == heading_text:
			for b in l.get_parent().find_children("", "Button", true, false):
				if (b as Button).text == button_text:
					return b
	return null


# Same card-scoping as _find_button_in_card, but for the qty stepper's own
# numeric Label (not a Button) -- used to read back the stepper's current
# value.
static func _find_label_in_card(root: Node, heading_text: String, label_text: String) -> Label:
	for l in root.find_children("", "Label", true, false):
		if (l as Label).text == heading_text:
			for sub in l.get_parent().find_children("", "Label", true, false):
				if (sub as Label).text == label_text:
					return sub
	return null


const TIME_HEADING := "⧖ Time Orichalchum"


func run() -> void:
	run_case("guild_marketplace_shows_locked_state_for_non_members", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = false

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		assert_true(_find_button(screen, "‹ Back") != null, "back button must still render when locked")
		assert_true(_find_button_starting_with(screen, "Buy ×") == null, "no buy buttons for a non-member")
		assert_true(_find_button_starting_with(screen, "Sell ×") == null, "no sell buttons for a non-member")

		screen.free()
	)

	run_case("guild_marketplace_shows_trading_ui_for_members", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		assert_true(_find_button_starting_with(screen, "Buy ×1") != null, "buy buttons render for a member")
		assert_true(_find_button_starting_with(screen, "Sell ×1") != null, "sell buttons render for a member")

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
		assert_true(_find_button(screen, "Buy ×1 (£69)") != null, "ore is still tradeable regardless of the consumables gate")
		assert_true(_find_button(screen, "Buy ×1 (£138)") == null, "consumables must not appear before flags.canSellConsumables is true")

		GameState.state["flags"]["canSellConsumables"] = true
		screen._refresh()

		assert_true(_find_button(screen, "Buy ×1 (£138)") != null, "consumables appear once the tutorial gate is open")

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
		var buy_button := _find_button(screen, "Buy ×1 (£69)")
		var sell_button := _find_button(screen, "Sell ×1 (£51)")
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

		var buy_button := _find_button(screen, "Buy ×1 (£69)")
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

		var sell_button := _find_button(screen, "Sell ×1 (£51)")
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

		var buy_button := _find_button(screen, "Buy ×1 (£69)")
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

		var sell_button := _find_button(screen, "Sell ×1 (£51)")
		assert_true(sell_button != null, "sanity: time's sell button must exist")
		assert_true(sell_button.disabled, "sell must be disabled with none held")

		screen.free()
	)

	# bugfixes-66: the qty stepper, ticket acceptance checks.
	run_case("guild_marketplace_qty_stepper_starts_at_one", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		assert_true(_find_label_in_card(screen, TIME_HEADING, "1") != null, "qty label starts at 1")
		assert_true(_find_button(screen, "Buy ×1 (£69)") != null, "buy button starts phrased for qty 1")
		assert_true(_find_button(screen, "Sell ×1 (£51)") != null, "sell button starts phrased for qty 1")

		screen.free()
	)

	run_case("guild_marketplace_qty_stepper_increments_and_updates_buy_sell_totals", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 1000
		GameState.state["player"]["orichalchum"]["time"] = 10

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		_find_button_in_card(screen, TIME_HEADING, "+").pressed.emit()
		_find_button_in_card(screen, TIME_HEADING, "+").pressed.emit()
		_find_button_in_card(screen, TIME_HEADING, "+").pressed.emit()

		# time buy £69/u, sell £51/u (same figures as the ×1 tests above) --
		# ×3 -> buy £207, sell £153.
		assert_true(_find_label_in_card(screen, TIME_HEADING, "3") != null, "qty label reflects 3 taps of +")
		assert_true(_find_button(screen, "Buy ×3 (£207)") != null, "buy button reflects qty and total")
		assert_true(_find_button(screen, "Sell ×3 (£153)") != null, "sell button reflects qty and total")

		screen.free()
	)

	run_case("guild_marketplace_qty_stepper_cannot_go_below_one", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		_find_button_in_card(screen, TIME_HEADING, "-").pressed.emit()
		_find_button_in_card(screen, TIME_HEADING, "-").pressed.emit()

		assert_true(_find_label_in_card(screen, TIME_HEADING, "1") != null, "qty stays at 1, doesn't go below")

		screen.free()
	)

	run_case("guild_marketplace_qty_stepper_clamps_buy_side_at_affordability", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40
		# buy £69/u, cash 150 -> affordable ceiling is 2 (2*69=138 <= 150,
		# 3*69=207 > 150). No stock held, so the stepper's own max is 2.
		GameState.state["player"]["cash"] = 150

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		for i in range(5):
			_find_button_in_card(screen, TIME_HEADING, "+").pressed.emit()

		assert_true(_find_label_in_card(screen, TIME_HEADING, "2") != null, "qty stops climbing at the affordability ceiling")
		var buy_button := _find_button(screen, "Buy ×2 (£138)")
		assert_true(buy_button != null, "buy button reflects the clamped qty")
		assert_true(not buy_button.disabled, "qty 2 is exactly what's affordable, so buy stays enabled")

		screen.free()
	)

	run_case("guild_marketplace_qty_stepper_clamps_sell_side_at_stock", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 0
		GameState.state["player"]["orichalchum"]["time"] = 2

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		for i in range(5):
			_find_button_in_card(screen, TIME_HEADING, "+").pressed.emit()

		assert_true(_find_label_in_card(screen, TIME_HEADING, "2") != null, "qty stops climbing at the stock ceiling")
		var sell_button := _find_button(screen, "Sell ×2 (£102)")
		assert_true(sell_button != null, "sell button reflects the clamped qty")
		assert_true(not sell_button.disabled, "qty 2 is exactly what's held, so sell stays enabled")

		screen.free()
	)

	run_case("guild_marketplace_buy_disables_past_affordability_even_while_sell_side_allows_higher_qty", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40
		# buy £69/u, cash 100 -> affordable ceiling is 1. Stock 5 lets the
		# shared stepper climb past that, since its own max is the larger of
		# the two ceilings (5).
		GameState.state["player"]["cash"] = 100
		GameState.state["player"]["orichalchum"]["time"] = 5

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		for i in range(3):
			_find_button_in_card(screen, TIME_HEADING, "+").pressed.emit()

		assert_true(_find_label_in_card(screen, TIME_HEADING, "4") != null, "qty climbed to 4, past the buy ceiling")
		var buy_button := _find_button(screen, "Buy ×4 (£276)")
		assert_true(buy_button != null and buy_button.disabled, "buy disables once qty exceeds what's affordable")
		var sell_button := _find_button(screen, "Sell ×4 (£204)")
		assert_true(sell_button != null and not sell_button.disabled, "sell stays enabled since qty 4 is within stock")

		screen.free()
	)

	# Regression: selling can shrink the row's ceiling out from under a
	# stepper value picked before the sale, without the player touching the
	# stepper itself. The very next "-" tap must still move the displayed
	# number, not silently re-clamp to the same value it's already showing.
	run_case("guild_marketplace_qty_stepper_responds_immediately_after_a_sale_shrinks_the_ceiling", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 100
		GameState.state["player"]["orichalchum"]["time"] = 10

		var screen := GuildMarketplaceScreen.new()
		screen._ready()

		for i in range(9):
			_find_button_in_card(screen, TIME_HEADING, "+").pressed.emit()
		assert_true(_find_label_in_card(screen, TIME_HEADING, "10") != null, "qty stepper reaches the stock ceiling (10)")

		_find_button(screen, "Sell ×10 (£510)").pressed.emit()
		# cash 100 + 510 = 610, stock now 0 -> buy ceiling floor(610/69) = 8,
		# sell ceiling 0 -> stepper display re-clamps the still-10 stored qty
		# down to 8 for this render.
		assert_true(_find_label_in_card(screen, TIME_HEADING, "8") != null, "display re-clamps to the new ceiling right after the sale")

		_find_button_in_card(screen, TIME_HEADING, "-").pressed.emit()
		assert_true(_find_label_in_card(screen, TIME_HEADING, "7") != null, "a single '-' tap must move the number, not re-clamp to the same 8 it's already showing")

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
