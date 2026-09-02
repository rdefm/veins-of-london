extends "res://tests/test_base.gd"

# RelationAccrual — collective1-06, spec.md §8.4: trade feeds the meter that
# owns the lane as an accumulating, remainder-carrying £-denominated counter
# (tradeProgress) rather than a flat per-transaction award, capped per day.
#
# bugfix, post-launch: the collective lane's rate/cap were originally £750
# per point, capped at +3/day -- too slow and, with no Notify feedback
# (added in RelationAccrual._accrue()), too invisible. Now £350/+5/day; see
# systems/relation_accrual.gd's LANES comment.


func run() -> void:
	# ── Collective lane: +1 per £350, capped at +5/day ──────────────────

	run_case("collective_accrues_one_relation_point_per_350_traded", func():
		GameState.reset()
		var starting: int = GameState.state["factions"]["collective"]["relation"]
		RelationAccrual.accrue_collective(350)
		assert_eq(GameState.state["factions"]["collective"]["relation"], starting + 1, "£350 exactly buys one relation point")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 0, "the rate is consumed exactly, nothing left over")
	)

	run_case("collective_tradeProgress_carries_its_remainder_across_trades", func():
		GameState.reset()
		RelationAccrual.accrue_collective(200)
		assert_eq(GameState.state["factions"]["collective"]["relation"], 0, "£200 alone is below the £350 rate")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 200, "the £200 is banked, not dropped")

		RelationAccrual.accrue_collective(200)
		# 200 + 200 = 400 >= 350 -> one point, 50 left over
		assert_eq(GameState.state["factions"]["collective"]["relation"], 1, "the second trade's £200 tops the first over the £350 rate")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 50, "the £50 remainder past the rate carries forward")
	)

	run_case("collective_relation_award_is_capped_at_5_per_day_but_tradeProgress_keeps_the_rest", func():
		GameState.reset()
		# £350 * 7 = one huge trade worth 7 relation points -- only 5/day allowed.
		RelationAccrual.accrue_collective(350 * 7)
		assert_eq(GameState.state["factions"]["collective"]["relation"], 5, "daily cap holds even a single huge trade to +5")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 350 * 2, "the 2 points blocked by the cap stay banked, not lost")

		# A same-day follow-up trade earns nothing further -- the cap is already spent.
		RelationAccrual.accrue_collective(350)
		assert_eq(GameState.state["factions"]["collective"]["relation"], 5, "still capped at 5 for the day")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 350 * 3, "further trade still banks into tradeProgress even while capped")
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
		RelationAccrual.accrue_collective(350 * 5)  # exactly caps out at +5, no remainder
		RelationAccrual.accrue_collective(300)      # already capped for the day -- banks, doesn't convert
		var relation_before_reset: int = GameState.state["factions"]["collective"]["relation"]
		assert_eq(relation_before_reset, 5, "capped at +5 for the day")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 300, "the capped £300 is banked, not lost")

		RelationAccrual.reset_daily_caps()

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before_reset, "resetting the cap counter doesn't itself award anything")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 300, "tradeProgress is untouched by the reset")

		# Now a small trade tops the banked £300 over the £350 rate, and today's
		# cap counter is back to zero, so it converts.
		RelationAccrual.accrue_collective(50)
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before_reset + 1, "the banked remainder plus a trade past the rate converts now the cap has reset")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 0, "the rate is consumed exactly")
	)

	run_case("daily_tick_resets_the_relation_accrual_cap", func():
		GameState.reset()
		RelationAccrual.accrue_collective(350 * 5)  # exactly caps out at +5, no remainder
		RelationAccrual.accrue_collective(300)      # already capped -- banks, doesn't convert
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

		# £980 crosses the £350 rate twice (700) -- +2 relation, £280 banked into tradeProgress.
		assert_eq(GameState.state["factions"]["collective"]["relation"], 2, "the vein's sale price accrues relation exactly like an ordinary trade")
		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], price - 700, "the remainder past the rate is banked, not dropped")
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
