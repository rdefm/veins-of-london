class_name Factions
extends RefCounted

# Faction joining. Like Equipment (T12 1/4) and Modal (T12 2/4), this is
# a small gap: R§3 never gives a "join faction" formula, and no earlier
# task claims it, but the factions screen needs a system function to call
# rather than mutating state.factions directly.


static func can_join(faction_id: String) -> bool:
	var f: Dictionary = GameState.state["factions"].get(faction_id, {})
	if f.is_empty() or f.get("joined", false):
		return false
	var join_relation: int = GameData.FACTIONS[faction_id]["joinRelation"]
	return f["relation"] >= join_relation


static func join(faction_id: String) -> Dictionary:
	if not can_join(faction_id):
		return { "ok": false, "reason": "Not eligible yet." }
	GameState.state["factions"][faction_id]["joined"] = true
	EventBus.state_changed.emit()
	return { "ok": true }
