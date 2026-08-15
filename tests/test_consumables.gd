extends "res://tests/test_base.gd"

# calc-effect-wiring-02: Consumables.use_healing_salve()/use_healing_burst().


func run() -> void:
	run_case("use_healing_salve_sets_days_left_and_daily_amount_from_effect_power", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["healingSalve"] = 2
		GameState.state["player"]["craftingSkill"] = 1
		var result := Consumables.use_healing_salve()
		assert_true(result["ok"], "should succeed with a salve in hand")
		# healingSalve effectPower at skill 1 = 3
		assert_eq(GameState.state["player"]["healingSalveDaysLeft"], 2, "activates a 2-day timer")
		assert_eq(GameState.state["player"]["healingSalveDailyAmount"], 3, "daily amount from effectPower")
		assert_eq(GameState.state["player"]["inventory"]["healingSalve"], 1, "one salve consumed")
	)

	run_case("use_healing_salve_refreshes_rather_than_stacks", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["healingSalve"] = 2
		GameState.state["player"]["craftingSkill"] = 1
		Consumables.use_healing_salve()
		GameState.state["player"]["healingSalveDaysLeft"] = 1  # simulate a day having passed
		GameState.state["player"]["craftingSkill"] = 5
		Consumables.use_healing_salve()
		# healingSalve effectPower at skill 5 = 8
		assert_eq(GameState.state["player"]["healingSalveDaysLeft"], 2, "reusing refreshes back to 2 days, not 3")
		assert_eq(GameState.state["player"]["healingSalveDailyAmount"], 8, "daily amount updates to the new activation's power")
	)

	run_case("use_healing_salve_fails_with_none_in_inventory", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["healingSalve"] = 0
		var result := Consumables.use_healing_salve()
		assert_true(not result["ok"], "should fail with no salve")
		assert_eq(GameState.state["player"]["healingSalveDaysLeft"], 0, "no timer should start")
	)

	run_case("use_healing_burst_heals_instantly_and_caps_at_hpMax", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["healingBurst"] = 2
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["hp"] = 95
		GameState.state["player"]["hpMax"] = 100
		var result := Consumables.use_healing_burst()
		assert_true(result["ok"], "should succeed with a burst in hand")
		# healingBurst effectPower at skill 1 = 8, but hp caps at hpMax
		assert_eq(GameState.state["player"]["hp"], 100, "heal caps at hpMax, not 95+8=103")
		assert_eq(GameState.state["player"]["inventory"]["healingBurst"], 1, "one burst consumed")
	)

	run_case("use_healing_burst_fails_with_none_in_inventory", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["healingBurst"] = 0
		var result := Consumables.use_healing_burst()
		assert_true(not result["ok"], "should fail with no burst")
	)

	run_case("use_healing_burst_logs_to_combat_when_a_fight_is_active", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["healingBurst"] = 1
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100
		GameState.state["combat"]["active"] = true
		Consumables.use_healing_burst()
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("healing burst"):
				found = true
		assert_true(found, "an active fight should get the result line in the combat log")
		assert_eq(GameState.state["notifications"].size(), 0, "no separate notification while in combat")
	)

	run_case("use_healing_burst_notifies_when_no_fight_is_active", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["healingBurst"] = 1
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100
		Consumables.use_healing_burst()
		assert_eq(GameState.state["combat"]["log"], [], "no active fight, nothing to log there")
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("healing burst"):
				found = true
		assert_true(found, "outside combat should push a notification instead")
	)
