extends "res://tests/test_base.gd"

# Faction incidents: the four triggers queue their event with a pending
# message; cooldowns and conditions gate them; saves backfill the state.


static func _fresh() -> void:
	GameState.reset()
	GameState.state["world"]["day"] = 20


static func _pending_kinds() -> Array:
	return GameState.state["pendingMessages"].filter(func(p): return p["kind"] == FactionIncidents.PENDING_KIND)


static func _queued_ids() -> Array:
	return FactionIncidents.queued().map(func(q): return q["incidentId"])


func run() -> void:
	run_case("data_validates_and_every_trigger_resolves", func():
		assert_true(GameData.validate(), str(GameData.get_errors()))
		for id in GameData.FACTION_INCIDENTS["entries"]:
			var entry: Dictionary = GameData.FACTION_INCIDENTS["entries"][id]
			assert_true(FactionIncidents._trigger_fn(entry["trigger"]).is_valid(), "%s trigger registered" % id)
		for trigger in FactionIncidents.TRIGGER_IDS:
			assert_true(FactionIncidents._trigger_fn(trigger).is_valid(), "%s in TRIGGER_IDS has a function" % trigger)
	)

	run_case("raided_by_faction_queues_revenge_offer_once_per_cooldown", func():
		_fresh()
		Grudges.record("firm", "shoreditch", "site_pv")
		FactionIncidents.daily_tick()
		assert_eq(_queued_ids(), ["inc_raided_revenge"])
		assert_eq(_pending_kinds().size(), 1)
		assert_eq(FactionIncidents.queued()[0]["context"]["faction_id"], "firm")
		FactionIncidents.daily_tick()
		assert_eq(FactionIncidents.queued().size(), 1, "same raid on cooldown")
	)

	run_case("raided_trigger_ignores_a_stale_grudge", func():
		_fresh()
		Grudges.record("firm", "shoreditch")
		GameState.state["world"]["day"] = 25
		FactionIncidents.daily_tick()
		assert_true(FactionIncidents.queued().is_empty())
	)

	run_case("war_between_factions_queues_but_player_wars_do_not", func():
		_fresh()
		FactionAI.wars().append({ "parties": ["firm", "guild"], "startDay": 15, "lastHostileDay": 15, "weariness": {} })
		FactionAI.wars().append({ "parties": ["player", "network"], "startDay": 10, "lastHostileDay": 10, "weariness": {} })
		FactionIncidents.daily_tick()
		assert_eq(_queued_ids(), ["inc_war_courting"])
		var context: Dictionary = FactionIncidents.queued()[0]["context"]
		assert_eq([context["faction_a"], context["faction_b"]], ["firm", "guild"])
	)

	run_case("fresh_war_waits_out_minWarDays", func():
		_fresh()
		FactionAI.wars().append({ "parties": ["firm", "guild"], "startDay": 20, "lastHostileDay": 20, "weariness": {} })
		FactionIncidents.daily_tick()
		assert_true(FactionIncidents.queued().is_empty())
	)

	run_case("truce_expiring_fires_inside_window_only", func():
		_fresh()
		FactionAI.truces().append({ "parties": ["player", "firm"], "startDay": 10, "endDay": 30, "dailyBonus": 0, "weekly": [] })
		FactionIncidents.daily_tick()
		assert_true(FactionIncidents.queued().is_empty(), "10 days left")
		GameState.state["world"]["day"] = 28
		FactionIncidents.daily_tick()
		assert_eq(_queued_ids(), ["inc_truce_expiring"])
		assert_eq(FactionIncidents.queued()[0]["context"]["days_left"], 2)
	)

	run_case("truce_between_factions_needs_playerInvolved_off", func():
		_fresh()
		FactionAI.truces().append({ "parties": ["firm", "guild"], "startDay": 10, "endDay": 21, "dailyBonus": 0, "weekly": [] })
		FactionIncidents.daily_tick()
		assert_true(FactionIncidents.queued().is_empty())
	)

	run_case("turf_flip_involving_player_queues_fallout_and_flips_are_consumed", func():
		_fresh()
		FactionIncidents.record_flip("shoreditch", "player", "firm")
		FactionIncidents.record_flip("soho", "guild", "network")
		FactionIncidents.daily_tick()
		assert_eq(_queued_ids(), ["inc_turf_flip_fallout"])
		assert_eq(FactionIncidents.queued()[0]["context"]["district"], "shoreditch")
		assert_true(GameState.state["factionIncidents"]["flips"].is_empty())
	)

	run_case("cooldown_lapses_and_refires", func():
		_fresh()
		FactionIncidents.record_flip("shoreditch", "player", "firm")
		FactionIncidents.daily_tick()
		GameState.state["world"]["day"] = 40
		FactionIncidents.record_flip("shoreditch", "player", "firm")
		FactionIncidents.daily_tick()
		assert_eq(FactionIncidents.queued().size(), 2)
	)

	run_case("pending_tap_starts_the_queued_event_with_its_context", func():
		_fresh()
		Grudges.record("firm", "shoreditch")
		FactionIncidents.daily_tick()
		FactionIncidents.start_pending(_pending_kinds()[0]["id"])
		assert_eq(GameState.state["event"]["eventId"], "inc_raided_revenge")
		assert_eq(GameState.state["event"]["context"]["faction_id"], "firm")
		assert_true(FactionIncidents.queued().is_empty())
		assert_true(_pending_kinds().is_empty())
	)

	run_case("old_save_backfills_empty_state", func():
		_fresh()
		var save := GameState.state.duplicate(true)
		save.erase("factionIncidents")
		var result: Dictionary = SaveManager.backfill_defaults(save)
		assert_eq(result["factionIncidents"], FactionIncidents.new_state())
	)
