extends "res://tests/test_base.gd"

# Ambush squads: Turf.ambush_chance, the keyed roll, the intro event's combat
# op, and win/loss settlement into relation and grudges.


static func _fresh(relation: int, tier: String = Turf.TIER_CONTROL) -> void:
	GameState.reset()
	GameState.state["turf"]["shoreditch"] = { "controller": "firm", "shares": {}, "tiers": { "firm": tier } }
	GameState.state["factions"]["firm"]["relation"] = relation


# First day (with the reset's time block) whose keyed roll hits; leaves the
# intro event open, so callers re-_fresh afterwards.
static func _first_hit_day() -> int:
	for day in range(2, 200):
		GameState.state["world"]["day"] = day
		if Ambush.maybe_trigger("shoreditch"):
			return day
	return -1


func run() -> void:
	run_case("every_faction_has_a_squad_of_known_templates", func():
		for faction_id in GameData.FACTIONS:
			assert_true(not GameData.ENEMY_FACTION_SQUADS[faction_id].is_empty(), faction_id)
	)

	run_case("chance_zero_at_or_above_the_relation_line", func():
		_fresh(-20)
		assert_eq(Turf.ambush_chance("shoreditch"), 0.0)
		_fresh(60)
		assert_eq(Turf.ambush_chance("shoreditch"), 0.0)
	)

	run_case("chance_rises_with_hostility_and_caps", func():
		_fresh(-40)
		var mild := Turf.ambush_chance("shoreditch")
		_fresh(-70)
		var harsh := Turf.ambush_chance("shoreditch")
		_fresh(-100)
		assert_true(mild > 0.0 and harsh > mild, "rises")
		assert_true(Turf.ambush_chance("shoreditch") <= float(GameData.TURF["ambush"]["maxChance"]) + 0.0001, "capped")
	)

	run_case("foothold_scales_down_control", func():
		_fresh(-60, Turf.TIER_CONTROL)
		var control := Turf.ambush_chance("shoreditch")
		_fresh(-60, Turf.TIER_FOOTHOLD)
		assert_true(is_equal_approx(Turf.ambush_chance("shoreditch"), control * float(GameData.TURF["footholdFactor"])))
	)

	run_case("friendly_district_never_triggers_and_leaves_rng_alone", func():
		_fresh(50)
		Rng.set_seed(7)
		var expected := Rng.randf()
		Rng.set_seed(7)
		assert_true(not Ambush.maybe_trigger("shoreditch"))
		assert_eq(Rng.randf(), expected)
		assert_eq(GameState.state["event"], null)
	)

	run_case("hit_starts_the_intro_event_without_touching_global_rng", func():
		_fresh(-100)
		Rng.set_seed(7)
		var expected := Rng.randf()
		Rng.set_seed(7)
		var hit := false
		for day in range(1, 200):
			GameState.state["world"]["day"] = day
			hit = Ambush.maybe_trigger("shoreditch")
			if hit:
				break
		assert_true(hit, "a 30% roll hits within 200 days")
		assert_eq(Rng.randf(), expected)
		assert_eq(GameState.state["event"]["eventId"], "faction_ambush")
		assert_eq(GameState.state["event"]["context"]["faction_id"], "firm")
	)

	run_case("prophets_breath_suppresses_ambush_until_it_expires", func():
		_fresh(-100)
		var seed: int = int(GameState.state["world"]["rollSeed"])
		var hit_day := _first_hit_day()
		assert_true(hit_day > 1, "a 30% roll hits after day 1 within 200 days")
		_fresh(-100)
		GameState.state["world"]["rollSeed"] = seed
		GameState.state["world"]["day"] = hit_day
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		assert_true(ActiveEffects.use(ActiveEffects.PROPHETS_BREATH)["ok"], "Bag use starts it")
		assert_true(ActiveEffects.prophets_breath_active(), "active")
		assert_true(not Ambush.maybe_trigger("shoreditch"), "suppressed on a hit roll")
		assert_eq(GameState.state["event"], null)

		_fresh(-100)
		GameState.state["world"]["rollSeed"] = seed
		GameState.state["world"]["day"] = hit_day - 1
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		ActiveEffects.use(ActiveEffects.PROPHETS_BREATH)
		GameState.state["world"]["day"] = hit_day
		assert_true(not ActiveEffects.prophets_breath_active(), "expired")
		assert_true(Ambush.maybe_trigger("shoreditch"), "ambush resumes after expiry")
	)

	run_case("prophets_breath_leaves_muggings_alone", func():
		_fresh(-100)
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		ActiveEffects.use(ActiveEffects.PROPHETS_BREATH)
		Events.apply_effects([{ "op": "start_street_mugging" }])
		assert_eq(GameState.state["combatPrep"]["kind"], CombatPrep.KIND_STREET_MUGGING)
	)

	run_case("event_op_requests_forced_faction_combat_prep", func():
		_fresh(-100)
		Events.start_event("faction_ambush", { "faction_id": "firm", "faction": "Firm", "district": "shoreditch" })
		Events.apply_effects([{ "op": "start_faction_ambush_combat" }])
		assert_eq(GameState.state["combatPrep"]["kind"], CombatPrep.KIND_FACTION_AMBUSH)
		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["context"], Combat.CONTEXT_FACTION_AMBUSH)
		assert_eq(combat["ambushFactionId"], "firm")
		assert_true(combat["enemies"].size() >= 2)
	)

	run_case("win_costs_relation_and_answers_grudge", func():
		_fresh(-60)
		Grudges.record("firm", "shoreditch")
		Ambush.resolve("firm", true)
		assert_true(not Grudges.has_grudge("firm"))
		var gain: int = int(GameData.FACTION_GRUDGE["answerRelationGain"]) - int(GameData.TURF["ambush"]["winRelationHit"])
		assert_eq(GameState.state["factions"]["firm"]["relation"], -60 + gain)
	)

	run_case("loss_records_a_grudge", func():
		_fresh(-60)
		GameState.state["world"]["currentDistrict"] = "shoreditch"
		Ambush.resolve("firm", false)
		assert_eq(GameState.state["grudges"]["firm"]["district"], "shoreditch")
	)
