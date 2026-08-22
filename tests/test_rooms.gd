extends "res://tests/test_base.gd"


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
		GameState.state["veinStationVeins"] = ["vs1"]
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
			GameState.state["veinStationVeins"] = ["vs2"]
			GameState.state["veinStationTargets"] = { "vs2": 70 }
			Rng.set_seed(candidate)
			Rooms.process_vein_station()
			if vein["growth"] > 40:
				seed = candidate
				final_growth = vein["growth"]
				break
		assert_true(seed != -1, "should find a successful cultivate roll within 200 tries")
		# cultivate_gain(skill 5, growth 40, ceiling 100) = round((6+2*5)*(1-40/100)) = round(16*0.6) = 10
		assert_eq(final_growth, 40 + 10, "growth += cultivate_gain on success")
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
		GameState.state["veinStationVeins"] = ["vs3"]
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
		GameState.state["veinStationVeins"] = ["vs4"]
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

	run_case("toggle_vein_station_vein_adds_and_removes", func():
		GameState.reset()
		Rooms.toggle_vein_station_vein("v1")
		assert_eq(GameState.state["veinStationVeins"], ["v1"], "first toggle adds")
		assert_eq(GameState.state["veinStationTargets"]["v1"], 70, "default target 70 on assignment")
		Rooms.toggle_vein_station_vein("v1")
		assert_eq(GameState.state["veinStationVeins"], [], "second toggle removes")
		assert_true(not GameState.state["veinStationTargets"].has("v1"), "target cleared on unassignment")
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
		Rooms.toggle_vein_station_vein("v2")
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
