class_name Equipment
extends RefCounted

# Weapon equip/unequip — no formula in R§3 covers this, but screens still
# can't mutate state directly, so this exists as a button-handler target
# for the inventory screen. Dial seat/unseat lives in systems/dial.gd
# instead — a Dial is a lifetime-owned instrument, not an equipment slot.


static func equip_weapon(item_id: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var found := false
	for item in player["items"]:
		if item["id"] == item_id:
			found = true
			break
	if not found:
		return { "ok": false, "reason": "Item not found." }

	player["equipment"]["weapon"] = item_id
	EventBus.state_changed.emit()
	return { "ok": true }


static func unequip_weapon() -> void:
	GameState.state["player"]["equipment"]["weapon"] = null
	EventBus.state_changed.emit()
