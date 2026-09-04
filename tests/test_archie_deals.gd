extends "res://tests/test_base.gd"

# bugfixes-95: Archie's proactive tag-along deal offers. See
# .scratch/0-bugfixes/issues/95-archie-tag-along-deal-offers.md for the
# confirmed mechanics these cases check.


func run() -> void:
	# ── chance curve ──────────────────────────────────────────────────────

	run_case("roll_chance_matches_the_confirmed_curve_at_a_few_cash_points", func():
		assert_almost_eq(ArchieDeals.roll_chance(0), 1.0, 0.0001, "cash 0 -> 100% chance")
		assert_almost_eq(ArchieDeals.roll_chance(100), 0.982, 0.001, "cash 100 -> near-certain, not yet floored")
		assert_almost_eq(ArchieDeals.roll_chance(2500), 0.55, 0.0001, "cash 2500 (halfway to the £5000 ceiling) -> halfway between 1.0 and the 0.10 floor")
		assert_almost_eq(ArchieDeals.roll_chance(5000), 0.10, 0.0001, "cash 5000 -> the 10% floor")
	)

	run_case("roll_chance_floors_at_010_past_the_5000_ceiling", func():
		assert_almost_eq(ArchieDeals.roll_chance(5000), 0.10, 0.0001)
		assert_almost_eq(ArchieDeals.roll_chance(50000), 0.10, 0.0001, "chance never drops below the 10% floor, however rich the player gets")
	)

	# ── deal-size tier scaling ───────────────────────────────────────────

	run_case("deal_tier_scales_by_5000_of_cash_and_caps_at_TIER_MAX", func():
		assert_eq(ArchieDeals.deal_tier(0), 0)
		assert_eq(ArchieDeals.deal_tier(4999), 0, "just under the first step is still tier 0")
		assert_eq(ArchieDeals.deal_tier(5000), 1)
		assert_eq(ArchieDeals.deal_tier(24999), 4)
		assert_eq(ArchieDeals.deal_tier(30000), ArchieDeals.TIER_MAX, "tier caps at TIER_MAX rather than growing unbounded")
		assert_eq(ArchieDeals.deal_tier(999999), ArchieDeals.TIER_MAX, "far past the cap still reads as TIER_MAX, never higher")
	)

	run_case("roll_deal_quantity_stays_within_the_tier_scaled_5_to_25_range", func():
		GameState.reset()
		for seed in range(100):
			Rng.set_seed(seed)
			var deal := ArchieDeals.roll_deal(0)  # tier 0 -> scale 1
			assert_true(deal["qty"] >= 5 and deal["qty"] <= 25, "tier 0 qty should be 5-25, got %d" % deal["qty"])

		for seed in range(100):
			Rng.set_seed(seed)
			var deal := ArchieDeals.roll_deal(15000)  # tier 3 -> scale 8
			assert_true(deal["qty"] >= 40 and deal["qty"] <= 200, "tier 3 qty should be 40-200 (5*8 to 25*8), got %d" % deal["qty"])
	)

	run_case("roll_deal_picks_one_of_the_five_canonical_ore_types", func():
		GameState.reset()
		var seen: Dictionary = {}
		for seed in range(100):
			Rng.set_seed(seed)
			var deal := ArchieDeals.roll_deal(0)
			assert_true(GameData.ORE_TYPES.has(deal["oreType"]), "oreType should be one of the five canonical ore types, got %s" % deal["oreType"])
			seen[deal["oreType"]] = true
		assert_true(seen.size() > 1, "100 rolls should surface more than one ore type")
	)

	run_case("roll_deal_gross_and_playerCut_match_the_standard_market_formula", func():
		GameState.reset()  # shoreditch, stable barometer -- no price/danger mods
		Rng.set_seed(1)
		var deal := ArchieDeals.roll_deal(0)
		var base_price: int = GameData.ORE_TYPES[deal["oreType"]]["basePrice"]
		assert_eq(deal["gross"], base_price * deal["qty"], "gross = basePrice * qty with no barometer/district mods active")
		assert_eq(deal["playerCut"], int(floor(deal["gross"] * 0.5)), "playerCut is a flat floor(gross*0.5), not the relation-scaled Archie ratio")
	)

	# ── daily-tick roll gating ───────────────────────────────────────────

	run_case("roll_daily_offer_never_fires_before_archieMotionEventSeen", func():
		for seed in range(20):
			GameState.reset()
			GameState.state["flags"]["archieMotionEventSeen"] = false
			GameState.state["player"]["cash"] = 0  # would force an offer if the gate were missing
			Rng.set_seed(seed)
			ArchieDeals.roll_daily_offer()
			assert_eq(GameState.state["flags"]["archieDealActive"], false, "no offer should roll before archieMotionEventSeen, seed %d" % seed)
			assert_true(Messages.pending_for("archie").is_empty(), "no pending entry should be queued before archieMotionEventSeen, seed %d" % seed)
	)

	run_case("roll_daily_offer_skips_entirely_when_a_deal_is_already_active", func():
		GameState.reset()
		GameState.state["flags"]["archieMotionEventSeen"] = true
		GameState.state["flags"]["archieDealActive"] = true
		GameState.state["player"]["cash"] = 0  # would force an offer if the guard were missing
		for seed in range(10):
			Rng.set_seed(seed)
			ArchieDeals.roll_daily_offer()
		assert_true(Messages.pending_for("archie").is_empty(), "an active deal must not be clobbered by a fresh roll")
	)

	run_case("roll_daily_offer_at_zero_cash_eventually_queues_an_offer", func():
		var hit := false
		for seed in range(20):
			GameState.reset()
			GameState.state["flags"]["archieMotionEventSeen"] = true
			GameState.state["player"]["cash"] = 0
			Rng.set_seed(seed)
			ArchieDeals.roll_daily_offer()
			if GameState.state["flags"]["archieDealActive"]:
				hit = true
				assert_eq(Messages.pending_for("archie").size(), 1, "should queue exactly one pending entry")
				assert_eq(Messages.pending_for("archie")[0]["kind"], ArchieDeals.PENDING_KIND, "pending entry should be an archie_deal offer")
				break
		assert_true(hit, "cash 0 -> 100% chance, should trigger within 20 seeds")
	)

	run_case("roll_daily_offer_touches_no_player_ore_or_cash", func():
		GameState.reset()
		GameState.state["flags"]["archieMotionEventSeen"] = true
		GameState.state["player"]["cash"] = 0
		var ore_before: Dictionary = GameState.deep_copy(GameState.state["player"]["orichalchum"])
		Rng.set_seed(1)
		ArchieDeals.roll_daily_offer()
		assert_eq(GameState.state["player"]["cash"], 0, "the offer itself must not touch cash")
		assert_eq(GameState.state["player"]["orichalchum"], ore_before, "the offer itself must not touch ore")
	)

	# ── decline ───────────────────────────────────────────────────────────

	run_case("decline_deal_clears_active_flag_resolves_pending_and_docks_relation", func():
		GameState.reset()
		GameState.state["flags"]["archieDealActive"] = true
		Messages.queue_pending("archie", ArchieDeals.PENDING_KIND, "Fancy tagging along for a cut?")
		var entry: Dictionary = Messages.pending_for("archie")[0]
		var relation_before: int = GameState.state["contacts"]["archie"]["relation"]
		var cash_before: int = GameState.state["player"]["cash"]

		ArchieDeals.decline_deal(entry["id"])

		assert_eq(GameState.state["flags"]["archieDealActive"], false, "archieDealActive cleared")
		assert_true(Messages.pending_for("archie").is_empty(), "pending entry resolved")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], relation_before + ArchieDeals.DECLINE_RELATION_LOSS, "declining docks relation")
		assert_eq(GameState.state["player"]["cash"], cash_before, "declining touches no cash")
	)

	# ── accept: non-mugged path ──────────────────────────────────────────

	run_case("accept_deal_non_mugged_pays_flat_50_50_split_and_awards_relation", func():
		var seed := -1
		var snapshot: Dictionary
		for candidate in range(300):
			GameState.reset()
			GameState.state["flags"]["archieDealActive"] = true
			Messages.queue_pending("archie", ArchieDeals.PENDING_KIND, "Fancy tagging along for a cut?")
			snapshot = GameState.deep_copy(GameState.state)
			Rng.set_seed(candidate)
			var entry: Dictionary = Messages.pending_for("archie")[0]
			ArchieDeals.accept_deal(entry["id"])
			if not GameState.state["combat"]["active"]:
				seed = candidate
				break
			GameState.state = snapshot
		assert_true(seed != -1, "should find a non-mugged roll within 300 tries")

		assert_eq(GameState.state["flags"]["archieDealActive"], false, "archieDealActive cleared once the deal resolves")
		assert_eq(GameState.state["modal"]["type"], "archie_deal_result", "a non-mugged accept should open archie_deal_result")
		assert_eq(GameState.state["modal"]["data"]["mugged"], false)
		var earned: int = GameState.state["modal"]["data"]["earned"]
		assert_eq(GameState.state["player"]["cash"], 40 + earned, "cash increases by the paid-out cut")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], 10 + ArchieDeals.DEAL_RELATION_GAIN, "accepting awards the flat relation gain")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "a non-mugged accept records one bank transaction")
		assert_eq(bank_log[0]["amount"], earned)
		assert_eq(bank_log[0]["label"], "Archie tag-along deal")
	)

	run_case("accept_deal_touches_no_player_ore", func():
		var seed := -1
		var snapshot: Dictionary
		for candidate in range(300):
			GameState.reset()
			GameState.state["flags"]["archieDealActive"] = true
			GameState.state["player"]["orichalchum"]["time"] = 5
			Messages.queue_pending("archie", ArchieDeals.PENDING_KIND, "Fancy tagging along for a cut?")
			snapshot = GameState.deep_copy(GameState.state)
			Rng.set_seed(candidate)
			var entry: Dictionary = Messages.pending_for("archie")[0]
			ArchieDeals.accept_deal(entry["id"])
			if not GameState.state["combat"]["active"]:
				seed = candidate
				break
			GameState.state = snapshot
		assert_true(seed != -1, "should find a non-mugged roll within 300 tries")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5, "the deal is Archie's own stock -- player ore is never touched")
	)

	# ── accept: mugged path (win/loss + always-ally) ─────────────────────

	run_case("accept_deal_mugged_defers_payout_to_pendingArchieDealCut_and_archie_always_joins", func():
		var seed := -1
		for candidate in range(300):
			GameState.reset()
			assert_true(not GameState.state["contacts"]["archie"]["recruited"], "sanity: not recruited by default")
			GameState.state["flags"]["archieDealActive"] = true
			Messages.queue_pending("archie", ArchieDeals.PENDING_KIND, "Fancy tagging along for a cut?")
			Rng.set_seed(candidate)
			var entry: Dictionary = Messages.pending_for("archie")[0]
			ArchieDeals.accept_deal(entry["id"])
			if GameState.state["combat"]["active"]:
				seed = candidate
				break
		assert_true(seed != -1, "should find a mugged roll within 300 tries")

		assert_eq(GameState.state["player"]["cash"], 40, "cash should NOT increase yet -- payout is deferred")
		assert_true(GameState.state["pendingArchieDealCut"] > 0, "pendingArchieDealCut should hold the computed cut")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_ARCHIE_DEAL_MUGGING)

		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join regardless of the recruited/kit/KO-cooldown gate")
		assert_eq(allies[0]["contactId"], "archie")
	)

	run_case("archie_deal_mugging_win_pays_out_and_clears_active_flag", func():
		GameState.reset()
		GameState.state["pendingArchieDealCut"] = 90
		GameState.state["flags"]["archieDealActive"] = true
		GameState.state["player"]["cash"] = 100

		ArchieDeals.resolve_mugging(true)

		assert_eq(GameState.state["player"]["cash"], 190, "pendingArchieDealCut credited on a won mugging")
		assert_eq(GameState.state["pendingArchieDealCut"], 0, "cleared after payout")
		assert_eq(GameState.state["flags"]["archieDealActive"], false, "archieDealActive cleared so the next day can roll again")
		assert_eq(GameState.state["modal"]["type"], "archie_deal_result")
		assert_eq(GameState.state["modal"]["data"]["mugged"], true)
		assert_eq(GameState.state["modal"]["data"]["earned"], 90)

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1)
		assert_eq(bank_log[0]["amount"], 90)
		assert_eq(bank_log[0]["label"], "Archie tag-along deal (contested)")
	)

	run_case("archie_deal_mugging_loss_pays_nothing_no_further_relation_hit_but_clears_active_flag", func():
		GameState.reset()
		GameState.state["pendingArchieDealCut"] = 90
		GameState.state["flags"]["archieDealActive"] = true
		GameState.state["player"]["cash"] = 100
		var relation_before: int = GameState.state["contacts"]["archie"]["relation"]

		ArchieDeals.resolve_mugging(false)

		assert_eq(GameState.state["player"]["cash"], 100, "a lost mugging pays neither party")
		assert_eq(GameState.state["pendingArchieDealCut"], 0, "cleared even on a loss")
		assert_eq(GameState.state["flags"]["archieDealActive"], false, "archieDealActive cleared so the next day can roll again")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], relation_before, "no further relation change beyond what accepting itself already applied")
		assert_eq(GameState.state["modal"], null, "a lost mugging opens no result modal")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 0, "no bank transaction on a lost mugging")
	)
