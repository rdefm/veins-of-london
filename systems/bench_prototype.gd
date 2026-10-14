class_name BenchPrototype
extends RefCounted

# Sandboxed Lab-revamp bench prototype (.scratch/lab-revamp/spec.md
# §Shared core rules). Two independent slices, "procedure" and "chart",
# each with its own calc pool, per-recipe best ranks, hint levels, item
# ledger and Rewind stack, all under GameState.state["benchPrototype"].
# Reads the player's real craftingSkill as a default and never writes
# anything outside benchPrototype -- no real inventory, XP or bench state.
#
# A manual run is begin_run() -> finish_run(score) (or abandon_run()).
# begin_run() pushes the Rewind snapshot and spends the recipe's base calc
# up front; finish_run() turns the score into a rank, raises best rank,
# rolls the re-run bonus and the bad-run flavour line, and logs the item.
#
# The procedure slice's real run is begin_procedure_run() -> one perform_*()
# per step with the raw gauge input (heat/compress released value, grind
# stroke readings, distil tap timings). Calc is spent step by step as each
# step is performed; the last step scores the run (spec §Slice A) and hands
# the score to finish_run(). A compress released at or past crackAt cracks
# the vessel and ends the run with no item.

const SLICE_PROCEDURE := "procedure"
const SLICE_CHART := "chart"
const SLICES: Array[String] = [SLICE_PROCEDURE, SLICE_CHART]

const BATCH_SIZES: Array[int] = [1, 5, 10]

# Apparatus whose step is one hold-and-release reading (perform_step).
const HOLD_APPARATUS: Array[String] = ["heat", "compression"]


static func _data() -> Dictionary:
	return GameData.BENCH_PROTOTYPE


# ── State ────────────────────────────────────────────────────────────────

static func new_state() -> Dictionary:
	var slices := {}
	for slice_id in SLICES:
		slices[slice_id] = new_slice(slice_id)
	return {
		"activeSlice": SLICE_PROCEDURE,
		# null = follow the player's real craftingSkill (read only).
		"skillOverride": null,
		"bonusType": _data().get("bonus", {}).get("defaultType", ""),
		"slices": slices,
	}


static func new_slice(slice_id: String) -> Dictionary:
	var best_ranks := {}
	var hint_levels := {}
	for recipe_id in _data().get("roster", []):
		best_ranks[recipe_id] = 0
		var levels := {}
		for hint in hints(slice_id, recipe_id):
			levels[hint["id"]] = "off"
		hint_levels[recipe_id] = levels
	return {
		"pool": _data().get("poolSeed", {}).duplicate(),
		"bestRanks": best_ranks,
		# recipeId -> { hintId -> "off" | "vague" | "exact" }.
		"hintLevels": hint_levels,
		"ledger": [],
		"xpTotal": 0,
		# null, or { recipeId, startedMsec, calcSpent } while a manual run is
		# open; a procedure run adds procedure (steps being run) and
		# performed (so far: { apparatus, value } for a hold step,
		# { apparatus, readings } for grind, plus stray for distil).
		"activeRun": null,
		"snapshots": [],
	}


static func _root() -> Dictionary:
	return GameState.state["benchPrototype"]


static func slice(slice_id: String) -> Dictionary:
	return _root()["slices"][slice_id]


# ── Pure core rules ──────────────────────────────────────────────────────

static func rank_for_score(score: int) -> int:
	var rank := 0
	for threshold in _data().get("rankThresholds", []):
		if score >= int(threshold):
			rank += 1
	return maxi(rank, 1)


static func effective_skill() -> int:
	var override = _root().get("skillOverride")
	if override != null:
		return int(override)
	return int(GameState.state["player"]["craftingSkill"])


# Widening multiplier every tolerance band/bullseye radius is scaled by:
# 1 + skillFactor × craftingSkill (spec §Slice A Tolerance, §Slice B).
static func skill_multiplier() -> float:
	return 1.0 + float(_data().get("skillFactor", 0.0)) * effective_skill()


static func recipe_cost(recipe_id: String, count: int = 1) -> Dictionary:
	var cost := {}
	var base: Dictionary = _data()["recipes"][recipe_id].get("baseCalc", {})
	for ore_type in base.keys():
		cost[ore_type] = int(base[ore_type]) * count
	return cost


static func can_afford(slice_id: String, cost: Dictionary) -> bool:
	var pool: Dictionary = slice(slice_id)["pool"]
	for ore_type in cost.keys():
		if int(pool.get(ore_type, 0)) < int(cost[ore_type]):
			return false
	return true


static func _spend(s: Dictionary, cost: Dictionary) -> void:
	for ore_type in cost.keys():
		s["pool"][ore_type] = int(s["pool"].get(ore_type, 0)) - int(cost[ore_type])


static func _refund(s: Dictionary, cost: Dictionary, fraction: float) -> Dictionary:
	var refunded := {}
	for ore_type in cost.keys():
		var amount: int = int(floor(int(cost[ore_type]) * fraction))
		if amount > 0:
			s["pool"][ore_type] = int(s["pool"].get(ore_type, 0)) + amount
			refunded[ore_type] = amount
	return refunded


# ── Debug controls ───────────────────────────────────────────────────────

static func open() -> void:
	Nav.go_to("bench_prototype")


static func exit() -> void:
	Nav.go_to("phone")


static func set_active_slice(slice_id: String) -> Dictionary:
	if not SLICES.has(slice_id):
		return { "ok": false, "reason": "Unknown slice." }
	_root()["activeSlice"] = slice_id
	EventBus.state_changed.emit()
	return { "ok": true }


static func set_skill_override(skill: int) -> void:
	_root()["skillOverride"] = clampi(skill, 0, int(_data().get("skillMax", 10)))
	EventBus.state_changed.emit()


static func clear_skill_override() -> void:
	_root()["skillOverride"] = null
	EventBus.state_changed.emit()


static func set_bonus_type(bonus_type: String) -> Dictionary:
	if not _data().get("bonus", {}).get("types", {}).has(bonus_type):
		return { "ok": false, "reason": "Unknown bonus type." }
	_root()["bonusType"] = bonus_type
	EventBus.state_changed.emit()
	return { "ok": true }


# The authored hints a slice's debug toggles can grant for a recipe.
static func hints(slice_id: String, recipe_id: String) -> Array:
	if slice_id != SLICE_PROCEDURE or not _data()["recipes"].has(recipe_id):
		return []
	return procedure_def(recipe_id).get("hints", [])


static func hint_def(slice_id: String, recipe_id: String, hint_id: String) -> Dictionary:
	for hint in hints(slice_id, recipe_id):
		if hint["id"] == hint_id:
			return hint
	return {}


static func hint_level(slice_id: String, recipe_id: String, hint_id: String) -> String:
	var levels = slice(slice_id)["hintLevels"].get(recipe_id)
	return levels.get(hint_id, "off") if levels is Dictionary else "off"


static func set_hint_level(slice_id: String, recipe_id: String, hint_id: String, level: String) -> Dictionary:
	if not _data().get("hintLevels", []).has(level):
		return { "ok": false, "reason": "Unknown hint level." }
	if hint_def(slice_id, recipe_id, hint_id).is_empty():
		return { "ok": false, "reason": "Unknown hint." }
	var s := slice(slice_id)
	if not s["hintLevels"].get(recipe_id) is Dictionary:
		s["hintLevels"][recipe_id] = {}
	s["hintLevels"][recipe_id][hint_id] = level
	EventBus.state_changed.emit()
	return { "ok": true }


static func refill_pool(slice_id: String) -> void:
	slice(slice_id)["pool"] = _data().get("poolSeed", {}).duplicate()
	EventBus.state_changed.emit()


# ── Manual run ───────────────────────────────────────────────────────────

static func begin_run(slice_id: String, recipe_id: String) -> Dictionary:
	var s := slice(slice_id)
	if s["activeRun"] != null:
		return { "ok": false, "reason": "A run is already open." }
	if not _data()["recipes"].has(recipe_id):
		return { "ok": false, "reason": "Unknown recipe." }
	var cost := recipe_cost(recipe_id)
	if not can_afford(slice_id, cost):
		return { "ok": false, "reason": "Not enough calc." }
	_push_snapshot(s)
	_spend(s, cost)
	s["activeRun"] = { "recipeId": recipe_id, "startedMsec": Time.get_ticks_msec(), "calcSpent": cost }
	EventBus.state_changed.emit()
	return { "ok": true }


# extra is merged into the ledger entry (a procedure run's per-step results).
static func finish_run(slice_id: String, score: int, extra: Dictionary = {}) -> Dictionary:
	var s := slice(slice_id)
	var run = s["activeRun"]
	if run == null:
		return { "ok": false, "reason": "No run open." }
	score = clampi(score, 0, 100)
	var recipe_id: String = run["recipeId"]
	var rank := rank_for_score(score)
	var prior_best: int = int(s["bestRanks"].get(recipe_id, 0))

	var items := 1
	var xp_multiplier := 1.0
	var bonus = null
	var bonus_def: Dictionary = _data().get("bonus", {})
	if rank >= prior_best and Rng.chance(float(bonus_def.get("chance", 0.0))):
		bonus = _root()["bonusType"]
		var type_def: Dictionary = bonus_def.get("types", {}).get(bonus, {})
		items += int(type_def.get("extraItems", 0))
		xp_multiplier = float(type_def.get("xpMultiplier", 1.0))
		if type_def.has("refundFraction"):
			_refund(s, run["calcSpent"], float(type_def["refundFraction"]))

	var flavour = null
	var bad_run: Dictionary = _data().get("badRun", {})
	var lines: Array = bad_run.get("lines", [])
	if score < int(bad_run.get("scoreBelow", 0)) and not lines.is_empty() \
			and Rng.randi_range(1, int(bad_run.get("oneIn", 1))) == 1:
		flavour = Rng.rand_from(lines)

	s["bestRanks"][recipe_id] = maxi(prior_best, rank)
	var xp: int = roundi(int(_data().get("baseXp", 0)) * xp_multiplier)
	var entry := {
		"kind": "run", "recipeId": recipe_id, "items": items, "rank": rank,
		"score": score, "durationMsec": maxi(0, Time.get_ticks_msec() - int(run["startedMsec"])),
		"bonus": bonus, "xp": xp, "flavour": flavour,
	}
	entry.merge(extra)
	_log(s, entry)
	s["activeRun"] = null
	EventBus.state_changed.emit()
	return { "ok": true, "entry": entry }


# Ends an open run without an item; the calc spent so far stays spent.
static func abandon_run(slice_id: String) -> Dictionary:
	var s := slice(slice_id)
	if s["activeRun"] == null:
		return { "ok": false, "reason": "No run open." }
	return { "ok": true, "entry": _close_run(s, "abandoned") }


static func _close_run(s: Dictionary, kind: String) -> Dictionary:
	var run: Dictionary = s["activeRun"]
	var entry := {
		"kind": kind, "recipeId": run["recipeId"], "items": 0, "rank": 0,
		"score": 0, "durationMsec": maxi(0, Time.get_ticks_msec() - int(run["startedMsec"])),
		"bonus": null, "xp": 0, "flavour": null,
	}
	_log(s, entry)
	s["activeRun"] = null
	EventBus.state_changed.emit()
	return entry


# ── Procedure (Slice A) ──────────────────────────────────────────────────

static func procedure_def(recipe_id: String) -> Dictionary:
	return _data()["recipes"][recipe_id]["procedure"]


# The steps the player knows (spec §Slice A Knowledge display): the base
# procedure, where each granted hint either corrects the target of the base
# step matching its ideal step or inserts that ideal step (no calc) in ideal
# order. An unknown ideal step is simply absent. Each step carries
# knowledge "base", "vague" or "exact"; a hinted one also its hintId and
# note. Targets are floats so a saved run round-trips unchanged.
static func known_procedure(recipe_id: String) -> Array:
	var procedure := procedure_def(recipe_id)
	var ideal: Array = procedure["ideal"]
	var base: Array = procedure["base"]
	var granted := {}
	for hint in procedure.get("hints", []):
		var level := hint_level(SLICE_PROCEDURE, recipe_id, hint["id"])
		if level != "off":
			granted[int(hint["step"])] = { "hint": hint, "level": level }
	var steps := []
	var next_ideal := 0
	var base_matches := match_ideal(ideal, base)
	for i in base.size():
		var m: int = base_matches[i]
		if m >= 0:
			_insert_hinted(steps, ideal, granted, next_ideal, m)
			next_ideal = m + 1
		var step: Dictionary = base[i].duplicate(true)
		step["target"] = float(step["target"])
		step["knowledge"] = "base"
		if granted.has(m):
			_apply_hint(step, ideal[m], granted[m])
		steps.append(step)
	_insert_hinted(steps, ideal, granted, next_ideal, ideal.size())
	return steps


static func _insert_hinted(steps: Array, ideal: Array, granted: Dictionary, from: int, to: int) -> void:
	for i in range(from, to):
		if granted.has(i):
			var step := { "apparatus": ideal[i]["apparatus"] }
			_apply_hint(step, ideal[i], granted[i])
			steps.append(step)


static func _apply_hint(step: Dictionary, ideal_step: Dictionary, grant: Dictionary) -> void:
	step["target"] = float(ideal_step["target"])
	step["knowledge"] = grant["level"]
	step["hintId"] = grant["hint"]["id"]
	step["note"] = grant["hint"][grant["level"]]["note"]


# band_half_width = base_tol × (1 + skillFactor × craftingSkill).
static func band_half_width(recipe_id: String) -> float:
	return float(procedure_def(recipe_id)["baseTolerance"]) * skill_multiplier()


# What the gauge shows for a known step, clamped to the 0-100 gauge: the
# band around its target, or for a vague step a fuzzy region vagueSpread
# wider each side and shifted by the hint's offset (|offset| <= vagueSpread,
# so the true band always sits inside it).
static func step_region(recipe_id: String, step: Dictionary) -> Dictionary:
	var half := band_half_width(recipe_id)
	var low := float(step["target"]) - half
	var high := float(step["target"]) + half
	var vague: bool = step.get("knowledge", "base") == "vague"
	if vague:
		var spread := float(_data().get("vagueSpread", 0))
		var offset := float(hint_def(SLICE_PROCEDURE, recipe_id, step["hintId"])["vague"]["offset"])
		low += offset - spread
		high += offset + spread
	return { "low": maxf(0.0, low), "high": minf(100.0, high), "vague": vague }


# 1.0 inside the band, falling linearly to 0 at 2× the band.
static func step_accuracy(value: float, target: float, half_width: float) -> float:
	var off := absf(value - target)
	if off <= half_width:
		return 1.0
	return clampf(2.0 - off / half_width, 0.0, 1.0)


# Pairs each performed step with an ideal step: in order, same apparatus,
# each ideal step used at most once. -1 marks an extra step.
static func match_ideal(ideal: Array, performed: Array) -> Array[int]:
	var matches: Array[int] = []
	var next := 0
	for step in performed:
		var found := -1
		for i in range(next, ideal.size()):
			if ideal[i]["apparatus"] == step["apparatus"]:
				found = i
				break
		matches.append(found)
		if found >= 0:
			next = found + 1
	return matches


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
static func score_procedure(recipe_id: String, performed: Array) -> Dictionary:
	var ideal: Array = procedure_def(recipe_id)["ideal"]
	var half := band_half_width(recipe_id)
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


static func procedure_cost(steps: Array) -> Dictionary:
	var cost := {}
	for step in steps:
		var calc: Dictionary = step.get("calc", {})
		for ore_type in calc.keys():
			cost[ore_type] = int(cost.get(ore_type, 0)) + int(calc[ore_type])
	return cost


# Opens a procedure run. The whole procedure must be affordable up front,
# but calc is only spent as each step is performed.
static func begin_procedure_run(recipe_id: String) -> Dictionary:
	var s := slice(SLICE_PROCEDURE)
	if s["activeRun"] != null:
		return { "ok": false, "reason": "A run is already open." }
	if not _data()["recipes"].has(recipe_id):
		return { "ok": false, "reason": "Unknown recipe." }
	var steps := known_procedure(recipe_id)
	if not can_afford(SLICE_PROCEDURE, procedure_cost(steps)):
		return { "ok": false, "reason": "Not enough calc." }
	_push_snapshot(s)
	s["activeRun"] = {
		"recipeId": recipe_id, "startedMsec": Time.get_ticks_msec(), "calcSpent": {},
		"procedure": steps, "performed": [],
	}
	return _advance(s)


# The open procedure run's next step, or null when none is open.
static func current_step() -> Variant:
	var run = slice(SLICE_PROCEDURE)["activeRun"]
	if run == null or not run.has("procedure"):
		return null
	var index: int = run["performed"].size()
	return run["procedure"][index] if index < run["procedure"].size() else null


static func gauge(apparatus: String) -> Dictionary:
	return _data()["gauges"][apparatus]


# Heat or compress: commits the raw needle value at release. A compress at
# or past crackAt cracks the vessel: the step's calc is spent and the run
# ends with no item.
static func perform_step(value: float) -> Dictionary:
	var step = current_step()
	if step == null or not HOLD_APPARATUS.has(step["apparatus"]):
		return { "ok": false, "reason": "No hold step to perform." }
	var s := slice(SLICE_PROCEDURE)
	value = clampf(value, 0.0, 100.0)
	_perform(s, { "value": value })
	if step["apparatus"] == "compression" and value >= float(gauge("compression")["crackAt"]):
		return { "ok": true, "done": true, "cracked": true, "entry": _close_run(s, "cracked") }
	return _advance(s)


# Grind: commits the pestle meter reading at each stroke. Strokes past the
# gauge's count are ignored; strokes short of it read as misses.
static func perform_grind(readings: Array) -> Dictionary:
	var step = current_step()
	if step == null or step["apparatus"] != "grinding":
		return { "ok": false, "reason": "No grind step to perform." }
	var clamped := []
	for i in int(gauge("grinding")["strokes"]):
		clamped.append(clampf(float(readings[i]), 0.0, 100.0) if i < readings.size() else null)
	var s := slice(SLICE_PROCEDURE)
	_perform(s, { "readings": clamped })
	return _advance(s)


# Distil: commits the tap times (msec since the first drip started).
static func perform_distil(tap_msecs: Array) -> Dictionary:
	var step = current_step()
	if step == null or step["apparatus"] != "distilling":
		return { "ok": false, "reason": "No distil step to perform." }
	var s := slice(SLICE_PROCEDURE)
	_perform(s, distil_readings(tap_msecs))
	return _advance(s)


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


static func _perform(s: Dictionary, record: Dictionary) -> void:
	var run: Dictionary = s["activeRun"]
	var step: Dictionary = run["procedure"][run["performed"].size()]
	var calc: Dictionary = step.get("calc", {})
	_spend(s, calc)
	for ore_type in calc.keys():
		run["calcSpent"][ore_type] = int(run["calcSpent"].get(ore_type, 0)) + int(calc[ore_type])
	record["apparatus"] = step["apparatus"]
	run["performed"].append(record)


# Scores the run once every step is performed.
static func _advance(s: Dictionary) -> Dictionary:
	if current_step() != null:
		EventBus.state_changed.emit()
		return { "ok": true, "done": false }
	var run: Dictionary = s["activeRun"]
	var scored := score_procedure(run["recipeId"], run["performed"])
	var steps := []
	for i in run["performed"].size():
		var performed: Dictionary = run["performed"][i].duplicate(true)
		performed["accuracy"] = scored["accuracies"][i]
		steps.append(performed)
	var result := finish_run(SLICE_PROCEDURE, scored["score"], { "steps": steps })
	result["done"] = true
	return result


# ── Batch ────────────────────────────────────────────────────────────────

# Auto-craft at best rank: base calc per item, XP at ×1.0, no bonus roll.
static func batch(slice_id: String, recipe_id: String, count: int) -> Dictionary:
	var s := slice(slice_id)
	if s["activeRun"] != null:
		return { "ok": false, "reason": "Finish the open run first." }
	if count < 1 or not _data()["recipes"].has(recipe_id):
		return { "ok": false, "reason": "Nothing to craft." }
	var best: int = int(s["bestRanks"].get(recipe_id, 0))
	if best < 1:
		return { "ok": false, "reason": "No rank yet." }
	var cost := recipe_cost(recipe_id, count)
	if not can_afford(slice_id, cost):
		return { "ok": false, "reason": "Not enough calc." }
	_push_snapshot(s)
	_spend(s, cost)
	var entry := {
		"kind": "batch", "recipeId": recipe_id, "items": count, "rank": best,
		"score": null, "durationMsec": 0, "bonus": null,
		"xp": int(_data().get("baseXp", 0)) * count, "flavour": null,
	}
	_log(s, entry)
	EventBus.state_changed.emit()
	return { "ok": true, "entry": entry }


static func _log(s: Dictionary, entry: Dictionary) -> void:
	s["ledger"].append(entry)
	s["xpTotal"] = int(s["xpTotal"]) + int(entry["xp"])


# ── Rewind ───────────────────────────────────────────────────────────────

static func _push_snapshot(s: Dictionary) -> void:
	var frame := {}
	for key in s.keys():
		if key != "snapshots":
			frame[key] = s[key]
	Snapshots.push("benchPrototype", s["snapshots"], frame)


# Steps the slice back to before its most recent run or batch.
static func rewind(slice_id: String) -> Dictionary:
	var s := slice(slice_id)
	var frame = Snapshots.pop_newest(s["snapshots"])
	if frame == null:
		return { "ok": false, "reason": "Nothing to rewind." }
	for key in frame.keys():
		s[key] = frame[key]
	EventBus.state_changed.emit()
	return { "ok": true }
