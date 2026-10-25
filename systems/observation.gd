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
	if not _stored(id).has("results"):
		_roll_all(id)
	return rows(id)


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


# Σmods for an observation's ores: Sense plus the observation's own mods, as
# [{label, delta}] (zero deltas dropped).
static func _mods(def: Dictionary) -> Array:
	var out: Array = []
	var sense: float = float(GameData.OBSERVATION["sensePerLevel"]) * (int(GameState.state["player"]["senseSkill"]) - 1)
	if sense != 0.0:
		out.append({ "label": GameData.OBSERVATION["senseLabel"], "delta": sense })
	for mod in def.get("mods", []):
		var delta: float = Events._mod_delta(mod)
		if delta != 0.0:
			out.append({ "label": mod.get("label", ""), "delta": delta })
	return out


static func _roll_value(id: String, ore: String, roll_count: int) -> float:
	var event_state: Dictionary = GameState.state["event"]
	return Rng.stable_unit("%d|%s|%s|%s|%s|%d" % [int(GameState.state["world"]["rollSeed"]), event_state["eventId"], id, ore, Events.run_key(), roll_count])


static func _roll_all(id: String) -> void:
	var def := _def(id)
	var event_state: Dictionary = GameState.state["event"]
	if not event_state.has("observations"):
		event_state["observations"] = {}
	var roll_count := 0
	var mods := _mods(def)
	var total := 0.0
	for mod in mods:
		total += float(mod["delta"])
	var results: Dictionary = {}
	var xp := 0
	var tier_effects: Array = []
	for ore in GameData.OBSERVATION["oreOrder"]:
		if not def["blocks"].has(ore):
			continue
		var tiers: Array = def["blocks"][ore]["tiers"]
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
		else:
			for k in range(tiers.size() - level, tiers.size()):
				tier_effects.append_array(tiers[k].get("effects", []))
		results[ore] = {
			"roll": clampi(ceili(snappedf(100.0 - roll * 100.0, 0.000001)), 1, 100),
			"needed": floori(snappedf(100.0 - needed_p * 100.0, 0.000001)) + 1,
			"level": level,
			"mods": mods,
		}
		xp += int(GameData.OBSERVATION["xpPerBlock"]) + int(GameData.OBSERVATION["xpPerTier"]) * level
	event_state["observations"][id] = { "rollCount": roll_count + 1, "results": results }
	Sense.award_xp(xp)
	Events.apply_effects(tier_effects)


static func _tier_chance(tier: Dictionary, total: float) -> float:
	var lo: float = float(tier.get("min", GameData.EVENT_CHECKS["defaultMin"]))
	var hi: float = float(tier.get("max", GameData.EVENT_CHECKS["defaultMax"]))
	return clampf(float(tier["base"]) + total, lo, hi)
