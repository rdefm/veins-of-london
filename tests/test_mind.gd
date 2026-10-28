extends "res://tests/test_base.gd"


func run() -> void:
	run_case("study_awards_ten_xp_and_spends_a_block_without_library", func():
		GameState.reset()
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Mind.study()
		assert_true(result["ok"], "Study should succeed")
		assert_eq(GameState.state["player"]["mindXP"], 10, "10 Mind XP without a Library")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before + 1, "one block spent")
	)

	run_case("study_awards_thirty_xp_with_library", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("library")
		Mind.study()
		assert_eq(GameState.state["player"]["mindXP"], 30, "30 Mind XP with a Library")
	)

	run_case("study_refused_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = GameData.TIME_BLOCKS.duplicate()
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Mind.study()
		assert_true(not result["ok"], "refused")
		assert_eq(GameState.state["player"]["mindXP"], 0, "no XP")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before, "no block spent")
	)

	run_case("mind_observation_mod_by_level_is_labelled_total", func():
		GameState.reset()
		var expect := { 1: 0.0, 2: 0.03, 3: 0.03, 4: 0.06, 5: 0.06 }
		for level in expect:
			GameState.state["player"]["mindSkill"] = level
			var mods: Array = Observation._mods({}, "time").filter(func(m): return m["label"] == "Mind")
			if expect[level] == 0.0:
				assert_eq(mods.size(), 0, "L%d: no Mind mod" % level)
			else:
				assert_eq(mods.size(), 1, "L%d: one labelled Mind mod" % level)
				assert_almost_eq(float(mods[0]["delta"]), expect[level], 0.0001, "L%d total" % level)
	)

	run_case("mind_craft_xp_mult_stacks_with_guild", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 0
		var expect := { 1: 20, 2: 22, 3: 24, 4: 26, 5: 30 }
		for level in expect:
			GameState.state["player"]["mindSkill"] = level
			var before: int = GameState.state["player"]["craftingXP"]
			Crafting.award_crafting_xp(20)
			assert_eq(GameState.state["player"]["craftingXP"] - before, expect[level], "L%d crafting XP" % level)
		GameState.state["player"]["mindSkill"] = 4
		GameState.state["factions"]["guild"]["relation"] = 30
		var guild_before: int = GameState.state["player"]["craftingXP"]
		Crafting.award_crafting_xp(20)
		assert_eq(GameState.state["player"]["craftingXP"] - guild_before, 33, "20 x 1.25 x 1.20 x 1.10")
	)

	run_case("mind_feat_texts_project_at_l2_and_l4", func():
		GameState.reset()
		var mind: Dictionary = SkillTree.project()[1]
		assert_eq(mind["id"], "mind")
		assert_eq(mind["feats"][0]["text"], "+3% observation, +10% Crafting XP")
		assert_eq(mind["feats"][1]["text"], "Observation bonus becomes +6%, Crafting XP bonus +20%")
		assert_eq(mind["feats"][2]["text"], "Mind actions have a 25% chance to cost no time block; Crafting XP +10%")
		assert_eq(mind["feats"][3]["text"], "The first Mind action each time block costs no time block; Crafting XP bonus becomes +25%")
	)
