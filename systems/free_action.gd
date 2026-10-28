class_name FreeAction
extends RefCounted

# Mind/Soul free-action perks (R§3.7a): spend() either advances the time block
# or saves it, and says why. The L3 roll is a stable hash, not the global Rng stream. Rule data lives in GameData.FREE_ACTION.

const BUCKETS := { "mind": "mindSkill", "soul": "soulSkill" }


# district_id enables the Guild internship freebie ("" = none applies).
static func spend(bucket: String, district_id: String = "") -> Dictionary:
	var fa: Dictionary = GameData.FREE_ACTION
	if TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "No time blocks left today." }

	var level: int = int(GameState.state["player"][BUCKETS[bucket]])
	var result := { "ok": true, "free": false, "bucket": bucket, "level": level, "rule": "" }

	if district_id != "" and Perks.take_free_cultivate(district_id):
		return _free(result, "internship", fa, 0)

	var used := _used_flags()
	var used_key := bucket + "Used"
	var guaranteed_level: int = fa["guaranteedLevel"]
	if level >= guaranteed_level and not used[used_key]:
		used[used_key] = true
		return _free(result, "guaranteed", fa, guaranteed_level)

	var roll_level: int = fa["rollLevel"]
	if level >= roll_level and _roll(bucket, used) < float(fa["chance"]):
		return _free(result, "roll", fa, roll_level)

	TimeSystem.advance_time_block()
	return result


# Stable per (rollSeed, day, block, bucket, rolls so far this block), so a
# Rewound block replays the same roll.
static func _roll(bucket: String, used: Dictionary) -> float:
	var rolls_key := bucket + "Rolls"
	var n: int = int(used[rolls_key])
	used[rolls_key] = n + 1
	var key := "%d|freeAction|%d|%d|%s|%d" % [int(GameState.state["world"]["rollSeed"]), used["day"], used["block"], bucket, n]
	return Rng.stable_unit(key)


static func _free(result: Dictionary, rule: String, fa: Dictionary, perk_level: int) -> Dictionary:
	result["free"] = true
	result["rule"] = rule
	result["line"] = String(fa["lines"][rule]).format({
		"bucket": String(result["bucket"]).capitalize(),
		"level": perk_level,
		"pct": roundi(float(fa["chance"]) * 100.0),
	})
	return result


# The freebie flags for the current (day, block), reset when either changes.
static func _used_flags() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var world: Dictionary = GameState.state["world"]
	var used: Dictionary = player["freeAction"]
	if int(used["day"]) != int(world["day"]) or int(used["block"]) != int(world["timeBlock"]):
		used["day"] = int(world["day"])
		used["block"] = int(world["timeBlock"])
		used["mindUsed"] = false
		used["soulUsed"] = false
		used["mindRolls"] = 0
		used["soulRolls"] = 0
	return used
