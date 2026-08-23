extends "res://tests/test_base.gd"


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


func run() -> void:
	run_case("sale_rejects_empty_item_list", func():
		GameState.reset()
		var result := Economy.execute_sale([])
		assert_true(not result["ok"], "an empty sale should be a no-op")
	)

	run_case("gross_math_basic_ore_sale", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# time basePrice 60, barometer stable -> effective price 60, gross = 180.
		# execute_sale awards ARCHIE_SALE_RELATION_GAIN (+2) *before* computing
		# the cut, so the ratio uses relation 12 (startRelation 10 + 2), not 10:
		# 0.60 + 0.25*(12-10)/70 = 0.6071428571; floor(180*that) = 109.
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 7, "3 ore deducted")
		assert_eq(GameState.state["player"]["cash"], 40 + 109, "playerCut reflects the cut ratio at post-award relation 12, added to starting cash 40")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "a non-mugged sale should open the sale_result modal")
		assert_eq(GameState.state["modal"]["data"]["mugged"], false, "modal data reflects the non-mugged outcome")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "a non-mugged sale records one bank transaction")
		assert_eq(bank_log[0]["amount"], 109, "the recorded amount matches the player cut")
		assert_eq(bank_log[0]["label"], "Archie sale", "the recorded label names the sale")
	)

	# collective1-06, spec §8.4: the flat ARCHIE_SALE_RELATION_GAIN-per-sale
	# award (bugfixes-63) stays, alongside RelationAccrual's separate
	# £-denominated tradeProgress accumulator (see tests/test_relation_accrual.gd
	# for the rate/cap/remainder behavior in isolation) -- these cases confirm
	# both fire on the same sale, and that the accumulator's own points don't
	# leak into the flat award's already-tested cut-ratio timing.
	run_case("sale_via_archie_awards_the_flat_gain_and_feeds_tradeProgress", func():
		GameState.reset()
		var starting_relation: int = GameState.state["contacts"]["archie"]["relation"]
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
		assert_eq(GameState.state["contacts"]["archie"]["relation"], starting_relation + 2, "the flat ARCHIE_SALE_RELATION_GAIN still applies")
		assert_eq(GameState.state["contacts"]["archie"]["tradeProgress"], 180, "gross value (3 * £60) also banked into tradeProgress")
	)

	run_case("a_single_sale_crossing_the_1000_rate_still_prices_its_own_cut_at_the_relation_after_the_flat_award_only", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 20
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 17 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# gross = 17*60 = 1020. The flat +2 award runs before the cut (as
		# always) -> relation 10 -> 12, cut ratio 0.6071428571, player_cut =
		# floor(1020*0.6071428571) = 619. RelationAccrual runs *after* the
		# cut (systems/economy.gd) -- £1,020 crosses its £1,000 rate for one
		# more point, relation 12 -> 13, but that point must not have been
		# folded into this sale's own cut (which would price at relation 13's
		# ratio 0.6107142857, floor(1020*that) = 622, if the ordering were wrong).
		assert_eq(GameState.state["contacts"]["archie"]["relation"], 13, "flat +2 award, then +1 from crossing the £1,000 tradeProgress rate")
		assert_eq(GameState.state["player"]["cash"], 40 + 619, "the cut used the flat-award relation (12), not the relation the accumulator bumped it to on top (13)")
	)

	run_case("mugged_sale_via_archie_still_awards_the_flat_gain_and_feeds_tradeProgress", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return result.get("mugged", false)
		)
		assert_true(seed != -1, "should find a mugged roll within 200 tries")
		# archie startRelation 10 (R§1.11) + ARCHIE_SALE_RELATION_GAIN 2 = 12
		assert_eq(GameState.state["contacts"]["archie"]["relation"], 12, "relation gain should not depend on the mugging outcome")
		assert_eq(GameState.state["contacts"]["archie"]["tradeProgress"], 180, "tradeProgress accrual should not depend on the mugging outcome either")
	)

	run_case("gross_math_applies_barometer_premiums", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["barometer"]["economic"] = "crisis"  # orePrice -0.35, fatePremium +0.5
			GameState.state["player"]["orichalchum"]["fate"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "fate", "qty": 2 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# effective fate price under crisis = round_epsilon(90*(1-0.35+0.5)) = 104; gross = 208
		# post-award relation 12 -> cut ratio 0.6071428571 (see gross_math_basic_ore_sale)
		assert_eq(GameState.state["player"]["cash"], 40 + 126, "playerCut reflects the barometer-adjusted price")
	)

	run_case("gross_math_applies_district_priceMod", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["world"]["currentDistrict"] = "city"  # priceMod +0.15
			GameState.state["player"]["orichalchum"]["fate"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "fate", "qty": 2 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# fate basePrice 90, stable barometer -> 90; city priceMod +0.15 -> round_epsilon(90*1.15) = 104; gross = 208
		# post-award relation 12 -> cut ratio 0.6071428571 (see gross_math_basic_ore_sale)
		assert_eq(GameState.state["player"]["cash"], 40 + 126, "playerCut reflects the district priceMod")
	)

	run_case("consumable_price_also_gets_district_priceMod", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["world"]["currentDistrict"] = "camden"  # priceMod -0.05
			GameState.state["player"]["inventory"]["timePearl"] = { "0": 5 }
			var result := Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "qty": 1 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# timePearl 120 * (1 - 0.05) = round_epsilon(114) = 114; post-award
		# relation 12 -> cut ratio 0.6071428571 (see gross_math_basic_ore_sale);
		# cut = floor(114*0.6071428571) = 69
		assert_eq(GameState.state["player"]["cash"], 40 + 69, "consumable sale price also carries the district priceMod")
	)

	run_case("dangerMod_can_tip_a_non_mugging_roll_into_a_mugging", func():
		var found_seed := -1
		for seed in range(1000):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 10
			Rng.set_seed(seed)
			var base_result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 1 }])
			if base_result.get("mugged", false):
				continue
			GameState.reset()
			GameState.state["world"]["currentDistrict"] = "camden"  # dangerMod +0.10
			GameState.state["player"]["orichalchum"]["time"] = 10
			Rng.set_seed(seed)
			var danger_result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 1 }])
			if danger_result.get("mugged", false):
				found_seed = seed
				break
		assert_true(found_seed != -1, "should find a seed where camden's +0.10 dangerMod tips a non-mugging roll into a mugging")
	)

	run_case("consumable_sale_flips_archieMotionPending_exactly_once", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["timePearl"] = { "0": 5 }

		var first := Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "qty": 1 }])
		assert_true(GameState.state["flags"]["archieMotionPending"], "first consumable sale should set the pending flag")
		var notif_count_after_first: int = GameState.state["notifications"].size()

		Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "qty": 1 }])
		var notif_count_after_second: int = GameState.state["notifications"].size()

		assert_eq(GameState.state["flags"]["consSoldCount"], 2, "counter still accumulates both sales")
		assert_eq(notif_count_after_second, notif_count_after_first, "second sale should not push another Archie-texted notification")
	)

	run_case("consumable_sale_does_not_flip_pending_once_archieMotionEventSeen", func():
		GameState.reset()
		GameState.state["flags"]["archieMotionEventSeen"] = true
		GameState.state["player"]["inventory"]["timePearl"] = { "0": 5 }
		Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "qty": 1 }])
		assert_true(not GameState.state["flags"]["archieMotionPending"], "should not re-trigger once the motion event has already been seen")
	)

	run_case("mugged_path_defers_payout_to_pendingSaleCut", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return result.get("mugged", false)
		)
		assert_true(seed != -1, "should find a mugged roll within 200 tries")
		assert_eq(GameState.state["player"]["cash"], 40, "cash should NOT increase yet — payout is deferred")
		# post-award relation 12 -> cut ratio 0.6071428571 (see gross_math_basic_ore_sale)
		assert_eq(GameState.state["pendingSaleCut"], 109, "pendingSaleCut holds floor(180*0.6071428571) = 109 until muggingWon")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 7, "goods are still deducted even when mugged")
	)

	run_case("complete_mugged_sale_pays_out_and_clears_pendingSaleCut", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		GameState.state["pendingSaleCut"] = 90
		var result := Economy.complete_mugged_sale()

		assert_eq(GameState.state["player"]["cash"], 190, "pendingSaleCut credited on muggingWon")
		assert_eq(GameState.state["pendingSaleCut"], 0, "pendingSaleCut clears after payout")
		assert_eq(result["earned"], 90, "returned earned matches what was paid")
		assert_eq(result["gross"], 180, "gross for display is earned * 2, per the prototype")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "muggingWon should open the sale_result modal")
		assert_eq(GameState.state["modal"]["data"]["mugged"], true, "modal data reflects the mugged outcome")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "the deferred mugging payout records one bank transaction")
		assert_eq(bank_log[0]["amount"], 90, "the recorded amount matches the deferred payout")
	)

	run_case("adjust_sell_qty_clamps_between_0_and_max", func():
		GameState.reset()
		Economy.adjust_sell_qty("ore_time", 5, 3)
		assert_eq(GameState.state["sellState"]["ore_time"], 3, "should clamp at max_qty")
		Economy.adjust_sell_qty("ore_time", -10, 3)
		assert_eq(GameState.state["sellState"]["ore_time"], 0, "should clamp at 0, not go negative")
	)

	run_case("clear_sell_state_empties_it", func():
		GameState.reset()
		Economy.adjust_sell_qty("ore_time", 2, 10)
		Economy.clear_sell_state()
		assert_eq(GameState.state["sellState"], {}, "should be empty after clearing")
	)

	run_case("sell_from_sell_state_builds_items_and_clears_afterward", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 10
			GameState.state["player"]["inventory"]["timePearl"] = { "0": 5 }
			Economy.adjust_sell_qty("ore_time", 3, 10)
			Economy.adjust_sell_qty("con_timePearl_0", 2, 5)
			var result := Economy.sell_from_sell_state()
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# gross = 3*60 (time) + 2*120 (timePearl, tier 0 -> 1.0x) = 420; post-award
		# relation 12 -> cut ratio 0.6071428571 (see gross_math_basic_ore_sale);
		# cut = floor(420*0.6071428571) = 254
		assert_eq(GameState.state["player"]["cash"], 40 + 254, "sale proceeds from both ore and consumable lines")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 7, "ore deducted")
		assert_eq(Crafting.inventory_qty("timePearl"), 3, "consumable deducted")
		assert_eq(GameState.state["sellState"], {}, "sellState cleared after selling")
	)

	# ── ticket 64: quality tier scales a consumable's sale price ─────────

	run_case("quality_price_multiplier_matches_the_confirmed_curve", func():
		assert_almost_eq(Economy.quality_price_multiplier(0), 1.0, 0.0001, "tier 0 (untiered/legacy) prices the same as tier 1 -- no bonus, no penalty")
		assert_almost_eq(Economy.quality_price_multiplier(1), 1.0, 0.0001, "tier 1: no bonus")
		assert_almost_eq(Economy.quality_price_multiplier(5), 2.0, 0.0001, "tier 5: +25%/tier over 1, doubling at the top skill tier")
	)

	run_case("selling_different_tiers_of_the_same_consumable_yields_different_prices", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["inventory"]["timePearl"] = { "1": 1 }
			var result := Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "tier": 1, "qty": 1 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# timePearl 120 * quality_price_multiplier(1) 1.0 = 120; the flat
		# ARCHIE_SALE_RELATION_GAIN (+2) applies before the cut (bugfixes-63,
		# kept alongside collective1-06 -- spec.md §8.4), so relation 12 ->
		# cut ratio 0.6071428571; cut = floor(120*0.6071428571) = 72
		assert_eq(GameState.state["player"]["cash"], 40 + 72, "tier 1 sells at the base price")

		GameState.reset()
		GameState.state["player"]["inventory"]["timePearl"] = { "5": 1 }
		Rng.set_seed(seed)
		Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "tier": 5, "qty": 1 }])
		# timePearl 120 * quality_price_multiplier(5) 2.0 = 240; cut = floor(240*0.6071428571) = 145
		assert_eq(GameState.state["player"]["cash"], 40 + 145, "tier 5 sells for double the tier-1 price, same base item")
	)

	run_case("execute_sale_removes_stock_from_the_exact_tier_sold_leaving_other_tiers_untouched", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["timePearl"] = { "1": 3, "5": 2 }
		Rng.set_seed(1)  # outcome (mugged or not) doesn't matter -- both branches deduct the same way
		Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "tier": 1, "qty": 2 }])
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "1": 1, "5": 2 }, "only the sold tier's bucket is drawn down")
	)

	run_case("sell_from_sell_state_offers_each_tier_of_a_consumable_as_its_own_sellable_line", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["inventory"]["timePearl"] = { "1": 5, "5": 5 }
			Economy.adjust_sell_qty("con_timePearl_1", 2, 5)
			Economy.adjust_sell_qty("con_timePearl_5", 1, 5)
			var result := Economy.sell_from_sell_state()
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# gross = 2*120 (tier 1, 1.0x) + 1*240 (tier 5, 2.0x) = 480; the flat
		# ARCHIE_SALE_RELATION_GAIN (+2) applies before the cut, so relation
		# 12 -> cut ratio 0.6071428571; cut = floor(480*0.6071428571) = 291
		assert_eq(GameState.state["player"]["cash"], 40 + 291, "each tier line sells at its own tier-scaled price")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "1": 3, "5": 4 }, "each tier's stock is drawn down independently")
	)

	# ── Faction trade lanes (bugfixes-28, generalized by collective1-01) ─

	run_case("guild_buy_price_above_ticker_base_at_full_spread", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 40  # join threshold -> full 15% spread
		var price := Economy.get_faction_buy_price("guild", "ore", "time")
		assert_eq(price, 69, "time basePrice 60, stable barometer -> 60 * 1.15 = 69")
	)

	run_case("guild_sell_price_below_ticker_base_at_full_spread", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 40
		var price := Economy.get_faction_sell_price("guild", "ore", "time")
		assert_eq(price, 51, "60 * 0.85 = 51")
	)

	run_case("guild_spread_clamps_at_max_below_join_threshold", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 0
		assert_eq(Economy.get_faction_sell_spread("guild"), 0.15, "spread never exceeds 15%, even below the join threshold")
		assert_eq(Economy.get_faction_buy_spread("guild"), 0.15, "buy and sell spread are identical for the Guild's symmetric row")
	)

	run_case("guild_spread_narrows_as_relation_increases_then_flattens_at_zero", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 40
		var full_price := Economy.get_faction_buy_price("guild", "ore", "time")

		GameState.state["factions"]["guild"]["relation"] = 65  # halfway to 90 -> spread 7.5%
		var narrowed_price := Economy.get_faction_buy_price("guild", "ore", "time")

		GameState.state["factions"]["guild"]["relation"] = 90
		var zero_spread_price := Economy.get_faction_buy_price("guild", "ore", "time")

		GameState.state["factions"]["guild"]["relation"] = 200
		var beyond_zero_price := Economy.get_faction_buy_price("guild", "ore", "time")

		assert_true(narrowed_price < full_price, "spread should narrow as relation climbs above the join threshold")
		assert_true(zero_spread_price < narrowed_price, "spread keeps narrowing toward relation 90")
		assert_eq(zero_spread_price, 60, "at relation 90 the spread is 0%, buy price == effective base price")
		assert_eq(beyond_zero_price, 60, "spread stays flat at 0% past relation 90, never negative")
	)

	run_case("guild_purchase_rejects_insufficient_cash", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 10
		var result := Economy.execute_faction_purchase("guild", [{ "kind": "ore", "type": "time", "qty": 5 }])
		assert_true(not result["ok"], "purchase should be rejected when cost exceeds cash")
		assert_eq(GameState.state["player"]["cash"], 10, "cash unchanged on rejected purchase")
		assert_eq(GameState.state["player"]["orichalchum"].get("time", 0), 0, "inventory unchanged on rejected purchase")
	)

	run_case("guild_purchase_deducts_cash_and_adds_inventory", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 1000
		var result := Economy.execute_faction_purchase("guild", [{ "kind": "ore", "type": "time", "qty": 3 }])
		assert_true(result["ok"], "purchase should succeed when cash covers cost")
		# price per unit 69 (see full-spread test above), qty 3 -> cost 207
		assert_eq(GameState.state["player"]["cash"], 1000 - 207, "cash reduced by total cost")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 3, "ore added to inventory")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "a Guild purchase records one bank transaction")
		assert_eq(bank_log[0]["amount"], -207, "the recorded amount is negative, matching the spend")
		assert_eq(bank_log[0]["label"], "Guild purchase", "the recorded label names the purchase -- generalization must not change the Guild's exact copy")
	)

	run_case("guild_sale_credits_cash_and_removes_inventory", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 100
		GameState.state["player"]["orichalchum"]["time"] = 5
		var result := Economy.execute_faction_sale("guild", [{ "kind": "ore", "type": "time", "qty": 2 }])
		assert_true(result["ok"], "sale should succeed")
		# price per unit 51 (see full-spread sell test above), qty 2 -> earned 102
		assert_eq(GameState.state["player"]["cash"], 100 + 102, "cash increased by total earned")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 3, "ore removed from inventory")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "a Guild sale records one bank transaction")
		assert_eq(bank_log[0]["amount"], 102, "the recorded amount matches total earned")
		assert_eq(bank_log[0]["label"], "Guild sale", "the recorded label names the sale -- generalization must not change the Guild's exact copy")
	)

	# ── The Collective lane (collective1-01 spec.md §8.1, §9.4): asymmetric spread, no district mod ─

	run_case("collective_sell_spread_matches_the_authoritative_curve_at_25_50_80", func():
		GameState.reset()
		# §8.1: sell spread 0.45 at relation 0 -> 0.05 at relation 90, anchored
		# at relation 0 (not joinRelation). Table's rates are the formula's
		# exact linear output, not the sketched approximations.
		GameState.state["factions"]["collective"]["relation"] = 25
		assert_almost_eq(1.0 - Economy.get_faction_sell_spread("collective"), 0.66, 0.005, "relation 25 -> ~0.66x sell rate")
		GameState.state["factions"]["collective"]["relation"] = 50
		assert_almost_eq(1.0 - Economy.get_faction_sell_spread("collective"), 0.77, 0.005, "relation 50 -> ~0.77x sell rate")
		GameState.state["factions"]["collective"]["relation"] = 80
		assert_almost_eq(1.0 - Economy.get_faction_sell_spread("collective"), 0.91, 0.005, "relation 80 -> ~0.91x sell rate")
	)

	run_case("collective_sell_spread_anchors_at_relation_zero_not_joinRelation", func():
		GameState.reset()
		# Guild anchors at joinRelation (40) and clamps to max spread below it.
		# The Collective anchors at 0 -- its spread is already narrowing at
		# relation 1, unlike the Guild's flat-below-anchor behaviour.
		GameState.state["factions"]["collective"]["relation"] = 0
		var spread_at_zero := Economy.get_faction_sell_spread("collective")
		assert_eq(spread_at_zero, 0.45, "relation 0 is the anchor -- full 0.45 spread")

		GameState.state["factions"]["collective"]["relation"] = 1
		var spread_at_one := Economy.get_faction_sell_spread("collective")
		assert_true(spread_at_one < spread_at_zero, "spread should already be narrowing just past relation 0")
	)

	run_case("collective_sell_spread_floors_at_005_not_zero", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 90
		assert_eq(Economy.get_faction_sell_spread("collective"), 0.05, "spread floors at 0.05 at relation 90")
		GameState.state["factions"]["collective"]["relation"] = 200
		assert_eq(Economy.get_faction_sell_spread("collective"), 0.05, "spread stays flat at 0.05 past relation 90, never reaching 0")
	)

	run_case("collective_buy_spread_is_decoupled_from_sell_spread", func():
		GameState.reset()
		# At relation 0: sell spread 0.45, buy spread only 0.15 -- the
		# Collective marks its own buy prices up far less than it discounts
		# its own sell prices, per §8.1's "they do not gouge their own".
		GameState.state["factions"]["collective"]["relation"] = 0
		assert_eq(Economy.get_faction_sell_spread("collective"), 0.45, "sell spread at relation 0")
		assert_eq(Economy.get_faction_buy_spread("collective"), 0.15, "buy spread at relation 0 is a separate, narrower curve")
	)

	run_case("collective_lane_ignores_district_priceMod", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 0
		GameState.state["world"]["currentDistrict"] = "city"  # priceMod +0.15
		var price_in_city := Economy.get_faction_sell_price("collective", "ore", "time")

		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 0
		GameState.state["world"]["currentDistrict"] = "camden"  # priceMod -0.05
		var price_in_camden := Economy.get_faction_sell_price("collective", "ore", "time")

		assert_eq(price_in_city, price_in_camden, "Collective lane prices must not vary by district, unlike the Archie lane")
	)

	run_case("collective_purchase_and_sale_round_trip_at_its_own_spread", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 0
		GameState.state["player"]["cash"] = 1000
		# time basePrice 60, stable barometer -> 60; buy spread 0.15 -> 69
		var result := Economy.execute_faction_purchase("collective", [{ "kind": "ore", "type": "time", "qty": 1 }])
		assert_true(result["ok"], "purchase should succeed")
		assert_eq(GameState.state["player"]["cash"], 1000 - 69, "cash reduced by the Collective's own buy price")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log[0]["label"], "Collective purchase", "faction_id.capitalize() names the lane in the bank log")

		GameState.state["player"]["cash"] = 100
		# sell spread 0.45 at relation 0 -> 60 * 0.55 = 33
		var sale_result := Economy.execute_faction_sale("collective", [{ "kind": "ore", "type": "time", "qty": 1 }])
		assert_true(sale_result["ok"], "sale should succeed")
		assert_eq(GameState.state["player"]["cash"], 100 + 33, "cash increased by the Collective's own sell price")
	)

	# ── Archie's relation-scaled cut (collective1-01 spec.md §8.2, R§3.6 amendment) ─

	run_case("archie_cut_ratio_matches_the_confirmed_curve_at_10_40_80", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["relation"] = 10
		assert_almost_eq(Economy.get_archie_cut_ratio(), 0.60, 0.0001, "relation 10 (start) -> 0.60x cut")
		GameState.state["contacts"]["archie"]["relation"] = 40
		assert_almost_eq(Economy.get_archie_cut_ratio(), 0.71, 0.005, "relation 40 -> ~0.71x cut")
		GameState.state["contacts"]["archie"]["relation"] = 80
		assert_almost_eq(Economy.get_archie_cut_ratio(), 0.85, 0.0001, "relation 80 (recruit threshold) -> 0.85x cut")
	)

	run_case("archie_cut_ratio_is_flat_outside_the_10_to_80_range", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["relation"] = 0
		assert_almost_eq(Economy.get_archie_cut_ratio(), 0.60, 0.0001, "below relation 10, cut stays flat at 0.60x")
		GameState.state["contacts"]["archie"]["relation"] = 100
		assert_almost_eq(Economy.get_archie_cut_ratio(), 0.85, 0.0001, "above relation 80, cut stays flat at 0.85x")
	)

	run_case("archie_sale_cut_uses_the_relation_scaled_ratio_not_a_flat_50_percent", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["contacts"]["archie"]["relation"] = 80  # 0.85x cut
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# time basePrice 60, stable barometer -> gross = 180; cut = floor(180*0.85) = 153
		assert_eq(GameState.state["player"]["cash"], 40 + 153, "playerCut reflects Archie's relation-scaled cut, not a flat 50%")
	)
