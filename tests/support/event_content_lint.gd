extends RefCounted
# The event content lint (R§3.9c): card-label time words agree with the
# event's `at`; every `goto` targets a later card in the same event; a card's
# conditional goto list is well formed; `end` is `true` and never sits beside
# a card goto; every check mod, `requires` and goto `if` names a known flag,
# item, contact, state path or remembered choice; no option carries both a
# fixed result_text and a check; a choice card has at most Events.MAX_OPTIONS
# options. tools/storyboard.html mirrors it; scripts/export_lint_refs.gd writes
# the reference lists and per-event violations the tool's lint is checked against.

const MAX_OPTIONS := Events.MAX_OPTIONS

const LABEL_TOKENS :=["weekday", "date", "block", "today"]

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

# Where the tool's reference lists live; regenerate with
# `godot --headless -s scripts/export_lint_refs.gd`.
const REFS_PATH := "res://tools/lint_refs.json"


# Everything tools/storyboard.html's lint needs: the reference lists, each
# event's choice-card option ids and observation tier counts, and this lint's
# violations per event (so the tool's lint can be held to the same answers).
static func export_refs() -> Dictionary:
	var refs := known_refs()
	var paths: Array = []
	_collect_paths(GameState.state, "", paths)
	paths.sort()
	var events: Dictionary = {}
	var violations: Dictionary = {}
	var ids: Array = GameData.EVENTS.keys()
	ids.sort()
	for id in ids:
		var def: Dictionary = GameData.EVENTS[id]
		var choice_cards: Dictionary = {}
		for card in def.get("cards", []):
			if card.has("choices") and card.get("key") is String:
				choice_cards[card["key"]] = (card["choices"] as Array).map(func(o): return str(o.get("id", "")))
		var observations: Dictionary = {}
		for obs_id in def.get("observations", {}):
			var blocks: Dictionary = {}
			for ore in def["observations"][obs_id].get("blocks", {}):
				blocks[ore] = (def["observations"][obs_id]["blocks"][ore].get("tiers", []) as Array).size()
			observations[obs_id] = blocks
		events[id] = { "choiceCards": choice_cards, "observations": observations }
		var found := lint_event(id, def, known_refs())
		if not found.is_empty():
			violations[id] = found
	var flags: Array = refs["flags"].keys()
	flags.sort()
	var items: Array = refs["items"].keys()
	items.sort()
	var contacts: Array = refs["contacts"].keys()
	contacts.sort()
	var procedures: Array = (GameData.LAB.get("procedures", {}) as Dictionary).keys()
	procedures.sort()
	return {
		"flags": flags, "items": items, "contacts": contacts, "paths": paths,
		"rungs": RecipeKnowledge.rungs(), "procedures": procedures,
		"ores": GameData.OBSERVATION["oreOrder"], "maxOptions": MAX_OPTIONS,
		"events": events, "violations": violations,
	}


static func export_text() -> String:
	return JSON.stringify(export_refs(), "\t", true) + "\n"


static func _collect_paths(value: Variant, prefix: String, into: Array) -> void:
	if not value is Dictionary:
		return
	for key in value:
		if value[key] == null:
			continue
		var path: String = ("%s.%s" % [prefix, key]) if prefix != "" else str(key)
		into.append(path)
		_collect_paths(value[key], path, into)


# Every flag, item, contact and state path a mod or `requires` may name.
static func known_refs() -> Dictionary:
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


static func _collect_set_flags(value: Variant, into: Dictionary) -> void:
	if value is Dictionary:
		if value.get("op") == "set_flag":
			into[value["flag"]] = true
		for v in value.values():
			_collect_set_flags(v, into)
	elif value is Array:
		for v in value:
			_collect_set_flags(v, into)


static func lint_event(id: String, def: Dictionary, refs: Dictionary) -> Array:
	var out: Array = []
	var cards: Array = def.get("cards", [])
	var at_block: Variant = (def["at"] as Dictionary).get("block") if def.get("at") is Dictionary else null
	refs["event"] = def
	out.append_array(_lint_observations(id, def, refs))
	out.append_array(_lint_situational(id, def, refs))
	for i in cards.size():
		var card: Dictionary = cards[i]
		if card.has("observe") and card["observe"] != null and not def.get("observations", {}).has(card["observe"]):
			out.append("%s: card %d observe '%s' is not defined" % [id, i, str(card["observe"])])
		if card.get("label") is String:
			out.append_array(_lint_label(id, i, card["label"], at_block))
		out.append_array(_lint_card_route(id, i, card, cards, refs))
		var option_count: int = (card.get("choices", []) as Array).size()
		if option_count > MAX_OPTIONS:
			out.append("%s: card %d has %d options (max %d)" % [id, i, option_count, MAX_OPTIONS])
		for j in option_count:
			out.append_array(_lint_option(id, i, j, card["choices"][j], cards, refs))
	return out


static func _lint_label(id: String, i: int, label: String, at_block: Variant) -> Array:
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


static func _lint_option(id: String, i: int, j: int, option: Dictionary, cards: Array, refs: Dictionary) -> Array:
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
		out.append_array(_lint_goto(where, goto, i, cards))
	if option.get("requires") is Dictionary:
		out.append_array(_lint_condition(where + " requires", option["requires"], refs))
	if option.get("pick") is Dictionary:
		out.append_array(_lint_pick(where, option, cards, i, refs))
	if option.get("check") is Dictionary:
		for mod in option["check"].get("mods", []):
			out.append_array(_lint_condition(where + " mod", mod, refs))
	return out


# An observation pick (R§3.9d): a defined observation, each ore a block of it,
# outcomes with atLeast in 1..tiers and a result_text, goto valid.
static func _lint_pick(where: String, option: Dictionary, cards: Array, i: int, refs: Dictionary) -> Array:
	var out: Array = []
	var pick: Dictionary = option["pick"]
	var obs: Dictionary = (refs.get("event", {}) as Dictionary).get("observations", {}).get(pick.get("observation", ""), {})
	if obs.is_empty():
		return ["%s pick observation '%s' is not defined" % [where, str(pick.get("observation"))]]
	if option.has("check"):
		out.append("%s has both pick and check" % where)
	if not pick.get("ores") is Dictionary or (pick["ores"] as Dictionary).is_empty():
		return out + ["%s pick has no ores" % where]
	for ore in pick["ores"]:
		var block: Dictionary = obs["blocks"].get(ore, {})
		if block.is_empty():
			out.append("%s pick ore '%s' is not in the observation" % [where, ore])
			continue
		var entries: Variant = pick["ores"][ore]
		if entries is Dictionary:
			entries = [entries]
		var tiers: int = (block["tiers"] as Array).size()
		var last := 99
		for entry: Dictionary in entries:
			var at_least := int(entry.get("atLeast", 0))
			if at_least < 1 or at_least > tiers:
				out.append("%s pick %s atLeast %s outside 1..%d" % [where, ore, str(entry.get("atLeast")), tiers])
			if at_least >= last:
				out.append("%s pick %s outcomes not best-first (atLeast must descend)" % [where, ore])
			last = at_least
			if not entry.has("result_text"):
				out.append("%s pick %s outcome has no result_text" % [where, ore])
			out.append_array(_lint_goto("%s pick %s" % [where, ore], entry.get("goto"), i, cards))
	return out


# A card's own `goto` (an index or a conditional [{if, card}, ..., {card}]
# list) and `end` (R§3.9a "Goto").
static func _lint_card_route(id: String, i: int, card: Dictionary, cards: Array, refs: Dictionary) -> Array:
	var out: Array = []
	var where := "%s: card %d" % [id, i]
	if card.has("end") and not (card["end"] is bool and card["end"]):
		out.append("%s end must be true, not %s" % [where, str(card["end"])])
	if card.has("end") and card.has("goto"):
		out.append("%s has both end and goto" % where)
	var goto: Variant = card.get("goto")
	if not goto is Array:
		out.append_array(_lint_goto(where, goto, i, cards))
		return out
	for k in (goto as Array).size():
		var entry: Variant = goto[k]
		if not entry is Dictionary:
			out.append("%s goto entry %d is not an object" % [where, k])
			continue
		out.append_array(_lint_goto("%s goto entry %d" % [where, k], entry.get("card"), i, cards, true))
		if entry.has("if"):
			if entry["if"] is Dictionary:
				out.append_array(_lint_condition("%s goto entry %d if" % [where, k], entry["if"], refs))
			else:
				out.append("%s goto entry %d if is not a condition" % [where, k])
		elif k < goto.size() - 1:
			out.append("%s goto entry %d has no if but is not last" % [where, k])
	return out


# A goto value must be null (none), a later card index in the same event, or an earlier-or-same "choice" card (a hub).
static func _lint_goto(where: String, goto: Variant, i: int, cards: Array, required: bool = false) -> Array:
	if goto == null and not required:
		return []
	var is_num: bool = typeof(goto) == TYPE_INT or typeof(goto) == TYPE_FLOAT
	if not is_num or int(goto) < 0 or int(goto) >= cards.size():
		return ["%s goto %s is not a later card" % [where, str(goto)]]
	if int(goto) <= i and cards[int(goto)].get("type") != "choice":
		return ["%s goto %s is not a later card" % [where, str(goto)]]
	return []


# Mirrors Events.condition_met()'s vocabulary (R§3.9a "Mods"/"Requires").
static func _lint_condition(where: String, c: Dictionary, refs: Dictionary) -> Array:
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
	if c.has("recipeRung"):
		var r: Dictionary = c["recipeRung"]
		return [] if RecipeKnowledge.rungs().has(r.get("rung")) and not Lab.procedure_def(str(r.get("recipe"))).is_empty() else ["%s: unknown recipe rung %s" % [where, JSON.stringify(r)]]
	if c.has("choice"):
		return _lint_choice_ref(where, c["choice"])
	if c.has("observed"):
		return _lint_observed_ref(where, c["observed"], refs.get("event", {}))
	return ["%s: unknown condition %s" % [where, JSON.stringify(c)]]


# Every `situational` list on a start_scripted_fight / start_raid_combat op
# (op-level, or inside a scripted fight's script): entries are {if: known
# condition, plus at least one known mod}, mod values well typed (R§3.7b).
static func _lint_situational(id: String, value: Variant, refs: Dictionary) -> Array:
	var out: Array = []
	if value is Array:
		for v in value:
			out.append_array(_lint_situational(id, v, refs))
	elif value is Dictionary:
		for key in value:
			if key == "situational":
				out.append_array(_lint_situational_list(id, value[key], refs))
			else:
				out.append_array(_lint_situational(id, value[key], refs))
	return out


static func _lint_situational_list(id: String, list: Variant, refs: Dictionary) -> Array:
	var out: Array = []
	var where := "%s: situational" % id
	if not list is Array:
		return ["%s is not a list" % where]
	for k in (list as Array).size():
		var entry: Variant = list[k]
		var at := "%s entry %d" % [where, k]
		if not entry is Dictionary or not entry.get("if") is Dictionary:
			out.append("%s needs an if condition" % at)
			continue
		out.append_array(_lint_condition(at + " if", entry["if"], refs))
		var mod_count := 0
		for key in entry:
			if key == "if":
				continue
			mod_count += 1
			if not Combat.SITUATIONAL_MODS.has(key):
				out.append("%s: unknown mod %s" % [at, key])
			elif key == "fleeBoost" and not (typeof(entry[key]) in [TYPE_INT, TYPE_FLOAT] and float(entry[key]) > 0.0 and float(entry[key]) <= 1.0):
				out.append("%s: fleeBoost must be a chance in (0, 1]" % at)
			elif key == "sight" and not (typeof(entry[key]) in [TYPE_INT, TYPE_FLOAT] and int(entry[key]) >= 1):
				out.append("%s: sight must be rounds >= 1" % at)
			elif key in ["oneAtATime", "firstStrike"] and not entry[key] is bool:
				out.append("%s: %s must be a bool" % [at, key])
		if mod_count == 0:
			out.append("%s has no mod" % at)
	return out


# An event's `observations` (R§3.9d): known ores, tiers best-first (base
# ascending), a miss text, mods that are known conditions.
static func _lint_observations(id: String, def: Dictionary, refs: Dictionary) -> Array:
	var out: Array = []
	var ores: Array = GameData.OBSERVATION["oreOrder"]
	for obs_id in def.get("observations", {}):
		var obs: Dictionary = def["observations"][obs_id]
		var where := "%s: observation %s" % [id, obs_id]
		for mod in obs.get("mods", []):
			if not (mod.has("path") and mod.has("perPoint")):
				out.append_array(_lint_condition(where + " mod", mod, refs))
		var blocks: Dictionary = obs.get("blocks", {})
		if blocks.is_empty():
			out.append("%s has no blocks" % where)
		for ore in blocks:
			var block_where := "%s %s" % [where, ore]
			var block: Dictionary = blocks[ore]
			if not ores.has(ore):
				out.append("%s: unknown ore" % block_where)
			if not block.get("miss") is String or String(block["miss"]) == "":
				out.append("%s: missing miss text" % block_where)
			var tiers: Array = block.get("tiers", [])
			if tiers.is_empty():
				out.append("%s: no tiers" % block_where)
			for k in tiers.size():
				if not tiers[k].has("base") or not tiers[k].has("text"):
					out.append("%s: tier %d needs base and text" % [block_where, k])
				elif k > 0 and tiers[k - 1].has("base") and float(tiers[k]["base"]) <= float(tiers[k - 1]["base"]):
					out.append("%s: tiers not best-first (base must ascend)" % block_where)
	return out


# {observed: {event?, id, ore, atLeast}}: a known ore, an observation defined in
# the named (or current) event, atLeast within that block's tier count.
static func _lint_observed_ref(where: String, ref: Dictionary, current: Dictionary) -> Array:
	var def: Dictionary = current
	if ref.has("event"):
		def = GameData.EVENTS.get(ref["event"], {})
	var block: Dictionary = def.get("observations", {}).get(ref.get("id", ""), {}).get("blocks", {}).get(ref.get("ore", ""), {})
	if block.is_empty():
		return ["%s: bad observed ref %s" % [where, JSON.stringify(ref)]]
	var at_least := int(ref.get("atLeast", 0))
	if at_least < 1 or at_least > (block.get("tiers", []) as Array).size():
		return ["%s: observed atLeast %s outside 1..%d" % [where, str(ref.get("atLeast")), (block.get("tiers", []) as Array).size()]]
	return []


static func _lint_choice_ref(where: String, ref: Dictionary) -> Array:
	var event: Dictionary = GameData.EVENTS.get(ref.get("event", ""), {})
	if event.is_empty():
		return ["%s: unknown event %s" % [where, ref.get("event")]]
	if typeof(ref.get("card")) != TYPE_STRING:
		return ["%s: card must be a card key string, got %s" % [where, str(ref.get("card"))]]
	var target: Dictionary = {}
	for card in event["cards"]:
		if card.get("key") == ref["card"] and card.has("choices"):
			target = card
	if target.is_empty():
		return ["%s: %s card %s is not a choice card" % [where, ref["event"], str(ref["card"])]]
	var options: Array = target["choices"]
	var option: Variant = ref.get("option")
	if option is String:
		for o in options:
			if o.get("id") == option:
				return []
	elif int(option) >= 0 and int(option) < options.size():
		return []
	return ["%s: unknown option %s at %s card %s" % [where, str(option), ref["event"], str(ref["card"])]]
