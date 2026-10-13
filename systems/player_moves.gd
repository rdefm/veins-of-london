class_name PlayerMoves
extends RefCounted

# The player's non-violent moves against a faction (spec "Player non-violent
# moves"): file a complaint (freezes a faction vein's security upgrades), tip
# off the police (timed sell-price penalty on the faction), leak to the Ticker
# (pulls Ticker states against the faction's own prefs and dents its standing
# with every other faction). Each costs £ and a block, is gated by Intel on the
# target, counts as a hostile act, drops the player's relation and answers an
# open grudge. None is a warmonger act. Data: data/player_moves.json.
# state.factionPenalties = { factionId: { untilDay, mult } }

const MOVE_COMPLAINT := "fileComplaint"
const MOVE_POLICE := "tipPolice"
const MOVE_LEAK := "leakTicker"
const EXEMPT_FACTION := "collective"


static func new_state() -> Dictionary:
	return {}


static func _cfg() -> Dictionary:
	return GameData.PLAYER_MOVES


static func move(move_id: String) -> Dictionary:
	return _cfg()["moves"][move_id]


static func move_ids() -> Array:
	return _cfg()["moves"].keys()


static func _day() -> int:
	return int(GameState.state["world"]["day"])


# Why the move can't be made now ("" when it can). site_id only matters for
# moves with needsVein.
static func block_reason(move_id: String, faction_id: String, site_id: String = "") -> String:
	var m := move(move_id)
	if faction_id == EXEMPT_FACTION or not GameData.FACTIONS.has(faction_id):
		return "Not a target."
	if not Intel.knows(Shares.PLAYER, faction_id, String(m["intelGate"])):
		return "Need more intel on them."
	if int(GameState.state["player"]["cash"]) < int(m["cost"]["cash"]):
		return "Not enough cash."
	if TimeSystem.blocks_left() < int(m["cost"]["blocks"]):
		return "No time left today."
	if bool(m["needsVein"]):
		var site: Variant = Sites.find_site(site_id)
		if site == null or site["factionVein"] == null or site["factionVein"]["factionId"] != faction_id:
			return "Pick one of their veins."
		if not NetworkHandler.is_vulnerable(site_id, NetworkHandler.EFFECT_SECURITY_FREEZE):
			return "Nothing left to stall there."
		if NetworkHandler.is_security_frozen(site_id):
			return "Already stalled."
	elif move_id == MOVE_LEAK and Barometer.leak_prefs(faction_id).is_empty():
		return "Nothing to leak."
	return ""


static func perform(move_id: String, faction_id: String, site_id: String = "") -> Dictionary:
	var reason := block_reason(move_id, faction_id, site_id)
	if reason != "":
		return { "ok": false, "reason": reason }
	var m := move(move_id)
	var cost: int = int(m["cost"]["cash"])
	GameState.state["player"]["cash"] -= cost
	Bank.record(-cost, String(m["label"]))
	for i in int(m["cost"]["blocks"]):
		TimeSystem.advance_time_block()

	match move_id:
		MOVE_COMPLAINT:
			NetworkHandler.reveal_vulnerable_vein(site_id, NetworkHandler.EFFECT_SECURITY_FREEZE, int(m["durationDays"]))
		MOVE_POLICE:
			GameState.state["factionPenalties"][faction_id] = { "untilDay": _day() + int(m["durationDays"]), "mult": float(m["sellMult"]) }
		MOVE_LEAK:
			_leak(faction_id, m)

	FactionAI.note_hostile_act(Shares.PLAYER, faction_id)
	Factions.adjust_player_relation(faction_id, -int(_cfg()["relationHit"]))
	Grudges.answer(faction_id)
	Notify.push(String(m["log"]) % GameData.FACTIONS[faction_id]["shortName"])
	EventBus.state_changed.emit()
	return { "ok": true }


# Pulls each Ticker state the faction pushes (and pushes each it pulls) at
# strengthMult x its pref strength, and costs it standing with the others.
static func _leak(faction_id: String, m: Dictionary) -> void:
	for pref in Barometer.leak_prefs(faction_id):
		var opposite := "pull" if pref["direction"] == "push" else "push"
		Barometer.queue_push(faction_id, pref["section"], pref["state"], opposite, int(pref["strength"]) * int(m["strengthMult"]))
	var name: String = GameData.FACTIONS[faction_id]["shortName"]
	Barometer.push_headline(String(m["headline"]) % name)
	var hit: int = int(_cfg()["otherFactionsRelationHit"])
	for other in GameData.FACTIONS.keys():
		if other != faction_id:
			Factions.adjust_relation(faction_id, other, -hit)


# Sell-price multiplier on the faction's goods while a police tip is live.
static func sell_mult(faction_id: String) -> float:
	var row: Variant = GameState.state["factionPenalties"].get(faction_id)
	if row == null or int(row["untilDay"]) <= _day():
		return 1.0
	return float(row["mult"])
