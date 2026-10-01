extends "res://tests/test_base.gd"

# systems/contact_texts.gd: the scheduler's cadence, gates and pause rule,
# reply rewards, vein templating, repeat order, save migration, and the
# data/contact_texts.json validator. Mechanism cases swap in a synthetic
# pool so content edits can't break them.

const Fixtures := preload("res://tests/support/fixtures.gd")

const TEST_POOL := {
	"gateFlag": "bizA1OwenJoined",
	"pauseWhenNotWorking": true,
	"veinSource": "cultivator",
	"correctReward": { "xp": { "skill": "cultivating", "amount": 2 } },
	"intervalMinDays": 2,
	"intervalMaxDays": 3,
	"texts": [
		{ "id": "q_vein", "kind": "question", "needsVein": true,
			"text": "The {ore} vein on {street}, {district}?",
			"replies": [
				{ "text": "Right", "correct": true, "response": "Ta, {street}." },
				{ "text": "Wrong", "correct": false, "response": "Oh." },
			] },
		{ "id": "flavour", "kind": "flavour", "needsVein": false,
			"text": "Bus stop.",
			"replies": [
				{ "text": "A", "correct": false, "response": "a" },
				{ "text": "B", "correct": false, "response": "b" },
			] },
	],
}


func _join_owen(with_vein: bool) -> void:
	GameState.reset()
	GameData.CONTACT_TEXTS = { "owen": TEST_POOL.duplicate(true) }
	GameState.state["contactTexts"]["owen"] = ContactTexts.new_contact_state()
	GameState.state["contacts"]["owen"]["recruited"] = true
	GameState.state["flags"]["bizOwenCultivationRole"] = true
	GameState.state["flags"]["bizA1OwenJoined"] = true
	Business.activate()
	Contacts.set_role("owen", "cultivation")
	if with_vein:
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with({ "location": "Brick Lane, East" })]
		Rooms.assign_vein("owen", "v1")


# Marks the flavour text played so send_next() picks the vein question.
func _send_question() -> String:
	GameState.state["contactTexts"]["owen"]["played"]["flavour"] = 0
	return ContactTexts.send_next("owen")


func _set_day(day: int) -> void:
	GameState.state["world"]["day"] = day


func _owen_thread() -> Array:
	return GameState.state["messages"].get("owen", [])


func _meet_archie() -> void:
	GameState.reset()
	GameState.state["flags"]["metArchie"] = true
	GameState.state["contactTexts"]["archie"] = ContactTexts.new_contact_state()


# Archie's thread minus anything but his random texts' opening lines.
func _archie_random_texts() -> Array:
	var openers: Array = GameData.CONTACT_TEXTS["archie"]["texts"].map(func(e): return e["text"])
	return GameState.state["messages"].get("archie", []).filter(func(m): return openers.has(m["text"]))


# Marks every other Archie text played so send_next() picks this one.
func _force_archie_text(text_id: String) -> void:
	var played := {}
	for entry in GameData.CONTACT_TEXTS["archie"]["texts"]:
		if entry["id"] != text_id:
			played[entry["id"]] = 0
	GameState.state["contactTexts"]["archie"]["played"] = played
	GameState.state["flags"]["metJames"] = true
	assert_eq(ContactTexts.send_next("archie"), text_id)


var _shipped_pool: Dictionary = {}


func _restore_pool() -> void:
	GameData.CONTACT_TEXTS = _shipped_pool.duplicate(true)


func run() -> void:
	_shipped_pool = GameData.CONTACT_TEXTS.duplicate(true)
	run_case("scheduler_seeds_from_the_join_day_and_fires_every_2_to_3_days", func():
		_join_owen(false)
		Rng.set_seed(7)
		_set_day(10)
		ContactTexts.daily_tick()
		var next_day: int = GameState.state["contactTexts"]["owen"]["nextDay"]
		assert_true(next_day >= 11 and next_day <= 12, "first text 2-3 days after joining on day 9, got %d" % next_day)
		assert_eq(_owen_thread().size(), 0, "seeding sends nothing")

		for day in range(11, next_day):
			_set_day(day)
			ContactTexts.daily_tick()
		assert_eq(_owen_thread().size(), 0, "nothing before the due day")

		_set_day(next_day)
		ContactTexts.daily_tick()
		assert_eq(_owen_thread().size(), 1, "fires on the due day")
		var after: int = GameState.state["contactTexts"]["owen"]["nextDay"]
		assert_true(after - next_day >= 2 and after - next_day <= 3, "next interval 2-3 days")
		_restore_pool()
	)

	run_case("scheduler_is_deterministic_under_a_seeded_rng", func():
		var runs: Array = []
		for i in range(2):
			_join_owen(true)
			Rng.set_seed(42)
			for day in range(1, 20):
				_set_day(day)
				ContactTexts.daily_tick()
				if GameState.state["contactTexts"]["owen"]["active"] != null:
					ContactTexts.reply("owen", 0)
			runs.append(_owen_thread().map(func(m): return [m["day"], m["text"]]))
		assert_eq(runs[0], runs[1], "same seed, same texts on the same days")
		assert_true(runs[0].size() > 0, "texts were sent")
		_restore_pool()
	)

	run_case("no_texts_before_owen_joins", func():
		_join_owen(false)
		GameState.state["flags"]["bizA1OwenJoined"] = false
		for day in range(1, 10):
			_set_day(day)
			ContactTexts.daily_tick()
		assert_eq(GameState.state["contactTexts"]["owen"]["nextDay"], null, "never seeded")
		assert_eq(_owen_thread().size(), 0)
		_restore_pool()
	)

	run_case("the_clock_pauses_while_owen_is_not_working", func():
		_join_owen(false)
		GameState.state["contactTexts"]["owen"]["nextDay"] = 5
		GameState.state["business"]["wages"]["owen"]["unpaid"] = true
		assert_true(not Payroll.is_working("owen"), "sanity: unpaid Owen isn't working")
		for day in range(5, 9):
			_set_day(day)
			ContactTexts.daily_tick()
		assert_eq(_owen_thread().size(), 0, "no texts while he isn't working")
		assert_eq(GameState.state["contactTexts"]["owen"]["nextDay"], 9, "due day pushed back one per paused day")

		GameState.state["business"]["wages"]["owen"]["unpaid"] = false
		_set_day(9)
		ContactTexts.daily_tick()
		assert_eq(_owen_thread().size(), 1, "fires once he's working again")
		_restore_pool()
	)

	run_case("a_due_text_waits_while_the_last_is_unanswered", func():
		_join_owen(false)
		GameState.state["contactTexts"]["owen"]["nextDay"] = 3
		_set_day(3)
		ContactTexts.daily_tick()
		GameState.state["contactTexts"]["owen"]["nextDay"] = 4
		_set_day(4)
		ContactTexts.daily_tick()
		assert_eq(_owen_thread().size(), 1, "second text held back")
		ContactTexts.reply("owen", 0)
		_set_day(5)
		ContactTexts.daily_tick()
		assert_eq(_owen_thread().size(), 4, "fires on the rollover after the reply")
		_restore_pool()
	)

	run_case("the_right_answer_grants_cultivating_xp_and_owen_replies", func():
		_join_owen(true)
		assert_eq(_send_question(), "q_vein", "the unplayed question goes out")
		var xp_before: int = GameState.state["contacts"]["owen"]["cultivatingXP"]
		assert_eq(ContactTexts.active_replies("owen"), ["Right", "Wrong"])

		var result := ContactTexts.reply("owen", 0)
		assert_true(result["ok"] and result["correct"])
		assert_eq(GameState.state["contacts"]["owen"]["cultivatingXP"], xp_before + GameData.CULTIVATOR_ACTION_XP)
		var thread := _owen_thread()
		assert_eq(thread[-2]["from"], "player")
		assert_eq(thread[-2]["text"], "Right")
		assert_eq(thread[-1]["from"], "them")
		assert_eq(thread[-1]["text"], "Ta, Brick Lane.", "follow-up templated too")
		assert_eq(GameState.state["contactTexts"]["owen"]["active"], null, "answered")
		assert_eq(ContactTexts.active_replies("owen"), [], "no replies left to tap")
		_restore_pool()
	)

	run_case("a_wrong_answer_grants_no_xp_but_owen_still_replies", func():
		_join_owen(true)
		_send_question()
		var xp_before: int = GameState.state["contacts"]["owen"]["cultivatingXP"]
		var result := ContactTexts.reply("owen", 1)
		assert_true(result["ok"] and not result["correct"])
		assert_eq(GameState.state["contacts"]["owen"]["cultivatingXP"], xp_before)
		assert_eq(_owen_thread()[-1]["text"], "Oh.")
		_restore_pool()
	)

	run_case("reply_xp_respects_owens_skill_cap", func():
		_join_owen(true)
		var owen: Dictionary = GameState.state["contacts"]["owen"]
		owen["cultivatingSkill"] = 3
		owen["cultivatingXP"] = 100000
		_send_question()
		ContactTexts.reply("owen", 0)
		assert_eq(owen["cultivatingSkill"], 3, "capped at level 3")
		_restore_pool()
	)

	run_case("vein_texts_template_a_real_assigned_vein", func():
		_join_owen(true)
		_send_question()
		assert_eq(_owen_thread()[-1]["text"], "The time vein on Brick Lane, Shoreditch?")
		_restore_pool()
	)

	run_case("vein_texts_are_skipped_when_owen_has_no_vein", func():
		_join_owen(false)
		assert_eq(ContactTexts.send_next("owen"), "flavour", "only the vein-free text is eligible")
		ContactTexts.reply("owen", 0)
		assert_eq(ContactTexts.send_next("owen"), "flavour", "repeats rather than send a vein text")
		GameData.CONTACT_TEXTS["owen"]["texts"] = [TEST_POOL["texts"][0].duplicate(true)]
		ContactTexts.reply("owen", 0)
		assert_eq(ContactTexts.send_next("owen"), "", "nothing eligible, nothing sent")
		_restore_pool()
	)

	run_case("each_text_plays_once_then_repeats_least_recently_used_first", func():
		_join_owen(true)
		var first := ContactTexts.send_next("owen")
		ContactTexts.reply("owen", 0)
		var second := ContactTexts.send_next("owen")
		ContactTexts.reply("owen", 0)
		assert_true(first != second, "the unplayed text goes before any repeat")
		assert_eq(ContactTexts.send_next("owen"), first, "then the least recently played")
		ContactTexts.reply("owen", 0)
		assert_eq(ContactTexts.send_next("owen"), second)
		_restore_pool()
	)

	run_case("owen_text_notifies_once_tagged_with_contact", func():
		_join_owen(false)
		var before: int = GameState.state["notifications"].size()
		ContactTexts.send_next("owen")
		var notifications: Array = GameState.state["notifications"]
		assert_eq(notifications.size(), before + 1, "one notification per text")
		assert_eq(notifications.back().get(Notify.META_CONTACT_ID), "owen", "tagged with the contact id")
		assert_true(Messages.has_unread("owen"), "thread marked unread")
		ContactTexts.reply("owen", 0)
		assert_eq(notifications.size(), before + 1, "his answer to a reply doesn't notify")
		_restore_pool()
	)

	run_case("contact_texts_state_is_pure_and_backfills_on_old_saves", func():
		_join_owen(true)
		ContactTexts.send_next("owen")
		var owen_texts: Dictionary = GameState.state["contactTexts"]["owen"]
		assert_eq(JSON.parse_string(JSON.stringify(owen_texts))["active"]["id"], owen_texts["active"]["id"], "round-trips through JSON")
		var old_save: Dictionary = GameState.state.duplicate(true)
		old_save.erase("contactTexts")
		assert_eq(SaveManager.backfill_defaults(old_save)["contactTexts"], {}, "old saves get the default")
		_restore_pool()
	)

	run_case("an_old_save_keeps_owens_text_state", func():
		_join_owen(true)
		var old_save: Dictionary = GameState.state.duplicate(true)
		old_save.erase("contactTexts")
		old_save["owenTexts"] = { "nextDay": 14.0, "played": { "flavour": 3.0 }, "playSeq": 3.0, "active": { "id": "flavour", "vars": {} } }
		assert_true(SaveManager.import_string(JSON.stringify(old_save))["ok"], "loads")
		assert_true(not GameState.state.has("owenTexts"), "old key dropped")
		var owen_texts: Dictionary = GameState.state["contactTexts"]["owen"]
		assert_eq(owen_texts["nextDay"], 14)
		assert_eq(typeof(owen_texts["nextDay"]), TYPE_INT, "ints restored")
		assert_eq(owen_texts["played"], { "flavour": 3 })
		assert_eq(ContactTexts.active_replies("owen"), ["A", "B"], "the unanswered text still awaits a reply")
		_restore_pool()
	)

	run_case("a_new_contact_is_data_only_with_gate_vein_source_and_rewards", func():
		GameState.reset()
		GameData.CONTACT_TEXTS = { "james": {
			"requireUnlocked": true,
			"intervalMinDays": 1,
			"intervalMaxDays": 1,
			"correctReward": { "relation": 1 },
			"texts": [
				{ "id": "gift", "kind": "flavour", "needsVein": false, "text": "Here.",
					"replies": [
						{ "text": "Ta", "response": "Go on.", "reward": { "cash": 5, "item": { "id": "timePearl", "qty": 1 } } },
						{ "text": "No", "response": "Suit yourself." },
					] },
				{ "id": "q", "kind": "question", "needsVein": true, "text": "{street}?",
					"replies": [
						{ "text": "Yes", "correct": true, "response": "Good.", "reward": { "xp": { "skill": "crafting", "amount": 3 } } },
						{ "text": "No", "response": "Hm." },
					] },
			],
		} }
		var james: Dictionary = GameState.state["contacts"]["james"]
		james["unlocked"] = false
		for day in range(1, 4):
			_set_day(day)
			ContactTexts.daily_tick()
		assert_true(not GameState.state["contactTexts"].has("james"), "gate closed until unlocked")

		james["unlocked"] = true
		_set_day(4)
		ContactTexts.daily_tick()
		assert_eq(GameState.state["contactTexts"]["james"]["nextDay"], 4, "seeded from yesterday, 1-day interval")
		ContactTexts.daily_tick()
		assert_eq(GameState.state["contactTexts"]["james"]["active"]["id"], "gift", "no player vein, so the vein text is ineligible")
		assert_eq(GameState.state["messages"]["james"][-1]["text"], "Here.")
		assert_eq(GameState.state["notifications"].back().get(Notify.META_CONTACT_ID), "james")

		var cash: int = GameState.state["player"]["cash"]
		var pearls: int = int(GameState.state["player"]["inventory"].get("timePearl", {}).get("0", 0))
		var relation: int = james["relation"]
		assert_true(ContactTexts.reply("james", 0)["ok"])
		assert_eq(GameState.state["player"]["cash"], cash + 5, "cash reward")
		assert_eq(int(GameState.state["player"]["inventory"]["timePearl"]["0"]), pearls + 1, "item reward, untiered")
		assert_eq(james["relation"], relation, "a flavour reply gets no correctReward")

		GameState.state["player"]["veins"] = [Fixtures.player_vein_with({ "location": "Brick Lane, East" })]
		assert_eq(ContactTexts.send_next("james"), "q", "any player vein feeds a player-source vein text")
		assert_eq(GameState.state["messages"]["james"][-1]["text"], "Brick Lane?")
		var xp: int = james["craftingXP"]
		ContactTexts.reply("james", 0)
		assert_eq(james["relation"], relation + 1, "correctReward on the right answer")
		assert_eq(james["craftingXP"], xp + 3, "plus the reply's own reward")
		_restore_pool()
	)

	run_case("shipped_contact_texts_pool_validates", func():
		var errors := GameData.validate_tables(GameData.snapshot()).filter(func(e): return e.begins_with("contact_texts"))
		assert_eq(errors, [], "no contact_texts errors")
		var counts := { "question": 0, "flavour": 0 }
		for entry in GameData.CONTACT_TEXTS["owen"]["texts"]:
			counts[entry["kind"]] += 1
		assert_eq(counts, { "question": 8, "flavour": 8 }, "Owen ships 8 questions and 8 flavour texts")
	)

	run_case("archie_ships_12_texts_and_starts_once_met", func():
		var counts := { "question": 0, "flavour": 0 }
		for entry in GameData.CONTACT_TEXTS["archie"]["texts"]:
			counts[entry["kind"]] += 1
		assert_eq(counts, { "question": 3, "flavour": 9 }, "Archie ships 3 questions and 9 flavour texts")

		GameState.reset()
		for day in range(1, 10):
			_set_day(day)
			ContactTexts.daily_tick()
		assert_true(not GameState.state["contactTexts"].has("archie"), "nothing before he's met")
		_meet_archie()
		_set_day(10)
		ContactTexts.daily_tick()
		var next_day: int = GameState.state["contactTexts"]["archie"]["nextDay"]
		assert_true(next_day >= 13 and next_day <= 15, "first text 4-6 days after meeting, got %d" % next_day)
		_set_day(next_day)
		ContactTexts.daily_tick()
		assert_eq(_archie_random_texts().size(), 1, "fires on the due day")
	)

	run_case("archie_pauses_while_unpaid", func():
		_meet_archie()
		GameState.state["contactTexts"]["archie"]["nextDay"] = 5
		GameState.state["business"]["wages"]["archie"] = { "unpaid": true, "owed": 0 }
		for day in range(5, 8):
			_set_day(day)
			ContactTexts.daily_tick()
		assert_eq(_archie_random_texts().size(), 0, "no texts while he's owed")
		assert_eq(GameState.state["contactTexts"]["archie"]["nextDay"], 8, "due day pushed back one per paused day")
	)

	run_case("archie_holds_his_text_while_a_deal_or_pending_message_is_open", func():
		_meet_archie()
		GameState.state["contactTexts"]["archie"]["nextDay"] = 5
		GameState.state["flags"]["archieMotionEventSeen"] = true
		GameState.state["player"]["cash"] = 0
		_set_day(5)
		ArchieDeals.roll_daily_offer()
		ContactTexts.daily_tick()
		assert_eq(Messages.pending_for("archie").size(), 1, "deal offer queued")
		assert_eq(GameState.state["contactTexts"]["archie"]["active"], null, "random text held behind the deal")

		ArchieDeals.decline_deal(Messages.pending_for("archie")[0]["id"])
		Messages.queue_pending("archie", "test_beat", "Story beat.")
		_set_day(6)
		ContactTexts.daily_tick()
		assert_eq(GameState.state["contactTexts"]["archie"]["active"], null, "held behind any open pending message")

		Messages.resolve_pending(Messages.pending_for("archie")[0]["id"])
		GameState.state["flags"]["archieDealActive"] = true
		ContactTexts.daily_tick()
		assert_eq(GameState.state["contactTexts"]["archie"]["active"], null, "held while an accepted deal is still running")

		GameState.state["flags"]["archieDealActive"] = false
		ContactTexts.daily_tick()
		assert_true(GameState.state["contactTexts"]["archie"]["active"] != null, "fires once he's free")
	)

	run_case("no_deal_offer_while_archies_text_awaits_a_reply", func():
		_meet_archie()
		GameState.state["flags"]["archieMotionEventSeen"] = true
		GameState.state["player"]["cash"] = 0
		ContactTexts.send_next("archie")
		ArchieDeals.roll_daily_offer()
		assert_eq(Messages.pending_for("archie").size(), 0, "deal waits for the reply")
		ContactTexts.reply("archie", 0)
		ArchieDeals.roll_daily_offer()
		assert_eq(Messages.pending_for("archie").size(), 1, "deal offered once answered")
	)

	run_case("archies_james_texts_wait_until_james_is_met", func():
		_meet_archie()
		var sent := {}
		for i in range(GameData.CONTACT_TEXTS["archie"]["texts"].size()):
			sent[ContactTexts.send_next("archie")] = true
			ContactTexts.reply("archie", 0)
		assert_true(not sent.has("good_batch") and not sent.has("james_receipt"), "no James texts before metJames")
		assert_true(not sent.has("bike_on_fence"), "no vein text without a player vein")
		GameState.state["flags"]["metJames"] = true
		GameState.state["contactTexts"]["archie"]["played"] = {}
		for entry in GameData.CONTACT_TEXTS["archie"]["texts"]:
			if entry["id"] != "james_receipt":
				GameState.state["contactTexts"]["archie"]["played"][entry["id"]] = 0
		assert_eq(ContactTexts.send_next("archie"), "james_receipt", "eligible once James is met")
	)

	run_case("archie_reply_rewards", func():
		_meet_archie()
		var archie: Dictionary = GameState.state["contacts"]["archie"]
		var relation: int = archie["relation"]
		_force_archie_text("nicer_postcode")
		assert_true(ContactTexts.reply("archie", 0)["correct"], "nicer postcode is right")
		assert_eq(archie["relation"], relation + 1, "right answer: +1 relation")
		_force_archie_text("dont_dump_it")
		assert_true(not ContactTexts.reply("archie", 1)["correct"])
		assert_eq(archie["relation"], relation + 1, "wrong answer: nothing")

		var cash: int = GameState.state["player"]["cash"]
		_force_archie_text("tenner_back")
		ContactTexts.reply("archie", 1)
		assert_eq(GameState.state["player"]["cash"], cash + 10, "his tenner")
		_force_archie_text("chips_friday")
		ContactTexts.reply("archie", 0)
		assert_eq(archie["relation"], relation + 3, "chips: +2 relation")
	)

	run_case("validator_rejects_a_malformed_pool", func():
		var bad := TEST_POOL.duplicate(true)
		bad["texts"][0]["replies"][1]["correct"] = true
		bad["texts"][1]["text"] = "On {street}."
		bad["texts"][1]["replies"].resize(1)
		bad["texts"].append(bad["texts"][1].duplicate(true))
		bad["veinSource"] = "moon"
		bad["correctReward"] = { "xp": { "skill": "juggling", "amount": 1 }, "luck": 1 }
		bad["texts"][0]["replies"][0]["reward"] = { "item": { "id": "nope", "qty": 1 }, "cash": 0 }
		var t := GameData.snapshot()
		t["contact_texts"] = { "owen": bad }
		var errors := GameData.validate_tables(t).filter(func(e): return e.begins_with("contact_texts"))
		var joined := "
".join(errors)
		assert_true(joined.contains("exactly 1 correct"), "two correct answers rejected")
		assert_true(joined.contains("{street} needs needsVein"), "vein placeholder without needsVein rejected")
		assert_true(joined.contains("needs 2-3 replies"), "one reply rejected")
		assert_true(joined.contains("duplicate id"), "duplicate id rejected")
		assert_true(joined.contains("veinSource 'moon'"), "unknown vein source rejected")
		assert_true(joined.contains("xp needs a skill"), "unknown skill rejected")
		assert_true(joined.contains("unknown reward 'luck'"), "unknown reward rejected")
		assert_true(joined.contains("item needs a recipe id"), "unknown item rejected")
		assert_true(joined.contains("cash must be > 0"), "zero cash rejected")
	)
