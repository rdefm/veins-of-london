extends "res://tests/test_base.gd"

# M1-LONDON D5/D9 — the 15 real district events, plus the new engine
# primitives ticket 09 needed to express their mechanics: the "chance" op,
# start_street_mugging (event_mugging combat context), npc_claim_best_
# unclaimed_site, and lose_time_block. Deck filter/weight/no-repeat
# plumbing itself stays covered by tests/test_district_deck.gd's synthetic
# entries — this file is about the real content's own effects.


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


static func _make_site(id: String, district: String, tier: String, discovered_day: int, claimed: bool = false, faction_claimed: bool = false, ore_type: String = "time") -> Dictionary:
	return {
		"id": id, "district": district, "tier": tier, "oreType": ore_type,
		"bonuses": [], "discoveredDay": discovered_day,
		"claimed": claimed, "factionVein": { "id": "fv_dummy", "factionId": "collective", "oreType": ore_type, "growth": 20, "rampantDays": 0, "security": "none", "claimedOnDay": discovered_day } if faction_claimed else null,
		"hasNaturalVein": false,
	}


# Drives an event from start up to (not including) its choice card, calling
# only advance() — no effects fire yet. Returns the choice card's index so
# callers know how many advance() calls remain after choose().
func _play_to_choice(event_id: String) -> int:
	Events.start_event(event_id)
	var cards: Array = GameData.EVENTS[event_id]["cards"]
	var choice_index := -1
	for i in range(cards.size()):
		if cards[i]["type"] == "choice":
			choice_index = i
			break
	for i in range(choice_index):
		Events.advance()
	return choice_index


# Finishes an event after its choice has been resolved via choose().
func _finish_after_choice(event_id: String, choice_index: int) -> void:
	var remaining: int = GameData.EVENTS[event_id]["cards"].size() - choice_index
	for i in range(remaining):
		Events.advance()


func _play_full(event_id: String) -> void:
	Events.start_event(event_id)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


func run() -> void:
	# ── new effect ops (isolated from any specific event content) ────────

	run_case("chance_op_takes_on_success_branch_when_p_is_1", func():
		GameState.reset()
		var cash_before: int = GameState.state["player"]["cash"]
		Events.apply_effects([{ "op": "chance", "p": 1.0, "on_success": [{ "op": "add", "path": "player.cash", "value": 5 }], "on_fail": [{ "op": "add", "path": "player.cash", "value": -5 }] }])
		assert_eq(GameState.state["player"]["cash"], cash_before + 5, "p=1.0 should always take on_success")
	)

	run_case("chance_op_takes_on_fail_branch_when_p_is_0", func():
		GameState.reset()
		var cash_before: int = GameState.state["player"]["cash"]
		Events.apply_effects([{ "op": "chance", "p": 0.0, "on_success": [{ "op": "add", "path": "player.cash", "value": 5 }], "on_fail": [{ "op": "add", "path": "player.cash", "value": -5 }] }])
		assert_eq(GameState.state["player"]["cash"], cash_before - 5, "p=0.0 should always take on_fail")
	)

	run_case("start_street_mugging_op_launches_event_mugging_combat", func():
		GameState.reset()
		Events.apply_effects([{ "op": "start_street_mugging" }])
		assert_true(GameState.state["combat"]["active"], "should launch combat")
		assert_eq(GameState.state["combat"]["context"], "event_mugging")
		assert_eq(GameState.state["combat"]["onWin"], "", "no dispatch — there's no sale to settle")
	)

	run_case("exit_combat_routes_event_mugging_back_to_the_event_screen_regardless_of_outcome", func():
		for outcome in ["win", "loss", "fled"]:
			GameState.reset()
			Events.apply_effects([{ "op": "start_street_mugging" }])
			GameState.state["combat"]["outcome"] = outcome
			var result := Combat.exit_combat()
			assert_eq(result["nextScreen"], "event", "outcome '%s' should still route back to the event" % outcome)
			assert_eq(GameState.state["currentScreen"], "event")
	)

	run_case("npc_claim_best_unclaimed_site_op_claims_the_best_site_in_the_current_district", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		GameState.state["world"]["sites"] = [
			_make_site("poor1", "camden", "poor", 1),
			_make_site("rich1", "camden", "rich", 1),
		]
		Events.apply_effects([{ "op": "npc_claim_best_unclaimed_site" }])
		assert_true(Sites.find_site("rich1")["factionVein"] != null, "the higher-tier site should be claimed")
		assert_eq(Sites.find_site("poor1")["factionVein"], null, "the lower-tier site is untouched")

		var vein: Dictionary = Sites.find_site("rich1")["factionVein"]
		var event = MapEvents.current()
		assert_eq(event["type"], "seed_claim", "the instant claim queues a map-animations seed/claim event (ticket 02)")
		assert_eq(event["district"], "camden")
		assert_eq(event["veinId"], vein["id"])
		assert_eq(event["owner"], vein["factionId"])

		var queue: Array = GameState.state["mapEvents"]["queue"]
		assert_eq(queue.size(), 2, "the seed_claim ring is followed by its own join_line event (ticket 05)")
		assert_eq(queue[1]["type"], "join_line")
		assert_eq(queue[1]["veinId"], vein["id"])
		assert_eq(queue[1]["owner"], vein["factionId"])
	)

	run_case("npc_claim_best_unclaimed_site_op_is_a_no_op_with_nothing_unclaimed", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		Events.apply_effects([{ "op": "npc_claim_best_unclaimed_site" }])
		assert_eq(GameState.state["world"]["sites"], [], "nothing to claim, nothing crashes")
	)

	run_case("lose_time_block_op_advances_exactly_one_block", func():
		GameState.reset()
		Events.apply_effects([{ "op": "lose_time_block" }])
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1)
	)

	run_case("lose_time_block_op_is_a_no_op_once_the_day_is_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var day_before: int = GameState.state["world"]["day"]
		Events.apply_effects([{ "op": "lose_time_block" }])
		assert_eq(GameState.state["world"]["day"], day_before, "must not force a day rollover")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [0, 1, 2])
	)

	# ── Sites: busker_greenwich's greenwichTipOff consumption (D5 #1) ────

	run_case("greenwich_tip_off_is_only_consumed_by_a_greenwich_roll", func():
		GameState.reset()
		GameState.state["flags"]["greenwichTipOff"] = true
		Sites.roll_tier("camden")
		assert_true(GameState.state["flags"]["greenwichTipOff"], "a different district's roll must not consume it")
		Sites.roll_tier("greenwich")
		assert_true(not GameState.state["flags"]["greenwichTipOff"], "a greenwich roll consumes it")
	)

	run_case("greenwich_tip_off_meaningfully_raises_rich_frequency", func():
		var rich_with := 0
		var rich_without := 0
		for seed in range(300):
			GameState.reset()
			GameState.state["flags"]["greenwichTipOff"] = true
			Rng.set_seed(seed)
			if Sites.roll_tier("greenwich") == "rich":
				rich_with += 1
		for seed in range(300):
			GameState.reset()
			Rng.set_seed(seed)
			if Sites.roll_tier("greenwich") == "rich":
				rich_without += 1
		assert_true(rich_with > rich_without, "the +10 rich weight tip-off should draw noticeably more rich tiers (with=%d, without=%d)" % [rich_with, rich_without])
	)

	# ── Economy: pigeon_omen's luckyOmen consumption (D5 #11) ────────────

	run_case("lucky_omen_consumed_on_next_sale_and_can_apply_a_10pct_bump", func():
		# collective1-01: execute_sale awards ARCHIE_SALE_RELATION_GAIN (+2)
		# *before* computing the cut, so Archie's startRelation 10 becomes 12
		# by cut time -> ratio 0.60 + 0.25*(12-10)/70 = 0.6071428571.
		var seed := _find_seed_for(500, func():
			GameState.reset()
			GameState.state["flags"]["luckyOmen"] = true
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return not result.get("mugged", true) and GameState.state["player"]["cash"] > 40 + 109
		)
		assert_true(seed != -1, "should find a seed where the omen hits and the sale isn't mugged, within 500 tries")
		assert_true(not GameState.state["flags"]["luckyOmen"], "the flag is consumed regardless of the coin flip")
		# time basePrice 60 * 1.10 = 66/unit, qty 3 -> gross 198, cut floor(198*0.6071428571) = 120
		assert_eq(GameState.state["player"]["cash"], 40 + 120, "the +10% bump should be reflected in the payout")
	)

	run_case("lucky_omen_consumed_even_when_the_coin_flip_misses", func():
		# No-bump gross 180 at post-award relation 12 -> cut floor(180*0.6071428571) = 109.
		var seed := _find_seed_for(500, func():
			GameState.reset()
			GameState.state["flags"]["luckyOmen"] = true
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return not result.get("mugged", true) and GameState.state["player"]["cash"] == 40 + 109
		)
		assert_true(seed != -1, "should find a seed where the omen misses, within 500 tries")
		assert_true(not GameState.state["flags"]["luckyOmen"], "the flag is consumed even on a miss")
	)

	# ── busker_greenwich (D5 #1) ──────────────────────────────────────────

	run_case("busker_greenwich_give_20_pays_grants_ore_tip_off_and_stays_redrawable", func():
		GameState.reset()
		var cash_before: int = GameState.state["player"]["cash"]
		var choice_index := _play_to_choice("busker_greenwich")
		Events.choose(0)  # Give him £20
		assert_eq(GameState.state["player"]["cash"], cash_before - 20)
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 1)
		assert_true(GameState.state["flags"]["greenwichTipOff"])
		_finish_after_choice("busker_greenwich", choice_index)
		assert_eq(GameState.state["event"], null)
	)

	run_case("busker_greenwich_walk_away_costs_nothing", func():
		GameState.reset()
		var cash_before: int = GameState.state["player"]["cash"]
		var choice_index := _play_to_choice("busker_greenwich")
		Events.choose(1)  # Keep walking
		assert_eq(GameState.state["player"]["cash"], cash_before)
		assert_true(not GameState.state["flags"]["greenwichTipOff"])
		_finish_after_choice("busker_greenwich", choice_index)
	)

	# ── city_suit (D5 #2) ─────────────────────────────────────────────────

	run_case("city_suit_trade_always_costs_200_and_can_succeed_for_8_fate_ore", func():
		var seed := _find_seed_for(300, func():
			GameState.reset()
			var choice_index := _play_to_choice("city_suit")
			Events.choose(0)  # Trade (£200)
			return GameState.state["player"]["orichalchum"].get("fate", 0) == 8
		)
		assert_true(seed != -1, "should find a success within 300 tries")
		assert_eq(GameState.state["player"]["cash"], 40 - 200, "the £200 is spent regardless of the roll")
	)

	run_case("city_suit_trade_can_also_fail_for_nothing", func():
		var seed := _find_seed_for(300, func():
			GameState.reset()
			var choice_index := _play_to_choice("city_suit")
			Events.choose(0)
			return GameState.state["player"]["orichalchum"].get("fate", 0) == 0
		)
		assert_true(seed != -1, "should find a failure within 300 tries")
		assert_eq(GameState.state["player"]["cash"], 40 - 200)
	)

	run_case("city_suit_pass_spends_nothing", func():
		GameState.reset()
		var choice_index := _play_to_choice("city_suit")
		Events.choose(1)  # Pass
		assert_eq(GameState.state["player"]["cash"], 40)
		assert_eq(GameState.state["player"]["orichalchum"].get("fate", 0), 0)
	)

	# ── camden_shakedown (D5 #3) ──────────────────────────────────────────

	run_case("camden_shakedown_pay_deducts_50_and_never_starts_combat", func():
		GameState.reset()
		var choice_index := _play_to_choice("camden_shakedown")
		Events.choose(0)  # Pay £50
		assert_eq(GameState.state["player"]["cash"], 40 - 50)
		assert_true(not GameState.state["combat"]["active"])
		_finish_after_choice("camden_shakedown", choice_index)
		assert_eq(GameState.state["event"], null)
	)

	run_case("camden_shakedown_refuse_can_trigger_a_street_mugging", func():
		var seed := _find_seed_for(300, func():
			GameState.reset()
			var choice_index := _play_to_choice("camden_shakedown")
			Events.choose(1)  # Refuse
			return GameState.state["combat"]["active"]
		)
		assert_true(seed != -1, "should find a mugging hit within 300 tries at p=0.4")
		assert_eq(GameState.state["combat"]["context"], "event_mugging")
		assert_eq(GameState.state["player"]["cash"], 40, "refusing costs no cash up front")
	)

	run_case("camden_shakedown_refuse_can_also_walk_away_clean", func():
		var seed := _find_seed_for(300, func():
			GameState.reset()
			var choice_index := _play_to_choice("camden_shakedown")
			Events.choose(1)
			return not GameState.state["combat"]["active"]
		)
		assert_true(seed != -1, "should find a non-mugging miss within 300 tries")
		assert_eq(GameState.state["player"]["cash"], 40)
	)

	# ── heath_dogwalker (D5 #4) ───────────────────────────────────────────

	run_case("heath_dogwalker_grants_2_life_ore", func():
		GameState.reset()
		_play_full("heath_dogwalker")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 2)
		assert_eq(GameState.state["event"], null)
	)

	# ── whitechapel_grief (D5 #5) ─────────────────────────────────────────

	run_case("whitechapel_grief_grants_1_emotion_ore", func():
		GameState.reset()
		_play_full("whitechapel_grief")
		assert_eq(GameState.state["player"]["orichalchum"]["emotion"], 1)
	)

	# ── kx_delay (D5 #6) ──────────────────────────────────────────────────

	run_case("kx_delay_wait_it_out_burns_an_extra_time_block", func():
		GameState.reset()
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var choice_index := _play_to_choice("kx_delay")
		Events.choose(0)  # Wait it out
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before + 1)
		assert_eq(GameState.state["player"]["cash"], 40, "waiting costs no cash")
		_finish_after_choice("kx_delay", choice_index)
	)

	run_case("kx_delay_cab_costs_30_and_no_extra_block", func():
		GameState.reset()
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var choice_index := _play_to_choice("kx_delay")
		Events.choose(1)  # Pay for a cab
		assert_eq(GameState.state["player"]["cash"], 40 - 30)
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before)
		_finish_after_choice("kx_delay", choice_index)
	)

	# ── soho_tout (D5 #7) ─────────────────────────────────────────────────

	run_case("soho_tout_is_flavour_only", func():
		GameState.reset()
		var snapshot: Dictionary = GameState.deep_copy(GameState.state["player"])
		_play_full("soho_tout")
		assert_eq(GameState.state["player"], snapshot, "no mechanical effects at all")
		assert_eq(GameState.state["event"], null)
	)

	# ── battersea_hum (D5 #8) ─────────────────────────────────────────────

	run_case("battersea_hum_grants_1_physics_ore", func():
		GameState.reset()
		_play_full("battersea_hum")
		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 1)
	)

	# ── shoreditch_archie (D5 #9) ─────────────────────────────────────────

	run_case("shoreditch_archie_grants_relation_2", func():
		GameState.reset()
		var relation_before: int = GameState.state["contacts"]["archie"]["relation"]
		_play_full("shoreditch_archie")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], relation_before + 2)
	)

	# ── conclave_watch (D5 #10) ───────────────────────────────────────────

	run_case("conclave_watch_sets_conclaveNoticed_and_then_excludes_itself", func():
		GameState.reset()
		var ids_before: Array = []
		for e in DistrictDeck.eligible_entries("city"):
			ids_before.append(e["id"])
		assert_true(ids_before.has("conclave_watch"), "eligible before it's been seen")

		_play_full("conclave_watch")
		assert_true(GameState.state["flags"]["conclaveNoticed"])

		var ids_after: Array = []
		for e in DistrictDeck.eligible_entries("city"):
			ids_after.append(e["id"])
		assert_true(not ids_after.has("conclave_watch"), "excludes itself once conclaveNoticed is true")
	)

	# ── pigeon_omen (D5 #11) ──────────────────────────────────────────────

	run_case("pigeon_omen_sets_luckyOmen", func():
		GameState.reset()
		_play_full("pigeon_omen")
		assert_true(GameState.state["flags"]["luckyOmen"])
	)

	run_case("busker_and_pigeon_remain_drawable_after_their_one_shot_flag_fires", func():
		GameState.reset()
		GameState.state["flags"]["greenwichTipOff"] = true
		GameState.state["flags"]["luckyOmen"] = true

		var greenwich_ids: Array = []
		for e in DistrictDeck.eligible_entries("greenwich"):
			greenwich_ids.append(e["id"])
		assert_true(greenwich_ids.has("busker_greenwich"), "busker_greenwich has no excludeIfFlag — it stays redrawable")

		var any_ids: Array = []
		for e in DistrictDeck.eligible_entries("shoreditch"):
			any_ids.append(e["id"])
		assert_true(any_ids.has("pigeon_omen"), "pigeon_omen has no excludeIfFlag — it stays redrawable")
	)

	# ── rain (D5 #12) ─────────────────────────────────────────────────────

	run_case("rain_is_flavour_only", func():
		GameState.reset()
		var snapshot: Dictionary = GameState.deep_copy(GameState.state["player"])
		_play_full("rain")
		assert_eq(GameState.state["player"], snapshot)
	)

	# ── rival_prospector (D5 #13) ─────────────────────────────────────────

	run_case("rival_prospector_pay_off_costs_100_and_touches_no_sites", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		GameState.state["world"]["sites"] = [_make_site("s1", "camden", "rich", 1)]
		var choice_index := _play_to_choice("rival_prospector")
		Events.choose(0)  # Pay them off
		assert_eq(GameState.state["player"]["cash"], 40 - 100)
		assert_eq(Sites.find_site("s1")["factionVein"], null)
		_finish_after_choice("rival_prospector", choice_index)
	)

	run_case("rival_prospector_let_them_have_it_faction_claims_the_best_unclaimed_site", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		GameState.state["world"]["sites"] = [
			_make_site("poor1", "camden", "poor", 1),
			_make_site("rich1", "camden", "rich", 1),
		]
		var choice_index := _play_to_choice("rival_prospector")
		Events.choose(1)  # Let them have it
		assert_eq(GameState.state["player"]["cash"], 40, "no payment on this branch")
		assert_true(Sites.find_site("rich1")["factionVein"] != null)
		assert_eq(Sites.find_site("poor1")["factionVein"], null)
		_finish_after_choice("rival_prospector", choice_index)
	)

	run_case("rival_prospector_only_draws_in_a_district_with_an_unclaimed_site", func():
		GameState.reset()
		var camden_ids_before: Array = []
		for e in DistrictDeck.eligible_entries("camden"):
			camden_ids_before.append(e["id"])
		assert_true(not camden_ids_before.has("rival_prospector"), "no unclaimed sites anywhere — excluded per D5's 'with unclaimed sites' wording")

		GameState.state["world"]["sites"] = [_make_site("s1", "camden", "fair", 1)]
		var camden_ids_after: Array = []
		for e in DistrictDeck.eligible_entries("camden"):
			camden_ids_after.append(e["id"])
		assert_true(camden_ids_after.has("rival_prospector"), "camden now has an unclaimed site — eligible")

		var hampstead_ids: Array = []
		for e in DistrictDeck.eligible_entries("hampstead"):
			hampstead_ids.append(e["id"])
		assert_true(not hampstead_ids.has("rival_prospector"), "the site is in camden, not hampstead — still excluded there")
	)

	# ── foxes (D5 #14) ────────────────────────────────────────────────────

	run_case("foxes_is_flavour_only", func():
		GameState.reset()
		var snapshot: Dictionary = GameState.deep_copy(GameState.state["player"])
		_play_full("foxes")
		assert_eq(GameState.state["player"], snapshot)
	)

	# ── roman_brick (D5 #15) ──────────────────────────────────────────────

	run_case("roman_brick_increments_oddities_on_repeat_draws", func():
		GameState.reset()
		_play_full("roman_brick")
		assert_eq(GameState.state["flags"]["oddities"], 1)
		_play_full("roman_brick")
		assert_eq(GameState.state["flags"]["oddities"], 2, "repeat draws keep incrementing the counter")
	)
