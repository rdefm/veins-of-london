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
	# Maxed (not just raised) so Sites.seed_success_chance's clamp is what
	# actually caps prospecting odds in debug play, not the skill curve --
	# Cultivating.get_cult_chance(5) alone is 0.78; only rich/saturated
	# tier's +0.20/+0.35 seedTierMod pushes that up to the 0.95 ceiling.
	player["cultivatingSkill"] = 5

	for ore_type in GameData.ORE_TYPES.keys():
		player["orichalchum"][ore_type] = 50

	# ticket 64: seeded at tier == the craftingSkill just set above, via
	# Crafting.inventory_add rather than a hand-built flat dict, since
	# inventory is now tier-bucketed.
	var debug_items := {
		"timePearl": 5, "enhancementPowder": 3, "rewind": 1,
		# calc-effect-wiring-02: a handful of each newly-wired consumable so
		# the debug start actually exercises the new inventory/combat Use
		# buttons without a lab detour.
		"healingSalve": 2, "blast": 3, "shield": 2, "blackHole": 2, "healingBurst": 3,
	}
	for recipe_key in debug_items:
		Crafting.inventory_add(recipe_key, player["craftingSkill"], debug_items[recipe_key])

	var crowbar_id := "item_" + str(Time.get_ticks_usec())
	player["items"] = [{ "id": crowbar_id, "type": "crowbar" }]
	player["equipment"]["weapon"] = crowbar_id

	# Each debug vein gets its own claimed site in shoreditch so
	# MapLayout.build_stop_items — which only turns a
	# vein into a Map stop when it's tied to a claimed site the vein's own
	# siteId points at — actually renders these on the Map tab. Without this
	# linkage the 3 veins existed in player.veins but could never appear as
	# a stop, so nothing (including a map-animation event queued against
	# them) could ever resolve or be tapped.
	var shoreditch_time_site := _debug_claimed_site("shoreditch", "time")
	var shoreditch_physics_site := _debug_claimed_site("shoreditch", "physics")
	var shoreditch_life_site := _debug_claimed_site("shoreditch", "life")

	# vein-growth-state: one per distinct visual state (collapsed, dormant,
	# rampant) so every band is inspectable immediately without waiting
	# out drift (docs/REFERENCE.md §5).
	player["veins"] = [
		_debug_vein("time", 0, shoreditch_time_site["id"]),
		_debug_vein("physics", 50, shoreditch_physics_site["id"]),
		_debug_vein("life", 100, shoreditch_life_site["id"]),
	]

	# M1-LONDON D7: 2 discovered, unclaimed sites — one rich (greenwich), one
	# saturated (whitechapel) — so a debug-started game has something to
	# seed/claim on the Map tab immediately. oreType/bonuses are fixed
	# (not rolled) to keep debug start deterministic like everything else here.
	#
	# multi-faction-line-routing (Chunk 2, ticket 03): faction-owned sites in
	# camden/kingscross/city so a debug-started game shows real routed
	# faction lines on the Map tab immediately, not just single-stop
	# termini stubs — camden's 2 firm sites exercise a multi-stop
	# elbow-routed faction line; kingscross/city each cover one more faction
	# with a single-stop stub, matching the real claim-roll path
	# (Factions.create_faction_vein()) rather than hand-building factionVein.
	var camden_firm_physics_site := _debug_site("camden", "fair", "physics", [])
	var camden_firm_emotion_site := _debug_site("camden", "fair", "emotion", [])
	var kingscross_network_site := _debug_site("kingscross", "fair", "fate", [])
	var city_conclave_site := _debug_site("city", "fair", "life", [])
	camden_firm_physics_site["factionVein"] = Factions.create_faction_vein("firm", camden_firm_physics_site, GameData.VEIN_GROWTH["seedGrowth"])
	camden_firm_emotion_site["factionVein"] = Factions.create_faction_vein("firm", camden_firm_emotion_site, GameData.VEIN_GROWTH["seedGrowth"])
	kingscross_network_site["factionVein"] = Factions.create_faction_vein("network", kingscross_network_site, GameData.VEIN_GROWTH["seedGrowth"])
	city_conclave_site["factionVein"] = Factions.create_faction_vein("conclave", city_conclave_site, GameData.VEIN_GROWTH["seedGrowth"])

	state["world"]["sites"] = [
		shoreditch_time_site,
		shoreditch_physics_site,
		shoreditch_life_site,
		_debug_site("greenwich", "rich", "time", ["yield"]),
		_debug_site("whitechapel", "saturated", "emotion", ["vigour", "wildCeiling", "yield"]),
		camden_firm_physics_site,
		camden_firm_emotion_site,
		kingscross_network_site,
		city_conclave_site,
	]

	# ticket 18: seed_day_one_veins() appends directly to
	# state["world"]["sites"], so it must run after the wholesale
	# reassignment above, not before, or its output would be discarded.
	# This gives a debug-started game both the hand-built demo fixture above
	# (deliberately exercising multi-stop elbow-routed faction lines) and
	# the full per-faction day-one roster a real New Game gets, so debug
	# play isn't under-representing faction presence on the Map tab.
	Factions.seed_day_one_veins()

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

	PhoneNav.route_home()
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
		"slotIndex": Sites.next_slot_index(district),
	}


# Already-claimed counterpart to _debug_site() above, one per _debug_vein()
# call — see the veins block's own comment for why a debug vein needs one of
# these to ever render as a Map stop.
static func _debug_claimed_site(district: String, ore_type: String) -> Dictionary:
	var site := _debug_site(district, "fair", ore_type, [])
	site["claimed"] = true
	return site


static func _debug_vein(ore_type: String, growth: int, site_id: String) -> Dictionary:
	return {
		"id": Cultivating.make_vein_id(),
		"oreType": ore_type,
		"growth": growth,
		"security": "none",
		"alarmUpgrades": [],
		"location": Cultivating.generate_location_name(),
		"claimedOnDay": 1,
		"district": "shoreditch",
		"siteId": site_id,
		"hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0,
	}
