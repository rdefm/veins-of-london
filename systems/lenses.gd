class_name Lenses
extends RefCounted

# Read layer for loaded Lenses (R§1.4 Lenses). owner_id "" is the player's Dial,
# a contact id that contact's (same convention as Dial.dial_of). Every lens
# effect reads through here; crafting and load/unload live in Dial.


static func loaded(owner_id: String = "") -> Array:
	var dial: Variant = Dial.dial_of(owner_id)
	if dial == null:
		return []
	return dial.get("lenses", [])


# Tier of the loaded Lens of `ore` on that Dial; 0 = none loaded.
static func tier_for(ore: String, owner_id: String = "") -> int:
	for lens in loaded(owner_id):
		if lens["ore"] == ore:
			return int(lens["tier"])
	return 0


static func has(ore: String, owner_id: String = "") -> bool:
	return tier_for(ore, owner_id) > 0


# Player Sense >= senseGates[gate]. A contact has no Sense, so always false for one.
static func sense_unlocked(gate: String, owner_id: String = "") -> bool:
	if owner_id != "":
		return false
	var gates: Dictionary = GameData.DIAL_LENS["senseGates"]
	if not gates.has(gate):
		return false
	return int(GameState.state["player"]["senseSkill"]) >= int(gates[gate])
