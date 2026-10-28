extends "res://tests/test_base.gd"


func run() -> void:
	run_case("soul_seed_chance_bonus_by_level", func():
		GameState.reset()
		var expect := { 1: 0.0, 2: 0.03, 3: 0.03, 4: 0.06, 5: 0.06 }
		for level in expect:
			GameState.state["player"]["soulSkill"] = level
			assert_almost_eq(Soul.seed_chance_bonus(), expect[level], 0.0001, "L%d" % level)
		GameState.state["player"]["soulSkill"] = 4
		var base: float = Cultivating.get_cult_chance(1) + GameData.SITE_SEED_TIER_MOD.get("rich", 0.0) + GameData.SITE_LADY_SEED_BONUS_PER_LEVEL * ActiveEffects.lady_level()
		assert_almost_eq(Sites.seed_success_chance(1, "rich"), clampf(base + 0.06, 0.05, 0.95), 0.0001)
	)

	run_case("soul_cultivate_gain_bonus_shifts_player_range_only", func():
		GameState.reset()
		var expect := { 1: 0, 2: 1, 3: 1, 4: 2, 5: 2 }
		for level in expect:
			GameState.state["player"]["soulSkill"] = level
			assert_eq(Soul.cultivate_gain_bonus(), expect[level], "L%d" % level)
		GameState.state["player"]["soulSkill"] = 4
		var skill := 1
		assert_eq(Cultivating.cultivate_gain(skill, 0, 100, 0.0, true), Cultivating.cultivate_max_gain(skill), "contacts unchanged")
		assert_eq(Cultivating.cultivate_gain(skill, 0, 100, 0.0, true, 2), Cultivating.cultivate_max_gain(skill) + 2)
		assert_eq(Cultivating.cultivate_gain(skill, 99, 100, 0.0, true, 2), 1, "headroom clamp after bonus")
		var plain := "+%d–%d" % [Cultivating.cultivate_min_gain(skill), Cultivating.cultivate_max_gain(skill)]
		assert_true(Cultivating.player_cultivate_gain_text(skill) != plain or ActiveEffects.lady_active(), "preview shows bonus")
		assert_eq(Cultivating.player_cultivate_gain_text(skill), "+%d–%d" % [Cultivating.cultivate_min_gain(skill) + 2, Cultivating.cultivate_max_gain(skill) + 2])
	)

	run_case("soul_dial_xp_mult_and_cast", func():
		GameState.reset()
		var expect := { 1: 1.0, 2: 1.1, 3: 1.1 * 1.15, 4: 1.2 * 1.15, 5: 1.2 * 1.35 }
		for level in expect:
			GameState.state["player"]["soulSkill"] = level
			assert_almost_eq(Soul.dial_xp_mult(), expect[level], 0.0001, "L%d" % level)
	)

	run_case("soul_level_xp_bonus_on_movement_craft_not_mind", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["mindSkill"] = 5
		player["soulSkill"] = 5
		assert_almost_eq(Mind.craft_xp_mult(false), 1.2, 0.0001, "Mind L3/L5 left out")
		assert_almost_eq(Mind.craft_xp_mult(), 1.2 * 1.25, 0.0001, "Mind L5 on lab craft")
		var before: int = int(player["craftingXP"])
		Crafting.award_crafting_xp(100, true)
		assert_eq(int(player["craftingXP"]) - before, int(round(100.0 * 1.2 * 1.35)))
	)

	run_case("soul_feat_texts_projected", func():
		GameState.reset()
		var soul: Dictionary = {}
		for row in SkillTree.project():
			if row["id"] == "soul":
				soul = row
		assert_eq(soul["feats"][0]["text"], "+3% Seed chance, +1 cultivate gain, +10% Dial XP")
		assert_eq(soul["feats"][1]["text"], "Seed chance bonus becomes +6%, cultivate gain +2, Dial XP +20%")
		assert_eq(soul["feats"][2]["text"], "Soul actions have a 25% chance to cost no time block; Dial and Movement craft XP +15%")
		assert_eq(soul["feats"][3]["text"], "The first Soul action each time block costs no time block; Dial and Movement craft XP bonus becomes +35%")
		var cultivating: Dictionary = {}
		for sub in soul["subSkills"]:
			if sub["id"] == "cultivating":
				cultivating = sub
		assert_eq(cultivating["feats"][0]["text"], "+12% Seed chance")
	)
