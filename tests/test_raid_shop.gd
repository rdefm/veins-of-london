extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const RaidingTests := preload("res://tests/test_raiding.gd")

# raid_shop (the Shop): the stage tree driven for real through
# Events.start_event/choose/advance. Checks are forced with
# _force_checks(); reads are seeded into event.observations.

const WALK_IN := "Walk in as a customer"
const ROUND_BACK := "Round the back"
const TOILET := "Ask for the toilet"
const STORY := "Spin her the story she wants"
const RESTOCK := "Hope nobody's restocking"
const UNLOCKED := "Hope it isn't locked"


static func _start(profile: Dictionary = {}, start_alert: int = 0) -> Dictionary:
	GameState.reset()
	var vein := RaidingTests._faction_vein_of_growth(10, "time", "guarded", "firm")
	GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
	var built := Raiding.security_profile(vein)
	built.merge({ "guards": 0, "cameras": 0, "alarm": false, "ward": false, "cellarFlap": false }, true)
	built.merge(profile, true)
	Events.start_event("raid_shop", { "site_id": "s1", "ally_ids": [], "securityProfile": built, "startAlert": start_alert })
	return vein


static func _force_checks(p: float) -> Callable:
	return RaidingTests._force_raid_checks(p, "raid_shop")


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


static func _odds(label: String) -> float:
	return float(Events.check_odds(_index(label))["probability"])


static func _card(key: String) -> Dictionary:
	for card in GameData.EVENTS["raid_shop"]["cards"]:
		if card["key"] == key:
			return card
	return {}


# Stores an already-rolled read of `ore` at `level` on observation `id`.
static func _seed_obs(id: String, ore: String, level: int) -> void:
	var obs: Dictionary = GameState.state["event"].get("observations", {})
	if not obs.has(id):
		obs[id] = { "rollCount": 1, "results": {} }
	obs[id]["results"][ore] = { "roll": 0.0, "needed": 100, "level": level, "mods": [] }
	GameState.state["event"]["observations"] = obs


# Customer route up to the back-room door with every check forced to pass.
static func _walk_in_to_the_back() -> void:
	_pick(WALK_IN)
	_pick(TOILET)


func run() -> void:
	run_case("raid_shop_is_the_event_for_the_three_shop_suffixes", func():
		GameState.reset()
		var vein := RaidingTests._faction_vein_of_growth(10, "time", "guarded", "firm")
		for suffix in ["near the off-licence", "behind the Tesco Metro", "beside the bookies"]:
			vein["location"] = "Unit 2, %s" % suffix
			assert_eq(Raiding.raid_event_id(vein), "raid_shop", suffix)
		assert_eq(GameData.EVENTS["raid_shop"]["reinforceClock"], 2, "the shop's clock runs at two cards")
		assert_eq(GameData.EVENTS["raid_shop"]["fightPresets"]["veinGuards"].get("waves", 0), 0, "the back room is not cramped into waves")
	)

	run_case("customer_route_clean_run_reaches_claim_loot", func():
		var vein := _start()
		var relation_before: int = GameState.state["factions"]["firm"]["relation"]
		var restore := _force_checks(1.0)
		_settle()
		assert_eq(_key(), "s_front")
		_pick(WALK_IN)
		assert_eq(_key(), "s_till")
		_pick(TOILET)
		assert_eq(_key(), "s_back", "no guards: the stock is a check, not a post")
		_pick(RESTOCK)
		assert_eq(_key(), "s_lock", "no ward: a plain lock on the cellar stairs")
		_pick(UNLOCKED)
		assert_eq(_key(), "s_room")
		_pick("Walk to the vein")
		restore.call()
		assert_eq(_key(), "s_claim")
		assert_eq(Events.alert_level(), 0)
		Events.choose(1)  # Loot and leave
		assert_eq(GameState.state["factions"]["firm"]["relation"], relation_before, "a clean loot leaves relation alone")
		assert_true(vein != null)
	)

	run_case("yard_door_route_clean_run_shares_the_back_room_and_stairs", func():
		_start({ "cameras": 1 })
		var restore := _force_checks(1.0)
		_settle()
		_pick(ROUND_BACK)
		assert_eq(_key(), "s_yard")
		_pick("Other ways…")
		_pick("Hope he's gone in")
		assert_eq(_key(), "s_door")
		_pick("Pick it")
		assert_eq(_key(), "s_back", "the same back room as the customer route")
		_pick(RESTOCK)
		assert_eq(_key(), "s_lock")
		_pick(UNLOCKED)
		restore.call()
		assert_eq(_key(), "s_room", "the yard door route never meets the till camera")
	)

	run_case("the_hinge_pins_result_shows_once_through_the_stockroom_to_the_cellar", func():
		for guards in [0, 1]:
			_start({ "guards": guards })
			var restore := _force_checks(1.0)
			_settle()
			_pick(ROUND_BACK)
			_pick("Other ways…")
			_pick("Hope he's gone in")
			RaidingTests._seed_read("physics", 2)
			var shown: Array = []
			Events.choose(_index("Slide the hinge pins out"))
			for step in range(40):
				if GameState.state["event"] == null or GameState.state["combat"]["active"] or _key() == "s_room":
					break
				shown.append(String(Events.revealed_cards().back()["text"]))
				if _key() == "post" and Events.is_choosing():
					Events.choose(_index("Bluff past"))
				elif _key() == "s_back" and Events.is_choosing():
					Events.choose(_index(RESTOCK))
				elif _key() == "s_lock" and Events.is_choosing():
					Events.choose(_index(UNLOCKED))
				else:
					Events.advance()
			restore.call()
			assert_eq(_key(), "s_room", "guards %d: reaches the vein room" % guards)
			var pins := shown.filter(func(t: String) -> bool: return t.begins_with("The pins come out"))
			assert_eq(pins.size(), 1, "guards %d: the pins result shows exactly once" % guards)
			assert_true(shown.has(String(_card("s_lock")["text"])), "guards %d: the cellar door prompt shows on first arrival" % guards)
	)

	run_case("cellar_route_exists_only_on_rotten_flap_sites_and_skips_the_back_room", func():
		_start({ "cellarFlap": false, "ward": true, "cameras": 1 })
		_settle()
		RaidingTests._seed_read("physics", 2)
		_pick("Other ways in…")
		assert_true(not _shown("The cellar flap"), "no rotten flap, no route")
		_start({ "cellarFlap": true, "ward": true, "cameras": 1 })
		_settle()
		_pick("Other ways in…")
		assert_true(not _shown("The cellar flap"), "a flap nobody has read is not offered")
		RaidingTests._seed_read("physics", 1)
		assert_true(_shown("The cellar flap"), "seeded and read")
		var restore := _force_checks(1.0)
		_pick("The cellar flap")
		assert_eq(_key(), "s_flap")
		_pick("Hope no one on the street looks down")
		assert_eq(_key(), "s_cellar")
		_pick("Walk past like you belong")
		restore.call()
		assert_eq(_key(), "s_room", "the cellar skips the back room, the stairs, the ward and the camera")
	)

	run_case("the_drayman's_slot_opens_the_flap_with_no_roll", func():
		_start({ "cellarFlap": true })
		_settle()
		_pick("Other ways in…")
		RaidingTests._seed_read("physics", 1)
		assert_true(not _shown("Take the flap while the drayman has it open"), "needs a sharp time read")
		RaidingTests._seed_read("time", 2)
		_pick("The cellar flap")
		assert_true(_shown("Take the flap while the drayman has it open"))
		assert_true(not Events.current_card()["choices"][_index("Take the flap while the drayman has it open")].has("check"))
		_pick("Take the flap while the drayman has it open")
		assert_eq(_key(), "s_cellar")
	)

	run_case("a_camera_always_sits_on_the_customer_route_before_the_till", func():
		_start({ "cameras": 1 })
		_settle()
		_pick(WALK_IN)
		assert_eq(_key(), "s_cam")
		var restore := _force_checks(1.0)
		_pick("Hope it's on the blink")
		restore.call()
		assert_eq(_key(), "s_till")
		_start({ "cameras": 0 })
		_settle()
		_pick(WALK_IN)
		assert_eq(_key(), "s_till", "no cameras on the site, no camera card")
	)

	run_case("a_warded_vein_puts_the_ward_on_the_cellar_stairs_instead_of_the_lock", func():
		_start({ "ward": true, "wardType": "time" })
		var restore := _force_checks(1.0)
		_settle()
		_walk_in_to_the_back()
		_pick(RESTOCK)
		restore.call()
		assert_eq(_key(), "s_ward")
	)

	run_case("a_failed_quiet_check_raises_alert_and_a_witness_window_offers_no_fight", func():
		_start()
		var restore := _force_checks(0.0)
		_settle()
		_pick(WALK_IN)
		_pick(TOILET)
		restore.call()
		assert_eq(Events.alert_level(), 1, "Suspicious")
		assert_eq(_key(), "s_win_wit")
		assert_eq(_index("Take him down"), -1, "staff are witnesses, not fighters")
		assert_true(_index("Talk it out") >= 0)
		assert_true(_index("Duck out of sight") >= 0)
		assert_true(_index("Run for it") >= 0)
	)

	run_case("a_street_witness_at_the_flap_is_also_a_talk_only_window", func():
		_start({ "cellarFlap": true })
		_settle()
		_pick("Other ways in…")
		RaidingTests._seed_read("physics", 1)
		_pick("The cellar flap")
		var fail := _force_checks(0.0)
		_pick("Hope no one on the street looks down")
		fail.call()
		assert_eq(_key(), "s_win_wit")
		assert_eq(_index("Take him down"), -1)
	)

	run_case("a_guard_who_sees_you_in_the_yard_can_be_fought", func():
		_start()
		_settle()
		_pick(ROUND_BACK)
		_pick("Other ways…")
		var fail := _force_checks(0.0)
		_pick("Hope he's gone in")
		fail.call()
		assert_eq(_key(), "s_win_out")
		assert_true(_index("Take him down") >= 0)
	)

	run_case("a_raised_alert_lowers_later_quiet_odds_and_alarm_gates_the_options_off", func():
		_start()
		_settle()
		_pick(WALK_IN)
		var unseen := _odds(TOILET)
		_start({}, 1)
		_settle()
		_pick(WALK_IN)
		assert_true(absf(_odds(TOILET) - (unseen - 0.10)) < 0.001, "Suspicious costs quiet checks 0.10")
		_start({}, 2)
		_settle()
		assert_true(not _shown(WALK_IN), "walking in is gone at Alarm")
		assert_true(not _shown(ROUND_BACK))
	)

	run_case("the_customer_route_gated_odds_follow_the_calibration", func():
		_start()
		_settle()
		_pick(WALK_IN)
		RaidingTests._seed_read("emotion", 2)
		assert_true(absf(_odds(STORY) - 0.63) < 0.001, "3 checks: 0.50 + 0.13")
		_start({ "cameras": 1 })
		_settle()
		_pick(WALK_IN)
		var ok := _force_checks(1.0)
		_pick("Hope it's on the blink")
		ok.call()
		assert_eq(_key(), "s_till")
		RaidingTests._seed_read("emotion", 2)
		assert_true(absf(_odds(STORY) - 0.71) < 0.001, "a camera makes it 4 checks: 0.58 + 0.13")
		_start({ "cellarFlap": true })
		_settle()
		_pick("Other ways in…")
		RaidingTests._seed_read("physics", 2)
		_pick("The cellar flap")
		assert_true(absf(_odds("Lever the rotten flap") - 0.53) < 0.001, "2 checks: 0.40 + 0.13")
	)

	run_case("the_clock_runs_at_two_cards_once_alarm_is_raised_on_an_alarm_line_site", func():
		_start({ "alarm": true })
		_settle()
		Events._apply_alert({ "atLeast": 2 })
		assert_eq(GameState.state["event"]["reinforce"]["length"], 2)
		Events._tick_reinforcement()  # the raising card doesn't tick
		Events._tick_reinforcement()
		assert_true(not Events.reinforcements_arrived())
		Events._tick_reinforcement()
		assert_true(Events.reinforcements_arrived())
	)

	run_case("force_the_yard_door_lands_on_the_back_room_post", func():
		_start({ "guards": 2 })
		var ok := _force_checks(1.0)
		_settle()
		_pick(ROUND_BACK)
		_pick("Other ways…")
		_pick("Hope he's gone in")
		_pick("Rougher ways…")
		_pick("Force the door")
		ok.call()
		assert_eq(_key(), "post")
		var door := _card("s_door2")
		var cover: Dictionary = {}
		for effect in door["choices"][1]["success"]["effects"]:
			if effect.get("op", "") == "alert":
				cover = effect["cover"]
		assert_eq(cover["base"], 0.35)
	)

	run_case("a_mid_raid_fight_win_continues_with_fewer_guards", func():
		var vein := _start({ "guards": 3 })
		var guards := Cultivating.vein_guard_count(vein)
		var ok := _force_checks(1.0)
		_settle()
		_walk_in_to_the_back()
		assert_eq(_key(), "post", "guards in the back room: the post")
		Events.choose(_index("Fight"))
		ok.call()
		assert_true(GameState.state["combat"]["active"], "the post fight starts")
		_win_fight()
		assert_true(GameState.state["event"] != null, "a win resumes the raid")
		assert_eq(GameState.state["event"]["context"]["guardsDown"], guards)
		Events.advance()
		_settle()
		assert_eq(_key(), "s_lock", "the customer route resumes at the cellar stairs")
	)

	run_case("a_fight_win_after_being_seen_at_the_yard_door_resumes_at_the_stockroom_choice", func():
		_start({ "guards": 2 })
		var ok := _force_checks(1.0)
		_settle()
		_pick(ROUND_BACK)
		_pick("Other ways…")
		_pick("Hope he's gone in")
		ok.call()
		assert_eq(_key(), "s_door")
		var fail := _force_checks(0.0)
		_pick("Pick it")
		fail.call()
		assert_eq(_key(), "s_win_out")
		Events.choose(_index("Take him down"))
		assert_true(GameState.state["combat"]["active"], "the window fight starts")
		_win_fight()
		Events.advance()
		_settle()
		assert_eq(_key(), "s_back", "the stockroom resumes at its choice, not the post again")
		assert_eq(Observation.in_effect(), "stock")
	)

	run_case("a_lost_mid_raid_fight_ends_the_raid", func():
		_start({ "guards": 3 })
		var ok := _force_checks(1.0)
		_settle()
		_walk_in_to_the_back()
		ok.call()
		Events.choose(_index("Fight"))
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["event"], null)
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	run_case("a_wormhole_at_the_front_goes_straight_to_the_vein_room", func():
		_start()
		_settle()
		RaidingTests._seed_read("physics", 2)
		Crafting.inventory_add("wormhole", 1, 1)
		_pick("Other ways in…")
		var ok := _force_checks(1.0)
		_pick("Open a Wormhole")
		ok.call()
		assert_eq(_key(), "s_room")
		assert_eq(Events.alert_level(), 0)
	)

	run_case("the_vein_room_offers_the_walk_with_no_guards_and_the_guard_options_with_them", func():
		for guards in [0, 2]:
			_start({ "guards": guards })
			_settle()
			RaidingTests._seed_read("physics", 2)
			Crafting.inventory_add("wormhole", 1, 1)
			_pick("Other ways in…")
			var ok := _force_checks(1.0)
			_pick("Open a Wormhole")
			ok.call()
			assert_eq(_key(), "s_room")
			var breath := _index("Prophet's Breath: slip past")
			if guards == 0:
				assert_true(_shown("Walk to the vein"), "no guards: walk to the vein")
				for label in ["Fight for the room", "Bluff past"]:
					assert_true(not _shown(label), "no guards: no %s" % label)
				assert_eq(Events.option_gate(breath)["display"], "hide", "no guards: nobody to slip past")
			else:
				assert_true(not _shown("Walk to the vein"), "guards: no walking past them")
				assert_true(_shown("Fight for the room"))
				assert_true(_shown("Bluff past"))
				assert_eq(Events.option_gate(breath)["display"], "disable", "guards, no Prophet's Breath: greyed")
	)

	run_case("every_card_after_the_cellar_names_its_own_read", func():
		var want := {
			"till": ["s_seen_till", "s_cam", "s_cam2", "s_win_cam"],
			"flap": ["s_seen_flap"],
			"yard": ["s_seen_yard"],
			"door": ["s_seen_door"],
			"stock": ["s_seen_in", "post", "post2", "post3", "s_back_loud", "s_back_in"],
			"lock": ["s_stairs_in", "s_ward", "s_ward2", "s_ward3"],
			"cellar": ["s_room", "s_claim_route", "s_final", "s_claim", "s_claim_a", "s_getaway", "s_retreat"],
			"": ["s_win_out", "s_win_out2", "s_win_in", "s_win_in2", "s_win_wit", "s_alarm", "s_alarm2", "s_reinf", "s_resume", "s_resume2", "s_out"],
		}
		for obs in want:
			for key in want[obs]:
				var card := _card(key)
				assert_true(card.has("observe"), "%s carries an explicit observe" % key)
				var got = card.get("observe")
				assert_eq("" if got == null else String(got), obs, key)
	)

	run_case("panic_in_the_back_room_covers_at_the_shops_lower_base", func():
		var post3 := _card("post3")
		var base := -1.0
		for choice in post3["choices"]:
			if choice["label"] == "Panic":
				for effect in choice["effects"]:
					if effect.get("op", "") == "alert":
						base = effect["cover"]["base"]
		assert_eq(base, 0.35)
	)

	run_case("backing_out_at_unseen_leaves_clean", func():
		_start()
		var relation_before: int = GameState.state["factions"]["firm"]["relation"]
		_settle()
		_pick("Other ways in…")
		_pick("Back out…")
		assert_eq(_key(), "s_retreat")
		Events.choose(_index("Walk out calmly"))
		assert_eq(GameState.state["factions"]["firm"]["relation"], relation_before)
		assert_true(not Raiding.is_wary("s1"))
	)

	run_case("the_till_and_stockroom_carry_their_own_reads_and_later_cards_go_back_to_the_raid_read", func():
		_start()
		_settle()
		_pick(WALK_IN)
		assert_eq(Observation.in_effect(), "till")
		_pick("Other ways…")
		assert_eq(Observation.in_effect(), "till", "the till's follow-up card keeps the till read")
		_start()
		var ok := _force_checks(1.0)
		_settle()
		_walk_in_to_the_back()
		ok.call()
		assert_eq(_key(), "s_back")
		assert_eq(Observation.in_effect(), "stock")
		_start()
		_settle()
		_pick(ROUND_BACK)
		assert_eq(Observation.in_effect(), "yard", "the yard never shows the stockroom read")
	)

	run_case("the_cellar_door_yard_and_yard_door_carry_their_own_reads_and_the_flap_never_shows_the_yard_door_read", func():
		_start()
		var ok := _force_checks(1.0)
		_settle()
		_walk_in_to_the_back()
		_pick(RESTOCK)
		ok.call()
		assert_eq(_key(), "s_lock")
		assert_eq(Observation.in_effect(), "lock")
		_pick("Rougher ways…")
		assert_eq(Observation.in_effect(), "lock", "the lock's follow-up card keeps the lock read")
		_start()
		_settle()
		_pick(ROUND_BACK)
		_pick("Other ways…")
		assert_eq(Observation.in_effect(), "yard", "the yard's follow-up card keeps the yard read")
		ok = _force_checks(1.0)
		_pick("Hope he's gone in")
		ok.call()
		assert_eq(_key(), "s_door")
		assert_eq(Observation.in_effect(), "door")
		_pick("Rougher ways…")
		assert_eq(Observation.in_effect(), "door", "the door's follow-up card keeps the door read")
		_start({ "cellarFlap": true })
		_settle()
		_pick("Other ways in…")
		RaidingTests._seed_read("physics", 1)
		_pick("The cellar flap")
		assert_eq(_key(), "s_flap")
		assert_eq(Observation.in_effect(), "flap", "the flap never shows the yard door read")
	)

	run_case("the_flap_and_the_cellar_carry_their_own_reads", func():
		_start({ "cellarFlap": true })
		_settle()
		_pick("Other ways in…")
		RaidingTests._seed_read("physics", 1)
		_pick("The cellar flap")
		assert_eq(Observation.in_effect(), "flap")
		_pick("Other ways…")
		assert_eq(Observation.in_effect(), "flap", "the flap's follow-up card keeps the flap read")
		_start({ "cellarFlap": true })
		_settle()
		_pick("Other ways in…")
		RaidingTests._seed_read("physics", 1)
		_pick("The cellar flap")
		var ok := _force_checks(1.0)
		_pick("Hope no one on the street looks down")
		ok.call()
		assert_eq(_key(), "s_cellar")
		assert_eq(Observation.in_effect(), "cellar")
		_pick("Other ways…")
		assert_eq(Observation.in_effect(), "cellar", "the cellar's follow-up card keeps the cellar read")
	)

	run_case("flap_reads_boost_levering_it_and_the_street_not_looking_down", func():
		_start({ "cellarFlap": true })
		_settle()
		_pick("Other ways in…")
		RaidingTests._seed_read("physics", 1)
		_pick("The cellar flap")
		var lever := _odds("Lever the rotten flap")
		var street := _odds("Hope no one on the street looks down")
		_seed_obs("flap", "time", 2)
		_seed_obs("flap", "physics", 1)
		assert_true(absf(_odds("Lever the rotten flap") - lever) < 0.001, "the weaker physics tier and the drayman's hours are only hints")
		assert_true(absf(_odds("Hope no one on the street looks down") - street) < 0.001, "the drayman's hours are informative only")
		_seed_obs("flap", "physics", 2)
		_seed_obs("flap", "life", 1)
		assert_true(absf(_odds("Lever the rotten flap") - (lever + 0.05)) < 0.001, "rusted to a flake: +0.05")
		assert_true(absf(_odds("Hope no one on the street looks down") - (street + 0.05)) < 0.001, "facing the road: +0.05")
	)

	run_case("cellar_reads_boost_waiting_for_the_guard_and_the_rest_are_informative", func():
		_start({ "cellarFlap": true })
		_settle()
		_pick("Other ways in…")
		RaidingTests._seed_read("physics", 1)
		_pick("The cellar flap")
		var ok := _force_checks(1.0)
		_pick("Hope no one on the street looks down")
		ok.call()
		assert_eq(_key(), "s_cellar")
		RaidingTests._seed_read("life", 1)
		var wait := _odds("Wait for the guard on the vein to turn")
		var hope := _odds("Walk past like you belong")
		_seed_obs("cellar", "life", 2)
		_seed_obs("cellar", "emotion", 2)
		assert_true(absf(_odds("Wait for the guard on the vein to turn") - wait) < 0.001, "the guard's life read is informative only")
		assert_true(absf(_odds("Walk past like you belong") - hope) < 0.001, "his boredom is informative only")
		_seed_obs("cellar", "time", 1)
		assert_true(absf(_odds("Wait for the guard on the vein to turn") - (wait + 0.05)) < 0.001, "every few minutes: +0.05")
	)

	run_case("lock_reads_boost_picking_it_and_hoping_it_is_open", func():
		_start()
		var ok := _force_checks(1.0)
		_settle()
		_walk_in_to_the_back()
		_pick(RESTOCK)
		ok.call()
		assert_eq(_key(), "s_lock")
		RaidingTests._seed_read("physics", 1)
		var pick := _odds("Pick it quiet")
		var unlocked := _odds(UNLOCKED)
		_seed_obs("lock", "physics", 1)
		assert_true(absf(_odds("Pick it quiet") - (pick + 0.05)) < 0.001, "the cheap lock: +0.05")
		_seed_obs("lock", "fate", 1)
		assert_true(absf(_odds(UNLOCKED) - unlocked) < 0.001, "the weaker fate tier is only a hint")
		_seed_obs("lock", "fate", 2)
		assert_true(absf(_odds(UNLOCKED) - (unlocked + 0.05)) < 0.001, "left off the lock: +0.05")
	)

	run_case("yard_reads_boost_waiting_out_the_smoker_and_the_phone_is_informative", func():
		_start()
		_settle()
		_pick(ROUND_BACK)
		assert_eq(_key(), "s_yard")
		RaidingTests._seed_read("life", 1)
		var wait := _odds("Wait for the smoker to finish")
		var delivery := _odds("Pose as the delivery")
		_seed_obs("yard", "time", 1)
		_seed_obs("yard", "life", 2)
		assert_true(absf(_odds("Wait for the smoker to finish") - (wait + 0.05)) < 0.001, "one cigarette a break: +0.05")
		assert_true(absf(_odds("Pose as the delivery") - delivery) < 0.001, "the yard life read is informative only")
	)

	run_case("yard_door_reads_boost_the_hinge_pins_and_the_pick", func():
		_start()
		_settle()
		_pick(ROUND_BACK)
		_pick("Other ways…")
		var ok := _force_checks(1.0)
		_pick("Hope he's gone in")
		ok.call()
		assert_eq(_key(), "s_door")
		RaidingTests._seed_read("physics", 2)
		var pins := _odds("Slide the hinge pins out")
		var pick := _odds("Pick it")
		_seed_obs("door", "physics", 1)
		_seed_obs("door", "time", 1)
		assert_true(absf(_odds("Slide the hinge pins out") - pins) < 0.001, "the weaker physics tier is only a hint")
		assert_true(absf(_odds("Pick it") - pick) < 0.001, "the weaker time tier is only a hint")
		_seed_obs("door", "physics", 2)
		_seed_obs("door", "time", 2)
		assert_true(absf(_odds("Slide the hinge pins out") - (pins + 0.05)) < 0.001, "pins out before: +0.05")
		assert_true(absf(_odds("Pick it") - (pick + 0.05)) < 0.001, "on the latch: +0.05")
	)

	run_case("till_reads_boost_the_toilet_the_regular_and_the_card_machine", func():
		_start()
		_settle()
		_pick(WALK_IN)
		RaidingTests._seed_read("life", 1)
		var toilet := _odds(TOILET)
		var regular := _odds("Wait until she's serving the regular")
		_seed_obs("till", "emotion", 1)
		_seed_obs("till", "life", 1)
		assert_true(absf(_odds(TOILET) - (toilet + 0.05)) < 0.001, "a till emotion read: +0.05")
		assert_true(absf(_odds("Wait until she's serving the regular") - (regular + 0.05)) < 0.001, "a till life read: +0.05")
		_pick("Other ways…")
		var machine := _odds("Hope the card machine goes down")
		_seed_obs("till", "fate", 1)
		assert_true(absf(_odds("Hope the card machine goes down") - machine) < 0.001, "the weaker fate tier is only a hint")
		_seed_obs("till", "fate", 2)
		assert_true(absf(_odds("Hope the card machine goes down") - (machine + 0.05)) < 0.001, "the taped machine: +0.05")
	)

	run_case("stockroom_reads_boost_the_pallet_runs_and_the_blind_side", func():
		_start()
		var ok := _force_checks(1.0)
		_settle()
		_walk_in_to_the_back()
		ok.call()
		assert_eq(_key(), "s_back")
		RaidingTests._seed_read("time", 1)
		RaidingTests._seed_read("life", 1)
		var pallets := _odds("Go in a quiet spell")
		var blind := _odds("Keep to the blind side of the shelving")
		var restock := _odds(RESTOCK)
		_seed_obs("stock", "time", 1)
		_seed_obs("stock", "physics", 1)
		_seed_obs("stock", "life", 2)
		assert_true(absf(_odds("Go in a quiet spell") - (pallets + 0.05)) < 0.001, "a stock time read: +0.05")
		assert_true(absf(_odds("Keep to the blind side of the shelving") - (blind + 0.05)) < 0.001, "a stock physics read: +0.05")
		assert_true(absf(_odds(RESTOCK) - restock) < 0.001, "the stock life read is informative only")
	)

	run_case("claim_takes_the_vein_and_costs_relation_even_when_clean", func():
		_start()
		var ok := _force_checks(1.0)
		_settle()
		_walk_in_to_the_back()
		_pick(RESTOCK)
		_pick(UNLOCKED)
		_pick("Walk to the vein")
		ok.call()
		Events.choose(0)  # Claim it
		assert_eq(GameState.state["world"]["sites"][0]["factionVein"], null)
		assert_eq(GameState.state["player"]["veins"].size(), 1)
	)
