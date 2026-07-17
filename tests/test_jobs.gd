extends "res://tests/test_base.gd"


func run() -> void:
	run_case("job_qty_bands_by_trust", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["relation"] = 1
		for seed in range(50):
			Rng.set_seed(seed)
			var job := Jobs.generate_james_job()
			assert_true(job["qty"] >= 1 and job["qty"] <= 3, "trust <= 1 should be qty 1-3, got %d" % job["qty"])

		GameState.state["contacts"]["james"]["relation"] = 3
		for seed in range(50):
			Rng.set_seed(seed)
			var job := Jobs.generate_james_job()
			assert_true(job["qty"] >= 3 and job["qty"] <= 6, "trust <= 3 should be qty 3-6, got %d" % job["qty"])

		GameState.state["contacts"]["james"]["relation"] = 4
		for seed in range(50):
			Rng.set_seed(seed)
			var job := Jobs.generate_james_job()
			assert_true(job["qty"] >= 5 and job["qty"] <= 10, "trust >= 4 should be qty 5-10, got %d" % job["qty"])
	)

	run_case("recipe_pool_excludes_enhancementPowder_until_unlocked", func():
		GameState.reset()
		GameState.state["flags"]["enhancementUnlocked"] = false
		for seed in range(50):
			Rng.set_seed(seed)
			var job := Jobs.generate_james_job()
			assert_eq(job["recipeKey"], "timePearl", "only timePearl should be offered before enhancementUnlocked")

		GameState.state["flags"]["enhancementUnlocked"] = true
		var seen_enhancement := false
		for seed in range(50):
			Rng.set_seed(seed)
			var job := Jobs.generate_james_job()
			if job["recipeKey"] == "enhancementPowder":
				seen_enhancement = true
		assert_true(seen_enhancement, "enhancementPowder should appear in the pool once unlocked")
	)

	run_case("pay_per_item_matches_consumable_prices", func():
		GameState.reset()
		Rng.set_seed(1)
		var job := Jobs.generate_james_job()
		assert_eq(job["payPerItem"], GameData.CONSUMABLE_PRICES[job["recipeKey"]], "payPerItem should come straight from CONSUMABLE_PRICES")
		assert_eq(job["totalPay"], job["payPerItem"] * job["qty"], "totalPay = payPerItem * qty")
	)

	run_case("offer_job_blocked_while_one_is_already_active", func():
		GameState.reset()
		Jobs.offer_job()
		var second := Jobs.offer_job()
		assert_true(not second["ok"], "should refuse a second offer while one is active")
	)

	run_case("accept_job_notifies_with_qty_and_pay", func():
		GameState.reset()
		Jobs.offer_job()
		Jobs.accept_job()
		var job = GameState.state["jamesJob"]
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("James wants %d" % job["qty"]) and n["text"].contains("£%d" % job["totalPay"]):
				found = true
		assert_true(found, "accept should notify with the qty and total pay")
	)

	run_case("fulfil_job_deducts_pays_and_clears", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["relation"] = 5  # push qty band up predictably enough for the test
		Rng.set_seed(1)
		Jobs.offer_job()
		var job = GameState.state["jamesJob"]
		GameState.state["player"]["inventory"][job["recipeKey"]] = job["qty"] + 10
		var cash_before: int = GameState.state["player"]["cash"]
		var relation_before: int = GameState.state["contacts"]["james"]["relation"]

		var result := Jobs.fulfil_job()

		assert_true(result["ok"], "should succeed with enough inventory")
		assert_eq(GameState.state["player"]["inventory"][job["recipeKey"]], 10, "qty deducted, 10 remain")
		assert_eq(GameState.state["player"]["cash"], cash_before + job["totalPay"], "cash increases by totalPay")
		assert_eq(GameState.state["contacts"]["james"]["relation"], relation_before + 5, "james relation +5")
		assert_eq(GameState.state["jamesJob"], null, "job cleared")
		assert_eq(GameState.state["flags"]["jamesJobActive"], false, "jobActive flag cleared")
	)

	run_case("fulfil_job_fails_with_insufficient_inventory", func():
		GameState.reset()
		Jobs.offer_job()
		var job = GameState.state["jamesJob"]
		GameState.state["player"]["inventory"][job["recipeKey"]] = 0

		var result := Jobs.fulfil_job()

		assert_true(not result["ok"], "should fail without enough inventory")
		assert_eq(result["have"], 0, "reports how many the player actually has")
		assert_eq(result["need"], job["qty"], "reports how many are needed")
		assert_true(GameState.state["jamesJob"] != null, "an unfulfilled job should stay active")
	)

	run_case("fulfil_job_fails_with_no_active_job", func():
		GameState.reset()
		var result := Jobs.fulfil_job()
		assert_true(not result["ok"], "no job active -> nothing to fulfil")
	)
