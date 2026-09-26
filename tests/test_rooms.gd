extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

func run() -> void:
	run_case("staff_block_is_a_no_op_without_staff", func():
		GameState.reset()
		GameState.state["labThresholds"]["timePearl"] = 5
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["player"]["orichalchum"]["time"] = 1000
		var output: Dictionary = Rooms.process_staff_block()
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "no producer -> nothing happens")
		assert_eq(output, { "ore": {}, "items": {} })
	)

	run_case("producer_makes_one_attempt_per_block_and_idles_when_ore_is_short", func():
		GameState.reset()
		_staff_lab("archie", 1)
		GameState.state["labThresholds"]["timePearl"] = 1000  # unreachable target
		# timePearl calcCost at skill 1 = baseCalcCost = 5. Exactly 3 attempts' worth.
		GameState.state["player"]["orichalchum"]["time"] = 15
		Rng.set_seed(1)
		Rooms.process_staff_block()
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 10, "one attempt per block")
		_run_blocks(3)
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 0, "3 attempts spend it all; the 4th block idles on short ore")
	)

	run_case("producer_crafts_to_threshold_and_then_idles", func():
		GameState.reset()
		_staff_lab("archie", 3)
		GameState.state["labThresholds"]["timePearl"] = 2
		GameState.state["player"]["orichalchum"]["time"] = 10000  # ore never the bottleneck here
		Rng.set_seed(7)
		_run_blocks(30)
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "should stop exactly at the threshold, never overshoot")
	)

	run_case("producer_skips_recipes_not_yet_unlocked", func():
		GameState.reset()
		_staff_lab("archie", 1)
		GameState.state["flags"]["craftingUnlocked"] = false
		GameState.state["flags"]["enhancementUnlocked"] = false
		GameState.state["labThresholds"]["timePearl"] = 5
		GameState.state["labThresholds"]["enhancementPowder"] = 5
		GameState.state["player"]["orichalchum"] = { "time": 1000, "life": 1000 }
		_run_blocks(3)
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "timePearl gated by craftingUnlocked")
		assert_eq(Crafting.inventory_qty("enhancementPowder"), 0, "enhancementPowder gated by enhancementUnlocked")
	)

	run_case("each_producer_makes_its_own_attempt_per_block", func():
		GameState.reset()
		_staff_lab("archie", 1)
		GameState.state["contacts"]["james"]["recruited"] = true
		GameState.state["flags"]["bizJamesProductionRole"] = true
		assert_true(Contacts.set_role("james", "production")["ok"])
		GameState.state["labThresholds"]["timePearl"] = 1000
		GameState.state["player"]["orichalchum"]["time"] = 100
		Rng.set_seed(1)
		Rooms.process_staff_block()
		var james_skill: int = GameState.state["contacts"]["james"]["craftingSkill"]
		var expected: int = Crafting.calc_cost("timePearl", 1)["time"] + Crafting.calc_cost("timePearl", james_skill)["time"]
		assert_eq(100 - GameState.state["player"]["orichalchum"]["time"], expected, "two producers, two attempts")
	)

	run_case("an_unpaid_room_hire_does_not_act", func():
		GameState.reset()
		_staff_lab("des", 1)  # a room hire; founders draw no daily wage
		GameState.state["payroll"]["paidToday"] = { "lab": false }
		GameState.state["labThresholds"]["timePearl"] = 5
		GameState.state["player"]["orichalchum"]["time"] = 100
		Rooms.process_staff_block()
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 100)
	)

	run_case("effective_lab_target_adds_contract_need_only_when_covering", func():
		GameState.reset()
		GameState.state["labThresholds"]["timePearl"] = 5
		var created: Dictionary = Offers.create_offer({ "id": "t1", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 10 } })
		Offers.accept_offer(created["offer"]["id"])
		assert_eq(Rooms.effective_lab_target("timePearl"), 5, "toggle off -- personal target only, contract need ignored")
		Rooms.set_lab_cover_contracts("timePearl", true)
		assert_eq(Rooms.effective_lab_target("timePearl"), 15, "toggle on -- additive (5 personal + 10 contract need)")
	)

	run_case("production_reserved_qty_protects_only_the_personal_target_while_covering", func():
		GameState.reset()
		GameState.state["labThresholds"]["timePearl"] = 5
		assert_eq(Rooms.production_reserved_qty("timePearl"), 0, "no reserve while the toggle is off")
		Rooms.set_lab_cover_contracts("timePearl", true)
		assert_eq(Rooms.production_reserved_qty("timePearl"), 5, "reserve equals the personal target once covering, never the contract-need portion")
	)

	run_case("producer_ignores_contract_need_when_toggle_is_off", func():
		GameState.reset()
		_staff_lab("archie", 3)
		GameState.state["labThresholds"]["timePearl"] = 2
		GameState.state["player"]["orichalchum"]["time"] = 10000
		var created: Dictionary = Offers.create_offer({ "id": "t2", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 5 } })
		Offers.accept_offer(created["offer"]["id"])
		Rng.set_seed(7)
		_run_blocks(30)
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "toggle defaults off -- an active contract for the item must not inflate Production's target")
	)

	run_case("producer_crafts_toward_the_combined_personal_target_and_contract_need", func():
		GameState.reset()
		_staff_lab("archie", 6)
		GameState.state["labThresholds"]["timePearl"] = 2
		GameState.state["labCoverContracts"]["timePearl"] = true
		GameState.state["player"]["orichalchum"]["time"] = 10000
		var created: Dictionary = Offers.create_offer({ "id": "t3", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 3 } })
		Offers.accept_offer(created["offer"]["id"])
		Rng.set_seed(1)
		_run_blocks(60)
		assert_eq(Crafting.inventory_qty("timePearl"), 5, "reaches the combined target (2 personal + 3 contract need), no further")
	)

	run_case("producer_orders_scarce_shared_ore_by_contract_priority_then_by_personal_target", func():
		GameState.reset()
		_staff_lab("archie", 1)
		GameState.state["labCoverContracts"]["timePearl"] = true
		GameState.state["labCoverContracts"]["rewind"] = true
		# timePearl costs 5 "time" ore/attempt, rewind costs 6, both at skill 1.
		GameState.state["player"]["orichalchum"]["time"] = 13
		var pearl_offer: Dictionary = Offers.create_offer({ "id": "t4_pearl", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 1000 } })
		Offers.accept_offer(pearl_offer["offer"]["id"])
		var rewind_offer: Dictionary = Offers.create_offer({ "id": "t4_rewind", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "rewind", "qty": 1000 } })
		var rewind_contract: Dictionary = Offers.accept_offer(rewind_offer["offer"]["id"])["contract"]
		# Move rewind's contract to the front so its recipe gets first pick of
		# the shared "time" ore -- order tracks sales.priorityOrder, not
		# GameData.RECIPES.keys()'s fixed data order.
		Contracts.reorder(rewind_contract["id"], 0)
		Rooms.process_staff_block()
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 7, "the higher-priority contract's recipe (rewind, 6) goes first")
		_run_blocks(2)
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 1, "rewind again (7 -> 1), then 1 is short for both recipes -> idle")
	)

	run_case("pick_vein_takes_the_vein_furthest_outside_its_band", func():
		GameState.reset()
		_staff_station("archie")
		GameState.state["player"]["veins"] = [_vein("a", 80), _vein("b", 40), _vein("c", 95)]
		GameState.state["cultivatorVeins"] = { "archie": ["a", "b", "c"] }
		GameState.state["veinStationTargets"] = { "a": 70, "b": 70, "c": 70 }
		# Distance past the band edge: a 5, b 25, c 20.
		assert_eq(Rooms.pick_vein("archie"), "b")
	)

	run_case("pick_vein_breaks_ties_by_assignment_order", func():
		GameState.reset()
		_staff_station("archie")
		GameState.state["player"]["veins"] = [_vein("a", 50), _vein("b", 90)]
		GameState.state["cultivatorVeins"] = { "archie": ["b", "a"] }
		GameState.state["veinStationTargets"] = { "a": 70, "b": 70 }
		assert_eq(Rooms.pick_vein("archie"), "b", "both 15 past the band edge -- earlier in the list wins")
	)

	run_case("pick_vein_is_null_when_every_vein_is_in_band", func():
		GameState.reset()
		_staff_station("archie")
		GameState.state["player"]["veins"] = [_vein("a", 75), _vein("b", 65)]
		GameState.state["cultivatorVeins"] = { "archie": ["a", "b"] }
		GameState.state["veinStationTargets"] = { "a": 70, "b": 70 }
		assert_eq(Rooms.pick_vein("archie"), null)
		var xp_before: int = GameState.state["contacts"]["archie"]["cultivatingXP"]
		Rooms.process_staff_block()
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], xp_before, "idle: no XP")
	)

	# "a vein at 95 with target 70 is pruned down".
	run_case("cultivator_prunes_a_vein_above_target", func():
		GameState.reset()
		_staff_station("archie")
		var vein := _vein("vs1", 95)
		GameState.state["player"]["veins"] = [vein]
		GameState.state["cultivatorVeins"] = { "archie": ["vs1"] }
		GameState.state["veinStationTargets"] = { "vs1": 70 }
		var xp_before: int = GameState.state["contacts"]["archie"]["cultivatingXP"]

		Rng.set_seed(1)
		var output: Dictionary = Rooms.process_staff_block()

		# points = max(0,95-50) - max(0,70-50) = 45-20 = 25
		# yield = round(25 * 0.35) = 9
		assert_eq(vein["growth"], 70, "pruned down exactly to the target")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 9, "ore credited using the §2.4 yield formula")
		assert_eq(output["ore"], { "time": 9 }, "block output reports the yield")
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], xp_before + GameData.CULTIVATOR_ACTION_XP, "+2 XP for a prune")
	)

	# Automated cultivation applies the same eligibility invariant as manual
	# cultivate()/prune() -- a drop below developmentThreshold clears the streak.
	run_case("cultivator_prune_below_90_clears_the_development_streak_same_as_manual_prune", func():
		GameState.reset()
		_staff_station("archie")
		var vein := _vein("vs5", 95)
		vein["level"] = 1
		vein["developmentStreak"] = 3
		GameState.state["player"]["veins"] = [vein]
		GameState.state["cultivatorVeins"] = { "archie": ["vs5"] }
		GameState.state["veinStationTargets"] = { "vs5": 70 }

		Rng.set_seed(1)
		Rooms.process_staff_block()

		assert_true(vein["growth"] < GameData.VEIN_GROWTH["developmentThreshold"], "sanity: pruned down to 70, below the 90 threshold")
		assert_eq(vein["developmentStreak"], 0, "the automated prune clears the streak identically to a manual prune")
	)

	# "one at 40 with target 70 is cultivated up".
	run_case("cultivator_cultivates_a_vein_below_target_with_2_xp_win_or_lose", func():
		var seed := -1
		var final_growth := -1
		for candidate in range(200):
			GameState.reset()
			_staff_station("archie")
			GameState.state["contacts"]["archie"]["cultivatingSkill"] = 5
			var vein := _vein("vs2", 40)
			GameState.state["player"]["veins"] = [vein]
			GameState.state["cultivatorVeins"] = { "archie": ["vs2"] }
			GameState.state["veinStationTargets"] = { "vs2": 70 }
			Rng.set_seed(candidate)
			Rooms.process_staff_block()
			assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], GameData.CULTIVATOR_ACTION_XP, "+2 XP per roll, success or fail")
			if vein["growth"] > 40:
				seed = candidate
				final_growth = vein["growth"]
				break
		assert_true(seed != -1, "should find a successful cultivate roll within 200 tries")
		# skill 5 at growth 40 (ample ceiling headroom) rolls in [10, 14].
		assert_true(final_growth >= 40 + 10 and final_growth <= 40 + 14, "growth += cultivate_gain on success, within skill 5's [10,14] range")
	)

	# "one at 70 is left alone" -- inside the +/-5 hold band.
	run_case("cultivator_leaves_a_vein_at_target_alone", func():
		GameState.reset()
		_staff_station("archie")
		var vein := _vein("vs3", 70)
		GameState.state["player"]["veins"] = [vein]
		GameState.state["cultivatorVeins"] = { "archie": ["vs3"] }
		GameState.state["veinStationTargets"] = { "vs3": 70 }
		var xp_before: int = GameState.state["contacts"]["archie"]["cultivatingXP"]

		Rng.set_seed(1)
		Rooms.process_staff_block()

		assert_eq(vein["growth"], 70, "growth untouched inside the hold band")
		assert_eq(GameState.state["player"]["orichalchum"].get("time", 0), 0, "no ore credited")
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], xp_before, "no contact XP awarded")
	)

	run_case("veins_are_left_alone_without_a_cultivator", func():
		GameState.reset()
		var vein := _vein("vs4", 95)
		GameState.state["player"]["veins"] = [vein]
		GameState.state["cultivatorVeins"] = { "archie": ["vs4"] }
		GameState.state["veinStationTargets"] = { "vs4": 70 }
		Rooms.process_staff_block()
		assert_eq(vein["growth"], 95, "archie holds no cultivation role -> nothing happens")
	)

	run_case("a_cultivator_with_more_veins_than_blocks_falls_behind", func():
		GameState.reset()
		_staff_station("archie")
		var veins := [_vein("a", 95), _vein("b", 94), _vein("c", 93), _vein("d", 92)]
		GameState.state["player"]["veins"] = veins
		GameState.state["cultivatorVeins"] = { "archie": ["a", "b", "c", "d"] }
		GameState.state["veinStationTargets"] = { "a": 70, "b": 70, "c": 70, "d": 70 }
		_run_blocks(TimeSystem.BLOCKS_PER_DAY)
		var growths: Array = []
		for vein in veins:
			growths.append(vein["growth"])
		assert_eq(growths, [70, 70, 70, 92], "one day = 3 actions; the fourth vein is left above its band")
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], 3 * GameData.CULTIVATOR_ACTION_XP)
	)

	run_case("adjust_lab_threshold_floors_at_0", func():
		GameState.reset()
		Rooms.adjust_lab_threshold("timePearl", 5)
		assert_eq(GameState.state["labThresholds"]["timePearl"], 5)
		Rooms.adjust_lab_threshold("timePearl", -10)
		assert_eq(GameState.state["labThresholds"]["timePearl"], 0, "should floor at 0, not go negative")
	)

	run_case("assign_vein_adds_and_unassign_vein_removes", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with()]
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "veinStation")
		assert_true(Rooms.assign_vein("archie", "v1")["ok"])
		assert_eq(Rooms.cultivator_veins("archie"), ["v1"], "assign adds")
		assert_eq(GameState.state["veinStationTargets"]["v1"], 70, "default target 70 on assignment")
		Rooms.unassign_vein("v1")
		assert_eq(Rooms.cultivator_veins("archie"), [], "unassign removes")
		assert_true(not GameState.state["veinStationTargets"].has("v1"), "target cleared on unassignment")
	)

	run_case("assign_vein_rejects_a_contact_outside_the_cultivation_role", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with()]
		GameState.state["contacts"]["archie"]["recruited"] = true
		assert_true(not Rooms.assign_vein("archie", "v1")["ok"])
		assert_eq(Rooms.cultivator_of("v1"), null)
	)

	run_case("assign_vein_moves_a_vein_between_cultivators_keeping_its_target", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with(), Fixtures.player_vein_with({ "id": "v2" })]
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "veinStation")
		GameState.state["contacts"]["owen"]["recruited"] = true
		GameState.state["flags"]["bizOwenCultivationRole"] = true
		assert_true(Contacts.set_role("owen", "cultivation")["ok"])

		Rooms.assign_vein("archie", "v1")
		Rooms.assign_vein("archie", "v2")
		Rooms.set_vein_station_target("v1", 85)
		assert_true(Rooms.assign_vein("owen", "v1")["ok"])

		assert_eq(Rooms.cultivator_veins("archie"), ["v2"], "moved off the old list")
		assert_eq(Rooms.cultivator_veins("owen"), ["v1"], "onto the new one")
		assert_eq(Rooms.cultivator_of("v1"), "owen")
		assert_eq(Rooms.vein_station_target("v1"), 85, "target follows the vein")
	)

	run_case("cultivators_lists_current_role_holders_with_vein_counts", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with(), Fixtures.player_vein_with({ "id": "v2" })]
		assert_eq(Rooms.cultivators(), [], "nobody in the role")
		_staff_station("archie")
		GameState.state["contacts"]["owen"]["recruited"] = true
		GameState.state["flags"]["bizOwenCultivationRole"] = true
		assert_true(Contacts.set_role("owen", "cultivation")["ok"])
		Rooms.assign_vein("archie", "v1")
		Rooms.assign_vein("archie", "v2")

		var rows: Array = Rooms.cultivators()
		assert_eq(rows.size(), 2)
		for row in rows:
			assert_eq(row["veinCount"], 2 if row["id"] == "archie" else 0)

		Contacts.set_role("owen", null)
		assert_eq(Rooms.cultivators(), [{ "id": "archie", "veinCount": 2 }], "a founder out of the role isn't listed")
	)

	run_case("set_vein_station_target_clamps_to_the_vein_ceiling", func():
		GameState.reset()
		var vein := {
			"id": "v2", "oreType": "time", "growth": 50, "security": "none",
			"alarmUpgrades": [], "location": "Vallance Rd, by the bus stop",
			"claimedOnDay": 1, "district": "shoreditch", "siteId": null,
			"hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0,
		}
		GameState.state["player"]["veins"] = [vein]
		Rooms.set_vein_station_target("v2", 150)
		assert_eq(GameState.state["veinStationTargets"]["v2"], 100, "clamped to the vein's ceiling (100, no wildCeiling)")
		Rooms.set_vein_station_target("v2", -10)
		assert_eq(GameState.state["veinStationTargets"]["v2"], 0, "clamped to 0 at the low end")
	)

	run_case("lab_room_lookup_by_id_still_resolves_after_display_name_rename", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "lab")
		assert_eq(Contacts.get_contact_in_room("lab"), "archie", "room id 'lab' still resolves after its display name became 'Improved Lab'")
		assert_eq(GameData.HOME_ROOMS["lab"]["id"], "lab", "internal id unchanged")
		assert_eq(GameData.HOME_ROOMS["lab"]["name"], "Improved Lab", "display name updated to disambiguate from the bench's 'The Lab'")
	)


func _run_blocks(count: int) -> void:
	for i in count:
		Rooms.process_staff_block()


func _staff_lab(contact_id: String, skill: int) -> void:
	GameState.state["contacts"][contact_id]["recruited"] = true
	Contacts.assign_to_room(contact_id, "lab")
	GameState.state["contacts"][contact_id]["craftingSkill"] = skill
	GameState.state["flags"]["craftingUnlocked"] = true


func _staff_station(contact_id: String) -> void:
	GameState.state["contacts"][contact_id]["recruited"] = true
	Contacts.assign_to_room(contact_id, "veinStation")


func _vein(id: String, growth: int) -> Dictionary:
	return Fixtures.player_vein_with({ "id": id, "growth": growth, "rampantDays": 0 })
