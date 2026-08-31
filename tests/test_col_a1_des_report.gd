extends "res://tests/test_base.gd"

# collective1-10, spec.md §6.7/§6.14/§10.3: S7 (col_a1_des_report), Des's
# thread resolution. Drives the real event JSON card-by-card, same idiom
# tests/test_col_a1_tuition.gd uses for S1-S4, plus the action-bar button
# (ContactCards.build_des_report_action(), wired into phone.gd's
# _build_action_bar) that's this scene's non-pendingMessages delivery.


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


# col_a1_des_sites completes via per-site reporting, not a live scan --
# activates the thread, plants a matching fate + physics site, then reports
# each individually through Collective.report_des_site(), which converts
# both sites to Collective veins immediately (not deferred to col_a1_des_
# report's on_complete) and stamps colA1DesSitesFound once both are in.
func _complete_des_sites_objective() -> void:
	GameState.state["flags"]["colA1DesThreadActive"] = true
	GameState.state["world"]["sites"].append(_site("s_fate", "fate", "fair"))
	GameState.state["world"]["sites"].append(_site("s_physics", "physics", "fair"))
	Collective.report_des_site("fate")
	Collective.report_des_site("physics")


func run() -> void:
	# ── delivery: the action-bar button, not a pendingMessages entry ───────

	run_case("build_des_report_action_is_null_before_colA1DesSitesFound", func():
		GameState.reset()
		assert_true(ContactCards.build_des_report_action() == null)
	)

	run_case("build_des_report_action_surfaces_once_colA1DesSitesFound_and_starts_the_event", func():
		GameState.reset()
		_complete_des_sites_objective()
		assert_true(GameState.state["flags"]["colA1DesSitesFound"], "objective completion should set the flag")

		var b := ContactCards.build_des_report_action() as Button
		assert_true(b != null)
		assert_eq(b.text, "Tell Des about the ground")

		b.pressed.emit()
		assert_eq(GameState.state["event"]["eventId"], "col_a1_des_report")
	)

	run_case("build_des_report_action_is_null_again_once_colA1DesThreadDone", func():
		GameState.reset()
		_complete_des_sites_objective()
		GameState.state["flags"]["colA1DesThreadDone"] = true
		assert_true(ContactCards.build_des_report_action() == null)
	)

	# ── §6.14: the "ages ago" line sits between cards 2 and 3, nowhere else ──

	run_case("ages_ago_line_is_inserted_between_cards_2_and_3_and_said_by_des", func():
		var cards: Array = GameData.EVENTS["col_a1_des_report"]["cards"]
		assert_eq(cards[1]["speaker"], "Des", "card 2: the fate/physics line")
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

	# ── site conversion: now per-site at report time, not deferred to on_complete ──

	run_case("report_des_site_seeds_collective_veins_immediately_as_each_ore_type_is_reported", func():
		GameState.reset()
		_complete_des_sites_objective()
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

	# ── on_complete: relation + thread flag (faction_seed_reported_sites is
	# now an inert no-op -- both sites are already seeded by the time this
	# event's on_complete runs; see test above) ──

	run_case("on_complete_awards_8_collective_relation_and_sets_the_thread_done_flag", func():
		GameState.reset()
		_complete_des_sites_objective()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		_play_event("col_a1_des_report")

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 8)
		assert_true(GameState.state["flags"]["colA1DesThreadDone"])
		# Regression (bugfix: an on_complete missing a "set_screen" op leaves
		# the EventScreen stuck on a dead Continue button, per tests/
		# test_col_a1_tuition.gd's S1 comment): must navigate back to Des's
		# conversation, where the action-bar button was tapped from.
		assert_eq(GameState.state["currentScreen"], "phone")
	)
