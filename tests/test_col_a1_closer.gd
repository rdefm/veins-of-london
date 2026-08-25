extends "res://tests/test_base.gd"

# collective1-16, spec.md §6.15/§8.6: S14 (col_a1_closer), Act 1's ending --
# the guaranteed scripted_seed (Whitechapel, rich, life -- never touching
# player.orichalchum, ignoring siteCap), the "I'm in"/"Not yet" choice that's
# now the only path to Factions.join("collective"), and the deferred-join
# follow-up (col_a1_deferred_join) declining leaves behind. Also covers
# Collective.maybe_trigger_closer()'s delivery condition (spec §10.4) and
# ContactCards.build_faction_card()'s suppressed Join button (spec §8.6).


func _play_event(event_id: String) -> void:
	Events.start_event(event_id)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


# Generic driver for an event whose cards include "choice" cards: picks
# choices[i] the i-th time a choice card is reached, in order. advance()
# both resolves a normal card and (once is_awaiting_choice() has gone false
# again after choose()) steps past an already-resolved choice card, so no
# separate post-choose() advance() call is needed.
func _play_event_with_choices(event_id: String, choices: Array) -> void:
	Events.start_event(event_id)
	var choice_i := 0
	while GameState.state["event"] != null:
		if Events.is_awaiting_choice():
			Events.choose(choices[choice_i])
			choice_i += 1
		else:
			Events.advance()


func _set_all_threads_done(relation: int = 27) -> void:
	GameState.state["flags"]["colA1DesThreadDone"] = true
	GameState.state["flags"]["colA1NadiaThreadDone"] = true
	GameState.state["flags"]["colA1HakimThreadDone"] = true
	GameState.state["factions"]["collective"]["relation"] = relation


func run() -> void:
	# ── delivery: Collective.maybe_trigger_closer() (spec §10.4) ───────────

	run_case("maybe_trigger_closer_is_false_with_no_threads_done", func():
		GameState.reset()
		assert_true(not Collective.maybe_trigger_closer())
		assert_true(Messages.pending_for("hakim").is_empty())
	)

	run_case("maybe_trigger_closer_is_false_with_only_two_of_three_threads_done", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadDone"] = true
		GameState.state["flags"]["colA1NadiaThreadDone"] = true
		GameState.state["factions"]["collective"]["relation"] = 27
		assert_true(not Collective.maybe_trigger_closer())
	)

	run_case("maybe_trigger_closer_is_false_below_relation_25_even_with_all_three_threads_done", func():
		GameState.reset()
		_set_all_threads_done(24)
		assert_true(not Collective.maybe_trigger_closer())
	)

	run_case("maybe_trigger_closer_queues_the_hakim_text_once_every_condition_is_met", func():
		GameState.reset()
		_set_all_threads_done()

		assert_true(Collective.maybe_trigger_closer())

		var pending: Array = Messages.pending_for("hakim")
		assert_eq(pending.size(), 1)
		assert_eq(pending[0]["kind"], "col_a1_closer")
		assert_true(Messages.has_unread("hakim"))
	)

	run_case("maybe_trigger_closer_does_not_double_queue_on_a_repeat_call", func():
		GameState.reset()
		_set_all_threads_done()
		Collective.maybe_trigger_closer()

		assert_true(not Collective.maybe_trigger_closer())
		assert_eq(Messages.pending_for("hakim").size(), 1)
	)

	run_case("maybe_trigger_closer_is_false_once_colA1Complete_is_already_set", func():
		GameState.reset()
		_set_all_threads_done()
		GameState.state["flags"]["colA1Complete"] = true
		assert_true(not Collective.maybe_trigger_closer())
	)

	run_case("events_advance_fires_the_closer_the_moment_the_third_thread_resolution_completes", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadDone"] = true
		GameState.state["flags"]["colA1NadiaThreadDone"] = true
		GameState.state["factions"]["collective"]["relation"] = 19  # +8 below lands exactly at 27 total across S1/S7/S10/S12 in real play; here just below 25

		_seed_rescued_hakim_vein_for_handback()
		_play_event("col_a1_hakim_done")  # sets colA1HakimThreadDone, +8 relation -> 27

		assert_true(GameState.state["flags"]["colA1HakimThreadDone"])
		assert_eq(Messages.pending_for("hakim").size(), 1, "advance()'s on_complete boundary must trigger the closer automatically")
	)

	# ── scripted_seed (spec §6.15/§10.3): the guaranteed, ore-free seed ─────

	run_case("scripted_seed_creates_a_claimed_rich_life_site_and_vein_in_whitechapel", func():
		GameState.reset()
		var sites_before: int = GameState.state["world"]["sites"].size()
		var veins_before: int = GameState.state["player"]["veins"].size()

		Events.apply_effects([{ "op": "scripted_seed", "district": "whitechapel", "tier": "rich", "oreType": "life" }])

		assert_eq(GameState.state["world"]["sites"].size(), sites_before + 1)
		assert_eq(GameState.state["player"]["veins"].size(), veins_before + 1)

		var site: Dictionary = GameState.state["world"]["sites"][sites_before]
		assert_eq(site["district"], "whitechapel")
		assert_eq(site["tier"], "rich")
		assert_eq(site["oreType"], "life")
		assert_true(site["claimed"])
		assert_true(site["factionVein"] == null)

		var vein: Dictionary = GameState.state["player"]["veins"][veins_before]
		assert_eq(vein["district"], "whitechapel")
		assert_eq(vein["oreType"], "life")
		assert_eq(vein["siteId"], site["id"])
		assert_eq(vein["growth"], GameData.VEIN_GROWTH["seedGrowth"])
	)

	run_case("scripted_seed_never_touches_player_orichalchum", func():
		GameState.reset()
		var ore_before: Dictionary = GameState.deep_copy(GameState.state["player"]["orichalchum"])

		Events.apply_effects([{ "op": "scripted_seed", "district": "whitechapel", "tier": "rich", "oreType": "life" }])

		assert_eq(GameState.state["player"]["orichalchum"], ore_before, "no add_ore, no seed-ore deduction -- the calc never enters inventory")
	)

	run_case("scripted_seed_ignores_whitechapel_at_siteCap", func():
		GameState.reset()
		var sites: Array = []
		for i in range(GameData.DISTRICTS["whitechapel"]["siteCap"]):
			sites.append({
				"id": "cap%d" % i, "district": "whitechapel", "tier": "fair", "oreType": "emotion",
				"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null, "hasNaturalVein": false,
			})
		GameState.state["world"]["sites"] = sites
		assert_eq(GameState.state["world"]["sites"].size(), GameData.DISTRICTS["whitechapel"]["siteCap"], "sanity: at cap")

		Events.apply_effects([{ "op": "scripted_seed", "district": "whitechapel", "tier": "rich", "oreType": "life" }])

		assert_eq(GameState.state["world"]["sites"].size(), GameData.DISTRICTS["whitechapel"]["siteCap"] + 1, "scripted creation ignores siteCap -- the cap only governs prospecting discovery")
	)

	run_case("scripted_seed_queues_the_seed_claim_and_join_line_map_events", func():
		GameState.reset()

		Events.apply_effects([{ "op": "scripted_seed", "district": "whitechapel", "tier": "rich", "oreType": "life" }])

		var queue: Array = GameState.state["mapEvents"]["queue"]
		var types: Array = []
		for entry in queue:
			types.append(entry["type"])
		assert_true(types.has("seed_claim"))
		assert_true(types.has("join_line"))
	)

	# ── join_faction op (spec §8.6): the only remaining path to joining ────

	run_case("join_faction_op_joins_when_eligible", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 25

		Events.apply_effects([{ "op": "join_faction", "faction": "collective" }])

		assert_true(GameState.state["factions"]["collective"]["joined"])
	)

	# ── S14 played straight through: "Thank him" + "I'm in" ────────────────

	run_case("playing_the_closer_with_thank_him_and_im_in_joins_and_seeds_the_vein", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 27

		_play_event_with_choices("col_a1_closer", [0, 0])  # Thank him, I'm in

		assert_true(GameState.state["event"] == null, "the event completes")
		assert_true(GameState.state["flags"]["colA1Stage"] == "complete")
		assert_true(GameState.state["flags"]["colA1Complete"])
		assert_true(GameState.state["flags"]["colA1Joined"])
		assert_true(GameState.state["factions"]["collective"]["joined"])
		assert_true(not GameState.state["flags"].get("colA1DeferredJoin", false))

		var found_seed := false
		for site in GameState.state["world"]["sites"]:
			if site["district"] == "whitechapel" and site["tier"] == "rich" and site["oreType"] == "life" and site["claimed"]:
				found_seed = true
		assert_true(found_seed)

		# Regression (bugfix: an on_complete missing a "set_screen" op leaves
		# the EventScreen stuck on a dead Continue button, per tests/
		# test_col_a1_tuition.gd's S1 comment): must navigate back to Hakim's
		# conversation, where the pending closer text was tapped from.
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	# ── S14 played straight through: "Insist on paying" + "Not yet" ────────

	run_case("playing_the_closer_with_not_yet_defers_membership", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 27

		_play_event_with_choices("col_a1_closer", [1, 1])  # Insist on paying, Not yet

		assert_true(GameState.state["flags"]["colA1Complete"])
		assert_true(GameState.state["flags"]["colA1DeferredJoin"])
		assert_true(not GameState.state["flags"].get("colA1Joined", false))
		assert_true(not GameState.state["factions"]["collective"]["joined"])
	)

	# ── ContactCards.build_faction_card(): no Join affordance for collective ──

	run_case("build_faction_card_shows_no_join_button_for_collective_even_when_eligible", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 30
		assert_true(Factions.can_join("collective"), "sanity: relation clears the gate")

		var card := ContactCards.build_faction_card("collective")
		assert_true(not _panel_contains_button_label(card, "Join"))
	)

	run_case("build_faction_card_still_shows_the_join_button_for_another_faction", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = GameData.FACTIONS["guild"]["joinRelation"]

		var card := ContactCards.build_faction_card("guild")
		assert_true(_panel_contains_button_label(card, "Join"))
	)

	# ── build_ask_des_joining_action(): the deferred-join follow-up ────────

	run_case("build_ask_des_joining_action_is_null_before_colA1DeferredJoin", func():
		GameState.reset()
		assert_true(ContactCards.build_ask_des_joining_action() == null)
	)

	run_case("build_ask_des_joining_action_surfaces_once_deferred_and_starts_the_event", func():
		GameState.reset()
		GameState.state["flags"]["colA1DeferredJoin"] = true

		var b := ContactCards.build_ask_des_joining_action() as Button
		assert_true(b != null)

		b.pressed.emit()
		assert_eq(GameState.state["event"]["eventId"], "col_a1_deferred_join")
	)

	run_case("build_ask_des_joining_action_is_null_again_once_colA1Joined", func():
		GameState.reset()
		GameState.state["flags"]["colA1DeferredJoin"] = true
		GameState.state["flags"]["colA1Joined"] = true
		assert_true(ContactCards.build_ask_des_joining_action() == null)
	)

	run_case("col_a1_deferred_join_on_complete_grants_membership", func():
		GameState.reset()
		GameState.state["flags"]["colA1DeferredJoin"] = true
		GameState.state["factions"]["collective"]["relation"] = 27

		_play_event("col_a1_deferred_join")

		assert_true(GameState.state["flags"]["colA1Joined"])
		assert_true(GameState.state["factions"]["collective"]["joined"])
		# Regression: on_complete must navigate off the event screen (see
		# col_a1_closer's own comment above).
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	# ── content sanity (PROSE-REVIEW: card text is drafted, not approved) ──

	run_case("col_a1_closer_card_10_is_the_hinge_line", func():
		var cards: Array = GameData.EVENTS["col_a1_closer"]["cards"]
		assert_true(cards[9]["text"].contains("There's no list. Nobody keeps one."))
	)


# Plants Hakim's own recovered vein (S11/S12's shape) so col_a1_hakim_done
# can actually be played through in the "advance() fires the closer
# automatically" test above, mirroring tests/test_col_a1_hakim_done.gd's own
# fixture.
func _seed_rescued_hakim_vein_for_handback() -> void:
	var site := {
		"id": "s1", "district": "whitechapel", "tier": "fair", "oreType": "emotion",
		"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false,
	}
	var vein := {
		"id": "v1", "district": "whitechapel", "oreType": "emotion", "growth": 61,
		"security": "none", "alarmUpgrades": [], "location": "Test Alley",
		"claimedOnDay": 1, "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0,
	}
	GameState.state["world"]["sites"] = [site]
	GameState.state["player"]["veins"] = [vein]
	GameState.state["collective"]["hakimVeinId"] = "v1"
	GameState.state["flags"]["colA1HakimRescued"] = true


func _panel_contains_button_label(node: Node, needle: String) -> bool:
	if node is Button and (node as Button).text.contains(needle):
		return true
	for child in node.get_children():
		if _panel_contains_button_label(child, needle):
			return true
	return false
