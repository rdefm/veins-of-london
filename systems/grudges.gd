class_name Grudges
extends RefCounted

# Grudges (R§3.1c): a successful faction raid on the player records a score
# to settle. A player raid on that faction, or a security upgrade on a vein in
# the grudge district, answers it within windowDays; an unanswered grudge
# expires into a decaying "looks soft" pressure on every faction's Threat
# toward the player (FactionAI.threat). Data: constants.json factionGrudge.
# state.grudges = { factionId: { sinceDay, siteId?, district } }
# state.grudgeEffects = { soft: [ { sinceDay } ], revenge: { siteId: untilDay } }


static func _cfg() -> Dictionary:
	return GameData.FACTION_GRUDGE


static func new_state() -> Dictionary:
	return {}


static func new_effects() -> Dictionary:
	return { "soft": [], "revenge": {} }


static func _day() -> int:
	return int(GameState.state["world"]["day"])


static func _effects() -> Dictionary:
	return GameState.state["grudgeEffects"]


static func has_grudge(faction_id: String) -> bool:
	return GameState.state["grudges"].has(faction_id)


# Records or refreshes faction_id's grudge. site_id is "" when the raid took
# no site (a loot raid).
static func record(faction_id: String, district_id: String, site_id: String = "") -> void:
	var grudge := { "sinceDay": _day(), "district": district_id }
	if site_id != "":
		grudge["siteId"] = site_id
	GameState.state["grudges"][faction_id] = grudge
	EventBus.state_changed.emit()


# The answer hook: the player acted against faction_id (a raid on it). A no-op
# without a grudge. Gives the relation gain and opens the revenge odds bonus
# on the lost site.
static func answer(faction_id: String) -> void:
	var grudges: Dictionary = GameState.state["grudges"]
	if not grudges.has(faction_id):
		return
	var grudge: Dictionary = grudges[faction_id]
	grudges.erase(faction_id)
	if grudge.has("siteId"):
		_effects()["revenge"][String(grudge["siteId"])] = _day() + int(_cfg()["revengeDays"])
	Factions.adjust_player_relation(faction_id, int(_cfg()["answerRelationGain"]))
	Notify.push(String(_cfg()["log"]["answered"]) % GameData.FACTIONS[faction_id]["shortName"], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()


# The answer hook for a security upgrade on a vein in district_id: answers
# every grudge set in that district.
static func answer_district(district_id: String) -> void:
	for faction_id in GameState.state["grudges"].keys():
		if GameState.state["grudges"][faction_id]["district"] == district_id:
			answer(faction_id)


# Odds bonus on the player's raid on site_id while a revenge window is open.
static func raid_odds_bonus(site_id: String) -> float:
	if site_id == "" or int(_effects()["revenge"].get(site_id, -1)) < _day():
		return 0.0
	return float(_cfg()["revengeOddsBonus"])


# Daily step: grudges past windowDays expire into a soft mark; spent revenge
# windows and fully decayed soft marks drop.
static func daily_tick() -> void:
	var day := _day()
	var grudges: Dictionary = GameState.state["grudges"]
	for faction_id in grudges.keys():
		if day - int(grudges[faction_id]["sinceDay"]) > int(_cfg()["windowDays"]):
			grudges.erase(faction_id)
			_effects()["soft"].append({ "sinceDay": day })
			Notify.push(String(_cfg()["log"]["expired"]) % GameData.FACTIONS[faction_id]["shortName"], Notify.CATEGORY_WARNING)
	var decay := int(_cfg()["softDecayDays"])
	_effects()["soft"] = _effects()["soft"].filter(func(mark): return day - int(mark["sinceDay"]) < decay)
	var revenge: Dictionary = _effects()["revenge"]
	for site_id in revenge.keys():
		if int(revenge[site_id]) < day:
			revenge.erase(site_id)
	EventBus.state_changed.emit()


# Extra Threat toward the player from every faction: softThreat per mark,
# decaying linearly to 0 over softDecayDays.
static func soft_pressure() -> float:
	var day := _day()
	var decay := float(_cfg()["softDecayDays"])
	var total := 0.0
	for mark in _effects()["soft"]:
		total += float(_cfg()["softThreat"]) * maxf(0.0, 1.0 - float(day - int(mark["sinceDay"])) / decay)
	return total


# District panel rows: { faction, daysLeft } for grudges set in district_id.
static func rows_for_district(district_id: String) -> Array:
	var rows := []
	for faction_id in GameState.state["grudges"].keys():
		var grudge: Dictionary = GameState.state["grudges"][faction_id]
		if grudge["district"] == district_id:
			rows.append({ "faction": faction_id, "daysLeft": maxi(0, int(_cfg()["windowDays"]) - (_day() - int(grudge["sinceDay"]))) })
	return rows
