class_name BoardMeetings
extends RefCounted

# Weekly board meetings (R§3.15, .scratch/board-meetings/spec.md §"Modules"
# → BoardMeetings): eligible ladder rungs become goal cards, a seeded agenda
# offers one per voice, the chosen card becomes the active goal (a generated
# objective definition evaluated by Objectives), and judge_week() pays the
# tier reached. Each Monday rollover opens a week whose meeting event
# (data/events/board_meeting*.json) starts once the player is free. Owns
# state.boardMeetings; static funcs only, never touches nodes.

const RESULT_MISSED := "missed"
const RUNG_DONE := "done"
const RUNG_SKIPPED := "skipped"
const REWARD_CASH := "cash"
const REWARD_ITEM := "item"
const REWARD_FACTION_RELATION := "factionRelation"
const REWARD_VIGNETTE := "vignette"


static func new_state() -> Dictionary:
	var weights := {}
	for voice_id in GameData.BOARD_VOICES:
		weights[voice_id] = float(GameData.BOARD_VOICES[voice_id]["baseWeight"])
	return {
		"enabled": false, "week": 0, "firstMeetingDay": 0,
		"agenda": [], "agendaWeek": 0, "active": null,
		"voiceWeights": weights, "rungs": {}, "spine": {},
		"history": [], "lastCompeting": 0, "pendingWeek": 0,
	}


static func _board() -> Dictionary:
	return GameState.state["boardMeetings"]


static func card_id(ladder_id: String, rung_id: String) -> String:
	return "%s:%s" % [ladder_id, rung_id]


# Per ladder (data order), the first rung not yet done/skipped whose premise
# holds and whose target tier isn't already met. A rung whose target is
# already met is recorded skipped (spec §"Modules"), so this writes state.
static func eligible_cards() -> Array:
	var cards: Array = []
	var active: Variant = _board()["active"]
	for ladder_id in GameData.BOARD_LADDERS:
		var ladder: Dictionary = GameData.BOARD_LADDERS[ladder_id]
		for rung in ladder["rungs"]:
			var rung_id: String = rung["id"]
			if rung_status(ladder_id, rung_id) != "":
				continue
			if active != null and active["cardId"] == card_id(ladder_id, rung_id):
				continue
			if not Objectives.condition_met(rung["premise"]):
				continue
			var card := _build_card(ladder_id, ladder, rung)
			if card.is_empty():
				continue
			if _tier_rank(Objectives.tier_met(card["goal"])) >= _tier_rank("target"):
				_set_rung_status(ladder_id, rung_id, RUNG_SKIPPED, card["ore"])
				_complete_spine(rung.get("spine"))
				continue
			cards.append(card)
			break
	return cards


static func rung_status(ladder_id: String, rung_id: String) -> String:
	return str(_board()["rungs"].get(ladder_id, {}).get(rung_id, {}).get("status", ""))


static func _set_rung_status(ladder_id: String, rung_id: String, status: String, ore_type: String = "") -> void:
	var rungs: Dictionary = _board()["rungs"]
	if not rungs.has(ladder_id):
		rungs[ladder_id] = {}
	var entry := { "status": status, "day": int(GameState.state["world"]["day"]) }
	if ore_type != "":
		entry["ore"] = ore_type
	rungs[ladder_id][rung_id] = entry


# Act 2 spine beats (state.boardMeetings.spine: beat id -> "done"). A beat is
# done once its rung is; a beat with `requires` stays locked until that beat is.
static func spine_done(beat_id: String) -> bool:
	return str(_board()["spine"].get(beat_id, "")) == "done"


static func spine_unlocked(beat_id: String) -> bool:
	for beat in GameData.BOARD_SPINE.get("beats", []):
		if beat["id"] == beat_id:
			return not beat.has("requires") or spine_done(beat["requires"])
	return false


static func _complete_spine(beat_id: Variant) -> void:
	if beat_id != null and str(beat_id) != "":
		_board()["spine"][str(beat_id)] = "done"


# Resolves a goal's "$best" / "$other" ore placeholder to a real ore type:
# the producing ore where the player's share is highest (canonical order
# breaks ties); "$other" skips ores this ladder already used. "" when none.
static func _resolve_ore(placeholder: String, ladder_id: String) -> String:
	if not placeholder.begins_with("$"):
		return placeholder
	var used := {}
	for entry in _board()["rungs"].get(ladder_id, {}).values():
		if entry.has("ore"):
			used[entry["ore"]] = true
	var best := ""
	var best_share := -1.0
	for ore_type in Objectives.market_ores():
		if placeholder == "$other" and used.has(ore_type):
			continue
		var share := Shares.ore_share(Shares.PLAYER, ore_type)
		if share > best_share:
			best = ore_type
			best_share = share
	return best


# A plain-data card: everything the meeting and Rewind need to show and
# choose it again without re-deriving.
static func _build_card(ladder_id: String, ladder: Dictionary, rung: Dictionary) -> Dictionary:
	var rung_id: String = rung["id"]
	var id := card_id(ladder_id, rung_id)
	var goal := {
		"id": "board_%s" % id, "type": rung["goal"]["type"],
		"params": GameState.deep_copy(rung["goal"].get("params", {})),
		"tiers": GameState.deep_copy(rung["tiers"]),
	}
	var ore_type := ""
	if goal["params"].has("oreType"):
		ore_type = _resolve_ore(str(goal["params"]["oreType"]), ladder_id)
		if ore_type == "":
			return {}
		goal["params"]["oreType"] = ore_type
	var preview := {}
	for tier in Objectives.TIER_ORDER:
		preview[tier] = reward_preview(rung["rewards"].get(tier, []))
	return {
		"id": id, "ladder": ladder_id, "rung": rung_id, "voice": ladder["voice"],
		"template": rung_id, "goal": goal,
		"rewards": GameState.deep_copy(rung["rewards"]), "preview": preview,
		"lengthWeeks": int(rung.get("lengthWeeks", 1)),
		"pinned": bool(rung.get("pinned", false)),
		"spine": rung.get("spine"),
		"ore": ore_type,
	}


# The week's offered cards, built once per week and kept in state so Rewind
# restores exactly what was shown. Pinned card first, then a seeded weighted
# pick, one per distinct voice; fillVoice tops up an unfilled slot. Seed =
# world.rollSeed + week, so the same state and week give the same agenda.
static func agenda(week: int) -> Array:
	var board := _board()
	if not board["enabled"]:
		return []
	if int(board["agendaWeek"]) == week and not board["agenda"].is_empty():
		return board["agenda"]
	var size := int(GameData.BOARD_TUNING["agendaSize"])
	var picked: Array = []
	var used_voices := {}
	var pool: Array = []
	for card in eligible_cards():
		if card["pinned"] and picked.is_empty():
			picked.append(card)
			used_voices[card["voice"]] = true
		else:
			pool.append(card)
	var draw := 0
	while picked.size() < size:
		var by_voice := _cards_by_voice(pool, used_voices, week)
		if by_voice.is_empty():
			break
		var voice_id := _weighted_voice(by_voice.keys(), week, draw)
		var voice_cards: Array = by_voice[voice_id]
		var card: Dictionary = voice_cards[_seeded_index(voice_cards.size(), week, "card|%d" % draw)]
		picked.append(card)
		pool.erase(card)
		used_voices[voice_id] = true
		draw += 1
	var fill_voice: String = GameData.BOARD_TUNING["fillVoice"]
	for card in pool:
		if picked.size() >= size:
			break
		if card["voice"] == fill_voice:
			picked.append(card)
	board["agenda"] = picked
	board["agendaWeek"] = week
	EventBus.state_changed.emit()
	return picked


# Cards per voice not yet on the agenda; a voice with pitchRarity < 1 is in
# the pool this week only on a seeded roll under it.
static func _cards_by_voice(pool: Array, used_voices: Dictionary, week: int) -> Dictionary:
	var by_voice := {}
	for card in pool:
		var voice_id: String = card["voice"]
		if used_voices.has(voice_id):
			continue
		var rarity := float(GameData.BOARD_VOICES[voice_id]["pitchRarity"])
		if rarity < 1.0 and _seeded_unit(week, "rarity|%s" % voice_id) >= rarity:
			continue
		if not by_voice.has(voice_id):
			by_voice[voice_id] = []
		by_voice[voice_id].append(card)
	return by_voice


static func _weighted_voice(voice_ids: Array, week: int, draw: int) -> String:
	var weights: Dictionary = _board()["voiceWeights"]
	var total := 0.0
	for voice_id in voice_ids:
		total += float(weights.get(voice_id, 0.0))
	var roll := _seeded_unit(week, "voice|%d" % draw) * total
	for voice_id in voice_ids:
		roll -= float(weights.get(voice_id, 0.0))
		if roll < 0.0:
			return voice_id
	return voice_ids[voice_ids.size() - 1]


static func _seeded_unit(week: int, salt: String) -> float:
	return Rng.stable_unit("%d|board|%d|%s" % [int(GameState.state["world"]["rollSeed"]), week, salt])


static func _seeded_index(count: int, week: int, salt: String) -> int:
	return mini(int(_seeded_unit(week, salt) * count), count - 1)


static func _agenda_card(id: String) -> Variant:
	for card in _board()["agenda"]:
		if card["id"] == id:
			return card
	return null


# Takes an agenda card as the active goal: the pitcher gains warmth, every
# other offered voice's weight is bumped, the pitcher's resets to base.
static func choose(id: String) -> Dictionary:
	var result := _take(id, false)
	if result["ok"]:
		var voice: Dictionary = GameData.BOARD_VOICES[result["card"]["voice"]]
		Contacts.award_relation(voice["contactId"], int(voice["warmth"]))
	return result


# The meeting's exit: Archie's offered card (his pinned card if he holds
# one, else his first offered) becomes the goal, flagged as a skip. No
# warmth — nobody was picked.
static func skip() -> Dictionary:
	var skip_voice: String = GameData.BOARD_TUNING["skipVoice"]
	var chosen: Variant = null
	for card in _board()["agenda"]:
		if card["voice"] != skip_voice:
			continue
		if card["pinned"]:
			chosen = card
			break
		if chosen == null:
			chosen = card
	if chosen == null:
		return { "ok": false, "reason": "%s has no card on the agenda." % GameData.BOARD_VOICES[skip_voice]["name"] }
	return _take(chosen["id"], true)


static func _take(id: String, is_skip: bool) -> Dictionary:
	var board := _board()
	if board["active"] != null:
		return { "ok": false, "reason": "A goal is already set this week." }
	var card: Variant = _agenda_card(id)
	if card == null:
		return { "ok": false, "reason": "That card isn't on the agenda." }
	board["active"] = {
		"cardId": card["id"], "ladder": card["ladder"], "rung": card["rung"],
		"template": card["template"],
		"voice": card["voice"], "ore": card.get("ore", ""), "goal": GameState.deep_copy(card["goal"]),
		"rewards": GameState.deep_copy(card["rewards"]),
		"lengthWeeks": card["lengthWeeks"], "week": int(board["week"]),
		"chosenDay": int(GameState.state["world"]["day"]),
		"baseline": {}, "progress": {}, "lockedTier": Objectives.TIER_NONE,
		"skip": is_skip,
	}
	var weights: Dictionary = board["voiceWeights"]
	var unpicked := {}
	for offered in board["agenda"]:
		if offered["voice"] != card["voice"]:
			unpicked[offered["voice"]] = true
	for voice_id in unpicked:
		weights[voice_id] = float(weights.get(voice_id, 0.0)) + float(GameData.BOARD_VOICES[voice_id]["unpickedBump"])
	weights[card["voice"]] = float(GameData.BOARD_VOICES[card["voice"]]["baseWeight"])
	_lock_stretch(board["active"])
	EventBus.state_changed.emit()
	return { "ok": true, "card": card }


# Called at the action boundaries Objectives.refresh() runs on: locks the
# stretch tier the moment it's met, so a later dip can't take it away.
static func note_progress() -> void:
	var active: Variant = GameState.state.get("boardMeetings", {}).get("active")
	if active != null:
		_lock_stretch(active)


static func _lock_stretch(active: Dictionary) -> void:
	if active["lockedTier"] == "stretch":
		return
	if Objectives.tier_met(active["goal"], active["progress"]) == "stretch":
		active["lockedTier"] = "stretch"


# The active goal's tier now: the best of the locked tier and the tier met
# this moment, or TIER_NONE with no active goal.
static func current_tier() -> String:
	var active: Variant = _board()["active"]
	if active == null:
		return Objectives.TIER_NONE
	var now := Objectives.tier_met(active["goal"], active["progress"])
	return now if _tier_rank(now) > _tier_rank(active["lockedTier"]) else str(active["lockedTier"])


# Monday judgement: resolves the active goal to missed/base/target/stretch,
# pays that tier's rewards (missed pays nothing, costs nothing), appends a
# capped history entry, marks the rung done at target or better, clears the
# goal. Returns the history entry, or {} with no active goal.
static func judge_week() -> Dictionary:
	var board := _board()
	var active: Variant = board["active"]
	if active == null:
		return {}
	note_progress()
	var tier := current_tier()
	var result := RESULT_MISSED if tier == Objectives.TIER_NONE else tier
	var paid: Array = []
	if result != RESULT_MISSED:
		paid = GameState.deep_copy(active["rewards"].get(result, []))
		for reward in paid:
			_pay(reward)
	if _tier_rank(tier) >= _tier_rank("target"):
		_set_rung_status(active["ladder"], active["rung"], RUNG_DONE, str(active.get("ore", "")))
		_complete_spine(_rung_spine(active["ladder"], active["rung"]))
	var entry := {
		"week": int(active["week"]), "voice": active["voice"], "ladder": active["ladder"],
		"rung": active["rung"], "ore": active.get("ore", ""), "result": result, "reward": paid, "skip": bool(active["skip"]),
	}
	var history: Array = board["history"]
	history.append(entry)
	var cap := int(GameData.BOARD_TUNING["historyLength"])
	while history.size() > cap:
		history.pop_front()
	board["active"] = null
	EventBus.state_changed.emit()
	return entry


static func _pay(reward: Dictionary) -> void:
	match reward["kind"]:
		REWARD_CASH:
			var amount := int(reward["amount"])
			GameState.state["player"]["cash"] += amount
			Bank.record(amount, "Board goal")
		REWARD_ITEM:
			assert(GameData.BOARD_TUNING["rewardItems"].has(reward["id"]), "board reward item '%s' not allowed" % reward["id"])
			Crafting.inventory_add(reward["id"], int(reward.get("tier", 1)), int(reward.get("qty", 1)))
		REWARD_FACTION_RELATION:
			Factions.adjust_player_relation(reward["factionId"], int(reward["amount"]))
		REWARD_VIGNETTE:
			# Content hook: the vignette id rides in the history entry's
			# reward list for the Minutes to play.
			pass


# One line per tier, generated from the same reward list judge_week() pays.
static func reward_preview(rewards: Array) -> String:
	var parts: PackedStringArray = []
	for reward in rewards:
		match reward["kind"]:
			REWARD_CASH:
				parts.append("£%d" % int(reward["amount"]))
			REWARD_ITEM:
				parts.append("%d× %s" % [int(reward.get("qty", 1)), GameData.RECIPES[reward["id"]]["name"]])
			REWARD_FACTION_RELATION:
				parts.append("+%d %s relation" % [int(reward["amount"]), GameData.FACTIONS[reward["factionId"]]["name"]])
			REWARD_VIGNETTE:
				parts.append("A story")
	return ", ".join(parts)


# An agenda card's or the active goal's label (both carry template + rung).
static func card_label(card: Dictionary) -> String:
	var label := str(GameData.BOARD_TEMPLATES.get(card.get("template", card["rung"]), {}).get("label", card["rung"]))
	return _with_ore(label, str(card.get("ore", "")))


static func _rung_spine(ladder_id: String, rung_id: String) -> Variant:
	for rung in GameData.BOARD_LADDERS.get(ladder_id, {}).get("rungs", []):
		if rung["id"] == rung_id:
			return rung.get("spine")
	return null


# Fills {ore} with the ore's display name; text with no ore is unchanged.
static func _with_ore(text: String, ore_type: String) -> String:
	if ore_type == "":
		return text
	return text.replace("{ore}", str(GameData.ORE_TYPES[ore_type]["name"]))


static func _tier_rank(tier: String) -> int:
	return Objectives.TIER_ORDER.find(tier) + 1


# Rollover ⑧i, after ⑥.4 contract renewal and ⑥.4b payday so a goal is
# judged on the week's real books (spec §"Modules" → Rollover). Act 1's
# closing flag (meeting.enableFlag) enables meetings; every rollover into a
# Monday from then on opens a week, so the first Monday on or after the
# flag is Week 1.
static func monday_rollover() -> void:
	var board := _board()
	if not board["enabled"]:
		if not GameState.state["flags"].get(GameData.BOARD_MEETING["enableFlag"], false):
			return
		board["enabled"] = true
	if Calendar.is_monday(int(GameState.state["world"]["day"])):
		open_week()


# Judges the active goal, advances the meeting count, builds the new week's
# agenda and leaves its meeting pending for maybe_start_meeting().
static func open_week() -> void:
	var board := _board()
	judge_week()
	board["week"] = int(board["week"]) + 1
	if int(board["firstMeetingDay"]) == 0:
		board["firstMeetingDay"] = int(GameState.state["world"]["day"])
	agenda(int(board["week"]))
	board["pendingWeek"] = int(board["week"])
	EventBus.state_changed.emit()


static func meeting_pending() -> bool:
	return int(GameState.state.get("boardMeetings", {}).get("pendingWeek", 0)) > 0


# Starts the pending meeting once the player is free: no event or fight
# live (a modal flow parks it via start_or_defer). Week 1 plays the scripted
# variant. The event has no `at`, so it spends no time block and needs no
# travel. True when the meeting started (or was parked behind a modal).
static func maybe_start_meeting() -> bool:
	if not meeting_pending():
		return false
	if GameState.state["event"] != null or GameState.state["combat"]["active"]:
		return false
	var board := _board()
	var week := int(board["pendingWeek"])
	board["pendingWeek"] = 0
	var meeting: Dictionary = GameData.BOARD_MEETING
	var event_id: String = meeting["week1EventId"] if week == 1 else meeting["eventId"]
	Events.start_or_defer(event_id, meeting_context(week))
	return true


# The meeting event's context (R§3.9a "Context options"): minutes for last
# week, the agenda summary, and one hub option per agenda card whose label
# and result_text read that card's tokens (c<i>_pitcher, c<i>_label, ...).
# Plain data, so Rewind and save/load restore exactly what was offered.
static func meeting_context(week: int) -> Dictionary:
	var meeting: Dictionary = GameData.BOARD_MEETING
	var context := { "week": str(week), "minutes": minutes_line(week) }
	var options: Array = []
	var summaries: PackedStringArray = []
	var cards := agenda(week)
	for i in cards.size():
		var card: Dictionary = cards[i]
		var tokens := card_tokens(card)
		var prefix := "c%d_" % i
		for key in tokens:
			context[prefix + key] = tokens[key]
		summaries.append(String(meeting["agendaCard"]).format(tokens))
		options.append({
			"id": card["id"],
			"label": _prefixed(meeting["optionLabel"], prefix),
			"effects": [{ "op": "board_choose", "card": card["id"] }],
			"result_text": _prefixed(meeting["chosenText"], prefix),
			"goto": "aob",
		})
	context["agenda"] = options
	context["agendaText"] = meeting["agendaEmpty"] if summaries.is_empty() else String(meeting["agendaSeparator"]).join(summaries)
	return context


# A card's display tokens: pitcher, label, pitch, why (templates), tiers
# (each tier's threshold numbers) and reward (the per-tier previews).
static func card_tokens(card: Dictionary) -> Dictionary:
	var meeting: Dictionary = GameData.BOARD_MEETING
	var template: Dictionary = GameData.BOARD_TEMPLATES.get(card["template"], {})
	var numbers := {}
	for tier in Objectives.TIER_ORDER:
		var parts: PackedStringArray = []
		for value in (card["goal"]["tiers"][tier] as Dictionary).values():
			parts.append(_number(value))
		numbers[tier] = "/".join(parts)
	return {
		"pitcher": GameData.BOARD_VOICES[card["voice"]]["name"],
		"label": card_label(card),
		"pitch": _with_ore(str(template.get("pitch", "")), str(card.get("ore", ""))),
		"why": _with_ore(str(template.get("why", "")), str(card.get("ore", ""))),
		"tiers": String(meeting["tierFormat"]).format(numbers),
		"reward": String(meeting["rewardFormat"]).format(card["preview"]),
	}


# Minutes for the week before `week`: its history entry's pitcher, label and
# result, or meeting.minutesNone with no goal judged that week.
static func minutes_line(week: int) -> String:
	var meeting: Dictionary = GameData.BOARD_MEETING
	var history: Array = _board()["history"]
	if history.is_empty() or int(history.back()["week"]) != week - 1:
		return meeting["minutesNone"]
	var entry: Dictionary = history.back()
	var line := String(meeting["minutesFormat"]).format({
		"pitcher": GameData.BOARD_VOICES[entry["voice"]]["name"],
		"label": card_label(entry),
		"result": meeting["resultNames"][entry["result"]],
	})
	if entry["skip"]:
		line += String(meeting["minutesSkip"])
	return line


static func _prefixed(text: String, prefix: String) -> String:
	return text.replace("{", "{" + prefix)


static func _number(value: Variant) -> String:
	var number := float(value)
	return str(int(number)) if is_equal_approx(number, roundf(number)) else str(number)
