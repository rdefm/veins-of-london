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

	run_case("generate_james_job_sets_byDay_deadline_two_days_per_qty", func():
		GameState.reset()
		GameState.state["world"]["day"] = 7
		Rng.set_seed(1)
		var job := Jobs.generate_james_job()
		assert_eq(job["type"], "craft", "craft job type")
		assert_eq(job["byDay"], 7 + job["qty"] * Jobs.DEADLINE_DAYS_PER_QTY, "byDay = day + qty * DEADLINE_DAYS_PER_QTY")
	)

	run_case("generate_flat_pay_job_shape", func():
		var job := Jobs.generate_flat_pay_job()
		assert_eq(job["type"], "flatPay", "flatPay job type")
		assert_eq(job["pay"], Jobs.FLAT_PAY_AMOUNT, "pay matches FLAT_PAY_AMOUNT")
	)

	run_case("offer_job_is_no_longer_a_player_invocable_method", func():
		var j := Jobs.new()
		assert_true(not j.has_method("offer_job"), "the manual-trigger offer_job() path must be removed, not just unused")
	)

	run_case("roll_daily_offer_always_offers_flat_pay_when_cash_at_or_below_threshold", func():
		for seed in range(10):
			GameState.reset()
			GameState.state["player"]["cash"] = Jobs.FLAT_PAY_LOW_CASH_THRESHOLD
			Rng.set_seed(seed)
			Jobs.roll_daily_offer()
			assert_eq(GameState.state["flags"]["jamesJobActive"], true, "cash <= threshold should always trigger an offer, seed %d" % seed)
			assert_eq(GameState.state["jamesJob"]["type"], "flatPay", "cash <= threshold should always be the flatPay job, seed %d" % seed)
			assert_eq(GameState.state["flags"]["jamesJobAccepted"], false, "a fresh offer is not yet accepted")
	)

	run_case("roll_daily_offer_skips_entirely_when_a_job_is_already_active", func():
		GameState.reset()
		var existing := Jobs.generate_flat_pay_job()
		GameState.state["jamesJob"] = existing
		GameState.state["flags"]["jamesJobActive"] = true
		GameState.state["flags"]["jamesJobAccepted"] = true
		GameState.state["player"]["cash"] = 0  # would force an offer if the guard were missing

		for seed in range(10):
			Rng.set_seed(seed)
			Jobs.roll_daily_offer()

		assert_eq(GameState.state["jamesJob"], existing, "an active job must not be clobbered by a fresh roll")
		assert_eq(GameState.state["flags"]["jamesJobAccepted"], true, "accepted flag untouched while a job is already active")
	)

	run_case("roll_daily_offer_baseline_chance_eventually_offers_something_above_the_cash_threshold", func():
		GameState.reset()
		GameState.state["player"]["cash"] = Jobs.FLAT_PAY_LOW_CASH_THRESHOLD + 1

		var hit := false
		for seed in range(200):
			GameState.reset()
			GameState.state["player"]["cash"] = Jobs.FLAT_PAY_LOW_CASH_THRESHOLD + 1
			Rng.set_seed(seed)
			Jobs.roll_daily_offer()
			if GameState.state["flags"]["jamesJobActive"]:
				hit = true
				break
		assert_true(hit, "an offer should eventually roll within 200 seeds at the baseline chances")
	)

	run_case("decline_job_clears_job_and_active_flags_with_no_relation_change", func():
		GameState.reset()
		GameState.state["jamesJob"] = Jobs.generate_james_job()
		GameState.state["flags"]["jamesJobActive"] = true
		GameState.state["flags"]["jamesJobAccepted"] = false
		var relation_before: int = GameState.state["contacts"]["james"]["relation"]

		Jobs.decline_job()

		assert_eq(GameState.state["jamesJob"], null, "job cleared")
		assert_eq(GameState.state["flags"]["jamesJobActive"], false, "jobActive flag cleared")
		assert_eq(GameState.state["flags"]["jamesJobAccepted"], false, "jobAccepted flag cleared")
		assert_eq(GameState.state["contacts"]["james"]["relation"], relation_before, "declining costs no relation")
	)

	run_case("accept_job_sets_accepted_flag_and_notifies", func():
		GameState.reset()
		var job := Jobs.generate_james_job()
		GameState.state["jamesJob"] = job
		GameState.state["flags"]["jamesJobActive"] = true

		Jobs.accept_job()

		assert_eq(GameState.state["flags"]["jamesJobAccepted"], true, "accepting sets jamesJobAccepted")
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("James wants %d" % job["qty"]) and n["text"].contains("£%d" % job["totalPay"]):
				found = true
		assert_true(found, "accept should notify with the qty and total pay")
	)

	run_case("fulfil_flat_pay_job_consumes_a_time_block_pays_and_awards_relation", func():
		GameState.reset()
		GameState.state["jamesJob"] = Jobs.generate_flat_pay_job()
		GameState.state["flags"]["jamesJobActive"] = true
		GameState.state["flags"]["jamesJobAccepted"] = true
		var cash_before: int = GameState.state["player"]["cash"]
		var relation_before: int = GameState.state["contacts"]["james"]["relation"]
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()

		var result := Jobs.fulfil_job()

		assert_true(result["ok"], "should succeed with a time block available")
		assert_eq(GameState.state["player"]["cash"], cash_before + Jobs.FLAT_PAY_AMOUNT, "cash increases by the flat pay")
		assert_eq(GameState.state["contacts"]["james"]["relation"], relation_before + 5, "james relation +5")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before + 1, "consumes one time block")
		assert_eq(GameState.state["jamesJob"], null, "job cleared")
		assert_eq(GameState.state["flags"]["jamesJobActive"], false, "jobActive flag cleared")
		assert_eq(GameState.state["flags"]["jamesJobAccepted"], false, "jobAccepted flag cleared")
		assert_eq(GameState.state["modal"]["type"], "james_job_complete", "a successful fulfil should open james_job_complete")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "a fulfilled flat-pay job records one bank transaction")
		assert_eq(bank_log[0]["amount"], Jobs.FLAT_PAY_AMOUNT, "the recorded amount matches the flat pay")
		assert_eq(bank_log[0]["label"], "James job", "the recorded label names the job")
	)

	run_case("fulfil_flat_pay_job_fails_when_no_time_blocks_left", func():
		GameState.reset()
		GameState.state["jamesJob"] = Jobs.generate_flat_pay_job()
		GameState.state["flags"]["jamesJobActive"] = true
		GameState.state["flags"]["jamesJobAccepted"] = true
		for i in range(TimeSystem.BLOCKS_PER_DAY):
			GameState.state["world"]["timeBlocksDone"].append(i)
		var cash_before: int = GameState.state["player"]["cash"]

		var result := Jobs.fulfil_job()

		assert_true(not result["ok"], "should fail with no time blocks left")
		assert_eq(GameState.state["player"]["cash"], cash_before, "no pay-out when it fails")
		assert_true(GameState.state["jamesJob"] != null, "job stays active so the player can retry after resting")
	)

	run_case("fulfil_craft_job_deducts_pays_and_clears", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["relation"] = 5  # push qty band up predictably enough for the test
		Rng.set_seed(1)
		var job := Jobs.generate_james_job()
		GameState.state["jamesJob"] = job
		GameState.state["flags"]["jamesJobActive"] = true
		GameState.state["flags"]["jamesJobAccepted"] = true
		Crafting.inventory_add(job["recipeKey"], 1, job["qty"] + 10)
		var cash_before: int = GameState.state["player"]["cash"]
		var relation_before: int = GameState.state["contacts"]["james"]["relation"]

		var result := Jobs.fulfil_job()

		assert_true(result["ok"], "should succeed with enough inventory")
		assert_eq(Crafting.inventory_qty(job["recipeKey"]), 10, "qty deducted, 10 remain")
		assert_eq(GameState.state["player"]["cash"], cash_before + job["totalPay"], "cash increases by totalPay")
		assert_eq(GameState.state["contacts"]["james"]["relation"], relation_before + 5, "james relation +5")
		assert_eq(GameState.state["jamesJob"], null, "job cleared")
		assert_eq(GameState.state["flags"]["jamesJobActive"], false, "jobActive flag cleared")
		assert_eq(GameState.state["flags"]["jamesJobAccepted"], false, "jobAccepted flag cleared")
		assert_eq(GameState.state["modal"]["type"], "james_job_complete", "a successful fulfil should open james_job_complete")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "a fulfilled craft job records one bank transaction")
		assert_eq(bank_log[0]["amount"], job["totalPay"], "the recorded amount matches totalPay")
		assert_eq(bank_log[0]["label"], "James job", "the recorded label names the job")
	)

	run_case("fulfil_craft_job_fails_with_insufficient_inventory", func():
		GameState.reset()
		var job := Jobs.generate_james_job()
		GameState.state["jamesJob"] = job
		GameState.state["flags"]["jamesJobActive"] = true
		GameState.state["flags"]["jamesJobAccepted"] = true
		# no inventory_add call -- recipeKey defaults to zero stock

		var result := Jobs.fulfil_job()

		assert_true(not result["ok"], "should fail without enough inventory")
		assert_eq(result["have"], 0, "reports how many the player actually has")
		assert_eq(result["need"], job["qty"], "reports how many are needed")
		assert_true(GameState.state["jamesJob"] != null, "an unfulfilled job should stay active")
		assert_eq(GameState.state["modal"]["type"], "james_job_short", "insufficient inventory should open james_job_short")
	)

	run_case("fulfil_job_fails_with_no_active_job", func():
		GameState.reset()
		var result := Jobs.fulfil_job()
		assert_true(not result["ok"], "no job active -> nothing to fulfil")
	)

	run_case("expire_overdue_job_clears_and_docks_relation_past_byDay", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		var job := Jobs.generate_james_job()
		job["byDay"] = 9  # already overdue as of day 10
		GameState.state["jamesJob"] = job
		GameState.state["flags"]["jamesJobActive"] = true
		GameState.state["flags"]["jamesJobAccepted"] = true
		var relation_before: int = GameState.state["contacts"]["james"]["relation"]

		Jobs.expire_overdue_job()

		assert_eq(GameState.state["jamesJob"], null, "overdue job cleared")
		assert_eq(GameState.state["flags"]["jamesJobActive"], false, "jobActive flag cleared")
		assert_eq(GameState.state["flags"]["jamesJobAccepted"], false, "jobAccepted flag cleared")
		assert_eq(GameState.state["contacts"]["james"]["relation"], relation_before + Jobs.MISSED_DEADLINE_RELATION_PENALTY, "missing the deadline docks relation")
	)

	run_case("expire_overdue_job_leaves_job_untouched_before_byDay", func():
		GameState.reset()
		GameState.state["world"]["day"] = 3
		var job := Jobs.generate_james_job()
		job["byDay"] = 20
		GameState.state["jamesJob"] = job
		GameState.state["flags"]["jamesJobActive"] = true
		var relation_before: int = GameState.state["contacts"]["james"]["relation"]

		Jobs.expire_overdue_job()

		assert_eq(GameState.state["jamesJob"], job, "job untouched before its deadline")
		assert_eq(GameState.state["flags"]["jamesJobActive"], true, "jobActive flag untouched")
		assert_eq(GameState.state["contacts"]["james"]["relation"], relation_before, "no relation change before the deadline")
	)

	run_case("expire_overdue_job_ignores_flatPay_jobs", func():
		GameState.reset()
		GameState.state["world"]["day"] = 999
		var job := Jobs.generate_flat_pay_job()
		GameState.state["jamesJob"] = job
		GameState.state["flags"]["jamesJobActive"] = true

		Jobs.expire_overdue_job()

		assert_eq(GameState.state["jamesJob"], job, "flatPay jobs have no deadline to expire")
		assert_eq(GameState.state["flags"]["jamesJobActive"], true, "jobActive flag untouched")
	)
