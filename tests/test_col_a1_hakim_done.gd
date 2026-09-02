extends "res://tests/test_base.gd"

# collective1-14, spec.md §6.12: S12 (col_a1_hakim_done), Hakim's thread
# resolution -- handing the recovered vein back. Same action-bar-button
# delivery idiom tests/test_col_a1_des_report.gd uses, plus the on_complete
# vein transfer (VeinTrade.sell_to_faction() reused at a forced £0, per
# systems/events.gd's "sell_contact_vein_to_faction" op) and the guard that
# stops that transfer from being mistaken for Nadia's own qualifying sale
# (systems/vein_trade.gd's soldByPlayer-false-on-forced-price behaviour).


func _play_event(event_id: String) -> void:
	Events.start_event(event_id)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


func _site(id: String, district: String, ore_type: String, tier: String) -> Dictionary:
	return {
		"id": id, "district": district, "tier": tier, "oreType": ore_type,
		"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
		"hasNaturalVein": false,
	}


func _player_vein(id: String, site_id: String, district: String, ore_type: String, growth: int, tier: String) -> Dictionary:
	return {
		"id": id, "district": district, "oreType": ore_type, "growth": growth,
		"security": "none", "alarmUpgrades": [], "location": "Test Alley",
		"claimedOnDay": 1, "siteId": site_id, "hospitability": { "tier": tier, "bonuses": [] },
		"rampantDays": 0,
	}


# Plants Hakim's granted vein directly (bypassing col_a1_hakim_meet's own
# event) with a matching site, and stores its id at collective.hakimVeinId --
# the exact shape grant_contact_vein leaves behind -- then sets
# colA1HakimRescued so the action-bar button and event are both reachable.
func _seed_rescued_hakim_vein(growth: int = 61) -> void:
	var site := _site("s1", "whitechapel", "emotion", "fair")
	var vein := _player_vein("v1", "s1", "whitechapel", "emotion", growth, "fair")
	GameState.state["world"]["sites"] = [site]
	GameState.state["player"]["veins"] = [vein]
	GameState.state["collective"]["hakimVeinId"] = "v1"
	GameState.state["flags"]["colA1HakimRescued"] = true


func run() -> void:
	# ── delivery: the action-bar button, not a pendingMessages entry ───────

	run_case("build_hakim_done_action_is_null_before_colA1HakimRescued", func():
		GameState.reset()
		assert_true(ContactCards.build_hakim_done_action() == null)
	)

	run_case("build_hakim_done_action_surfaces_once_colA1HakimRescued_and_starts_the_event", func():
		GameState.reset()
		_seed_rescued_hakim_vein()

		var b := ContactCards.build_hakim_done_action() as Button
		assert_true(b != null)

		b.pressed.emit()
		assert_eq(GameState.state["event"]["eventId"], "col_a1_hakim_done")
	)

	run_case("build_hakim_done_action_is_null_again_once_colA1HakimThreadDone", func():
		GameState.reset()
		_seed_rescued_hakim_vein()
		GameState.state["flags"]["colA1HakimThreadDone"] = true
		assert_true(ContactCards.build_hakim_done_action() == null)
	)

	# ── on_complete: transfer at £0, +£120 cash, +10 relation, both flags ──

	run_case("on_complete_transfers_hakims_vein_to_the_collective_at_price_zero", func():
		GameState.reset()
		_seed_rescued_hakim_vein(61)

		_play_event("col_a1_hakim_done")

		assert_eq(GameState.state["player"]["veins"].size(), 0, "the vein leaves player.veins")
		var site: Variant = Sites.find_site("s1")
		assert_true(site["factionVein"] != null)
		assert_eq(site["factionVein"]["factionId"], "collective")
		assert_eq(site["factionVein"]["oreType"], "emotion")
		assert_eq(site["factionVein"]["growth"], 61, "growth is passed through unchanged")
	)

	run_case("on_complete_does_not_stamp_soldByPlayer_since_this_is_a_handback_not_a_sale", func():
		GameState.reset()
		_seed_rescued_hakim_vein()

		_play_event("col_a1_hakim_done")

		var site: Variant = Sites.find_site("s1")
		assert_true(not site["factionVein"]["soldByPlayer"], "a forced-price handback must not count as a player market sale")
	)

	run_case("on_complete_pays_exactly_120_cash_regardless_of_what_quote_would_have_priced_it_at", func():
		GameState.reset()
		_seed_rescued_hakim_vein(61)
		var cash_before: int = GameState.state["player"]["cash"]

		_play_event("col_a1_hakim_done")

		assert_eq(GameState.state["player"]["cash"], cash_before + 120)
	)

	run_case("on_complete_awards_10_collective_relation_and_sets_both_flags", func():
		GameState.reset()
		_seed_rescued_hakim_vein()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		_play_event("col_a1_hakim_done")

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 10)
		assert_true(GameState.state["flags"]["colA1HakimThreadDone"])
		assert_true(GameState.state["flags"]["hakimIntelUnlocked"])
		# Regression (bugfix: an on_complete missing a "set_screen" op leaves
		# the EventScreen stuck on a dead Continue button, per tests/
		# test_col_a1_tuition.gd's S1 comment): must navigate back to Hakim's
		# conversation, where the action-bar button was tapped from.
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	# ── the Nadia clash this ticket's guard exists to prevent ──────────────

	run_case("on_complete_does_not_falsely_complete_col_a1_nadia_vein_or_fire_its_done_event", func():
		GameState.reset()
		_seed_rescued_hakim_vein(61)
		# Nadia's ask has already been played (S9), so her objective is
		# active and watching for exactly this shape of sale: an emotion
		# vein, sold to collective. Hakim's handback must not satisfy it.
		GameState.state["flags"]["colA1NadiaAskSeen"] = true
		Objectives.refresh()
		assert_true(GameState.state["objectives"]["col_a1_nadia_vein"]["active"])

		_play_event("col_a1_hakim_done")

		assert_true(not GameState.state["objectives"]["col_a1_nadia_vein"]["complete"], "Hakim's handback must not satisfy Nadia's objective")
		assert_true(not GameState.state["flags"].get("colA1NadiaThreadDone", false), "col_a1_nadia_done must not have fired")
	)
