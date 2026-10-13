class_name Harassment
extends RefCounted

# Faction harassment (R§ Harassment): the escalation rung between warning and
# market lines queues an authored event against one of the player's veins in
# the faction's turf; effects an event leaves behind persist in
# state.harassment.active and worsen while ignored. Data in
# data/faction_harassment.json; the rung itself lives in FactionAI.
# state.harassment = { active: [ { id, factionId, veinId?, kind, params,
# sinceDay, untilDay?, escalation } ], queued: [ { harassmentId, factionId,
# eventId, veinId } ], nextId: int }. Each queued entry also sends a pending
# message from the faction's key member (PENDING_KIND); tapping it plays the event.

const PENDING_KIND := "faction_harassment"
const KIND_SECURITY_DEGRADE := "securityDegrade"
const KIND_WORK_BAN := "workBan"
const KIND_FREEZE := "freeze"
const KIND_SELL_PENALTY := "sellPenalty"
const KIND_SHOP_BAR := "shopBar"


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
	if not KeyMembers.can_speak(observer):
		return {}
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
	KeyMembers.send(faction_id, str(entry(move["harassmentId"])["notice"]), PENDING_KIND, { "veinId": move["veinId"] })


# Starts the oldest queued harassment event; false when none is waiting.
static func start_next() -> bool:
	if queued().is_empty():
		return false
	var next: Dictionary = queued().pop_front()
	Events.start_or_defer(next["eventId"], {
		"faction_id": next["factionId"], "vein_id": next["veinId"], "harassment_id": next["harassmentId"],
	})
	return true


# Pending-message tap: resolves the message and plays the oldest queued event.
static func start_pending(pending_id: String) -> void:
	Messages.resolve_pending(pending_id)
	start_next()


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
	GameState.state["pendingMessages"] = GameState.state["pendingMessages"].filter(func(m: Dictionary) -> bool:
		return m["kind"] != PENDING_KIND or veins.has(m["payload"].get("veinId", "")))


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


# ── physical and legal effects ───────────────────────────────────────────

static func _rows(vein_id: String, kind: String) -> Array:
	return active().filter(func(r: Dictionary) -> bool: return r.get("veinId", "") == vein_id and r["kind"] == kind)


# Security tiers knocked off a vein: each securityDegrade row's tiers plus its escalation.
static func security_degrade_tiers(vein_id: String) -> int:
	var total := 0
	for row in _rows(vein_id, KIND_SECURITY_DEGRADE):
		total += int(row["params"].get("tiers", 1)) + int(row["escalation"])
	return total


# £ to put a vein's degraded security right: the rows' params.cost, else the data default; 0 when intact.
static func security_repair_cost(vein_id: String) -> int:
	var total := 0
	for row in _rows(vein_id, KIND_SECURITY_DEGRADE):
		total += int(row["params"].get("cost", _cfg()["repairCost"]))
	return total


static func is_frozen(vein_id: String) -> bool:
	return not _rows(vein_id, KIND_FREEZE).is_empty()


# True when a workBan row bans the current time block.
static func is_work_banned(vein_id: String) -> bool:
	var block: int = GameState.state["world"]["timeBlock"]
	for row in _rows(vein_id, KIND_WORK_BAN):
		if TimeSystem.block_index(str(row["params"].get("block", ""))) == block:
			return true
	return false


# { ok, reason } for acting on a vein: a freeze stops everything; work (cultivate, harvest) is also stopped in a banned block.
static func vein_gate(vein_id: String, is_work: bool) -> Dictionary:
	if is_frozen(vein_id):
		return { "ok": false, "reason": "Frozen by injunction." }
	if is_work and is_work_banned(vein_id):
		return { "ok": false, "reason": "Work banned this block." }
	return { "ok": true, "reason": "" }


# Player pays to put degraded security right; clears the vein's securityDegrade rows.
static func repair_security(vein_id: String) -> Dictionary:
	var cost := security_repair_cost(vein_id)
	if cost == 0:
		return { "ok": false, "reason": "Nothing to repair." }
	var gate := vein_gate(vein_id, false)
	if not gate["ok"]:
		return gate
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < cost:
		return { "ok": false, "reason": "Not enough cash." }
	player["cash"] -= cost
	Bank.record(-cost, "Vein security repair")
	GameState.state["harassment"]["active"] = active().filter(func(r: Dictionary) -> bool:
		return not (r.get("veinId", "") == vein_id and r["kind"] == KIND_SECURITY_DEGRADE))
	EventBus.state_changed.emit()
	return { "ok": true }


# fine event op: takes up to amount from the player's cash.
static func fine(amount: int) -> int:
	var player: Dictionary = GameState.state["player"]
	var paid := mini(amount, int(player["cash"]))
	if paid > 0:
		player["cash"] -= paid
		Bank.record(-paid, "Fine")
	return paid


# spend_block event op: burns count time blocks (a hearing).
static func spend_blocks(count: int) -> void:
	for i in count:
		if not TimeSystem.is_time_exhausted():
			TimeSystem.advance_time_block()


# ── economic and information effects ─────────────────────────────────────

# Product of every active sellPenalty row that covers the good. params.class
# "ore" covers ores, "item" covers consumables; params.goods (optional) narrows
# it to those ore ids / recipe keys.
static func sell_mult(kind: String, good: String) -> float:
	var item_class := "ore" if kind == "ore" else "item"
	var mult := 1.0
	for row in active():
		if row["kind"] != KIND_SELL_PENALTY:
			continue
		var params: Dictionary = row["params"]
		if params.get("class", "") != item_class:
			continue
		var goods: Array = params.get("goods", [])
		if not goods.is_empty() and not goods.has(good):
			continue
		mult *= float(params.get("mult", 1.0))
	return mult


# True when any sellPenalty row is active, for the sell menu's notice.
static func has_sell_penalty() -> bool:
	for row in active():
		if row["kind"] == KIND_SELL_PENALTY:
			return true
	return false


# True while a shopBar row bars the player from the faction's shop.
static func is_shop_barred(faction_id: String) -> bool:
	for row in active():
		if row["kind"] == KIND_SHOP_BAR and row["params"].get("factionId", row["factionId"]) == faction_id:
			return true
	return false


# raise_intel event op: every faction's intel on the player rises by amount.
static func raise_intel(amount: int) -> void:
	for faction_id in GameData.FACTIONS.keys():
		Intel.raise(faction_id, Shares.PLAYER, amount)
	EventBus.state_changed.emit()
