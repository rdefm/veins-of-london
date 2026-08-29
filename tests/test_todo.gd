extends "res://tests/test_base.gd"

# Todo — the Phone "Notes" app's checklist (R§3.11). Ticket 79: rewritten
# against the objective-backed model (data/objectives.json's "tutorial"
# questline replaces the old hardcoded flag chain; systems/objectives.gd's
# generic engine drives active/done for both it and Collective). Todo itself
# is a pure read now, so every case that changes a flag after GameState.
# reset() calls Objectives.refresh() explicitly first, same as
# tests/test_objectives.gd already does — reset() only covers the boot-time
# refresh, not any flag flip a test makes afterward.


# Installs a synthetic GameData.OBJECTIVES set (same pattern
# tests/test_objectives.gd uses) so the grouping/hiding test below doesn't
# depend on real col_a1_* prose or thread structure. Returns the original
# for restoration.
func _install_objectives(entries: Dictionary) -> Dictionary:
	var original: Dictionary = GameData.OBJECTIVES
	GameData.OBJECTIVES = entries.duplicate(true)
	return original


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
		var sections := Todo.get_active_questlines()
		assert_eq(sections.size(), 1, "only the tutorial questline should be active at game start")
		assert_eq(sections[0]["questline"], "tutorial")
		var items: Array = sections[0]["items"]
		assert_eq(items.size(), 1, "only the first checkpoint should be unlocked at game start")
		assert_eq(items[0]["done"], false, "first checkpoint should be undone")
		assert_eq(items[0]["title"], "Get back to Archie. He's sorting the new buyer.", "first checkpoint text")
	)

	run_case("buyer_wait_text_depends_on_day", func():
		GameState.reset()
		GameState.state["flags"]["metArchie"] = true
		GameState.state["world"]["day"] = 1
		Objectives.refresh()
		var items: Array = _section(Todo.get_active_questlines(), "tutorial")["items"]
		assert_eq(items[1]["title"], "Wait for Archie's text — he's lining up the buyer.", "day < 2 shows the waiting text")

		GameState.state["world"]["day"] = 2
		items = _section(Todo.get_active_questlines(), "tutorial")["items"]
		assert_eq(items[1]["title"], "Back up Archie on the sale tonight. Check Contacts.", "day >= 2 shows the follow-up text")
	)

	run_case("only_the_last_4_tutorial_items_are_shown", func():
		GameState.reset()
		var flags: Dictionary = GameState.state["flags"]
		flags["metArchie"] = true
		flags["buyerEventSeen"] = true
		flags["metJames"] = true
		flags["craftingUnlocked"] = true
		flags["archieCraftChatSeen"] = true
		flags["homeRaidEventSeen"] = true
		# archiePartnerSeen deliberately left false here -- see the next case.
		Objectives.refresh()

		var items: Array = _section(Todo.get_active_questlines(), "tutorial")["items"]
		assert_eq(items.size(), 4, "checklist should cap at 4 items")
		assert_eq(items[3]["title"], "You have calc now. The flat isn't as secure as you thought.", "the newest unlocked item should be last")
		assert_eq(items[3]["done"], true, "the newest unlocked item's flag is already true")
	)

	run_case("final_tutorial_item_shows_checked_then_the_whole_section_hides_on_cultivationTutorialSeen", func():
		# ticket 79: the old flag chain's last entry unlocked and then sat
		# permanently unchecked forever. Now it completes and renders
		# checked like any other item, and the whole section disappears on
		# a later, distinct gate flag -- same shape Collective's colA1Complete
		# gives it, not the item's own completeFlag (archiePartnerSeen),
		# which would hide the section in the same instant the item
		# completed, and it would never render checked at all.
		GameState.reset()
		var flags: Dictionary = GameState.state["flags"]
		for f in ["metArchie", "buyerEventSeen", "metJames", "craftingUnlocked", "archieCraftChatSeen", "homeRaidEventSeen", "archiePartnerSeen"]:
			flags[f] = true
		Objectives.refresh()

		var items: Array = _section(Todo.get_active_questlines(), "tutorial")["items"]
		assert_eq(items[3]["title"], "Archie's time vein is yours. You cultivate and harvest it — Archie sells what you make.", "the final checkpoint should be the newest unlocked item")
		assert_eq(items[3]["done"], true, "the final checkpoint should render checked, not stuck unchecked forever")

		flags["cultivationTutorialSeen"] = true
		Objectives.refresh()
		var sections := Todo.get_active_questlines()
		assert_eq(_section(sections, "tutorial"), null, "the whole tutorial section should hide once the questline's gate flag is true")
	)

	run_case("archie_partner_line_renders_checked_immediately_after_the_real_debrief_event_not_stale", func():
		# ticket 90's investigation: is "Archie's time vein is yours..."
		# rendering unchecked because state.objectives["tut_archie_partner"].
		# complete is genuinely still false (a refresh() staleness bug), or
		# because it renders checked but the wording still reads like an
		# active instruction (a legibility problem)? Unlike the synthetic
		# case above (which sets flags directly and calls Objectives.refresh()
		# itself), this drives the real home_raid_debrief_win event -- whose
		# on_complete sets homeRaidEventSeen and archiePartnerSeen together,
		# then Events.apply_effects() calls Objectives.refresh() once at the
		# end (events.gd's boundary #6) -- with no test-side refresh() call,
		# to prove the real event path leaves nothing stale. It comes back
		# complete/checked immediately, confirming the bug (human playtest,
		# ticket 90 item 4) is the wording reading like a command despite the
		# checkmark, not a staleness bug -- hence the title reword above,
		# not a code fix here.
		GameState.reset()
		Events.start_event("home_raid_debrief_win")
		for i in range(GameData.EVENTS["home_raid_debrief_win"]["cards"].size()):
			Events.advance()

		assert_true(GameState.state["objectives"]["tut_archie_partner"]["complete"], "complete flips true in the same on_complete call that sets archiePartnerSeen -- no stale window")
		var items: Array = _section(Todo.get_active_questlines(), "tutorial")["items"]
		var last_item: Dictionary = items[items.size() - 1]
		assert_eq(last_item["title"], "Archie's time vein is yours. You cultivate and harvest it — Archie sells what you make.")
		assert_eq(last_item["done"], true, "renders checked with no extra refresh() call needed -- ruling out staleness")
	)

	run_case("sections_group_by_questline_and_the_whole_section_hides_on_its_gate_flag", func():
		GameState.reset()
		var original := _install_objectives({
			"syn_a": _synthetic("syn_a", "collective", null, "synA"),
			"syn_b": _synthetic("syn_b", "collective", "synA", "synB"),
		})
		GameState.state["flags"]["synA"] = true
		Objectives.refresh()

		var sections := Todo.get_active_questlines()
		var collective_section = _section(sections, "collective")
		assert_true(collective_section != null, "a section should appear for a questline with an active objective")
		assert_eq(collective_section["label"], "Collective")
		assert_eq(collective_section["items"].size(), 2, "both active synthetic objectives should be grouped into one section")
		assert_eq(collective_section["items"][0]["done"], true, "syn_a is complete (its own flag is true)")
		assert_eq(collective_section["items"][1]["done"], false, "syn_b hasn't completed yet")

		GameState.state["flags"]["colA1Complete"] = true
		sections = Todo.get_active_questlines()
		assert_eq(_section(sections, "collective"), null, "the whole section should hide on the questline's gate flag, not item-by-item")

		GameData.OBJECTIVES = original
	)
