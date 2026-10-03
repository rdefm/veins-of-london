extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

const CANDIDATES := ["marcia", "tomasz", "bernie", "saoirse", "priya", "dot", "gideon", "ray"]


func run() -> void:
	run_case("roster_is_seeded_locked_unrecruited_and_open", func():
		GameState.reset()
		for candidate_id in CANDIDATES:
			var c: Dictionary = GameState.state["contacts"][candidate_id]
			assert_true(not c["unlocked"] and not c["recruited"], "%s seeded locked" % candidate_id)
			assert_eq(Hiring.status(candidate_id), { "state": "open", "employer": null, "since": 0 })
		assert_eq(Hiring.candidate_ids(), CANDIDATES)
		assert_eq(Contacts.display_name("priya"), "Priya Sandhu")
		assert_true(not Contacts.can_recruit("priya"), "candidates join only by hiring")
	)

	run_case("cultivators_carry_their_specialities", func():
		GameState.reset()
		var contacts: Dictionary = GameState.state["contacts"]
		assert_eq(contacts["marcia"]["specialities"], ["life"])
		assert_eq(contacts["tomasz"]["specialities"], ["physics"])
		assert_eq(contacts["bernie"]["specialities"], ["life", "physics"])
		assert_eq(contacts["saoirse"]["specialities"], ["fate", "emotion"])
	)

	run_case("old_save_backfills_candidates_and_hiring_state", func():
		GameState.reset()
		var save: Dictionary = GameState.state.duplicate(true)
		save.erase("hiring")
		for candidate_id in CANDIDATES:
			save["contacts"].erase(candidate_id)
		var loaded := SaveManager.backfill_defaults(save)
		assert_eq(loaded["hiring"]["status"].keys(), CANDIDATES)
		assert_eq(loaded["hiring"]["feed"], [])
		assert_eq(loaded["hiring"]["feedSeen"], 0)
		assert_true(not loaded["contacts"]["gideon"]["recruited"])
		var partial: Dictionary = GameState.state.duplicate(true)
		partial["hiring"]["status"].erase("ray")
		assert_eq(SaveManager.backfill_defaults(partial)["hiring"]["status"]["ray"]["state"], "open")
	)

	run_case("app_is_absent_until_james_joins", func():
		GameState.reset()
		assert_true(not _app_ids().has("lodedinnit"))
		GameState.state["flags"]["bizA1JamesJoined"] = true
		assert_true(_app_ids().has("lodedinnit"))
	)

	run_case("profile_numbers_read_from_data", func():
		GameState.reset()
		assert_eq(Hiring.level("gideon"), 3)
		assert_eq(Hiring.level_cap("gideon"), 5)
		assert_eq(Hiring.weekly_wage("gideon"), 480)
		assert_eq(Hiring.level_cap("bernie"), 3)
	)

	run_case("hire_is_refused_without_a_built_room_or_a_free_seat", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		GameState.state["home"]["rooms"].erase("lab")
		assert_true(not Hiring.hire("priya")["ok"], "no lab built")
		GameState.state["home"]["rooms"].append("lab")
		assert_true(Hiring.hire("priya")["ok"])
		var result := Hiring.hire("dot")
		assert_true(not result["ok"], "the lab's one seat is taken")
		assert_eq(result["reason"], "No free seat in the Improved Lab.")
		assert_true(not GameState.state["contacts"]["dot"]["recruited"])
	)

	run_case("hire_prepays_the_first_week_from_pot_then_float", func():
		_setup()
		GameState.state["business"]["pot"] = 100
		GameState.state["business"]["float"] = 500
		assert_true(Hiring.hire("priya")["ok"])
		var business: Dictionary = GameState.state["business"]
		assert_eq(business["pot"], 0)
		assert_eq(business["float"], 280)
		assert_eq(business["week"]["expenses"][-1], { "kind": "wage", "contactId": "priya", "amount": 320 })
		var wage: Dictionary = business["wages"]["priya"]
		assert_eq(wage["weekly"], 320)
		assert_eq(wage["hiredDay"], 9)
		assert_eq(wage["paidThroughDay"], 16)
		assert_eq(wage["owed"], 0)
		var c: Dictionary = GameState.state["contacts"]["priya"]
		assert_true(c["unlocked"] and c["recruited"])
		assert_eq(c["assignedRoom"], "lab")
		assert_eq(c["craftingSkill"], 2)
		assert_eq(c["craftingXP"], int(GameData.CRAFTING_XP_LEVELS[2]))
		assert_eq(Contacts.role_of("priya"), "production")
		assert_eq(Hiring.status("priya"), { "state": "ours", "employer": null, "since": 9 })
		assert_true(not Hiring.hire("priya")["ok"], "already ours")
	)

	run_case("hire_short_of_funds_asks_for_a_float_top_up", func():
		_setup()
		GameState.state["business"]["float"] = 100
		GameState.state["player"]["cash"] = 1000
		var result := Hiring.hire("priya")
		assert_true(not result["ok"])
		assert_eq(result["topUp"], 220)
		assert_eq(GameState.state["player"]["cash"], 1000, "No: nothing moves")
		assert_true(not GameState.state["contacts"]["priya"]["recruited"], "No: no hire")
		assert_true(Hiring.hire("priya", true)["ok"])
		assert_eq(GameState.state["player"]["cash"], 780)
		assert_eq(GameState.state["business"]["float"], 0)
		assert_true(GameState.state["contacts"]["priya"]["recruited"])
	)

	run_case("top_up_pays_the_hire_before_another_owed_wage", func():
		_setup()
		GameState.state["business"]["wages"]["owen"]["owed"] = 200
		GameState.state["business"]["wages"]["owen"]["unpaid"] = true
		GameState.state["player"]["cash"] = 1000
		assert_eq(Hiring.hire("priya")["topUp"], 320)
		assert_true(Hiring.hire("priya", true)["ok"])
		assert_eq(GameState.state["player"]["cash"], 680)
		assert_eq(GameState.state["business"]["float"], 0)
		assert_eq(Business.owed("owen"), 200, "Owen still owed; the top-up went to the hire")
	)

	run_case("top_up_hire_is_refused_without_the_cash", func():
		_setup()
		GameState.state["player"]["cash"] = 50
		assert_true(not Hiring.hire("priya", true)["ok"])
		assert_eq(GameState.state["player"]["cash"], 50)
		assert_true(not GameState.state["contacts"]["priya"]["recruited"])
	)

	run_case("payday_skips_the_prepaid_week_then_charges_days_after_it", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("priya")
		for day in range(10, 16):
			GameState.state["world"]["day"] = day
			Business.daily_tick()
		var first: Dictionary = GameState.state["business"]["ledger"][-1]
		assert_eq(first["day"], 15)
		assert_eq(first["expenses"].filter(func(e): return e.get("contactId") == "priya" and e["kind"] == "wage").size(), 1,
			"only the prepay line; payday adds none")
		for day in range(16, 23):
			GameState.state["world"]["day"] = day
			Business.daily_tick()
		var second: Dictionary = GameState.state["business"]["ledger"][-1]
		assert_eq(second["day"], 22)
		var lines: Array = second["expenses"].filter(func(e): return e.get("contactId") == "priya")
		assert_eq(lines, [{ "kind": "wage", "contactId": "priya", "amount": Business.prorated_wage(320, 6) }],
			"days 16-21 owed; day 15 was prepaid")
	)

	run_case("a_hired_crafter_makes_only_recipes_within_their_specialities", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("priya")
		for recipe_key in Rooms.producible_recipes("priya"):
			assert_true(GameData.RECIPES[recipe_key]["ingredients"].keys().all(func(o): return o == "physics"))
		GameState.state["labThresholds"]["blast"] = 1
		GameState.state["labThresholds"]["timePearl"] = 1
		GameState.state["player"]["orichalchum"]["physics"] = 1000
		GameState.state["player"]["orichalchum"]["time"] = 1000
		Rng.set_seed(1)
		Rooms.process_staff_block()
		assert_eq(Crafting.inventory_qty("blast"), 1)
		assert_eq(Crafting.inventory_qty("timePearl"), 0)
	)

	run_case("a_hired_cultivator_tends_veins", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		assert_true(Hiring.hire("marcia")["ok"])
		var vein := Fixtures.player_vein_with({ "id": "vh1", "growth": 95, "rampantDays": 0 })
		GameState.state["player"]["veins"] = [vein]
		assert_true(Rooms.assign_vein("marcia", "vh1")["ok"])
		GameState.state["veinStationTargets"]["vh1"] = 70
		Rng.set_seed(1)
		Rooms.process_staff_block()
		assert_eq(vein["growth"], 70)
	)


	run_case("level_up_raises_the_weekly_wage", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("marcia")
		Hiring.hire("priya")
		var wages: Dictionary = GameState.state["business"]["wages"]
		var marcia_weekly: int = wages["marcia"]["weekly"]
		var levels: Array = GameData.CULTIVATING_XP_LEVELS
		var c: Dictionary = GameState.state["contacts"]["marcia"]
		Contacts.award_contact_xp("marcia", "cultivating", int(levels[c["cultivatingSkill"] + 1]) - int(c["cultivatingXP"]))
		var data := Hiring.candidate("marcia")
		assert_eq(wages["marcia"]["weekly"], marcia_weekly + int(data["wagePerLevel"]))
		assert_eq(Hiring.weekly_wage("marcia"), wages["marcia"]["weekly"])
		wages["priya"]["wageMult"] = 1.25
		Contacts.award_contact_xp("priya", "crafting", int(GameData.CRAFTING_XP_LEVELS[3]) - int(GameData.CRAFTING_XP_LEVELS[2]))
		assert_eq(wages["priya"]["weekly"], GameState.round_epsilon((320 + 60) * 1.25), "weekly = round(formula × wageMult)")
	)

	run_case("a_capped_hire_wage_never_rises", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("bernie")
		Contacts.award_contact_xp("bernie", "cultivating", 100000)
		assert_eq(GameState.state["contacts"]["bernie"]["cultivatingSkill"], 3)
		assert_eq(GameState.state["business"]["wages"]["bernie"]["weekly"], 420)
	)

	run_case("let_go_frees_the_seat_and_releases_the_veins", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("marcia")
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with({ "id": "vl1" })]
		Rooms.assign_vein("marcia", "vl1")
		assert_eq(Hiring.hires_for_room("veinStation"), ["marcia"])
		assert_true(Hiring.let_go("marcia")["ok"])
		var c: Dictionary = GameState.state["contacts"]["marcia"]
		assert_eq(c["assignedRoom"], null)
		assert_true(not c["recruited"])
		assert_eq(Rooms.cultivator_of("vl1"), null)
		assert_true(not GameState.state["veinStationTargets"].has("vl1"))
		assert_eq(Hiring.status("marcia"), { "state": "open", "employer": null, "since": 9 })
		assert_eq(Hiring.hires_for_room("veinStation"), [])
		assert_true(Hiring.hire("tomasz")["ok"], "the seat is free again")
		assert_true(not Hiring.let_go("marcia")["ok"], "no longer ours")
	)

	run_case("payday_pays_a_leaver_once_then_drops_the_entry", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("priya")
		for day in range(10, 19):
			GameState.state["world"]["day"] = day
			Business.daily_tick()
		Hiring.let_go("priya")
		var wages: Dictionary = GameState.state["business"]["wages"]
		assert_true(wages["priya"]["leaving"])
		for day in range(19, 30):
			GameState.state["world"]["day"] = day
			Business.daily_tick()
		var ledger: Array = GameState.state["business"]["ledger"]
		var lines: Array = []
		for record in ledger:
			lines.append_array(record["expenses"].filter(func(e): return e.get("contactId") == "priya" and record["day"] > 15))
		assert_eq(lines, [{ "kind": "wage", "contactId": "priya", "amount": Business.prorated_wage(320, 2) }],
			"days 17-18 paid at payday 22, once")
		assert_true(not wages.has("priya"))
	)

	run_case("let_go_in_the_prepaid_week_drops_the_entry_at_once", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("priya")
		Hiring.let_go("priya")
		assert_true(not GameState.state["business"]["wages"].has("priya"))
	)

	run_case("rehire_wage_reflects_the_kept_level", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("priya")
		Contacts.award_contact_xp("priya", "crafting", int(GameData.CRAFTING_XP_LEVELS[3]) - int(GameData.CRAFTING_XP_LEVELS[2]))
		GameState.state["business"]["wages"]["priya"]["wageMult"] = 1.25
		Hiring.let_go("priya")
		assert_eq(Hiring.level("priya"), 3)
		assert_eq(Hiring.weekly_wage("priya"), 380)
		var float_before: int = GameState.state["business"]["float"]
		assert_true(Hiring.hire("priya")["ok"])
		assert_eq(GameState.state["business"]["float"], float_before - 380)
		assert_eq(GameState.state["business"]["wages"]["priya"]["weekly"], 380)
		assert_eq(GameState.state["business"]["wages"]["priya"]["wageMult"], 1.0)
	)

	run_case("rehire_before_payday_carries_the_leavers_worked_days_as_owed", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("priya")
		for day in range(10, 19):
			GameState.state["world"]["day"] = day
			Business.daily_tick()
		Hiring.let_go("priya")
		var float_before: int = GameState.state["business"]["float"]
		assert_true(Hiring.hire("priya")["ok"])
		assert_eq(GameState.state["business"]["float"], float_before - 320 - Business.prorated_wage(320, 2),
			"days 17-18 settled with the re-hire")
		assert_eq(Business.owed("priya"), 0)
	)

	run_case("market_flips_at_about_one_in_fourteen_to_any_faction", func():
		_setup()
		assert_true(is_equal_approx(float(GameData.HIRING_MARKET["flipChancePerDay"]), 1.0 / 14.0))
		Rng.set_seed(4242)
		var flips := 0
		var employers := {}
		for day in range(10, 710):
			GameState.state["world"]["day"] = day
			var before: Dictionary = GameState.state["hiring"]["status"].duplicate(true)
			Hiring.roll_market_flips()
			for candidate_id in CANDIDATES:
				var now: Dictionary = Hiring.status(candidate_id)
				if now["state"] == before[candidate_id]["state"]:
					assert_eq(now, before[candidate_id], "%s unchanged without a flip" % candidate_id)
					continue
				flips += 1
				assert_eq(now["since"], day)
				if now["state"] == "employed":
					assert_eq(before[candidate_id]["state"], "open")
					employers[now["employer"]] = true
				else:
					assert_eq(now["employer"], null)
		# 8 candidates × 700 rollovers × 1/14 = 400 expected flips.
		assert_true(flips > 330 and flips < 470, "flip count %d near 400" % flips)
		var pool: Array = GameState.state["factions"].keys()
		assert_eq(Hiring.employer_pool(), pool)
		for faction_id in pool:
			assert_true(employers.has(faction_id), "%s drawn as an employer" % faction_id)
		assert_eq(employers.size(), pool.size())
	)

	run_case("ours_never_flips", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		Hiring.hire("priya")
		var hired: Dictionary = Hiring.status("priya").duplicate()
		Rng.set_seed(7)
		for day in range(10, 400):
			GameState.state["world"]["day"] = day
			Hiring.roll_market_flips()
		assert_eq(Hiring.status("priya"), hired)
	)

	run_case("rollover_rolls_market_flips", func():
		_setup()
		var chance: float = GameData.HIRING_MARKET["flipChancePerDay"]
		GameData.HIRING_MARKET["flipChancePerDay"] = 1.0
		TimeSystem.daily_tick()
		GameData.HIRING_MARKET["flipChancePerDay"] = chance
		for candidate_id in CANDIDATES:
			assert_eq(Hiring.status(candidate_id)["state"], "employed")
	)

	run_case("poach_applies_the_premium_and_relation_cost", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		GameState.state["hiring"]["status"]["priya"] = { "state": "employed", "employer": "firm", "since": 3 }
		GameState.state["factions"]["firm"]["relation"] = 10
		assert_eq(Hiring.hire_block_reason("priya"), "")
		assert_eq(Hiring.weekly_wage("priya"), 400, "320 × 1.25")
		assert_true(Hiring.hire("priya")["ok"])
		assert_eq(GameState.state["business"]["float"], 4600)
		var wage: Dictionary = GameState.state["business"]["wages"]["priya"]
		assert_eq(wage["wageMult"], 1.25)
		assert_eq(wage["weekly"], 400)
		assert_eq(GameState.state["factions"]["firm"]["relation"], 2)
		assert_eq(Hiring.status("priya")["state"], "ours")
		Contacts.award_contact_xp("priya", "crafting", int(GameData.CRAFTING_XP_LEVELS[3]) - int(GameData.CRAFTING_XP_LEVELS[2]))
		assert_eq(wage["weekly"], 475, "premium kept on a level-up: 380 × 1.25")
	)

	run_case("open_hire_has_no_premium_or_relation_cost", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		var relations := {}
		for faction_id in GameState.state["factions"]:
			relations[faction_id] = GameState.state["factions"][faction_id]["relation"]
		assert_true(Hiring.hire("priya")["ok"])
		assert_eq(GameState.state["business"]["wages"]["priya"]["wageMult"], 1.0)
		assert_eq(GameState.state["business"]["wages"]["priya"]["weekly"], 320)
		for faction_id in relations:
			assert_eq(GameState.state["factions"][faction_id]["relation"], relations[faction_id])
	)

	run_case("market_status_survives_save_load_and_rewind", func():
		_setup()
		var employed := { "state": "employed", "employer": "guild", "since": 7 }
		GameState.state["hiring"]["status"]["dot"] = employed.duplicate()
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		GameState.state["hiring"]["status"]["dot"] = { "state": "open", "employer": null, "since": 9 }
		GameState.state = snapshot
		assert_eq(Hiring.status("dot"), employed, "rewind restores the snapshot's status")
		var text := SaveManager.export_string()
		GameState.reset()
		assert_true(SaveManager.import_string(text)["ok"])
		assert_eq(Hiring.status("dot")["state"], "employed")
		assert_eq(Hiring.status("dot")["employer"], "guild")
		assert_eq(int(Hiring.status("dot")["since"]), 7)
	)

	run_case("poach_offer_rolls_weekly_and_is_weighted_by_stance", func():
		_setup_hired_on_monday()
		GameData.HIRING_MARKET["poachChance"] = 0.0
		Hiring.daily_poach_tick()
		assert_true(Hiring.pending_poach("priya").is_empty(), "no roll, no offer")
		GameData.HIRING_MARKET["poachChance"] = 1.0
		Hiring.daily_poach_tick()
		var pending: Dictionary = Hiring.pending_poach("priya")
		assert_eq(pending["offer"], GameState.round_epsilon(float(Hiring.weekly_wage("priya")) * 1.2))
		assert_eq(pending["expiresDay"], GameState.state["world"]["day"] + 2)
		assert_eq(GameState.state["hiring"]["poach"]["priya"]["attempts"], 1)
		var ids: Array = GameState.state["factions"].keys()
		for faction_id in ids:
			GameState.state["factionStances"]["player"][faction_id]["stance"] = "partner"
		GameState.state["factionStances"]["player"][ids[1]]["stance"] = "hostile"
		for i in 20:
			assert_eq(Hiring._pick_poacher(), ids[1], "only the hostile faction has weight")
		GameState.state["factionStances"]["player"][ids[1]]["stance"] = "partner"
		assert_eq(Hiring._pick_poacher(), "", "no weighted faction, no poacher")
	)

	run_case("poach_attempts_cap_and_non_monday_skips", func():
		_setup_hired_on_monday()
		GameData.HIRING_MARKET["poachChance"] = 1.0
		for i in 3:
			Hiring.daily_poach_tick()
			Hiring.match_poach("priya")
		Hiring.daily_poach_tick()
		assert_true(Hiring.pending_poach("priya").is_empty(), "attempt cap of 3 holds")
		assert_eq(GameState.state["hiring"]["poach"]["priya"]["attempts"], 3)
		GameState.state["hiring"]["poach"]["priya"]["attempts"] = 0
		GameState.state["world"]["day"] += 1
		Hiring.daily_poach_tick()
		assert_true(Hiring.pending_poach("priya").is_empty(), "offers roll on Mondays only")
	)

	run_case("poach_match_sets_wage_and_never_exceeds_cap", func():
		_setup_hired_on_monday()
		GameData.HIRING_MARKET["poachChance"] = 1.0
		var before := Hiring.weekly_wage("priya")
		Hiring.daily_poach_tick()
		var offer: int = Hiring.pending_poach("priya")["offer"]
		assert_true(offer <= GameState.round_epsilon(float(before) * 1.25), "offer within the cap")
		assert_true(Hiring.match_poach("priya")["ok"])
		assert_eq(Hiring.weekly_wage("priya"), offer)
		assert_eq(GameState.state["business"]["wages"]["priya"]["weekly"], offer)
		assert_eq(Hiring.status("priya")["state"], "ours")
		assert_true(Hiring.pending_poach("priya").is_empty())
	)

	run_case("poach_unanswered_resolves_after_a_full_day", func():
		_setup_hired_on_monday()
		GameData.HIRING_MARKET["poachChance"] = 1.0
		Hiring.daily_poach_tick()
		var faction_id: String = Hiring.pending_poach("priya")["factionId"]
		GameData.HIRING_MARKET["poachChance"] = 0.0
		GameState.state["world"]["day"] += 1
		Hiring.daily_poach_tick()
		assert_eq(Hiring.status("priya")["state"], "ours", "still answerable the next day")
		GameState.state["world"]["day"] += 1
		Hiring.daily_poach_tick()
		assert_eq(Hiring.status("priya")["state"], "employed")
		assert_eq(Hiring.status("priya")["employer"], faction_id)
		assert_true(GameState.state["business"]["wages"]["priya"].get("leaving", false))
		assert_true(Hiring.pending_poach_ids().is_empty())
	)

	run_case("poach_decline_makes_hire_employed_at_the_faction", func():
		_setup_hired_on_monday()
		GameData.HIRING_MARKET["poachChance"] = 1.0
		Hiring.daily_poach_tick()
		var faction_id: String = Hiring.pending_poach("priya")["factionId"]
		assert_true(Hiring.decline_poach("priya")["ok"])
		assert_eq(Hiring.status("priya")["employer"], faction_id)
		assert_eq(GameState.state["contacts"]["priya"]["assignedRoom"], null)
	)

	run_case("traits_read_from_data", func():
		_setup()
		assert_eq(Hiring.trait_skip_chance("saoirse"), 0.2)
		assert_eq(Hiring.trait_skip_chance("ray"), 0.2)
		assert_eq(Hiring.trait_skip_chance("tomasz"), 0.0)
		assert_eq(Hiring.trait_xp_mult("tomasz"), 1.25)
		assert_eq(Hiring.trait_xp_mult("saoirse"), 1.0)
		assert_eq(Hiring.trait_xp_mult("marcia"), 1.0)
		GameData.HIRING_TRAITS["distracted"]["skipChance"] = 1.0
		assert_true(Hiring.trait_skips_block("ray"), "chance 1 always skips")
		assert_true(not Hiring.trait_skips_block("priya"), "no trait never skips")
		GameData.HIRING_TRAITS["distracted"]["skipChance"] = 0.2
	)

	run_case("distracted_skip_rate_matches_data_with_seeded_rng", func():
		_setup()
		Rng.set_seed(7)
		var skips := 0
		for i in 1000:
			if Hiring.trait_skips_block("saoirse"):
				skips += 1
		assert_true(skips > 150 and skips < 250, "about 20%% of 1000, got %d" % skips)
	)

	run_case("distracted_producer_skips_whole_block", func():
		_setup()
		GameData.HIRING_TRAITS["distracted"]["skipChance"] = 1.0
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["labThresholds"]["timePearl"] = 1000
		GameState.state["player"]["orichalchum"]["time"] = 1000
		GameState.state["contacts"]["ray"]["recruited"] = true
		Contacts.assign_to_room("ray", "lab")
		GameState.state["contacts"]["ray"]["specialities"] = ["time"]
		Rooms.process_staff_block()
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "distracted crafter made nothing")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 1000)
		GameData.HIRING_TRAITS["distracted"]["skipChance"] = 0.2
	)

	run_case("eager_staffer_earns_scaled_role_xp_only", func():
		_setup()
		GameState.state["contacts"]["tomasz"]["cultivatingXP"] = 0
		Contacts.award_contact_xp("tomasz", "cultivating", 10)
		assert_eq(GameState.state["contacts"]["tomasz"]["cultivatingXP"], 13, "10 x 1.25 rounds to 13")
		GameState.state["contacts"]["tomasz"]["salesXP"] = 0
		Contacts.award_contact_xp("tomasz", "sales", 10)
		assert_eq(GameState.state["contacts"]["tomasz"]["salesXP"], 10, "non-role skill unscaled")
	)


# _setup(), priya hired, world day moved to the next Monday.
func _setup_hired_on_monday() -> void:
	_setup()
	GameState.state["business"]["float"] = 5000
	Hiring.hire("priya")
	var day: int = GameState.state["world"]["day"]
	while not Calendar.is_monday(day):
		day += 1
	GameState.state["world"]["day"] = day
	Rng.set_seed(11)


func _app_ids() -> Array:
	return PhoneApps.apps().map(func(app): return app["id"])


# Pot running, Station and Lab built, Tuesday day 9.
func _setup() -> void:
	GameState.reset()
	GameData.HIRING_MARKET["poachChance"] = 0.1
	GameState.state["world"]["day"] = 9
	Business.activate()
	GameState.state["flags"]["bizA1JamesJoined"] = true
	GameState.state["home"]["rooms"] = ["veinStation", "lab"]
