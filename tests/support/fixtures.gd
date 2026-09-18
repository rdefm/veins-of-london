extends RefCounted

# Shared synthetic state-dict builders for tests. Static; use via
# `const Fixtures := preload("res://tests/support/fixtures.gd")`.
#   site(id, ore, tier, claimed, faction_vein, district, bonuses)  world site dict (shoreditch by default)
#   site_with_vein(id, vein)                               unclaimed shoreditch site holding a faction vein
#   player_vein(id, site_id, district, ore, growth, tier, bonuses)  claimed player vein dict
#   player_vein_with(overrides)                            default shoreditch player vein "v1", keys overridden
#   seed_vein(id, growth, ore) -> vein                     append a claimed site + its player vein to state
#   seed_faction_vein(id, growth, faction, ore) -> vein    append a site holding a real faction vein to state
#   alarmed_vein(id, district, ore)                        player vein with the "alarm" upgrade, growth 40
#   enemy(name, hp, hp_max, koed, speed, is_mugging, ability)  combat enemy dict
#   ally(name, hp, hp_max, koed, speed)                    combat ally dict
#   dial(loaded_recipe_keys, current_charge, max_charge)   tier-1 dial with the given complications loaded
#   dial_with_loaded(recipe_key, tier, charge)             impact-movement dial with one complication at detent 0
#   install_objectives(entries) -> original                swap GameData.OBJECTIVES; returns the table to restore
#   has_notification(text) -> bool                         any notification in state with exactly this text


static func site(id: String, ore_type: String, tier: String, claimed: bool = false, faction_vein: Variant = null, district: String = "shoreditch", bonuses: Array = []) -> Dictionary:
	return {
		"id": id, "district": district, "tier": tier, "oreType": ore_type,
		"bonuses": bonuses, "discoveredDay": 1, "claimed": claimed, "factionVein": faction_vein,
		"hasNaturalVein": false,
	}


static func site_with_vein(id: String, vein: Dictionary) -> Dictionary:
	return {
		"id": id, "district": "shoreditch", "tier": "fair", "oreType": vein["oreType"],
		"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
		"hasNaturalVein": false,
	}


static func player_vein(id: String, site_id: String, district: String, ore_type: String, growth: int, tier: String, bonuses: Array = []) -> Dictionary:
	return {
		"id": id, "district": district, "oreType": ore_type, "growth": growth,
		"security": "none", "alarmUpgrades": [], "location": "Test Alley",
		"claimedOnDay": 1, "siteId": site_id, "hospitability": { "tier": tier, "bonuses": bonuses },
		"rampantDays": 0,
	}


static func player_vein_with(overrides: Dictionary = {}) -> Dictionary:
	var vein := player_vein("v1", "s1", "shoreditch", "time", 20, "fair")
	for key in overrides:
		vein[key] = overrides[key]
	return vein


static func seed_vein(id: String, growth: int, ore_type: String = "life") -> Dictionary:
	var vein := player_vein(id, "site_%s" % id, "shoreditch", ore_type, growth, "fair")
	GameState.state["world"]["sites"].append(site("site_%s" % id, ore_type, "fair", true))
	GameState.state["player"]["veins"].append(vein)
	return vein


static func seed_faction_vein(id: String, growth: int, faction_id: String = "collective", ore_type: String = "life") -> Dictionary:
	var faction_site := site("site_%s" % id, ore_type, "fair")
	var vein := Factions.create_faction_vein(faction_id, faction_site, growth)
	vein["id"] = id
	faction_site["factionVein"] = vein
	GameState.state["world"]["sites"].append(faction_site)
	return vein


static func alarmed_vein(id: String, district: String, ore_type: String) -> Dictionary:
	return {
		"id": id, "siteId": "site_" + id, "district": district,
		"oreType": ore_type, "growth": 40, "security": "none",
		"alarmUpgrades": ["alarm"], "location": "Test Street",
	}


static func enemy(name: String, hp: int = 20, hp_max: int = 20, koed: bool = false, speed: int = 10, is_mugging: bool = false, ability = null) -> Dictionary:
	return {
		"name": name, "hp": hp, "hpMax": hp_max, "attackMin": 1, "attackMax": 1,
		"isMugging": is_mugging, "weapon": null, "ability": ability, "evadeChance": 0.0,
		"speed": speed, "koed": koed,
	}


static func ally(name: String, hp: int = 20, hp_max: int = 20, koed: bool = false, speed: int = 10) -> Dictionary:
	return {
		"contactId": name.to_lower(), "name": name, "hp": hp, "hpMax": hp_max,
		"attackMin": 1, "attackMax": 1, "stash": 0, "healAmount": 0, "speed": speed,
		"koed": koed,
	}


static func dial(loaded_recipe_keys: Array, current_charge: int = 3, max_charge: int = 5) -> Dictionary:
	var loaded: Array = []
	for key in loaded_recipe_keys:
		loaded.append({ "recipeKey": key, "tier": 1 })
	return {
		"level": 1, "xp": 0, "currentCharge": current_charge, "maxCharge": max_charge,
		"rechargeRate": 0, "combatRegenTurnCounter": 0, "lastRegenDay": 1,
		"capacityMax": Dial.capacity_max(1), "movement": null, "loadedComplications": loaded,
		"haftId": "stub",
	}


static func dial_with_loaded(recipe_key: String, tier: int, charge: int) -> Dictionary:
	return {
		"level": 1, "xp": 0, "currentCharge": charge, "maxCharge": 20, "rechargeRate": 2.0,
		"combatRegenTurnCounter": 0, "lastRegenDay": GameState.state["world"]["day"],
		"capacityMax": 4, "movement": { "archetype": "impact", "oreType": "time", "tier": 1 },
		"loadedComplications": [{ "recipeKey": recipe_key, "tier": tier, "detent": 0 }],
		"haftId": "collective_brolly",
	}


static func install_objectives(entries: Dictionary) -> Dictionary:
	var original: Dictionary = GameData.OBJECTIVES
	GameData.OBJECTIVES = entries.duplicate(true)
	return original


static func has_notification(text: String) -> bool:
	for n in GameState.state["notifications"]:
		if n["text"] == text:
			return true
	return false
