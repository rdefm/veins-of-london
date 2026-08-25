extends "res://tests/test_base.gd"

# collective1-13, spec.md §6.11: S11 (col_a1_hakim_meet), Hakim's
# introduction -- the yard. Drives the real event JSON card-by-card, same
# choice-driving idiom tests/test_col_a1_nadia_meet.gd uses for S8, plus the
# Whitechapel map pin (MapPins.active_contact_pins()) that's this scene's
# delivery, and the grant_contact_vein on_complete op that hands Hakim's vein
# to the player and gives col_a1_hakim_rescue (activated back at S4, ticket
# 08) something real to read.


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


# col_a1_hakim_meet's single choice card carries no effects either way (both
# branches are cosmetic dialogue only, per spec §6.11) -- plays the whole
# event through choice 0 ("I'll do it") for cases that only care about
# on_complete.
func _play_through_choice(event_id: String) -> void:
	var choice_index := _play_to_choice(event_id)
	Events.choose(0)
	_finish_after_choice(event_id, choice_index)


func _pin_ids() -> Array:
	var ids: Array = []
	for pin in MapPins.active_contact_pins():
		ids.append(pin["eventId"])
	return ids


func run() -> void:
	# ── delivery: Whitechapel map pin, gated on colA1HubReached / not colA1HakimMet ──

	run_case("col_a1_hakim_meet_pin_is_gated_on_colA1HubReached_and_hides_once_met", func():
		GameState.reset()
		assert_true(not _pin_ids().has("col_a1_hakim_meet"), "hidden before colA1HubReached")

		GameState.state["flags"]["colA1HubReached"] = true
		var pins := MapPins.active_contact_pins()
		assert_true(_pin_ids().has("col_a1_hakim_meet"), "shown once colA1HubReached is true")
		for pin in pins:
			if pin["eventId"] == "col_a1_hakim_meet":
				assert_eq(pin["district"], "whitechapel")

		_play_through_choice("col_a1_hakim_meet")
		assert_true(GameState.state["flags"]["colA1HakimMet"])

		assert_true(not _pin_ids().has("col_a1_hakim_meet"), "hidden again once colA1HakimMet")
	)

	# ── both choice branches leave state untouched and reach the same next card ──

	run_case("both_choice_branches_leave_relation_untouched_and_reach_the_same_next_card", func():
		for choice_index_to_pick in [0, 1]:
			GameState.reset()
			GameState.state["flags"]["colA1HubReached"] = true
			var relation_before: int = GameState.state["factions"]["collective"]["relation"]

			var choice_index := _play_to_choice("col_a1_hakim_meet")
			Events.choose(choice_index_to_pick)
			assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before, "choice %d must not move relation" % choice_index_to_pick)

			Events.advance()  # past the resolved choice card, onto the resolution card
			var next_card: Dictionary = Events.current_card()
			assert_eq(next_card["type"], "resolution")

			_finish_after_choice("col_a1_hakim_meet", choice_index + 1)
			assert_true(GameState.state["flags"]["colA1HakimMet"])
	)

	# ── on_complete: grant_contact_vein creates Hakim's vein and sets colA1HakimMet ──

	run_case("on_complete_grants_hakims_vein_at_growth_18_sparse_fair_and_stores_its_id", func():
		GameState.reset()
		GameState.state["flags"]["colA1HubReached"] = true
		var veins_before: int = GameState.state["player"]["veins"].size()

		_play_through_choice("col_a1_hakim_meet")

		assert_true(GameState.state["flags"]["colA1HakimMet"])
		assert_eq(GameState.state["player"]["veins"].size(), veins_before + 1, "grant_contact_vein adds exactly one vein")

		var vein_id: String = GameState.state["collective"]["hakimVeinId"]
		assert_true(vein_id != "" and vein_id != null, "hakimVeinId is stored")

		var vein: Variant = null
		for v in GameState.state["player"]["veins"]:
			if v["id"] == vein_id:
				vein = v
		assert_true(vein != null, "the stored id resolves to a real vein in player.veins")
		assert_eq(vein["oreType"], "emotion")
		assert_eq(vein["growth"], 18)
		assert_eq(vein["district"], "whitechapel")
		assert_eq(Cultivating.growth_band(vein)["id"], "sparse")

		var site: Variant = Sites.find_site(vein["siteId"])
		assert_true(site != null, "grant_contact_vein backs the vein with a real site, same as grant_vein_with_site")
		assert_eq(site["tier"], "fair")
	)

	run_case("on_complete_moves_no_relation", func():
		GameState.reset()
		GameState.state["flags"]["colA1HubReached"] = true
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		_play_through_choice("col_a1_hakim_meet")

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before)
	)

	# ── col_a1_hakim_rescue: activated at S4 already, now has a real vein to read ──

	run_case("col_a1_hakim_rescue_completes_once_hakims_vein_clears_the_threshold", func():
		GameState.reset()
		GameState.state["flags"]["colA1HubReached"] = true
		Objectives.refresh()
		assert_true(GameState.state["objectives"]["col_a1_hakim_rescue"]["active"], "colA1HubReached is col_a1_hakim_rescue's activateFlag (ticket 08)")

		_play_through_choice("col_a1_hakim_meet")
		Objectives.refresh()
		assert_true(not GameState.state["flags"].get("colA1HakimRescued", false), "growth 18 is well short of the threshold 60")

		var vein_id: String = GameState.state["collective"]["hakimVeinId"]
		for v in GameState.state["player"]["veins"]:
			if v["id"] == vein_id:
				v["growth"] = 61

		Objectives.refresh()
		assert_true(GameState.state["flags"]["colA1HakimRescued"], "veinIdStatePath collective.hakimVeinId resolves to Hakim's granted vein")
	)

	# ── save/load: hakimVeinId backfills for existing saves ────────────────

	run_case("hakimVeinId_backfills_for_saves_missing_the_key", func():
		var save: Dictionary = GameState.new_game_state()
		save["collective"].erase("hakimVeinId")
		assert_true(not save["collective"].has("hakimVeinId"))

		var backfilled: Dictionary = SaveManager.backfill_defaults(save)
		assert_true(backfilled["collective"].has("hakimVeinId"))
		assert_eq(backfilled["collective"]["hakimVeinId"], null)
	)
