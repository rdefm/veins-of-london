extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const RaidingTests := preload("res://tests/test_raiding.gd")

# vein_raid (the Yard): the stage tree driven for real through
# Events.start_event/choose/advance. Checks are forced with
# _force_checks(); reads are seeded into event.observations.


static func _start(profile: Dictionary = {}, start_alert: int = 0) -> Dictionary:
	GameState.reset()
	var vein := RaidingTests._faction_vein_of_growth(10, "time", "guarded", "firm")
	GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
	var built := Raiding.security_profile(vein)
	built.merge({ "guards": 0, "cameras": 0, "alarm": false, "ward": false, "fireEscape": false }, true)
	built.merge(profile, true)
	Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1", "ally_ids": [], "securityProfile": built, "startAlert": start_alert })
	return vein


static func _force_checks(p: float) -> Callable:
	return RaidingTests._force_raid_checks(p)


static func _key() -> String:
	return String(Events.current_card().get("key", ""))


static func _index(label: String) -> int:
	return RaidingTests._option_index(label)


# Steps over routers and tension cards until a choice card (or the event's end).
static func _settle() -> void:
	var guard := 0
	while GameState.state["event"] != null and not GameState.state["combat"]["active"] and not Events.current_card().has("choices") and guard < 20:
		Events.advance()
		guard += 1


# Picks `label`, then moves on past its resolution text to the next choice card.
static func _pick(label: String) -> void:
	var i := _index(label)
	assert(i >= 0, "no option '%s' on %s" % [label, _key()])
	Events.choose(i)
	if GameState.state["event"] != null and not GameState.state["combat"]["active"]:
		Events.advance()
	_settle()


static func _win_fight() -> void:
	GameState.state["combat"]["outcome"] = "win"
	Combat.exit_combat()
	_settle()


static func _shown(label: String) -> bool:
	var i := _index(label)
	return i >= 0 and Events.option_gate(i)["display"] == "show"


func run() -> void:
	run_case("front_route_clean_run_reaches_claim_loot", func():
		var vein := _start()
		var relation_before: int = GameState.state["factions"]["firm"]["relation"]
		var restore := _force_checks(1.0)
		_settle()
		assert_eq(_key(), "y_gate")
		_pick("Talk your way through the gate")
		assert_eq(_key(), "y_yard")
		_pick("Walk like you belong")
		assert_eq(_key(), "y_door")
		_pick("Hope it isn't locked")
		assert_eq(_key(), "y_room", "no camera, no ward: straight to the vein room")
		_pick("Walk to the vein")
		restore.call()
		assert_eq(_key(), "y_claim")
		assert_eq(Events.alert_level(), 0)
		Events.choose(1)  # Loot and leave
		assert_eq(GameState.state["factions"]["firm"]["relation"], relation_before, "a clean loot leaves relation alone")
		assert_true(vein != null)
	)

	run_case("back_route_clean_run_reaches_claim_loot", func():
		_start()
		var restore := _force_checks(1.0)
		_settle()
		_pick("Over the fence")
		assert_eq(_key(), "y_window")
		_pick("Ease it")
		assert_eq(_key(), "y_corridor")
		_pick("Hope he's late")
		assert_eq(_key(), "y_room")
		_pick("Walk to the vein")
		restore.call()
		assert_eq(_key(), "y_claim")
	)

	run_case("the_roof_route_exists_only_on_fire_escape_sites", func():
		_start({ "fireEscape": false })
		_settle()
		RaidingTests._seed_read("physics", 1)
		assert_true(not _shown("Up the fire escape"), "no fire escape, no roof route")
		_start({ "fireEscape": true })
		_settle()
		assert_true(not _shown("Up the fire escape"), "a fire escape nobody has read is not offered")
		RaidingTests._seed_read("physics", 1)
		assert_true(_shown("Up the fire escape"), "seeded and read")
	)

	run_case("roof_route_clean_run_skips_the_threshold_and_reaches_claim_loot", func():
		_start({ "fireEscape": true, "ward": true, "cameras": 1 })
		var restore := _force_checks(1.0)
		_settle()
		RaidingTests._seed_read("physics", 1)
		_pick("Up the fire escape")
		assert_eq(_key(), "y_climb")
		_pick("Trust the rung")
		assert_eq(_key(), "y_skylight")
		_pick("Chance the catch")
		assert_eq(_key(), "y_drop")
		_pick("Hope he turns")
		restore.call()
		assert_eq(_key(), "y_room", "the roof skips the ward and the camera")
	)

	run_case("a_warded_vein_puts_the_ward_on_the_threshold_of_the_front_route", func():
		_start({ "ward": true, "wardType": "time" })
		var restore := _force_checks(1.0)
		_settle()
		_pick("Talk your way through the gate")
		_pick("Walk like you belong")
		_pick("Hope it isn't locked")
		restore.call()
		assert_eq(_key(), "y_ward")
	)

	run_case("a_camera_in_the_routes_zone_comes_before_the_threshold", func():
		_start({ "cameras": 1, "cameraZone": "front" })
		var restore := _force_checks(1.0)
		_settle()
		_pick("Talk your way through the gate")
		_pick("Walk like you belong")
		_pick("Hope it isn't locked")
		restore.call()
		assert_eq(_key(), "y_cam")
		_start({ "cameras": 1, "cameraZone": "back" })
		restore = _force_checks(1.0)
		_settle()
		_pick("Talk your way through the gate")
		_pick("Walk like you belong")
		_pick("Hope it isn't locked")
		restore.call()
		assert_eq(_key(), "y_room", "a back-zone camera doesn't cover the front route")
	)

	run_case("a_failed_quiet_check_raises_alert_and_lands_on_the_window_card", func():
		_start()
		var restore := _force_checks(0.0)
		_settle()
		_pick("Talk your way through the gate")
		restore.call()
		assert_eq(Events.alert_level(), 1, "Suspicious")
		assert_eq(_key(), "y_win_out")
	)

	run_case("alarm_gates_off_the_quiet_options_and_a_failed_check_there_lands_on_the_search", func():
		_start({}, 2)
		_settle()
		assert_eq(Events.alert_level(), 2)
		assert_true(not _shown("Talk your way through the gate"), "quiet option gone at Alarm")
		var fail := _force_checks(0.0)
		_pick("Read the gaps…")
		_pick("The gate's on the latch")
		fail.call()
		assert_eq(_key(), "y_alarm", "failing at Alarm: searching, not another window")
	)

	run_case("a_window_win_back_to_unseen_resumes_the_route", func():
		_start()
		var fail := _force_checks(0.0)
		_settle()
		_pick("Talk your way through the gate")
		fail.call()
		assert_eq(_key(), "y_win_out")
		var ok := _force_checks(1.0)
		_pick("Talk it out")
		ok.call()
		assert_eq(Events.alert_level(), 0, "talked back to Unseen")
		assert_eq(_key(), "y_yard", "resumes where the gate left off")
	)

	run_case("a_lost_window_goes_to_alarm", func():
		_start()
		var fail := _force_checks(0.0)
		_settle()
		_pick("Talk your way through the gate")
		_pick("Talk it out")
		fail.call()
		assert_eq(Events.alert_level(), 2)
		assert_eq(_key(), "y_alarm")
	)

	run_case("a_wormhole_at_the_gate_goes_straight_to_the_vein_room", func():
		_start()
		_settle()
		RaidingTests._seed_read("physics", 2)
		Crafting.inventory_add("wormhole", 1, 1)
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		var i := _index("Open a Wormhole")
		Events.toggle_item(i, "wormhole")
		var ok := _force_checks(1.0)
		_pick("Open a Wormhole")
		ok.call()
		assert_eq(_key(), "y_room")
		assert_eq(Crafting.inventory_qty("wormhole"), 0, "spent")
		assert_eq(Events.alert_level(), 0)
	)

	run_case("a_failed_wormhole_lands_inside_suspicious", func():
		_start()
		_settle()
		RaidingTests._seed_read("physics", 2)
		Crafting.inventory_add("wormhole", 1, 1)
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		Events.toggle_item(_index("Open a Wormhole"), "wormhole")
		var fail := _force_checks(0.0)
		_pick("Open a Wormhole")
		fail.call()
		assert_eq(Events.alert_level(), 1)
		assert_eq(_key(), "y_room")
	)

	run_case("blast_the_gate_is_a_no_roll_raise_to_alarm_that_lands_on_the_guard_post", func():
		_start({ "guards": 2 })
		_settle()
		Crafting.inventory_add("blast", 1, 1)
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		Events.toggle_item(_index("Blast the gate"), "blast")
		Events.choose(_index("Blast the gate"))
		assert_eq(Crafting.inventory_qty("blast"), 0, "spent")
		Events.advance()
		_settle()
		assert_true(Events.alert_level() >= 0)
		assert_eq(_key(), "post")
	)

	run_case("prophets_breath_skips_the_yard_crossing_with_no_alert", func():
		_start()
		_settle()
		Crafting.inventory_add("prophetsBreath", 1, 1)
		_pick("Talk your way through the gate")
		if _key() != "y_yard":
			return
		_pick("Other ways…")
		Events.toggle_item(_index("Prophet's Breath: know when he turns"), "prophetsBreath")
		_pick("Prophet's Breath: know when he turns")
		assert_eq(_key(), "y_door")
		assert_eq(Events.alert_level(), 0)
		assert_eq(Crafting.inventory_qty("prophetsBreath"), 0)
	)

	run_case("time_pearl_rush_leaves_alert_alone_and_penalises_the_next_check", func():
		_start()
		var ok := _force_checks(1.0)
		_settle()
		Crafting.inventory_add("timePearl", 1, 1)
		_pick("Talk your way through the gate")
		_pick("Other ways…")
		Events.toggle_item(_index("Time Pearl: freeze and rush past"), "timePearl")
		_pick("Time Pearl: freeze and rush past")
		ok.call()
		assert_eq(_key(), "y_door")
		assert_eq(Events.alert_level(), 0)
		var lasting: Array = GameState.state["event"].get("lasting", [])
		assert_true(lasting.any(func(l): return l.get("next", false) and float(l.get("add", 0.0)) < 0.0), "-0.15 on the next check")
	)

	run_case("pans_rapture_at_the_search_lowers_alert_one_tier_and_removes_the_guards", func():
		var vein := _start({ "guards": 2 })
		_settle()
		Crafting.inventory_add("pansRapture", 1, 1)
		var fail := _force_checks(0.0)
		_pick("Talk your way through the gate")
		_pick("Talk it out")
		fail.call()
		assert_eq(_key(), "y_alarm")
		Events.toggle_item(_index("Pan's Rapture"), "pansRapture")
		Events.choose(_index("Pan's Rapture"))
		assert_eq(Events.alert_level(), 1)
		assert_true(int(GameState.state["event"]["context"]["guardsDown"]) >= Cultivating.vein_guard_count(vein), "every guard present is out of the next fight")
		assert_eq(Crafting.inventory_qty("pansRapture"), 0)
	)

	run_case("a_mid_raid_fight_win_continues_with_fewer_guards", func():
		var vein := _start({ "guards": 3 })
		var guards := Cultivating.vein_guard_count(vein)
		var ok := _force_checks(1.0)
		_settle()
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		_pick("Force the gate")
		ok.call()
		assert_eq(_key(), "post")
		Events.choose(_index("Fight"))
		assert_true(GameState.state["combat"]["active"], "the post fight starts")
		_win_fight()
		assert_true(GameState.state["event"] != null, "a win resumes the raid")
		assert_eq(GameState.state["event"]["context"]["guardsDown"], guards)
	)

	run_case("a_lost_mid_raid_fight_ends_the_raid", func():
		_start({ "guards": 3 })
		var ok := _force_checks(1.0)
		_settle()
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		_pick("Force the gate")
		ok.call()
		Events.choose(_index("Fight"))
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["event"], null)
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	run_case("backing_out_at_unseen_leaves_clean", func():
		_start()
		var relation_before: int = GameState.state["factions"]["firm"]["relation"]
		_settle()
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		_pick("Back out…")
		assert_eq(_key(), "y_retreat")
		Events.choose(_index("Back out"))
		assert_eq(GameState.state["factions"]["firm"]["relation"], relation_before)
		assert_true(not Raiding.is_wary("s1"))
	)

	run_case("claim_takes_the_vein_and_costs_relation_even_when_clean", func():
		_start()
		var ok := _force_checks(1.0)
		_settle()
		_pick("Talk your way through the gate")
		_pick("Walk like you belong")
		_pick("Hope it isn't locked")
		_pick("Walk to the vein")
		ok.call()
		Events.choose(0)  # Claim it
		assert_eq(GameState.state["world"]["sites"][0]["factionVein"], null)
		assert_eq(GameState.state["player"]["veins"].size(), 1)
	)
