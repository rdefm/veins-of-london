extends "res://tests/test_base.gd"

# 01-debug-app: DebugTools' two adjusters, tested standalone against
# GameState.state -- same "system function mutates state, screen never
# touches it directly" contract as every other systems/*.gd file.


func run() -> void:
	run_case("add_cash_adds_the_given_amount_to_player_cash", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100

		DebugTools.add_cash(250)

		assert_eq(GameState.state["player"]["cash"], 350, "cash increases by the given amount")
	)

	run_case("add_cash_can_take_a_negative_amount", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100

		DebugTools.add_cash(-40)

		assert_eq(GameState.state["player"]["cash"], 60, "cash decreases when given a negative amount")
	)

	run_case("add_calc_adds_the_given_amount_to_the_chosen_ore_type", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["physics"] = 5

		DebugTools.add_calc("physics", 30)

		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 35, "physics ore increases by the given amount")

		for ore_type in GameData.ORE_TYPES.keys():
			if ore_type != "physics":
				assert_eq(GameState.state["player"]["orichalchum"].get(ore_type, 0), 0, "no other ore type is touched (%s)" % ore_type)
	)

	run_case("add_calc_works_from_an_unseeded_ore_type", func():
		GameState.reset()
		assert_eq(GameState.state["player"]["orichalchum"].get("time", 0), 0, "sanity: player.orichalchum starts empty")

		DebugTools.add_calc("time", 12)

		assert_eq(GameState.state["player"]["orichalchum"]["time"], 12, "adding to a never-seeded ore type starts from 0, not an error")
	)

	run_case("event_ids_lists_every_loaded_event", func():
		var ids := DebugTools.event_ids()
		assert_eq(ids.size(), GameData.EVENTS.size(), "one id per data/events/*.json")
		for event_id in GameData.EVENTS:
			assert_true(event_id in ids, "%s is listed" % event_id)
	)

	run_case("every_event_fires_and_plays_through_from_debug_start_without_errors", func():
		var catcher := ErrorCatcher.new()
		OS.add_logger(catcher)
		for event_id in DebugTools.event_ids():
			for branch in range(_max_choice_count(event_id)):
				DebugStart.apply()
				catcher.errors.clear()
				DebugTools.fire_event(event_id)
				var ended := _play_out(branch)
				assert_true(catcher.errors.is_empty(), "%s (choice %d) raised no errors: %s" % [event_id, branch, catcher.errors])
				assert_true(ended, "%s (choice %d) played to its end or handed off to combat" % [event_id, branch])
		OS.remove_logger(catcher)
	)

	run_case("vein_raid_gets_an_enemy_held_target_site", func():
		DebugStart.apply()
		DebugTools.fire_event("vein_raid")

		var context: Dictionary = GameState.state["event"]["context"]
		var site: Variant = Sites.find_site(context["site_id"])
		assert_true(site != null and site["factionVein"] != null, "context site carries a faction vein")
		assert_true(site["factionVein"]["factionId"] != "collective", "and it isn't the Collective's")
	)

	run_case("hakim_done_sells_a_granted_hakim_vein_to_the_collective", func():
		DebugStart.apply()
		assert_eq(GameState.state["collective"]["hakimVeinId"], null, "sanity: no Hakim vein on a debug start")
		DebugTools.fire_event("col_a1_hakim_done")
		_play_out(0)

		var site_id := _site_holding_faction_vein(GameState.state["collective"]["hakimVeinId"])
		assert_true(site_id != "", "Hakim's vein ended up faction-held")
		assert_eq(Sites.find_site(site_id)["factionVein"]["factionId"], "collective", "sold to the Collective")
	)

	run_case("hakim_retake_takes_a_firm_held_hakim_vein_back_and_ruins_it", func():
		DebugStart.apply()
		DebugTools.fire_event("col_a2_hakim_retake")
		var vein_id: Variant = GameState.state["collective"]["hakimVeinId"]
		var site_id := _site_holding_faction_vein(vein_id)
		assert_true(site_id != "", "setup leaves Hakim's vein faction-held")
		assert_eq(Sites.find_site(site_id)["factionVein"]["factionId"], "firm", "by the Firm")

		_play_out(0)
		assert_true(Sites.find_site(site_id).get("ruinedByFirm", false), "Take it back claims then ruins the site")
	)

	run_case("contested_vein_claim_lands_on_a_seeded_faction_site", func():
		DebugStart.apply()
		DebugTools.fire_event("col_a2_contested_vein")
		var site: Variant = Sites.find_site(GameState.state["collective"]["contestedVeinSiteId"])
		assert_true(site != null and site["factionVein"] != null, "setup seeds a faction vein at contestedVeinSiteId")

		_play_out(0)
		assert_true(Sites.find_site(site["id"])["claimed"], "the claim choice takes the site")
	)

	run_case("reveal_site_events_get_an_unclaimed_site_in_context", func():
		DebugStart.apply()
		DebugTools.fire_event("col_hakim_intel")
		var site: Variant = Sites.find_site(GameState.state["event"]["context"]["site_id"])
		assert_true(site != null and not site["claimed"] and site["factionVein"] == null, "a fresh unclaimed site to reveal")
	)

	run_case("fire_event_unlocks_contacts_its_effects_address", func():
		DebugStart.apply()
		assert_eq(GameState.state["contacts"]["des"]["unlocked"], false, "sanity: Des locked on a debug start")
		DebugTools.fire_event("col_a1_seeding")
		assert_eq(GameState.state["contacts"]["des"]["unlocked"], true, "unlocked because the event queues Des a message")
	)


# Runtime errors (not warnings) logged while a case runs.
class ErrorCatcher extends Logger:
	var errors: Array = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		errors.append("%s:%d %s %s" % [file, line, function, rationale if rationale != "" else code])


static func _max_choice_count(event_id: String) -> int:
	var most := 1
	for card in GameData.EVENTS[event_id]["cards"]:
		most = maxi(most, card.get("choices", []).size())
	return most


# Continues/chooses (choice index clamped to branch) until the event ends or
# hands off to another screen (combat). False if it never got there.
static func _play_out(branch: int) -> bool:
	for step in range(200):
		if GameState.state["event"] == null or GameState.state["currentScreen"] != "event":
			return true
		if Events.is_awaiting_choice():
			Events.choose(mini(branch, Events.current_card()["choices"].size() - 1))
		else:
			Events.advance()
	return false


static func _site_holding_faction_vein(vein_id: Variant) -> String:
	for site in GameState.state["world"]["sites"]:
		if site["factionVein"] != null and site["factionVein"]["id"] == vein_id:
			return site["id"]
	return ""
