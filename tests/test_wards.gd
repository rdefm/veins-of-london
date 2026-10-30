extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# Wards (R§3.12 "Wards"): ward type from the owner's primaryOre, the
# ward_trigger op, Powder power vs freeze, and Prophet's Breath on the read.


static func _faction_vein(site_id: String, security: String, faction_id: String) -> Dictionary:
	return {
		"id": "fv_" + site_id, "factionId": faction_id, "oreType": "time", "growth": 30,
		"security": security, "alarmUpgrades": [],
		"location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch",
		"siteId": site_id, "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0, "kit": {}, "features": { "cameras": 0, "alarm": false },
	}


# A live vein_raid on a `faction_id` vein at `security`, its profile in context.
static func _start_raid(security: String, faction_id: String) -> Dictionary:
	var vein := _faction_vein("s1", security, faction_id)
	Factions.sync_ward(vein)
	GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
	Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1", "securityProfile": Raiding.security_profile(vein) })
	return vein


# Card 0 outside (observe "look": one fate block that can't hit, ward line on
# fate 1); card 1 the ward (Powder slip check at `p`, fail triggers); card 2 a
# plain check; card 3 the end.
static func _install_event(p: float) -> Dictionary:
	var original: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_ward_event"] = {
		"id": "test_ward_event",
		"observations": { "look": {
			"mods": [],
			"ward": { "ore": "fate", "atLeast": 1 },
			"blocks": { "fate": { "miss": "Nothing.", "tiers": [{ "base": 0.0, "min": 0.0, "max": 0.0, "text": "A ward." }] } },
		} },
		"cards": [
			{ "type": "narration", "key": "outside", "label": null, "speaker": null, "text": "Outside", "observe": "look" },
			{ "type": "choice", "key": "ward", "label": null, "speaker": null, "text": "The threshold.", "choices": [
				{ "id": "slip", "label": "Slip it",
					"check": { "base": p, "min": p, "max": p, "mods": [
						{ "item": "enhancementPowder", "optional": true, "label": "Powder", "effect": { "kind": "wardPass", "nextCheck": { "add": 0.15 } } },
					] },
					"success": { "result_text": "Through.", "effects": [] },
					"fail": { "result_text": "It bites.", "effects": [{ "op": "ward_trigger" }] } },
			] },
			{ "type": "choice", "key": "window", "label": null, "speaker": null, "text": "Someone looks up.", "choices": [
				{ "id": "talk", "label": "Talk", "check": { "base": 0.5, "mods": [], "min": 0.0, "max": 1.0 },
					"success": { "result_text": "s", "effects": [] }, "fail": { "result_text": "f", "effects": [] } },
			] },
			{ "type": "narration", "key": "end", "label": null, "speaker": null, "text": "End" },
		],
		"on_complete": [],
	}
	return original


static func _start_event(ward_type: String) -> void:
	Events.start_event("test_ward_event", { "securityProfile": { "ward": ward_type != "", "wardType": ward_type } })


func run() -> void:
	run_case("guild_warded_vein_gets_a_time_ward_others_generic", func():
		GameState.reset()
		var guild := _faction_vein("s1", "warded", "guild")
		Factions.sync_ward(guild)
		assert_eq(guild["features"].get("ward"), "time", "Guild primaryOre time -> time ward")
		for faction_id in ["collective", "firm", "network", "conclave"]:
			var v := _faction_vein("s1", "guarded", faction_id)
			Factions.sync_ward(v)
			assert_eq(v["features"].get("ward"), "generic", "%s lays the generic ward" % faction_id)
		var basic := _faction_vein("s1", "basic", "guild")
		Factions.sync_ward(basic)
		assert_true(not basic["features"].has("ward"), "below warded, no ward")
		assert_eq(Raiding.security_profile(guild)["wardType"], "time", "the profile carries the ward type")
		assert_eq(Raiding.security_profile(basic)["wardType"], "", "no ward, no type")
		for i in 12:
			var site := { "id": "c%d" % i, "district": "shoreditch", "tier": "fair", "oreType": "time", "bonuses": [] }
			var made := Factions.create_faction_vein("guild", site, 30)
			var warded: bool = Cultivating.VEIN_SECURITY_ORDER.find(made["security"]) >= Cultivating.VEIN_SECURITY_ORDER.find("warded")
			assert_eq(made["features"].get("ward", ""), "time" if warded else "", "claim lays a ward only on warded+ (%s)" % made["security"])
	)

	run_case("trigger_raises_alert_and_freezes_the_player_in_a_following_fight", func():
		GameState.reset()
		_start_raid("guarded", "guild")
		Events.apply_effects([{ "op": "ward_trigger" }])
		assert_eq(Events.alert_level(), 1, "the trigger raises alert to Suspicious")
		Events._start_raid_combat({ "preset": "veinGuards" })
		var cp: Dictionary = GameState.state["combat"]
		assert_eq(int(cp["situational"].get("playerFrozen", 0)), 2, "the player starts frozen for the ward's 2 rounds")
		var frozen: Array = cp["log"].filter(func(b): return b["kind"] == "frozen" and b["actor"] == CombatRounds.PLAYER_INDEX)
		assert_eq(frozen.size(), 2, "the first two actions pass frozen")
	)

	run_case("generic_ward_only_raises_alert_and_no_ward_does_nothing", func():
		GameState.reset()
		_start_raid("guarded", "firm")
		Events.apply_effects([{ "op": "ward_trigger" }])
		assert_eq(Events.alert_level(), 1)
		Events._start_raid_combat({ "preset": "veinGuards" })
		assert_true(not GameState.state["combat"]["situational"].has("playerFrozen"), "a generic ward freezes nobody")
		GameState.reset()
		_start_raid("basic", "guild")
		Events.apply_effects([{ "op": "ward_trigger" }])
		assert_eq(Events.alert_level(), 0, "no ward, no trigger")
	)

	run_case("an_untriggered_ward_starts_a_normal_fight", func():
		GameState.reset()
		_start_raid("guarded", "guild")
		Events._start_raid_combat({ "preset": "veinGuards" })
		assert_true(not GameState.state["combat"]["situational"].has("playerFrozen"))
	)

	run_case("powder_t3_passes_a_time_ward_with_no_alert", func():
		GameState.reset()
		var original := _install_event(0.0)
		GameState.state["player"]["inventory"]["enhancementPowder"] = { "3": 1 }
		_start_event("time")
		Events.advance()
		Events.toggle_item(0, "enhancementPowder")
		Events.choose(0)
		assert_eq(Events.alert_level(), 0, "power 2 >= freeze 2: the failed roll's trigger is skipped")
		assert_eq(Crafting.inventory_qty("enhancementPowder"), 0, "spent")
		assert_true(not GameState.state["event"].has("wardTrigger"))
		assert_true(GameState.state["event"].get("lasting", []).is_empty(), "no window bonus when through")
		GameData.EVENTS = original
	)

	run_case("powder_t1_still_triggers_and_the_next_check_gets_the_bonus", func():
		GameState.reset()
		var original := _install_event(1.0)
		GameState.state["player"]["inventory"]["enhancementPowder"] = { "1": 1 }
		_start_event("time")
		Events.advance()
		Events.toggle_item(0, "enhancementPowder")
		Events.choose(0)
		assert_eq(Events.alert_level(), 1, "power 1 < freeze 2: triggers even on a passed roll")
		var lasting: Array = GameState.state["event"].get("lasting", [])
		assert_eq(lasting.size(), 1)
		assert_true(lasting[0]["next"] and is_equal_approx(float(lasting[0]["add"]), 0.15), "the window card gets the Powder bonus")
		GameData.EVENTS = original
	)

	run_case("prophets_breath_read_reveals_the_ward_on_a_failed_roll_and_is_spent", func():
		GameState.reset()
		var original := _install_event(0.5)
		_start_event("time")
		Observation.read()
		assert_eq(Observation.ward_line("look"), {}, "a missed fate read doesn't see the ward")
		GameState.reset()
		GameState.state["player"]["inventory"]["prophetsBreath"] = { "1": 2 }
		_start_event("time")
		assert_true(Observation.toggle_reveal()["ok"])
		assert_true(Observation.reveal_toggle()["on"])
		var rows := Observation.read()
		assert_true(not rows[0]["hit"], "the roll still missed")
		var line := Observation.ward_line("look")
		assert_eq(line.get("name"), GameData.WARDS["types"]["time"]["name"], "type revealed")
		assert_eq(line.get("effect"), GameData.WARDS["types"]["time"]["effect"], "effect revealed")
		assert_eq(Crafting.inventory_qty("prophetsBreath"), 1, "spent on the read")
		assert_eq(Observation.reveal_toggle(), {}, "nothing left to buy on a revealed read")
		GameData.EVENTS = original
	)

	run_case("no_reveal_toggle_without_a_ward", func():
		GameState.reset()
		var original := _install_event(0.5)
		GameState.state["player"]["inventory"]["prophetsBreath"] = { "1": 1 }
		_start_event("")
		assert_eq(Observation.reveal_toggle(), {})
		GameData.EVENTS = original
	)

	run_case("rewind_refunds_the_breath_and_its_reveal", func():
		GameState.reset()
		var original := _install_event(0.5)
		GameState.state["player"]["inventory"]["prophetsBreath"] = { "1": 1 }
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		_start_event("time")
		Events.advance()
		Observation.toggle_reveal()
		Observation.read()
		assert_eq(Crafting.inventory_qty("prophetsBreath"), 0)
		assert_true(Events.rewind()["ok"])
		assert_eq(Crafting.inventory_qty("prophetsBreath"), 1, "Rewind refunds the Breath")
		assert_eq(Observation.ward_line("look"), {}, "and the reveal it bought")
		assert_true(not Observation.reveal_toggle().is_empty(), "the re-armed read can take it again")
		GameData.EVENTS = original
	)

	run_case("ward_data_validates", func():
		var t := GameData.snapshot()
		assert_eq(GameData.validate_tables(t).filter(func(e: String) -> bool: return e.begins_with("wards")), [], "shipped wards.json is clean")
		var bad: Dictionary = GameData.WARDS.duplicate(true)
		bad["types"]["time"]["fightStart"]["nope"] = 1
		bad["types"]["time"]["onTrigger"].append({ "op": "nope" })
		t["wards"] = bad
		var errors := GameData.validate_tables(t).filter(func(e: String) -> bool: return e.begins_with("wards"))
		assert_eq(errors.size(), 2, str(errors))
	)
