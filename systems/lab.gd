class_name Lab
extends RefCounted

# The live Lab (.scratch/lab-port/spec.md): recipe knowledge and procedure
# definitions over GameState.state["lab"] and data/lab.json (GameData.LAB).
#
# A recipe is known once granted (grant_recipe(): its base procedure). Its
# hidden steps -- ideal steps the base procedure lacks or gets wrong, each
# with an authored hint and rung -- are then granted at a specificity
# (grant_steps()): "insight" shows only its apparatus and place, "vague" a
# fuzzy region and direction, "exact" the true band. A grant only ever
# raises a step's specificity.
#
# A manual run (spec § Run rules) is freeform: add_ore() taps one of the
# recipe's jars, spending its fixed amount of the player's real calc, and
# the first tap opens the run. Each perform_*() works the mixture with one
# apparatus, in any order, repeats allowed. finish_run() scores the steps,
# turns the score into a rank and files one item at tier = rank through
# Crafting, gives each step a clue that can teach hidden steps, and may roll
# the re-run bonus. A compress past crackAt cracks the vessel; it and
# abandon_run() lose the calc and give no item. No time block is spent.
# During a lesson (LessonSession) runs draw on its pool instead.
#
# batch() crafts a hand-performed recipe ×N at its best rank. rewind()
# undoes the last run or batch (see § Rewind below).


static func _data() -> Dictionary:
	return GameData.LAB


# ── State ────────────────────────────────────────────────────────────────

static func new_state() -> Dictionary:
	return {
		# recipeKey -> { steps: { "<idealIndex>": specificity }, vagueHits:
		# { "<idealIndex>": in-band runs while vague } }. Unknown steps are
		# absent; specificity is a data/lab.json specificities entry.
		"known": {},
		# recipeKey -> 1..5, only ever rising.
		"bestRanks": {},
		# null, or the run in progress.
		"activeRun": null,
		# Recipe keys performed by hand at least once (batch needs one).
		"performedOnce": [],
		# The Rewind point for the last run or batch, or null: { activeEffects
		# (player.activeEffects before it), calcSpent (net ore type -> n),
		# filed ([{ key, tier, qty }] items it filed), used ([{ item, tier }]
		# effect items used mid-run) }.
		"lastCraft": null,
		# Debug app only: a crafting skill the Lab uses in place of the
		# player's, or null to use the player's.
		"skillOverride": null,
		# null, or the open lesson session (LessonSession).
		"lesson": null,
	}


static func _root() -> Dictionary:
	return GameState.state["lab"]


# ── Knowledge ────────────────────────────────────────────────────────────

static func procedure_def(recipe_key: String) -> Dictionary:
	return _data().get("procedures", {}).get(recipe_key, {})


static func is_known(recipe_key: String) -> bool:
	return _root()["known"].has(recipe_key)


# Known recipes in data/recipes.json order; with an ore type, only those
# using it as an ingredient (the recipe book's ore tab).
static func known_recipes(ore_type: String = "") -> Array:
	var result := []
	for recipe_key in GameData.RECIPES.keys():
		if not is_known(recipe_key):
			continue
		if ore_type.is_empty() or GameData.RECIPES[recipe_key].get("ingredients", {}).has(ore_type):
			result.append(recipe_key)
	return result


# The tier a recipe's items come out at outside a manual run: its best rank,
# or 1 before the first run.
static func item_tier(recipe_key: String) -> int:
	return maxi(1, int(_root()["bestRanks"].get(recipe_key, 0)))


# The tier a Lab staffer's items come out at: their own crafting level,
# capped at data staffTierCap. The player's ranks and skill play no part
# (spec § Staff (Rooms)).
static func staff_item_tier(staff_skill: int) -> int:
	return clampi(staff_skill, 1, int(_data().get("staffTierCap", 4)))


# Adds a recipe at base (no hidden steps known). Granting a known recipe
# changes nothing.
static func grant_recipe(recipe_key: String) -> Dictionary:
	if procedure_def(recipe_key).is_empty():
		return { "ok": false, "reason": "Unknown recipe." }
	var known: Dictionary = _root()["known"]
	if not known.has(recipe_key):
		known[recipe_key] = { "steps": {}, "vagueHits": {} }
		EventBus.state_changed.emit()
	return { "ok": true }


# Grants hidden ideal steps of a known recipe at a specificity: unknown ->
# granted, vague -> exact in place. A grant at or below a step's current
# specificity leaves it alone. Indices that aren't hidden steps are skipped.
# { ok, granted: [idealIndex] } -- the steps whose specificity rose.
static func grant_steps(recipe_key: String, ideal_indices: Array, specificity: String) -> Dictionary:
	var order: Array = _data().get("specificities", [])
	if not order.has(specificity):
		return { "ok": false, "reason": "Unknown specificity." }
	if not is_known(recipe_key):
		return { "ok": false, "reason": "Recipe not known." }
	var entry: Dictionary = _root()["known"][recipe_key]
	var granted := []
	for index in ideal_indices:
		var i := int(index)
		if _hint_for_step(recipe_key, i).is_empty():
			continue
		var key := str(i)
		if order.find(entry["steps"].get(key, "")) >= order.find(specificity):
			continue
		entry["steps"][key] = specificity
		entry["vagueHits"].erase(key)
		granted.append(i)
	if not granted.is_empty():
		EventBus.state_changed.emit()
	return { "ok": true, "granted": granted }


# Ideal indices of a recipe's hidden steps tagged with a rung.
static func rung_steps(recipe_key: String, rung: String) -> Array:
	var result := []
	for hint in procedure_def(recipe_key).get("hints", []):
		if hint.get("rung") == rung:
			result.append(int(hint["step"]))
	return result


# A hidden step's specificity, or "" while unknown.
static func step_specificity(recipe_key: String, ideal_index: int) -> String:
	if not is_known(recipe_key):
		return ""
	return _root()["known"][recipe_key]["steps"].get(str(ideal_index), "")


# The steps the player knows: the base procedure, where each granted hint
# either corrects the target of the base step matching its ideal step or
# inserts that ideal step (no calc) in ideal order. An unknown ideal step is
# simply absent. Each step carries knowledge "base", "insight", "vague" or
# "exact"; a hinted one also its hintId and note. An inserted insight step
# has no target (its place and apparatus only); an insight on a base step
# leaves it as the base step. While the player's Prophet's Breath effect
# runs, every ideal step not known exact shows its true target as knowledge
# "revealed" (unknown steps inserted, vague ones sharpened, no note);
# knowledge is untouched. Targets are floats so a saved run round-trips
# unchanged.
static func known_procedure(recipe_key: String) -> Array:
	if ActiveEffects.prophets_breath_active():
		return _book(recipe_key, true)["steps"]
	return _book(recipe_key, false, LessonSession.talk_through_steps(recipe_key))["steps"]


# The 1-based place an ideal step takes in the known procedure (Prophet's
# Breath aside), or 0 when the book doesn't show it.
static func step_position(recipe_key: String, ideal_index: int) -> int:
	return _book(recipe_key, false)["ideals"].find(ideal_index) + 1


# { steps (the known procedure), ideals (each step's ideal index, -1 for a
# base step matching none) }. talk_through: ideal indices a lesson's
# talk-through shows at their true target, knowledge "talkThrough".
static func _book(recipe_key: String, reveal: bool, talk_through: Array = []) -> Dictionary:
	var procedure := procedure_def(recipe_key)
	var ideal: Array = procedure["ideal"]
	var base: Array = procedure["base"]
	var granted := {}
	for hint in procedure.get("hints", []):
		var level := step_specificity(recipe_key, int(hint["step"]))
		if not level.is_empty():
			granted[int(hint["step"])] = { "hint": hint, "level": level }
	if reveal:
		for i in ideal.size():
			if granted.get(i, {}).get("level") != "exact":
				granted[i] = { "level": "revealed" }
	for i in talk_through:
		if granted.get(int(i), {}).get("level") != "exact":
			granted[int(i)] = { "level": "talkThrough" }
	var book := { "steps": [], "ideals": [] }
	var next_ideal := 0
	var base_matches := match_ideal(ideal, base)
	for i in base.size():
		var m: int = base_matches[i]
		if m >= 0:
			_insert_hinted(book, ideal, granted, next_ideal, m)
			next_ideal = m + 1
		var step: Dictionary = base[i].duplicate(true)
		step["target"] = float(step["target"])
		step["knowledge"] = "base"
		if granted.has(m):
			_apply_hint(step, ideal[m], granted[m])
		book["steps"].append(step)
		book["ideals"].append(m)
	_insert_hinted(book, ideal, granted, next_ideal, ideal.size())
	return book


static func _insert_hinted(book: Dictionary, ideal: Array, granted: Dictionary, from: int, to: int) -> void:
	for i in range(from, to):
		if granted.has(i):
			var step := { "apparatus": ideal[i]["apparatus"] }
			_apply_hint(step, ideal[i], granted[i])
			book["steps"].append(step)
			book["ideals"].append(i)


static func _apply_hint(step: Dictionary, ideal_step: Dictionary, grant: Dictionary) -> void:
	if grant["level"] == "insight":
		if not step.has("target"):
			step["knowledge"] = "insight"
			step["hintId"] = grant["hint"]["id"]
			step["note"] = str(_data()["insightNote"])
		return
	step["target"] = float(ideal_step["target"])
	step["knowledge"] = grant["level"]
	step.erase("note")
	if grant.has("hint"):
		step["hintId"] = grant["hint"]["id"]
		step["note"] = grant["hint"][grant["level"]]["note"]


# The hint at an ideal step, or {} when it has none.
static func _hint_for_step(recipe_key: String, ideal_index: int) -> Dictionary:
	for hint in procedure_def(recipe_key).get("hints", []):
		if int(hint["step"]) == ideal_index:
			return hint
	return {}


static func _hint_by_id(recipe_key: String, hint_id: String) -> Dictionary:
	for hint in procedure_def(recipe_key).get("hints", []):
		if hint["id"] == hint_id:
			return hint
	return {}


# The crafting skill the Lab plays at: the Debug skill override when set,
# else the player's craftingSkill.
static func effective_skill() -> int:
	var override = _root().get("skillOverride")
	if override != null:
		return int(override)
	return int(GameState.state["player"]["craftingSkill"])


# ── Bands ────────────────────────────────────────────────────────────────

# band_half_width = baseTolerance × (1 + skillFactor × effective_skill())
# × (1 + bench_bonus()) (spec § Run rules).
static func band_half_width(recipe_key: String) -> float:
	var skill := effective_skill()
	return float(procedure_def(recipe_key)["baseTolerance"]) \
		* (1.0 + float(_data().get("skillFactor", 0.0)) * skill) \
		* (1.0 + bench_bonus(recipe_key))


# The player's existing craft bonuses, each converted by its
# benchBonusFactors entry: the Home workshop/library bonus, the Guild perk's
# craft bonus, and the seated Movement's attunement when its ore is one of
# the recipe's ingredients.
static func bench_bonus(recipe_key: String) -> float:
	var factors: Dictionary = _data().get("benchBonusFactors", {})
	var attunement := 0.0
	for ore_type in base_calc(recipe_key).keys():
		attunement = maxf(attunement, Dial.attunement_bonus(ore_type))
	return Home.get_workshop_bonus() * float(factors.get("home", 0.0)) \
		+ Perks.craft_chance_bonus() * float(factors.get("perk", 0.0)) \
		+ attunement * float(factors.get("attunement", 0.0))


# What the gauge shows for a known step, clamped to the 0-100 gauge: the
# band around its target, or for a vague step a fuzzy region vagueSpread
# wider each side and shifted by the hint's offset (|offset| <= vagueSpread,
# so the true band always sits inside it). An insight step shows no band: {}.
static func step_region(recipe_key: String, step: Dictionary) -> Dictionary:
	if step.get("knowledge") == "insight":
		return {}
	var half := band_half_width(recipe_key)
	var low := float(step["target"]) - half
	var high := float(step["target"]) + half
	var vague: bool = step.get("knowledge", "base") == "vague"
	if vague:
		var spread := float(_data().get("vagueSpread", 0))
		var offset := float(_hint_by_id(recipe_key, step["hintId"])["vague"]["offset"])
		low += offset - spread
		high += offset + spread
	return { "low": maxf(0.0, low), "high": minf(100.0, high), "vague": vague }


# The known step the open run's next use of this apparatus performs: the
# first known step on it after the last known step the run's performed steps
# have matched, or {} when the book shows none.
static func pending_step(apparatus: String) -> Dictionary:
	var run = active_run()
	if run == null:
		return {}
	var steps := known_procedure(run["recipe"])
	var next := 0
	for m in match_ideal(steps, run["performed"]):
		if m >= 0:
			next = m + 1
	for i in range(next, steps.size()):
		if steps[i]["apparatus"] == apparatus:
			return steps[i]
	return {}


# ── Matching ─────────────────────────────────────────────────────────────

# Pairs each performed step with an ideal step: in order, same apparatus,
# the ideal step's ore (if it names one) already in the mixture by then,
# each ideal step used at most once. -1 marks an extra step.
static func match_ideal(ideal: Array, performed: Array) -> Array[int]:
	var matches: Array[int] = []
	var next := 0
	var mixture := {}
	for step in performed:
		for ore_type in _added_ores(step):
			mixture[ore_type] = true
		var found := -1
		for i in range(next, ideal.size()):
			if ideal[i]["apparatus"] == step["apparatus"] and (not ideal[i].has("ore") or mixture.has(ideal[i]["ore"])):
				found = i
				break
		matches.append(found)
		if found >= 0:
			next = found + 1
	return matches


# The ore types a step adds to the mixture: a performed step's ores, or a
# base procedure step's calc.
static func _added_ores(step: Dictionary) -> Array:
	return step["ores"] if step.has("ores") else step.get("calc", {}).keys()


# ── Clues and learning ───────────────────────────────────────────────────

# Ideal indices of the hidden steps the player can't see the target of yet:
# unknown or insight, and no base step matches them.
static func hidden_ideal_steps(recipe_key: String) -> Array[int]:
	var procedure := procedure_def(recipe_key)
	var base_matches := match_ideal(procedure["ideal"], procedure["base"])
	var hidden: Array[int] = []
	for hint in procedure.get("hints", []):
		var step := int(hint["step"])
		if step_specificity(recipe_key, step) in ["", "insight"] and not base_matches.has(step):
			hidden.append(step)
	return hidden


# One clue per performed step (spec § Run rules), each { apparatus, ideal
# (matched ideal index, -1 for none), clue, direction }:
#   "hit"     in band
#   "near"    right step, wrong amount; direction "higher"/"lower" moves the
#             mean reading toward the ideal target (null when it's already
#             in band, e.g. missed strokes or a stray distil tap)
#   "none"    no effect: an extra step (a wrong-ore step never matches)
#   "changed" an off-book step lands on a hidden ideal step and every
#             on-book step still matches the ideal step it would without it
static func notebook_clues(recipe_key: String, performed: Array) -> Array:
	var ideal: Array = procedure_def(recipe_key)["ideal"]
	var half := band_half_width(recipe_key)
	var matches := match_ideal(ideal, performed)
	var hidden := hidden_ideal_steps(recipe_key)
	var in_place := _book_matches_kept(ideal, performed, matches, hidden)
	var clues := []
	for i in performed.size():
		var m: int = matches[i]
		var clue := { "apparatus": performed[i]["apparatus"], "ideal": m, "clue": "none", "direction": null }
		if m >= 0:
			var target := float(ideal[m]["target"])
			if hidden.has(m) and in_place:
				clue["clue"] = "changed"
			elif performed_accuracy(performed[i], target, half) >= 1.0:
				clue["clue"] = "hit"
			else:
				clue["clue"] = "near"
				clue["direction"] = _direction(performed[i], target, half)
		clues.append(clue)
	return clues


# Whether dropping the off-book steps (those matching a hidden ideal step)
# leaves every other step's match unchanged.
static func _book_matches_kept(ideal: Array, performed: Array, matches: Array[int], hidden: Array[int]) -> bool:
	var book := []
	var book_matches: Array[int] = []
	var mixture := []
	for i in performed.size():
		mixture.append_array(_added_ores(performed[i]))
		if hidden.has(matches[i]):
			continue
		var step: Dictionary = performed[i].duplicate()
		step["ores"] = mixture
		mixture = []
		book.append(step)
		book_matches.append(matches[i])
	return match_ideal(ideal, book) == book_matches


static func _direction(performed: Dictionary, target: float, half_width: float) -> Variant:
	var values := []
	if performed.has("value"):
		values.append(float(performed["value"]))
	for reading in performed.get("readings", []):
		if reading != null:
			values.append(float(reading))
	if values.is_empty():
		return null
	var mean := 0.0
	for v in values:
		mean += v
	mean /= values.size()
	if absf(mean - target) <= half_width:
		return null
	return "higher" if mean < target else "lower"


# Applies a finished run's clues through grant_steps(), the same path story
# and debug grants take: "changed" grants the hidden step vague; a "hit" on
# a vague step counts in vagueHits, and vagueToExactHits of them grant it
# exact. Marks each clue with learned ("vague"/"exact") and, for a counted
# hit, hits so far.
static func _learn(recipe_key: String, clues: Array) -> void:
	var entry: Dictionary = _root()["known"][recipe_key]
	for clue in clues:
		var i: int = clue["ideal"]
		if clue["clue"] == "changed":
			grant_steps(recipe_key, [i], "vague")
			clue["learned"] = "vague"
			continue
		if clue["clue"] != "hit" or step_specificity(recipe_key, i) != "vague":
			continue
		var hits := int(entry["vagueHits"].get(str(i), 0)) + 1
		entry["vagueHits"][str(i)] = hits
		clue["hits"] = hits
		if hits >= int(_data().get("vagueToExactHits", 3)):
			grant_steps(recipe_key, [i], "exact")
			clue["learned"] = "exact"


# ── Calc ─────────────────────────────────────────────────────────────────

# Calc one item of the recipe costs, for the player and Lab staff alike: the
# recipe's data/recipes.json ingredients (its procedure's base steps spend
# exactly this). Crafting skill doesn't reduce it.
static func base_calc(recipe_key: String) -> Dictionary:
	var cost := {}
	var base: Dictionary = GameData.RECIPES.get(recipe_key, {}).get("ingredients", {})
	for ore_type in base.keys():
		cost[ore_type] = int(base[ore_type])
	return cost


# A jar tap adds this much of the ore: the recipe's base calc of it, 0 for
# an ore the recipe doesn't use.
static func jar_amount(recipe_key: String, ore_type: String) -> int:
	return int(base_calc(recipe_key).get(ore_type, 0))


# Where run calc comes from: a running lesson's pool, else the player's
# unstashed orichalchum.
static func _calc_store() -> Dictionary:
	if LessonSession.is_running():
		return LessonSession.pool()
	return GameState.state["player"]["orichalchum"]


# The calc a run can draw on.
static func calc_available(ore_type: String) -> int:
	return int(_calc_store().get(ore_type, 0))


# Every run calc spend goes through here. False (nothing spent) when short.
static func _spend_calc(ore_type: String, amount: int) -> bool:
	if calc_available(ore_type) < amount:
		return false
	_calc_store()[ore_type] = calc_available(ore_type) - amount
	_note_calc(ore_type, amount)
	return true


# ── Manual run ───────────────────────────────────────────────────────────

# Apparatus whose step is one hold-and-release reading (perform_step).
const HOLD_APPARATUS: Array[String] = ["heat", "compression"]


static func active_run() -> Variant:
	return _root()["activeRun"]


static func gauge(apparatus: String) -> Dictionary:
	return _data()["gauges"][apparatus]


# Step-end feedback timings and the input-zone pulse (data/lab.json feedback).
static func feedback() -> Dictionary:
	return _data()["feedback"]


# The ore type of a recipe's first calc, which tints the gauge's input zone.
static func lead_ore(recipe_key: String) -> String:
	var keys := base_calc(recipe_key).keys()
	return str(keys[0]) if not keys.is_empty() else ""


# Bench plate region ids (data/hq_visuals.json labBench): an ore jar is
# "ore_<oreType>", an apparatus "apparatus_<apparatusId>".
const ORE_REGION_PREFIX := "ore_"
const APPARATUS_REGION_PREFIX := "apparatus_"


# An apparatus's display name: its painted label on the bench plate, else
# its data/approaches.json name.
static func apparatus_name(apparatus: String) -> String:
	var regions: Dictionary = GameData.HQ_VISUALS["labBench"]["regions"]
	var region: Dictionary = regions.get(APPARATUS_REGION_PREFIX + apparatus, {})
	return region.get("label", GameData.APPROACHES[apparatus]["name"])


# Opens a run by tapping every recipe jar once (the whole base calc).
static func begin_run(recipe_key: String) -> Dictionary:
	if active_run() != null:
		return { "ok": false, "reason": "A run is already open." }
	if not is_known(recipe_key):
		return { "ok": false, "reason": "Recipe not known." }
	var lesson_block := LessonSession.run_block_reason(recipe_key)
	if not lesson_block.is_empty():
		return { "ok": false, "reason": lesson_block }
	var cost := base_calc(recipe_key)
	for ore_type in cost.keys():
		if calc_available(ore_type) < int(cost[ore_type]):
			return { "ok": false, "reason": "Not enough calc." }
	for ore_type in cost.keys():
		add_ore(recipe_key, ore_type)
	return { "ok": true }


# Taps a jar: spends the ore's fixed recipe amount from real calc into the
# mixture. Only the run recipe's own jars tap. The first tap opens the run;
# it records { recipe, startedMsec, calcSpent, performed, added } (added =
# ore types tapped in since the last step).
static func add_ore(recipe_key: String, ore_type: String) -> Dictionary:
	var run = active_run()
	if run != null and run["recipe"] != recipe_key:
		return { "ok": false, "reason": "Another run is open." }
	if not is_known(recipe_key):
		return { "ok": false, "reason": "Recipe not known." }
	var lesson_block := LessonSession.run_block_reason(recipe_key)
	if not lesson_block.is_empty():
		return { "ok": false, "reason": lesson_block }
	var amount := jar_amount(recipe_key, ore_type)
	if amount <= 0:
		var ore_name: String = GameData.ORE_TYPES.get(ore_type, {}).get("name", ore_type)
		var recipe_name: String = GameData.RECIPES.get(recipe_key, {}).get("name", "This recipe")
		return { "ok": false, "reason": "%s doesn't use %s." % [recipe_name, ore_name] }
	if calc_available(ore_type) < amount:
		return { "ok": false, "reason": "Not enough calc." }
	if run == null:
		_open_rewind_point()
	_spend_calc(ore_type, amount)
	if run == null:
		run = {
			"recipe": recipe_key, "startedMsec": Time.get_ticks_msec(), "calcSpent": {},
			"performed": [], "added": [],
		}
		_root()["activeRun"] = run
	run["calcSpent"][ore_type] = int(run["calcSpent"].get(ore_type, 0)) + amount
	if not run["added"].has(ore_type):
		run["added"].append(ore_type)
	EventBus.state_changed.emit()
	return { "ok": true }


# An apparatus works the mixture only once a jar tap has opened the run.
static func check_apparatus() -> Dictionary:
	if active_run() == null:
		return { "ok": false, "reason": "Add calc from a jar first." }
	return { "ok": true }


# Heat or compress: commits the raw needle value at release. A compress at
# or past crackAt cracks the vessel and ends the run with no item.
static func perform_step(apparatus: String, value: float) -> Dictionary:
	if not HOLD_APPARATUS.has(apparatus):
		return { "ok": false, "reason": "Not a hold apparatus." }
	var check := check_apparatus()
	if not check["ok"]:
		return check
	value = clampf(value, 0.0, 100.0)
	_perform(apparatus, { "value": value })
	if apparatus == "compression" and value >= float(gauge("compression")["crackAt"]):
		var result := _close_run("cracked")
		result["cracked"] = true
		return result
	EventBus.state_changed.emit()
	return { "ok": true }


# Grind: commits the pestle meter reading at each stroke. Strokes past the
# gauge's count are ignored; strokes short of it read as misses.
static func perform_grind(readings: Array) -> Dictionary:
	var check := check_apparatus()
	if not check["ok"]:
		return check
	var clamped := []
	for i in int(gauge("grinding")["strokes"]):
		clamped.append(clampf(float(readings[i]), 0.0, 100.0) if i < readings.size() else null)
	_perform("grinding", { "readings": clamped })
	EventBus.state_changed.emit()
	return { "ok": true }


# Distil: commits the tap times (msec since the first drip started).
static func perform_distil(tap_msecs: Array) -> Dictionary:
	var check := check_apparatus()
	if not check["ok"]:
		return check
	_perform("distilling", distil_readings(tap_msecs))
	EventBus.state_changed.emit()
	return { "ok": true }


# Drip i falls from 0 to 100 over fallMsec, starting at i × beatMsec. A tap
# during a drip's fall reads its position; a tap between drips, after the
# last, or a second tap on the same drip is stray. Untapped drips read null.
static func distil_readings(tap_msecs: Array) -> Dictionary:
	var g := gauge("distilling")
	var beat := float(g["beatMsec"])
	var fall := float(g["fallMsec"])
	var readings := []
	readings.resize(int(g["drips"]))
	var stray := false
	for tap in tap_msecs:
		var t := float(tap)
		var drip := floori(t / beat)
		var into := t - drip * beat
		if drip < 0 or drip >= readings.size() or into > fall or readings[drip] != null:
			stray = true
			continue
		readings[drip] = 100.0 * into / fall
	return { "readings": readings, "stray": stray }


# Records the step ({ apparatus, ores, value } for a hold step, { apparatus,
# ores, readings } for grind, plus stray for distil) with the ores tapped in
# since the previous one.
static func _perform(apparatus: String, record: Dictionary) -> void:
	var run: Dictionary = active_run()
	record["apparatus"] = apparatus
	record["ores"] = run["added"]
	run["added"] = []
	run["performed"].append(record)


# Finish: scores the performed steps (none scores 0), turns them into clues
# and learns from them, then files the item(s) at tier = rank through
# Crafting.file_crafted() with the recipe's xpReward × the bonus's
# xpMultiplier. A rank at or above the best rank rolls the re-run bonus
# (one type drawn at random); a score below badRun.scoreBelow sometimes
# returns a flavour line; then the insight roll (RecipeKnowledge.roll_insight,
# finished runs only). Best rank only rises; the recipe joins performedOnce.
# A running lesson hears of the run (result.lesson, LessonSession.after_run).
static func finish_run() -> Dictionary:
	var run = active_run()
	if run == null:
		return { "ok": false, "reason": "No run open." }
	var s := _root()
	var recipe_key: String = run["recipe"]
	var scored := score_procedure(recipe_key, run["performed"])
	var clues := notebook_clues(recipe_key, run["performed"])
	_learn(recipe_key, clues)
	var lady_bonus := lady_score_bonus()
	var score := clampi(int(scored["score"]) + lady_bonus, 0, 100)
	var rank := rank_for_score(score)
	var prior_best := int(s["bestRanks"].get(recipe_key, 0))
	var bonus := _roll_bonus(rank, prior_best)
	var type_def: Dictionary = _data()["bonus"]["types"].get(bonus, {})
	var refunded := _refund_calc(run["calcSpent"], float(type_def.get("refundFraction", 0.0)))
	var flavour = _bad_run_line(score)
	var insight = RecipeKnowledge.roll_insight(recipe_key)
	s["bestRanks"][recipe_key] = maxi(prior_best, rank)
	if not s["performedOnce"].has(recipe_key):
		s["performedOnce"].append(recipe_key)
	var steps := []
	for i in run["performed"].size():
		var performed: Dictionary = run["performed"][i].duplicate(true)
		performed["accuracy"] = scored["accuracies"][i]
		steps.append(performed)
	var xp := roundi(int(GameData.RECIPES[recipe_key]["xpReward"]) * float(type_def.get("xpMultiplier", 1.0)))
	var extra_items := int(type_def.get("extraItems", 0))
	var net_calc := {}
	for ore_type in run["calcSpent"].keys():
		net_calc[ore_type] = int(run["calcSpent"][ore_type]) - int(refunded.get(ore_type, 0))
	s["activeRun"] = null
	_file(recipe_key, rank, 1, false, net_calc, xp)
	_file(recipe_key, rank, extra_items, false, {}, 0)
	var result := {
		"ok": true, "recipe": recipe_key, "outcome": "finished", "score": score,
		"rawScore": scored["score"], "ladyBonus": lady_bonus, "rank": rank,
		"items": 1 + extra_items, "xp": xp, "newBest": rank > prior_best, "steps": steps,
		"clues": clues, "bonus": bonus if not bonus.is_empty() else null,
		"refunded": refunded, "flavour": flavour, "insight": insight,
		"durationMsec": maxi(0, Time.get_ticks_msec() - int(run["startedMsec"])),
	}
	_after_lesson_run(result)
	_emit_hook(result)
	return result


static func _after_lesson_run(result: Dictionary) -> void:
	if LessonSession.is_running():
		result["lesson"] = LessonSession.after_run(result)


# A bonus type id when a rank at or above the prior best wins the bonus
# chance, else "".
static func _roll_bonus(rank: int, prior_best: int) -> String:
	var bonus_def: Dictionary = _data()["bonus"]
	if rank < prior_best or not Rng.chance(float(bonus_def.get("chance", 0.0))):
		return ""
	return Rng.rand_from(bonus_def["types"].keys())


# Gives back floor(spent × fraction) of each ore to where it came from.
# ore type -> amount refunded (amounts of 0 left out).
static func _refund_calc(spent: Dictionary, fraction: float) -> Dictionary:
	var refunded := {}
	var orichalchum: Dictionary = _calc_store()
	for ore_type in spent.keys():
		var amount := floori(int(spent[ore_type]) * fraction)
		if amount > 0:
			orichalchum[ore_type] = calc_available(ore_type) + amount
			refunded[ore_type] = amount
			_note_calc(ore_type, -amount)
	return refunded


# A badRun line one time in oneIn for a score below scoreBelow, else null.
static func _bad_run_line(score: int) -> Variant:
	var bad_run: Dictionary = _data()["badRun"]
	var lines: Array = bad_run.get("lines", [])
	if score >= int(bad_run.get("scoreBelow", 0)) or lines.is_empty():
		return null
	if Rng.randi_range(1, int(bad_run.get("oneIn", 1))) != 1:
		return null
	return Rng.rand_from(lines)


# Gives the run up: the calc spent stays spent, no item.
static func abandon_run() -> Dictionary:
	if active_run() == null:
		return { "ok": false, "reason": "No run open." }
	return _close_run("abandoned")


# Ends an open run with no item; the calc spent so far stays spent and the
# recipe's xpReward / failedRunXpDivisor XP is awarded.
static func _close_run(outcome: String) -> Dictionary:
	var run: Dictionary = active_run()
	var recipe_key: String = run["recipe"]
	var xp := floori(float(GameData.RECIPES[recipe_key]["xpReward"]) / float(_data().get("failedRunXpDivisor", 3)))
	_root()["activeRun"] = null
	Crafting.award_crafting_xp(xp)
	EventBus.state_changed.emit()
	var result := {
		"ok": true, "recipe": recipe_key, "outcome": outcome, "score": 0, "rank": 0,
		"items": 0, "xp": xp,
		"durationMsec": maxi(0, Time.get_ticks_msec() - int(run["startedMsec"])),
	}
	_after_lesson_run(result)
	_emit_hook(result)
	return result


# The manual-run hook (spec § Run rules): once per completed manual run.
static func _emit_hook(result: Dictionary) -> void:
	EventBus.lab_run_completed.emit({
		"recipe": result["recipe"], "score": result["score"],
		"rank": result["rank"], "outcome": result["outcome"],
	})


# ── Scoring ──────────────────────────────────────────────────────────────

# rankThresholds[i] is the minimum score for rank i+1; never below rank 1.
static func rank_for_score(score: int) -> int:
	var rank := 0
	for threshold in _data().get("rankThresholds", []):
		if score >= int(threshold):
			rank += 1
	return maxi(rank, 1)


# 1.0 inside the band, falling linearly to 0 at 2× the band.
static func step_accuracy(value: float, target: float, half_width: float) -> float:
	var off := absf(value - target)
	if off <= half_width:
		return 1.0
	return clampf(2.0 - off / half_width, 0.0, 1.0)


# A performed step's accuracy against its ideal target: a hold step's one
# value, or the mean over a grind/distil step's readings (a missed one
# scores 0). A stray distil tap spoils the whole step.
static func performed_accuracy(performed: Dictionary, target: float, half_width: float) -> float:
	if performed.get("stray", false):
		return 0.0
	if not performed.has("readings"):
		return step_accuracy(float(performed["value"]), target, half_width)
	var readings: Array = performed["readings"]
	if readings.is_empty():
		return 0.0
	var total := 0.0
	for reading in readings:
		if reading != null:
			total += step_accuracy(float(reading), target, half_width)
	return total / readings.size()


# score = Σ weight × accuracy over the ideal steps (a missing one scores 0),
# minus extraStepPenalty per extra step, clamped 0-100. accuracies is per
# performed step (null for an extra).
static func score_procedure(recipe_key: String, performed: Array) -> Dictionary:
	var ideal: Array = procedure_def(recipe_key)["ideal"]
	var half := band_half_width(recipe_key)
	var matches := match_ideal(ideal, performed)
	var total := 0.0
	var accuracies := []
	for i in performed.size():
		if matches[i] < 0:
			total -= float(_data().get("extraStepPenalty", 0))
			accuracies.append(null)
			continue
		var ideal_step: Dictionary = ideal[matches[i]]
		var accuracy := performed_accuracy(performed[i], float(ideal_step["target"]), half)
		total += float(ideal_step["weight"]) * accuracy
		accuracies.append(accuracy)
	return { "score": clampi(roundi(total), 0, 100), "accuracies": accuracies }


# ── Bench effects ────────────────────────────────────────────────────────

# Score points the player's Be A Lady effect adds to a finished run: item
# level × ladyScorePerLevel, 0 when inactive.
static func lady_score_bonus() -> int:
	var effect = ActiveEffects.find(ActiveEffects.LADY)
	if effect == null:
		return 0
	return int(effect["level"]) * int(_data().get("ladyScorePerLevel", 0))


# The active effects the bench's Use item control can start from the
# player's inventory (Prophet's Breath reveals bands, Be A Lady adds score).
static func usable_effects() -> Array:
	return [ActiveEffects.PROPHETS_BREATH, ActiveEffects.LADY]


# An item used mid-run comes back if the run is Rewound.
static func use_effect(item: String) -> Dictionary:
	if not usable_effects().has(item):
		return { "ok": false, "reason": "Can't use that here." }
	var result := ActiveEffects.use(item)
	var point = _root()["lastCraft"]
	if result["ok"] and active_run() != null and point != null and not LessonSession.is_open():
		point["used"].append({ "item": item, "tier": int(result["level"]) })
	return result



# ── Batch ────────────────────────────────────────────────────────────────

# Crafts `count` of a recipe performed by hand at least once, at its best
# rank, for base calc × count: no performance, never fails, xpReward XP per
# item and no manual-run hook. multi files under the multi-target key when
# Crafting.multi_craft_available() allows it.
static func batch(recipe_key: String, count: int, multi: bool = false) -> Dictionary:
	var s := _root()
	if s["activeRun"] != null:
		return { "ok": false, "reason": "Finish the open run first." }
	if LessonSession.is_open():
		return { "ok": false, "reason": "Not during a lesson." }
	if count < 1 or not is_known(recipe_key):
		return { "ok": false, "reason": "Nothing to craft." }
	if not s["performedOnce"].has(recipe_key):
		return { "ok": false, "reason": "Craft it by hand first." }
	var per_item := base_calc(recipe_key)
	for ore_type in per_item.keys():
		if calc_available(ore_type) < int(per_item[ore_type]) * count:
			return { "ok": false, "reason": "Not enough calc." }
	multi = multi and Crafting.multi_craft_available(recipe_key)
	var rank := int(s["bestRanks"].get(recipe_key, 1))
	var xp := int(GameData.RECIPES[recipe_key]["xpReward"]) * count
	_open_rewind_point()
	for ore_type in per_item.keys():
		_spend_calc(ore_type, int(per_item[ore_type]) * count)
	_file(recipe_key, rank, count, multi, per_item, xp)
	return {
		"ok": true, "recipe": recipe_key, "items": count, "rank": rank,
		"multi": multi, "xp": xp,
	}


# The most items the player's calc pays for in one batch.
static func max_batch(recipe_key: String) -> int:
	var per_item := base_calc(recipe_key)
	var most := -1
	for ore_type in per_item.keys():
		var count := floori(calc_available(ore_type) / float(per_item[ore_type]))
		most = count if most < 0 else mini(most, count)
	return maxi(most, 0)


# Files items through Crafting, noting them on the Rewind point.
static func _file(recipe_key: String, tier: int, qty: int, multi: bool, costs_per_item: Dictionary, xp: int) -> void:
	if qty <= 0:
		return
	var point = _root()["lastCraft"]
	if point != null and not LessonSession.is_open():
		point["filed"].append({ "key": Crafting.inventory_key(recipe_key, multi), "tier": tier, "qty": qty })
	Crafting.file_crafted(recipe_key, tier, qty, multi, costs_per_item, xp)


# ── Rewind ───────────────────────────────────────────────────────────────
# The bench Rewind (spec § Rewind) undoes the last run or batch: the calc it
# spent comes back, the items it filed and the open run go, items used
# mid-run return and active effects go back to before it. XP, and what the
# run taught (known steps, best rank, performedOnce), stay -- the player
# remembers. Paid like the event/combat Rewind (Rewind.choose_payment()).

# A run's first jar tap, or a batch, opens a new Rewind point. A lesson's
# runs leave the last one as it was: their calc and items stay out of it.
static func _open_rewind_point() -> void:
	if LessonSession.is_open():
		return
	_root()["lastCraft"] = {
		"activeEffects": GameState.deep_copy(ActiveEffects.effects()),
		"calcSpent": {}, "filed": [], "used": [],
	}


static func _note_calc(ore_type: String, amount: int) -> void:
	var point = _root()["lastCraft"]
	if point != null and not LessonSession.is_open():
		point["calcSpent"][ore_type] = int(point["calcSpent"].get(ore_type, 0)) + amount


static func has_rewind_point() -> bool:
	return _root()["lastCraft"] != null


static func can_rewind() -> bool:
	return has_rewind_point() and Rewind.can_pay() and not LessonSession.is_open()


static func rewind(source: String = "") -> Dictionary:
	if LessonSession.is_open():
		return { "ok": false, "reason": "Not during a lesson." }
	var point = _root()["lastCraft"]
	if point == null:
		return { "ok": false, "reason": "Nothing to rewind." }
	var payment := Rewind.choose_payment(source)
	if not payment["ok"]:
		return payment
	if not _filed_in_stock(point["filed"]):
		return { "ok": false, "reason": "What it made is gone." }
	# Rewinds the craft made can't pay for undoing it.
	if payment["consumable"] and Crafting.inventory_qty("rewind") <= _filed_qty(point["filed"], "rewind"):
		if source != "" or int(payment["dialIndex"]) < 0:
			return { "ok": false, "reason": "No Rewind in stock." }
		payment["consumable"] = false
	var player: Dictionary = GameState.state["player"]
	for filed in point["filed"]:
		Crafting.inventory_remove_from_tier(filed["key"], int(filed["tier"]), int(filed["qty"]))
	for ore_type in point["calcSpent"].keys():
		player["orichalchum"][ore_type] = calc_available(ore_type) + int(point["calcSpent"][ore_type])
	for used in point["used"]:
		Crafting.inventory_add(used["item"], int(used["tier"]), 1)
	player["activeEffects"] = GameState.deep_copy(point["activeEffects"])
	_root()["activeRun"] = null
	_root()["lastCraft"] = null
	Rewind.pay(payment)
	EventBus.state_changed.emit()
	return { "ok": true }


static func _filed_qty(filed_list: Array, key: String) -> int:
	var qty := 0
	for filed in filed_list:
		if filed["key"] == key:
			qty += int(filed["qty"])
	return qty


static func _filed_in_stock(filed_list: Array) -> bool:
	var needed := {}
	for filed in filed_list:
		var unit := "%s|%d" % [filed["key"], int(filed["tier"])]
		needed[unit] = int(needed.get(unit, 0)) + int(filed["qty"])
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	for unit in needed.keys():
		var parts: PackedStringArray = unit.split("|")
		if int(inventory.get(parts[0], {}).get(parts[1], 0)) < int(needed[unit]):
			return false
	return true


# ── Debug (Debug app Lab page) ───────────────────────────────────────────

static func set_skill_override(skill: int) -> void:
	_root()["skillOverride"] = clampi(skill, 0, int(_data()["debug"]["skillMax"]))
	EventBus.state_changed.emit()


static func clear_skill_override() -> void:
	_root()["skillOverride"] = null
	EventBus.state_changed.emit()


# Forgets a recipe and every hidden step granted for it. Its best rank and
# performedOnce entry stand. Refused while its run is open.
static func revoke_recipe(recipe_key: String) -> Dictionary:
	var run = active_run()
	if run != null and run["recipe"] == recipe_key:
		return { "ok": false, "reason": "Run open." }
	if _root()["known"].erase(recipe_key):
		EventBus.state_changed.emit()
	return { "ok": true }


# Sets a recipe's best rank outright, lower included; 0 clears it.
static func set_best_rank(recipe_key: String, rank: int) -> Dictionary:
	if procedure_def(recipe_key).is_empty():
		return { "ok": false, "reason": "Unknown recipe." }
	var best: Dictionary = _root()["bestRanks"]
	if rank <= 0:
		best.erase(recipe_key)
	else:
		best[recipe_key] = mini(rank, int(_data()["rankThresholds"].size()))
	EventBus.state_changed.emit()
	return { "ok": true }


# Tops every ore type's calc up to debug.refillCalc; more is left alone.
static func refill_calc() -> void:
	var target := int(_data()["debug"]["refillCalc"])
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	for ore_type in GameData.ORE_TYPES.keys():
		orichalchum[ore_type] = maxi(calc_available(ore_type), target)
	EventBus.state_changed.emit()
