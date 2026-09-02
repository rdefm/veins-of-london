extends "res://tests/test_base.gd"

# collective1-10/des-sites-partial-turnin ticket 02, spec.md §6.7/§6.14/§10.3:
# S7 (col_a1_des_report), Des's thread resolution. Drives the real event JSON
# card-by-card, same idiom tests/test_col_a1_tuition.gd uses for S1-S4, plus
# the action-bar button (ContactCards.build_des_report_action(), wired into
# phone.gd's _build_action_bar) that's this scene's non-pendingMessages
# delivery. Per-site reporting (ticket 01) means this button now surfaces and
# fires per ore type, not once both are simultaneously unclaimed -- see
# col_a1_des_report_first_fate/col_a1_des_report_first_physics for the
# in-between scene and this file's own final/closing scene.


func _play_event(event_id: String) -> void:
	Events.start_event(event_id)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


func _site(id: String, ore_type: String, tier: String) -> Dictionary:
	return {
		"id": id, "district": "shoreditch", "tier": tier, "oreType": ore_type,
		"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
		"hasNaturalVein": false,
	}


func run() -> void:
	# ── delivery: the action-bar button, not a pendingMessages entry ───────

	run_case("build_des_report_action_is_null_before_the_thread_is_active", func():
		GameState.reset()
		assert_true(ContactCards.build_des_report_action() == null)
	)

	run_case("build_des_report_action_is_null_while_active_with_no_qualifying_site", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		assert_true(ContactCards.build_des_report_action() == null)
	)

	run_case("build_des_report_action_surfaces_for_a_single_qualifying_site_and_reports_it", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"].append(_site("s_fate", "fate", "fair"))

		var b := ContactCards.build_des_report_action() as Button
		assert_true(b != null)
		assert_eq(b.text, "Tell Des about the ground")

		var relation_before: int = GameState.state["factions"]["collective"]["relation"]
		b.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "col_a1_des_report_first_fate", "only one of the two required ore types is in -- the first-report scene naming the still-needed one")
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 6, "report_des_site() awards relation immediately, not deferred to the scene's on_complete")
		assert_true(Sites.find_site("s_fate")["factionVein"] != null, "reported site converts to a Collective vein immediately")
		assert_true(not GameState.state["objectives"]["col_a1_des_sites"]["complete"], "physics still outstanding")
	)

	run_case("build_des_report_action_surfaces_again_for_the_second_ore_type_and_closes_the_thread", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"].append(_site("s_fate", "fate", "fair"))
		Collective.report_des_site("fate")
		GameState.state["world"]["sites"].append(_site("s_physics", "physics", "fair"))

		var b := ContactCards.build_des_report_action() as Button
		assert_true(b != null, "button reappears once a qualifying site exists for the still-needed ore type")

		var relation_before: int = GameState.state["factions"]["collective"]["relation"]
		b.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "col_a1_des_report", "both ore types now reported -- the reworked closing scene")
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 6, "second report_des_site() call awards its own +6; the scene's on_complete must not award a further relation")
		assert_true(GameState.state["objectives"]["col_a1_des_sites"]["complete"])
	)

	run_case("build_des_report_action_is_null_again_once_colA1DesThreadDone", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"].append(_site("s_fate", "fate", "fair"))
		GameState.state["world"]["sites"].append(_site("s_physics", "physics", "fair"))
		Collective.report_des_site("fate")
		Collective.report_des_site("physics")
		GameState.state["flags"]["colA1DesThreadDone"] = true
		assert_true(ContactCards.build_des_report_action() == null)
	)

	# ── §6.14: the "ages ago" line sits between cards 2 and 3, nowhere else ──

	run_case("ages_ago_line_is_inserted_between_cards_2_and_3_and_said_by_des", func():
		var cards: Array = GameData.EVENTS["col_a1_des_report"]["cards"]
		assert_eq(cards[1]["speaker"], "Des", "card 2: the closing-the-pair line")
		assert_true(cards[2]["text"].contains("ages ago"), "card 3 (inserted): the ages-ago line")
		assert_eq(cards[2]["speaker"], "Des")
		assert_eq(cards[3]["type"], "narration", "card 4: 'you ask who', unchanged position relative to the insertion")
		assert_true(not cards[3]["text"].contains("ages ago"))
	)

	# ── §14.3: card 4 ("nobody's ever raided...") reads as a paperwork joke ──

	run_case("card_4_is_the_nobody_s_ever_raided_line", func():
		var cards: Array = GameData.EVENTS["col_a1_des_report"]["cards"]
		assert_true(cards[4]["text"].contains("Nobody's ever raided a vein they didn't know about"))
	)

	# ── site conversion: per-site at report time, not deferred to on_complete ──

	run_case("report_des_site_seeds_collective_veins_immediately_as_each_ore_type_is_reported", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"].append(_site("s_fate", "fate", "fair"))
		GameState.state["world"]["sites"].append(_site("s_physics", "physics", "fair"))
		Collective.report_des_site("fate")
		Collective.report_des_site("physics")

		var reported: Dictionary = GameState.state["objectives"]["col_a1_des_sites"]["progress"]["reportedSiteIds"]
		assert_eq(reported, { "fate": "s_fate", "physics": "s_physics" })

		var fate_site: Dictionary = Sites.find_site("s_fate")
		var physics_site: Dictionary = Sites.find_site("s_physics")
		assert_true(fate_site["factionVein"] != null, "fate site already carries a faction vein once reported")
		assert_true(physics_site["factionVein"] != null, "physics site already carries a faction vein once reported")
		assert_eq(fate_site["factionVein"]["factionId"], "collective")
		assert_eq(physics_site["factionVein"]["factionId"], "collective")
		assert_eq(fate_site["factionVein"]["growth"], GameData.VEIN_GROWTH["seedGrowth"])
		assert_eq(physics_site["factionVein"]["growth"], GameData.VEIN_GROWTH["seedGrowth"])

		var vein_ids: Array = [fate_site["factionVein"]["id"], physics_site["factionVein"]["id"]]
		assert_eq(MapEvents.pending_vein_ids(), vein_ids, "both seeds queue their seed_claim map event")
		assert_eq(MapEvents.pending_join_line_vein_ids(), vein_ids, "both also queue their join_line map event")
	)

	# ── on_complete: thread flag only -- relation is awarded per-report by
	# Collective.report_des_site(), never here (see the button tests above) ──

	run_case("on_complete_sets_the_thread_done_flag_and_awards_no_further_relation", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"].append(_site("s_fate", "fate", "fair"))
		GameState.state["world"]["sites"].append(_site("s_physics", "physics", "fair"))
		Collective.report_des_site("fate")
		Collective.report_des_site("physics")
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		_play_event("col_a1_des_report")

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before, "both +6 awards already landed via report_des_site()")
		assert_true(GameState.state["flags"]["colA1DesThreadDone"])
		# Regression (bugfix: an on_complete missing a "set_screen" op leaves
		# the EventScreen stuck on a dead Continue button, per tests/
		# test_col_a1_tuition.gd's S1 comment): must navigate back to Des's
		# conversation, where the action-bar button was tapped from.
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	# ── the two first-report scenes each land back on Des's conversation too ──

	run_case("first_report_scenes_return_to_phone_without_touching_the_thread_done_flag", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["world"]["sites"].append(_site("s_fate", "fate", "fair"))
		Collective.report_des_site("fate")

		_play_event("col_a1_des_report_first_fate")

		assert_eq(GameState.state["currentScreen"], "phone")
		assert_true(not GameState.state["flags"].get("colA1DesThreadDone", false))
	)
