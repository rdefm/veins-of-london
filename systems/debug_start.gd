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
		player["orichalchum"][ore_type] = 20

	player["inventory"] = { "timePearl": 5, "enhancementPowder": 3, "rewind": 1 }

	var crowbar_id := "item_" + str(Time.get_ticks_usec())
	player["items"] = [{ "id": crowbar_id, "type": "crowbar" }]
	player["equipment"]["weapon"] = crowbar_id

	player["veins"] = [
		_debug_vein("time", 3),
		_debug_vein("physics", 1),
		_debug_vein("life", 5),
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


static func _debug_vein(ore_type: String, level: int) -> Dictionary:
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
		"hospitability": { "tier": "fair", "bonuses": [] },
	}
