extends "res://tests/test_base.gd"


func run() -> void:
	run_case("process_lab_is_a_no_op_without_an_assigned_contact", func():
		GameState.reset()
		GameState.state["labThresholds"]["timePearl"] = 5
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["player"]["orichalchum"]["time"] = 1000
		Rooms.process_lab()
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], 0, "no contact in the lab -> nothing happens")
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
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], 2, "should stop exactly at the threshold, never overshoot")
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
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], 0, "timePearl gated by craftingUnlocked")
		assert_eq(GameState.state["player"]["inventory"]["enhancementPowder"], 0, "enhancementPowder gated by enhancementUnlocked")
	)

	run_case("veinStation_harvests_a_charged_vein", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "veinStation")
		var vein := {
			"id": "vs1", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 5, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Roman Rd, in the car park", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		GameState.state["veinStationVeins"] = ["vs1"]
		var xp_before: int = GameState.state["contacts"]["archie"]["cultivatingXP"]

		Rng.set_seed(1)
		Rooms.process_vein_station()

		assert_eq(vein["charged"], false, "harvested vein should discharge")
		assert_true(GameState.state["player"]["orichalchum"]["time"] > 0, "ore credited to the player")
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], xp_before + 15, "+15 contact cultivating XP for a harvest")
	)

	run_case("veinStation_cultivates_an_uncharged_vein", func():
		var seed := -1
		var final_devbar := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["contacts"]["archie"]["recruited"] = true
			Contacts.assign_to_room("archie", "veinStation")
			GameState.state["contacts"]["archie"]["cultivatingSkill"] = 5
			# level 2 (not 1): level 1's devBarMax is 8, and a skill-5 success
			# gains 1+5=6 — from devBar 2 that's 2+6=8, which would hit
			# devBarMax and trigger a level-up, resetting devBar back to 0
			# and masking the very success this case is trying to detect.
			# Level 2's devBarMax (16) leaves headroom.
			var vein := {
				"id": "vs2", "oreType": "life", "level": 2, "levelLabel": "Minor",
				"devBar": 2, "charged": false, "chargeBlocks": 0, "security": "none",
				"location": "Hackney Rd, under the railway arch", "claimedOnDay": 1, "district": "shoreditch",
				"hospitability": { "tier": "fair", "bonuses": [] },
			}
			GameState.state["player"]["veins"] = [vein]
			GameState.state["veinStationVeins"] = ["vs2"]
			Rng.set_seed(candidate)
			Rooms.process_vein_station()
			if vein["devBar"] > 2:
				seed = candidate
				final_devbar = vein["devBar"]
				break
		assert_true(seed != -1, "should find a successful cultivate roll within 200 tries")
		assert_eq(final_devbar, 2 + (1 + 5), "devBar += 1+skill (skill 5) on success")
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], 20, "+20 contact cultivating XP for a successful cultivate")
	)

	run_case("veinStation_is_a_no_op_without_an_assigned_contact", func():
		GameState.reset()
		var vein := {
			"id": "vs3", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 5, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Vallance Rd, by the bus stop", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		GameState.state["veinStationVeins"] = ["vs3"]
		Rooms.process_vein_station()
		assert_eq(vein["charged"], true, "no assigned contact -> nothing happens")
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
		Rooms.toggle_vein_station_vein("v1")
		assert_eq(GameState.state["veinStationVeins"], [], "second toggle removes")
	)

	run_case("lab_room_lookup_by_id_still_resolves_after_display_name_rename", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "lab")
		assert_eq(Contacts.get_contact_in_room("lab"), "archie", "room id 'lab' still resolves after its display name became 'Improved Lab'")
		assert_eq(GameData.HOME_ROOMS["lab"]["id"], "lab", "internal id unchanged")
		assert_eq(GameData.HOME_ROOMS["lab"]["name"], "Improved Lab", "display name updated to disambiguate from the bench's 'The Lab'")
	)
