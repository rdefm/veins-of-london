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

const SLICE_PROCEDURE := "procedure"
const SLICE_CHART := "chart"
const SLICES: Array[String] = [SLICE_PROCEDURE, SLICE_CHART]

const BATCH_SIZES: Array[int] = [1, 5, 10]


static func _data() -> Dictionary:
	return GameData.BENCH_PROTOTYPE


# ── State ────────────────────────────────────────────────────────────────

static func new_state() -> Dictionary:
	var slices := {}
	for slice_id in SLICES:
		slices[slice_id] = new_slice()
	return {
		"activeSlice": SLICE_PROCEDURE,
		# null = follow the player's real craftingSkill (read only).
		"skillOverride": null,
		"bonusType": _data().get("bonus", {}).get("defaultType", ""),
		"slices": slices,
	}


static func new_slice() -> Dictionary:
	var best_ranks := {}
	var hint_levels := {}
	for recipe_id in _data().get("roster", []):
		best_ranks[recipe_id] = 0
		hint_levels[recipe_id] = "off"
	return {
		"pool": _data().get("poolSeed", {}).duplicate(),
		"bestRanks": best_ranks,
		"hintLevels": hint_levels,
		"ledger": [],
		"xpTotal": 0,
		# null, or { recipeId, startedMsec, calcSpent } while a manual run is open.
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


static func set_hint_level(slice_id: String, recipe_id: String, level: String) -> Dictionary:
	if not _data().get("hintLevels", []).has(level):
		return { "ok": false, "reason": "Unknown hint level." }
	var s := slice(slice_id)
	if not s["hintLevels"].has(recipe_id):
		return { "ok": false, "reason": "Unknown recipe." }
	s["hintLevels"][recipe_id] = level
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


static func finish_run(slice_id: String, score: int) -> Dictionary:
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
	_log(s, entry)
	s["activeRun"] = null
	EventBus.state_changed.emit()
	return { "ok": true, "entry": entry }


# Ends an open run without an item; the calc spent so far stays spent.
static func abandon_run(slice_id: String) -> Dictionary:
	var s := slice(slice_id)
	var run = s["activeRun"]
	if run == null:
		return { "ok": false, "reason": "No run open." }
	_log(s, {
		"kind": "abandoned", "recipeId": run["recipeId"], "items": 0, "rank": 0,
		"score": 0, "durationMsec": maxi(0, Time.get_ticks_msec() - int(run["startedMsec"])),
		"bonus": null, "xp": 0, "flavour": null,
	})
	s["activeRun"] = null
	EventBus.state_changed.emit()
	return { "ok": true }


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
