class_name MoveLevels
extends RefCounted

# Per-move levels 1..levelMax beside Combat Skill (R§3.7b Move levels): the
# player's and each contact's persistent { level, xp } per move (owner ""
# is the player, else a contact id), the XP ladder they climb, and the fixed
# levels a fighter with none rolls for a fight. Numbers in
# data/combat_rounds.json moveXp / moveLevelRoll.


static func _data() -> Dictionary:
	return GameData.COMBAT_ROUNDS


# The levelled moves (moveXp.moves).
static func move_ids() -> Array:
	return _data()["moveXp"]["moves"]


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


# The Move Book's rows for the owner (Profile): per move { id, name, level, xp,
# isMax, badge, teaser, stat, stops, railFill, wordRow, unlocks, xpLine }.
# stops[i] = { level, milestone, text, reached, current, next } (text: the
# move's per-level stat); wordRow is {} or { stat, words }; unlocks[i] =
# { level, state: earned|next|locked, tag, what, how }. Strings from
# data/combat_rounds.json moveBook, numbers from moveLevelEffects / moveXp.
static func book(owner: String) -> Array:
	var rec := record(owner)
	var xp_ladder := xp_levels()
	var level_max := CombatRounds.level_max()
	var text: Dictionary = _data()["moveBook"]
	var rows: Array = []
	for move_id in move_ids():
		var entry: Dictionary = rec.get(move_id, { "level": 1, "xp": 0 })
		var level := int(entry["level"])
		var xp := int(entry["xp"])
		var is_max := level >= level_max
		var fx: Dictionary = _data()["moveLevelEffects"][move_id]
		var spec: Dictionary = text["moves"][move_id]
		var unlocks: Array = []
		for u in spec["unlocks"]:
			var unlock_level := int(u["level"]) if u.has("level") else int(fx[u["levelKey"]])
			unlocks.append({ "level": unlock_level, "what": _fill(str(u["what"]), move_id), "how": _fill(str(u["how"]), move_id) })
		var next_level := 0
		for u in unlocks:
			if next_level == 0 and int(u["level"]) > level:
				next_level = int(u["level"])
			var state := "earned" if int(u["level"]) <= level else ("next" if int(u["level"]) == next_level else "locked")
			u["state"] = state
			u["tag"] = _fill(str(text["tag" + state.capitalize()]), move_id, { "level": u["level"], "xp": maxi(0, int(xp_ladder[int(u["level"])]) - xp) })
		var teaser: String = str(text["teaserDone"])
		for u in unlocks:
			if u["state"] == "next":
				teaser = _fill(str(text["teaser"]), move_id, { "level": u["level"], "unlock": u["what"], "xp": maxi(0, int(xp_ladder[int(u["level"])]) - xp) })
		var track: Dictionary = spec["track"]
		var milestones: Array = unlocks.map(func(u): return int(u["level"]))
		var stops: Array = []
		for n in range(1, level_max + 1):
			var value: float = float(fx[track["key"]][n]) * float(track["scale"])
			stops.append({
				"level": n, "milestone": n in milestones,
				"text": str(track["zero"]) if value <= 0.0 and track.has("zero") else str(track["format"]).replace("{v}", str(roundi(value))),
				"reached": n <= level, "current": n == level, "next": n == level + 1,
			})
		var rail := 1.0
		if not is_max:
			rail = (float(level - 1) + float(xp - int(xp_ladder[level])) / float(int(xp_ladder[level + 1]) - int(xp_ladder[level]))) / float(level_max - 1)
		var xp_line := ""
		if is_max:
			xp_line = _fill(str(text["xpLineMax"]), move_id, { "xp": xp })
		else:
			xp_line = _fill(str(text["xpLine"]), move_id, { "xp": xp, "next": xp_ladder[level + 1], "level": level + 1, "resolved": _data()["moveXp"]["resolved"], "fizzled": _data()["moveXp"]["fizzled"] })
		rows.append({
			"id": move_id, "name": str(_data()["moves"][move_id]["name"]), "level": level, "xp": xp, "isMax": is_max,
			"badge": str(text["badgeMax"]) if is_max else _fill(str(text["badge"]), move_id, { "level": level }),
			"teaser": teaser, "stat": str(spec["stat"]), "stops": stops, "railFill": rail,
			"wordRow": spec.get("wordRow", {}), "unlocks": unlocks, "xpLine": xp_line,
		})
	return rows


# The fight's long-press peek for the player's `move_id`: { title, effects,
# next } from book(""); effects are the current stat value then each earned
# unlock, next is the following level's gain and XP (or the done line).
static func peek(move_id: String) -> Dictionary:
	var text: Dictionary = _data()["moveBook"]["peek"]
	for row in book(""):
		if row["id"] != move_id:
			continue
		var level := int(row["level"])
		var effects: Array = [str(row["stops"][level - 1]["text"]) + " " + str(row["stat"]).to_lower()]
		for u in row["unlocks"]:
			if u["state"] == "earned":
				effects.append(u["what"])
		var next := str(text["nextDone"])
		if not row["isMax"]:
			var gain: Array = [str(row["stops"][level]["text"]) + " " + str(row["stat"]).to_lower()]
			for u in row["unlocks"]:
				if int(u["level"]) == level + 1:
					gain.append(u["what"])
			var xp_ladder := xp_levels()
			next = _fill(str(text["next"]), move_id, { "level": level + 1, "gain": " · ".join(gain), "xp": maxi(0, int(xp_ladder[level + 1]) - int(row["xp"])) })
		return { "title": _fill(str(text["title"]), move_id, { "name": row["name"], "level": level }), "effects": effects, "next": next }
	return {}


# The Notification for `owner`'s `move_id` reaching `level`: { text, detail }.
# detail is the unlock when one lands at that level, else the stat change
# (plus the move's noticeExtra line, if any). Strings from moveBook.notice.
static func level_up_notice(owner: String, move_id: String, level: int) -> Dictionary:
	var text: Dictionary = _data()["moveBook"]["notice"]
	var spec: Dictionary = _data()["moveBook"]["moves"][move_id]
	var move_name := str(_data()["moves"][move_id]["name"])
	var title := _fill(str(text["reached"]), move_id, { "move": move_name, "level": level })
	if owner != "":
		title = _fill(str(text["reachedOwner"]), move_id, { "owner": Contacts.display_name(owner), "move": move_name, "level": level })
	for row in book(owner):
		if row["id"] != move_id:
			continue
		var detail := ""
		for u in row["unlocks"]:
			if int(u["level"]) == level:
				detail = _fill(str(text["unlocked"]), move_id, { "what": u["what"] })
		if detail == "":
			detail = _fill(str(text["change"]), move_id, { "stat": spec["noticeStat"], "from": row["stops"][level - 2]["text"], "to": row["stops"][level - 1]["text"] })
			var extra: String = str(spec.get("noticeExtra", {}).get(str(level), ""))
			if extra != "":
				detail += " " + extra + "."
		return { "text": title, "detail": detail }
	return { "text": title, "detail": "" }


# `text` with {token} / {token%} filled from the move's moveLevelEffects
# numbers (% scales x100), the base chip / Stun actions, then `extra`.
static func _fill(text: String, move_id: String, extra: Dictionary = {}) -> String:
	var fx: Dictionary = _data()["moveLevelEffects"][move_id]
	for key in fx:
		if fx[key] is Array:
			continue
		text = text.replace("{%s%%}" % key, str(roundi(float(fx[key]) * 100.0))).replace("{%s}" % key, str(roundi(float(fx[key]))))
	text = text.replace("{baseChip%}", str(roundi(float(_data()["chipMultiplier"]) * 100.0)))
	text = text.replace("{baseActions}", str(int(_data()["moves"]["stun"]["params"]["actions"])))
	for key in extra:
		text = text.replace("{%s}" % key, str(extra[key]))
	return text


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
