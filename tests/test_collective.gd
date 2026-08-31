extends "res://tests/test_base.gd"

# collective1-07, spec §5.5/§7.2/§9.5: Collective.complete_trade() is the one
# thing that differs across Des/Nadia/Hakim's otherwise-identical Trade
# doors -- a bark line appended to whichever contact's conversation the
# trade happened in, drawn without repeats until that vendor's pool is
# exhausted.


func _site(id: String, ore_type: String, tier: String, claimed: bool = false, faction_vein: Variant = null) -> Dictionary:
	return {
		"id": id, "district": "shoreditch", "tier": tier, "oreType": ore_type,
		"bonuses": [], "discoveredDay": 1, "claimed": claimed, "factionVein": faction_vein,
		"hasNaturalVein": false,
	}


func run() -> void:
	run_case("complete_trade_sells_via_the_collective_lane_and_credits_cash", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.adjust_sell_qty("ore_time", 3, 10)

		var result := Collective.complete_trade("des")

		assert_true(result["ok"], "sale should succeed")
		# time basePrice 60, collective relation 0 -> sell spread 0.45 -> 33/unit
		assert_eq(GameState.state["player"]["cash"], 40 + 99, "cash credited at the collective's sell price")
	)

	run_case("complete_trade_appends_a_bark_line_to_the_trading_contacts_conversation", func():
		GameState.reset()
		GameState.state["contacts"]["nadia"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["orichalchum"]["emotion"] = 5
		Economy.adjust_sell_qty("ore_emotion", 2, 5)

		Collective.complete_trade("nadia")

		var thread: Array = GameState.state["messages"]["nadia"]
		assert_eq(thread.size(), 1, "one bark message appended")
		assert_eq(thread[0]["from"], "them", "the bark reads as the vendor speaking")
		assert_eq(thread[0]["text"], GameData.COLLECTIVE_BARKS["nadia"][0], "first draw is the pool's first line")
	)

	run_case("complete_trade_draws_barks_with_no_repeat_until_the_pool_is_exhausted_then_wraps", func():
		GameState.reset()
		GameState.state["contacts"]["hakim"] = { "unlocked": true, "relation": 0 }
		var pool: Array = GameData.COLLECTIVE_BARKS["hakim"]

		for i in range(pool.size()):
			GameState.state["player"]["orichalchum"]["time"] = 10
			Economy.adjust_sell_qty("ore_time", 1, 10)
			Collective.complete_trade("hakim")

		var thread: Array = GameState.state["messages"]["hakim"]
		var seen: Array[String] = []
		for msg in thread:
			assert_true(not seen.has(msg["text"]), "no line repeats before the pool is exhausted")
			seen.append(msg["text"])
		assert_eq(seen.size(), pool.size(), "every line in the pool was drawn exactly once")

		# One more trade beyond the pool's size wraps back to the first line.
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.adjust_sell_qty("ore_time", 1, 10)
		Collective.complete_trade("hakim")
		assert_eq(thread[thread.size() - 1]["text"], pool[0], "the draw wraps back to the pool's first line")
	)

	run_case("complete_trade_is_a_no_op_on_bark_and_message_thread_when_the_cart_is_empty", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }

		var result := Collective.complete_trade("des")

		assert_true(not result["ok"], "nothing to sell")
		assert_true(not GameState.state["messages"].has("des"), "no bark appended when nothing was actually sold")
	)

	run_case("des_nadia_and_hakim_trade_at_identical_terms", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["contacts"]["nadia"] = { "unlocked": true, "relation": 0 }
		GameState.state["contacts"]["hakim"] = { "unlocked": true, "relation": 0 }

		for contact_id in ["des", "nadia", "hakim"]:
			GameState.reset()
			GameState.state["contacts"][contact_id] = { "unlocked": true, "relation": 0 }
			GameState.state["player"]["orichalchum"]["time"] = 10
			Economy.adjust_sell_qty("ore_time", 3, 10)
			var result := Collective.complete_trade(contact_id)
			assert_eq(result["earned"], 99, "%s's door prices identically to the others" % contact_id)
	)

	# ── report_des_site() ──────────────────────────────────────────────

	run_case("report_des_site_converts_a_qualifying_site_awards_relation_and_records_progress", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"] = [_site("s1", "fate", "fair")]
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		var result := Collective.report_des_site("fate")

		assert_true(result["ok"], "a qualifying fate site exists")
		var site: Dictionary = Sites.find_site("s1")
		assert_true(site["factionVein"] != null, "the site converts to a Collective vein immediately")
		assert_eq(site["factionVein"]["factionId"], "collective")
		assert_eq(site["factionVein"]["growth"], GameData.VEIN_GROWTH["seedGrowth"])
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 4, "+4 relation on report")
		assert_eq(GameState.state["objectives"]["col_a1_des_sites"]["progress"]["reportedSiteIds"], { "fate": "s1" })
	)

	run_case("report_des_site_is_a_no_op_when_no_qualifying_site_exists", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		var result := Collective.report_des_site("fate")

		assert_true(not result["ok"], "no fate site to report")
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before, "no relation awarded on a no-op")
		assert_eq(GameState.state["objectives"].get("col_a1_des_sites", {}).get("progress", {}).get("reportedSiteIds", {}), {}, "nothing recorded on a no-op")
	)

	run_case("report_des_site_ignores_claimed_and_faction_owned_sites", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"] = [_site("s1", "fate", "fair", true)]

		var result := Collective.report_des_site("fate")

		assert_true(not result["ok"], "the only matching site is already claimed")
	)

	run_case("report_des_site_cannot_double_report_the_same_ore_type", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"] = [_site("s1", "fate", "fair")]
		GameState.state["world"]["sites"].append(_site("s2", "fate", "rich"))

		Collective.report_des_site("fate")
		var relation_after_first: int = GameState.state["factions"]["collective"]["relation"]
		var result := Collective.report_des_site("fate")

		assert_true(not result["ok"], "fate has already been reported once")
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_after_first, "no second relation award")
		assert_eq(Sites.find_site("s2")["factionVein"], null, "the second qualifying fate site is left untouched, not re-matched")
	)

	run_case("a_site_reported_for_one_ore_type_can_never_be_matched_again_for_any_ore_type", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"] = [_site("s1", "fate", "fair")]

		Collective.report_des_site("fate")

		var params: Dictionary = GameData.OBJECTIVES["col_a1_des_sites"]["params"]
		var reported_site: Dictionary = Sites.find_site("s1")
		assert_true(not Objectives.site_matches_discovery_params(reported_site, "fate", params), "no longer unclaimed, so it can't satisfy fate again")
		assert_true(not Objectives.site_matches_discovery_params(reported_site, "physics", params), "wrong oreType and no longer unclaimed -- can't be re-matched for the other required type either")
	)

	run_case("report_des_site_is_a_no_op_for_an_ore_type_not_required_by_the_objective", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"] = [_site("s1", "time", "fair")]

		var result := Collective.report_des_site("time")

		assert_true(not result["ok"], "time isn't one of col_a1_des_sites' required ore types")
	)

	run_case("col_a1_des_sites_completes_once_both_ore_types_are_reported_out_of_simultaneous_availability", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"] = [_site("s_fate", "fate", "fair")]

		# Report fate while it's the only qualifying site around -- the fate
		# site is already converted (no longer unclaimed) by the time physics
		# turns up, so the two are never simultaneously unclaimed.
		var fate_result := Collective.report_des_site("fate")
		assert_true(fate_result["ok"])
		assert_true(not GameState.state["flags"].get("colA1DesSitesFound", false), "physics hasn't been reported yet")

		GameState.state["world"]["sites"].append(_site("s_physics", "physics", "fair"))
		var physics_result := Collective.report_des_site("physics")
		assert_true(physics_result["ok"])

		assert_true(GameState.state["flags"]["colA1DesSitesFound"], "both ore types now individually reported")
		assert_true(GameState.state["objectives"]["col_a1_des_sites"]["complete"])
		assert_eq(GameState.state["objectives"]["col_a1_des_sites"]["progress"]["reportedSiteIds"], { "fate": "s_fate", "physics": "s_physics" })
	)

	# ── next_reportable_des_ore_type() ──────────────────────────────────

	run_case("next_reportable_des_ore_type_is_empty_when_the_thread_is_not_active", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site("s1", "fate", "fair")]
		assert_eq(Collective.next_reportable_des_ore_type(), "")
	)

	run_case("next_reportable_des_ore_type_is_empty_with_no_qualifying_site", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		assert_eq(Collective.next_reportable_des_ore_type(), "")
	)

	run_case("next_reportable_des_ore_type_returns_fate_before_physics_when_both_qualify", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"] = [_site("s_fate", "fate", "fair"), _site("s_physics", "physics", "fair")]
		assert_eq(Collective.next_reportable_des_ore_type(), "fate", "requireEachOreType order: fate, physics")
	)

	run_case("next_reportable_des_ore_type_skips_an_ore_type_already_reported", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"] = [_site("s_fate", "fate", "fair")]
		Collective.report_des_site("fate")
		GameState.state["world"]["sites"].append(_site("s_physics", "physics", "fair"))
		assert_eq(Collective.next_reportable_des_ore_type(), "physics")
	)

	run_case("next_reportable_des_ore_type_is_empty_once_both_are_reported", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"] = [_site("s_fate", "fate", "fair"), _site("s_physics", "physics", "fair")]
		Collective.report_des_site("fate")
		Collective.report_des_site("physics")
		assert_eq(Collective.next_reportable_des_ore_type(), "")
	)
