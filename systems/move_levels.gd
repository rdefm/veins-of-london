class_name MoveLevels
extends RefCounted

# Per-move levels 1..levelMax beside Combat Skill (R§3.7b Move levels): the
# player's and each contact's persistent { level, xp } per move (owner ""
# is the player, else a contact id), the XP ladder they climb, and the fixed
# levels a fighter with none rolls for a fight. Numbers in
# data/combat_rounds.json moveXp / moveLevelRoll.


static func _data() -> Dictionary:
	return GameData.COMBAT_ROUNDS


static func move_ids() -> Array:
	return _data()["moves"].keys()


# A fresh { moveId: { level: 1, xp: 0 } } record.
static func new_state() -> Dictionary:
	var record := {}
	for move_id in move_ids():
		record[move_id] = { "level": 1, "xp": 0 }
	return record


# The owner's persistent record; {} for an unknown contact.
static func record(owner: String) -> Dictionary:
	var holder: Dictionary = GameState.state["player"] if owner == "" else GameState.state["contacts"].get(owner, {})
	return holder.get("moveLevels", {})


# xp_levels()[n] is the cumulative XP that reaches level n.
static func xp_levels() -> Array:
	return _data()["moveXp"]["levels"]


static func level_for_xp(xp: int) -> int:
	var levels := xp_levels()
	var level := 1
	while level < CombatRounds.level_max() and xp >= int(levels[level + 1]):
		level += 1
	return level


# The owner's level per move, { moveId: level }.
static func levels_of(owner: String) -> Dictionary:
	var rec := record(owner)
	var levels := {}
	for move_id in move_ids():
		levels[move_id] = int(rec.get(move_id, {}).get("level", 1))
	return levels


# XP for one use of a move: moveXp.fizzled when it fizzled, else resolved.
static func xp_for_use(fizzled: bool) -> int:
	return int(_data()["moveXp"]["fizzled" if fizzled else "resolved"])


# Adds `amount` XP to the owner's `move_id`; returns its new level when that
# took it up one, else 0.
static func award(owner: String, move_id: String, amount: int) -> int:
	var rec := record(owner)
	if not rec.has(move_id):
		return 0
	var entry: Dictionary = rec[move_id]
	entry["xp"] = int(entry["xp"]) + amount
	var level := level_for_xp(int(entry["xp"]))
	if level <= int(entry["level"]):
		return 0
	entry["level"] = level
	return level


# Fixed levels for a fighter at Combat Skill `level` with no record: per
# move, `level` less a moveLevelRoll row's `below`, picked by weight, min 1.
static func roll(level: int, rng: RandomNumberGenerator) -> Dictionary:
	var rows: Array = _data()["moveLevelRoll"]
	var total := 0
	for row in rows:
		total += int(row["weight"])
	var levels := {}
	for move_id in move_ids():
		var pick := rng.randi_range(1, total)
		for row in rows:
			pick -= int(row["weight"])
			if pick <= 0:
				levels[move_id] = maxi(1, level - int(row["below"]))
				break
	return levels


# Each move's display row for the owner: { name, level, xp, xpFloor, xpNext,
# isMax }.
static func summary(owner: String) -> Array:
	var rec := record(owner)
	var levels := xp_levels()
	var rows: Array = []
	for move_id in move_ids():
		var entry: Dictionary = rec.get(move_id, { "level": 1, "xp": 0 })
		var level := int(entry["level"])
		var is_max := level >= CombatRounds.level_max()
		rows.append({
			"id": move_id, "name": str(_data()["moves"][move_id]["name"]),
			"level": level, "xp": int(entry["xp"]), "isMax": is_max,
			"xpFloor": int(levels[level]), "xpNext": int(levels[level]) if is_max else int(levels[level + 1]),
		})
	return rows
