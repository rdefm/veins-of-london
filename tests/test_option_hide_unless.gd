extends "res://tests/test_base.gd"

# Option requires.hideUnless (R§3.9a "Requires"): a failing hideUnless hides
# the option whatever its own condition; a holding one leaves requires/display
# as they are.

const GUARDED := { "securityProfile": { "guards": 1 } }
const UNGUARDED := { "securityProfile": { "guards": 0 } }
const HIDE_UNLESS := { "security": { "feature": "guards", "atLeast": 1 } }


static func _install_event() -> Dictionary:
	var original: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_hide_unless"] = {
		"id": "test_hide_unless",
		"cards": [
			{ "type": "choice", "key": "room", "label": null, "speaker": null, "text": "Room", "choices": [
				{ "label": "Slip past", "requires": { "item": "timePearl", "display": "disable", "hideUnless": HIDE_UNLESS }, "effects": [], "result_text": "Past." },
				{ "label": "Wave", "requires": { "hideUnless": HIDE_UNLESS }, "effects": [], "result_text": "Waved." },
				{ "label": "Breathe", "requires": { "item": "timePearl", "optional": true, "display": "disable", "hideUnless": HIDE_UNLESS },
					"check": { "base": 0.5, "mods": [{ "item": "timePearl", "optional": true, "add": 0.1 }], "min": 0.0, "max": 1.0 },
					"success": { "result_text": "s", "effects": [] }, "fail": { "result_text": "f", "effects": [] } },
				{ "label": "Leave", "effects": [], "result_text": "Out." },
			] },
		],
		"on_complete": [],
	}
	GameData.EVENTS["test_hide_unless_hub"] = {
		"id": "test_hide_unless_hub",
		"cards": [
			{ "type": "choice", "key": "hub", "advance": "all", "label": null, "speaker": null, "text": "Hub", "choices": [
				{ "label": "Ask", "effects": [], "result_text": "Asked.", "goto": "hub" },
				{ "label": "Ask the guard", "requires": { "hideUnless": HIDE_UNLESS }, "effects": [], "result_text": "Asked him.", "goto": "hub" },
				{ "label": "Go", "exit": true, "effects": [], "result_text": "Gone." },
			] },
			{ "type": "narration", "key": "out", "label": null, "speaker": null, "text": "Out" },
		],
		"on_complete": [],
	}
	return original


func run() -> void:
	run_case("failing_hide_unless_hides_whatever_requires_says_and_choose_refuses", func():
		GameState.reset()
		var original := _install_event()
		Crafting.inventory_add("timePearl", 1, 1)
		Events.start_event("test_hide_unless", UNGUARDED)
		for i in 3:
			assert_eq(Events.option_gate(i)["display"], "hide", "option %d hidden without guards" % i)
			assert_eq(Events.unmet_requirement_lines(i), [], "option %d lists no lines" % i)
		Events.choose(0)
		assert_true(Events.is_awaiting_choice(), "a hidden option can't be committed")
		assert_eq(Events.option_gate(3)["display"], "show", "an ungated option still shows")
		GameState.state["event"] = null
		GameData.EVENTS = original
	)

	run_case("holding_hide_unless_falls_through_to_requires_and_display", func():
		GameState.reset()
		var original := _install_event()
		Events.start_event("test_hide_unless", GUARDED)
		assert_eq(Events.option_gate(0)["display"], "disable", "item missing: greyed")
		assert_eq(Events.unmet_requirement_lines(0), ["Needs: Time Pearl in your bag"], "the ? modal names the item, not the guards")
		assert_eq(Events.option_gate(2)["display"], "disable", "optional item off: greyed")
		Crafting.inventory_add("timePearl", 1, 1)
		assert_eq(Events.option_gate(0)["display"], "show", "item held: shows")
		assert_eq(Events.option_gate(2)["display"], "show", "owned unlock item: on by default, shows")
		Events.choose(0)
		assert_true(not Events.is_awaiting_choice(), "a shown option commits")
		GameState.state["event"] = null
		GameData.EVENTS = original
	)

	run_case("hide_unless_alone_shows_when_it_holds", func():
		GameState.reset()
		var original := _install_event()
		Events.start_event("test_hide_unless", GUARDED)
		assert_eq(Events.option_gate(1)["display"], "show", "guards present: shows")
		assert_eq(Events.unmet_requirement_lines(1), [])
		GameState.state["event"] = null
		Events.start_event("test_hide_unless", UNGUARDED)
		assert_eq(Events.option_gate(1)["display"], "hide", "no guards: hidden")
		GameState.state["event"] = null
		GameData.EVENTS = original
	)

	run_case("hub_advance_all_skips_a_hide_unless_hidden_question", func():
		GameState.reset()
		var original := _install_event()
		Events.start_event("test_hide_unless_hub", UNGUARDED)
		assert_true(not Events.hub_exit_available(), "one question still to ask")
		Events.choose(0)
		Events.advance()
		assert_true(Events.hub_exit_available(), "the hidden question doesn't count")
		GameState.state["event"] = null
		Events.start_event("test_hide_unless_hub", GUARDED)
		Events.choose(0)
		Events.advance()
		assert_true(not Events.hub_exit_available(), "with guards the second question counts")
		GameState.state["event"] = null
		GameData.EVENTS = original
	)
