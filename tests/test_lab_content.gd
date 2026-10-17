extends "res://tests/test_base.gd"

# The procedure content test (.scratch/lab-port/spec.md § Content P1/P2,
# § Testing Decisions Seam 4): every authored procedure in data/lab.json is
# schema-valid, spends exactly its recipe's ingredients, has a full rung
# ladder of hidden steps, and a perfect max-skill run at each knowledge
# level scores inside that level's band.

# Knowledge level (rungs granted so far) -> [min, max] perfect-run score.
const BANDS := [[40, 59], [60, 74], [75, 89], [90, 100]]
const PROTOTYPE_RECIPES := ["timePearl", "healingSalve", "healingBurst"]


func _procedures() -> Dictionary:
	return GameData.LAB["procedures"]


func _rungs() -> Array:
	return GameData.LAB["rungs"]


# A run that performs every known step dead on its shown target, tapping in
# a base step's calc ores just before it.
func _perfect_run(recipe_key: String) -> Array:
	var performed := []
	for step in Lab.known_procedure(recipe_key):
		var record := { "apparatus": step["apparatus"], "ores": step.get("calc", {}).keys() }
		var target := float(step["target"])
		match step["apparatus"]:
			"grinding":
				record["readings"] = _repeat(target, int(Lab.gauge("grinding")["strokes"]))
			"distilling":
				record["readings"] = _repeat(target, int(Lab.gauge("distilling")["drips"]))
			_:
				record["value"] = target
		performed.append(record)
	return performed


func _repeat(value: float, count: int) -> Array:
	var result := []
	for i in count:
		result.append(value)
	return result


func run() -> void:
	run_case("prototype_recipes_have_procedures", func():
		for recipe_key in PROTOTYPE_RECIPES:
			assert_true(_procedures().has(recipe_key), "%s has a procedure" % recipe_key)
	)

	run_case("every_procedure_is_schema_valid", func():
		var errors := GameData.validate_tables(GameData.snapshot())
		for recipe_key in _procedures():
			var where := "lab.procedures.%s" % recipe_key
			var own := errors.filter(func(e): return e.contains(where))
			assert_true(own.is_empty(), "%s validates: %s" % [where, own])
	)

	run_case("base_calc_is_the_recipe_ingredients", func():
		for recipe_key in _procedures():
			var spent := {}
			for step in _procedures()[recipe_key]["base"]:
				for ore_type in step.get("calc", {}):
					spent[ore_type] = int(spent.get(ore_type, 0)) + int(step["calc"][ore_type])
			assert_eq(spent, Lab.base_calc(recipe_key), "%s base steps spend its ingredients" % recipe_key)
			for ore_type in GameData.RECIPES[recipe_key]["ingredients"]:
				assert_true(spent.has(ore_type), "%s: ingredient %s in base" % [recipe_key, ore_type])
	)

	run_case("base_calc_off_the_ingredients_fails_validation", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["recipes"]["healingBurst"]["ingredients"]["life"] += 1
		var errors := GameData.validate_tables(corrupted)
		assert_true(errors.any(func(e): return e.contains("lab.procedures.healingBurst.base")), "mismatch flagged")
	)

	run_case("every_hidden_step_has_one_rung_and_every_rung_a_step", func():
		for recipe_key in _procedures():
			var procedure: Dictionary = _procedures()[recipe_key]
			var base_matched := Lab.match_ideal(procedure["ideal"], procedure["base"])
			var hinted := {}
			for hint in procedure["hints"]:
				assert_true(_rungs().has(hint.get("rung")), "%s.%s has a rung" % [recipe_key, hint["id"]])
				hinted[int(hint["step"])] = true
			for i in procedure["ideal"].size():
				if not base_matched.has(i):
					assert_true(hinted.has(i), "%s: inserted ideal step %d has a hint" % [recipe_key, i])
			for rung in _rungs():
				assert_true(not Lab.rung_steps(recipe_key, rung).is_empty(), "%s has a %s step" % [recipe_key, rung])
	)

	run_case("perfect_max_skill_run_lands_in_each_knowledge_band", func():
		var max_skill := GameData.CRAFTING_XP_LEVELS.size() - 1
		for recipe_key in _procedures():
			GameState.reset()
			GameState.state["player"]["craftingSkill"] = max_skill
			Lab.grant_recipe(recipe_key)
			for level in BANDS.size():
				if level > 0:
					Lab.grant_steps(recipe_key, Lab.rung_steps(recipe_key, _rungs()[level - 1]), "exact")
				var score: int = Lab.score_procedure(recipe_key, _perfect_run(recipe_key))["score"]
				var band: Array = BANDS[level]
				assert_true(score >= band[0] and score <= band[1], "%s level %d scores %d, band %s" % [recipe_key, level, score, band])
	)
