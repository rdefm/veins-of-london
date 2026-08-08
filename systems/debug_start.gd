class_name DebugStart
extends RefCounted

# Debug Start (R§5): a maximal-unlock state for testing every screen/
# feature without playing the tutorial. Static funcs only.
#
# One deliberate exception to "all flags complete/true": homeRaidEventSeen
# stays false. R§5 calls out `homeRaidEventPending = true` as its own
# trailing clause, separate from "all flags complete" — the only way that
# clause means anything is if homeRaidEventSeen is NOT also forced true
# (the trigger is pending && !seen, per R§3.8). The HTML's own debug
# start makes this exact same carve-out, with a comment explaining why.


static func apply() -> void:
	GameState.reset()
	var state: Dictionary = GameState.state
	var player: Dictionary = state["player"]

	player["cash"] = 1000000
	player["craftingSkill"] = 3
	player["cultivatingSkill"] = 2

	for ore_type in GameData.ORE_TYPES.keys():
		player["orichalchum"][ore_type] = 100

	player["inventory"] = { "timePearl": 5, "enhancementPowder": 3, "rewind": 1 }

	var crowbar_id := "item_" + str(Time.get_ticks_usec())
	player["items"] = [{ "id": crowbar_id, "type": "crowbar" }]
	player["equipment"]["weapon"] = crowbar_id

	# Each debug vein gets its own claimed site in shoreditch (siteCap 3, so
	# exactly fills it) so MapLayout.build_stop_items — which only turns a
	# vein into a Map stop when it's tied to a claimed site the vein's own
	# siteId points at — actually renders these on the Map tab. Without this
	# linkage the 3 veins existed in player.veins but could never appear as
	# a stop, so nothing (including a map-animation event queued against
	# them) could ever resolve or be tapped.
	var shoreditch_time_site := _debug_claimed_site("shoreditch", "time")
	var shoreditch_physics_site := _debug_claimed_site("shoreditch", "physics")
	var shoreditch_life_site := _debug_claimed_site("shoreditch", "life")

	player["veins"] = [
		_debug_vein("time", 3, shoreditch_time_site["id"]),
		_debug_vein("physics", 1, shoreditch_physics_site["id"]),
		_debug_vein("life", 5, shoreditch_life_site["id"]),
	]

	# M1-LONDON D7: 2 discovered, unclaimed sites — one rich (greenwich), one
	# saturated (whitechapel) — so a debug-started game has something to
	# seed/claim on the Map tab immediately. oreType/bonuses are fixed
	# (not rolled) to keep debug start deterministic like everything else here.
	state["world"]["sites"] = [
		shoreditch_time_site,
		shoreditch_physics_site,
		shoreditch_life_site,
		_debug_site("greenwich", "rich", "time", ["yield"]),
		_debug_site("whitechapel", "saturated", "emotion", ["recharge", "maxLevel", "yield"]),
	]

	var flags: Dictionary = state["flags"]
	for key in flags.keys():
		match typeof(flags[key]):
			TYPE_BOOL:
				flags[key] = true
			_:
				pass  # tutorialStage (String) and consSoldCount (int) handled below
	flags["tutorialStage"] = "free"
	flags["consSoldCount"] = 5
	flags["homeRaidEventSeen"] = false  # see the comment at the top of this file
	flags["homeRaidEventPending"] = true

	var home: Dictionary = state["home"]
	home["tier"] = "townhouse"
	home["rooms"] = ["workshop", "homeGym"]
	home["security"] = ["lock", "cameras"]

	var contacts: Dictionary = state["contacts"]
	contacts["archie"]["relation"] = 60
	contacts["james"]["unlocked"] = true
	contacts["james"]["relation"] = 40

	var factions: Dictionary = state["factions"]
	factions["guild"]["joined"] = true
	factions["guild"]["relation"] = GameData.FACTIONS["guild"]["joinRelation"]
	factions["collective"]["relation"] = 25
	factions["firm"]["relation"] = 15

	var barometer: Dictionary = state["barometer"]
	barometer["economic"] = "boom"
	barometer["social"] = "stable"
	barometer["political"] = "war"
	Barometer.ensure_progress()

	Nav.go_to("home")
	EventBus.state_changed.emit()


static func _debug_site(district: String, tier: String, ore_type: String, bonuses: Array) -> Dictionary:
	return {
		"id": Sites.make_site_id(),
		"district": district,
		"tier": tier,
		"oreType": ore_type,
		"bonuses": bonuses,
		"discoveredDay": GameState.state["world"]["day"],
		"claimed": false,
		"factionVein": null,
		"hasNaturalVein": false,
	}


# Already-claimed counterpart to _debug_site() above, one per _debug_vein()
# call — see the veins block's own comment for why a debug vein needs one of
# these to ever render as a Map stop.
static func _debug_claimed_site(district: String, ore_type: String) -> Dictionary:
	var site := _debug_site(district, "fair", ore_type, [])
	site["claimed"] = true
	return site


static func _debug_vein(ore_type: String, level: int, site_id: String) -> Dictionary:
	var level_data: Dictionary = GameData.VEIN_LEVELS[str(level)]
	var recharge_blocks: int = level_data["rechargeBlocks"]
	return {
		"id": Cultivating.make_vein_id(),
		"oreType": ore_type,
		"level": level,
		"levelLabel": level_data["label"],
		"devBar": GameState.round_epsilon(level_data["devBarMax"] * 0.5),
		"charged": true,
		"chargeBlocks": recharge_blocks,
		"security": "none",
		"location": Cultivating.generate_location_name(),
		"claimedOnDay": 1,
		"district": "shoreditch",
		"siteId": site_id,
		"hospitability": { "tier": "fair", "bonuses": [] },
	}
