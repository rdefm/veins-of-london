extends "res://tests/test_base.gd"

const EventPlay := preload("res://tests/support/event_play.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")

# collective-act2 06, spec.md §5.1/§6.8/§6.8a: T8 (col_a2_nadia_ledger)
# activates Nadia's three missions and funds them; T8a (col_a2_nadia_
# defend_brief) fires only once col_a2_nadia_supplies completes and names
# the vein col_a2_nadia_defend then watches. Drives the real event JSON via
# tests/support/event_play.gd, same idiom tests/test_col_a2_phase0.gd uses,
# plus Collective's own T8a helper functions and their raiding.gd/crafting.gd
# call sites directly.


# High enough that craft_chance() (baseSuccess + (skill-1)*0.13, capped at
# 0.95) clears the 0.95 cap for all three recipes, so a short seed search
# reliably finds a success.
const _HIGH_SKILL := 10


func _craft_until_success(recipe_key: String) -> void:
	for seed in range(200):
		Rng.set_seed(seed)
		var result := Crafting.attempt_craft(recipe_key)
		if result.get("success", false):
			return
	assert_true(false, "should find a successful %s craft within 200 seeds" % recipe_key)


func run() -> void:
	# ── T8: col_a2_nadia_ledger ─────────────────────────────────────────────

	run_case("col_a2_nadia_ledger_on_complete_funds_and_activates_reseed_and_supplies_only", func():
		GameState.reset()
		var cash_before: int = GameState.state["player"]["cash"]

		EventPlay.play_event("col_a2_nadia_ledger")

		assert_true(GameState.state["player"]["cash"] > cash_before, "Nadia funds the missions, not the player")
		assert_true(GameState.state["player"]["orichalchum"]["physics"] >= 11, "enough physics for one Blast (5) and one Shield (6)")
		assert_true(GameState.state["player"]["orichalchum"]["emotion"] >= 6, "enough emotion for one Pan's Prank")
		assert_true(GameState.state["flags"]["colA2LedgerStarted"])
		assert_eq(GameState.state["flags"]["colA2Stage"], "hardening")

		assert_true(GameState.state["objectives"]["col_a2_nadia_reseed"]["active"], "reseed activates on T8 completion")
		assert_true(GameState.state["objectives"]["col_a2_nadia_supplies"]["active"], "supplies activates on T8 completion")
		assert_true(not GameState.state["objectives"]["col_a2_nadia_defend"]["active"], "defend must NOT activate at T8 -- only via T8a")
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	# ── sequencing: supplies before defend, not parallel ────────────────────

	run_case("col_a2_nadia_defend_stays_inactive_until_supplies_completes_then_brief_autofires", func():
		GameState.reset()
		Fixtures.seed_vein("v1", 20, "time")
		GameState.state["player"]["craftingSkill"] = _HIGH_SKILL

		EventPlay.play_event("col_a2_nadia_ledger")
		assert_true(not GameState.state["objectives"]["col_a2_nadia_defend"]["active"], "still inactive right after T8")
		assert_true(not GameState.state["flags"].get("colA2DefendBriefed", false))

		_craft_until_success("blast")
		assert_true(not GameState.state["objectives"]["col_a2_nadia_supplies"]["complete"], "one of three recipes is not enough")
		assert_true(not GameState.state["flags"].get("colA2DefendBriefed", false), "must not fire early")

		_craft_until_success("shield")
		assert_true(not GameState.state["objectives"]["col_a2_nadia_supplies"]["complete"], "two of three recipes is not enough")

		_craft_until_success("pansPrank")
		assert_true(GameState.state["objectives"]["col_a2_nadia_supplies"]["complete"], "all three recipes crafted -- supplies complete")
		assert_eq(GameState.state["event"]["eventId"], "col_a2_nadia_defend_brief", "the moment supplies completes, the brief scene autofires")

		EventPlay.play_event("col_a2_nadia_defend_brief")
		assert_true(GameState.state["flags"]["colA2DefendBriefed"])
		assert_eq(GameState.state["collective"]["nadiaDefendVeinId"], "v1")
		assert_true(GameState.state["objectives"]["col_a2_nadia_defend"]["active"], "defend activates only once T8a resolves")
	)

	run_case("col_a2_nadia_defend_brief_does_not_refire_once_briefed", func():
		GameState.reset()
		GameState.state["flags"]["colA2DefendBriefed"] = true
		var objectives: Dictionary = GameState.state["objectives"]
		objectives["col_a2_nadia_supplies"] = { "active": true, "complete": true, "progress": {} }

		assert_true(not Collective.maybe_trigger_a2_nadia_defend_brief())
	)

	# ── Collective.pick_nadia_defend_vein(): alarm upgrade beats exposure ───

	run_case("pick_nadia_defend_vein_prefers_a_vein_that_already_has_the_alarm_upgrade", func():
		GameState.reset()
		var exposed := Fixtures.seed_vein("v_exposed", 20, "time")
		exposed["security"] = "none"
		var alarmed := Fixtures.seed_vein("v_alarmed", 20, "life")
		alarmed["alarmUpgrades"] = ["alarm"]

		Collective.pick_nadia_defend_vein()

		assert_eq(GameState.state["collective"]["nadiaDefendVeinId"], "v_alarmed")
	)

	run_case("pick_nadia_defend_vein_falls_back_to_the_lowest_raid_resist_vein", func():
		GameState.reset()
		var guarded := Fixtures.seed_vein("v_guarded", 20, "time")
		guarded["security"] = "guarded"
		var soft := Fixtures.seed_vein("v_soft", 20, "life")
		soft["security"] = "none"

		Collective.pick_nadia_defend_vein()

		assert_eq(GameState.state["collective"]["nadiaDefendVeinId"], "v_soft", "no alarmed vein exists -- picks the most exposed one")
	)

	# ── re-target on loss ────────────────────────────────────────────────────

	run_case("maybe_retarget_nadia_defend_vein_repoints_when_the_watched_vein_is_lost", func():
		GameState.reset()
		var lost := Fixtures.seed_vein("v_lost", 20, "time")
		var other := Fixtures.seed_vein("v_other", 20, "life")
		GameState.state["collective"]["nadiaDefendVeinId"] = "v_lost"

		Collective.maybe_retarget_nadia_defend_vein("v_lost")

		assert_eq(GameState.state["collective"]["nadiaDefendVeinId"], "v_other", "re-targets rather than dead-ending")
	)

	run_case("maybe_retarget_nadia_defend_vein_is_a_no_op_for_an_unrelated_loss", func():
		GameState.reset()
		Fixtures.seed_vein("v_watched", 20, "time")
		Fixtures.seed_vein("v_unrelated", 20, "life")
		GameState.state["collective"]["nadiaDefendVeinId"] = "v_watched"

		Collective.maybe_retarget_nadia_defend_vein("v_unrelated")

		assert_eq(GameState.state["collective"]["nadiaDefendVeinId"], "v_watched")
	)

	run_case("resolve_raid_outcome_retargets_nadia_defend_vein_on_a_real_ownership_loss", func():
		GameState.reset()
		var lost := Fixtures.player_vein("v_lost", "s_lost", "shoreditch", "time", 20, "fair")
		var other := Fixtures.player_vein("v_other", "s_other", "shoreditch", "life", 20, "fair")
		GameState.state["player"]["veins"] = [lost, other]
		GameState.state["world"]["sites"] = [
			Fixtures.site("s_lost", "time", "fair", true),
			Fixtures.site("s_other", "life", "fair", true),
		]
		GameState.state["collective"]["nadiaDefendVeinId"] = "v_lost"

		var outcome := { "attackerId": "firm", "veinId": "v_lost", "siteId": "s_lost", "success": true, "outcomeType": "claim" }
		Raiding.resolve_raid_outcome(outcome)

		assert_eq(GameState.state["collective"]["nadiaDefendVeinId"], "v_other")
	)

	# ── pre-fight reminder card ──────────────────────────────────────────────

	run_case("start_defend_vein_prepends_the_reminder_only_for_the_watched_vein_and_only_once", func():
		GameState.reset()
		var vein := Fixtures.alarmed_vein("v1", "shoreditch", "life")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["collective"]["nadiaDefendVeinId"] = "v1"

		Combat.start_defend_vein("v1", 10)
		var log: Array = GameState.state["combat"]["log"]
		assert_true(log[0].begins_with("Nadia,"), "the reminder is prepended ahead of the fight's own opening line")
		assert_true(GameState.state["flags"]["colA2DefendReminderShown"])

		Combat.start_defend_vein("v1", 10)
		var log2: Array = GameState.state["combat"]["log"]
		assert_true(not log2[0].begins_with("Nadia,"), "must not repeat once already shown")
	)

	run_case("start_defend_vein_never_shows_the_reminder_for_a_vein_nadia_isnt_watching", func():
		GameState.reset()
		var vein := Fixtures.alarmed_vein("v_other", "shoreditch", "life")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["collective"]["nadiaDefendVeinId"] = "v1"

		Combat.start_defend_vein("v_other", 10)
		var log: Array = GameState.state["combat"]["log"]
		assert_true(not log[0].begins_with("Nadia,"))
	)
