class_name FactionIncidents
extends RefCounted

# Faction incidents (R§3.1f): the daily tick turns faction-sim state into
# authored events. Each data entry (faction_incidents.json) names a trigger,
# an event, a cooldown and trigger-specific conditions; a firing trigger sends
# the entry's notice as a pending message from a key member and queues the
# event, which the message's button plays.
# Adding a trigger = a `_trigger_<name>` function returning hits, one line in
# `_trigger_fn`, its id in TRIGGER_IDS, and data entries naming it.
# state.factionIncidents = { queued: [ { queueId, incidentId, eventId, context } ],
# cooldowns: { "<incidentId>|<subject>": untilDay }, flips: [ { day, district, from, to } ],
# nextId: int }.

const PENDING_KIND := "faction_incident"
const TRIGGER_IDS: PackedStringArray = ["raidedByFaction", "warBetween", "truceExpiring", "turfFlip"]


static func _cfg() -> Dictionary:
	return GameData.FACTION_INCIDENTS


static func new_state() -> Dictionary:
	return { "queued": [], "cooldowns": {}, "flips": [], "nextId": 1 }


static func _state() -> Dictionary:
	return GameState.state["factionIncidents"]


static func _day() -> int:
	return int(GameState.state["world"]["day"])


static func queued() -> Array:
	return _state()["queued"]


# Turf.recompute reports each controller change here; the next tick consumes it.
static func record_flip(district_id: String, from_id: String, to_id: String) -> void:
	_state()["flips"].append({ "day": _day(), "district": district_id, "from": from_id, "to": to_id })


# A trigger function takes the entry's conditions and returns hits:
# { subject: String (cooldown key), speakers: [factionId] (first able to speak
# sends the notice), context: Dictionary (the event's context) }.
static func _trigger_fn(trigger: String) -> Callable:
	match trigger:
		"raidedByFaction":
			return _trigger_raided
		"warBetween":
			return _trigger_war
		"truceExpiring":
			return _trigger_truce
		"turfFlip":
			return _trigger_flip
	return Callable()


static func _trigger_raided(conditions: Dictionary) -> Array:
	var hits := []
	var max_age := int(conditions.get("maxAgeDays", 2))
	var grudges: Dictionary = GameState.state["grudges"]
	for faction_id in grudges.keys():
		var grudge: Dictionary = grudges[faction_id]
		if _day() - int(grudge["sinceDay"]) > max_age:
			continue
		hits.append({
			"subject": "%s@%d" % [faction_id, int(grudge["sinceDay"])],
			"speakers": [faction_id],
			"context": { "faction_id": faction_id, "district": grudge["district"], "site_id": grudge.get("siteId", "") },
		})
	return hits


static func _trigger_war(conditions: Dictionary) -> Array:
	var hits := []
	var min_days := int(conditions.get("minWarDays", 1))
	for war in FactionAI.wars():
		var parties: Array = war["parties"]
		if parties.has(Shares.PLAYER) or _day() - int(war["startDay"]) < min_days:
			continue
		hits.append({
			"subject": "%s+%s@%d" % [parties[0], parties[1], int(war["startDay"])],
			"speakers": parties.duplicate(),
			"context": { "faction_a": parties[0], "faction_b": parties[1] },
		})
	return hits


static func _trigger_truce(conditions: Dictionary) -> Array:
	var hits := []
	var within := int(conditions.get("withinDays", 2))
	var player_only: bool = conditions.get("playerInvolved", true)
	for truce in FactionAI.truces():
		var parties: Array = truce["parties"]
		var left := int(truce["endDay"]) - _day()
		if left < 0 or left > within:
			continue
		var has_player: bool = parties.has(Shares.PLAYER)
		if player_only and not has_player:
			continue
		var others: Array = parties.filter(func(p: String) -> bool: return p != Shares.PLAYER)
		hits.append({
			"subject": "%s+%s@%d" % [parties[0], parties[1], int(truce["endDay"])],
			"speakers": others,
			"context": { "faction_id": others[0], "days_left": left },
		})
	return hits


static func _trigger_flip(conditions: Dictionary) -> Array:
	var hits := []
	var involves_player: bool = conditions.get("involvesPlayer", false)
	for flip in _state()["flips"]:
		var from_id: String = flip["from"]
		var to_id: String = flip["to"]
		if involves_player and from_id != Turf.PLAYER and to_id != Turf.PLAYER:
			continue
		var speakers := []
		for faction_id in [to_id, from_id]:
			if faction_id != "" and faction_id != Turf.PLAYER:
				speakers.append(faction_id)
		hits.append({
			"subject": "%s@%d" % [flip["district"], int(flip["day"])],
			"speakers": speakers,
			"context": { "district": flip["district"], "from": from_id, "to": to_id, "faction_id": speakers[0] if not speakers.is_empty() else "" },
		})
	return hits


# Daily step (⑥.5j2b): runs every entry's trigger, queues the hits that are off
# cooldown, then drops the consumed flips and lapsed cooldowns.
static func daily_tick() -> void:
	var day := _day()
	for incident_id in _cfg()["entries"]:
		var entry: Dictionary = _cfg()["entries"][incident_id]
		var trigger := _trigger_fn(String(entry["trigger"]))
		if not trigger.is_valid():
			push_error("FactionIncidents: unregistered trigger '%s'" % entry["trigger"])
			continue
		for hit in trigger.call(entry["conditions"]):
			var key := "%s|%s" % [incident_id, hit["subject"]]
			if int(_state()["cooldowns"].get(key, -1)) >= day:
				continue
			if queued().size() >= int(_cfg()["queueCap"]):
				break
			if _fire(entry, hit):
				_state()["cooldowns"][key] = day + int(entry["cooldownDays"])
	_state()["flips"] = []
	var cooldowns: Dictionary = _state()["cooldowns"]
	for key in cooldowns.keys():
		if int(cooldowns[key]) < day:
			cooldowns.erase(key)
	EventBus.state_changed.emit()


# Queues the entry's event and sends its notice; false (nothing queued) when no
# party to the hit can speak.
static func _fire(entry: Dictionary, hit: Dictionary) -> bool:
	var speaker := ""
	for faction_id in hit["speakers"]:
		if KeyMembers.can_speak(faction_id):
			speaker = faction_id
			break
	if speaker == "":
		return false
	var state := _state()
	var queue_id := "i%d" % int(state["nextId"])
	state["nextId"] = int(state["nextId"]) + 1
	state["queued"].append({ "queueId": queue_id, "incidentId": entry["id"], "eventId": entry["eventId"], "context": hit["context"] })
	KeyMembers.send(speaker, str(entry["notice"]), PENDING_KIND, { "queueId": queue_id })
	return true


# Starts the queued event with queue_id; false when it is gone.
static func start(queue_id: String) -> bool:
	for i in queued().size():
		if queued()[i]["queueId"] == queue_id:
			var next: Dictionary = queued().pop_at(i)
			Events.start_or_defer(next["eventId"], next["context"])
			return true
	return false


# Pending-message tap: resolves the message and plays its event.
static func start_pending(pending_id: String) -> void:
	var queue_id := ""
	for entry in GameState.state["pendingMessages"]:
		if entry["id"] == pending_id:
			queue_id = String(entry["payload"].get("queueId", ""))
	Messages.resolve_pending(pending_id)
	start(queue_id)
