extends "res://tests/test_base.gd"

const FACTION_IDS := ["collective", "firm", "guild", "network", "conclave"]


static func _days(n: int) -> void:
	for i in n:
		FactionAI.update_stances()


static func _set_pair(a: String, b: String, value: int) -> void:
	Factions.adjust_relation(a, b, value - Factions.get_relation(a, b))


static func _log_texts(faction_id: String) -> Array:
	return FactionAI.activity_log(faction_id).map(func(e: Dictionary) -> String: return e["text"])


func run() -> void:
	run_case("london_starts_with_the_canonical_stances_inside_their_bands", func():
		GameState.reset()
		assert_eq(FactionAI.pair_stance("collective", "firm"), FactionAI.HOSTILE)
		assert_eq(FactionAI.pair_stance("firm", "collective"), FactionAI.HOSTILE, "pairs are symmetric")
		assert_eq(FactionAI.pair_stance("guild", "conclave"), FactionAI.BUSINESS_RIVAL)
		assert_eq(FactionAI.pair_stance("network", "conclave"), FactionAI.BUSINESS_RIVAL)
		assert_eq(FactionAI.pair_stance("collective", "guild"), FactionAI.PARTNER)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.NEUTRAL)
		assert_eq(FactionAI.pair_stance("collective", "network"), FactionAI.NEUTRAL)
		for faction_id in FACTION_IDS:
			assert_eq(FactionAI.player_stance(faction_id), FactionAI.NEUTRAL, "%s player stance" % faction_id)
		_days(10)
		for i in FACTION_IDS.size():
			for j in range(i + 1, FACTION_IDS.size()):
				var a: String = FACTION_IDS[i]
				var b: String = FACTION_IDS[j]
				assert_eq(FactionAI.pair_stance(a, b), FactionAI.starting_pair_stance(a, b), "%s-%s holds its starting stance" % [a, b])
	)

	run_case("a_new_band_flips_the_stance_only_after_the_hysteresis_days", func():
		GameState.reset()
		_set_pair("firm", "guild", 60)
		_days(2)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.NEUTRAL, "two days in the band is not enough")
		_days(1)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.PARTNER, "third day flips")
		assert_true(_log_texts("firm").has("Now Partner with The Guild."), "logged on the Firm")
		assert_true(_log_texts("guild").has("Now Partner with Firm."), "logged on the Guild")
	)

	run_case("leaving_the_new_band_resets_the_hysteresis_count", func():
		GameState.reset()
		_set_pair("firm", "guild", 60)
		_days(2)
		_set_pair("firm", "guild", 0)
		_days(1)
		_set_pair("firm", "guild", 60)
		_days(2)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.NEUTRAL, "count restarted")
		_days(1)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.PARTNER)
	)

	run_case("business_rival_needs_an_overlap_else_neutral", func():
		GameState.reset()
		_set_pair("firm", "guild", -20)
		_set_pair("collective", "guild", -20)
		_days(3)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.BUSINESS_RIVAL, "Firm and Guild share physics")
		assert_eq(FactionAI.pair_stance("collective", "guild"), FactionAI.NEUTRAL, "Collective and Guild share nothing")
		_set_pair("collective", "guild", -45)
		_days(3)
		assert_eq(FactionAI.pair_stance("collective", "guild"), FactionAI.HOSTILE, "Hostile needs no overlap")
	)

	run_case("player_business_rival_needs_five_percent_share_in_a_faction_ore", func():
		GameState.reset()
		Factions.adjust_player_relation("firm", -20)
		Shares.record_ore("player", "physics", 1)
		Shares.record_ore("firm", "physics", 24)
		_days(3)
		assert_eq(FactionAI.player_stance("firm"), FactionAI.NEUTRAL, "4% of physics is below the bar")
		Shares.record_craft("player", { "life": 1 })
		Shares.record_craft("firm", { "life": 9 })
		_days(3)
		assert_eq(FactionAI.player_stance("firm"), FactionAI.BUSINESS_RIVAL, "10% of life crafting overlaps")
	)

	run_case("a_player_stance_change_sends_a_key_member_message_and_logs_it", func():
		GameState.reset()
		Factions.adjust_player_relation("firm", 60)
		_days(3)
		assert_eq(FactionAI.player_stance("firm"), FactionAI.PARTNER)
		var thread: Array = GameState.state["messages"].get("lusk", [])
		var line: String = GameData.FACTION_STANCES["lines"]["firm"]["partner"]
		assert_true(thread.any(func(m: Dictionary) -> bool: return m["text"] == line), "Lusk sends the partner line")
		assert_true(_log_texts("firm").has("Your standing: Partner."), "activity log entry")
	)

	run_case("the_collective_player_stance_holds_neutral_until_its_questline_ends", func():
		GameState.reset()
		Factions.adjust_player_relation("collective", 60)
		_days(5)
		assert_eq(FactionAI.player_stance("collective"), FactionAI.NEUTRAL, "held mid-questline")
		GameState.state["flags"]["colA2Complete"] = true
		_days(3)
		assert_eq(FactionAI.player_stance("collective"), FactionAI.PARTNER, "follows relation once done")
	)

	run_case("the_activity_log_is_bounded_oldest_first_out", func():
		GameState.reset()
		var cap: int = GameData.FACTION_STANCES["activityLogCap"]
		for i in cap + 5:
			FactionAI.log_activity("guild", "entry %d" % i)
		var texts := _log_texts("guild")
		assert_eq(texts.size(), cap)
		assert_eq(texts[0], "entry 5", "oldest dropped")
		assert_eq(texts[-1], "entry %d" % (cap + 4), "newest kept")
	)

	run_case("the_daily_rollover_runs_the_stance_update", func():
		GameState.reset()
		Factions.adjust_player_relation("guild", -60)
		for i in 3:
			TimeSystem.daily_tick()
		assert_eq(FactionAI.player_stance("guild"), FactionAI.HOSTILE)
	)
