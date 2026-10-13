class_name Harassment
extends RefCounted

# Faction harassment (R§ Harassment): the escalation rung between warning and
# market lines queues an authored event against one of the player's veins in
# the faction's turf; effects an event leaves behind persist in
# state.harassment.active and worsen while ignored. Data in
# data/faction_harassment.json; the rung itself lives in FactionAI.
# state.harassment = { active: [ { id, factionId, veinId?, kind, params,
# sinceDay, untilDay?, escalation } ], queued: [ { harassmentId, factionId,
# eventId, veinId } ], nextId: int }.


static func _cfg() -> Dictionary:
	return GameData.FACTION_HARASSMENT


static func new_state() -> Dictionary:
	return { "active": [], "queued": [], "nextId": 1 }


static func entry(harassment_id: String) -> Dictionary:
	return _cfg()["entries"].get(harassment_id, {})


static func active() -> Array:
	return GameState.state["harassment"]["active"]


static func queued() -> Array:
	return GameState.state["harassment"]["queued"]


# The player's veins in districts where faction_id controls or has a foothold,
# not already carrying an active effect from it.
static func eligible_veins(faction_id: String) -> Array:
	var result := []
	for vein in GameState.state["player"].get("veins", []):
		if Turf.tier(vein["district"], faction_id) == Turf.TIER_NONE:
			continue
		if not _harassed_by(vein["id"], faction_id):
			result.append(vein)
	return result


static func _harassed_by(vein_id: String, faction_id: String) -> bool:
	for row in active():
		if row.get("veinId", "") == vein_id and row["factionId"] == faction_id:
			return true
	for row in queued():
		if row["veinId"] == vein_id and row["factionId"] == faction_id:
			return true
	return false


# { move, damage, cost, harassmentId, eventId, veinId } for one harassment
# entry against the player, or {} when it can't land (no eligible vein, unmet
# requires, wrong faction).
static func candidate(observer: String, harassment_id: String) -> Dictionary:
	var row := entry(harassment_id)
	if row.is_empty() or row["factionId"] != observer:
		return {}
	var requires: Dictionary = row["requires"]
	if not requires.is_empty() and not Events.condition_met(requires):
		return {}
	var vein_id := ""
	if row["target"] == "vein":
		var veins := eligible_veins(observer)
		if veins.is_empty():
			return {}
		vein_id = veins[0]["id"]
	return {
		"move": FactionAI.MOVE_HARASS, "harassmentId": harassment_id, "eventId": row["eventId"],
		"veinId": vein_id, "cost": int(row["cost"]), "damage": float(row["cost"]),
	}


static func queue(move: Dictionary, faction_id: String) -> void:
	queued().append({
		"harassmentId": move["harassmentId"], "factionId": faction_id,
		"eventId": move["eventId"], "veinId": move["veinId"],
	})


# Starts the oldest queued harassment event; false when none is waiting.
static func start_next() -> bool:
	if queued().is_empty():
		return false
	var next: Dictionary = queued().pop_front()
	Events.start_or_defer(next["eventId"], {
		"faction_id": next["factionId"], "vein_id": next["veinId"], "harassment_id": next["harassmentId"],
	})
	return true


# Records an effect an event left behind. params.days (optional) sets untilDay.
static func add(faction_id: String, kind: String, vein_id: String, params: Dictionary) -> Dictionary:
	var state: Dictionary = GameState.state["harassment"]
	var day: int = GameState.state["world"]["day"]
	var row := {
		"id": "h%d" % int(state["nextId"]), "factionId": faction_id, "kind": kind,
		"params": params, "sinceDay": day, "escalation": 0,
	}
	state["nextId"] = int(state["nextId"]) + 1
	if vein_id != "":
		row["veinId"] = vein_id
	if params.has("days"):
		row["untilDay"] = day + int(params["days"])
	state["active"].append(row)
	EventBus.state_changed.emit()
	return row


static func clear(effect_id: String) -> void:
	GameState.state["harassment"]["active"] = active().filter(func(r: Dictionary) -> bool: return r["id"] != effect_id)
	EventBus.state_changed.emit()


static func clear_where(faction_id: String, kind: String, vein_id: String) -> void:
	GameState.state["harassment"]["active"] = active().filter(func(r: Dictionary) -> bool:
		return not (r["factionId"] == faction_id and (kind == "" or r["kind"] == kind) and (vein_id == "" or r.get("veinId", "") == vein_id)))
	EventBus.state_changed.emit()


# harassment_add event op: context supplies faction_id and vein_id.
static func add_from_event(effect: Dictionary) -> void:
	var context: Dictionary = (GameState.state.get("event") as Dictionary).get("context", {}) if GameState.state.get("event") != null else {}
	add(str(effect.get("faction", context.get("faction_id", ""))), effect["kind"], str(effect.get("vein", context.get("vein_id", ""))), effect.get("params", {}))


# harassment_clear event op: clears this faction's effects of a kind on the context vein.
static func clear_from_event(effect: Dictionary) -> void:
	var context: Dictionary = (GameState.state.get("event") as Dictionary).get("context", {}) if GameState.state.get("event") != null else {}
	clear_where(str(effect.get("faction", context.get("faction_id", ""))), str(effect.get("kind", "")), str(effect.get("vein", context.get("vein_id", ""))))


# Daily: expires timed effects and ones whose vein is gone,
# and sets escalation to one step per escalation.everyDays ignored, to max.
static func tick() -> void:
	var day: int = GameState.state["world"]["day"]
	var cadence: Dictionary = _cfg()["escalation"]
	var veins := {}
	for vein in GameState.state["player"].get("veins", []):
		veins[vein["id"]] = true
	var kept := []
	for row in active():
		if row.has("untilDay") and day > int(row["untilDay"]):
			continue
		if row.has("veinId") and not veins.has(row["veinId"]):
			continue
		row["escalation"] = mini(int(cadence["max"]), floori(float(day - int(row["sinceDay"])) / float(cadence["everyDays"])))
		kept.append(row)
	GameState.state["harassment"]["active"] = kept
	GameState.state["harassment"]["queued"] = queued().filter(func(r: Dictionary) -> bool: return veins.has(r["veinId"]) or r["veinId"] == "")


# Active effects touching a district's veins, for the district panel:
# { id, faction, kind, label, escalation, veinId }.
static func rows_for_district(district_id: String) -> Array:
	var in_district := {}
	for vein in GameState.state["player"].get("veins", []):
		if vein["district"] == district_id:
			in_district[vein["id"]] = true
	var rows := []
	for row in active():
		if in_district.has(row.get("veinId", "")):
			rows.append({
				"id": row["id"], "faction": row["factionId"], "kind": row["kind"],
				"label": _cfg()["kindLabels"].get(row["kind"], row["kind"]),
				"escalation": int(row["escalation"]), "veinId": row["veinId"],
			})
	return rows
