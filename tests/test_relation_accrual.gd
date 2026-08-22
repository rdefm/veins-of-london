extends "res://tests/test_base.gd"

# RelationAccrual — collective1-06, spec.md §8.4: trade feeds the meter that
# owns the lane as an accumulating, remainder-carrying £-denominated counter
# (tradeProgress) rather than a flat per-transaction award, capped per day.


func run() -> void:
	# ── Collective lane: +1 per £750, capped at +3/day ──────────────────

	run_case("collective_accrues_one_relation_point_per_750_traded", func():
		GameState.reset()
		var starting: int = GameState.state["factions"]["collective"]["relation"]
		RelationAccrual.accrue_collective(750)
		assert_eq(GameState.state["factions"]["collective"]["relation"], starting + 1, "£750 exactly buys one relation point")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 0, "the rate is consumed exactly, nothing left over")
	)

	run_case("collective_tradeProgress_carries_its_remainder_across_trades", func():
		GameState.reset()
		RelationAccrual.accrue_collective(400)
		assert_eq(GameState.state["factions"]["collective"]["relation"], 0, "£400 alone is below the £750 rate")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 400, "the £400 is banked, not dropped")

		RelationAccrual.accrue_collective(400)
		# 400 + 400 = 800 >= 750 -> one point, 50 left over
		assert_eq(GameState.state["factions"]["collective"]["relation"], 1, "the second trade's £400 tops the first over the £750 rate")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 50, "the £50 remainder past the rate carries forward")
	)

	run_case("collective_relation_award_is_capped_at_3_per_day_but_tradeProgress_keeps_the_rest", func():
		GameState.reset()
		# £750 * 5 = one huge trade worth 5 relation points -- only 3/day allowed.
		RelationAccrual.accrue_collective(750 * 5)
		assert_eq(GameState.state["factions"]["collective"]["relation"], 3, "daily cap holds even a single huge trade to +3")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 750 * 2, "the 2 points blocked by the cap stay banked, not lost")

		# A same-day follow-up trade earns nothing further -- the cap is already spent.
		RelationAccrual.accrue_collective(750)
		assert_eq(GameState.state["factions"]["collective"]["relation"], 3, "still capped at 3 for the day")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 750 * 3, "further trade still banks into tradeProgress even while capped")
	)

	# ── Archie lane: +1 per £1,000, capped at +2/day ────────────────────

	run_case("archie_accrues_one_relation_point_per_1000_sold", func():
		GameState.reset()
		var starting: int = GameState.state["contacts"]["archie"]["relation"]
		RelationAccrual.accrue_archie(1000)
		assert_eq(GameState.state["contacts"]["archie"]["relation"], starting + 1, "£1,000 exactly buys one relation point")
		assert_eq(GameState.state["contacts"]["archie"]["tradeProgress"], 0, "the rate is consumed exactly, nothing left over")
	)

	run_case("archie_relation_award_is_capped_at_2_per_day", func():
		GameState.reset()
		var starting: int = GameState.state["contacts"]["archie"]["relation"]
		RelationAccrual.accrue_archie(1000 * 4)
		assert_eq(GameState.state["contacts"]["archie"]["relation"], starting + 2, "daily cap holds even a single huge sale to +2")
		assert_eq(GameState.state["contacts"]["archie"]["tradeProgress"], 1000 * 2, "the 2 points blocked by the cap stay banked, not lost")
	)

	# ── Daily cap reset ──────────────────────────────────────────────────

	run_case("reset_daily_caps_clears_the_award_counter_but_not_tradeProgress", func():
		GameState.reset()
		RelationAccrual.accrue_collective(750 * 3)  # exactly caps out at +3, no remainder
		RelationAccrual.accrue_collective(700)      # already capped for the day -- banks, doesn't convert
		var relation_before_reset: int = GameState.state["factions"]["collective"]["relation"]
		assert_eq(relation_before_reset, 3, "capped at +3 for the day")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 700, "the capped £700 is banked, not lost")

		RelationAccrual.reset_daily_caps()

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before_reset, "resetting the cap counter doesn't itself award anything")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 700, "tradeProgress is untouched by the reset")

		# Now a small trade tops the banked £700 over the £750 rate, and today's
		# cap counter is back to zero, so it converts.
		RelationAccrual.accrue_collective(50)
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before_reset + 1, "the banked remainder plus a trade past the rate converts now the cap has reset")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 0, "the rate is consumed exactly")
	)

	run_case("daily_tick_resets_the_relation_accrual_cap", func():
		GameState.reset()
		RelationAccrual.accrue_collective(750 * 3)  # exactly caps out at +3, no remainder
		RelationAccrual.accrue_collective(700)      # already capped -- banks, doesn't convert
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		TimeSystem.daily_tick()

		RelationAccrual.accrue_collective(50)
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 1, "a fresh day's cap lets the banked remainder convert")
	)

	# ── Vein sales count toward tradeProgress like any other trade ──────

	run_case("vein_sale_price_counts_toward_the_selling_factions_tradeProgress", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "life",
			"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
			"hasNaturalVein": false,
		}]
		GameState.state["player"]["veins"] = [{
			"id": "v1", "district": "shoreditch", "oreType": "life", "growth": 20,
			"security": "none", "alarmUpgrades": [], "location": "Test Alley",
			"claimedOnDay": 1, "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
			"rampantDays": 0,
		}]

		# spec §8.3's worked table: fresh seed (growth 20), fair -> quote £980.
		var price: int = VeinTrade.quote(GameState.state["player"]["veins"][0])
		assert_eq(price, 980)
		VeinTrade.sell_to_faction("v1", "collective")

		# £980 crosses the £750 rate once -- +1 relation, £230 banked into tradeProgress.
		assert_eq(GameState.state["factions"]["collective"]["relation"], 1, "the vein's sale price accrues relation exactly like an ordinary trade")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], price - 750, "the remainder past the rate is banked, not dropped")
	)

	# ── Des, Nadia and Hakim get no personal trickle from trade ─────────

	run_case("an_unconfigured_lane_id_is_a_no_op", func():
		GameState.reset()
		# collective1-06, spec §8.4: Des, Nadia and Hakim's lanes feed the
		# Collective faction meter, not a personal one -- RelationAccrual has
		# no lane entry for them, so an unknown lane id must be inert.
		assert_true(not RelationAccrual.LANES.has("des"), "no personal accrual lane exists for Des")
		assert_true(not RelationAccrual.LANES.has("nadia"), "no personal accrual lane exists for Nadia")
		assert_true(not RelationAccrual.LANES.has("hakim"), "no personal accrual lane exists for Hakim")
	)
