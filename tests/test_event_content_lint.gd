extends "res://tests/test_base.gd"

# Card label tokens (R§3.9c) and the event content lint: a data test over
# every event definition. Rules: card-label time words agree with the
# event's `at`; every `goto` targets a later card in the same event; every
# check mod and `requires` names a known flag, item, contact, state path or
# remembered choice; no option carries both a fixed result_text and a check.

# The opening chain (spec "opening-choices"); its content tickets rewrite
# these events and shrink KNOWN_OPENING as they go.
const OPENING_EVENTS := [
	"intro", "buyer", "james_meeting", "archie_craft_chat", "archie_cultivation",
	"home_raid_intro", "home_raid_debrief_win", "home_raid_debrief_loss",
]

# Exact violations the opening content tickets are expected to clear. Not an
# allowlist: any violation missing from here fails, and so does an entry
# the lint does not find.
const KNOWN_OPENING := [
	"buyer: card 0 label 'The next morning' says 'morning' but the event has no at",
	"james_meeting: card 0 label 'Two days later — Bermondsey' hard-codes a day; use {weekday}/{date}",
]

# Violations in non-opening events left for their owner to fix.
const KNOWN_OTHER := [
	# A raid launches from the Raid button in any block.
	"vein_raid: card 0 label 'Night work' says 'night' but the event has no at",
]

const LABEL_TOKENS := ["weekday", "date", "block", "today"]

# Label word -> the `at.block` values it agrees with.
const BLOCK_WORDS := {
	"morning": ["morning"],
	"afternoon": ["afternoon"],
	"evening": ["evening", "night"],
	"tonight": ["evening", "night"],
	"night": ["evening", "night"],
}

# Hard-coded day claims: drift as soon as the calendar moves; use a token.
const DAY_PATTERNS := [
	"\\btomorrow\\b", "\\byesterday\\b", "\\bdays? later\\b", "\\bweeks? later\\b", "\\bnext day\\b",
	"\\b(mon|tues|wednes|thurs|fri|satur|sun)day\\b",
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
			{ "type": "choice", "label": null, "text": "", "choices": [
				{ "label": "a", "result_text": "x", "effects": [], "goto": 0 },
				{ "label": "b", "result_text": "x", "check": { "base": 0.5, "mods": [] }, "success": { "result_text": "s", "effects": [] }, "fail": { "result_text": "f", "effects": [] } },
				{ "label": "c", "requires": { "flag": "noSuchFlag" }, "check": { "base": 0.5, "mods": [
					{ "item": "noSuchItem", "add": 0.1, "label": "" },
					{ "relation": "nobody", "atLeast": 1, "add": 0.1, "label": "" },
					{ "path": "player.nope", "perPoint": 0.1, "label": "" },
					{ "choice": { "event": "lint_probe", "card": 2, "option": "zzz" }, "add": 0.1, "label": "" },
				] }, "success": { "result_text": "s", "effects": [], "goto": 9 }, "fail": { "result_text": "f", "effects": [] } },
			] },
		] }
		GameData.EVENTS["lint_probe"] = def
		var found := _lint_event("lint_probe", def, _known_refs())
		GameData.EVENTS.erase("lint_probe")
		for fragment in ["unknown token {bogus}", "'tonight' contradicts at.block morning", "hard-codes a day", "goto 0", "result_text and a check", "unknown flag noSuchFlag", "unknown item noSuchItem", "unknown contact nobody", "unknown path player.nope", "unknown option zzz", "goto 9"]:
			assert_true(found.any(func(v): return String(v).contains(fragment)), "expected a violation containing '%s' in %s" % [fragment, found])
	)

	run_case("event_content_lint", func():
		GameState.reset()
		var refs := _known_refs()
		var found: Array = []
		var ids: Array = GameData.EVENTS.keys()
		ids.sort()
		for id in ids:
			found.append_array(_lint_event(id, GameData.EVENTS[id], refs))
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


# Every flag, item, contact and state path a mod or `requires` may name.
func _known_refs() -> Dictionary:
	var flags: Dictionary = {}
	for flag in GameState.state["flags"]:
		flags[flag] = true
	for id in GameData.EVENTS:
		_collect_set_flags(GameData.EVENTS[id], flags)
	return {
		"flags": flags,
		"items": GameData.RECIPES,
		"contacts": GameState.state["contacts"],
	}


func _collect_set_flags(value: Variant, into: Dictionary) -> void:
	if value is Dictionary:
		if value.get("op") == "set_flag":
			into[value["flag"]] = true
		for v in value.values():
			_collect_set_flags(v, into)
	elif value is Array:
		for v in value:
			_collect_set_flags(v, into)


func _lint_event(id: String, def: Dictionary, refs: Dictionary) -> Array:
	var out: Array = []
	var cards: Array = def.get("cards", [])
	var at_block: Variant = (def["at"] as Dictionary).get("block") if def.get("at") is Dictionary else null
	for i in cards.size():
		var card: Dictionary = cards[i]
		if card.get("label") is String:
			out.append_array(_lint_label(id, i, card["label"], at_block))
		for j in (card.get("choices", []) as Array).size():
			out.append_array(_lint_option(id, i, j, card["choices"][j], cards, refs))
	return out


func _lint_label(id: String, i: int, label: String, at_block: Variant) -> Array:
	var out: Array = []
	var where := "%s: card %d label '%s'" % [id, i, label]
	var token_re := RegEx.create_from_string("\\{([^}]*)\\}")
	for m in token_re.search_all(label):
		if not LABEL_TOKENS.has(m.get_string(1)):
			out.append("%s has unknown token {%s}" % [where, m.get_string(1)])
	var words := token_re.sub(label, "", true).to_lower()
	for pattern in DAY_PATTERNS:
		if RegEx.create_from_string(pattern).search(words) != null:
			out.append("%s hard-codes a day; use {weekday}/{date}" % where)
			break
	for word in BLOCK_WORDS:
		if RegEx.create_from_string("\\b%s\\b" % word).search(words) == null:
			continue
		if at_block == null:
			out.append("%s says '%s' but the event has no at" % [where, word])
		elif not (BLOCK_WORDS[word] as Array).has(at_block):
			out.append("%s: '%s' contradicts at.block %s" % [where, word, at_block])
	return out


func _lint_option(id: String, i: int, j: int, option: Dictionary, cards: Array, refs: Dictionary) -> Array:
	var out: Array = []
	var where := "%s: card %d option %d" % [id, i, j]
	if option.has("check") and option.has("result_text"):
		out.append("%s has both result_text and a check" % where)
	var gotos: Array = [option.get("goto")]
	for key in ["success", "fail"]:
		if option.get(key) is Dictionary:
			gotos.append(option[key].get("goto"))
	if option.get("bySuccesses") is Dictionary:
		for outcome in option["bySuccesses"].values():
			gotos.append(outcome.get("goto"))
	for goto in gotos:
		if goto == null:
			continue
		var is_num: bool = typeof(goto) == TYPE_INT or typeof(goto) == TYPE_FLOAT
		if not is_num or int(goto) <= i or int(goto) >= cards.size():
			out.append("%s goto %s is not a later card" % [where, str(goto)])
	if option.get("requires") is Dictionary:
		out.append_array(_lint_condition(where + " requires", option["requires"], refs))
	if option.get("check") is Dictionary:
		for mod in option["check"].get("mods", []):
			out.append_array(_lint_condition(where + " mod", mod, refs))
	return out


# Mirrors Events.condition_met()'s vocabulary (R§3.9a "Mods"/"Requires").
func _lint_condition(where: String, c: Dictionary, refs: Dictionary) -> Array:
	if c.has("item"):
		return [] if refs["items"].has(c["item"]) else ["%s: unknown item %s" % [where, c["item"]]]
	if c.has("flag"):
		return [] if refs["flags"].has(c["flag"]) else ["%s: unknown flag %s" % [where, c["flag"]]]
	if c.has("relation"):
		return [] if refs["contacts"].has(c["relation"]) else ["%s: unknown contact %s" % [where, c["relation"]]]
	if c.has("path"):
		return [] if GameState.read_path(c["path"]) != null else ["%s: unknown path %s" % [where, c["path"]]]
	if c.has("cash"):
		return []
	if c.has("choice"):
		return _lint_choice_ref(where, c["choice"])
	return ["%s: unknown condition %s" % [where, JSON.stringify(c)]]


func _lint_choice_ref(where: String, ref: Dictionary) -> Array:
	var event: Dictionary = GameData.EVENTS.get(ref.get("event", ""), {})
	if event.is_empty():
		return ["%s: unknown event %s" % [where, ref.get("event")]]
	var cards: Array = event["cards"]
	var card_index := int(ref.get("card", -1))
	if card_index < 0 or card_index >= cards.size() or not cards[card_index].has("choices"):
		return ["%s: %s card %s is not a choice card" % [where, ref["event"], str(ref.get("card"))]]
	var options: Array = cards[card_index]["choices"]
	var option: Variant = ref.get("option")
	if option is String:
		for o in options:
			if o.get("id") == option:
				return []
	elif int(option) >= 0 and int(option) < options.size():
		return []
	return ["%s: unknown option %s at %s card %d" % [where, str(option), ref["event"], card_index]]
