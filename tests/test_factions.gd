extends "res://tests/test_base.gd"


func run() -> void:
	run_case("can_join_requires_relation_and_not_already_joined", func():
		GameState.reset()
		assert_true(not Factions.can_join("guild"), "relation 0 < joinRelation 40")

		GameState.state["factions"]["guild"]["relation"] = 40
		assert_true(Factions.can_join("guild"), "relation meets joinRelation")

		GameState.state["factions"]["guild"]["joined"] = true
		assert_true(not Factions.can_join("guild"), "already joined")
	)

	run_case("join_sets_joined_true", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 20
		var result := Factions.join("collective")
		assert_true(result["ok"], "collective joinRelation is 20")
		assert_eq(GameState.state["factions"]["collective"]["joined"], true, "joined flag set")
	)

	run_case("join_fails_when_not_eligible", func():
		GameState.reset()
		var result := Factions.join("conclave")
		assert_true(not result["ok"], "relation 0 < conclave's joinRelation 60")
	)
