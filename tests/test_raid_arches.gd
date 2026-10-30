extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const RaidingTests := preload("res://tests/test_raiding.gd")

# raid_arches (the Arches): the stage tree driven for real through
# Events.start_event/choose/advance. Checks are forced with
# _force_checks(); reads are seeded into event.observations.

const KNOCK := "Knock: \"from next door\""


static func _start(profile: Dictionary = {}, start_alert: int = 0) -> Dictionary:
	GameState.reset()
	var vein := RaidingTests._faction_vein_of_growth(10, "time", "guarded", "firm")
	GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
	var built := Raiding.security_profile(vein)
	built.merge({ "guards": 0, "cameras": 0, "alarm": false, "ward": false, "neighbourArch": false }, true)
	built.merge(profile, true)
	Events.start_event("raid_arches", { "site_id": "s1", "ally_ids": [], "securityProfile": built, "startAlert": start_alert })
	return vein


static func _force_checks(p: float) -> Callable:
	return RaidingTests._force_raid_checks(p, "raid_arches")


static func _key() -> String:
	return String(Events.current_card().get("key", ""))


static func _index(label: String) -> int:
	return RaidingTests._option_index(label)


static func _settle() -> void:
	var guard := 0
	while GameState.state["event"] != null and not GameState.state["combat"]["active"] and not Events.current_card().has("choices") and guard < 20:
		Events.advance()
		guard += 1


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
	run_case("raid_arches_is_the_event_for_a_railway_arch_vein", func():
		GameState.reset()
		var vein := RaidingTests._faction_vein_of_growth(10, "time", "guarded", "firm")
		vein["location"] = "Stall 4, under the railway arch"
		assert_eq(Raiding.raid_event_id(vein), "raid_arches")
	)

	run_case("shutter_route_clean_run_reaches_claim_loot", func():
		var vein := _start()
		var relation_before: int = GameState.state["factions"]["firm"]["relation"]
		var restore := _force_checks(1.0)
		_settle()
		assert_eq(_key(), "a_front")
		_pick(KNOCK)
		assert_eq(_key(), "a_bench")
		_pick("Keep the story going")
		assert_eq(_key(), "a_partition")
		_pick("Hope it isn't locked")
		assert_eq(_key(), "a_room", "no camera, no ward: straight to the vein room")
		_pick("Walk to the vein")
		restore.call()
		assert_eq(_key(), "a_claim")
		assert_eq(Events.alert_level(), 0)
		Events.choose(1)  # Loot and leave
		assert_eq(GameState.state["factions"]["firm"]["relation"], relation_before, "a clean loot leaves relation alone")
		assert_true(vein != null)
	)

	run_case("neighbour_route_exists_only_on_neighbour_arch_sites_and_skips_the_threshold", func():
		_start({ "neighbourArch": false })
		_settle()
		RaidingTests._seed_read("physics", 2)
		_pick("Read the gaps…")
		assert_true(not _shown("Through the garage next door"), "no connected arch, no route")
		_start({ "neighbourArch": true, "ward": true, "cameras": 1 })
		_settle()
		_pick("Read the gaps…")
		assert_true(not _shown("Through the garage next door"), "a wall nobody has read is not offered")
		RaidingTests._seed_read("physics", 2)
		assert_true(_shown("Through the garage next door"), "seeded and read")
		var restore := _force_checks(1.0)
		_pick("Through the garage next door")
		assert_eq(_key(), "a_garage")
		_pick("Slip in while he's under a car")
		assert_eq(_key(), "a_wall")
		_pick("Work the loose blocks quiet")
		restore.call()
		assert_eq(_key(), "a_room", "the neighbour route skips the ward and the camera")
	)

	run_case("trackside_route_clean_run_skips_the_threshold_and_reaches_claim_loot", func():
		_start({ "ward": true, "cameras": 1 })
		var restore := _force_checks(1.0)
		_settle()
		RaidingTests._seed_read("physics", 1)
		_pick("Read the gaps…")
		_pick("Round the back, over the railway fence")
		assert_eq(_key(), "a_tracks")
		_pick("Hope there's no track crew tonight")
		assert_eq(_key(), "a_vent")
		_pick("Take the mesh off quiet")
		assert_eq(_key(), "a_crawl")
		_pick("Hope he turns")
		restore.call()
		assert_eq(_key(), "a_room", "the vent is past the ward")
	)

	run_case("a_warded_vein_puts_the_ward_on_the_partition", func():
		_start({ "ward": true, "wardType": "time" })
		var restore := _force_checks(1.0)
		_settle()
		_pick(KNOCK)
		_pick("Keep the story going")
		_pick("Hope it isn't locked")
		restore.call()
		assert_eq(_key(), "a_ward")
	)

	run_case("a_camera_on_the_shutter_comes_before_the_threshold", func():
		_start({ "cameras": 1 })
		var restore := _force_checks(1.0)
		_settle()
		_pick(KNOCK)
		_pick("Keep the story going")
		_pick("Hope it isn't locked")
		restore.call()
		assert_eq(_key(), "a_cam")
	)

	run_case("a_failed_quiet_check_raises_alert_and_lands_on_the_window_card", func():
		_start()
		var restore := _force_checks(0.0)
		_settle()
		_pick(KNOCK)
		restore.call()
		assert_eq(Events.alert_level(), 1, "Suspicious")
		assert_eq(_key(), "a_win_out")
	)

	run_case("a_witness_window_offers_no_fight", func():
		_start({ "neighbourArch": true })
		_settle()
		RaidingTests._seed_read("physics", 2)
		_pick("Read the gaps…")
		_pick("Through the garage next door")
		var fail := _force_checks(0.0)
		_pick("Slip in while he's under a car")
		fail.call()
		assert_eq(_key(), "a_win_wit")
		assert_eq(_index("Take him down"), -1, "incapacitating a civilian is not offered")
		assert_true(_index("Talk it out") >= 0)
	)

	run_case("alarm_gates_off_the_quiet_options_and_a_failed_check_there_lands_on_the_search", func():
		_start({}, 2)
		_settle()
		assert_true(not _shown(KNOCK), "quiet option gone at Alarm")
		_pick("Read the gaps…")
		assert_true(not _shown("Round the back, over the railway fence"))
	)

	run_case("force_and_blast_the_shutter_land_on_the_bench_post_and_carry_the_train_cover", func():
		var event: Dictionary = GameData.EVENTS["raid_arches"]
		assert_eq(event["fightPresets"]["veinGuards"]["waves"], 2, "the arch fits two at a time")
		var front3: Dictionary = {}
		for card in event["cards"]:
			if card["key"] == "a_front3":
				front3 = card
		var force_cover: Dictionary = {}
		for effect in front3["choices"][0]["success"]["effects"]:
			if effect.get("op", "") == "alert":
				force_cover = effect["cover"]
		assert_eq(force_cover["base"], 0.35)
		assert_eq(force_cover["mods"][0]["add"], 0.35, "a time read times the noise to a train")
		assert_eq(front3["choices"][0]["success"]["goto"], "post")
		_start({ "guards": 2 })
		var ok := _force_checks(1.0)
		_settle()
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		_pick("Force the shutter")
		ok.call()
		assert_eq(_key(), "post")
	)

	run_case("a_wormhole_at_the_front_goes_straight_to_the_vein_room", func():
		_start()
		_settle()
		RaidingTests._seed_read("physics", 2)
		Crafting.inventory_add("wormhole", 1, 1)
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		Events.toggle_item(_index("Open a Wormhole"), "wormhole")
		var ok := _force_checks(1.0)
		_pick("Open a Wormhole")
		ok.call()
		assert_eq(_key(), "a_room")
		assert_eq(Events.alert_level(), 0)
	)

	run_case("a_mid_raid_fight_win_continues_with_fewer_guards", func():
		var vein := _start({ "guards": 3 })
		var guards := Cultivating.vein_guard_count(vein)
		var ok := _force_checks(1.0)
		_settle()
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		_pick("Force the shutter")
		ok.call()
		assert_eq(_key(), "post")
		Events.choose(_index("Fight"))
		assert_true(GameState.state["combat"]["active"], "the post fight starts")
		_win_fight()
		assert_true(GameState.state["event"] != null, "a win resumes the raid")
		assert_eq(GameState.state["event"]["context"]["guardsDown"], guards)
		Events.advance()
		_settle()
		assert_eq(_key(), "a_partition", "the loud route resumes at the partition")
	)

	run_case("a_lost_mid_raid_fight_ends_the_raid", func():
		_start({ "guards": 3 })
		var ok := _force_checks(1.0)
		_settle()
		_pick("Read the gaps…")
		_pick("Louder, or stranger…")
		_pick("Force the shutter")
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
		assert_eq(_key(), "a_retreat")
		Events.choose(_index("Back out"))
		assert_eq(GameState.state["factions"]["firm"]["relation"], relation_before)
		assert_true(not Raiding.is_wary("s1"))
	)

	run_case("claim_takes_the_vein_and_costs_relation_even_when_clean", func():
		_start()
		var ok := _force_checks(1.0)
		_settle()
		_pick(KNOCK)
		_pick("Keep the story going")
		_pick("Hope it isn't locked")
		_pick("Walk to the vein")
		ok.call()
		Events.choose(0)  # Claim it
		assert_eq(GameState.state["world"]["sites"][0]["factionVein"], null)
		assert_eq(GameState.state["player"]["veins"].size(), 1)
	)
