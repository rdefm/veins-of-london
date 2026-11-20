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


# A loaded Fate Lens's light bonus to every roll that Dial's owner makes
# (R§1.4 Lenses): fateAllRollsBonusByTier at its tier, 0.0 with none. Each
# roll's call site adds it before that roll's own clamp.
static func fate_all_rolls_bonus(owner_id: String = "") -> float:
	var curve: Array = GameData.DIAL_LENS["fateAllRollsBonusByTier"]
	return float(curve[clampi(tier_for("fate", owner_id), 0, curve.size() - 1)])


# Label for the Fate line in a mods breakdown.
static func fate_label() -> String:
	return str(GameData.DIAL_LENS["fateAllRollsLabel"])


# Sense level a gate needs; 0 for "always" (no gate).
static func gate_level(gate: String) -> int:
	return int(GameData.DIAL_LENS["senseGates"].get(gate, 0))


# One-line effect of a Lens of `ore` (its always-on bonus), for pickers.
static func one_line(ore: String) -> String:
	return str(GameData.DIAL_LENS["effects"].get(ore, {}).get("always", ""))


# Lens Details rows, in Sense order: { gate, level, text, unlocked }. A
# contact's Lens has one row (its winding ore plus any combat effect, R§1.4
# Contact Dials); the player's lists every gate, locked ones by current Sense.
static func effect_rows(ore: String, owner_id: String = "") -> Array:
	var lens_data: Dictionary = GameData.DIAL_LENS
	if owner_id != "":
		var text: String = lens_data["contactEffects"].get(ore, lens_data["contactNoEffect"])
		return [{ "gate": "always", "level": 0, "text": text, "unlocked": true }]
	var effects: Dictionary = lens_data["effects"].get(ore, {})
	var rows: Array = [{ "gate": "always", "level": 0, "text": str(effects.get("always", "")), "unlocked": true }]
	for gate in ["world", "combat", "glimpse", "peripheral"]:
		var text: String = str(effects.get(gate, lens_data["sharedEffects"].get(gate, "")))
		rows.append({ "gate": gate, "level": gate_level(gate), "text": text, "unlocked": sense_unlocked(gate) })
	return rows


# Player Sense >= senseGates[gate]. A contact has no Sense, so always false for one.
static func sense_unlocked(gate: String, owner_id: String = "") -> bool:
	if owner_id != "":
		return false
	var gates: Dictionary = GameData.DIAL_LENS["senseGates"]
	if not gates.has(gate):
		return false
	return int(GameState.state["player"]["senseSkill"]) >= int(gates[gate])
