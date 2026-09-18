class_name DebugStart
extends RefCounted

# Debug Start (R§5): a maximal-unlock state for testing every screen/
# feature without playing the tutorial. Static funcs only.
#
# One deliberate exception to "all flags complete/true": homeRaidEventSeen
# stays false, since the home-raid trigger is pending && !seen (R§3.8) —
# forcing seen true would make R§5's own `homeRaidEventPending = true`
# clause meaningless.


static func apply() -> void:
	GameState.reset()
	var state: Dictionary = GameState.state
	var player: Dictionary = state["player"]

	player["cash"] = 1000000
	player["craftingSkill"] = 3
	# Maxed so Sites.seed_success_chance's 0.95 clamp caps prospecting odds
	# in debug play, not the skill curve — get_cult_chance(5) alone is only
	# 0.78; rich/saturated tier's seedTierMod (R§1.11) makes up the rest.
	player["cultivatingSkill"] = 5

	for ore_type in GameData.ORE_TYPES.keys():
		player["orichalchum"][ore_type] = 50

	# Seeded via Crafting.inventory_add (tier == craftingSkill above), not a
	# hand-built flat dict, since inventory is tier-bucketed. Includes a
	# handful of each combat consumable to exercise the Use buttons directly.
	var debug_items := {
		"timePearl": 5, "enhancementPowder": 3, "rewind": 1,
		"healingSalve": 2, "blast": 3, "shield": 2, "blackHole": 2, "healingBurst": 3,
	}
	for recipe_key in debug_items:
		Crafting.inventory_add(recipe_key, player["craftingSkill"], debug_items[recipe_key])

	var crowbar_id := "item_" + str(Time.get_ticks_usec())
	player["items"] = [{ "id": crowbar_id, "type": "crowbar" }]
	player["equipment"]["weapon"] = crowbar_id

	# Dial.new_dial()'s bare inert shape (no Movement, no Complications),
	# skipping attempt_seed()'s gift-gate/cost/roll like everything else in
	# this file. The player still crafts/seats a Movement themselves.
	player["dial"] = Dial.new_dial("guild_cane")

	# Each debug vein gets its own claimed site in shoreditch, since
	# MapLayout.build_stop_items only renders a vein as a Map stop when its
	# siteId points at a claimed site.
	var shoreditch_time_site := _debug_claimed_site("shoreditch", "time")
	var shoreditch_physics_site := _debug_claimed_site("shoreditch", "physics")
	var shoreditch_life_site := _debug_claimed_site("shoreditch", "life")

	# One per distinct visual state (collapsed, dormant, rampant) so every
	# growth band (R§3.4) is inspectable immediately without waiting out drift.
	player["veins"] = [
		_debug_vein("time", 0, shoreditch_time_site["id"]),
		_debug_vein("physics", 50, shoreditch_physics_site["id"]),
		_debug_vein("life", 100, shoreditch_life_site["id"]),
	]

	# M1-LONDON §D7: 2 discovered unclaimed sites — rich (greenwich) and
	# saturated (whitechapel) — so there's something to seed/claim on the
	# Map tab immediately; oreType/bonuses are fixed, not rolled, to keep
	# debug start deterministic.
	#
	# Faction-owned sites in camden/kingscross/city so real routed faction
	# lines show immediately, not just single-stop stubs: camden's 2 firm
	# sites exercise a multi-stop elbow-routed line, kingscross/city each
	# cover one more faction with a single-stop stub. Built via the real
	# claim-roll path (Factions.create_faction_vein()) rather than
	# hand-building factionVein.
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

	# seed_day_one_veins() appends directly to state["world"]["sites"], so it
	# must run after the wholesale reassignment above — this gives the
	# hand-built fixture above plus the full per-faction day-one roster a
	# real New Game gets.
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
# call (a debug vein needs a claimed site to render as a Map stop).
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
		"extraGuards": 0,
	}
