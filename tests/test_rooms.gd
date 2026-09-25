extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

func run() -> void:
	run_case("process_lab_is_a_no_op_without_an_assigned_contact", func():
		GameState.reset()
		GameState.state["labThresholds"]["timePearl"] = 5
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["player"]["orichalchum"]["time"] = 1000
		Rooms.process_lab()
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "no contact in the lab -> nothing happens")
	)

	run_case("process_lab_stops_exactly_when_ore_runs_out", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "lab")
		GameState.state["contacts"]["archie"]["craftingSkill"] = 1
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["labThresholds"]["timePearl"] = 1000  # unreachable target
		# timePearl calcCost at skill 1 = baseCalcCost = 5. Exactly 3 attempts' worth.
		GameState.state["player"]["orichalchum"]["time"] = 15
		Rng.set_seed(1)
		Rooms.process_lab()
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 0, "ore should be fully spent, 3 attempts * 5")
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].begins_with("Lab (Archie): ") and n["text"].contains("from 3 attempts"):
				found = true
		assert_true(found, "should report exactly 3 attempts before running out of calc")
	)

	run_case("process_lab_crafts_to_threshold_using_the_contacts_skill", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "lab")
		GameState.state["contacts"]["archie"]["craftingSkill"] = 3
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["labThresholds"]["timePearl"] = 2
		GameState.state["player"]["orichalchum"]["time"] = 10000  # ore never the bottleneck here
		Rng.set_seed(7)
		Rooms.process_lab()
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "should stop exactly at the threshold, never overshoot")
	)

	run_case("process_lab_skips_recipes_not_yet_unlocked", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "lab")
		GameState.state["flags"]["craftingUnlocked"] = false
		GameState.state["flags"]["enhancementUnlocked"] = false
		GameState.state["labThresholds"]["timePearl"] = 5
		GameState.state["labThresholds"]["enhancementPowder"] = 5
		GameState.state["player"]["orichalchum"] = { "time": 1000, "life": 1000 }
		Rooms.process_lab()
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "timePearl gated by craftingUnlocked")
		assert_eq(Crafting.inventory_qty("enhancementPowder"), 0, "enhancementPowder gated by enhancementUnlocked")
	)

	# ticket 30: Production contract-coverage toggle.
	run_case("effective_lab_target_adds_contract_need_only_when_covering", func():
		GameState.reset()
		GameState.state["labThresholds"]["timePearl"] = 5
		var created: Dictionary = Offers.create_offer({ "id": "t1", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 10 } })
		Offers.accept_offer(created["offer"]["id"])
		assert_eq(Rooms.effective_lab_target("timePearl"), 5, "toggle off -- personal target only, contract need ignored")
		Rooms.set_lab_cover_contracts("timePearl", true)
		assert_eq(Rooms.effective_lab_target("timePearl"), 15, "toggle on -- additive per ticket 29 (5 personal + 10 contract need)")
	)

	run_case("production_reserved_qty_protects_only_the_personal_target_while_covering", func():
		GameState.reset()
		GameState.state["labThresholds"]["timePearl"] = 5
		assert_eq(Rooms.production_reserved_qty("timePearl"), 0, "no reserve while the toggle is off")
		Rooms.set_lab_cover_contracts("timePearl", true)
		assert_eq(Rooms.production_reserved_qty("timePearl"), 5, "reserve equals the personal target once covering, never the contract-need portion")
	)

	run_case("process_lab_ignores_contract_need_when_toggle_is_off", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "lab")
		GameState.state["contacts"]["archie"]["craftingSkill"] = 3
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["labThresholds"]["timePearl"] = 2
		GameState.state["player"]["orichalchum"]["time"] = 10000
		var created: Dictionary = Offers.create_offer({ "id": "t2", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 5 } })
		Offers.accept_offer(created["offer"]["id"])
		Rng.set_seed(7)
		Rooms.process_lab()
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "toggle defaults off -- an active contract for the item must not inflate Production's target")
	)

	run_case("process_lab_crafts_toward_the_combined_personal_target_and_contract_need", func():
		var seed := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["contacts"]["archie"]["recruited"] = true
			Contacts.assign_to_room("archie", "lab")
			GameState.state["contacts"]["archie"]["craftingSkill"] = 6
			GameState.state["flags"]["craftingUnlocked"] = true
			GameState.state["labThresholds"]["timePearl"] = 2
			GameState.state["labCoverContracts"]["timePearl"] = true
			GameState.state["player"]["orichalchum"]["time"] = 10000
			var created: Dictionary = Offers.create_offer({ "id": "t3", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 3 } })
			Offers.accept_offer(created["offer"]["id"])
			Rng.set_seed(candidate)
			Rooms.process_lab()
			if Crafting.inventory_qty("timePearl") == 5:
				seed = candidate
				break
		assert_true(seed != -1, "should find a seed reaching the combined target (2 personal + 3 contract need) within 200 tries")
	)

	run_case("process_lab_orders_scarce_shared_ore_by_contract_priority_then_by_personal_target", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "lab")
		GameState.state["contacts"]["archie"]["craftingSkill"] = 1
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["labCoverContracts"]["timePearl"] = true
		GameState.state["labCoverContracts"]["rewind"] = true
		# timePearl costs 5 "time" ore/attempt, rewind costs 6, both at skill 1.
		GameState.state["player"]["orichalchum"]["time"] = 13
		var pearl_offer: Dictionary = Offers.create_offer({ "id": "t4_pearl", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 1000 } })
		Offers.accept_offer(pearl_offer["offer"]["id"])
		var rewind_offer: Dictionary = Offers.create_offer({ "id": "t4_rewind", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "rewind", "qty": 1000 } })
		var rewind_contract: Dictionary = Offers.accept_offer(rewind_offer["offer"]["id"])["contract"]
		# timePearl's contract was accepted first (default priority order); move
		# rewind's contract to the front so its recipe should get first pick of
		# the shared "time" ore -- proving order tracks sales.priorityOrder
		# (ticket 25) rather than GameData.RECIPES.keys()'s fixed data order.
		Contracts.reorder(rewind_contract["id"], 0)
		Rooms.process_lab()
		# rewind processed first: floor(13/6) = 2 attempts, 12 spent, 1 left
		# (1 < timePearl's cost of 5, so timePearl gets zero attempts).
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 1, "the higher-priority contract's recipe (rewind) should drain the shared ore first")
	)

	# vein-growth-state ticket 06, spec §11 item 10: "a vein at 95 with target
	# 70 is pruned down".
	run_case("veinStation_prunes_a_vein_above_target", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "veinStation")
		var vein := {
			"id": "vs1", "oreType": "time", "growth": 95, "security": "none",
			"alarmUpgrades": [], "location": "Roman Rd, in the car park",
			"claimedOnDay": 1, "district": "shoreditch", "siteId": null,
			"hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0,
		}
		GameState.state["player"]["veins"] = [vein]
		GameState.state["cultivatorVeins"] = { "archie": ["vs1"] }
		GameState.state["veinStationTargets"] = { "vs1": 70 }
		var xp_before: int = GameState.state["contacts"]["archie"]["cultivatingXP"]

		Rng.set_seed(1)
		Rooms.process_vein_station()

		# points = max(0,95-50) - max(0,70-50) = 45-20 = 25
		# yield = round(25 * 0.35) = 9
		assert_eq(vein["growth"], 70, "pruned down exactly to the target")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 9, "ore credited using the §2.4 yield formula")
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], xp_before + 15, "+15 contact cultivating XP for a prune")
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"] == "Vein Station (Archie): pruned 9 Time Orichalchum.":
				found = true
		assert_true(found, "notification uses prune language and an ore-type breakdown, matching the old harvest-breakdown shape")
	)

	# cultivation-refining ticket 08: automated vein-station cultivation must
	# apply the same eligibility invariant as manual cultivate()/prune() --
	# a drop below developmentThreshold clears the streak either way.
	run_case("veinStation_prune_below_90_clears_the_development_streak_same_as_manual_prune", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "veinStation")
		var vein := {
			"id": "vs5", "oreType": "time", "growth": 95, "security": "none",
			"alarmUpgrades": [], "location": "Roman Rd, in the car park",
			"claimedOnDay": 1, "district": "shoreditch", "siteId": null,
			"hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0,
			"level": 1, "developmentStreak": 3,
		}
		GameState.state["player"]["veins"] = [vein]
		GameState.state["cultivatorVeins"] = { "archie": ["vs5"] }
		GameState.state["veinStationTargets"] = { "vs5": 70 }

		Rng.set_seed(1)
		Rooms.process_vein_station()

		assert_true(vein["growth"] < GameData.VEIN_GROWTH["developmentThreshold"], "sanity: pruned down to 70, below the 90 threshold")
		assert_eq(vein["developmentStreak"], 0, "the vein station's automated prune clears the streak identically to a manual prune")
	)

	# spec §11 item 10: "one at 40 with target 70 is cultivated up".
	run_case("veinStation_cultivates_a_vein_below_target", func():
		var seed := -1
		var final_growth := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["contacts"]["archie"]["recruited"] = true
			Contacts.assign_to_room("archie", "veinStation")
			GameState.state["contacts"]["archie"]["cultivatingSkill"] = 5
			var vein := {
				"id": "vs2", "oreType": "life", "growth": 40, "security": "none",
				"alarmUpgrades": [], "location": "Hackney Rd, under the railway arch",
				"claimedOnDay": 1, "district": "shoreditch", "siteId": null,
				"hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0,
			}
			GameState.state["player"]["veins"] = [vein]
			GameState.state["cultivatorVeins"] = { "archie": ["vs2"] }
			GameState.state["veinStationTargets"] = { "vs2": 70 }
			Rng.set_seed(candidate)
			Rooms.process_vein_station()
			if vein["growth"] > 40:
				seed = candidate
				final_growth = vein["growth"]
				break
		assert_true(seed != -1, "should find a successful cultivate roll within 200 tries")
		# cultivation-refining ticket 03: cultivate_gain is now a uniform
		# [skill+5, skill+9] roll rather than a fixed diminishing formula --
		# skill 5 at growth 40 (ample ceiling headroom) rolls in [10, 14].
		assert_true(final_growth >= 40 + 10 and final_growth <= 40 + 14, "growth += cultivate_gain on success, within skill 5's [10,14] range")
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], 20, "+20 contact cultivating XP for a successful cultivate")
	)

	# spec §11 item 10: "one at 70 is left alone" -- target 70, growth 70,
	# inside the +/-5 hold band either way.
	run_case("veinStation_leaves_a_vein_at_target_alone", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "veinStation")
		var vein := {
			"id": "vs3", "oreType": "time", "growth": 70, "security": "none",
			"alarmUpgrades": [], "location": "Vallance Rd, by the bus stop",
			"claimedOnDay": 1, "district": "shoreditch", "siteId": null,
			"hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0,
		}
		GameState.state["player"]["veins"] = [vein]
		GameState.state["cultivatorVeins"] = { "archie": ["vs3"] }
		GameState.state["veinStationTargets"] = { "vs3": 70 }
		var xp_before: int = GameState.state["contacts"]["archie"]["cultivatingXP"]

		Rng.set_seed(1)
		Rooms.process_vein_station()

		assert_eq(vein["growth"], 70, "growth untouched inside the hold band")
		assert_eq(GameState.state["player"]["orichalchum"].get("time", 0), 0, "no ore credited")
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], xp_before, "no contact XP awarded")
	)

	run_case("veinStation_is_a_no_op_without_an_assigned_contact", func():
		GameState.reset()
		var vein := {
			"id": "vs4", "oreType": "time", "growth": 95, "security": "none",
			"alarmUpgrades": [], "location": "Vallance Rd, by the bus stop",
			"claimedOnDay": 1, "district": "shoreditch", "siteId": null,
			"hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0,
		}
		GameState.state["player"]["veins"] = [vein]
		GameState.state["cultivatorVeins"] = { "archie": ["vs4"] }
		GameState.state["veinStationTargets"] = { "vs4": 70 }
		Rooms.process_vein_station()
		assert_eq(vein["growth"], 95, "no assigned contact -> nothing happens")
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
