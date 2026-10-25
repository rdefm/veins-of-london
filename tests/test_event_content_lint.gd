extends "res://tests/test_base.gd"

const EventContentLint := preload("res://tests/support/event_content_lint.gd")

# Card label tokens (R§3.9c) and the event content lint: a data test over
# every event definition. Rules: card-label time words agree with the
# event's `at`; every `goto` targets a later card in the same event; a card's
# conditional goto list is well formed; `end` is `true` and never sits beside
# a card goto; every check mod, `requires` and goto `if` names a known flag, item, contact, state path or
# remembered choice; no option carries both a fixed result_text and a check;
# a choice card has at most Events.MAX_OPTIONS options.

# The opening chain (spec "opening-choices"); its content tickets rewrite
# these events and shrink KNOWN_OPENING as they go.
const OPENING_EVENTS := [
	"cold_open", "pub", "buyer", "james_meeting", "gym", "archie_sells_pearls", "archie_cultivation", "prologue_ending",
	"home_raid_intro", "home_raid_debrief_win", "home_raid_debrief_loss",
]

# Exact violations the opening content tickets are expected to clear. Not an
# allowlist: any violation missing from here fails, and so does an entry
# the lint does not find.
const KNOWN_OPENING := [
]

# Violations in non-opening events left for their owner to fix.
const KNOWN_OTHER := [
	# A raid launches from the Raid button in any block.
	"vein_raid: card 0 label 'Night work' says 'night' but the event has no at",
]



func run() -> void:
	run_case("label_tokens_fill_from_calendar_and_current_block", func():
		GameState.reset()
		GameData.EVENTS["test_label_tokens"] = { "id": "test_label_tokens", "cards": [
			{ "type": "text", "label": "{today} — {weekday}, {date} ({block})", "speaker": null, "text": "a" },
			{ "type": "text", "label": "Plain", "speaker": null, "text": "b" },
		] }
		GameState.state["world"]["day"] = 1
		GameState.state["world"]["timeBlock"] = 2
		Events.start_event("test_label_tokens")
		var expected := "Tonight — Tuesday, %s (Evening)" % Calendar.format_day(1)
		assert_eq(Events.current_card()["label"], expected, "current_card resolves tokens")
		assert_eq(Events.revealed_cards()[0]["label"], expected, "revealed_cards resolves tokens")
		assert_eq(GameData.EVENTS["test_label_tokens"]["cards"][0]["label"], "{today} — {weekday}, {date} ({block})", "definition untouched")
		GameState.state["world"]["day"] = 7
		GameState.state["world"]["timeBlock"] = 0
		assert_eq(Events.current_card()["label"], "This morning — Monday, %s (Morning)" % Calendar.format_day(7), "follows the clock")
		Events.advance()
		assert_eq(Events.current_card()["label"], "Plain", "a token-free label is unchanged")
		GameData.EVENTS.erase("test_label_tokens")
		GameState.state["event"] = null
	)

	run_case("lint_flags_each_rule_on_a_synthetic_event", func():
		GameState.reset()
		var def := { "id": "lint_probe", "at": { "block": "morning", "advance": true }, "cards": [
			{ "type": "text", "label": "Tonight — {weekday} {bogus}", "text": "" },
			{ "type": "text", "label": "Two days later", "text": "" },
			{ "type": "choice", "key": "pick", "label": null, "text": "", "choices": [
				{ "label": "a", "result_text": "x", "effects": [], "goto": 0 },
				{ "label": "b", "result_text": "x", "check": { "base": 0.5, "mods": [] }, "success": { "result_text": "s", "effects": [] }, "fail": { "result_text": "f", "effects": [] } },
				{ "label": "c", "requires": { "flag": "noSuchFlag" }, "check": { "base": 0.5, "mods": [
					{ "item": "noSuchItem", "add": 0.1, "label": "" },
					{ "relation": "nobody", "atLeast": 1, "add": 0.1, "label": "" },
					{ "path": "player.nope", "perPoint": 0.1, "label": "" },
					{ "choice": { "event": "lint_probe", "card": "pick", "option": "zzz" }, "add": 0.1, "label": "" },
					{ "choice": { "event": "lint_probe", "card": 2, "option": "zzz" }, "add": 0.1, "label": "" },
				] }, "success": { "result_text": "s", "effects": [], "goto": 9 }, "fail": { "result_text": "f", "effects": [] } },
			] },
			{ "type": "text", "label": null, "text": "", "end": 1, "goto": 4 },
			{ "type": "text", "label": null, "text": "", "goto": [{ "card": 6 }, { "if": { "flag": "noRouteFlag" }, "card": 3 }, "x", { "if": "nope", "card": 6 }] },
			{ "type": "text", "label": null, "text": "", "goto": [{ "if": { "flag": "noRouteFlag" } }] },
			{ "type": "text", "label": null, "text": "" },
			{ "type": "choice", "label": null, "text": "", "choices": [
				{ "label": "1", "result_text": "x", "effects": [] }, { "label": "2", "result_text": "x", "effects": [] },
				{ "label": "3", "result_text": "x", "effects": [] }, { "label": "4", "result_text": "x", "effects": [] },
				{ "label": "5", "result_text": "x", "effects": [] },
			] },
		] }
		GameData.EVENTS["lint_probe"] = def
		var found := EventContentLint.lint_event("lint_probe", def, EventContentLint.known_refs())
		GameData.EVENTS.erase("lint_probe")
		for fragment in ["unknown token {bogus}", "'tonight' contradicts at.block morning", "hard-codes a day", "goto 0", "result_text and a check", "unknown flag noSuchFlag", "unknown item noSuchItem", "unknown contact nobody", "unknown path player.nope", "unknown option zzz", "card must be a card key string", "goto 9", "card 3 end must be true", "card 3 has both end and goto", "entry 0 has no if but is not last", "entry 1 if: unknown flag noRouteFlag", "entry 1 goto 3", "entry 2 is not an object", "entry 3 if is not a condition", "card 5 goto entry 0 goto <null>", "card 7 has 5 options (max 4)"]:
			assert_true(found.any(func(v): return String(v).contains(fragment)), "expected a violation containing '%s' in %s" % [fragment, found])
	)

	run_case("lint_flags_malformed_observations", func():
		GameState.reset()
		var def := { "id": "obs_probe", "observations": {
			"bad": { "blocks": {
				"void": { "tiers": [{ "base": 0.5, "text": "a" }], "miss": "m" },
				"life": { "tiers": [{ "base": 0.6, "text": "a" }, { "base": 0.3, "text": "b" }] },
				"time": { "tiers": [{ "base": 0.3, "text": "a" }], "miss": "m" },
			} },
		}, "cards": [
			{ "type": "text", "label": null, "text": "", "observe": "nope" },
			{ "type": "choice", "label": null, "text": "", "observe": "bad", "choices": [
				{ "label": "x", "result_text": "x", "requires": { "observed": { "id": "bad", "ore": "time", "atLeast": 2 } } },
				{ "label": "y", "result_text": "y", "requires": { "observed": { "id": "ghost", "ore": "time", "atLeast": 1 } } },
				{ "label": "z", "result_text": "z", "requires": { "observed": { "id": "bad", "ore": "time", "atLeast": 1 } } },
			] },
		] }
		var found := EventContentLint.lint_event("obs_probe", def, EventContentLint.known_refs())
		for fragment in ["observation bad void: unknown ore", "bad life: missing miss text", "bad life: tiers not best-first", "card 0 observe 'nope' is not defined", "atLeast 2 outside 1..1", "bad observed ref"]:
			assert_true(found.any(func(v): return String(v).contains(fragment)), "expected a violation containing '%s' in %s" % [fragment, found])
		assert_eq(found.size(), 6, "valid refs add no violations: %s" % [found])
	)

	run_case("lint_refs_file_is_fresh", func():
		GameState.reset()
		var file := FileAccess.open(EventContentLint.REFS_PATH, FileAccess.READ)
		assert_true(file != null, "%s missing; run: godot --headless -s scripts/export_lint_refs.gd" % EventContentLint.REFS_PATH)
		if file == null:
			return
		var on_disk := file.get_as_text().replace("\r\n", "\n")
		assert_true(on_disk == EventContentLint.export_text(), "%s is stale; run: godot --headless -s scripts/export_lint_refs.gd" % EventContentLint.REFS_PATH)
	)

	run_case("lint_situational_entries", func():
		GameState.reset()
		var refs := EventContentLint.known_refs()
		var def := { "cards": [{ "effects": [{ "op": "start_raid_combat", "situational": [
			{ "if": { "flag": "noSuchFlag" }, "sight": 1 },
			{ "if": { "cash": { "atLeast": 1 } }, "bogus": true },
			{ "if": { "cash": { "atLeast": 1 } }, "fleeBoost": 2 },
			{ "if": { "cash": { "atLeast": 1 } } },
			{ "sight": 1 },
			{ "if": { "cash": { "atLeast": 1 } }, "oneAtATime": true, "firstStrike": false, "sight": 3, "fleeBoost": 0.5 },
		] }] }] }
		var out := EventContentLint.lint_event("t", def, refs)
		assert_eq(out.size(), 5, str(out))
	)

	run_case("event_content_lint", func():
		GameState.reset()
		var refs := EventContentLint.known_refs()
		var found: Array = []
		var ids: Array = GameData.EVENTS.keys()
		ids.sort()
		for id in ids:
			found.append_array(EventContentLint.lint_event(id, GameData.EVENTS[id], refs))
		var known: Array = KNOWN_OPENING + KNOWN_OTHER
		for v in found:
			assert_true(known.has(v), "new content lint violation: %s" % v)
		for v in known:
			assert_true(found.has(v), "known violation no longer occurs, delete it from the list: %s" % v)
		for v in KNOWN_OPENING:
			assert_true(OPENING_EVENTS.has(String(v).get_slice(":", 0)), "KNOWN_OPENING holds a non-opening event: %s" % v)
		for v in KNOWN_OTHER:
			assert_true(not OPENING_EVENTS.has(String(v).get_slice(":", 0)), "KNOWN_OTHER holds an opening event: %s" % v)
	)


