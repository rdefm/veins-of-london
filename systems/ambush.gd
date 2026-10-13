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


# Stable [0,1) roll for this block's action in the district.
static func _unit(district_id: String, salt: String) -> float:
	var world: Dictionary = GameState.state["world"]
	return Rng.stable_unit("ambush|%d|%d|%d|%s|%s" % [int(world["rollSeed"]), int(world["day"]), int(world["timeBlock"]), district_id, salt])


# Rolls the district's ambush chance. True when it hit and the intro event
# has started (the caller then skips anything else it would open).
static func maybe_trigger(district_id: String) -> bool:
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
