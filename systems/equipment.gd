class_name Equipment
extends RefCounted

# Weapon equip/unequip. Mirrors Devices.equip_device/unequip_device (T06)
# for the device slot — no formula in R§3 covers this (items/equipment
# aren't given an explicit system anywhere in M0-PORT.md), but screens
# still can't mutate state directly, so this small system exists to give
# T12's inventory screen a button handler to call.


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
