class_name Observation
extends RefCounted

# Observation (R§3.9d): an event's `observations` table, a card's `observe`
# reference, and the read that rolls once per listed ore. Results live under
# state.event.observations[obsId] = {rollCount, results: {ore: {roll, needed,
# level, mods}}}; `level` is 0 for a miss, else the count of tiers reached
# (1 = the lowest hit, tiers.size() = the best). Never draws from the global Rng.


# The observation id in effect for the current card: the latest `observe` key at
# or before it (null clears), "" for none.
static func in_effect() -> String:
	var event_state: Variant = GameState.state["event"]
	if event_state == null or not Events.has_live_definition():
		return ""
	var cards: Array = GameData.EVENTS[event_state["eventId"]]["cards"]
	var id := ""
	for i in range(mini(int(event_state["cardIndex"]) + 1, cards.size())):
		if cards[i].has("observe"):
			id = "" if cards[i]["observe"] == null else String(cards[i]["observe"])
	return id


# True when the observation in effect has not been read yet this run.
static func is_unread() -> bool:
	var id := in_effect()
	return id != "" and not _stored(id).has("results")


# Performs the read of the observation in effect (first call rolls, awards Sense
# XP and runs reached tiers' effects; later calls return the stored results).
# Returns display rows, or [] when nothing is in effect.
static func read() -> Array:
	var id := in_effect()
	if id == "":
		return []
	if not _stored(id).has("results") or is_armed():
		_roll_all(id)
	return rows(id)


# True when the observation in effect was read and an event Rewind re-armed it.
static func is_armed() -> bool:
	var id := in_effect()
	return id != "" and bool(_stored(id).get("armed", false))


# Re-arms every read observation of the live event for one more roll; returns
# their ids. Called by Events.rewind() after the observations are carried over.
static func rearm_read() -> Array:
	var rearmed: Array = []
	var event_state: Variant = GameState.state["event"]
	if event_state == null:
		return rearmed
	for id in event_state.get("observations", {}):
		var stored: Dictionary = event_state["observations"][id]
		if stored.has("results"):
			stored["armed"] = true
			rearmed.append(id)
	return rearmed


# Display rows in ore order for a read observation: {ore, roll, needed, level,
# tiers, text, hit, mods}. roll is the shown d100 (high is good), needed the
# shown threshold for the landed tier (or the easiest tier on a miss).
static func rows(id: String) -> Array:
	var def := _def(id)
	var stored: Dictionary = _stored(id)
	var out: Array = []
	if def.is_empty() or not stored.has("results"):
		return out
	for ore in GameData.OBSERVATION["oreOrder"]:
		if not def["blocks"].has(ore) or not stored["results"].has(ore):
			continue
		var block: Dictionary = def["blocks"][ore]
		var result: Dictionary = stored["results"][ore]
		var tiers: Array = block["tiers"]
		var level := int(result["level"])
		out.append({
			"ore": ore,
			"roll": int(result["roll"]),
			"needed": int(result["needed"]),
			"level": level,
			"tiers": tiers.size(),
			"text": String(tiers[tiers.size() - level]["text"]) if level > 0 else String(block["miss"]),
			"hit": level > 0,
			"mods": result["mods"],
			"rerolled": result.has("last"),
			"last": int(result.get("last", result["roll"])),
			"improved": bool(result.get("improved", false)),
		})
	return out


# The `observed` condition (current run): the stored tier level for the ore is at
# least atLeast. The cross-event `event` form reads persistent memory, not yet held.
static func observed(cond: Dictionary) -> bool:
	if cond.has("event") or GameState.state["event"] == null:
		return false
	var result: Dictionary = _stored(String(cond.get("id", ""))).get("results", {}).get(cond.get("ore", ""), {})
	return int(result.get("level", 0)) >= int(cond.get("atLeast", 1))


static func _def(id: String) -> Dictionary:
	if not Events.has_live_definition():
		return {}
	var event_state: Dictionary = GameState.state["event"]
	return GameData.EVENTS[event_state["eventId"]].get("observations", {}).get(id, {})


static func _stored(id: String) -> Dictionary:
	var event_state: Variant = GameState.state["event"]
	if event_state == null:
		return {}
	return event_state.get("observations", {}).get(id, {})


# Σmods for one ore of an observation, as [{label, delta}] (zero deltas dropped):
# Sense, the observation's own mods, then the kit (seated Movement attunement,
# Be A Lady, Prophet's Breath, held items' `observeBonus`).
static func _mods(def: Dictionary, ore: String) -> Array:
	var out: Array = []
	var sense: float = float(GameData.OBSERVATION["sensePerLevel"]) * (int(GameState.state["player"]["senseSkill"]) - 1)
	_add_mod(out, GameData.OBSERVATION["senseLabel"], sense)
	for mod in def.get("mods", []):
		_add_mod(out, mod.get("label", ""), Events._mod_delta(mod))
	_add_mod(out, GameData.OBSERVATION["attunementLabel"], Dial.attunement_bonus(ore))
	_add_mod(out, GameData.EVENT_CHECKS["ladyLabel"], float(GameData.EVENT_CHECKS["ladyBonusPerLevel"]) * ActiveEffects.lady_level())
	if ore == "time" and ActiveEffects.prophets_breath_active():
		_add_mod(out, GameData.OBSERVATION["breathLabel"], float(GameData.OBSERVATION["breathBonus"]))
	for key in GameData.RECIPES:
		var bonus: Dictionary = GameData.RECIPES[key].get("observeBonus", {})
		if not bonus.is_empty() and Crafting.inventory_qty(key) > 0:
			_add_mod(out, GameData.RECIPES[key].get("name", key), float(bonus.get(ore, 0.0)) + float(bonus.get("all", 0.0)))
	return out


static func _add_mod(out: Array, label: String, delta: float) -> void:
	if delta != 0.0:
		out.append({ "label": label, "delta": delta })


# Sum of a mods list's deltas.
static func mods_total(mods: Array) -> float:
	var total := 0.0
	for mod in mods:
		total += float(mod["delta"])
	return total


static func _roll_value(id: String, ore: String, roll_count: int) -> float:
	var event_state: Dictionary = GameState.state["event"]
	return Rng.stable_unit("%d|%s|%s|%s|%s|%d" % [int(GameState.state["world"]["rollSeed"]), event_state["eventId"], id, ore, Events.run_key(), roll_count])


static func _roll_all(id: String) -> void:
	var def := _def(id)
	var event_state: Dictionary = GameState.state["event"]
	if not event_state.has("observations"):
		event_state["observations"] = {}
	var previous: Dictionary = event_state["observations"].get(id, {})
	var kept: Dictionary = previous.get("results", {})
	var roll_count := int(previous.get("rollCount", 0))
	var results: Dictionary = {}
	var xp := 0
	var tier_effects: Array = []
	for ore in GameData.OBSERVATION["oreOrder"]:
		if not def["blocks"].has(ore):
			continue
		var tiers: Array = def["blocks"][ore]["tiers"]
		var mods := _mods(def, ore)
		var total := mods_total(mods)
		var roll := _roll_value(id, ore, roll_count)
		var level := 0
		var needed_p := 0.0
		for k in range(tiers.size()):
			var p := _tier_chance(tiers[k], total)
			if roll < p:
				level = tiers.size() - k
				needed_p = p
				break
		if level == 0:
			needed_p = _tier_chance(tiers[tiers.size() - 1], total)
		var shown := clampi(ceili(snappedf(100.0 - roll * 100.0, 0.000001)), 1, 100)
		var old_level := int(kept[ore]["level"]) if kept.has(ore) else 0
		# Effects run only for tiers newly reached (every reached tier on the first read).
		for k in range(tiers.size() - level, tiers.size() - old_level):
			tier_effects.append_array(tiers[k].get("effects", []))
		if kept.has(ore) and level <= old_level:
			results[ore] = kept[ore].duplicate()
			results[ore]["last"] = shown
			results[ore]["improved"] = false
		else:
			results[ore] = {
				"roll": shown,
				"needed": floori(snappedf(100.0 - needed_p * 100.0, 0.000001)) + 1,
				"level": level,
				"mods": mods,
			}
			if kept.has(ore):
				results[ore]["last"] = shown
				results[ore]["improved"] = true
		xp += int(GameData.OBSERVATION["xpPerBlock"]) + int(GameData.OBSERVATION["xpPerTier"]) * level
	event_state["observations"][id] = { "rollCount": roll_count + 1, "results": results }
	Sense.award_xp(xp)
	Events.apply_effects(tier_effects)


static func _tier_chance(tier: Dictionary, total: float) -> float:
	var lo: float = float(tier.get("min", GameData.EVENT_CHECKS["defaultMin"]))
	var hi: float = float(tier.get("max", GameData.EVENT_CHECKS["defaultMax"]))
	return clampf(float(tier["base"]) + total, lo, hi)
