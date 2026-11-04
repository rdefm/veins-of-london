extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# Todo — the Phone "ToDo" app's checklist (R§3.11). Ticket 79: rewritten
# against the objective-backed model (data/objectives.json's "tutorial"
# questline replaces the old hardcoded flag chain; systems/objectives.gd's
# generic engine drives active/done for both it and Collective). Todo itself
# is a pure read now, so every case that changes a flag after GameState.
# reset() calls Objectives.refresh() explicitly first, same as
# tests/test_objectives.gd already does — reset() only covers the boot-time
# refresh, not any flag flip a test makes afterward.


func _synthetic(id: String, questline: String, activate_flag: Variant, complete_flag: String) -> Dictionary:
	return {
		"id": id, "title": id, "detail": "", "type": "flag_true",
		"params": {}, "activateFlag": activate_flag,
		"completeFlag": complete_flag, "questline": questline,
	}


func _section(sections: Array, questline: String) -> Variant:
	for s in sections:
		if s["questline"] == questline:
			return s
	return null


func run() -> void:
	run_case("fresh_game_shows_only_the_first_tutorial_item_undone", func():
		GameState.reset()
		var sections := Todo.get_questline_sections()
		assert_eq(sections.map(func(s): return s["questline"]), ["tutorial", "business_empire"], "tutorial is the only started questline; Business Empire is always listed as a placeholder")
		assert_eq(sections[0]["status"], "active")
		assert_eq(sections[0]["defaultExpanded"], true, "an active questline starts expanded")
		var items: Array = sections[0]["items"]
		assert_eq(items.size(), 1, "only the first checkpoint should be unlocked at game start")
		assert_eq(items[0]["done"], false, "first checkpoint should be undone")
		assert_eq(items[0]["title"], "Get out of Mile End in one piece.", "first checkpoint text")
	)

	run_case("buyer_wait_text_depends_on_day", func():
		GameState.reset()
		GameState.state["flags"]["coldOpenSeen"] = true
		GameState.state["flags"]["metArchie"] = true
		GameState.state["world"]["day"] = 1
		Objectives.refresh()
		var items: Array = _section(Todo.get_questline_sections(), "tutorial")["items"]
		assert_eq(items[2]["title"], "Wait for Archie's text — he's lining up the buyer.", "day < 2 shows the waiting text")

		GameState.state["world"]["day"] = 2
		items = _section(Todo.get_questline_sections(), "tutorial")["items"]
		assert_eq(items[2]["title"], "Back up Archie on the sale tonight. Check Contacts.", "day >= 2 shows the follow-up text")
	)

	run_case("every_unlocked_tutorial_item_is_listed_uncapped", func():
		GameState.reset()
		var flags: Dictionary = GameState.state["flags"]
		flags["coldOpenSeen"] = true
		flags["metArchie"] = true
		flags["buyerEventSeen"] = true
		Lab.grant_recipe("timePearl")
		flags["gymUnlocked"] = true
		flags["archieSoldPearls"] = true
		flags["homeRaidEventSeen"] = true
		Objectives.refresh()

		var items: Array = _section(Todo.get_questline_sections(), "tutorial")["items"]
		assert_true(items.size() > 4, "no per-section cap")
		var last: Dictionary = items[items.size() - 1]
		assert_eq(last["title"], "Work the vein Archie gave you.", "the newest unlocked item should be last")
		assert_eq(last["done"], false, "the newest unlocked item is the one current objective")
		assert_eq(items.filter(func(item): return not item["done"]).size(), 1, "exactly one undone Prologue objective")
	)

	run_case("final_tutorial_item_shows_checked_then_the_section_turns_done_on_prologueDone", func():
		# The last objective completes and renders checked; the section turns
		# done on the later, distinct gate flag (prologueDone, set by the ending).
		GameState.reset()
		var flags: Dictionary = GameState.state["flags"]
		for f in ["coldOpenSeen", "metArchie", "buyerEventSeen", "gymUnlocked", "archieSoldPearls", "homeRaidEventSeen", "cultivationTutorialSeen", "rentPaid"]:
			flags[f] = true
		Lab.grant_recipe("timePearl")
		Objectives.refresh()

		var items: Array = _section(Todo.get_questline_sections(), "tutorial")["items"]
		assert_eq(items[items.size() - 1]["title"], "Pay Monday's rent in full.", "the final objective should be the newest unlocked item")
		assert_eq(items[3]["done"], true, "the final objective should render checked")

		flags["prologueDone"] = true
		Objectives.refresh()
		var tutorial: Dictionary = _section(Todo.get_questline_sections(), "tutorial")
		assert_eq(tutorial["status"], "done", "the tutorial section should turn done once the questline's gate flag is true")
		assert_eq(tutorial["defaultExpanded"], false, "a completed questline starts collapsed")
		assert_eq(tutorial["items"].size(), 9, "a done section keeps its items for the collapsed view")
	)

	run_case("flat_raid_objective_completes_with_the_real_debrief_event_not_stale", func():
		# Drives the real prologue_home_raid_debrief_win event, with no test-side
		# refresh() call, to prove the real event path leaves nothing stale.
		GameState.reset()
		for f in ["coldOpenSeen", "metArchie", "buyerEventSeen", "gymUnlocked", "archieSoldPearls"]:
			GameState.state["flags"][f] = true
		Lab.grant_recipe("timePearl")
		Objectives.refresh()
		Events.start_event("prologue_home_raid_debrief_win")
		for i in range(GameData.EVENTS["prologue_home_raid_debrief_win"]["cards"].size()):
			Events.advance()

		assert_true(GameState.state["objectives"]["pro_flat_raid"]["complete"], "complete flips true in the same on_complete call that sets homeRaidEventSeen -- no stale window")
		var items: Array = _section(Todo.get_questline_sections(), "tutorial")["items"]
		assert_eq(items[items.size() - 1]["title"], "Work the vein Archie gave you.", "the vein objective follows the raid")
	)

	run_case("sections_group_by_questline_and_the_whole_section_turns_done_on_its_gate_flag", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"syn_a": _synthetic("syn_a", "collective", null, "synA"),
			"syn_b": _synthetic("syn_b", "collective", "synA", "synB"),
		})
		GameState.state["flags"]["synA"] = true
		Objectives.refresh()

		var sections := Todo.get_questline_sections()
		var collective_section = _section(sections, "collective")
		assert_true(collective_section != null, "a section should appear for a questline with an active objective")
		assert_eq(collective_section["label"], "Collective")
		assert_eq(collective_section["items"].size(), 2, "both active synthetic objectives should be grouped into one section")
		assert_eq(collective_section["items"][0]["done"], true, "syn_a is complete (its own flag is true)")
		assert_eq(collective_section["items"][1]["done"], false, "syn_b hasn't completed yet")

		GameState.state["flags"]["colA1Complete"] = true
		sections = Todo.get_questline_sections()
		assert_eq(_section(sections, "collective")["status"], "active", "gate flag alone doesn't finish a section with an undone active goal")

		GameState.state["flags"]["synB"] = true
		Objectives.refresh()
		sections = Todo.get_questline_sections()
		assert_eq(_section(sections, "collective")["status"], "done", "gate flag + every goal complete turns the section done")

		GameData.OBJECTIVES = original
	)

	run_case("unstarted_questlines_are_omitted_but_business_empire_is_always_a_placeholder", func():
		GameState.reset()
		var sections := Todo.get_questline_sections()
		assert_eq(_section(sections, "collective"), null, "no Collective section before any of its objectives activate")
		var empire: Dictionary = _section(sections, "business_empire")
		assert_eq(empire["status"], "placeholder")
		assert_eq(empire["items"], [], "the placeholder has no objectives yet")
		assert_true(empire["emptyText"] != "", "the placeholder carries its empty-state line")
		assert_eq(sections[sections.size() - 1]["questline"], "business_empire", "sections follow QUESTLINES' declaration order")
	)

	run_case("collective_ledger_renders_under_the_collective_section_and_keeps_it_active", func():
		GameState.reset()
		GameState.state["flags"]["colA1Complete"] = true
		GameState.state["flags"]["colA2Stage"] = "hardening"
		var vein := Factions.create_faction_vein("collective", Fixtures.site("s1", "life", "fair"), 30)
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "life", "fair", false, vein)]

		var collective: Variant = _section(Todo.get_questline_sections(), "collective")
		assert_true(collective != null, "a live ledger shows the Collective section even with no active objectives")
		assert_eq(collective["ledger"].size(), 1, "the ledger rows ride inside the Collective section")
		assert_eq(collective["status"], "active", "Act 1's gate flag doesn't mark Collective done while the Act 2 ledger is live")
		assert_eq(collective["defaultExpanded"], true)
	)

	# ── Collective ledger (Act 2 §5.2) ───────────────────────────────────

	run_case("collective_ledger_is_empty_until_colA2Stage_reaches_hardening", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "life", "fair", false, Factions.create_faction_vein("collective", Fixtures.site("s1", "life", "fair"), 30))]
		assert_eq(Todo.get_collective_ledger(), [], "no colA2Stage flag at all should read as not unlocked")

		GameState.state["flags"]["colA2Stage"] = "call"
		assert_eq(Todo.get_collective_ledger(), [], "an earlier colA2Stage value should still hide the ledger")

		GameState.state["flags"]["colA2Stage"] = "hardening"
		assert_eq(Todo.get_collective_ledger().size(), 1, "colA2Stage 'hardening' unlocks the ledger")
	)

	run_case("collective_ledger_lists_only_collective_owned_faction_veins", func():
		GameState.reset()
		GameState.state["flags"]["colA2Stage"] = "hardening"
		var collective_vein := Factions.create_faction_vein("collective", Fixtures.site("s1", "physics", "rich"), 30)
		var firm_vein := Factions.create_faction_vein("firm", Fixtures.site("s2", "life", "fair"), 30)
		GameState.state["world"]["sites"] = [
			Fixtures.site("s1", "physics", "rich", false, collective_vein),
			Fixtures.site("s2", "life", "fair", false, firm_vein),
			Fixtures.site("s3", "time", "fair"),
		]

		var rows := Todo.get_collective_ledger()
		assert_eq(rows.size(), 1, "only the Collective-owned faction vein should appear, not the Firm's vein or the unclaimed site")
		assert_eq(rows[0]["district"], GameData.DISTRICTS["shoreditch"]["name"])
		assert_eq(rows[0]["oreType"], GameData.ORE_TYPES["physics"]["name"])
		assert_eq(rows[0]["security"], Cultivating.security_label(collective_vein))
	)

	run_case("no_board_section_when_meetings_are_off_or_no_goal_is_active", func():
		GameState.reset()
		assert_eq(_section(Todo.get_questline_sections(), "board"), null, "meetings off: no Board section")
		GameState.state["boardMeetings"]["enabled"] = true
		assert_eq(_section(Todo.get_questline_sections(), "board"), null, "meetings on but no goal chosen: no Board section")
	)

	run_case("board_section_lists_the_goal_with_tier_reached_and_progress_to_next", func():
		GameState.reset()
		Fixtures.board_reserve_goal(100)
		var sections := Todo.get_questline_sections()
		assert_eq(sections[sections.size() - 1]["questline"], "board", "Board is listed after every questline")
		var board: Dictionary = _section(sections, "board")
		assert_eq([board["label"], board["status"]], ["Board", "active"])
		var items: Array = board["items"]
		assert_eq(items.size(), 1)
		assert_eq([items[0]["title"], items[0]["detail"], items[0]["done"]], ["Build a cash reserve", "No tier yet · 0 of 2 weeks to Base", false])

		GameState.state["business"]["float"] = 250
		items = _section(Todo.get_questline_sections(), "board")["items"]
		assert_eq(items[0]["detail"], "Base reached · 2.5 of 3 weeks to Target")

		GameState.state["business"]["float"] = 400
		BoardMeetings.note_progress()
		GameState.state["business"]["float"] = 0
		items = _section(Todo.get_questline_sections(), "board")["items"]
		assert_eq(items[0]["detail"], "Stretch reached", "a locked stretch stays reached after a dip, with no next tier")
	)

	run_case("act2_section_lists_spine_beats_with_done_and_locked_state", func():
		GameState.reset()
		assert_eq(_section(Todo.get_questline_sections(), "act2"), null, "no Act 2 section while meetings are off")
		GameState.state["boardMeetings"]["enabled"] = true
		var section: Dictionary = _section(Todo.get_questline_sections(), "act2")
		assert_eq(section["status"], "active")
		assert_eq(section["items"].size(), GameData.BOARD_SPINE["beats"].size())
		assert_eq(section["items"][0]["done"], false)
		assert_eq(section["items"][1]["detail"], GameData.BOARD_SPINE["lockedText"], "beat 2 is locked until beat 1")
		GameState.state["boardMeetings"]["spine"]["share_target"] = "done"
		section = _section(Todo.get_questline_sections(), "act2")
		assert_eq([section["items"][0]["done"], section["items"][1]["detail"]], [true, ""])
		assert_true(not str(Todo.current_objective().get("id", "")).begins_with("spine_"), "the overview never becomes the Story row")
	)

	run_case("pages_carry_presentation_from_data_and_split_active_from_done", func():
		GameState.reset()
		var pages := Todo.get_pages()
		var tut: Dictionary = _page(pages, "tutorial")
		assert_eq(tut["label"], GameData.TODO_PAGES["questlines"]["tutorial"]["label"])
		assert_eq(tut["subtitle"], GameData.TODO_PAGES["questlines"]["tutorial"]["subtitle"])
		assert_eq(tut["accent"], GameData.TODO_PAGES["questlines"]["tutorial"]["accent"])
		assert_eq(tut["active"].size(), 1)
		assert_eq(tut["done"].size(), 0)
		GameState.state["flags"]["coldOpenSeen"] = true
		Objectives.refresh()
		tut = _page(Todo.get_pages(), "tutorial")
		assert_eq(tut["done"].map(func(i): return i["id"]), ["pro_cold_open"], "completed goals move to done")
		assert_true(tut["done"][0]["done"])
		assert_true(not tut.has("total"), "no n-of-N total is projected")
	)

	run_case("pages_order_started_then_placeholder_then_board_then_finished", func():
		GameState.reset()
		GameState.state["flags"]["prologueDone"] = true
		for oid in GameData.OBJECTIVES.keys():
			var odef: Dictionary = GameData.OBJECTIVES[oid]
			if odef["questline"] == "tutorial" and odef.has("completeFlag"):
				GameState.state["flags"][odef["completeFlag"]] = true
		Objectives.refresh()
		_activate_board_goal()
		for oid in GameState.state["objectives"].keys():
			if GameData.OBJECTIVES[oid]["questline"] == "tutorial":
				GameState.state["objectives"][oid]["complete"] = true
		var ids := Todo.get_pages().map(func(p): return p["id"])
		assert_eq(ids, ["act2", "business_empire", "board", "tutorial"], "started, placeholder, board, finished")
		GameState.state["flags"]["prologueDone"] = false
		Objectives.refresh()
		ids = Todo.get_pages().map(func(p): return p["id"])
		assert_eq(ids, ["tutorial", "act2", "business_empire", "board"], "started, placeholder, board")
	)

	run_case("done_flag_with_undone_active_goal_stays_active_then_done_when_all_complete", func():
		GameState.reset()
		GameState.state["flags"]["bizA1Proposed"] = true
		GameState.state["flags"]["bizA1Complete"] = true
		Objectives.refresh()
		var page: Dictionary = _page(Todo.get_pages(), "business_empire")
		assert_eq(page["status"], "active", "open goal keeps page active despite done flag")
		assert_true(page["active"].size() > 0)
		for id in GameData.OBJECTIVES.keys():
			var def: Dictionary = GameData.OBJECTIVES[id]
			if def["questline"] == "business_empire" and def.has("completeFlag"):
				GameState.state["flags"][def["completeFlag"]] = true
		Objectives.refresh()
		var done_ids := []
		for id in GameData.OBJECTIVES.keys():
			if GameData.OBJECTIVES[id]["questline"] == "business_empire" \
					and GameState.state["objectives"].get(id, {}).get("active", false) \
					and not GameState.state["objectives"][id].get("complete", false):
				done_ids.append(id)
		if done_ids.is_empty():
			page = _page(Todo.get_pages(), "business_empire")
			assert_eq(page["status"], "done", "all goals complete + flag = done")
	)

	run_case("placeholder_page_carries_empty_text", func():
		GameState.reset()
		var page: Dictionary = _page(Todo.get_pages(), "business_empire")
		assert_eq(page["status"], "placeholder")
		assert_eq(page["emptyText"], "Nothing on the books yet.")
		assert_eq(page["active"].size() + page["done"].size(), 0)
	)

	run_case("board_page_carries_base_target_stretch_steps", func():
		GameState.reset()
		_activate_board_goal()
		var board: Dictionary = _page(Todo.get_pages(), "board")
		assert_eq(board["steps"].map(func(s): return s["tier"]), ["base", "target", "stretch"])
		assert_eq(board["steps"].map(func(s): return s["target"]), ["2", "3", "4"])
		assert_eq(board["steps"].map(func(s): return s["reached"]), [false, false, false])
		GameState.state["boardMeetings"]["active"]["lockedTier"] = "target"
		board = _page(Todo.get_pages(), "board")
		assert_eq(board["steps"].map(func(s): return s["reached"]), [true, true, false])
		assert_eq(board["active"].size(), 1)
	)

	run_case("collective_ledger_is_on_its_page", func():
		GameState.reset()
		GameState.state["flags"]["colA1Complete"] = true
		GameState.state["flags"]["colA2Stage"] = "hardening"
		var vein := Factions.create_faction_vein("collective", Fixtures.site("s1", "life", "fair"), 30)
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "life", "fair", false, vein)]
		var page: Variant = _page(Todo.get_pages(), "collective")
		assert_true(page != null)
		assert_eq(page["ledger"].size(), 1)
	)

	run_case("pip_shows_on_change_and_clears_when_seen", func():
		GameState.reset()
		assert_true(_page(Todo.get_pages(), "tutorial")["pip"], "first goal is new")
		Todo.mark_seen("tutorial")
		assert_true(not _page(Todo.get_pages(), "tutorial")["pip"])
		GameState.state["flags"]["coldOpenSeen"] = true
		Objectives.refresh()
		assert_true(_page(Todo.get_pages(), "tutorial")["pip"], "a new goal re-raises the pip")
		assert_true(not _page(Todo.get_pages(), "business_empire")["pip"], "untouched page has no pip")
	)

	run_case("default_page_is_the_most_recently_changed", func():
		GameState.reset()
		var pages := Todo.get_pages()
		assert_eq(pages[Todo.default_page_index()]["id"], "tutorial")
		_activate_board_goal()
		Objectives.refresh()
		pages = Todo.get_pages()
		assert_eq(pages[Todo.default_page_index()]["id"], "board", "newest change wins")
		Todo.mark_seen("board")
		assert_eq(Todo.get_pages()[Todo.default_page_index()]["id"], "board", "seen does not move the choice")
	)

	run_case("old_saves_backfill_todo_state", func():
		GameState.reset()
		var old_save: Dictionary = GameState.deep_copy(GameState.state)
		old_save.erase("todo")
		var filled: Dictionary = SaveManager.backfill_defaults(old_save)
		assert_eq(filled["todo"], Todo.new_state())
	)


func _page(pages: Array, id: String) -> Variant:
	for p in pages:
		if p["id"] == id:
			return p
	return null


func _activate_board_goal() -> void:
	GameState.state["boardMeetings"]["enabled"] = true
	GameState.state["boardMeetings"]["active"] = {
		"rung": "fin_reserve", "template": "fin_reserve", "ore": "", "faction": "",
		"goal": { "id": "fin_reserve", "type": "reserve_weeks_at_least", "params": {} },
		"tiers": {},
		"progress": Objectives.initial_progress("reserve_weeks_at_least"), "lockedTier": Objectives.TIER_NONE,
	}
	GameState.state["boardMeetings"]["active"]["goal"]["tiers"] = { "base": { "minWeeks": 2 }, "target": { "minWeeks": 3 }, "stretch": { "minWeeks": 4 } }
