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


# Loads a Time Lens (tier 1) on a fresh player Dial at Sense `sense`.
static func _load_time_lens(sense: int) -> void:
	var player: Dictionary = GameState.state["player"]
	player["senseSkill"] = sense
	GameState.state["flags"]["dialGiftGranted"] = true
	var dial: Dictionary = Dial.new_dial("collective_brolly")
	dial["level"] = 5
	dial["lenses"] = [{ "ore": "time", "tier": 1 }]
	player["dial"] = dial


# maybe_trigger's result in shoreditch for each of today's blocks from
# `from_block` on, each from a fresh state on `seed`/`day` (optionally with a
# Time Lens loaded).
static func _block_hits(seed: int, day: int, with_lens: bool, from_block: int = 0) -> Array:
	var hits := []
	for block in range(from_block, TimeSystem.BLOCKS_PER_DAY):
		_fresh(-100)
		if with_lens:
			_load_time_lens(5)
		GameState.state["world"]["rollSeed"] = seed
		GameState.state["world"]["day"] = day
		GameState.state["world"]["timeBlock"] = block
		hits.append(Ambush.maybe_trigger("shoreditch"))
	return hits


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

	run_case("due_today_agrees_with_every_block_roll_and_is_pure", func():
		_fresh(-100)
		var seed: int = int(GameState.state["world"]["rollSeed"])
		var saw_due := false
		var saw_clear := false
		for day in range(1, 41):
			for from_block in TimeSystem.BLOCKS_PER_DAY:
				_fresh(-100)
				GameState.state["world"]["rollSeed"] = seed
				GameState.state["world"]["day"] = day
				GameState.state["world"]["timeBlock"] = from_block
				var before: Dictionary = GameState.deep_copy(GameState.state)
				var due := Ambush.due_today()
				assert_eq(GameState.state, before, "due_today changes nothing")
				var hit: bool = _block_hits(seed, day, false, from_block).has(true)
				assert_eq(due.has("shoreditch"), hit, "day %d from block %d" % [day, from_block])
				saw_due = saw_due or hit
				saw_clear = saw_clear or not hit
		assert_true(saw_due and saw_clear, "40 days give both outcomes")
	)

	run_case("forewarning_needs_time_lens_and_world_gate_and_never_moves_ambushes", func():
		_fresh(-100)
		var seed: int = int(GameState.state["world"]["rollSeed"])
		var day := _first_hit_day()
		assert_true(day > 0, "a hit day exists")
		_fresh(-100)
		GameState.state["world"]["rollSeed"] = seed
		GameState.state["world"]["day"] = day
		assert_true(Ambush.due_today().has("shoreditch"))
		assert_eq(Ambush.forewarned_today(), [] as Array[String], "no lens")
		_load_time_lens(Lenses.gate_level("world") - 1)
		assert_eq(Ambush.forewarned_today(), [] as Array[String], "below the world gate")
		_load_time_lens(Lenses.gate_level("world"))
		assert_eq(Ambush.forewarned_today(), Ambush.due_today(), "at the gate")
		for d in range(1, 21):
			assert_eq(_block_hits(seed, d, true), _block_hits(seed, d, false), "day %d same with lens" % d)
	)

	run_case("prophets_breath_clears_the_forewarning", func():
		_fresh(-100)
		var seed: int = int(GameState.state["world"]["rollSeed"])
		var day := _first_hit_day()
		_fresh(-100)
		_load_time_lens(5)
		GameState.state["world"]["rollSeed"] = seed
		GameState.state["world"]["day"] = day
		assert_true(not Ambush.forewarned_today().is_empty(), "warned before")
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		ActiveEffects.use(ActiveEffects.PROPHETS_BREATH)
		assert_eq(Ambush.due_today(), [] as Array[String], "suppressed: nothing due")
		assert_eq(Ambush.forewarned_today(), [] as Array[String])
	)

	run_case("brief_names_forewarned_districts", func():
		_fresh(-100)
		var seed: int = int(GameState.state["world"]["rollSeed"])
		var day := _first_hit_day()
		_fresh(-100)
		GameState.state["world"]["rollSeed"] = seed
		GameState.state["world"]["day"] = day
		var key := "ambush:%d" % day
		assert_true(DailyBrief.items().all(func(r): return r["key"] != key), "no row without the lens")
		_load_time_lens(5)
		var rows := DailyBrief.items().filter(func(r): return r["key"] == key)
		assert_eq(rows.size(), 1)
		assert_eq([rows[0]["tier"], rows[0]["kind"], rows[0]["action"]], ["urgent", "ambushForewarning", { "to": "map" }])
		assert_true(String(rows[0]["label"]).contains("Shoreditch"), rows[0]["label"])
	)
