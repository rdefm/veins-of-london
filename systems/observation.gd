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


# The security of a faction vein as one string: guard count and guard kit. Add
# any future site security option here and stored site reads track it (R§3.9d).
static func security_signature(vein: Dictionary) -> String:
	return "%d|%s" % [Cultivating.vein_guard_count(vein), JSON.stringify(vein.get("guardKit", {}), "", true)]


# The faction vein a live raid event targets (context site_id), or null.
static func _context_vein() -> Variant:
	var event_state: Variant = GameState.state.get("event")
	if event_state == null:
		return null
	var site_id := String(event_state.get("context", {}).get("site_id", ""))
	var site: Variant = Sites.find_site(site_id) if site_id != "" else null
	return site["factionVein"] if site != null else null


# The single invalidation entry point for per-site reads: the site's stored read,
# or {} when none. A read whose recorded security differs from the vein's current
# security is dropped here, so any security change clears it on next use.
static func site_memory(site_id: String) -> Dictionary:
	var by_site: Dictionary = GameState.state.get("siteObservations", {})
	if not by_site.has(site_id):
		return {}
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null or by_site[site_id]["security"] != security_signature(site["factionVein"]):
		by_site.erase(site_id)
		return {}
	return by_site[site_id]


# Seeds a starting raid event's observations from its site's stored read and
# stamps the security the event began against. Called by Events.start_event.
static func restore_site_memory() -> void:
	var vein: Variant = _context_vein()
	if vein == null:
		return
	var event_state: Dictionary = GameState.state["event"]
	event_state["context"]["security"] = security_signature(vein)
	var memory := site_memory(String(event_state["context"]["site_id"]))
	if memory.is_empty() or not GameData.EVENTS[event_state["eventId"]].has("observations"):
		return
	var observations: Dictionary = memory["observations"].duplicate(true)
	for id in observations.keys():
		if not GameData.EVENTS[event_state["eventId"]]["observations"].has(id):
			observations.erase(id)
	event_state["observations"] = observations


# Keeps the live raid event's reads against its site, tagged with the security the
# event began against. Called as the event completes.
static func _store_site_memory() -> void:
	var vein: Variant = _context_vein()
	var event_state: Dictionary = GameState.state["event"]
	if vein == null or event_state.get("observations", {}).is_empty():
		return
	var observations: Dictionary = event_state["observations"].duplicate(true)
	for id in observations:
		observations[id].erase("armed")
	var by_site: Dictionary = GameState.state.get("siteObservations", {})
	by_site[event_state["context"]["site_id"]] = {
		"security": String(event_state["context"].get("security", security_signature(vein))),
		"observations": observations,
	}
	GameState.state["siteObservations"] = by_site


# Folds the live event's reads into state.observationMemory, keeping the best
# level per ore across runs. Called as the event completes.
static func record_memory() -> void:
	var event_state: Variant = GameState.state["event"]
	if event_state == null or event_state.get("observations", {}).is_empty():
		return
	_store_site_memory()
	var memory: Dictionary = GameState.state.get("observationMemory", {})
	var by_obs: Dictionary = memory.get(event_state["eventId"], {})
	for id in event_state["observations"]:
		var by_ore: Dictionary = by_obs.get(id, {})
		for ore in event_state["observations"][id].get("results", {}):
			var level := int(event_state["observations"][id]["results"][ore]["level"])
			by_ore[ore] = maxi(level, int(by_ore.get(ore, 0)))
		by_obs[id] = by_ore
	memory[event_state["eventId"]] = by_obs
	GameState.state["observationMemory"] = memory


# The `observed` condition: the stored tier level for the ore is at least atLeast.
# With `event` it reads persistent memory from completed runs; without, this run.
static func observed(cond: Dictionary) -> bool:
	if cond.has("event"):
		var level := int(GameState.state.get("observationMemory", {}).get(cond["event"], {}).get(cond.get("id", ""), {}).get(cond.get("ore", ""), 0))
		return level >= int(cond.get("atLeast", 1))
	if GameState.state["event"] == null:
		return false
	var result: Dictionary = _stored(String(cond.get("id", ""))).get("results", {}).get(cond.get("ore", ""), {})
	return int(result.get("level", 0)) >= int(cond.get("atLeast", 1))


# Ores whose read currently unlocks (`requires`) or boosts (check `mods`) a choice,
# in first-seen order: each `observed` condition on the choice that holds now.
static func option_ores(choice: Dictionary) -> Array:
	var out: Array = []
	var conditions: Array = []
	var requires: Variant = choice.get("requires")
	if requires is Dictionary:
		conditions.append(requires)
	for mod in choice.get("check", {}).get("mods", []):
		conditions.append(mod)
	for cond in conditions:
		if not cond.has("observed") or not Events.condition_met(cond):
			continue
		var ore := String(cond["observed"].get("ore", ""))
		if ore != "" and not out.has(ore):
			out.append(ore)
	for ore in pick_ores(choice):
		if not out.has(ore):
			out.append(ore)
	return out


# Why an option is available or boosted, one entry per observation-driven source:
# {kind: unlock|boost|pick, ore, ore_name, obs, level, tiers, at_least, tier_text,
# add}. `unlock` = a holding `observed` in requires, `boost` = a holding `observed`
# check mod (add = its delta), `pick` = a qualifying ore of a pick option.
static func explainers(choice: Dictionary) -> Array:
	var out: Array = []
	var requires: Variant = choice.get("requires")
	if requires is Dictionary and requires.has("observed") and Events.condition_met(requires):
		out.append(_explainer("unlock", requires["observed"], 0.0))
	for mod in choice.get("check", {}).get("mods", []):
		if mod.has("observed") and Events.condition_met(mod):
			out.append(_explainer("boost", mod["observed"], float(mod.get("add", 0.0))))
	for ore in pick_ores(choice):
		var pick: Dictionary = choice["pick"]
		out.append(_explainer("pick", { "id": pick["observation"], "ore": ore, "atLeast": pick_outcome(choice, ore).get("atLeast", 1) }, 0.0))
	return out


# The one-line "why": the authored `explain` override if the option has one, else
# generated from the first explainer; "" when no observation drives the option.
static func explain_line(choice: Dictionary) -> String:
	var entries := explainers(choice)
	if entries.is_empty():
		return ""
	if choice.has("explain"):
		return String(choice["explain"])
	var texts: Dictionary = GameData.OBSERVATION["explain"]
	var first: Dictionary = entries[0]
	if first["kind"] == "pick":
		var names: Array = []
		for entry in entries:
			if entry["kind"] == "pick":
				names.append(entry["ore_name"])
		return texts["pickLine"] % ", ".join(names)
	return texts["line"] % first["tier_text"]


# The ? modal's explainer lines: per entry, observation / ore / tier reached /
# what it saw / what it did.
static func explain_modal_lines(choice: Dictionary) -> Array:
	var texts: Dictionary = GameData.OBSERVATION["explain"]
	var out: Array = []
	for entry in explainers(choice):
		out.append(texts["observation"] % entry["obs"])
		out.append(texts["ore"] % entry["ore_name"])
		if entry["tiers"] > 0:
			out.append(texts["tier"] % [entry["level"], entry["tiers"]])
		if entry["tier_text"] != "":
			out.append(texts["saw"] % entry["tier_text"])
		match entry["kind"]:
			"unlock":
				out.append(texts["unlock"] % entry["at_least"])
			"boost":
				out.append(texts["boost"] % roundi(entry["add"] * 100.0))
			"pick":
				out.append(texts["pick"] % entry["at_least"])
	return out


static func _explainer(kind: String, cond: Dictionary, add: float) -> Dictionary:
	var ore := String(cond.get("ore", ""))
	var id := String(cond.get("id", ""))
	var event_id := String(cond.get("event", ""))
	var live: Variant = GameState.state["event"]
	if event_id == "" and live != null:
		event_id = String(live["eventId"])
	var def: Dictionary = GameData.EVENTS.get(event_id, {}).get("observations", {}).get(id, {})
	var tiers: Array = def.get("blocks", {}).get(ore, {}).get("tiers", [])
	var level: int
	if cond.has("event"):
		level = int(GameState.state.get("observationMemory", {}).get(event_id, {}).get(id, {}).get(ore, 0))
	else:
		level = int(_stored(id).get("results", {}).get(ore, {}).get("level", 0))
	return {
		"kind": kind,
		"ore": ore,
		"ore_name": ore.capitalize(),
		"obs": String(def.get("name", GameData.OBSERVATION["explain"]["observationDefault"])),
		"level": level,
		"tiers": tiers.size(),
		"at_least": int(cond.get("atLeast", 1)),
		"tier_text": String(tiers[tiers.size() - level]["text"]) if level > 0 and level <= tiers.size() else "",
		"add": add,
	}


# The outcome a pick option gives for an ore: the first entry (best atLeast first)
# whose atLeast the current-run level reaches, else {}.
static func pick_outcome(choice: Dictionary, ore: String) -> Dictionary:
	var pick: Dictionary = choice.get("pick", {})
	var entries: Variant = pick.get("ores", {}).get(ore, [])
	if entries is Dictionary:
		entries = [entries]
	var level := int(_stored(String(pick.get("observation", ""))).get("results", {}).get(ore, {}).get("level", 0))
	for entry: Dictionary in entries:
		if level >= int(entry.get("atLeast", 1)):
			return entry
	return {}


# Ores a pick option can be committed with now, in oreOrder.
static func pick_ores(choice: Dictionary) -> Array:
	var out: Array = []
	if not choice.has("pick"):
		return out
	for ore in GameData.OBSERVATION["oreOrder"]:
		if not pick_outcome(choice, ore).is_empty():
			out.append(ore)
	return out


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
	out.append_array(raid_mods())
	return out


# Raid-factor mods when the live event is a vein raid (context site_id with a
# faction vein) or a stockpile raid (context faction_id); ordinary events get none.
static func raid_mods() -> Array:
	var context: Dictionary = Events._live_event_context()
	var event_state: Variant = GameState.state.get("event")
	if event_state != null and event_state["eventId"] in [Raiding.STOCKPILE_RAID_EVENT_ID, Raiding.STOCKPILE_RAID_STASH_EVENT_ID]:
		var faction_id: String = context.get("faction_id", "")
		return Raiding.stockpile_factor_mods(faction_id) if GameState.state["factions"].has(faction_id) else []
	var site_id: String = context.get("site_id", "")
	if site_id == "":
		return []
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return []
	return Raiding.raid_factor_mods(site["factionVein"])


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
