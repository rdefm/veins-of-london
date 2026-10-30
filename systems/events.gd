class_name Events
extends RefCounted

# Event runner (R§3.9, ui-vision.md §11). Cards: {type, label, speaker,
# text}; a "choice" card adds {choices:[{id?, label, effects, result_text}]};
# a check option swaps result_text for {check, success, fail} (R§3.9a).
# An option may carry `requires` (option_gate()); it or its outcome may carry
# `goto`, a later card (or earlier choice card) Continue jumps to, by index or card `key`. Any card may carry `goto` (an
# index or key, or a conditional list [{if, card}, ..., {card}]) or `end: true`
# (R§3.9a "Goto"); an option/outcome goto takes precedence over both.
# Events: {id, cards, on_complete:[effect]}. state.event holds runtime
# progress: {eventId, cardIndex, snapshots, choiceResults, jumps, rolled, toggles,
# choosing?}. `choosing` is true once Continue was tapped on an unresolved choice
# card's prompt, so the screen shows its option buttons instead of its text.
#
# Any card (including a choice's own "choices" entries) may carry an optional
# "image" key -- an asset path, or explicit null to clear the event screen's
# persistent image slot. Omitting the key falls back to a convention-named
# asset at that card index; a picked choice's own "image" rides along in
# choiceResults[cardIndex] the same way.

const Preferences := preload("res://systems/preferences.gd")

# start_raid_combat's "guards" value meaning "one per guard on the raided vein".
const RAID_GUARDS_FROM_VEIN := "vein"
# Fight-setup keys a raid fight op's own value replaces its preset's with
# (fight_setup(); situational appends instead).
const FIGHT_OVERRIDE_KEYS: Array[String] = ["guards", "template", "waves"]

# The fixed text box fits this many option buttons; the content lint enforces it.
const MAX_OPTIONS := 4


# context: a raid's target site_id is only known at Raid-button-press time, so
# it's carried here and read back by _event_site_id() below; every other caller omits it.
static func start_event(event_id: String, context: Dictionary = {}) -> void:
	# An id with no definition would open an event screen with no cards to show.
	if not GameData.EVENTS.has(event_id):
		push_error("Events.start_event: unknown event id '%s'" % event_id)
		return
	_apply_timing(GameData.EVENTS[event_id].get("at", {}))
	TimingLog.begin(TimingLog.KIND_EVENT, event_id)
	GameState.state["event"] = { "eventId": event_id, "cardIndex": 0, "snapshots": [], "choiceResults": {}, "jumps": {}, "rolled": {}, "toggles": {}, "context": context, "alert": _clamp_alert(int(context.get("startAlert", 0))) }
	Observation.restore_site_memory()
	Nav.go_to("event")


# R§3.9b "Event timing": `at.advance` moves the clock forward to `at.block`
# before the first card; a passed block or "night" leaves it where it is.
static func _apply_timing(at: Dictionary) -> void:
	if at.get("advance", false):
		TimeSystem.advance_to_block(String(at.get("block", "")))


# False when state.event names an id with no definition (e.g. one carried in
# from an older save) -- the event screen then offers only abandon().
static func has_live_definition() -> bool:
	var event_state = GameState.state["event"]
	return event_state != null and GameData.EVENTS.has(event_state["eventId"])


# The unresolvable event screen's exit: drops state.event without running any
# effects and returns to the phone.
static func abandon() -> void:
	TimingLog.end(TimingLog.KIND_EVENT)
	GameState.state["event"] = null
	Nav.go_to("phone")


# start_event(), unless a modal flow is open (e.g. a sale confirmation) --
# then the event waits behind it and starts when that flow closes.
static func start_or_defer(event_id: String, context: Dictionary = {}) -> void:
	if GameState.state["modal"] == null:
		start_event(event_id, context)
		return
	Modal.defer_event(event_id, context)


static func _event_def() -> Dictionary:
	var event_state: Dictionary = GameState.state["event"]
	return GameData.EVENTS[event_state["eventId"]]


# The card at the runner's current position -- awaiting a Continue tap, or (for a "choice" card) a pick.
static func current_card() -> Dictionary:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	return _with_label_tokens(cards[event_state["cardIndex"]])


# True once the current card is an unresolved "choice" card -- the runner must not advance() past it via Continue.
static func is_awaiting_choice() -> bool:
	var event_state: Dictionary = GameState.state["event"]
	var card: Dictionary = current_card()
	if card["type"] != "choice":
		return false
	return not event_state["choiceResults"].has(str(event_state["cardIndex"]))


# True on an unresolved choice card once its prompt has been continued past:
# the screen shows the option buttons only.
static func is_choosing() -> bool:
	return is_awaiting_choice() and GameState.state["event"].get("choosing", false)


# All cards revealed so far (_visited_indices()). A resolved "choice"
# card's result_text is spliced in right after it as a synthetic resolution
# card, without consuming its own cardIndex slot.
static func revealed_cards() -> Array:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	var choice_results: Dictionary = event_state["choiceResults"]

	# fillFromContext: card text's {key} placeholders read the event's context.
	var fill: bool = _event_def().get("fillFromContext", false)
	var result: Array = []
	for i in _visited_indices():
		var card: Dictionary = _with_label_tokens(cards[i])
		if fill:
			card = card.duplicate()
			card["text"] = String(card["text"]).format(event_state.get("context", {}))
		result.append(card)
		if choice_results.has(str(i)):
			var resolution: Dictionary = choice_results[str(i)]
			if is_silent_text(resolution["text"]):
				continue
			var resolution_card: Dictionary = { "type": "resolution", "label": null, "speaker": null, "text": resolution["text"] }
			if resolution.has("image"):
				resolution_card["image"] = resolution["image"]
			for key in ["outcome", "successes", "attempts", "roll", "needed"]:
				if resolution.has(key):
					resolution_card[key] = resolution[key]
			result.append(resolution_card)
	return result


# R§3.9c "Label tokens": the card, with its label's {weekday}/{date}/
# {block}/{today} filled from the calendar and current block; a card without
# a token comes back as-is.
static func _with_label_tokens(card: Dictionary) -> Dictionary:
	var label: Variant = card.get("label")
	if not label is String or not String(label).contains("{"):
		return card
	var world: Dictionary = GameState.state["world"]
	var day: int = int(world["day"])
	var block: int = int(world["timeBlock"])
	var labels: Dictionary = GameData.EVENT_LABELS
	var tokens := {
		"weekday": labels["weekdayNames"][Calendar.weekday_index(day)],
		"date": Calendar.format_day(day),
		"block": GameData.TIME_BLOCKS[block],
		"today": labels["todayPhrases"][block],
	}
	var resolved: Dictionary = card.duplicate()
	resolved["label"] = String(label).format(tokens)
	return resolved


# Derived state for the event screen's persistent image slot (ui-vision.md §11):
# scans cards up to the current position, sticky until the next image, explicit
# null clears it. Not stored on state.event, so Rewind restores it for free.
static func current_image_path() -> Variant:
	var result: Variant = null
	var event_state: Dictionary = GameState.state["event"]
	var event_id: String = event_state["eventId"]
	var cards: Array = _event_def()["cards"]
	var choice_results: Dictionary = event_state["choiceResults"]
	for i in _visited_indices():
		var card: Dictionary = cards[i]
		if card.has("image"):
			result = card["image"]
		else:
			var discovered_path: Variant = _convention_image_path(event_id, i + 1)
			if discovered_path != null:
				result = discovered_path
		if choice_results.has(str(i)):
			var resolution: Dictionary = choice_results[str(i)]
			if resolution.has("image"):
				result = resolution["image"]
	return result


# Convention-based event art: one-based card numbers map directly to
# assets/events/<event_id>/<event_id>_card<n>.<extension>. Explicit card image
# keys remain authoritative, including null (clear).
static func _convention_image_path(event_id: String, card_number: int) -> Variant:
	var stem := "res://assets/events/%s/%s_card%d" % [event_id, event_id, card_number]
	for extension in ["png", "jpg", "jpeg", "webp"]:
		var path := "%s.%s" % [stem, extension]
		if ResourceLoader.exists(path):
			return path
	return null


# True when Continue on the current card finishes the event: the final card,
# or one marked `end: true` whose resolution (if any) has no goto of its own.
static func is_last_card() -> bool:
	var event_state: Dictionary = GameState.state["event"]
	var index: int = int(event_state["cardIndex"])
	var cards: Array = _event_def()["cards"]
	if index >= cards.size() - 1:
		return true
	var resolution: Dictionary = event_state["choiceResults"].get(str(index), {})
	var end: Variant = cards[index].get("end", false)
	return end is bool and end and not resolution.has("goto")


static func can_rewind() -> bool:
	if not has_rewind_point():
		return false
	return Crafting.inventory_qty("rewind") > 0 or Dial.find_loaded_rewind_complication_index() >= 0


# True once the live event has a snapshot to rewind to, regardless of stock/charge.
static func has_rewind_point() -> bool:
	var event_state = GameState.state["event"]
	return event_state != null and not event_state["snapshots"].is_empty()


# Continue: snapshots full state, then either reveals the next card or (on the last card) runs on_complete and clears state.event.
static func advance() -> void:
	if is_awaiting_choice():
		# Continue on the prompt step swaps to the option buttons; the pick itself
		# goes through choose(). No snapshot: nothing but the step changes.
		if not is_choosing():
			GameState.state["event"]["choosing"] = true
			EventBus.state_changed.emit()
		return

	_snapshot_before_mutation()
	_continue()


# Continue's state change without its snapshot: shared by advance() and a
# silent choose(), which already snapshotted before the pick.
static func _continue() -> void:
	var event_state: Dictionary = GameState.state["event"]
	if is_last_card():
		var on_complete: Array = _event_def().get("on_complete", [])
		# state.event is nulled BEFORE on_complete runs, so a mid-on_complete emit never
		# finds a live EventScreen still rendering a tappable Continue. An on_complete op
		# needing the event's context (e.g. reveal_site) is handed it explicitly instead.
		var context: Dictionary = event_state.get("context", {})
		TimingLog.end(TimingLog.KIND_EVENT, str(event_state["eventId"]))
		Observation.record_memory()
		GameState.state["event"] = null
		apply_effects(on_complete, context)
		# The one path all three Act-1 closer prerequisite flags flow through; a
		# harmless no-op for every other event's completion.
		Collective.maybe_trigger_closer()
		# Act 2's own opener -- same "check after any on_complete" idiom, since
		# colA1Complete only ever flips inside an event's on_complete too.
		Collective.maybe_trigger_act2_intro()
		# T5's scripted vein loss -- same idiom, gated on colA2Stage which T3's
		# on_complete sets.
		Collective.maybe_trigger_a2_contested_vein_setup()
		# T9's checkpoint -- stamps ledgerStartedDay straight after T8's on_complete.
		Collective.maybe_trigger_a2_checkpoint()
		# T14's gate usually crosses on T13's own +15 relation award.
		Collective.maybe_trigger_a2_spine_reward()
		# Beat 1: an event can grant a vein or recruit Archie; the Beat 1
		# scene itself starts Archie's starter chain.
		BusinessQuest.maybe_trigger_proposition()
		BusinessQuest.maybe_issue_starter()
		# Beat 3: prior completions can meet Beat 2 inside the Beat 1 scene.
		BusinessQuest.maybe_trigger_owen_intro()
		BusinessQuest.maybe_trigger_partnership()
		BusinessQuest.maybe_trigger_production()
		BusinessQuest.maybe_trigger_put_to_work()
		BusinessQuest.maybe_trigger_owen_craft()
		SaveManager.autosave()  # R§6: autosave on event completion
	else:
		var here: int = int(event_state["cardIndex"])
		var resolution: Dictionary = event_state["choiceResults"].get(str(here), {})
		var dest := -1
		if resolution.has("goto"):
			dest = int(resolution["goto"])
		else:
			dest = _goto_target(_card_goto(_event_def()["cards"][here]))
			if dest > here:
				if not event_state.has("jumps"):
					event_state["jumps"] = {}
				event_state["jumps"][str(here)] = dest
		_tick_reinforcement()
		if dest >= 0 and dest <= here:
			_reenter_hub(event_state, dest)
		else:
			event_state["cardIndex"] = _next_index(here)
		EventBus.state_changed.emit()


# Backward goto to choice card `hub`: drops the resolutions, jumps and toggles
# of every card from the hub on, so the hub is unresolved and the revealed
# list shows it once, as on first arrival.
static func _reenter_hub(event_state: Dictionary, hub: int) -> void:
	for key in ["choiceResults", "jumps", "toggles"]:
		var table: Dictionary = event_state.get(key, {})
		for entry in table.keys():
			if int(String(entry).split("|")[0]) >= hub:
				table.erase(entry)
	event_state["cardIndex"] = hub
	event_state["choosing"] = true  # the prompt was already read; land on the options


# A card's own `goto` as a plain target: an index as-is, or a conditional
# list's first entry whose `if` holds (condition_met), an entry without `if`
# always matching. null when the card has none or no entry matches.
static func _card_goto(card: Dictionary) -> Variant:
	var goto: Variant = card.get("goto")
	if not goto is Array:
		return goto
	for entry in goto:
		if entry is Dictionary and (not entry.has("if") or (entry["if"] is Dictionary and condition_met(entry["if"]))):
			return entry.get("card")
	return null


# A resolved option's or card's `goto` as a card index, or -1 for none. Within
# this event: a later card, or a "choice" card at or before this one (a hub;
# the choice card itself loops its options back to it). An
# out-of-range or non-choice backward target is rejected (push_error) and play
# falls through to the next card.
static func _goto_target(goto: Variant) -> int:
	if goto == null:
		return -1
	var here: int = int(GameState.state["event"]["cardIndex"])
	var cards: Array = _event_def()["cards"]
	var target := _goto_index(goto, cards)
	if goto is String and target < 0:
		push_error("Events: goto '%s' from card %d of '%s' names no card key" % [goto, here, GameState.state["event"]["eventId"]])
		return -1
	if target > here and target < cards.size():
		return target
	if target >= 0 and target <= here and cards[target]["type"] == "choice":
		return target
	push_error("Events: goto %s from card %d of '%s' is not a later card or an earlier choice card" % [str(goto), here, GameState.state["event"]["eventId"]])
	return -1


# A goto value as a card index: a number as-is, or a card `key` string looked
# up in `cards` (R§3.9a "Goto"). -1 for an unknown key or any other value.
static func _goto_index(goto: Variant, cards: Array) -> int:
	if typeof(goto) == TYPE_INT or typeof(goto) == TYPE_FLOAT:
		return int(goto)
	if goto is String:
		for i in cards.size():
			if cards[i].get("key") == goto:
				return i
	return -1


# The card Continue moved to from card `index`: its resolution's goto, else
# the card goto resolved when it was continued past (state.event.jumps), else
# the next one.
static func _next_index(index: int) -> int:
	var event_state: Dictionary = GameState.state["event"]
	var resolution: Dictionary = event_state["choiceResults"].get(str(index), {})
	var jump: Variant = event_state.get("jumps", {}).get(str(index), index + 1)
	return maxi(int(resolution.get("goto", jump)), index + 1)


# The card indexes played so far, 0..cardIndex, skipping any a goto jumped past.
static func _visited_indices() -> Array:
	var visited: Array = []
	var last: int = int(GameState.state["event"]["cardIndex"])
	var i := 0
	while i <= last:
		visited.append(i)
		i = _next_index(i)
	return visited


# Resolves the current "choice" card: applies the picked choice's effects, then
# records its result_text so revealed_cards() shows it as a resolution card.
# Doesn't advance cardIndex -- Continue still moves past the resolution -- unless
# the result_text is blank, when it continues at once.
static func choose(choice_index: int, pick_ore: String = "") -> void:
	if not is_awaiting_choice():
		return
	if option_gate(choice_index)["display"] != "show":
		return  # a hidden or disabled option can't be committed
	var picking: Dictionary = current_card()["choices"][choice_index]
	if picking.has("pick") and Observation.pick_outcome(picking, pick_ore).is_empty():
		return  # a pick option needs a qualifying ore
	if choice_index == hub_exit_index() and not hub_exit_available():
		return  # the hub's advance rule isn't met yet

	_snapshot_before_mutation()

	var event_state: Dictionary = GameState.state["event"]
	# Re-asking a reselectable hub question replays its answer without re-firing its effects.
	var re_asked: bool = hub_exit_index() >= 0 and choice_index != hub_exit_index() and _picked_here().has(choice_index)
	event_state.erase("choosing")
	var card: Dictionary = current_card()
	var choice: Dictionary = card["choices"][choice_index]

	# A check option resolves through its rolled outcome object instead of
	# its own result_text; the option's own effects (if any) still apply first.
	var outcome := ""
	var source: Dictionary = Observation.pick_outcome(choice, pick_ore) if choice.has("pick") else choice
	var attempts := 1
	var successes := 0
	var shown_roll := 0
	var shown_needed := 0
	var toggled := active_toggles(choice_index)
	if choice.has("check"):
		var p: float = odds_for(choice["check"], toggled)["probability"]
		attempts = check_attempts(choice)
		for attempt in range(attempts):
			var raw: float = check_roll(choice_index, attempt)
			if attempt == 0:
				shown_roll = clampi(ceili(snappedf(100.0 - raw * 100.0, 0.000001)), 1, 100)
				shown_needed = floori(snappedf(100.0 - p * 100.0, 0.000001)) + 1
			if raw < p:
				successes += 1
		outcome = "success" if successes > 0 else "fail"
		source = choice.get("bySuccesses", {}).get(str(successes), choice[outcome])
		_rolled(event_state)[_roll_key(choice_index)] = prior_rolls(choice_index) + 1
		_clear_next_check_bonuses(event_state)
	# A toggled consumable is spent only here, on committing its own option,
	# rolled or not.
	var spent: Array = []
	for mod in _optional_mods(choice_index):
		if not toggled.has(mod["item"]) or spent.has(mod["item"]):
			continue
		if mod.has("effect"):
			spent.append(mod["item"])
			apply_item_effect(mod["item"], mod["effect"], item_source(mod["item"]))
		elif mod.get("consume", false):
			spent.append(mod["item"])
			_pay_item(mod["item"], item_source(mod["item"]))

	var resolution: Dictionary = { "text": source["result_text"] }
	if source.has("image"):
		resolution["image"] = source["image"]
	elif choice.has("image"):
		resolution["image"] = choice["image"]
	if outcome != "":
		resolution["outcome"] = outcome
	if attempts == 1 and outcome != "":
		resolution["roll"] = shown_roll
		resolution["needed"] = shown_needed
	if attempts > 1:
		resolution["successes"] = successes
		resolution["attempts"] = attempts
	var target := _goto_target(source.get("goto"))
	if target >= 0:
		resolution["goto"] = target
	event_state["choiceResults"][str(event_state["cardIndex"])] = resolution
	if not event_state.has("picked"):
		event_state["picked"] = {}
	var picked: Array = event_state["picked"].get(str(event_state["cardIndex"]), [])
	if not picked.has(choice_index):
		picked.append(choice_index)
	event_state["picked"][str(event_state["cardIndex"])] = picked
	_remember_choice(event_state["eventId"], str(card.get("key", event_state["cardIndex"])), str(choice.get("id", choice_index)), outcome, successes if attempts > 1 else -1, pick_ore)
	var effects: Array = choice.get("effects", [])
	if choice.has("pick"):
		effects = effects + source.get("effects", [])
	if outcome != "":
		for i in range(successes):
			effects = effects + choice["check"].get("perSuccess", [])
		effects = effects + source.get("effects", [])
	if not re_asked:
		apply_effects(effects)
	# A blank result_text shows no resolution card: play moves straight on (R§3.9a Goto),
	# unless the effects ended this event or started another.
	if is_silent_text(resolution["text"]) and is_same(GameState.state["event"], event_state):
		_continue()


# True for a result_text that shows no resolution card: null or blank.
static func is_silent_text(text: Variant) -> bool:
	return text == null or String(text).strip_edges() == ""


# Choice memory: flags.choices[eventId][cardKey] = {id, outcome?,
# successes?} (outcome "success"/"fail" for a check option; successes for a
# multi-attempt check). Lives in the state tree, so Rewind's snapshot restore
# drops a rewound pick for free.
static func _remember_choice(event_id: String, card_key: String, option_id: String, outcome: String = "", successes: int = -1, ore: String = "") -> void:
	var memory: Dictionary = GameState.state["flags"]["choices"]
	if not memory.has(event_id):
		memory[event_id] = {}
	var record := { "id": option_id }
	if ore != "":
		record["ore"] = ore
	if outcome != "":
		record["outcome"] = outcome
	if successes >= 0:
		record["successes"] = successes
	memory[event_id][card_key] = record


# ── checks (opening-choices spec "Event engine": Odds, Deterministic rolls) ──

# Odds for the current choice card's option: {} when it has no check, else
# {probability, base, mods:[{label, delta}], attempts}. The event
# screen reads only this; it never computes odds itself. probability is per
# attempt. A check already rolled before a Rewind rolls twice and keeps the
# best, so its probability is 1 - (1 - p)^2, listed as one extra modifier.
static func check_odds(choice_index: int) -> Dictionary:
	var choice: Dictionary = current_card()["choices"][choice_index]
	if not choice.has("check"):
		return {}
	var odds := odds_for(choice["check"], active_toggles(choice_index))
	odds["attempts"] = check_attempts(choice)
	if prior_rolls(choice_index) > 0:
		var p: float = odds["probability"]
		var advantaged: float = 1.0 - (1.0 - p) * (1.0 - p)
		odds["mods"].append({ "label": GameData.EVENT_CHECKS["rewoundLabel"], "delta": advantaged - p })
		odds["probability"] = advantaged
	return odds


# How many times this option's check on the current card has been rolled
# this event run. Kept across Rewind (see rewind()), so a nonzero count means
# the check is being re-rolled after a Rewind.
static func prior_rolls(choice_index: int) -> int:
	return int(GameState.state["event"].get("rolled", {}).get(_roll_key(choice_index), 0))


# How many times a check option rolls on commit (check.attempts, default 1).
static func check_attempts(choice: Dictionary) -> int:
	return maxi(1, int(choice.get("check", {}).get("attempts", 1)))


static func _rolled(event_state: Dictionary) -> Dictionary:
	if not event_state.has("rolled"):
		event_state["rolled"] = {}
	return event_state["rolled"]


static func _roll_key(choice_index: int) -> String:
	return "%d|%d" % [int(GameState.state["event"]["cardIndex"]), choice_index]


# base + every matching modifier's signed delta, clamped to [min, max].
# toggled: the optional items switched on for this option (active_toggles()).
# lasting: false leaves out state.event.lasting bonuses (an alert cover).
# A check boosted by an item (a toggled item effect, or a lasting bonus)
# defaults its max to eventChecks.itemBoostedMax instead of defaultMax.
static func odds_for(check: Dictionary, toggled: Array = [], lasting: bool = true) -> Dictionary:
	var base: float = float(check.get("base", 0.0))
	var probability := base
	var applied: Array = []
	var boosted := false
	for mod in check.get("mods", []):
		var item_effect: bool = mod.has("effect") and toggled.has(mod.get("item", ""))
		boosted = boosted or item_effect
		var delta: float = _bypass_gain(base, mod["item"]) if item_effect and mod["effect"].get("kind") == "unlock" else _mod_delta(mod, toggled)
		if delta != 0.0:
			probability += delta
			var label: String = GameData.EVENT_CHECKS["alert"]["modFormat"] % alert_tier_name(alert_level()) if mod.has("alertByTier") else mod.get("label", "")
			applied.append({ "label": label, "delta": delta })
	for bonus in (_lasting_bonuses(check, toggled) if lasting else []):
		boosted = true
		probability += float(bonus["delta"])
		applied.append(bonus)
	if check.get("raidFactors", false):
		for factor in Observation.raid_mods():
			probability += float(factor["delta"])
			applied.append(factor)
	if ActiveEffects.lady_active():
		var lady_delta: float = float(GameData.EVENT_CHECKS["ladyBonusPerLevel"]) * ActiveEffects.lady_level()
		if lady_delta != 0.0:
			probability += lady_delta
			applied.append({ "label": GameData.EVENT_CHECKS["ladyLabel"], "delta": lady_delta })
	var lo: float = float(check.get("min", GameData.EVENT_CHECKS["defaultMin"]))
	var hi: float = float(check.get("max", GameData.EVENT_CHECKS["itemBoostedMax" if boosted else "defaultMax"]))
	probability = clampf(probability, lo, hi)
	return { "probability": probability, "base": base, "mods": applied }


# A modifier's signed delta: a {path, perPoint} mod scales with the value;
# a toggled `bonus` item effect adds its "add" scaled by item_tier_scale();
# every other mod adds its "add" when condition_met() holds right now.
static func _mod_delta(mod: Dictionary, toggled: Array = []) -> float:
	if mod.has("effect"):
		var effect: Dictionary = mod["effect"]
		if effect.get("kind") == "bonus" and toggled.has(mod.get("item", "")):
			return float(effect.get("add", 0.0)) * item_tier_scale(mod["item"])
		return 0.0
	if mod.has("path") and mod.has("perPoint"):
		var value: float = float(GameState.read_path(mod["path"], 0))
		return float(mod["perPoint"]) * maxf(0.0, value - float(mod.get("above", 0)))
	if mod.has("alertByTier"):
		var by_tier: Array = mod["alertByTier"]
		var level := alert_level()
		return float(by_tier[level]) if level < by_tier.size() else 0.0
	return float(mod.get("add", 0.0)) if condition_met(mod, toggled) else 0.0


# The condition vocabulary shared by check mods and option `requires`
# (R§3.9a): {item} held, {item, equipped} in a loadout slot, {item, optional}
# toggled on (toggled = active_toggles()), {flag} truthy, {choice: {event,
# card (key), option}} remembered, {path, atLeast}, {relation, atLeast},
# {cash: {atLeast}}, {recipeRung: {recipe, rung}} owned (vague or exact),
# {observed: {id, ore, atLeast}} read this run (R§3.9d), {alert: {atLeast?,
# atMost?}} the live event's alert level, {security: {feature, atLeast?,
# atMost?, is?}} the live raid's security profile, {all: [conditions]} every
# part holds. Unknown shapes never hold.
static func condition_met(condition: Dictionary, toggled: Array = []) -> bool:
	if condition.has("all"):
		for part in condition["all"]:
			if not condition_met(part, toggled):
				return false
		return true
	if condition.has("item"):
		if condition.get("equipped", false):
			return Loadout.find_slot(condition["item"]) >= 0
		if condition.get("optional", false):
			return toggled.has(condition["item"])
		return Crafting.inventory_qty(condition["item"]) > 0
	if condition.has("flag"):
		return true if GameState.state["flags"].get(condition["flag"], false) else false
	if condition.has("choice"):
		var c: Dictionary = condition["choice"]
		var record := choice_record(c["event"], str(c["card"]))
		if c.has("ore") and record.get("ore") != c["ore"]:
			return false
		return record.get("id") == _option_key(c["option"])
	if condition.has("path"):
		return float(GameState.read_path(condition["path"], 0)) >= float(condition["atLeast"])
	if condition.has("relation"):
		var contact: Dictionary = GameState.state["contacts"].get(condition["relation"], {})
		return contact.get("relation", 0) >= condition["atLeast"]
	if condition.has("cash"):
		return GameState.state["player"]["cash"] >= condition["cash"]["atLeast"]
	if condition.has("recipeRung"):
		var r: Dictionary = condition["recipeRung"]
		return RecipeKnowledge.owns_rung(r["recipe"], r["rung"])
	if condition.has("observed"):
		return Observation.observed(condition["observed"])
	if condition.has("alert"):
		var a: Dictionary = condition["alert"]
		var level := alert_level()
		return level >= int(a.get("atLeast", 0)) and level <= int(a.get("atMost", level))
	if condition.has("security"):
		return _security_met(condition["security"])
	if condition.has("wardTriggered"):
		return ward_triggered_here() == bool(condition["wardTriggered"])
	if condition.has("reinforcements"):
		return reinforcements_arrived() == bool(condition["reinforcements"])
	return false


# ── security profile (R§3.12 "Security profile") ──

# The live event's security profile (context.securityProfile); {} with none.
static func security_profile() -> Dictionary:
	var event_state: Variant = GameState.state.get("event")
	return event_state.get("context", {}).get("securityProfile", {}) if event_state != null else {}


# {feature, atLeast?, atMost?, is?}: `is` matches a string feature exactly;
# otherwise the feature as a count (true = 1, absent = 0) lies in
# [atLeast, atMost], atLeast defaulting to 1 (0 when only atMost is given).
static func _security_met(s: Dictionary) -> bool:
	var value: Variant = security_profile().get(String(s.get("feature", "")))
	if s.has("is"):
		return value != null and str(value) == str(s["is"])
	var n := _security_count(value)
	return n >= int(s.get("atLeast", 0 if s.has("atMost") else 1)) and n <= int(s.get("atMost", n))


static func _security_count(value: Variant) -> int:
	if value is bool:
		return 1 if value else 0
	return int(value) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else 0


# ── alert level (R§3.9a "Alert") ──

# The live event's alert tier (0 = eventChecks.alert.tiers[0]); 0 with no event.
static func alert_level() -> int:
	var event_state: Variant = GameState.state.get("event")
	return int(event_state.get("alert", 0)) if event_state != null else 0


static func alert_tier_name(level: int) -> String:
	return String(GameData.EVENT_CHECKS["alert"]["tiers"][_clamp_alert(level)])


static func _clamp_alert(level: int) -> int:
	return clampi(level, 0, (GameData.EVENT_CHECKS["alert"]["tiers"] as Array).size() - 1)


# Caught = the live event's alert at or above eventChecks.alert.caughtAtLeast.
static func alert_caught() -> bool:
	return alert_level() >= int(GameData.EVENT_CHECKS["alert"]["caughtAtLeast"])


# The `alert` op: `add` shifts the level (signed), `atLeast` raises it to that
# tier if lower; clamped to the tier range. No-op outside a live event. A
# `cover` check rolled first and passed leaves the level as it is and adds its
# line to the current card's result text (R§3.9a "Alert").
static func _apply_alert(effect: Dictionary) -> void:
	var event_state: Variant = GameState.state.get("event")
	if event_state == null:
		return
	if effect.has("cover") and _roll_cover(effect["cover"]):
		return
	var level := alert_level() + int(effect.get("add", 0))
	if effect.has("atLeast"):
		level = maxi(level, int(effect["atLeast"]))
	event_state["alert"] = _clamp_alert(level)
	_maybe_start_reinforcement_clock()


# ── reinforcement clock (R§3.12 "Reinforcements") ──

# Alarm on a site with an alarm line starts event.reinforce {ticks, length,
# arrived, skip}; skip spares the card that raised it. length is the event's
# `reinforceClock` or raidSecurity.reinforcement.clockCards. No-op if started.
static func _maybe_start_reinforcement_clock() -> void:
	var event_state: Dictionary = GameState.state["event"]
	if event_state.has("reinforce") or alert_level() < (GameData.EVENT_CHECKS["alert"]["tiers"] as Array).size() - 1:
		return
	if _security_count(security_profile().get("alarm")) <= 0:
		return
	var cfg: Dictionary = GameData.RAID_SECURITY["reinforcement"]
	var length := int(_event_def().get("reinforceClock", cfg["clockCards"]))
	event_state["reinforce"] = { "ticks": 0, "length": length, "arrived": false, "skip": true }


# One tick per card resolved after the raising card; at length the guards arrive.
static func _tick_reinforcement() -> void:
	var clock: Variant = GameState.state["event"].get("reinforce")
	if clock == null or clock["arrived"]:
		return
	if clock["skip"]:
		clock["skip"] = false
		return
	clock["ticks"] = int(clock["ticks"]) + 1
	if int(clock["ticks"]) >= int(clock["length"]):
		clock["arrived"] = true


# Reinforcements already in the pool (the clock fired or a fight took them).
static func reinforcements_arrived() -> bool:
	var event_state: Variant = GameState.state.get("event")
	return event_state != null and event_state.get("reinforce", {}).get("arrived", false)


# Clock running, not fired, Alarm still up: the next fight gets them at round 3.
static func reinforcements_pending() -> bool:
	var event_state: Variant = GameState.state.get("event")
	if event_state == null or not event_state.has("reinforce") or reinforcements_arrived():
		return false
	return alert_level() >= (GameData.EVENT_CHECKS["alert"]["tiers"] as Array).size() - 1


# Rolls an alert op's cover ({base, mods?, min?, max?, text}) through
# odds_for(), so Be A Lady and authored mods count (not lasting or
# next-check bonuses, which belong to choice checks). On success the cover's
# text joins the current card's resolution (or becomes it, when silent).
static func _roll_cover(cover: Dictionary) -> bool:
	var event_state: Dictionary = GameState.state["event"]
	var roll := cover_roll()
	var covers: Dictionary = event_state.get("covers", {})
	var card := str(int(event_state["cardIndex"]))
	covers[card] = int(covers.get(card, 0)) + 1
	event_state["covers"] = covers
	if roll >= float(odds_for(cover, [], false)["probability"]):
		return false
	var resolution: Variant = event_state["choiceResults"].get(card)
	if resolution != null:
		var text: Variant = resolution.get("text")
		resolution["text"] = cover.get("text", "") if is_silent_text(text) else "%s\n\n%s" % [text, cover.get("text", "")]
	return true


# The next cover roll on the current card in [0,1): a stable hash of
# world.rollSeed, event id, card index and how many covers this card has
# rolled (plus run_key() for a repeatable event), so Rewind and a save reload
# replay it. Never draws from the global Rng stream.
static func cover_roll() -> float:
	var event_state: Dictionary = GameState.state["event"]
	var card := int(event_state["cardIndex"])
	var key := "%d|%s|%d|cover|%d" % [int(GameState.state["world"]["rollSeed"]), event_state["eventId"], card, int(event_state.get("covers", {}).get(str(card), 0))]
	if _event_def().get("repeatable", false):
		key += "|" + run_key()
	return Rng.stable_unit(key)


# ── option gating (R§3.9a "Requires") ──

# How the current card's option shows: {display: "show"|"hide"|"disable",
# reason}. An option with no `requires`, or whose condition holds, shows;
# otherwise its requires.display decides (default "hide"). Only a "show"
# option can be committed.
static func option_gate(choice_index: int) -> Dictionary:
	var choice: Dictionary = current_card()["choices"][choice_index]
	if _spent_one_shot(choice_index):
		return { "display": "hide", "reason": "", "asked": true }
	var asked := _picked_here().has(choice_index)
	var requires: Variant = choice.get("requires")
	var toggled := active_toggles(choice_index)
	if not requires is Dictionary or condition_met(requires, toggled):
		return _pick_gate(choice, asked) if choice.has("pick") else { "display": "show", "reason": "", "asked": asked }
	var display: String = requires.get("display", "hide")
	return { "display": display if display == "disable" else "hide", "reason": String(requires.get("reason", "")), "asked": asked }


# The ? modal's lines for a locked option: one per unmet part of its `requires`
# (observation tier, item), then the authored `reason` if any. [] when it holds.
static func unmet_requirement_lines(choice_index: int) -> Array:
	var choice: Dictionary = current_card()["choices"][choice_index]
	var requires: Variant = choice.get("requires")
	var toggled := active_toggles(choice_index)
	if not requires is Dictionary or condition_met(requires, toggled):
		return []
	var out: Array = []
	var parts: Array = requires["all"] if requires.has("all") else [requires]
	for part in parts:
		if not condition_met(part, toggled):
			var line := _unmet_line(part)
			if line != "":
				out.append(line)
	var reason := String(requires.get("reason", ""))
	if reason != "":
		out.append(reason)
	return out


static func _unmet_line(part: Dictionary) -> String:
	var texts: Dictionary = GameData.EVENT_CHECKS["unmet"]
	if part.has("observed"):
		var entry: Dictionary = Observation.unmet_entry(part["observed"])
		return texts["observed"] % [entry["obs"], entry["ore_name"], entry["at_least"]]
	if part.has("item"):
		var name: String = GameData.RECIPES.get(part["item"], {}).get("name", part["item"])
		return texts["itemOptional" if part.get("optional", false) else "item"] % name
	if part.has("alert"):
		var a: Dictionary = part["alert"]
		if a.has("atLeast") and alert_level() < int(a["atLeast"]):
			return texts["alertAtLeast"] % alert_tier_name(int(a["atLeast"]))
		return texts["alertAtMost"] % alert_tier_name(int(a.get("atMost", 0)))
	if part.has("security"):
		return _security_unmet_line(part["security"], texts)
	return ""


# Names the missing feature (raidSecurity.featureNames): its `absent` text
# for atMost 0, its name with the bound for a count, its name alone otherwise.
static func _security_unmet_line(s: Dictionary, texts: Dictionary) -> String:
	var feature := String(s.get("feature", ""))
	var names: Dictionary = GameData.RAID_SECURITY["featureNames"].get(feature, { "name": feature, "absent": feature })
	if s.has("is"):
		return texts["securityIs"] % [names["name"], str(s["is"])]
	if s.has("atMost") and int(s["atMost"]) == 0:
		return texts["security"] % names["absent"]
	var n := _security_count(security_profile().get(feature))
	if s.has("atMost") and n > int(s["atMost"]):
		return texts["securityAtMost"] % [names["name"], int(s["atMost"])]
	var at_least := int(s.get("atLeast", 1))
	return texts["securityAtLeast"] % [names["name"], at_least] if at_least > 1 else texts["security"] % names["name"]


# A pick option shows only while some ore qualifies; otherwise it's greyed with
# its reason (R§3.9d "Observation pick").
static func _pick_gate(choice: Dictionary, asked: bool) -> Dictionary:
	if Observation.pick_ores(choice).is_empty():
		var reason: String = choice["pick"].get("reason", GameData.OBSERVATION["pickReason"])
		return { "display": "disable", "reason": reason, "asked": asked }
	return { "display": "show", "reason": "", "asked": asked }


# ── conversation hubs (R§3.9a "Hub advance") ──

# Index of the current choice card's option flagged `exit: true` (the hub's
# footer →), or -1 for a card without one.
static func hub_exit_index() -> int:
	var choices: Array = current_card().get("choices", [])
	for i in range(choices.size()):
		if choices[i].get("exit", false) == true:
			return i
	return -1


# True when the hub's exit may be taken now: it exists and shows, and the card's
# `advance` rule is met -- "anytime" (default), "all" (every askable question
# asked) or an integer N (N questions asked). A rule that can never be met
# (N above the askable questions, or an unknown rule) logs an error and opens
# the exit, so the hub always completes.
static func hub_exit_available() -> bool:
	var exit_index := hub_exit_index()
	if exit_index < 0 or option_gate(exit_index)["display"] != "show":
		return false
	var rule: Variant = current_card().get("advance", "anytime")
	if rule is String and rule == "anytime":
		return true
	var asked := 0
	var askable := 0
	for i in range(current_card()["choices"].size()):
		if i == exit_index:
			continue
		if _picked_here().has(i):
			asked += 1
			askable += 1
		elif option_gate(i)["display"] != "hide":
			askable += 1
	if rule is String and rule == "all":
		return asked >= askable
	if typeof(rule) == TYPE_INT or typeof(rule) == TYPE_FLOAT:
		if int(rule) <= askable:
			return asked >= int(rule)
	push_error("Events: hub card %d of '%s' can never meet advance rule %s; showing the exit" % [int(GameState.state["event"]["cardIndex"]), GameState.state["event"]["eventId"], str(rule)])
	return true


static func _picked_here() -> Array:
	var event_state: Dictionary = GameState.state["event"]
	return event_state.get("picked", {}).get(str(event_state["cardIndex"]), [])


# True when option `choice_index` of the current card was already picked on an
# earlier visit to this hub and is one-shot (no `reselectable: true`). The
# exit option is never spent. On a hub without an exit option, never true for
# the last remaining forward exit (a non-back-edge option): that one stays
# visible so the event can finish (push_error).
static func _spent_one_shot(choice_index: int) -> bool:
	var event_state: Dictionary = GameState.state["event"]
	var picked: Array = _picked_here()
	var choices: Array = current_card()["choices"]
	if not picked.has(choice_index) or choices[choice_index].get("reselectable", false) == true:
		return false
	if choices[choice_index].get("exit", false) == true:
		return false
	if hub_exit_index() >= 0:
		return true
	if not _is_back_edge(choices[choice_index]):
		for i in range(choices.size()):
			if i != choice_index and not _is_back_edge(choices[i]) and (not picked.has(i) or choices[i].get("reselectable", false) == true):
				return true
		push_error("Events: hub card %d of '%s' has no forward exit left; showing option %d" % [int(event_state["cardIndex"]), event_state["eventId"], choice_index])
		return false
	return true


# True when the option, or any of its outcomes, has a `goto` to this card or an
# earlier one (a hub loop).
static func _is_back_edge(choice: Dictionary) -> bool:
	var here: int = int(GameState.state["event"]["cardIndex"])
	var cards: Array = _event_def()["cards"]
	var sources: Array = [choice, choice.get("success"), choice.get("fail")]
	sources.append_array(choice.get("bySuccesses", {}).values())
	for source in sources:
		if source is Dictionary:
			var target := _goto_index(source.get("goto"), cards)
			if target >= 0 and target <= here:
				return true
	return false


# An option reference as choice memory stores it: a string id, or an index
# (JSON parses it as a float) as its integer string.
static func _option_key(option: Variant) -> String:
	if option is String:
		return option
	return str(int(option))


# What distinguishes one run of an event from another for stable rolls
# (R§3.9a "Roll"): world.day, plus ":<site_id>" when the live event's context
# names a site. Pure state, so a save reload yields the same key.
static func run_key() -> String:
	var key := str(int(GameState.state["world"]["day"]))
	var site_id: String = _live_event_context().get("site_id", "")
	if site_id != "":
		key += ":" + site_id
	return key


# The check's roll in [0,1) for the current card's option: a stable hash of
# world.rollSeed, event id, card index, option index, prior_rolls(), run_key()
# (only for an event with `repeatable: true`) and the toggled optional items
# (sorted, appended only when any), plus "|a<n>" for attempt n > 0 of a
# multi-attempt check, so each re-roll after a Rewind is fresh, changed
# preparation can change it, and a save reload replays the same roll. A
# re-roll draws a second value per attempt and keeps the lower (best of two).
# Never draws from the global Rng stream.
static func check_roll(choice_index: int, attempt_index: int = 0) -> float:
	var event_state: Dictionary = GameState.state["event"]
	var prior: int = prior_rolls(choice_index)
	var key := "%d|%s|%d|%d|%d" % [int(GameState.state["world"]["rollSeed"]), event_state["eventId"], int(event_state["cardIndex"]), choice_index, prior]
	if _event_def().get("repeatable", false):
		key += "|" + run_key()
	var toggled := active_toggles(choice_index)
	if not toggled.is_empty():
		key += "|" + ",".join(PackedStringArray(toggled))
	if attempt_index > 0:
		key += "|a%d" % attempt_index
	var roll: float = Rng.stable_unit(key)
	if prior > 0:
		roll = minf(roll, Rng.stable_unit(key + "|adv"))
	return roll


# ── wards (R§3.12 "Wards") ──

# The live raid's ward type (wards.json types[securityProfile.wardType]); {} with no ward.
static func live_ward() -> Dictionary:
	var ward_type := String(security_profile().get("wardType", ""))
	return GameData.WARDS["types"].get(ward_type, {}) if ward_type != "" else {}


# True when the live event's ward triggered on the current card.
static func ward_triggered_here() -> bool:
	return _marked_here("wardTrigger")


static func _marked_here(key: String) -> bool:
	var event_state: Variant = GameState.state.get("event")
	return event_state != null and event_state.has(key) and int(event_state[key]) == int(event_state["cardIndex"])


# The `ward_trigger` op: the live raid's ward bites at most once per card, and
# not on a card an item slipped it (wardPass). Marks the card, so a
# start_raid_combat later on it gets the type's fightStart, then runs the
# type's onTrigger effects. No-op with no ward.
static func trigger_ward() -> void:
	var ward := live_ward()
	if ward.is_empty() or ward_triggered_here() or _marked_here("wardPassed"):
		return
	var event_state: Dictionary = GameState.state["event"]
	event_state["wardTrigger"] = int(event_state["cardIndex"])
	for effect in ward["onTrigger"]:
		_apply_one(effect)


# The triggered ward's fightStart as one situational entry gated on
# `wardTriggered`, or [] when it didn't trigger here or starts nothing.
static func _ward_fight_start() -> Array:
	var fight_start: Dictionary = live_ward().get("fightStart", {})
	if fight_start.is_empty() or not ward_triggered_here():
		return []
	var entry := { "if": { "wardTriggered": true } }
	entry.merge(fight_start)
	return [entry]


# `wardPass` at a ward with the powerVsFreeze counter: the item's effectPower
# at the tier spent against the ward's freezeRounds. At or above, it's through:
# the ward can't trigger on this card and true is returned. Below, the ward
# triggers now. Any other ward (or none) is left alone.
static func _ward_pass(item: String, tier: int) -> bool:
	var ward := live_ward()
	if not ward.get("counters", []).has("powerVsFreeze"):
		return false
	if float(Crafting.effect_power(item, tier)) >= float(ward["freezeRounds"]):
		var event_state: Dictionary = GameState.state["event"]
		event_state["wardPassed"] = int(event_state["cardIndex"])
		return true
	trigger_ward()
	return false


# ── item effects (R§3.9a Item effects) ──

const ITEM_SOURCE_INVENTORY := "inventory"
const ITEM_SOURCE_DIAL := "dial"


# Where an item effect would be paid from now: inventory first, then a loaded
# Dial Complication of that recipe with charge to cast it; "" when neither.
static func item_source(item: String) -> String:
	if Crafting.inventory_qty(item) > 0:
		return ITEM_SOURCE_INVENTORY
	if Dial.find_loaded_complication_index(item) >= 0:
		return ITEM_SOURCE_DIAL
	return ""


# The tier a commit would spend: highest held in inventory, else the loaded
# Complication's stored tier; 0 with neither.
static func _source_tier(item: String) -> int:
	match item_source(item):
		ITEM_SOURCE_INVENTORY:
			return Crafting.highest_tier(item)
		ITEM_SOURCE_DIAL:
			var dial: Dictionary = GameState.state["player"]["dial"]
			return int(dial["loadedComplications"][Dial.find_loaded_complication_index(item)]["tier"])
	return 0


# Pays for an item effect from `source`; the tier paid, 0 when nothing was.
# Inventory spends the highest tier held, a Dial cast spends the loaded
# Complication's charge at its stored tier, so the odds shown before commit
# are the odds rolled.
static func _pay_item(item: String, source: String) -> int:
	var tier := _source_tier(item)
	if tier <= 0:
		return 0
	if source == ITEM_SOURCE_INVENTORY and Crafting.inventory_qty(item) > 0:
		Crafting.inventory_remove_from_tier(item, tier, 1)
		return tier
	if source == ITEM_SOURCE_DIAL:
		var index := Dial.find_loaded_complication_index(item)
		if index >= 0:
			tier = int(GameState.state["player"]["dial"]["loadedComplications"][index]["tier"])
			Dial.cast_complication(index)
			return tier
	return 0


# A rolled item effect's strength multiplier at `tier` (eventChecks.itemTierScale,
# tier 1 first); tier -1 reads the tier a commit spends (_source_tier()).
# 1.0 with none held.
static func item_tier_scale(item: String, tier: int = -1) -> float:
	if tier < 0:
		tier = _source_tier(item)
	var scale: Array = GameData.EVENT_CHECKS["itemTierScale"]
	return float(scale[clampi(tier, 1, scale.size()) - 1]) if tier > 0 else 1.0


# A bypass (an `unlock` item on a check option) scales the check's base by
# shrinking its miss chance: 1 − (1 − base) / scale. Returns the gain over base.
static func _bypass_gain(base: float, item: String) -> float:
	return (1.0 - base) * (1.0 - 1.0 / item_tier_scale(item))


# The one resolver for a toggled item's `effect` on commit: pays from `source`,
# then applies by kind. Items never fail; the payment is spent whatever the roll
# does. `bonus` with an `entry` tag also persists in event.lasting for the rest
# of the event (pure data, gone when the event ends). Any kind may carry
# `nextCheck: {add, label?}`: a lasting entry for the next check rolled in this
# event only, labelled with the item's name unless given one. `wardPass` that
# gets through a ward skips its nextCheck.
static func apply_item_effect(item: String, effect: Dictionary, source: String) -> void:
	var tier := _pay_item(item, source)
	match effect.get("kind", ""):
		"wardPass":
			if _ward_pass(item, maxi(tier, 1)):
				return
		"revealWard":
			Observation.mark_ward_revealed()
		"bonus":
			if effect.has("entry"):
				_lasting(GameState.state["event"]).append({
					"item": item,
					"entry": effect["entry"],
					"add": float(effect.get("add", 0.0)) * item_tier_scale(item, tier),
					"label": effect.get("label", ""),
				})
	if effect.has("nextCheck"):
		var next: Dictionary = effect["nextCheck"]
		_lasting(GameState.state["event"]).append({
			"item": item,
			"next": true,
			"add": float(next.get("add", 0.0)),
			"label": next.get("label", GameData.RECIPES.get(item, {}).get("name", item)),
		})


static func _lasting(event_state: Dictionary) -> Array:
	if not event_state.has("lasting"):
		event_state["lasting"] = []
	return event_state["lasting"]


# Drops the next-check-only entries once a check has rolled, pass or fail.
static func _clear_next_check_bonuses(event_state: Dictionary) -> void:
	if event_state.has("lasting"):
		event_state["lasting"] = event_state["lasting"].filter(func(e: Dictionary) -> bool: return not e.get("next", false))


# Persisted bonuses that apply to `check`: every next-check-only entry, plus
# each `entry` bonus whose tag matches, skipping an item that is toggled on
# this very check (already counted by its own mod).
static func _lasting_bonuses(check: Dictionary, toggled: Array) -> Array:
	var out: Array = []
	var event_state: Variant = GameState.state.get("event")
	if not (event_state is Dictionary):
		return out
	for entry in event_state.get("lasting", []):
		if entry.get("next", false) or (check.has("entry") and entry["entry"] == check["entry"] and not toggled.has(entry["item"])):
			out.append({ "label": entry["label"], "delta": entry["add"] })
	return out


# ── optional item toggles (spec "Item toggle in state") ──

# The optional item mods on the current card's option, for the screen:
# [{item, name, delta, on, held}] in mod order. "held" false means none in
# inventory, so the toggle can't be switched on.
static func item_toggles(choice_index: int) -> Array:
	var out: Array = []
	var stored: Array = _stored_toggles(choice_index)
	for mod in _optional_mods(choice_index):
		var item: String = mod["item"]
		var source := item_source(item)
		var held: bool = source != ""
		out.append({
			"item": item,
			"source": source,
			"name": GameData.RECIPES.get(item, {}).get("name", item),
			"delta": _mod_delta(mod, [item]) if mod.has("effect") else float(mod.get("add", 0.0)),
			"on": held and stored.has(item),
			"held": held,
		})
	return out


# Flips an optional item on or off for the current card's option. Kept in
# state.event.toggles["<cardIndex>|<optionIndex>"], so save and Rewind
# capture it; takes no snapshot and spends nothing (choose() spends).
static func toggle_item(choice_index: int, item: String) -> Dictionary:
	if not is_awaiting_choice():
		return { "ok": false, "reason": "No choice to prepare for." }
	if not _optional_mods(choice_index).any(func(m: Dictionary) -> bool: return m["item"] == item):
		return { "ok": false, "reason": "That item doesn't help here." }
	var event_state: Dictionary = GameState.state["event"]
	if not event_state.has("toggles"):
		event_state["toggles"] = {}
	var key := _roll_key(choice_index)
	var stored: Array = event_state["toggles"].get(key, []).duplicate()
	if stored.has(item):
		stored.erase(item)
	elif item_source(item) == "":
		return { "ok": false, "reason": "None on you." }
	else:
		stored.append(item)
	event_state["toggles"][key] = stored
	EventBus.state_changed.emit()
	return { "ok": true }


# The toggled optional items that count right now: switched on for this
# option, still an optional mod on it, and still held. Sorted, so the roll
# key doesn't depend on toggle order.
static func active_toggles(choice_index: int) -> Array:
	var stored: Array = _stored_toggles(choice_index)
	var out: Array = []
	for mod in _optional_mods(choice_index):
		var item: String = mod["item"]
		if stored.has(item) and not out.has(item) and item_source(item) != "":
			out.append(item)
	out.sort()
	return out


static func _stored_toggles(choice_index: int) -> Array:
	return GameState.state["event"].get("toggles", {}).get(_roll_key(choice_index), [])


# A check option's optional item mods, or a no-roll option's `items` (same shape).
static func _optional_mods(choice_index: int) -> Array:
	var choice: Dictionary = current_card()["choices"][choice_index]
	var mods: Array = choice["check"].get("mods", []) if choice.has("check") else choice.get("items", [])
	return mods.filter(func(m: Dictionary) -> bool: return m.has("item") and m.get("optional", false))


# The committed choice at an event's card, or {} if none was made.
static func choice_record(event_id: String, card_key: String) -> Dictionary:
	var memory: Dictionary = GameState.state["flags"]["choices"]
	return memory.get(event_id, {}).get(card_key, {}).duplicate()


# The committed option's id (its "id" field, else its index as a string), or null.
static func choice_id(event_id: String, card_key: String) -> Variant:
	return choice_record(event_id, card_key).get("id")


# Shared by advance()/choose(). event.snapshots must be emptied before the deep
# copy -- it lives inside the tree being copied, and left in place would embed
# every prior snapshot into the new one, compounding across a long event.
# state.blockStart (a whole-state copy, Rewind) is left out the same way;
# rewind() keeps the live one.
static func _snapshot_before_mutation() -> void:
	var event_state: Dictionary = GameState.state["event"]
	var stack: Array = event_state["snapshots"]
	event_state["snapshots"] = []
	var block_start: Variant = GameState.state.get("blockStart")
	GameState.state["blockStart"] = null
	var snap: Dictionary = GameState.deep_copy(GameState.state)
	GameState.state["blockStart"] = block_start
	event_state["snapshots"] = stack
	Snapshots.push("event", stack, snap)


# source: "consumable" or "dial" pays from that source only; "" prefers the
# consumable and falls back to a loaded Dial Rewind complication.
static func rewind(source: String = "") -> Dictionary:
	if not can_rewind():
		return { "ok": false, "reason": "No rewind available." }

	var event_state: Dictionary = GameState.state["event"]
	var has_consumable: bool = Crafting.inventory_qty("rewind") > 0
	var rewind_index: int = Dial.find_loaded_rewind_complication_index()
	match source:
		"consumable":
			if not has_consumable:
				return { "ok": false, "reason": "No Rewind in stock." }
		"dial":
			if rewind_index < 0:
				return { "ok": false, "reason": "No Dial Rewind charge." }
			has_consumable = false

	var stack: Array = event_state["snapshots"]
	var snap: Dictionary = Snapshots.pop_newest(stack)
	var live_meta: Dictionary = GameState.state["meta"].duplicate()
	var live_rolled: Dictionary = _rolled(event_state)
	var live_observations: Variant = event_state.get("observations")
	var snapped_observations: Dictionary = snap["event"].get("observations", {}) if snap.get("event") is Dictionary else {}
	var block_start: Variant = GameState.state.get("blockStart")
	GameState.state = snap
	GameState.state["blockStart"] = block_start
	Preferences.carry_forward(live_meta)
	# snap's own event.snapshots is always [] (see advance()) -- carry the real,
	# already-popped live stack forward instead of trusting that.
	GameState.state["event"]["snapshots"] = stack
	# Roll counts survive the Rewind, so a check rolled before it re-rolls
	# with advantage (check_odds()).
	GameState.state["event"]["rolled"] = live_rolled
	# Reads survive the Rewind; each read observation is re-armed for one more roll.
	if live_observations != null:
		GameState.state["event"]["observations"] = live_observations
		Observation.drop_refunded_reveals(snapped_observations)
	var rearmed := Observation.rearm_read()

	if has_consumable:
		Crafting.inventory_remove("rewind", 1)
	else:
		Dial.cast_complication(rewind_index)

	Notify.push("⟲ Time unspools. The moment resets. Only you remember.")
	EventBus.state_changed.emit()
	return { "ok": true, "rearmed": rearmed }


# ── effect ops ──────────────────────────────────────────────────────────

static func apply_effects(effects: Array, context: Dictionary = {}) -> void:
	for effect in effects:
		_apply_one(effect, context)
	# Every tutorial checkpoint flag is set exclusively via the set_flag op below,
	# same as several Collective flags, so this is one of the boundaries objectives.gd's own doc lists.
	Objectives.refresh()
	EventBus.state_changed.emit()


static func _apply_one(effect: Dictionary, context: Dictionary = {}) -> void:
	match effect["op"]:
		"set_flag":
			GameState.state["flags"][effect["flag"]] = effect["value"]
		"add":
			_apply_add(effect["path"], effect["value"])
		"add_ore":
			var ore: Dictionary = GameState.state["player"]["orichalchum"]
			ore[effect["type"]] = ore.get(effect["type"], 0) + effect["qty"]
		"sell_ore_at_market":
			_sell_ore_at_market(effect, context)
		"add_item":
			# Event-granted items file under tier 1 unless the effect names a `tier`;
			# `equip` then moves one unit into the first empty player loadout slot.
			var tier := int(effect.get("tier", 1))
			Crafting.inventory_add(effect["item"], tier, effect["qty"])
			if effect.get("equip", false):
				var slots: Array = GameState.state["player"]["loadout"]["slots"]
				var free := slots.find(null)
				if free >= 0:
					Loadout.equip(free, effect["item"], maxi(tier, 1))
		"relation":
			Contacts.award_relation(effect["contact"], effect["value"])
		"grant_vein_with_site":
			_grant_vein_with_site(effect["vein"])
		# grant_vein_with_site's contact-handoff cousin -- same site+vein creation, but
		# also records the new vein's id at a named state path so a later objective can find it again.
		"grant_contact_vein":
			_set_path(effect["statePath"], _grant_vein_with_site(effect["vein"]))
		"set_screen":
			# Routing to "phone" also resets phoneNav to its home view, same as every other route-to-phone-home call site.
			if effect["screen"] == "phone":
				PhoneNav.route_home()
			else:
				Nav.go_to(effect["screen"])
		"notify":
			Notify.push(effect["text"])
		"set_stage":
			GameState.state["flags"]["tutorialStage"] = effect["value"]
		# Optional opening modifiers ride the prep's args to Combat.start_home_raid_combat().
		"start_home_raid_combat":
			var mods := {}
			for key in ["enemyHpMult", "enemyFirst", "pearlLock"]:
				if effect.has(key):
					mods[key] = effect[key]
			CombatPrep.request(CombatPrep.KIND_HOME_RAID, mods)
		# Skips the fight: same consequence and debrief as the combat outcome.
		"resolve_home_raid":
			Combat.resolve_home_raid(effect["outcome"])
		"chance":
			if Rng.chance(effect["p"]):
				apply_effects(effect.get("on_success", []), context)
			else:
				apply_effects(effect.get("on_fail", []), context)
		"start_street_mugging":
			CombatPrep.request(CombatPrep.KIND_STREET_MUGGING)
		"start_scripted_fight":
			var script: Dictionary = effect["script"].duplicate()
			if effect.has("situational"):
				script["situational"] = effect["situational"]
			Combat.start_scripted_fight(script)
		"start_demo_fight":
			Combat.start_demo_fight(effect["script"])
		"start_faction_ambush_combat":
			CombatPrep.request(CombatPrep.KIND_FACTION_AMBUSH, { "factionId": _event_faction_id(effect), "district": _event_district() })
		"npc_claim_best_unclaimed_site":
			Sites.npc_claim_best_unclaimed_site(GameState.state["world"]["currentDistrict"])
		"lose_time_block":
			if not TimeSystem.is_time_exhausted():
				TimeSystem.advance_time_block()
		"tutorial_cultivate":
			_tutorial_cultivate()
		"start_raid_combat":
			_start_raid_combat(effect)
		"reduce_raid_guards":
			_reduce_raid_guards(effect)
		"alert":
			_apply_alert(effect)
		"ward_trigger":
			trigger_ward()
		"back_out":
			Raiding.back_out(_event_site_id(effect), alert_level())
		"claim_raid_vein":
			Raiding.claim_vein(_event_site_id(effect))
		"loot_raid_vein":
			Raiding.loot_vein(_event_site_id(effect), _event_caught(effect))
		# Stockpile raid ops: the raided faction comes from start_event()'s
		# context (Raiding.begin_stockpile_raid()), like a vein raid's site_id.
		"start_stockpile_raid_combat":
			_start_stockpile_raid_combat(effect)
		"loot_stockpile":
			var faction_id := _event_faction_id(effect)
			if GameState.state["factions"].has(faction_id):
				Raiding.loot_stockpile(faction_id, effect.get("all", false))
		# Contested-vein choice ops (col_a2_contested_vein, spec §6.5): both
		# resolve a site id from a named state path (no per-raid context to
		# thread, since a map pin's tap carries none) rather than reusing
		# claim_raid_vein's context-threaded site_id. veinIdStatePath instead
		# names the faction vein itself (col_a2_hakim_retake, spec §6.13).
		"claim_faction_vein":
			Raiding.claim_vein(_state_path_site_id(effect))
		"buy_faction_vein":
			_buy_faction_vein(effect)
		"unlock_contact":
			GameState.state["contacts"][effect["contact"]]["unlocked"] = true
		"recruit_contact":
			Contacts.force_recruit(effect["contact"])
		"accept_secret_offer":
			var offerer: String = effect.get("contact", context.get("contact_id", _live_event_context().get("contact_id", "")))
			KeyMembers.accept_offer(offerer)
		"activate_business":
			Business.activate()
		"set_james_crafting_skill":
			BusinessQuest.set_james_crafting_skill()
		"issue_recurring_offers":
			BusinessQuest.maybe_issue_recurring()
		"set_contact_role":
			Contacts.set_role(effect["contact"], effect["role"])
		"push_message":
			# Optional "from" lets an authored SMS thread replay its own outgoing "player" lines verbatim; defaults to "them" when omitted.
			Messages.append(effect["contact"], effect.get("from", "them"), effect["text"])
		# Ticker story article + timed ore demand rise, both keyed by a market.json storyRises id.
		"post_story":
			var story_id: String = effect["story"]
			var rise: Dictionary = GameData.MARKET["storyRises"][story_id]
			var end_day: int = int(GameState.state["world"]["day"]) + int(rise["days"])
			Market.add_story_rise(story_id)
			Barometer.push_headline(str(GameData.BAROMETER_NEWS["wireArticles"][story_id]["deck"]).format({ "ore": GameData.ORE_TYPES[rise["ore"]]["name"] }), story_id, { "ore": rise["ore"], "endDay": end_day })
		# push_message's follow-up-action cousin: queues unread text plus a pendingMessages
		# entry an action bar can surface, for a "tap to start an event" beat.
		"queue_pending_message":
			Messages.queue_pending(effect["contact"], effect["kind"], effect["text"], effect.get("payload", {}))
		# Faction-facing twin of the "relation" op above (which is contact-only).
		"faction_relation":
			Factions.adjust_player_relation(effect["faction"], effect["value"])
		# Settle the accepted favour the running event was opened for (Diplomacy.
		# settle_from_event); relation / rival + rivalRelation / memberRelation are the deltas.
		"favour_kept", "favour_failed":
			var favour_event: Variant = GameState.state.get("event")
			if favour_event != null:
				Diplomacy.settle_from_event(effect["op"] == "favour_kept", effect, favour_event.get("context", {}))
		"harassment_add":
			Harassment.add_from_event(effect)
		"harassment_clear":
			Harassment.clear_from_event(effect)
		"fine":
			Harassment.fine(int(effect["amount"]))
		"spend_block":
			Harassment.spend_blocks(int(effect.get("count", 1)))
		"raise_intel":
			Harassment.raise_intel(int(effect["amount"]))
		"log_method":
			GameState.state["methodLog"][effect["key"]] = effect["value"]
		# col_a2_nadia_defend_brief (T8a, spec §6.8a): no per-raid context to
		# resolve a site from, unlike claim_faction_vein/loot_raid_vein above --
		# Collective.pick_nadia_defend_vein() picks and writes the target itself.
		"col_a2_pick_nadia_defend_vein":
			Collective.pick_nadia_defend_vein()
		"col_a2_provoke_firm":
			Collective.provoke_firm(float(effect["multiplier"]), int(effect["days"]))
		# Act 2 T10/T11 (spec §5.4): unrolled ownership transfer. veinIdStatePath
		# names the vein (T10, Hakim's); without it, Collective picks T11's target.
		"col_a2_force_vein_loss":
			var target: Variant = GameState.read_path(effect["veinIdStatePath"]) if effect.has("veinIdStatePath") else Collective.second_loss_target_id()
			Collective.force_vein_loss(target, effect["faction"])
		# T13 (spec §5.4): runs right after the retake's claim/buy op.
		"col_a2_ruin_site":
			Collective.ruin_hakim_site()
		"network_reveal_vulnerable_vein":
			NetworkHandler.reveal_vulnerable_vein(_event_site_id(effect, context), effect["effect"])
		"network_reveal_site":
			NetworkHandler.reveal_site(effect["oreType"], effect["minTier"])
		"faction_seed_reported_sites":
			_faction_seed_reported_sites(effect["objective"], effect["faction"])
		# Resolves a contact-granted vein's id via veinIdStatePath and sells it at a forced
		# price. See VeinTrade.sell_to_faction() for why a forced price also marks the sale as not a real market transaction.
		# The state path is re-pointed at the new faction vein's id, so it keeps naming that vein after the handover.
		"sell_contact_vein_to_faction":
			var sale := VeinTrade.sell_to_faction(GameState.read_path(effect["veinIdStatePath"]), effect["faction"], effect["price"])
			if sale.get("ok", false):
				_set_path(effect["veinIdStatePath"], sale["factionVeinId"])
		# Chains straight into a second event from a choice's own effects -- for
		# divergent card sequences that don't rejoin (a `goto` only jumps forward within one event).
		"start_event":
			start_event(effect["event"])
		# Creates the site+vein+claim directly (see _scripted_seed() below) rather than
		# spending calc through Sites.attempt_seed(), so this seed can't roll a failure.
		"scripted_seed":
			_scripted_seed(effect["district"], effect["tier"], effect["oreType"])
		# The only remaining path to Factions.join("collective") -- ContactCards.build_faction_card() suppresses the generic Join button for that faction.
		"join_faction":
			Factions.join(effect["faction"])
		"grant_recipe":
			Lab.grant_recipe(effect["recipe"])
		# Steps by ideal index, or every hidden step of a rung.
		"grant_recipe_steps":
			var steps: Array = effect["steps"] if effect.has("steps") else Lab.rung_steps(effect["recipe"], effect["rung"])
			Lab.grant_steps(effect["recipe"], steps, effect["specificity"])
		# A consolation (collision fallback) result carries a line to show.
		"grant_recipe_rung":
			var granted: Dictionary = RecipeKnowledge.grant_rung(effect["recipe"], effect["rung"], effect.get("specificity", "exact"), effect.get("source", ""))
			if granted.has("line"):
				Notify.push(granted["line"])
		# Pauses the event at the bench (LessonSession) until a run reaches rank.
		"start_lesson_session":
			var opened: Dictionary = LessonSession.start(effect["recipe"], int(effect["rank"]), effect.get("hintRung", ""), effect.get("lines", {}))
			if not opened["ok"]:
				push_error("Events: start_lesson_session refused: %s" % opened["reason"])
		# The site was already created at roll time (Collective.maybe_trigger_hakim_intel())
		# -- this just queues its discover map event. Runs post on_complete, so
		# _event_site_id() falls back to advance()'s explicitly-threaded context rather than live event state.
		"reveal_site":
			_reveal_site(_event_site_id(effect, context))
		"set_hakim_intel_day":
			GameState.state["collective"]["hakimIntelLastDay"] = GameState.state["world"]["day"]


# Adds when both the existing and incoming values are numeric (e.g. player.cash),
# otherwise assigns outright (e.g. contacts.james.unlocked).
static func _apply_add(path: String, value: Variant) -> void:
	var current: Variant = GameState.read_path(path)
	var new_value: Variant
	if _is_number(current) and _is_number(value):
		new_value = current + value
	else:
		new_value = value
	_set_path(path, new_value)


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


static func _set_path(path: String, value: Variant) -> void:
	var parts: PackedStringArray = path.split(".")
	var current: Dictionary = GameState.state
	for i in range(parts.size() - 1):
		current = current[parts[i]]
	current[parts[parts.size() - 1]] = value


# Shared by _grant_vein_with_site()/_scripted_seed(): fabricates and claims a site with no prospecting roll, appending to state.world.sites.
static func _append_claimed_site(district: String, tier: String, ore_type: String, bonuses: Array) -> Dictionary:
	var site: Dictionary = {
		"id": Sites.make_site_id(),
		"district": district,
		"tier": tier,
		"oreType": ore_type,
		"bonuses": bonuses,
		"discoveredDay": GameState.state["world"]["day"],
		"claimed": true,
		"factionVein": null,
		"hasNaturalVein": false,
		"slotIndex": Sites.next_slot_index(district),
	}
	GameState.state["world"]["sites"].append(site)
	return site


# A granted vein needs a matching claimed site on state.world.sites, or the Map
# tab shows it with no site backing it. Tier/oreType/bonuses are derived from
# the vein template's own hospitability fields, so they stay in sync by construction.
static func _grant_vein_with_site(vein_template: Dictionary) -> String:
	var hospitability: Dictionary = vein_template.get("hospitability", { "tier": "fair", "bonuses": [] })
	var day: int = GameState.state["world"]["day"]

	var site: Dictionary = _append_claimed_site(vein_template["district"], hospitability["tier"], vein_template["oreType"], hospitability["bonuses"])

	var vein: Dictionary = GameState.deep_copy(vein_template)
	vein["id"] = Cultivating.make_vein_id()
	vein["claimedOnDay"] = day
	vein["siteId"] = site["id"]
	vein["rampantDays"] = 0
	vein["guardKit"] = {}
	GameState.state["player"]["veins"].append(vein)
	return vein["id"]


# A guaranteed, scripted seed -- unlike _grant_vein_with_site() (copies a static
# template), this fabricates a fresh site at an explicit district/tier/oreType
# and claims it exactly as a successful Sites.attempt_seed() would, ignoring
# the district's siteCap (which only governs prospecting discovery).
static func _scripted_seed(district: String, tier: String, ore_type: String) -> void:
	var site: Dictionary = _append_claimed_site(district, tier, ore_type, [])

	var hospitability := { "tier": tier, "bonuses": [] }
	var vein := Cultivating.make_vein(ore_type, GameData.VEIN_GROWTH["seedGrowth"], district, site["id"], hospitability)
	GameState.state["player"]["veins"].append(vein)
	MapEvents.queue_seed_claim(district, vein["id"], "player")
	MapEvents.queue_join_line(district, vein["id"], "player")


# Forced, always-successful cultivate on the vein the home-raid debrief granted,
# at no block cost. No vein id exists in static JSON (created at runtime), so
# this looks up "the Whitechapel time vein" directly -- safe since a fresh
# playthrough has exactly one, and this fires only once, right after that debrief.
static func _tutorial_cultivate() -> void:
	var vein = _find_tutorial_cultivation_vein()
	if vein == null:
		return

	var skill: int = GameState.state["player"]["cultivatingSkill"]
	var vein_ceiling: int = Cultivating.ceiling(vein)
	var gain: int = Cultivating.cultivate_gain(skill, vein["growth"], vein_ceiling)
	vein["growth"] = clampi(vein["growth"] + gain, 0, vein_ceiling)


static func _find_tutorial_cultivation_vein() -> Variant:
	for vein in GameState.state["player"]["veins"]:
		if vein["district"] == "whitechapel" and vein["oreType"] == "time":
			return vein
	return null


# A raid's site_id is runtime-generated, never hardcoded in event JSON --
# Raiding.begin_raid() passes it via start_event()'s context instead. A live
# choice-card effect reads GameState.state["event"].context directly; an
# on_complete effect (state.event already null by then) falls back to the explicitly-threaded fallback_context.
static func _live_event_context() -> Dictionary:
	var event_state: Variant = GameState.state.get("event")
	return event_state.get("context", {}) if event_state != null else {}


static func _event_site_id(effect: Dictionary, fallback_context: Dictionary = {}) -> String:
	if effect.has("site_id"):
		return effect["site_id"]
	var event_state: Variant = GameState.state.get("event")
	if event_state != null:
		var from_live_context: String = event_state.get("context", {}).get("site_id", "")
		if from_live_context != "":
			return from_live_context
	return fallback_context.get("site_id", "")


# buy_faction_vein's helper: resolves a site's current factionVein id from
# effect["siteIdStatePath"] and reuses VeinTrade.buy_from_faction() at its
# normal quote() price. A silent no-op if the site or its faction vein is
# already gone (e.g. bought from the Map screen before this event ran).
static func _buy_faction_vein(effect: Dictionary) -> void:
	var site: Variant = Sites.find_site(_state_path_site_id(effect))
	if site == null or site["factionVein"] == null:
		return
	VeinTrade.buy_from_faction(site["factionVein"]["id"], effect["faction"])


# sell_ore_at_market's helper: removes qty (effect["qty"], else the event
# context's effect["qtyContextKey"]) of effect["type"] ore from the player
# (capped at what they hold) and pays Market.quote() x that qty -- a
# counterparty-free sale: no faction wallet, cut, mugging or relation.
static func _sell_ore_at_market(effect: Dictionary, context: Dictionary) -> void:
	var ore_type: String = effect["type"]
	var wanted: int = int(effect["qty"]) if effect.has("qty") else int(context.get(effect.get("qtyContextKey", ""), 0))
	var ore: Dictionary = GameState.state["player"]["orichalchum"]
	var qty: int = mini(wanted, int(ore.get(ore_type, 0)))
	if qty <= 0:
		return
	var earned: int = Market.line_total("ore", Market.quote("ore", ore_type), qty)
	ore[ore_type] -= qty
	Market.record_supply("ore", ore_type, qty, "player")
	GameState.state["player"]["cash"] += earned
	Bank.record(earned, effect.get("label", "Ore sale"))


# claim_faction_vein/buy_faction_vein's site: siteIdStatePath directly, or the
# site holding the faction vein veinIdStatePath names ("" once no site does).
static func _state_path_site_id(effect: Dictionary) -> String:
	if effect.has("siteIdStatePath"):
		var site_id: Variant = GameState.read_path(effect["siteIdStatePath"])
		return site_id if site_id != null else ""
	var vein_id: Variant = GameState.read_path(effect["veinIdStatePath"])
	for site in GameState.state["world"]["sites"]:
		if site["factionVein"] != null and site["factionVein"]["id"] == vein_id:
			return site["id"]
	return ""


# The site was already appended to state.world.sites at roll time -- this just
# queues its discover map event, same as Sites._create_site() does for a fresh
# prospect. No-op if the site is already gone.
static func _reveal_site(site_id: String) -> void:
	var site: Variant = Sites.find_site(site_id)
	if site == null:
		return
	MapEvents.queue_discover(site["district"], site_id)


# Mirrors _event_site_id(): the raid-assist ally list is only known at
# Raid-button-press time, so it's carried through start_event()'s context rather than baked into the authored card's JSON.
static func _event_ally_ids(effect: Dictionary) -> Array:
	if effect.has("ally_ids"):
		return effect["ally_ids"]
	var event_state: Variant = GameState.state.get("event")
	if event_state == null:
		return []
	return event_state.get("context", {}).get("ally_ids", [])


# "caught" drives loot_raid_vein's relation hit: derived from the live alert
# level (alert_caught()), or vein_raid's hand-set flags.raidCaught, whose clean
# and caught paths share one claim/loot card.
static func _event_caught(effect: Dictionary) -> bool:
	if effect.has("caught"):
		return effect["caught"]
	return alert_caught() or GameState.state["flags"].get("raidCaught", false)


# A stockpile raid's faction id, from the effect or the live event context.
static func _event_faction_id(effect: Dictionary) -> String:
	if effect.has("faction_id"):
		return effect["faction_id"]
	var event_state: Variant = GameState.state.get("event")
	if event_state == null:
		return ""
	return event_state.get("context", {}).get("faction_id", "")


# The running event's context district (an ambush's), else the player's
# current district.
static func _event_district() -> String:
	var event_state: Variant = GameState.state.get("event")
	var district: String = "" if event_state == null else str(event_state.get("context", {}).get("district", ""))
	return district if district != "" else str(GameState.state["world"]["currentDistrict"])


# A caught stockpile raid's fight: one enemy per stockpile guard, at the
# stockpileRaid valueTier; template from the card, else stockpileRaid.guardTemplate.
static func _start_stockpile_raid_combat(effect: Dictionary) -> void:
	var faction_id := _event_faction_id(effect)
	if not GameState.state["factions"].has(faction_id):
		return
	var cfg: Dictionary = GameData.STOCKPILE_RAID
	var guards_down: int = int(_live_event_context().get("guardsDown", 0))
	var guards: int = FactionSim.stockpile_guards(faction_id) - guards_down
	if guards_down > 0 and guards <= 0:
		return
	Combat.start_stockpile_raid(faction_id, int(cfg["valueTier"]), maxi(guards, 1), effect.get("template", cfg["guardTemplate"]), _event_ally_ids(effect), effect.get("situational", []))


# Branches into Combat.start_raid() with context "event_raid" (see combat.gd's
# exit_combat()) so a win resumes this same event. guards/template come from
# the authoring card, defaulting to a single guard on the catch-all template.
# guards "vein" sizes the squad to the vein's own guards (Cultivating.
# vein_guard_count); start_raid() floors it at 1, extras queue as reinforcements.
static func _start_raid_combat(effect: Dictionary) -> void:
	var site: Variant = Sites.find_site(_event_site_id(effect))
	if site == null or site["factionVein"] == null:
		return

	var vein: Dictionary = site["factionVein"]
	var fight := fight_setup(effect, _running_fight_presets())
	var guards_spec: Variant = fight.get("guards", 1)
	var guards: int = Cultivating.vein_guard_count(vein) if guards_spec is String and guards_spec == RAID_GUARDS_FROM_VEIN else int(guards_spec)
	var cfg: Dictionary = GameData.RAID_SECURITY["reinforcement"]
	guards -= int(_live_event_context().get("guardsDown", 0))
	if reinforcements_arrived():
		guards += int(cfg["guards"])
	if guards <= 0:
		return
	var wave := 0
	if reinforcements_pending():
		wave = int(cfg["guards"])
		GameState.state["event"]["reinforce"]["arrived"] = true
	var situational: Array = fight.get("situational", []) + _ward_fight_start()
	Combat.start_raid(vein["id"], Cultivating.combined_magnitude(vein), guards, fight.get("template", ""), Combat.CONTEXT_EVENT_RAID, _event_ally_ids(effect), situational, int(fight.get("waves", 0)), wave)


# A raid fight op's setup (R§3.7b Fight presets): its `preset` from `presets`
# (the event's fightPresets), with the op's guards / template / waves
# replacing the preset's and its situational appended after the preset's.
# An op with no preset is its own setup.
static func fight_setup(effect: Dictionary, presets: Dictionary) -> Dictionary:
	if not effect.has("preset"):
		return effect
	var fight: Dictionary = presets.get(effect["preset"], {}).duplicate(true)
	for key in FIGHT_OVERRIDE_KEYS:
		if effect.has(key):
			fight[key] = effect[key]
	fight["situational"] = fight.get("situational", []) + effect.get("situational", [])
	return fight


static func _running_fight_presets() -> Dictionary:
	if GameState.state.get("event") == null:
		return {}
	return _event_def().get("fightPresets", {})


# Takes `count` (default 1) guards out of the live raid event's later
# start_raid_combat; at zero guards left that op starts no fight.
static func _reduce_raid_guards(effect: Dictionary) -> void:
	add_raid_guards_down(int(effect.get("count", 1)))


# Adds `count` to the live event's guardsDown (R§3.7b Guard carry-over):
# the reduce_raid_guards op, and Combat.exit_combat() for a won raid fight.
static func add_raid_guards_down(count: int) -> void:
	var event_state: Variant = GameState.state.get("event")
	if event_state == null or count <= 0:
		return
	var context: Dictionary = event_state.get("context", {})
	context["guardsDown"] = int(context.get("guardsDown", 0)) + count
	event_state["context"] = context


# Seeds `faction_id` a faction vein on each site recorded in `objective_id`'s
# progress["matchedSiteIds"] (Sites.seed_faction_vein()). A site already
# claimed or vein-occupied is silently skipped. Currently inert for
# col_a1_des_sites, whose own evaluator reports/converts sites individually and
# never populates matchedSiteIds -- kept for any future objective using this "convert everything at once" shape.
static func _faction_seed_reported_sites(objective_id: String, faction_id: String) -> void:
	var progress: Dictionary = GameState.state["objectives"][objective_id]["progress"]
	var matched: Dictionary = progress.get("matchedSiteIds", {})
	for site_id in matched.values():
		var site: Variant = Sites.find_site(site_id)
		if site == null or site["claimed"] or site["factionVein"] != null:
			continue
		Sites.seed_faction_vein(site, faction_id)
