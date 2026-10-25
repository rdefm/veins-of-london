extends "res://tests/test_base.gd"


func run() -> void:
	run_case("sense_xp_levels_the_skill_at_exactly_80", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		assert_eq(player["senseSkill"], 1, "new game starts at Sense 1")
		assert_eq(player["senseXP"], 0, "new game starts at 0 Sense XP")

		Sense.award_xp(79)
		assert_eq(player["senseSkill"], 1, "79 XP should not yet level up")
		Sense.award_xp(1)
		assert_eq(player["senseSkill"], 2, "should level up at exactly 80 XP")
	)

	run_case("sense_curve_reaches_level_10", func():
		GameState.reset()
		assert_eq(GameData.SENSE_XP_LEVELS.size(), 11, "curve has levels 0..10")
		Sense.award_xp(int(GameData.SENSE_XP_LEVELS[10]))
		assert_eq(GameState.state["player"]["senseSkill"], 10, "enough XP reaches level 10")
		Sense.award_xp(100000)
		assert_eq(GameState.state["player"]["senseSkill"], 10, "level 10 is the cap")
	)

	run_case("sense_level_up_notifies", func():
		GameState.reset()
		var before: int = GameState.state["notifications"].size()
		Sense.award_xp(80)
		var after: int = GameState.state["notifications"].size()
		assert_true(after > before, "level-up pushes a notification")
	)
