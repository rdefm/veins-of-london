extends "res://tests/test_base.gd"

# systems/muscle.gd: guard records, names, traits, weights and wages.

const Fixtures := preload("res://tests/support/fixtures.gd")
const NodeQuery := preload("res://tests/support/node_query.gd")
const RUN_CAP := 400


func _guard(level: int, traits: Array, nickname: String = "") -> Dictionary:
	return { "id": "gx", "name": "Dee Okafor", "nickname": nickname, "level": level, "xp": 0, "traits": traits,
		"post": "reserve", "injuredUntilDay": 0, "trainingUntilDay": 0 }


func _is_pure(node: Variant) -> bool:
	if node is Dictionary:
		for k in node:
			if not _is_pure(node[k]):
				return false
		return true
	if node is Array:
		for v in node:
			if not _is_pure(v):
				return false
		return true
	return typeof(node) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]


func run() -> void:
	_posting_cases()
	_xp_cases()
	run_case("state_starts_empty_and_holds_only_primitives", func():
		GameState.reset()
		var m: Dictionary = GameState.state["muscle"]
		assert_eq(m["guards"], [])
		assert_eq(m["former"], [])
		Rng.set_seed(1)
		m["guards"].append(Muscle.create_guard(3))
		assert_true(_is_pure(m), "pure data")
		var round_trip: Variant = JSON.parse_string(JSON.stringify(m))
		assert_eq(round_trip["guards"][0]["name"], m["guards"][0]["name"])
	)

	run_case("level_table_matches_the_spec_and_comes_from_json", func():
		GameState.reset()
		var weights := [1.0, 1.25, 1.5, 1.75, 2.0]
		var wages := [500, 600, 750, 900, 1100]
		var odds := [50, 30, 15, 5, 0]
		var xp := [0, 50, 100, 200, 400]
		for i in 5:
			var row: Dictionary = Muscle.level_row(i + 1)
			assert_eq(Muscle.level_weight(i + 1), weights[i])
			assert_eq(Muscle.level_wage(i + 1), wages[i])
			assert_eq(int(row["boardOdds"]), odds[i])
			assert_eq(int(row["xpToReach"]), xp[i])
	)

	run_case("all_thirteen_traits_are_defined_with_text", func():
		assert_eq(GameData.MUSCLE_TRAITS.size(), 13)
		for id in GameData.MUSCLE_TRAITS:
			var t: Dictionary = GameData.MUSCLE_TRAITS[id]
			assert_true(not String(t["label"]).is_empty() and not String(t["effect"]).is_empty(), id)
			assert_true(["positive", "mixed", "negative"].has(t["kind"]), id)
			assert_true(t["params"] is Dictionary and not t["params"].is_empty(), id)
	)

	run_case("traits_roll_one_or_two_and_never_a_blocked_pair", func():
		GameState.reset()
		Rng.set_seed(42)
		var seconds := 0
		for i in RUN_CAP:
			var traits := Muscle.roll_traits()
			assert_true(traits.size() == 1 or traits.size() == 2, "one or two")
			if traits.size() == 2:
				seconds += 1
				assert_true(traits[0] != traits[1], "distinct")
				assert_true(not Muscle.traits_blocked(traits[0], traits[1]), "not blocked: %s" % [traits])
		assert_true(seconds > RUN_CAP * 0.15 and seconds < RUN_CAP * 0.35, "about 25%% second traits, got %d" % seconds)
		for pair in [["solid", "glassJaw"], ["quickStudy", "slowLearner"], ["watchful", "flaky"], ["quickStudy", "lazy"]]:
			assert_true(Muscle.traits_blocked(pair[0], pair[1]) and Muscle.traits_blocked(pair[1], pair[0]), "%s" % [pair])
	)

	run_case("trait_effects_stack_multiplicatively", func():
		GameState.reset()
		assert_eq(Muscle.wage(_guard(1, [])), 500)
		assert_eq(Muscle.wage(_guard(1, ["cheap", "mouthy"])), int(round(500 * 0.8 * 1.1)))
		assert_eq(Muscle.wage(_guard(3, ["cheap"])), 600)
		assert_almost_eq(Muscle.trait_mult(_guard(1, ["brawler", "hothead"]), "attackMult"), 1.5625, 0.0001)
		assert_almost_eq(Muscle.trait_mult(_guard(1, ["hothead"]), "hpMult"), 0.8, 0.0001)
	)

	run_case("repel_weight_is_level_plus_trait_modifiers", func():
		GameState.reset()
		assert_eq(Muscle.weight(_guard(2, ["watchful"])), 1.25, "fight weight ignores repel traits")
		assert_eq(Muscle.repel_weight(_guard(2, ["watchful"])), 1.5)
		assert_eq(Muscle.repel_weight(_guard(2, ["mouthy"])), 1.5)
		assert_eq(Muscle.repel_weight(_guard(2, ["flaky"])), 1.0)
		assert_eq(Muscle.repel_weight(_guard(4, ["brawler"])), 1.75)
	)

	run_case("names_are_unique_across_current_and_former_and_some_get_nicknames", func():
		GameState.reset()
		Rng.set_seed(7)
		var seen := {}
		var nicknamed := 0
		for i in RUN_CAP:
			var g := Muscle.create_guard(1)
			assert_true(not seen.has(g["name"]), "duplicate %s" % g["name"])
			seen[g["name"]] = true
			if not String(g["nickname"]).is_empty():
				nicknamed += 1
			# Alternate between current and former so both lists block repeats.
			if i % 2 == 0:
				GameState.state["muscle"]["guards"].append(g)
			else:
				GameState.state["muscle"]["former"].append(g)
		assert_true(nicknamed > RUN_CAP * 0.08 and nicknamed < RUN_CAP * 0.25, "about 15%% nicknames, got %d" % nicknamed)
	)

	run_case("short_and_full_names", func():
		assert_eq(Muscle.short_name(_guard(1, [])), "Dee O.")
		assert_eq(Muscle.full_name(_guard(1, [], "Spanner")), "Dee \"Spanner\" O.")
		assert_eq(Muscle.full_name(_guard(1, [])), "Dee O.")
	)

	run_case("name_pools_are_big_enough", func():
		assert_eq(GameData.MUSCLE_FIRST_NAMES.size(), 60)
		assert_eq(GameData.MUSCLE_SURNAMES.size(), 60)
		assert_true(GameData.MUSCLE_NICKNAMES.size() >= 20)
	)

	run_case("create_guard_clamps_level_and_starts_in_reserve_at_that_levels_xp", func():
		GameState.reset()
		Rng.set_seed(3)
		var g := Muscle.create_guard(9)
		assert_eq(g["level"], 5)
		assert_eq(g["xp"], 400)
		assert_eq(g["post"], "reserve")
		var h := Muscle.create_guard(1)
		assert_true(g["id"] != h["id"], "ids advance")
	)

	run_case("security_office_costs_2500_needs_townhouse_and_gates_can_manage", func():
		GameState.reset()
		var room: Dictionary = GameData.HOME_ROOMS["securityOffice"]
		assert_eq(room["cost"], 2500)
		assert_eq(room["minTier"], "townhouse")
		assert_true(not Muscle.can_manage(), "no room, no management")
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		assert_true(not Home.add_room("securityOffice")["ok"], "flat is too low")
		GameState.state["home"]["tier"] = "townhouse"
		assert_true(Home.add_room("securityOffice")["ok"])
		assert_eq(GameState.state["player"]["cash"], 97500)
		assert_true(Muscle.can_manage())
	)

	run_case("buying_the_office_sets_the_intro_flag_once_and_stocks_the_board", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "townhouse"
		assert_true(not GameState.state["flags"]["securityOfficeBought"])
		Home.add_room("securityOffice")
		assert_true(GameState.state["flags"]["securityOfficeBought"])
		assert_eq(Muscle.board().size(), 4)
		# Lose the room and re-buy: the flag stays set, and the existing board isn't re-rolled.
		var ids: Array = Muscle.board().map(func(c): return c["id"])
		GameState.state["home"]["rooms"].erase("securityOffice")
		Home.add_room("securityOffice")
		assert_true(GameState.state["flags"]["securityOfficeBought"], "never cleared")
		assert_eq(Muscle.board().map(func(c): return c["id"]), ids, "re-buy doesn't re-roll")
	)

	run_case("board_level_odds_hold_over_a_seeded_run_and_never_roll_level_5", func():
		GameState.reset()
		Rng.set_seed(11)
		var counts := [0, 0, 0, 0, 0, 0]
		var n := RUN_CAP * 10
		for i in n:
			counts[Muscle.roll_board_level()] += 1
		assert_eq(counts[5], 0, "no level 5")
		assert_true(absf(counts[1] / float(n) - 0.50) < 0.03, "L1 about 50%")
		assert_true(absf(counts[2] / float(n) - 0.30) < 0.03, "L2 about 30%")
		assert_true(absf(counts[3] / float(n) - 0.15) < 0.03, "L3 about 15%")
		assert_true(absf(counts[4] / float(n) - 0.05) < 0.02, "L4 about 5%")
	)

	run_case("roll_board_makes_four_unique_cards_in_reserve", func():
		GameState.reset()
		Rng.set_seed(5)
		Muscle.roll_board()
		var cards := Muscle.board()
		assert_eq(cards.size(), 4)
		var names := {}
		for c in cards:
			names[c["name"]] = true
			assert_eq(c["post"], "reserve")
			assert_true(c["level"] < 5)
		assert_eq(names.size(), 4, "unique names")
	)

	run_case("former_guards_return_as_they_left_with_injuries_cleared_and_the_tag", func():
		GameState.reset()
		Rng.set_seed(2)
		var old := Muscle.create_guard(4)
		old["xp"] = 250
		old["injuredUntilDay"] = 99
		old["post"] = "home"
		Muscle.add_former(old)
		var returned := 0
		for i in 100:
			Muscle.roll_board()
			for c in Muscle.board():
				if c["id"] == old["id"]:
					returned += 1
					assert_eq(c["name"], old["name"])
					assert_eq(c["level"], 4)
					assert_eq(c["xp"], 250)
					assert_eq(c["traits"], old["traits"])
					assert_eq(c["injuredUntilDay"], 0)
					assert_eq(c["post"], "reserve")
					assert_true(c["returning"], "tagged")
		# Each of 4 cards is 10% former, but one former fills at most one slot.
		assert_true(returned >= 20 and returned <= 45, "about 34 of 100 boards: %d" % returned)
	)

	run_case("no_former_means_no_returning_cards", func():
		GameState.reset()
		Rng.set_seed(8)
		for i in 20:
			Muscle.roll_board()
			for c in Muscle.board():
				assert_true(not c.has("returning"))
	)

	run_case("hire_pays_the_prorated_advance_empties_the_slot_and_lands_in_reserve", func():
		GameState.reset()
		Rng.set_seed(4)
		GameState.state["home"]["rooms"] = ["securityOffice"]
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(8) + 3
		GameState.state["player"]["cash"] = 10000
		Muscle.roll_board()
		var card: Dictionary = Muscle.board()[1]
		var advance := GuardUpkeep.guard_hire_advance(card)
		assert_eq(advance, Business.prorated_wage(Muscle.wage(card), 4), "4 days left from Thursday")
		var result := Muscle.hire(1)
		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["cash"], 10000 - advance)
		assert_eq(Muscle.board()[1], null, "slot stays empty")
		assert_eq(Muscle.guards().size(), 1)
		assert_eq(Muscle.guards()[0]["id"], card["id"])
		assert_eq(Muscle.guards()[0]["post"], "reserve")
		assert_true(not Muscle.hire(1)["ok"], "no second hire from an empty slot")
		assert_eq(Muscle.guards().size(), 1)
	)

	run_case("hire_refused_without_cash_or_without_the_room", func():
		GameState.reset()
		Rng.set_seed(4)
		Muscle.roll_board()
		GameState.state["player"]["cash"] = 100000
		assert_true(not Muscle.hire(0)["ok"], "no Security Office")
		GameState.state["home"]["rooms"] = ["securityOffice"]
		GameState.state["player"]["cash"] = 0
		assert_true(not Muscle.hire(0)["ok"], "no cash")
		assert_eq(Muscle.guards(), [])
		assert_true(Muscle.board()[0] != null, "card kept")
	)

	run_case("hiring_a_returning_guard_takes_them_off_the_former_list", func():
		GameState.reset()
		GameState.state["home"]["rooms"] = ["securityOffice"]
		GameState.state["player"]["cash"] = 10000
		Rng.set_seed(6)
		var old := Muscle.create_guard(2)
		Muscle.add_former(old)
		var card: Dictionary = old.duplicate(true)
		card["returning"] = true
		GameState.state["muscle"]["board"]["cards"] = [card, null, null, null]
		assert_true(Muscle.hire(0)["ok"])
		assert_eq(Muscle.former(), [])
		assert_true(not Muscle.guards()[0].has("returning"))
	)

	run_case("dismiss_moves_to_former_with_no_refund_even_when_injured", func():
		GameState.reset()
		GameState.state["home"]["rooms"] = ["securityOffice"]
		GameState.state["player"]["cash"] = 500
		Rng.set_seed(7)
		var g := Muscle.create_guard(2)
		g["injuredUntilDay"] = 50
		Muscle.guards().append(g)
		assert_true(Muscle.dismiss(g["id"])["ok"])
		assert_eq(Muscle.guards(), [])
		assert_eq(Muscle.former().size(), 1)
		assert_eq(Muscle.former()[0]["name"], g["name"])
		assert_eq(GameState.state["player"]["cash"], 500, "no refund")
		assert_true(not Muscle.dismiss(g["id"])["ok"], "already gone")
	)

	run_case("former_list_is_capped_at_20_oldest_dropped", func():
		GameState.reset()
		Rng.set_seed(9)
		var first_id := ""
		for i in 25:
			var g := Muscle.create_guard(1)
			if i == 0:
				first_id = g["id"]
			Muscle.add_former(g)
		assert_eq(Muscle.former().size(), 20)
		assert_true(Muscle.former().all(func(f): return f["id"] != first_id), "oldest dropped")
	)

	run_case("board_rolls_on_monday_only_with_the_room_and_only_once_a_day", func():
		GameState.reset()
		Rng.set_seed(10)
		var monday := Calendar.monday_on_or_after(8)
		GameState.state["world"]["day"] = monday
		Muscle.roll_board_if_due()
		assert_eq(Muscle.board(), [], "no room, no roll")
		GameState.state["home"]["rooms"] = ["securityOffice"]
		Muscle.roll_board_if_due()
		assert_eq(Muscle.board().size(), 4)
		var ids: Array = Muscle.board().map(func(c): return c["id"])
		Muscle.roll_board_if_due()
		assert_eq(Muscle.board().map(func(c): return c["id"]), ids, "same day, no re-roll")
		GameState.state["world"]["day"] = monday + 1
		Muscle.roll_board_if_due()
		assert_eq(Muscle.board().map(func(c): return c["id"]), ids, "not a Monday")
		GameState.state["world"]["day"] = monday + 7
		Muscle.roll_board_if_due()
		assert_true(Muscle.board().map(func(c): return c["id"]) != ids, "next Monday rerolls")
	)

	run_case("monday_bill_sums_each_guards_own_wage_reserve_included", func():
		GameState.reset()
		Rng.set_seed(12)
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(8)
		var a := Muscle.create_guard(1)
		var b := Muscle.create_guard(3)
		a["traits"] = []
		b["traits"] = ["cheap"]
		Muscle.guards().append(a)
		Muscle.guards().append(b)
		var expected := Muscle.wage(a) + Muscle.wage(b)
		assert_eq(GuardUpkeep.next_monday_bill(), expected)
		GameState.state["player"]["cash"] = 10000
		var result := GuardUpkeep.pay_monday_bill()
		assert_true(result["billed"] and not result["short"])
		assert_eq(result["due"], expected)
		assert_eq(GameState.state["player"]["cash"], 10000 - expected)
	)


# ── posting ────────────────────────────────────────────────────────────

func _managed() -> void:
	GameState.reset()
	Rng.set_seed(3)
	GameState.state["home"]["rooms"] = ["securityOffice"]
	Fixtures.seed_vein("v1", 50)


func _reserve_guard(level: int = 1) -> String:
	var g := Muscle.create_guard(level)
	Muscle.guards().append(g)
	return g["id"]


func _reserve_guard_with_no_traits() -> String:
	var g := Muscle.create_guard(1)
	g["traits"] = []
	Muscle.guards().append(g)
	return g["id"]


func _posting_cases() -> void:
	run_case("posting_needs_the_room_a_real_post_and_an_available_guard", func():
		_managed()
		var id := _reserve_guard()
		GameState.state["home"]["rooms"] = []
		assert_true(not Muscle.post(id, "home")["ok"], "no Security Office")
		GameState.state["home"]["rooms"] = ["securityOffice"]
		assert_true(not Muscle.post(id, "nowhere")["ok"], "no such post")
		Muscle.guard(id)["injuredUntilDay"] = GameState.state["world"]["day"] + 2
		assert_true(not Muscle.post(id, "home")["ok"], "injured")
		Muscle.guard(id)["injuredUntilDay"] = 0
		Muscle.guard(id)["trainingUntilDay"] = GameState.state["world"]["day"] + 1
		assert_true(not Muscle.post(id, "v1")["ok"], "in training")
		Muscle.guard(id)["trainingUntilDay"] = 0
		assert_true(Muscle.post(id, "v1")["ok"])
		assert_eq(Muscle.guard(id)["post"], "v1")
		assert_true(Muscle.post(id, "reserve")["ok"], "back to Reserve")
	)

	run_case("a_post_holds_four_and_reserve_holds_any_number", func():
		_managed()
		var ids: Array = []
		for i in 6:
			ids.append(_reserve_guard())
		for i in 4:
			assert_true(Muscle.post(ids[i], "v1")["ok"])
		assert_true(not Muscle.post(ids[4], "v1")["ok"], "v1 is full")
		assert_true(Muscle.post(ids[4], "home")["ok"], "HQ has its own four")
		assert_true(Muscle.post(ids[0], "v1")["ok"], "re-posting to the same post isn't blocked by the cap")
		assert_eq(Muscle.cap("reserve"), -1)
		assert_eq(Muscle.reserve().size(), 1)
		for id in ids:
			Muscle.post(id, "reserve")
		assert_eq(Muscle.reserve().size(), 6)
	)

	run_case("counts_and_kit_capacity_equal_available_guards_posted_there", func():
		_managed()
		var vein: Dictionary = Cultivating.find_vein("v1")
		var ids: Array = []
		for i in 3:
			ids.append(_reserve_guard())
			Muscle.post(ids[i], "v1")
		Muscle.post(_reserve_guard(), "home")
		assert_eq(Cultivating.vein_guard_count(vein), 3)
		assert_eq(Home.get_guard_count(), 1)
		assert_eq(GuardKit.capacity(vein), 3 * int(GameData.GUARD_KIT["slotsPerGuard"]))
		assert_eq(GuardKit.hq_capacity(), int(GameData.GUARD_KIT["hqSlotsPerGuard"]))
		Muscle.guard(ids[0])["injuredUntilDay"] = GameState.state["world"]["day"] + 3
		assert_eq(Cultivating.vein_guard_count(vein), 2, "an injured guard isn't a body")
		assert_eq(GuardKit.capacity(vein), 2 * int(GameData.GUARD_KIT["slotsPerGuard"]))
	)

	run_case("an_all_l1_roster_matches_the_old_flat_numbers", func():
		_managed()
		var vein: Dictionary = Cultivating.find_vein("v1")
		vein["security"] = "warded"
		for i in 3:
			Muscle.post(_reserve_guard_with_no_traits(), "v1")
		assert_eq(Cultivating.vein_raid_resist(vein), 35 + 3 * 20, "resist: ward + 20 per guard")
		assert_almost_eq(Raiding.guard_repel_chance(Cultivating.vein_guard_count(vein)), 0.45, 0.0001, "repel: 15% per guard")
		assert_eq(GuardKit.capacity(vein), 6, "kit: 2 slots per guard")
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(8)
		assert_eq(GuardUpkeep.next_monday_bill(), 3 * GuardUpkeep.weekly_wage(), "bill: weekly wage each")
	)

	run_case("level_raises_resist_and_repel_and_repel_traits_leave_resist_alone", func():
		_managed()
		var vein: Dictionary = Cultivating.find_vein("v1")
		vein["security"] = "warded"
		var g := Muscle.create_guard(3)
		g["traits"] = ["watchful"]
		Muscle.guards().append(g)
		Muscle.post(g["id"], "v1")
		assert_eq(Cultivating.vein_raid_resist(vein), 35 + 30, "resist: 20 x weight 1.5")
		assert_almost_eq(Muscle.post_repel_weight_sum("v1"), 1.75, 0.0001)
		assert_almost_eq(Raiding.guard_repel_chance(Cultivating.vein_repel_weight(vein)), 0.2625, 0.0001)
		g["traits"] = ["flaky"]
		assert_eq(Cultivating.vein_raid_resist(vein), 65, "flaky: resist unchanged")
		assert_almost_eq(Muscle.post_repel_weight_sum("v1"), 1.25, 0.0001)
	)

	run_case("repel_caps_at_75_before_kit_and_90_with_kit", func():
		_managed()
		assert_almost_eq(Raiding.guard_repel_chance(9.0), 0.75, 0.0001)
		var every_type: Dictionary = {}
		for recipe_key in GameData.GUARD_KIT["items"]:
			every_type[recipe_key] = { "1": 1 }
		assert_almost_eq(GuardKit.repel_chance_with(Raiding.guard_repel_chance(9.0), every_type), 0.90, 0.0001)
	)

	run_case("hq_raid_reduction_scales_by_guard_weight", func():
		_managed()
		var base := Home.get_home_raid_chance()
		var g := Muscle.create_guard(5)
		g["traits"] = []
		Muscle.guards().append(g)
		Muscle.post(g["id"], "home")
		assert_almost_eq(base - Home.get_home_raid_chance(), 0.05 * 2.0, 0.0001)
	)

	run_case("security_score_examples_and_bands", func():
		_managed()
		var vein: Dictionary = Cultivating.find_vein("v1")
		vein["security"] = "warded"
		assert_eq(Muscle.vein_security_score(vein), 40, "warded alone")
		var g := Muscle.create_guard(1)
		g["traits"] = []
		Muscle.guards().append(g)
		Muscle.post(g["id"], "v1")
		assert_eq(Muscle.vein_security_score(vein), 52, "warded + 1 L1")
		assert_eq(Muscle.score_band(24), "Exposed")
		assert_eq(Muscle.score_band(25), "Light")
		assert_eq(Muscle.score_band(49), "Light")
		assert_eq(Muscle.score_band(50), "Solid")
		assert_eq(Muscle.score_band(74), "Solid")
		assert_eq(Muscle.score_band(75), "Fortified")
		assert_eq(Muscle.score_text("v1"), "52 · Solid")
		assert_eq(Muscle.score_text("reserve"), "")
	)

	run_case("the_security_screen_post_actions_all_go_through_muscle_post", func():
		_managed()
		var id := _reserve_guard()
		var screen := SecurityScreen.new()
		screen._ready()
		var assign := NodeQuery.find_button(screen, "+ Assign")
		assert_true(assign != null, "Posts tab offers + Assign")
		assign.pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "guard_assign")
		var layer := ModalLayer.new()
		layer._ready()
		var row := layer.find_children("AssignRow_%s" % id, "Button", true, false)
		assert_eq(row.size(), 1, "Reserve guards are the choices")
		(row[0] as Button).pressed.emit()
		assert_eq(Muscle.guard(id)["post"], "home")
		layer.free()
		screen._refresh()
		var back := screen.find_children("ToReserve_%s" % id, "Button", true, false)
		assert_eq(back.size(), 1, "→ Reserve on a posted guard")
		(back[0] as Button).pressed.emit()
		assert_eq(Muscle.guard(id)["post"], "reserve")
		screen.free()
	)

	run_case("an_empty_reserve_offers_a_hire_link_in_the_assign_sheet", func():
		_managed()
		Modal.open("guard_assign", { "place": "home" })
		var layer := ModalLayer.new()
		layer._ready()
		var link := layer.find_children("HireLink", "Button", true, false)
		assert_eq(link.size(), 1)
		assert_eq((link[0] as Button).text, "No one in reserve — Hire ›")
		layer.free()
	)

	run_case("the_post_picker_lists_hq_every_vein_and_reserve", func():
		_managed()
		var id := _reserve_guard()
		Modal.open("guard_post", { "guardId": id })
		var layer := ModalLayer.new()
		layer._ready()
		for place_id in ["home", "v1", "reserve"]:
			assert_true(NodeQuery.find_button(layer, SecurityScreen.place_header(place_id)) != null, "row for %s" % place_id)
		NodeQuery.find_button(layer, SecurityScreen.place_header("v1")).pressed.emit()
		assert_eq(Muscle.guard(id)["post"], "v1")
		layer.free()
	)


# ── XP, levels, training ──

func _posted_guard(post_id: String, level: int, traits: Array) -> Dictionary:
	var g := Muscle.create_guard(level)
	g["traits"] = traits
	g["post"] = post_id
	Muscle.guards().append(g)
	return g


func _level_notes() -> Array:
	return GameState.state["notifications"].filter(func(n): return String(n["text"]).contains("is now level"))


func _xp_cases() -> void:
	run_case("guard_ally_stats_scale_by_weight_and_traits", func():
		var plain := Combat.build_guard_ally()
		assert_eq(plain["hpMax"], 30, "plain L1 block")
		var g := _guard(3, ["brawler", "solid"])
		var ally := Combat.build_guard_ally(g)
		assert_eq(ally["hpMax"], int(round(30 * 1.5 * 1.25)), "weight x Solid")
		assert_eq(ally["attackMax"], int(round(10 * 1.5 * 1.25)), "weight x Brawler")
		assert_eq(ally["name"], "Dee O.")
		assert_eq(ally["guardLevel"], 3)
		var glass := Combat.build_guard_ally(_guard(1, ["glassJaw"]))
		assert_eq(glass["hpMax"], int(round(30 * 0.75)))
	)

	run_case("injure_drops_to_reserve_for_trait_adjusted_days_and_counts_down", func():
		_managed()
		var g := _posted_guard("home", 1, [])
		var tough := _posted_guard("home", 1, ["hardToKeepDown"])
		var day: int = GameState.state["world"]["day"]
		Muscle.injure(g["id"])
		Muscle.injure(tough["id"])
		assert_eq(g["post"], "reserve")
		assert_eq(Muscle.injury_days_left(g), 3)
		assert_eq(Muscle.injury_days_left(tough), 1)
		assert_true(not Muscle.post(g["id"], "home")["ok"], "unpostable")
		assert_true(not Muscle.train(g["id"])["ok"], "untrainable")
		GameState.state["world"]["day"] = day + 3
		Muscle.daily_tick()
		assert_eq(g["injuredUntilDay"], 0, "healed")
		assert_true(Muscle.is_available(g["id"]))
	)

	run_case("settle_guard_allies_pays_xp_and_injures_only_the_koed", func():
		_managed()
		var a := _posted_guard("home", 1, [])
		var b := _posted_guard("home", 1, [])
		var ally_a := Combat.build_guard_ally(a)
		var ally_b := Combat.build_guard_ally(b)
		ally_b["koed"] = true
		Combat._settle_guard_allies([ally_a, ally_b])
		assert_eq(a["xp"], 3.0)
		assert_eq(b["xp"], 3.0, "XP win or lose")
		assert_eq(Muscle.injury_days_left(a), 0)
		assert_eq(Muscle.injury_days_left(b), 3)
	)

	run_case("passive_xp_only_for_available_posted_guards", func():
		_managed()
		var posted := _posted_guard("v1", 1, [])
		var lazy := _posted_guard("v1", 1, ["lazy"])
		var idle := _posted_guard("reserve", 1, [])
		var hurt := _posted_guard("home", 1, [])
		hurt["injuredUntilDay"] = GameState.state["world"]["day"] + 2
		Muscle.daily_tick()
		assert_eq(posted["xp"], 1.0, "posted earns +1")
		assert_eq(lazy["xp"], 0, "Lazy earns none")
		assert_eq(idle["xp"], 0, "Reserve earns none")
		assert_eq(hurt["xp"], 0, "injured earns none")
	)

	run_case("xp_multipliers_apply_to_every_source", func():
		_managed()
		var quick := _posted_guard("v1", 1, ["quickStudy"])
		var slow := _posted_guard("v1", 1, ["slowLearner"])
		Muscle.award_xp(quick["id"], Muscle.XP_PASSIVE)
		Muscle.award_xp(slow["id"], Muscle.XP_PASSIVE)
		assert_eq(quick["xp"], 1.5)
		assert_eq(slow["xp"], 0.5)
		Muscle.award_xp(quick["id"], Muscle.XP_REPEL)
		Muscle.award_xp(slow["id"], Muscle.XP_REPEL)
		assert_eq(quick["xp"], 9.0, "1.5 + 5 x 1.5")
		assert_eq(slow["xp"], 3.0, "0.5 + 5 x 0.5")
		Muscle.award_xp(quick["id"], Muscle.XP_TRAINING)
		assert_eq(quick["xp"], 24.0, "training x1.5 too")
	)

	run_case("repel_xp_goes_to_each_available_guard_at_the_post", func():
		_managed()
		var a := _posted_guard("v1", 1, [])
		var b := _posted_guard("v1", 1, [])
		var hurt := _posted_guard("v1", 1, [])
		hurt["injuredUntilDay"] = GameState.state["world"]["day"] + 2
		var other := _posted_guard("home", 1, [])
		Muscle.award_repel_xp("v1")
		assert_eq(a["xp"], 5.0)
		assert_eq(b["xp"], 5.0)
		assert_eq(hurt["xp"], 0, "uncounted")
		assert_eq(other["xp"], 0, "other post")
	)

	run_case("hq_repel_success_awards_repel_xp", func():
		_managed()
		var home_guards: Array = []
		for i in 4:
			home_guards.append(_posted_guard("home", 5, []))
		var won := false
		for seed in range(1, 60):
			Rng.set_seed(seed)
			if Home._guards_repel_pending_raid():
				won = true
				break
		assert_true(won, "some seed repels")
		assert_eq(home_guards[0]["xp"], 405.0, "400 for level 5 plus 5")
	)

	run_case("level_ups_at_thresholds_with_one_notification_each", func():
		_managed()
		var g := _posted_guard("v1", 1, [])
		g["xp"] = 49.0
		Muscle.award_xp(g["id"], Muscle.XP_PASSIVE)
		assert_eq(g["level"], 2)
		assert_eq(_level_notes().size(), 1)
		g["xp"] = 399.0
		g["level"] = 4
		Muscle.award_xp(g["id"], Muscle.XP_PASSIVE)
		assert_eq(g["level"], 5)
		assert_eq(_level_notes().size(), 2)
		Muscle.award_xp(g["id"], Muscle.XP_REPEL)
		assert_eq(g["level"], 5, "top level holds")
		assert_eq(_level_notes().size(), 2)
	)

	run_case("a_level_up_keeps_this_weeks_bill_and_raises_the_next", func():
		_managed()
		var g := _posted_guard("v1", 1, [])
		g["xp"] = 49.0
		var before := GuardUpkeep.muscle_wage_total()
		assert_eq(before, 500)
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(8) + 2
		Muscle.daily_tick()
		assert_eq(g["level"], 2)
		assert_eq(GuardUpkeep.muscle_wage_total(), 600, "the next Monday bill uses the new wage")
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(8)
		GameState.state["player"]["cash"] = 10000
		assert_eq(GuardUpkeep.pay_monday_bill()["due"], 600)
	)

	run_case("train_charges_gives_xp_and_takes_the_guard_away_for_a_day", func():
		_managed()
		var g := _posted_guard("v1", 3, [])
		g["xp"] = 100.0
		GameState.state["player"]["cash"] = 1000
		var day: int = GameState.state["world"]["day"]
		var result := Muscle.train(g["id"])
		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["cash"], 400, "£200 x level 3")
		assert_eq(g["xp"], 110.0)
		assert_eq(g["post"], "v1", "post kept")
		assert_true(not Muscle.is_available(g["id"]), "away")
		assert_eq(Muscle.available_at("v1").size(), 0, "not counted at the post")
		assert_true(not Muscle.train(g["id"])["ok"], "can't train while away")
		GameState.state["world"]["day"] = day + 1
		Muscle.daily_tick()
		assert_true(Muscle.is_available(g["id"]), "back next day")
		assert_eq(g["trainingUntilDay"], 0)
		assert_eq(Muscle.available_at("v1").size(), 1)
	)

	run_case("train_refused_when_unaffordable_or_unavailable", func():
		_managed()
		var g := _posted_guard("v1", 2, [])
		GameState.state["player"]["cash"] = 399
		var r := Muscle.train(g["id"])
		assert_true(not r["ok"])
		assert_eq(GameState.state["player"]["cash"], 399, "nothing taken")
		assert_eq(g["xp"], 50, "no XP")
		GameState.state["player"]["cash"] = 5000
		g["injuredUntilDay"] = GameState.state["world"]["day"] + 2
		assert_true(not Muscle.train(g["id"])["ok"], "injured")
		assert_eq(GameState.state["player"]["cash"], 5000)
	)
