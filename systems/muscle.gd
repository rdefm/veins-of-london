class_name Muscle
extends RefCounted

# Hired guards (spec .scratch/muscle/spec.md): individual guard records under
# state.muscle, each with a generated name, level, XP, one or two traits, a
# post and injury/training countdowns. Static funcs only; every number comes
# from GameData.MUSCLE / MUSCLE_TRAITS / MUSCLE_* name pools.

const POST_RESERVE := "reserve"
const POST_HOME := "home"


# state.muscle: pure data. board.cards holds guard-shaped records or null
# (hired slot); former is the FIFO of dismissed/walked guards.
static func new_state() -> Dictionary:
	return { "nextId": 1, "guards": [], "board": { "day": 0, "cards": [] }, "former": [], "responders": {} }


static func guards() -> Array:
	return GameState.state["muscle"]["guards"]


static func guard(id: String) -> Dictionary:
	for g in guards():
		if g["id"] == id:
			return g
	return {}


static func former() -> Array:
	return GameState.state["muscle"]["former"]


# ── level table ───────────────────────────────────────────────────────

static func level_row(level: int) -> Dictionary:
	var rows: Array = GameData.MUSCLE["levels"]
	return rows[clampi(level, 1, rows.size()) - 1]


static func level_weight(level: int) -> float:
	return float(level_row(level)["weight"])


static func level_wage(level: int) -> int:
	return int(level_row(level)["wage"])


# ── guard creation ────────────────────────────────────────────────────

# A new guard record, not yet stored anywhere: unique name, 1-2 traits.
# `level` is clamped to the level table. Draws ids from state.muscle.nextId.
static func create_guard(level: int = 1) -> Dictionary:
	var muscle: Dictionary = GameState.state["muscle"]
	var id := "g%d" % int(muscle["nextId"])
	muscle["nextId"] = int(muscle["nextId"]) + 1
	var name_parts := generate_name()
	return {
		"id": id,
		"name": name_parts["name"],
		"nickname": name_parts["nickname"],
		"level": clampi(level, 1, GameData.MUSCLE["levels"].size()),
		"xp": int(level_row(level)["xpToReach"]),
		"traits": roll_traits(),
		"post": POST_RESERVE,
		"injuredUntilDay": 0,
		"trainingUntilDay": 0,
	}


# { name: "Dee Okafor", nickname: "Spanner" | "" }. The name is unique across
# current guards, former guards and the board's open cards.
static func generate_name() -> Dictionary:
	var used := _used_names()
	var first_pool: Array = GameData.MUSCLE_FIRST_NAMES
	var surname_pool: Array = GameData.MUSCLE_SURNAMES
	var full := ""
	var attempts := 0
	var cap: int = first_pool.size() * surname_pool.size()
	while attempts <= cap:
		var candidate := "%s %s" % [Rng.rand_from(first_pool), Rng.rand_from(surname_pool)]
		if not used.has(candidate):
			full = candidate
			break
		attempts += 1
	assert(full != "", "name pool exhausted")
	var nickname := ""
	if Rng.chance(float(GameData.MUSCLE["nicknameChance"])):
		nickname = Rng.rand_from(GameData.MUSCLE_NICKNAMES)
	return { "name": full, "nickname": nickname }


static func _used_names() -> Dictionary:
	var used := {}
	var muscle: Dictionary = GameState.state["muscle"]
	for list in [muscle["guards"], muscle["former"], muscle["board"]["cards"]]:
		for g in list:
			if g != null:
				used[g["name"]] = true
	return used


# One trait, 25% a second distinct one that isn't blocked against the first.
static func roll_traits() -> Array:
	var ids: Array = GameData.MUSCLE_TRAITS.keys()
	var picked: Array = [Rng.rand_from(ids)]
	if Rng.chance(float(GameData.MUSCLE["secondTraitChance"])):
		var options: Array = ids.filter(func(t): return t != picked[0] and not traits_blocked(picked[0], t))
		if not options.is_empty():
			picked.append(Rng.rand_from(options))
	return picked


static func traits_blocked(a: String, b: String) -> bool:
	for pair in GameData.MUSCLE_BLOCKED_PAIRS:
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return true
	return false


# ── trait maths ───────────────────────────────────────────────────────

# Product of a numeric trait param across a guard's traits (1.0 when none set it).
static func trait_mult(g: Dictionary, param: String) -> float:
	var product := 1.0
	for t in g["traits"]:
		product *= float(GameData.MUSCLE_TRAITS[t]["params"].get(param, 1.0))
	return product


# Sum of a numeric trait param across a guard's traits (0.0 when none set it).
static func trait_sum(g: Dictionary, param: String) -> float:
	var total := 0.0
	for t in g["traits"]:
		total += float(GameData.MUSCLE_TRAITS[t]["params"].get(param, 0.0))
	return total


# ── weights and wage ──────────────────────────────────────────────────

static func weight(g: Dictionary) -> float:
	return level_weight(int(g["level"]))


# Level weight plus the guard's repel-only trait modifiers.
static func repel_weight(g: Dictionary) -> float:
	return weight(g) + trait_sum(g, "repelWeightMod")


# Weekly wage: level wage x every trait's wage multiplier, rounded to £.
static func wage(g: Dictionary) -> int:
	return int(round(level_wage(int(g["level"])) * trait_mult(g, "wageMult")))


# ── names ─────────────────────────────────────────────────────────────

# "Dee O." -- first name and surname initial.
static func short_name(g: Dictionary) -> String:
	var parts: PackedStringArray = String(g["name"]).split(" ")
	return "%s %s." % [parts[0], parts[parts.size() - 1].left(1)]


# "Dee O." or, with a nickname, "Dee \"Spanner\" O.".
static func full_name(g: Dictionary) -> String:
	var parts: PackedStringArray = String(g["name"]).split(" ")
	var initial := parts[parts.size() - 1].left(1)
	if String(g["nickname"]).is_empty():
		return "%s %s." % [parts[0], initial]
	return "%s \"%s\" %s." % [parts[0], g["nickname"], initial]
