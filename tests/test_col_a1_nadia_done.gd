extends "res://tests/test_base.gd"

# collective1-12, spec.md §6.10: S10 (col_a1_nadia_done), Nadia's thread
# resolution -- fires automatically the moment col_a1_nadia_vein's qualifying
# sale completes (Collective.maybe_trigger_nadia_vein_done(), called from
# VeinTrade.sell_to_faction() after Objectives.refresh()), never from an
# action bar. Same site/vein helper shape tests/test_vein_trade.gd uses.


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


# Puts col_a1_nadia_vein through activation (colA1NadiaAskSeen, its
# activateFlag) and plants a matching player-owned emotion vein + site,
# ready to be sold to "collective" via VeinTrade.sell_to_faction().
func _seed_qualifying_vein(growth: int = 60) -> void:
	GameState.state["flags"]["colA1NadiaAskSeen"] = true
	Objectives.refresh()
	assert_true(GameState.state["objectives"]["col_a1_nadia_vein"]["active"])

	var site := _site("s1", "hackney", "emotion", "fair")
	var vein := _player_vein("v1", "s1", "hackney", "emotion", growth, "fair")
	GameState.state["world"]["sites"] = [site]
	GameState.state["player"]["veins"] = [vein]


func run() -> void:
	# ── Collective.maybe_trigger_nadia_vein_done() — the unit itself ───────

	run_case("maybe_trigger_nadia_vein_done_is_false_when_the_objective_is_still_incomplete", func():
		GameState.reset()
		assert_true(not Collective.maybe_trigger_nadia_vein_done())
		assert_eq(GameState.state["event"], null)
	)

	run_case("maybe_trigger_nadia_vein_done_is_false_once_colA1NadiaThreadDone_is_already_set", func():
		GameState.reset()
		_seed_qualifying_vein()
		VeinTrade.sell_to_faction("v1", "collective")  # drives the objective to complete via the real lane
		assert_true(GameState.state["objectives"]["col_a1_nadia_vein"]["complete"])
		GameState.state["flags"]["colA1NadiaThreadDone"] = true
		GameState.state["event"] = null

		assert_true(not Collective.maybe_trigger_nadia_vein_done())
		assert_eq(GameState.state["event"], null)
	)

	run_case("maybe_trigger_nadia_vein_done_starts_the_event_once_the_objective_is_complete", func():
		GameState.reset()
		_seed_qualifying_vein()
		VeinTrade.sell_to_faction("v1", "collective")  # drives the objective to complete via the real lane
		assert_true(GameState.state["objectives"]["col_a1_nadia_vein"]["complete"])

		# Reset just the runtime signal we're isolating -- the event already
		# auto-started once inside sell_to_faction() above; call the unit
		# directly to prove it, independent of that integration path.
		GameState.state["event"] = null
		assert_true(Collective.maybe_trigger_nadia_vein_done())
		assert_eq(GameState.state["event"]["eventId"], "col_a1_nadia_done")
	)

	# ── VeinTrade.sell_to_faction() integration: the real trigger boundary ──

	run_case("sell_to_faction_auto_starts_col_a1_nadia_done_on_the_qualifying_sale", func():
		GameState.reset()
		_seed_qualifying_vein()

		var result := VeinTrade.sell_to_faction("v1", "collective")

		assert_true(result["ok"])
		assert_eq(GameState.state["event"]["eventId"], "col_a1_nadia_done")
	)

	run_case("sell_to_faction_does_not_auto_start_the_event_when_col_a1_nadia_vein_is_not_active", func():
		GameState.reset()
		# colA1NadiaAskSeen never set -- the objective is never activated.
		var site := _site("s1", "hackney", "emotion", "fair")
		var vein := _player_vein("v1", "s1", "hackney", "emotion", 60, "fair")
		GameState.state["world"]["sites"] = [site]
		GameState.state["player"]["veins"] = [vein]

		VeinTrade.sell_to_faction("v1", "collective")

		assert_eq(GameState.state["event"], null)
	)

	run_case("sell_to_faction_does_not_re_fire_the_event_on_a_later_unrelated_sale", func():
		GameState.reset()
		_seed_qualifying_vein()
		VeinTrade.sell_to_faction("v1", "collective")
		assert_eq(GameState.state["event"]["eventId"], "col_a1_nadia_done")

		# Play the auto-started event through so colA1NadiaThreadDone lands,
		# then sell a second qualifying vein -- the thread must not re-open.
		for i in range(GameData.EVENTS["col_a1_nadia_done"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["colA1NadiaThreadDone"])

		var site2 := _site("s2", "hackney", "emotion", "fair")
		var vein2 := _player_vein("v2", "s2", "hackney", "emotion", 60, "fair")
		GameState.state["world"]["sites"].append(site2)
		GameState.state["player"]["veins"].append(vein2)

		VeinTrade.sell_to_faction("v2", "collective")

		assert_eq(GameState.state["event"], null, "the thread is already closed -- no second col_a1_nadia_done")
	)

	# ── on_complete: relation +8, colA1NadiaThreadDone ──────────────────────
	# Driven directly via Events.start_event() (same idiom test_col_a1_des_
	# report.gd uses), not through a real sale -- VeinTrade.sell_to_faction()
	# also runs the sale's own RelationAccrual.accrue_faction() (spec §8.4),
	# which would add its own relation points on top of this scene's +8 and
	# make the assertion price-dependent for no reason this test cares about.

	run_case("on_complete_awards_8_collective_relation_and_sets_the_thread_done_flag", func():
		GameState.reset()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		Events.start_event("col_a1_nadia_done")
		for i in range(GameData.EVENTS["col_a1_nadia_done"]["cards"].size()):
			Events.advance()

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 8)
		assert_true(GameState.state["flags"]["colA1NadiaThreadDone"])
		# Regression (bugfix: an on_complete missing a "set_screen" op leaves
		# the EventScreen stuck on a dead Continue button, per tests/
		# test_col_a1_tuition.gd's S1 comment): must navigate back to the vein
		# list, where the qualifying sale that auto-fired this event happened.
		assert_eq(GameState.state["currentScreen"], "vein_list")
	)
