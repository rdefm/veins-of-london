extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# Raid security profile (R§3.12 "Security profile"): tier → profile, faction
# vein features, seeded site details, and the `{security}` condition.


static func _faction_vein(site_id: String, security: String, faction_id: String = "firm") -> Dictionary:
	return {
		"id": "fv_" + site_id, "factionId": faction_id, "oreType": "physics", "growth": 30,
		"security": security, "alarmUpgrades": [],
		"location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch",
		"siteId": site_id, "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0, "kit": {}, "features": { "cameras": 0, "alarm": false },
	}


# A fixture event whose card 0 jumps by fireEscape, then a card with a
# locks-gated option and a ward-modded check.
static func _install_event() -> Dictionary:
	var original: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_security_event"] = {
		"id": "test_security_event",
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Outside",
				"goto": [{ "if": { "security": { "feature": "fireEscape" } }, "card": "roof" }, { "card": "front" }] },
			{ "type": "choice", "key": "front", "label": null, "speaker": null, "text": "Door", "choices": [
				{ "label": "Pick the lock", "requires": { "security": { "feature": "locks" }, "display": "disable" }, "effects": [], "result_text": "Click." },
				{ "label": "Walk in", "requires": { "security": { "feature": "locks", "atMost": 0 }, "display": "disable" }, "effects": [], "result_text": "Open." },
				{ "label": "Creep", "check": { "base": 0.5, "mods": [{ "security": { "feature": "ward" }, "add": -0.05, "label": "Ward" }], "min": 0.0, "max": 1.0 },
					"success": { "result_text": "s", "effects": [] }, "fail": { "result_text": "f", "effects": [] } },
				{ "label": "Bluff", "requires": { "security": { "feature": "guards", "atLeast": 2 }, "display": "disable" }, "effects": [], "result_text": "Fine." },
			] },
			{ "type": "narration", "key": "roof", "label": null, "speaker": null, "text": "Roof" },
		],
		"on_complete": [],
	}
	return original


static func _start_with(profile: Dictionary) -> void:
	Events.start_event("test_security_event", { "securityProfile": profile })


# A tier's profile with no fire escape, so the fixture lands on the front card.
static func _front_profile(tier: String) -> Dictionary:
	var profile := Raiding.security_profile(_faction_vein("s1", tier))
	profile["fireEscape"] = false
	return profile


func run() -> void:
	run_case("each_tier_yields_its_profile", func():
		GameState.reset()
		var expect := {
			"none": [false, false, 0], "basic": [true, false, 0],
			"warded": [true, true, 0], "guarded": [true, true, 1],
		}
		for tier in expect:
			var p := Raiding.security_profile(_faction_vein("s1", tier))
			assert_eq([p["tier"], p["locks"], p["ward"], p["guards"]], [tier] + expect[tier], tier)
		var extra := _faction_vein("s1", "guarded")
		extra["extraGuards"] = 2
		assert_eq(Raiding.security_profile(extra)["guards"], 3, "guard count = the vein's guard count")
		var featured := _faction_vein("s1", "basic")
		featured["features"] = { "cameras": 2, "alarm": true }
		var fp := Raiding.security_profile(featured)
		assert_eq([fp["cameras"], fp["alarm"]], [2, true], "cameras and alarm come from features")
	)

	run_case("begin_raid_carries_the_profile_in_the_event_context", func():
		GameState.reset()
		var vein := _faction_vein("s1", "warded")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		Raiding.begin_raid(vein)
		var profile: Dictionary = GameState.state["event"]["context"]["securityProfile"]
		assert_eq(profile, Raiding.security_profile(vein))
		assert_eq(JSON.parse_string(JSON.stringify(profile)).size(), profile.size(), "pure data")
		GameState.state["event"] = null
	)

	run_case("site_details_stable_per_site_and_vary_between_sites", func():
		GameState.reset()
		var first := Raiding.site_details("s1")
		assert_eq(Raiding.site_details("s1"), first, "same site, same details")
		var vein := _faction_vein("s1", "basic")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		Raiding.begin_raid(vein)
		var raid_one: Dictionary = GameState.state["event"]["context"]["securityProfile"].duplicate()
		GameState.state["event"] = null
		GameState.state["world"]["timeBlocksDone"] = []
		Raiding.begin_raid(vein)
		assert_eq(GameState.state["event"]["context"]["securityProfile"], raid_one, "two raids on one site see the same profile")
		GameState.state["event"] = null
		var differs := false
		for i in 20:
			if Raiding.site_details("s%d" % (i + 2)) != first:
				differs = true
		assert_true(differs, "other sites roll their own details")
		assert_true(GameData.RAID_SECURITY["siteDetails"]["cameraZones"].has(first["cameraZone"]), "cameraZone is a listed zone")
	)

	run_case("features_rolled_at_claim", func():
		GameState.reset()
		var site := { "id": "s9", "district": "shoreditch", "tier": "fair", "oreType": "time", "bonuses": [] }
		var vein := Factions.create_faction_vein("firm", site, 30)
		var f: Dictionary = vein["features"]
		assert_true(f["cameras"] is int and f["cameras"] >= 0 and f["cameras"] <= int(GameData.RAID_SECURITY["features"]["maxCameras"]), "cameras in range")
		assert_true(f["alarm"] is bool, "alarm is a bool")
		assert_eq(Factions.roll_vein_features("firm", "time", "s9"), f, "the roll is a stable hash of game, day, site and faction")
	)

	run_case("opulence_tilts_the_features_roll", func():
		GameState.reset()
		var rich := 0
		var poor := 0
		for i in 200:
			GameState.state["factions"]["guild"]["resources"] = 5000
			var r := Factions.roll_vein_features("guild", "time", "x%d" % i)
			rich += int(r["cameras"]) + (1 if r["alarm"] else 0)
			GameState.state["factions"]["guild"]["resources"] = 0
			var p := Factions.roll_vein_features("guild", "time", "x%d" % i)
			poor += int(p["cameras"]) + (1 if p["alarm"] else 0)
		assert_true(rich > poor, "a richer faction rolls more cameras and alarms (%d vs %d)" % [rich, poor])
	)

	run_case("faction_claiming_a_player_vein_rolls_features_and_player_claim_drops_them", func():
		GameState.reset()
		var vein := _faction_vein("s1", "basic")
		vein.erase("features")
		var site := Fixtures.site_with_vein("s1", vein)
		GameState.state["world"]["sites"] = [site]
		Raiding.claim_vein("s1")
		var player_vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_true(not player_vein.has("features"), "a player vein carries no faction features")
		Raiding.transfer_player_vein_to_faction(player_vein, site, "guild")
		assert_true(site["factionVein"]["features"] is Dictionary, "a faction taking the vein rolls features")
	)

	run_case("old_save_backfills_features_and_save_round_trips_them", func():
		GameState.reset()
		var vein := _faction_vein("s1", "guarded")
		vein["features"] = { "cameras": 2, "alarm": true }
		var old := _faction_vein("s2", "basic")
		old.erase("features")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein), Fixtures.site_with_vein("s2", old)]
		var save: Dictionary = JSON.parse_string(JSON.stringify(SaveManager._saveable_state()))
		var filled := SaveManager.backfill_defaults(save)
		var sites: Array = filled["world"]["sites"]
		assert_eq([int(sites[0]["factionVein"]["features"]["cameras"]), sites[0]["factionVein"]["features"]["alarm"]], [2, true], "saved features survive")
		var expected := Factions.roll_vein_features("firm", "physics", "s2", filled)
		assert_eq(sites[1]["factionVein"]["features"], expected, "a save without features rolls them as a claim would")
	)

	run_case("security_condition_gates_an_option_with_a_named_reason", func():
		GameState.reset()
		var original := _install_event()
		_start_with(_front_profile("none"))
		Events.advance()
		assert_eq(Events.current_card().get("key"), "front")
		assert_eq(Events.option_gate(0)["display"], "disable", "no locks: pick option locked")
		assert_eq(Events.option_gate(1)["display"], "show", "no locks: walk in")
		var names: Dictionary = GameData.RAID_SECURITY["featureNames"]
		var texts: Dictionary = GameData.EVENT_CHECKS["unmet"]
		assert_eq(Events.unmet_requirement_lines(0), [texts["security"] % names["locks"]["name"]], "names the missing feature")
		assert_eq(Events.unmet_requirement_lines(3), [texts["securityAtLeast"] % [names["guards"]["name"], 2]], "a count names its bound")
		GameState.state["event"] = null
		_start_with(_front_profile("basic"))
		Events.advance()
		assert_eq(Events.option_gate(0)["display"], "show", "locks: pick option shows")
		assert_eq(Events.unmet_requirement_lines(1), [texts["security"] % names["locks"]["absent"]], "atMost 0 names the absence")
		GameState.state["event"] = null
		GameData.EVENTS = original
	)

	run_case("security_condition_adds_a_mod", func():
		GameState.reset()
		var original := _install_event()
		var check: Dictionary = GameData.EVENTS["test_security_event"]["cards"][1]["choices"][2]["check"]
		_start_with(_front_profile("basic"))
		assert_almost_eq(Events.odds_for(check)["probability"], 0.5, 0.0001, "no ward, no mod")
		GameState.state["event"] = null
		_start_with(_front_profile("warded"))
		assert_almost_eq(Events.odds_for(check)["probability"], 0.45, 0.0001, "ward mod applies")
		GameState.state["event"] = null
		GameData.EVENTS = original
	)

	run_case("security_condition_drives_a_conditional_goto", func():
		GameState.reset()
		var original := _install_event()
		var profile := Raiding.security_profile(_faction_vein("s1", "basic"))
		profile["fireEscape"] = true
		_start_with(profile)
		Events.advance()
		assert_eq(Events.current_card().get("key"), "roof", "fire escape jumps to the roof")
		GameState.state["event"] = null
		profile["fireEscape"] = false
		_start_with(profile)
		Events.advance()
		assert_eq(Events.current_card().get("key"), "front", "no fire escape falls through to the front")
		GameState.state["event"] = null
		GameData.EVENTS = original
	)

	run_case("security_is_matches_a_string_feature", func():
		GameState.reset()
		var original := _install_event()
		_start_with({ "cameraZone": "front", "tier": "warded" })
		assert_true(Events.condition_met({ "security": { "feature": "cameraZone", "is": "front" } }))
		assert_true(not Events.condition_met({ "security": { "feature": "cameraZone", "is": "back" } }))
		assert_true(Events.condition_met({ "security": { "feature": "tier", "is": "warded" } }))
		assert_true(not Events.condition_met({ "security": { "feature": "fireEscape" } }), "absent feature never holds")
		GameState.state["event"] = null
		GameData.EVENTS = original
	)
