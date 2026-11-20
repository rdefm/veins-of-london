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


# Peripheral sight (R§1.4 Lenses): the best tier among the player's owned but
# unloaded Lenses of `ore`, at Sense >= senseGates.peripheral and only while no
# Lens of that ore is loaded; 0 otherwise. Player only.
static func peripheral_tier(ore: String) -> int:
	if Dial.dial_of("") == null or not sense_unlocked("peripheral") or has(ore):
		return 0
	var best: int = 0
	for lens in GameState.state["player"].get("lensInventory", []):
		if lens["ore"] == ore:
			best = maxi(best, int(lens["tier"]))
	return best


# A loaded Fate Lens's light bonus to every roll that Dial's owner makes
# (R§1.4 Lenses): fateAllRollsBonusByTier at its tier, 0.0 with none. Each
# roll's call site adds it before that roll's own clamp.
static func fate_all_rolls_bonus(owner_id: String = "") -> float:
	var curve: Array = GameData.DIAL_LENS["fateAllRollsBonusByTier"]
	return float(curve[clampi(tier_for("fate", owner_id), 0, curve.size() - 1)])


# Life Lens world sight (R§1.4 Lenses): the player's prospect tier-weight shift,
# sites.json lifeProspectShiftByTier at the loaded Life Lens's tier while Sense
# >= senseGates.world; 0.0 otherwise.
static func life_prospect_shift() -> float:
	if not sense_unlocked("world"):
		return 0.0
	var curve: Array = GameData.SITE_LIFE_PROSPECT_SHIFT_BY_TIER
	return float(curve[clampi(tier_for("life"), 0, curve.size() - 1)])


# Life Lens world sight on the vein sheet: a loaded Life Lens and Sense >= senseGates.world.
static func life_drift_sight() -> bool:
	return has("life") and sense_unlocked("world")


# Emotion Lens world sight on faction cards: a loaded Emotion Lens and Sense >= senseGates.world.
static func emotion_standing_sight() -> bool:
	return has("emotion") and sense_unlocked("world")


# Emotion Lens faction-card lines (R§1.4 Lenses): exact Threat toward the player
# (FactionAI.threat) and, with an open grudge, its days left (Grudges.days_left).
# Empty without emotion_standing_sight. Strings: dial.json lens.emotionStanding.
static func emotion_standing_lines(faction_id: String) -> Array:
	if not emotion_standing_sight():
		return []
	var text: Dictionary = GameData.DIAL_LENS["emotionStanding"]
	var lines: Array = [String(text["threat"]) % FactionAI.threat(faction_id, Shares.PLAYER)]
	var left := Grudges.days_left(faction_id)
	if left == 0:
		lines.append(String(text["grudgeLastDay"]))
	elif left == 1:
		lines.append(String(text["grudgeOneDay"]))
	elif left > 1:
		lines.append(String(text["grudgeDays"]) % left)
	return lines


# Fate Lens combat sight (R§1.4 Lenses): a loaded Fate Lens and Sense >=
# senseGates.combat flags read enemy intents whose pre-rolled crit lands.
static func fate_crit_sight() -> bool:
	return has("fate") and sense_unlocked("combat")


# Time Lens combat sight (R§1.4 Lenses): the share cut from enemy unread
# chances, timeFogCutByTier[tier]. The player needs Sense >=
# senseGates.combat; a contact (no Sense) applies it to its own AI reads.
static func time_fog_cut(owner_id: String = "") -> float:
	if owner_id == "" and not sense_unlocked("combat"):
		return 0.0
	return float(GameData.DIAL_LENS["timeFogCutByTier"][tier_for("time", owner_id)])


# Physics Lens combat sight (R§1.4 Lenses): flat Strike damage added to hits
# dealt and cut from hits taken, physicsFlatByTier[tier]. The player needs
# Sense >= senseGates.combat; a contact (no Sense) gets it from its own Dial.
static func physics_flat(owner_id: String = "") -> int:
	if owner_id == "" and not sense_unlocked("combat"):
		return 0
	return int(GameData.DIAL_LENS["physicsFlatByTier"][tier_for("physics", owner_id)])


# Life Lens combat sight: enemy HP shown as hp/hpMax. Player only.
static func life_hp_sight() -> bool:
	return has("life") and sense_unlocked("combat")


# Emotion Lens combat sight: an enemy action's target shows, read or not.
# Player only.
static func emotion_target_sight() -> bool:
	return has("emotion") and sense_unlocked("combat")


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
