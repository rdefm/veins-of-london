extends "res://tests/test_base.gd"

# collective1-09, spec.md §6.5/§6.6/§10.4: Des's two location-agnostic
# "Firm as weather" beats (S5 col_a1_firm_skirmish, S6
# col_a1_firm_intimidation) and the trigger hook that pre-empts the
# district deck draw for them (systems/collective.gd's
# maybe_trigger_weather_beat(), wired into Sites.prospect()). Real event
# JSON is driven card-by-card the same way tests/test_col_a1_tuition.gd
# drives S1-S4; the trigger hook itself is exercised directly against
# synthetic site dicts, the same idiom tests/test_district_events.gd uses
# for district-event content.


func _play_event(event_id: String) -> void:
	Events.start_event(event_id)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


# Drives an event up to (not including) its choice card.
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


func _finish_after_choice(event_id: String, choice_index: int) -> void:
	var remaining: int = GameData.EVENTS[event_id]["cards"].size() - choice_index
	for i in range(remaining):
		Events.advance()


func _site(id: String, ore_type: String, tier: String, claimed: bool = false, faction_vein: Variant = null) -> Dictionary:
	return {
		"id": id, "district": "shoreditch", "tier": tier, "oreType": ore_type,
		"bonuses": [], "discoveredDay": 1, "claimed": claimed, "factionVein": faction_vein,
		"hasNaturalVein": false,
	}


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		Rng.set_seed(seed)
		if fn.call():
			return seed
	return -1


func run() -> void:
	# ── maybe_trigger_weather_beat() -- unit seam, synthetic sites ──────────

	run_case("does_not_fire_when_colA1DesThreadActive_is_false", func():
		GameState.reset()
		var fired := Collective.maybe_trigger_weather_beat(_site("s1", "fate", "fair"))
		assert_true(not fired)
		assert_eq(GameState.state["event"], null)
	)

	run_case("does_not_fire_for_a_null_site_the_at_cap_reroll_can_produce", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		var fired := Collective.maybe_trigger_weather_beat(null)
		assert_true(not fired)
	)

	run_case("does_not_fire_for_a_site_whose_ore_type_is_not_fate_or_physics", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		var fired := Collective.maybe_trigger_weather_beat(_site("s1", "emotion", "rich"))
		assert_true(not fired)
	)

	run_case("does_not_fire_for_a_qualifying_ore_type_below_minTier", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		var fired := Collective.maybe_trigger_weather_beat(_site("s1", "fate", "poor"))
		assert_true(not fired)
	)

	run_case("does_not_fire_for_an_already_claimed_site", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		var fired := Collective.maybe_trigger_weather_beat(_site("s1", "fate", "fair", true))
		assert_true(not fired)
	)

	run_case("fires_S5_on_the_first_qualifying_site_and_sets_colA1SkirmishSeen", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		var fired := Collective.maybe_trigger_weather_beat(_site("s1", "fate", "fair"))
		assert_true(fired)
		assert_eq(GameState.state["event"]["eventId"], "col_a1_firm_skirmish")
	)

	run_case("fires_S6_on_the_next_qualifying_site_once_S5_has_already_fired", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["flags"]["colA1SkirmishSeen"] = true

		var fired := Collective.maybe_trigger_weather_beat(_site("s2", "physics", "rich"))
		assert_true(fired)
		assert_eq(GameState.state["event"]["eventId"], "col_a1_firm_intimidation")
	)

	run_case("does_not_fire_a_third_time_once_both_beats_have_been_seen", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["flags"]["colA1SkirmishSeen"] = true
		GameState.state["flags"]["colA1IntimidationSeen"] = true

		var fired := Collective.maybe_trigger_weather_beat(_site("s3", "fate", "saturated"))
		assert_true(not fired)
		assert_eq(GameState.state["event"], null)
	)

	# ── §10.4: the deck's seeded roll is provably not consumed ──────────────

	run_case("a_firing_weather_beat_consumes_zero_Rng_draws", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesThreadActive"] = true

		Rng.set_seed(12345)
		var fired := Collective.maybe_trigger_weather_beat(_site("s1", "fate", "fair"))
		assert_true(fired)
		var next_after_hook: float = Rng.randf()

		Rng.set_seed(12345)
		var fresh_first_draw: float = Rng.randf()

		assert_eq(next_after_hook, fresh_first_draw, "if the hook had consumed any Rng draw, this would no longer be the stream's first value")
	)

	# ── Sites.prospect() integration: the story beat pre-empts the deck ─────

	run_case("prospect_starts_the_weather_beat_instead_of_the_district_deck_and_records_nothing_in_recentEvents", func():
		var seed := _find_seed_for(500, func():
			GameState.reset()
			GameState.state["flags"]["colA1DesThreadActive"] = true
			var result := Sites.prospect("city")  # City's oreBias leans fate — see data/districts.json
			var site: Variant = result.get("site")
			return site != null and (site["oreType"] == "fate" or site["oreType"] == "physics") and GameData.SITE_TIER_ORDER.find(site["tier"]) >= GameData.SITE_TIER_ORDER.find("fair")
		)
		assert_true(seed != -1, "should find a qualifying-site seed within 500 tries")

		assert_eq(GameState.state["event"]["eventId"], "col_a1_firm_skirmish", "the weather beat, not the district deck, should have started")
		assert_eq(GameState.state["world"]["recentEvents"], [], "the deck draw never ran -- nothing recorded")
	)

	run_case("prospect_falls_through_to_the_ordinary_deck_when_the_thread_is_not_active", func():
		GameState.reset()
		Rng.set_seed(3)  # a seed known (test_sites.gd) to succeed below siteCap
		var result := Sites.prospect("shoreditch")
		assert_true(result["ok"])
		assert_true(GameState.state["event"] == null or GameData.EVENTS[GameState.state["event"]["eventId"]].get("deck") != null, "with the thread inactive, only an ordinary deck draw (or nothing) may have started")
	)

	# ── S5: col_a1_firm_skirmish content ─────────────────────────────────

	run_case("col_a1_firm_skirmish_on_complete_sets_colA1SkirmishSeen", func():
		GameState.reset()
		_play_event("col_a1_firm_skirmish")
		assert_true(GameState.state["flags"]["colA1SkirmishSeen"])
	)

	run_case("col_a1_firm_skirmish_moves_no_relation_and_no_site", func():
		GameState.reset()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]
		var sites_before: Array = GameState.state["world"]["sites"].duplicate(true)

		_play_event("col_a1_firm_skirmish")

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before)
		assert_eq(GameState.state["world"]["sites"], sites_before)
	)

	# ── S6: col_a1_firm_intimidation content ─────────────────────────────

	run_case("col_a1_firm_intimidation_back_off_logs_backed_off_starts_no_combat", func():
		GameState.reset()
		var choice_index := _play_to_choice("col_a1_firm_intimidation")
		Events.choose(0)  # Back off
		assert_eq(GameState.state["methodLog"]["firmFirstContact"], "backed_off")
		assert_true(not GameState.state["combat"]["active"])
		_finish_after_choice("col_a1_firm_intimidation", choice_index)
		assert_true(GameState.state["flags"]["colA1IntimidationSeen"])
	)

	run_case("col_a1_firm_intimidation_hold_your_ground_logs_held_starts_no_combat", func():
		GameState.reset()
		var choice_index := _play_to_choice("col_a1_firm_intimidation")
		Events.choose(1)  # Hold your ground
		assert_eq(GameState.state["methodLog"]["firmFirstContact"], "held")
		assert_true(not GameState.state["combat"]["active"])
		_finish_after_choice("col_a1_firm_intimidation", choice_index)
		assert_true(GameState.state["flags"]["colA1IntimidationSeen"])
	)

	run_case("col_a1_firm_intimidation_tell_them_where_to_go_logs_fought_and_starts_combat", func():
		GameState.reset()
		var choice_index := _play_to_choice("col_a1_firm_intimidation")
		Events.choose(2)  # Tell them where to go
		assert_eq(GameState.state["methodLog"]["firmFirstContact"], "fought")
		assert_true(GameState.state["combat"]["active"], "should launch the street mugging")
		assert_eq(GameState.state["combat"]["context"], "event_mugging")
	)

	run_case("all_three_branches_leave_relation_and_sites_untouched", func():
		for choice_index_to_pick in [0, 1, 2]:
			GameState.reset()
			var relation_before: int = GameState.state["factions"]["collective"]["relation"]
			var sites_before: Array = GameState.state["world"]["sites"].duplicate(true)

			var choice_index := _play_to_choice("col_a1_firm_intimidation")
			Events.choose(choice_index_to_pick)

			assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before, "choice %d must not move relation" % choice_index_to_pick)
			assert_eq(GameState.state["world"]["sites"], sites_before, "choice %d must leave both patches with the player" % choice_index_to_pick)
	)

	run_case("methodLog_starts_empty_and_only_S6_writes_to_it", func():
		GameState.reset()
		assert_eq(GameState.state["methodLog"], {}, "methodLog is seeded empty by new_game_state()")
	)

	# ── §5.7: Rewind erases the log (plans/COLLECTIVE-QUESTLINE.md §8.3) ────

	run_case("rewind_undoes_S6s_methodLog_write_like_any_other_state", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }

		Events.start_event("col_a1_firm_intimidation")
		var cards: Array = GameData.EVENTS["col_a1_firm_intimidation"]["cards"]
		for i in range(cards.size()):
			if cards[i]["type"] == "choice":
				break
			Events.advance()

		Events.choose(0)  # Back off
		assert_eq(GameState.state["methodLog"]["firmFirstContact"], "backed_off")

		var result := Events.rewind()
		assert_true(result["ok"])
		assert_eq(GameState.state["methodLog"], {}, "rewind restores methodLog to its pre-choice state, same as any other state")
		assert_true(Events.is_awaiting_choice(), "rewind should un-resolve the choice card")
	)
