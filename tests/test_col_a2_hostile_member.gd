extends "res://tests/test_base.gd"

const EventPlay := preload("res://tests/support/event_play.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")

# spec.md §6.7: T7 (col_a2_hostile_member), Act 2's third Phase 1 choice --
# absorb (Collective relation hit), make an example (timed Firm targeting
# multiplier on Collective veins), or offer protection (T6's cash ->
# collective.resources lever plus a relation gain).


func _pin_ids() -> Array:
	var ids: Array = []
	for pin in MapPins.active_contact_pins():
		ids.append(pin["eventId"])
	return ids


func _start() -> void:
	GameState.reset()
	GameState.state["flags"]["colA2Stage"] = "call"
	GameState.state["player"]["cash"] = 1000


func _firm_collective_target_share(seeds: int) -> float:
	var collective_hits := 0
	var firm_attacks := 0
	for seed in range(seeds):
		Rng.set_seed(seed)
		for attempt in Factions.roll_rivalry_attempts():
			if attempt["attackerId"] != "firm":
				continue
			firm_attacks += 1
			if attempt["defenderId"] == "collective":
				collective_hits += 1
	return float(collective_hits) / float(max(firm_attacks, 1))


func run() -> void:
	run_case("pin_is_gated_on_colA2Stage_and_hides_once_resolved", func():
		GameState.reset()
		assert_true(not _pin_ids().has("col_a2_hostile_member"), "hidden before colA2Stage")
		GameState.state["flags"]["colA2Stage"] = "call"
		GameState.state["player"]["cash"] = 1000
		assert_true(_pin_ids().has("col_a2_hostile_member"), "shown once colA2Stage is set")

		EventPlay.play_event_with_choices("col_a2_hostile_member", [0])
		assert_true(GameState.state["flags"]["colA2HostileMemberDone"])
		assert_true(not _pin_ids().has("col_a2_hostile_member"), "hidden once resolved")
		assert_eq(GameState.state["currentScreen"], "map")
	)

	run_case("absorb_branch_costs_collective_relation_only", func():
		_start()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]
		EventPlay.play_event_with_choices("col_a2_hostile_member", [0])
		assert_true(GameState.state["factions"]["collective"]["relation"] < relation_before)
		assert_eq(GameState.state["player"]["cash"], 1000)
		assert_true(GameState.state["collective"]["firmProvocation"] == null)
		assert_eq(GameState.state["methodLog"]["a2HostileMember"], "absorbed")
	)

	run_case("example_branch_stamps_a_timed_firm_provocation", func():
		_start()
		var today: int = GameState.state["world"]["day"]
		EventPlay.play_event_with_choices("col_a2_hostile_member", [1])
		var provocation: Dictionary = GameState.state["collective"]["firmProvocation"]
		assert_true(provocation["expiresDay"] > today)
		assert_true(provocation["multiplier"] > 1.0)
		assert_eq(GameState.state["player"]["cash"], 1000)
		assert_eq(GameState.state["methodLog"]["a2HostileMember"], "example")

		assert_true(Collective.firm_target_multiplier("firm", "collective") > 1.0, "live while provoked")
		assert_eq(Collective.firm_target_multiplier("firm", "guild"), 1.0, "Collective-specific")
		assert_eq(Collective.firm_target_multiplier("guild", "collective"), 1.0, "Firm-specific")
		GameState.state["world"]["day"] = provocation["expiresDay"]
		assert_eq(Collective.firm_target_multiplier("firm", "collective"), 1.0, "expired")
	)

	run_case("protect_branch_funds_collective_resources_and_gains_relation", func():
		_start()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]
		var resources_before: int = GameState.state["factions"]["collective"]["resources"]
		EventPlay.play_event_with_choices("col_a2_hostile_member", [2])
		assert_eq(GameState.state["player"]["cash"], 1000 - 150)
		assert_eq(GameState.state["factions"]["collective"]["resources"], resources_before + 150)
		assert_true(GameState.state["factions"]["collective"]["relation"] > relation_before)
		assert_eq(GameState.state["methodLog"]["a2HostileMember"], "protected")
	)

	run_case("provocation_skews_firm_rivalry_targets_toward_collective", func():
		GameState.reset()
		GameState.state["world"]["sites"] = []
		Fixtures.seed_faction_vein("fv_collective", 50, "collective")
		Fixtures.seed_faction_vein("fv_guild", 50, "guild")
		Fixtures.seed_faction_vein("fv_firm", 50, "firm")
		var baseline := _firm_collective_target_share(300)
		Collective.provoke_firm(3.0, 7)
		var provoked := _firm_collective_target_share(300)
		assert_true(provoked > baseline + 0.15, "baseline %.2f vs provoked %.2f" % [baseline, provoked])
	)
