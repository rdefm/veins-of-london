class_name Ambush
extends RefCounted

# Faction ambushes (R§3.1d). After the player spends a block acting in a
# district, maybe_trigger() rolls Turf.ambush_chance(); a hit opens the
# authored intro event, whose start_faction_ambush_combat op calls
# CombatPrep.request(KIND_FACTION_AMBUSH). The roll is a keyed stable value, so
# it never draws from the global Rng stream (DistrictDeck's roll order is
# untouched) and a district with no hostile faction costs nothing.


static func _cfg() -> Dictionary:
	return GameData.TURF["ambush"]


# Stable [0,1) roll for an action in the district keyed to `block` of today
# (-1 = the current world.timeBlock).
static func _unit(district_id: String, salt: String, block: int = -1) -> float:
	var world: Dictionary = GameState.state["world"]
	if block < 0:
		block = int(world["timeBlock"])
	return Rng.stable_unit("ambush|%d|%d|%d|%s|%s" % [int(world["rollSeed"]), int(world["day"]), block, district_id, salt])


# Rolls the district's ambush chance. True when it hit and the intro event
# has started (the caller then skips anything else it would open). Never
# fires while Prophet's Breath is active (R§3.1d).
static func maybe_trigger(district_id: String) -> bool:
	if ActiveEffects.prophets_breath_active():
		return false
	var chances := Turf.ambush_chances(district_id)
	if chances.is_empty():
		return false
	if _unit(district_id, "hit") >= Turf.ambush_chance(district_id):
		return false
	var faction_id := _pick_faction(chances, _unit(district_id, "faction"))
	Events.start_or_defer(String(_cfg()["eventId"]), {
		"faction_id": faction_id,
		"faction": GameData.FACTIONS[faction_id]["shortName"],
		"district": district_id,
	})
	return true


# Districts (GameData.DISTRICTS order) where any of today's keyed rolls still
# to come (one per time block from world.timeBlock on, at the current chance)
# would hit: exactly the rolls maybe_trigger can still make today. Pure;
# changes nothing. Empty while Prophet's Breath is active, since
# maybe_trigger rolls nothing then.
static func due_today() -> Array[String]:
	var due: Array[String] = []
	if ActiveEffects.prophets_breath_active():
		return due
	for district_id in GameData.DISTRICTS:
		if Turf.ambush_chances(district_id).is_empty():
			continue
		var chance := Turf.ambush_chance(district_id)
		for block in range(int(GameState.state["world"]["timeBlock"]), TimeSystem.BLOCKS_PER_DAY):
			if _unit(district_id, "hit", block) < chance:
				due.append(district_id)
				break
	return due


# Time Lens world sight (R§1.4 Lenses): due_today() for a player with a Time
# Lens loaded at Sense >= senseGates.world; empty otherwise.
static func forewarned_today() -> Array[String]:
	if not Lenses.has("time") or not Lenses.sense_unlocked("world"):
		return [] as Array[String]
	return due_today()


# Weighted by each faction's own chance; `unit` in [0,1).
static func _pick_faction(chances: Dictionary, unit: float) -> String:
	var total := 0.0
	for chance in chances.values():
		total += float(chance)
	var roll := unit * total
	var last := ""
	for faction_id in chances:
		last = faction_id
		roll -= float(chances[faction_id])
		if roll < 0.0:
			return faction_id
	return last


# Settles a finished ambush fight. A win costs the faction's goodwill
# (winRelationHit) and answers any grudge it held; a loss hands it a grudge
# in the district the player was acting in.
static func resolve(faction_id: String, won: bool) -> void:
	if not GameState.state["factions"].has(faction_id):
		return
	if won:
		Factions.adjust_player_relation(faction_id, -int(_cfg()["winRelationHit"]))
		Grudges.answer(faction_id)
	else:
		Grudges.record(faction_id, str(GameState.state["world"].get("currentDistrict", "")))
