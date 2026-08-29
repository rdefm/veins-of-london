extends "res://tests/test_base.gd"

# 01-debug-app: DebugTools' two adjusters, tested standalone against
# GameState.state -- same "system function mutates state, screen never
# touches it directly" contract as every other systems/*.gd file.


func run() -> void:
	run_case("add_cash_adds_the_given_amount_to_player_cash", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100

		DebugTools.add_cash(250)

		assert_eq(GameState.state["player"]["cash"], 350, "cash increases by the given amount")
	)

	run_case("add_cash_can_take_a_negative_amount", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100

		DebugTools.add_cash(-40)

		assert_eq(GameState.state["player"]["cash"], 60, "cash decreases when given a negative amount")
	)

	run_case("add_calc_adds_the_given_amount_to_the_chosen_ore_type", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["physics"] = 5

		DebugTools.add_calc("physics", 30)

		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 35, "physics ore increases by the given amount")

		for ore_type in GameData.ORE_TYPES.keys():
			if ore_type != "physics":
				assert_eq(GameState.state["player"]["orichalchum"].get(ore_type, 0), 0, "no other ore type is touched (%s)" % ore_type)
	)

	run_case("add_calc_works_from_an_unseeded_ore_type", func():
		GameState.reset()
		assert_eq(GameState.state["player"]["orichalchum"].get("time", 0), 0, "sanity: player.orichalchum starts empty")

		DebugTools.add_calc("time", 12)

		assert_eq(GameState.state["player"]["orichalchum"]["time"], 12, "adding to a never-seeded ore type starts from 0, not an error")
	)
