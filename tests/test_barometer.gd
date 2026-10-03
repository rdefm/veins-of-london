extends "res://tests/test_base.gd"


func run() -> void:
	run_case("ensure_progress_inits_active_at_100_others_at_0", func():
		GameState.reset()
		Barometer.ensure_progress()
		var progress: Dictionary = GameState.state["barometer"]["progress"]
		assert_eq(progress["economic"]["stable"], 100, "active state starts at 100")
		assert_eq(progress["economic"]["boom"], 0, "non-active state starts at 0")
		assert_eq(progress["social"]["stable"], 100, "social active state starts at 100")
		assert_eq(progress["political"]["stable"], 100, "political active state starts at 100")
	)

	run_case("ensure_progress_does_not_clobber_existing_values", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 42
		Barometer.ensure_progress()
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["boom"], 42, "second call should not reset an existing value")
	)

	run_case("drift_is_deterministic_given_the_same_seed", func():
		GameState.reset()
		Barometer.ensure_progress()
		var baseline: Dictionary = GameState.deep_copy(GameState.state["barometer"]["progress"])

		Rng.set_seed(555)
		Barometer._apply_organic_drift()
		var first_result: Dictionary = GameState.deep_copy(GameState.state["barometer"]["progress"])

		GameState.state["barometer"]["progress"] = GameState.deep_copy(baseline)
		Rng.set_seed(555)
		Barometer._apply_organic_drift()
		var second_result: Dictionary = GameState.deep_copy(GameState.state["barometer"]["progress"])

		assert_eq(first_result, second_result, "same seed should drift identically")
	)

	run_case("state_force_fed_to_100_flips_active_and_zeroes_old", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 100
		Barometer._resolve_section("economic")

		assert_eq(GameState.state["barometer"]["economic"], "boom", "boom should become the active state")
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["boom"], 100, "new active sits at 100")
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["stable"], 0, "old active drops to 0")
		assert_eq(Barometer.news_sections_order(), ["economic", "political", "social"], "a changed active state leads the feed")
	)

	run_case("news_recency_tracks_only_active_state_changes", func():
		GameState.reset()
		Barometer.ensure_progress()
		assert_eq(Barometer.news_sections_order(), ["political", "economic", "social"], "fresh game uses editorial order")
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 70
		Barometer._resolve_section("economic")
		assert_eq(GameState.state["barometer"]["changeSeq"], 0, "progress alone does not stamp recency")
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 100
		Barometer._resolve_section("economic")
		GameState.state["barometer"]["progress"]["social"]["unrest"] = 100
		Barometer._resolve_section("social")
		assert_eq(Barometer.news_sections_order(), ["social", "economic", "political"], "latest shift leads")
		assert_eq(GameState.state["barometer"]["changeSeq"], 2, "each active-state shift stamps once")
		Barometer._resolve_section("social")
		assert_eq(GameState.state["barometer"]["changeSeq"], 2, "re-resolution without a shift does not stamp")
	)

	run_case("manual_push_stamps_recency_only_when_it_resolves", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["player"]["cash"] = 5000
		GameState.state["barometer"]["progress"]["social"]["festival"] = 80
		assert_true(Barometer.manual_push("social", "festival")["ok"], "push succeeds")
		assert_eq(Barometer.news_sections_order()[0], "social", "push-triggered active shift leads")
		assert_eq(GameState.state["barometer"]["changedAt"]["social"], 1, "manual shift is stamped")
	)

	run_case("resolution_pushes_a_breaking_news_notification", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["social"]["unrest"] = 100
		Rng.set_seed(1)
		Barometer._resolve_section("social")
		var headlines: Array = GameData.BAROMETER_STATES["social"]["unrest"]["headlines"]
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].begins_with("📰 BREAKING — ") and headlines.has(n["text"].trim_prefix("📰 BREAKING — ")):
				found = true
		assert_true(found, "should push a '📰 BREAKING — <headline>' notification using one of the state's headline variants")
	)


	run_case("trend_hint_state_flags_a_non_active_state_at_or_above_70", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 70
		assert_eq(Barometer.trend_hint_state("economic"), "boom", "boom at exactly 70 should qualify")
	)


	run_case("trend_hint_state_is_null_below_threshold", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 69
		assert_eq(Barometer.trend_hint_state("economic"), null, "boom at 69 should not qualify")
	)


	run_case("trend_hint_state_picks_the_highest_progress_qualifying_state", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 75
		GameState.state["barometer"]["progress"]["economic"]["crisis"] = 90
		assert_eq(Barometer.trend_hint_state("economic"), "crisis", "crisis (90) should beat boom (75)")
	)

	run_case("a_queued_push_nudges_one_tick_like_a_pref_then_clears", func():
		GameState.reset()
		Barometer.ensure_progress()
		var baseline: Dictionary = GameState.deep_copy(GameState.state["barometer"]["progress"])
		Barometer._apply_faction_nudges()
		var prefs_only: int = GameState.state["barometer"]["progress"]["social"]["festival"]
		GameState.state["barometer"]["progress"] = baseline
		Barometer.queue_push("conclave", "social", "festival", "push", 5)
		Barometer._apply_faction_nudges()
		assert_eq(GameState.state["barometer"]["progress"]["social"]["festival"], prefs_only + 5, "the push adds its strength")
		assert_eq(Barometer.queued_pushes(), [], "and is spent")
		Barometer._apply_faction_nudges()
		assert_eq(GameState.state["barometer"]["progress"]["social"]["festival"], prefs_only * 2 + 5, "only once")
	)

	run_case("manual_push_costs_2000_adds_20_progress_and_sets_cooldown", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["player"]["cash"] = 5000
		var result := Barometer.manual_push("economic", "boom")

		assert_true(result["ok"], "push should succeed with enough cash and no cooldown")
		assert_eq(GameState.state["player"]["cash"], 3000, "push costs £2000")
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["boom"], 20, "push adds +20 progress")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "the push records one bank transaction")
		assert_eq(bank_log[0]["amount"], -Barometer.MANUAL_ACTION_COST, "the recorded amount matches the manual action cost")
	)

	run_case("manual_push_respects_cooldown", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["player"]["cash"] = 10000
		Barometer.manual_push("economic", "boom")
		var cash_after_first: int = GameState.state["player"]["cash"]
		var result := Barometer.manual_push("economic", "boom")

		assert_true(not result["ok"], "second push same day should be blocked by cooldown")
		assert_eq(GameState.state["player"]["cash"], cash_after_first, "blocked push should not spend cash")
	)

	run_case("manual_push_requires_enough_cash", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["player"]["cash"] = 100
		var result := Barometer.manual_push("economic", "boom")
		assert_true(not result["ok"], "push should fail without £2000")
	)

	run_case("manual_pull_subtracts_20_and_does_not_resolve", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 50
		GameState.state["player"]["cash"] = 5000
		Barometer.manual_pull("economic", "boom")
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["boom"], 30, "pull subtracts 20")
		assert_eq(GameState.state["barometer"]["economic"], "stable", "pull alone never resolves a new active state")
	)

	run_case("item_demand_mult_combines_demand_all_and_item_demand", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "boom"  # demandAll +0.1
		GameState.state["barometer"]["political"] = "war"  # shield +0.6
		assert_almost_eq(Barometer.get_item_demand_mult("shield"), 1.1 * 1.6, 0.0001, "(1 + demandAll) x (1 + itemDemand)")
		assert_almost_eq(Barometer.get_item_demand_mult("timePearl"), 1.1, 0.0001, "demandAll alone lifts every item")
		GameState.state["barometer"]["economic"] = "recession"  # demandAll -0.1
		assert_almost_eq(Barometer.get_item_demand_mult("timePearl"), 0.9, 0.0001, "a negative demandAll lowers every item")
	)

	run_case("item_demand_sums_across_active_states", func():
		GameState.reset()
		GameState.state["barometer"]["social"] = "festival"  # shield +0.4
		GameState.state["barometer"]["political"] = "war"  # shield +0.6
		assert_almost_eq(Barometer.get_merged_effects()["itemDemand"]["shield"], 1.0, 0.0001, "per-recipe fractions sum")
	)

	run_case("austerity_raises_living_costs_and_keeps_mugging_effect", func():
		GameState.reset()
		GameState.state["barometer"]["political"] = "austerity"
		var fx: Dictionary = Barometer.get_merged_effects()
		assert_almost_eq(fx["dailyCost"], 0.05, 0.0001, "Austerity adds 5% to the weekly base")
		assert_almost_eq(fx["mugChance"], 0.06, 0.0001, "mugging effect remains +6 points")
		GameState.state["barometer"]["social"] = "lockdown"
		assert_almost_eq(Barometer.get_merged_effects()["dailyCost"], 0.15, 0.0001, "living-cost modifiers sum before billing")
	)

	run_case("ore_regulation_raises_item_demand_without_changing_mugging_chance", func():
		GameState.reset()
		GameState.state["barometer"]["political"] = "regulation"
		var fx: Dictionary = Barometer.get_merged_effects()
		assert_true(not fx.has("mugChance"), "Regulation has no mugging modifier")
		assert_almost_eq(Barometer.get_effective_mug_chance(0.20), 0.20, 0.0001, "Regulation leaves base mugging chance alone")
		assert_almost_eq(fx["demandAll"], 0.08, 0.0001, "Regulation retains its demand modifier")
		assert_almost_eq(Barometer.get_item_demand_mult("shield"), 1.08, 0.0001, "Shield demand rises")
		assert_almost_eq(Barometer.get_item_demand_mult("timePearl"), 1.08, 0.0001, "Time Pearl demand rises")
		GameState.state["barometer"]["social"] = "crime"
		assert_almost_eq(Barometer.get_merged_effects()["mugChance"], 0.15, 0.0001, "Crime Wave alone contributes the mugging modifier")
		assert_almost_eq(Barometer.get_effective_mug_chance(0.20), 0.35, 0.0001, "Crime Wave mugging effect still applies with Regulation")
		assert_almost_eq(Barometer.get_item_demand_mult("shield"), 1.08, 0.0001, "Regulation demand still applies with Crime Wave")
	)

	run_case("election_effect_mod_scales_the_demand_keys", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "boom"  # demandAll +0.1, mugChance -0.05
		GameState.state["barometer"]["social"] = "festival"  # shield +0.4
		GameState.state["barometer"]["political"] = "election"  # effectMod -0.3
		var fx := Barometer.get_merged_effects()
		assert_almost_eq(fx["demandAll"], 0.07, 0.0001, "demandAll x 0.7")
		assert_almost_eq(fx["itemDemand"]["shield"], 0.28, 0.0001, "itemDemand x 0.7")
		assert_almost_eq(fx["mugChance"], -0.05, 0.0001, "non-demand keys unscaled")
	)

	run_case("effective_mug_chance_is_clamped_0_to_0_8", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "crisis"  # +0.12 mugChance
		var chance := Barometer.get_effective_mug_chance(0.20)
		assert_almost_eq(chance, 0.32, 0.0001, "0.20 base + 0.12 crisis mugChance")
	)
