extends "res://tests/test_base.gd"

# M1-LONDON D5 — district event deck engine. Deck entries are injected as
# synthetic GameData.EVENTS entries (same pattern tests/test_events.gd
# uses for its own synthetic events) so these tests don't depend on
# ticket 09's real 15 events.


func _synthetic_event(event_id: String, deck: Dictionary) -> Dictionary:
	return {
		"id": event_id,
		"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "x" }],
		"on_complete": [],
		"deck": deck,
	}


# Installs `entries` (event_id -> deck sub-object) into a duplicated
# GameData.EVENTS, first stripping every real deck-bearing entry (ticket
# 09's 15 district events) so these engine tests stay isolated from real
# content — same reasoning as _synthetic_event's doc comment. Returns the
# original for restoration.
func _install_deck(entries: Dictionary) -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	for event_id in GameData.EVENTS.keys():
		if GameData.EVENTS[event_id].has("deck"):
			GameData.EVENTS.erase(event_id)
	for event_id in entries.keys():
		GameData.EVENTS[event_id] = _synthetic_event(event_id, entries[event_id])
	return original_events


func run() -> void:
	# ── district filtering ────────────────────────────────────────────

	run_case("eligible_entries_matches_own_district_and_any", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_greenwich": { "district": "greenwich", "weight": 1, "excludeIfFlag": null, "barometerState": null },
			"e_camden": { "district": "camden", "weight": 1, "excludeIfFlag": null, "barometerState": null },
			"e_any": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
		})

		var ids: Array = []
		for entry in DistrictDeck.eligible_entries("greenwich"):
			ids.append(entry["id"])
		ids.sort()
		assert_eq(ids, ["e_any", "e_greenwich"], "greenwich draws should see its own district entry plus 'any', not camden's")

		GameData.EVENTS = original_events
	)

	run_case("eligible_entries_carries_weight_through_from_the_deck_def", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_weighted": { "district": "any", "weight": 7, "excludeIfFlag": null, "barometerState": null },
		})

		var entries := DistrictDeck.eligible_entries("soho")
		assert_eq(entries.size(), 1)
		assert_eq(entries[0]["weight"], 7)

		GameData.EVENTS = original_events
	)

	run_case("eligible_entries_defaults_weight_to_1_when_omitted", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["e_default_weight"] = {
			"id": "e_default_weight",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "x" }],
			"on_complete": [],
			"deck": { "district": "any" },
		}

		var entries := DistrictDeck.eligible_entries("soho")
		assert_eq(entries[0]["weight"], 1)

		GameData.EVENTS = original_events
	)

	run_case("eligible_entries_ignores_events_with_no_deck_field", func():
		GameState.reset()
		# "intro" etc. are ordinary tutorial events with no "deck" key.
		var entries := DistrictDeck.eligible_entries("shoreditch")
		for entry in entries:
			assert_true(entry["id"] != "intro", "a non-deck event must never surface as a deck entry")
	)

	# ── excludeIfFlag ──────────────────────────────────────────────────

	run_case("excludeIfFlag_drops_the_entry_once_the_flag_is_true", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_conclave": { "district": "any", "weight": 1, "excludeIfFlag": "conclaveNoticed", "barometerState": null },
		})

		assert_eq(DistrictDeck.eligible_entries("city").size(), 1, "eligible before the flag is set")

		GameState.state["flags"]["conclaveNoticed"] = true
		assert_eq(DistrictDeck.eligible_entries("city").size(), 0, "excluded once the flag is true")

		GameData.EVENTS = original_events
	)

	run_case("excludeIfFlag_null_never_excludes", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_no_exclude": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
		})

		GameState.state["flags"]["someUnrelatedFlag"] = true
		assert_eq(DistrictDeck.eligible_entries("city").size(), 1, "no excludeIfFlag means never excluded")

		GameData.EVENTS = original_events
	)

	# ── barometerState (reserved plumbing, D5) ──────────────────────────

	run_case("barometerState_filter_gates_on_the_current_section_state", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_boom_only": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": { "section": "economic", "state": "boom" } },
		})

		assert_eq(GameState.state["barometer"]["economic"], "stable", "sanity: default barometer state")
		assert_eq(DistrictDeck.eligible_entries("city").size(), 0, "excluded while the section is in a different state")

		GameState.state["barometer"]["economic"] = "boom"
		assert_eq(DistrictDeck.eligible_entries("city").size(), 1, "eligible once the section matches")

		GameData.EVENTS = original_events
	)

	# ── requireUnclaimedSiteInDistrict (D5 #13, rival_prospector) ────────

	run_case("requireUnclaimedSiteInDistrict_excludes_the_entry_with_nothing_unclaimed", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_needs_site": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null, "requireUnclaimedSiteInDistrict": true },
		})

		assert_eq(DistrictDeck.eligible_entries("camden").size(), 0, "no sites at all in camden — excluded")

		GameData.EVENTS = original_events
	)

	run_case("requireUnclaimedSiteInDistrict_includes_the_entry_once_an_unclaimed_site_exists", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_needs_site": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null, "requireUnclaimedSiteInDistrict": true },
		})
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "camden", "tier": "fair", "oreType": "physics",
			"bonuses": [], "discoveredDay": 1, "claimed": false, "npcClaimed": false,
			"npcClaimedDay": null, "hasNaturalVein": false,
		}]

		assert_eq(DistrictDeck.eligible_entries("camden").size(), 1, "camden now has an unclaimed site — eligible")
		assert_eq(DistrictDeck.eligible_entries("hampstead").size(), 0, "the site is in camden, not hampstead — still excluded there")

		GameData.EVENTS = original_events
	)

	run_case("requireUnclaimedSiteInDistrict_defaults_false_when_omitted", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_no_site_requirement": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
		})

		assert_eq(DistrictDeck.eligible_entries("camden").size(), 1, "omitting the field entirely must not gate the entry")

		GameData.EVENTS = original_events
	)

	# ── no-repeat-within-5-days ──────────────────────────────────────────

	run_case("no_repeat_excludes_an_event_drawn_within_the_last_5_days", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_recent": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
		})
		GameState.state["world"]["day"] = 10
		GameState.state["world"]["recentEvents"] = [{ "id": "e_recent", "day": 6 }]  # 4 days ago

		assert_eq(DistrictDeck.eligible_entries("city").size(), 0, "drawn 4 days ago — still inside the 5-day window")

		GameData.EVENTS = original_events
	)

	run_case("no_repeat_window_reopens_exactly_at_5_days", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_recent": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
		})
		GameState.state["world"]["day"] = 11
		GameState.state["world"]["recentEvents"] = [{ "id": "e_recent", "day": 6 }]  # exactly 5 days ago

		assert_eq(DistrictDeck.eligible_entries("city").size(), 1, "5 days elapsed — the entry is eligible again")

		GameData.EVENTS = original_events
	)

	run_case("no_repeat_only_excludes_its_own_id_not_other_entries", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_recent": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
			"e_untouched": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
		})
		GameState.state["world"]["day"] = 10
		GameState.state["world"]["recentEvents"] = [{ "id": "e_recent", "day": 6 }]

		var ids: Array = []
		for entry in DistrictDeck.eligible_entries("city"):
			ids.append(entry["id"])
		assert_eq(ids, ["e_untouched"], "only the recently-drawn id should be excluded")

		GameData.EVENTS = original_events
	)

	run_case("draw_itself_is_side_effect_free", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_a": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
		})
		GameState.state["world"]["day"] = 20
		GameState.state["world"]["recentEvents"] = [{ "id": "e_stale", "day": 1 }]

		var picked = DistrictDeck.draw("city")
		assert_eq(picked, "e_a")
		assert_eq(GameState.state["world"]["recentEvents"], [{ "id": "e_stale", "day": 1 }], "draw() alone must not record or prune recentEvents")

		GameData.EVENTS = original_events
	)

	# ── weighted_pick ──────────────────────────────────────────────────

	run_case("weighted_pick_never_returns_an_id_outside_the_pool", func():
		var entries := [{ "id": "a", "weight": 1 }, { "id": "b", "weight": 5 }, { "id": "c", "weight": 2 }]
		for seed in range(50):
			Rng.set_seed(seed)
			var picked := DistrictDeck.weighted_pick(entries)
			assert_true(["a", "b", "c"].has(picked), "picked id should always be one of the pool's ids")

	)

	run_case("weighted_pick_favours_higher_weight_entries_over_many_draws", func():
		var entries := [{ "id": "rare", "weight": 1 }, { "id": "common", "weight": 9 }]
		var common_count := 0
		for seed in range(200):
			Rng.set_seed(seed)
			if DistrictDeck.weighted_pick(entries) == "common":
				common_count += 1
		# Expected ~180/200; a generous band avoids flaking on seed choice.
		assert_true(common_count > 120, "a 9:1 weight split should draw the heavy entry well over half the time, got %d/200" % common_count)

	)

	run_case("weighted_pick_single_entry_always_wins", func():
		var entries := [{ "id": "only", "weight": 3 }]
		Rng.set_seed(1)
		assert_eq(DistrictDeck.weighted_pick(entries), "only")
	)

	# ── maybe_trigger() ──────────────────────────────────────────────────

	run_case("maybe_trigger_starts_an_event_on_a_hit_with_an_eligible_pool", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_trigger": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
		})

		var seed := -1
		for candidate in range(200):
			GameState.reset()
			Rng.set_seed(candidate)
			if Rng.chance(DistrictDeck.TRIGGER_CHANCE):
				seed = candidate
				break
		assert_true(seed != -1, "should find a triggering seed within 200 tries")

		GameState.reset()
		Rng.set_seed(seed)
		DistrictDeck.maybe_trigger("shoreditch")
		assert_eq(GameState.state["event"]["eventId"], "e_trigger", "a hit with one eligible entry should start it")
		assert_eq(GameState.state["world"]["recentEvents"].size(), 1, "the draw should be recorded")
		assert_eq(GameState.state["world"]["recentEvents"][0]["id"], "e_trigger")

		GameData.EVENTS = original_events
	)

	run_case("maybe_trigger_prunes_stale_recentEvents_entries_when_it_records", func():
		GameState.reset()
		var original_events := _install_deck({
			"e_trigger": { "district": "any", "weight": 1, "excludeIfFlag": null, "barometerState": null },
		})
		GameState.state["world"]["day"] = 20
		GameState.state["world"]["recentEvents"] = [{ "id": "e_stale", "day": 1 }]  # 19 days old

		var seed := -1
		for candidate in range(200):
			Rng.set_seed(candidate)
			if Rng.chance(DistrictDeck.TRIGGER_CHANCE):
				seed = candidate
				break
		assert_true(seed != -1, "should find a triggering seed within 200 tries")

		Rng.set_seed(seed)
		DistrictDeck.maybe_trigger("shoreditch")
		var ids: Array = []
		for entry in GameState.state["world"]["recentEvents"]:
			ids.append(entry["id"])
		assert_eq(ids, ["e_trigger"], "the stale entry should be pruned away, leaving only the fresh pick")

		GameData.EVENTS = original_events
	)

	run_case("maybe_trigger_is_a_no_op_with_an_empty_pool_even_on_a_hit", func():
		GameState.reset()
		var original_events := _install_deck({})  # strips real content too — a genuinely empty pool
		var seed := -1
		for candidate in range(200):
			GameState.reset()
			Rng.set_seed(candidate)
			if Rng.chance(DistrictDeck.TRIGGER_CHANCE):
				seed = candidate
				break
		assert_true(seed != -1, "should find a triggering seed within 200 tries")

		GameState.reset()
		Rng.set_seed(seed)
		DistrictDeck.maybe_trigger("shoreditch")  # no deck entries installed at all
		assert_eq(GameState.state["event"], null, "nothing eligible -> no event starts, even on a chance hit")
		assert_eq(GameState.state["world"]["recentEvents"], [], "nothing recorded when nothing was drawn")

		GameData.EVENTS = original_events
	)
