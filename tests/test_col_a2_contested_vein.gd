extends "res://tests/test_base.gd"

const EventPlay := preload("res://tests/support/event_play.gd")

# collective-act2 03, spec.md §6.5: T5 (col_a2_contested_vein), Act 2's
# first Phase 1 choice. Drives Collective.maybe_trigger_a2_contested_vein_
# setup() (the scripted "Collective vein taken by the Firm" fact T5's
# choice resolves against) plus the real event JSON's Force/Buy back
# branches, same choice-driving idiom tests/test_col_a1_hakim_meet.gd uses.


func _pin_ids() -> Array:
	var ids: Array = []
	for pin in MapPins.active_contact_pins():
		ids.append(pin["eventId"])
	return ids


func run() -> void:
	# ── setup: Collective.maybe_trigger_a2_contested_vein_setup() ──────────

	run_case("setup_is_false_before_colA2Stage_is_set", func():
		GameState.reset()
		assert_true(not Collective.maybe_trigger_a2_contested_vein_setup())
		assert_eq(GameState.state["collective"]["contestedVeinSiteId"], null)
	)

	run_case("setup_creates_a_firm_owned_site_once_colA2Stage_is_set", func():
		GameState.reset()
		GameState.state["flags"]["colA2Stage"] = "call"

		assert_true(Collective.maybe_trigger_a2_contested_vein_setup())

		var site_id: String = GameState.state["collective"]["contestedVeinSiteId"]
		assert_true(site_id != null and site_id != "")

		var site: Variant = Sites.find_site(site_id)
		assert_true(site != null)
		assert_eq(site["district"], "camden")
		assert_true(not site["claimed"])
		assert_true(site["factionVein"] != null)
		assert_eq(site["factionVein"]["factionId"], "firm")
	)

	run_case("setup_does_not_double_fire_on_a_repeat_call", func():
		GameState.reset()
		GameState.state["flags"]["colA2Stage"] = "call"
		Collective.maybe_trigger_a2_contested_vein_setup()
		var sites_before: int = GameState.state["world"]["sites"].size()

		assert_true(not Collective.maybe_trigger_a2_contested_vein_setup())
		assert_eq(GameState.state["world"]["sites"].size(), sites_before)
	)

	run_case("events_advance_fires_the_setup_the_moment_colA2Stage_is_set_via_on_complete", func():
		GameState.reset()
		EventPlay.play_event("col_a2_pattern")  # T3's on_complete sets colA2Stage "call"

		assert_eq(GameState.state["flags"]["colA2Stage"], "call")
		assert_true(GameState.state["collective"]["contestedVeinSiteId"] != null, "advance()'s on_complete boundary must trigger T5's setup automatically")
	)

	# ── delivery: Camden map pin, gated on colA2Stage / hides once resolved ──

	run_case("col_a2_contested_vein_pin_is_gated_on_colA2Stage_and_hides_once_resolved", func():
		GameState.reset()
		assert_true(not _pin_ids().has("col_a2_contested_vein"), "hidden before colA2Stage")

		GameState.state["flags"]["colA2Stage"] = "call"
		Collective.maybe_trigger_a2_contested_vein_setup()
		var pins := MapPins.active_contact_pins()
		assert_true(_pin_ids().has("col_a2_contested_vein"), "shown once colA2Stage is set")
		for pin in pins:
			if pin["eventId"] == "col_a2_contested_vein":
				assert_eq(pin["district"], "camden")

		EventPlay.play_event_with_choices("col_a2_contested_vein", [0])
		assert_true(GameState.state["flags"]["colA2ContestedVeinDone"])
		assert_true(not _pin_ids().has("col_a2_contested_vein"), "hidden again once colA2ContestedVeinDone")
	)

	# ── Force branch: claim_faction_vein ────────────────────────────────────

	run_case("force_branch_transfers_the_vein_to_the_player_and_hits_firm_relation", func():
		GameState.reset()
		GameState.state["flags"]["colA2Stage"] = "call"
		Collective.maybe_trigger_a2_contested_vein_setup()
		var site_id: String = GameState.state["collective"]["contestedVeinSiteId"]
		var relation_before: int = GameState.state["factions"]["firm"]["relation"]
		var veins_before: int = GameState.state["player"]["veins"].size()

		EventPlay.play_event_with_choices("col_a2_contested_vein", [0])  # Take it back

		var site: Variant = Sites.find_site(site_id)
		assert_true(site["claimed"])
		assert_eq(site["factionVein"], null)
		assert_eq(GameState.state["player"]["veins"].size(), veins_before + 1)
		assert_eq(GameState.state["factions"]["firm"]["relation"], relation_before + Raiding.CLAIM_RELATION_HIT)
		assert_eq(GameState.state["methodLog"]["a2ContestedVein"], "force")
	)

	# ── Buy back branch: buy_faction_vein ───────────────────────────────────

	run_case("buy_back_branch_transfers_the_vein_to_the_player_and_charges_cash", func():
		GameState.reset()
		GameState.state["flags"]["colA2Stage"] = "call"
		Collective.maybe_trigger_a2_contested_vein_setup()
		var site_id: String = GameState.state["collective"]["contestedVeinSiteId"]
		GameState.state["player"]["cash"] = 100000
		var cash_before: int = GameState.state["player"]["cash"]
		var veins_before: int = GameState.state["player"]["veins"].size()

		EventPlay.play_event_with_choices("col_a2_contested_vein", [1])  # Buy it back

		var site: Variant = Sites.find_site(site_id)
		assert_true(site["claimed"])
		assert_eq(site["factionVein"], null)
		assert_eq(GameState.state["player"]["veins"].size(), veins_before + 1)
		assert_true(GameState.state["player"]["cash"] < cash_before, "buy_from_faction() must have charged the quoted price")
		assert_eq(GameState.state["methodLog"]["a2ContestedVein"], "bought")
	)

	run_case("on_complete_always_sets_colA2ContestedVeinDone_and_returns_to_the_map", func():
		for choice_index in [0, 1]:
			GameState.reset()
			GameState.state["flags"]["colA2Stage"] = "call"
			Collective.maybe_trigger_a2_contested_vein_setup()
			GameState.state["player"]["cash"] = 100000

			EventPlay.play_event_with_choices("col_a2_contested_vein", [choice_index])

			assert_true(GameState.state["flags"]["colA2ContestedVeinDone"])
			assert_eq(GameState.state["currentScreen"], "map")
			assert_true(GameState.state["event"] == null)
	)

	# ── save/load: contestedVeinSiteId backfills for existing saves ────────

	run_case("contestedVeinSiteId_backfills_for_saves_missing_the_key", func():
		var save: Dictionary = GameState.new_game_state()
		save["collective"].erase("contestedVeinSiteId")
		assert_true(not save["collective"].has("contestedVeinSiteId"))

		var backfilled: Dictionary = SaveManager.backfill_defaults(save)
		assert_true(backfilled["collective"].has("contestedVeinSiteId"))
		assert_eq(backfilled["collective"]["contestedVeinSiteId"], null)
	)
