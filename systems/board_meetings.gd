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
const REWARD_CONTRACT := "contract"


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
			for alt in rung.get("altVoices", []):
				cards.append(_build_card(ladder_id, ladder, rung, str(alt["voice"]), str(alt["template"])))
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
static func _resolve_ore(placeholder: String, ladder_id: String, tally: String = "ore") -> String:
	if not placeholder.begins_with("$"):
		return placeholder
	var used := {}
	for entry in _board()["rungs"].get(ladder_id, {}).values():
		if entry.has("ore"):
			used[entry["ore"]] = true
	var best := ""
	var best_share := -1.0
	for ore_type in Objectives.market_ores(tally):
		if placeholder == "$other" and used.has(ore_type):
			continue
		var share := Shares.share(tally, Shares.PLAYER, ore_type)
		if share > best_share:
			best = ore_type
			best_share = share
	return best


# A plain-data card: everything the meeting and Rewind need to show and
# choose it again without re-deriving.
static func _build_card(ladder_id: String, ladder: Dictionary, rung: Dictionary, voice_id: String = "", template_id: String = "") -> Dictionary:
	var rung_id: String = rung["id"]
	var id := card_id(ladder_id, rung_id)
	var goal := {
		"id": "board_%s" % id, "type": rung["goal"]["type"],
		"params": GameState.deep_copy(rung["goal"].get("params", {})),
		"tiers": GameState.deep_copy(rung["tiers"]),
	}
	var ore_type := ""
	if goal["params"].has("oreType"):
		var tally := "craft" if goal["type"] == Objectives.TYPE_CRAFTING_SHARE_AT_LEAST else "ore"
		ore_type = _resolve_ore(str(goal["params"]["oreType"]), ladder_id, tally)
		if ore_type == "":
			return {}
		goal["params"]["oreType"] = ore_type
	var preview := {}
	for tier in Objectives.TIER_ORDER:
		preview[tier] = reward_preview(rung["rewards"].get(tier, []))
	return {
		"id": id, "ladder": ladder_id, "rung": rung_id, "voice": voice_id if voice_id != "" else ladder["voice"],
		"template": template_id if template_id != "" else rung_id, "goal": goal,
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
			_drop_card_id(pool, card["id"])
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
		_drop_card_id(pool, card["id"])
		used_voices[voice_id] = true
		draw += 1
	var fill_voice: String = GameData.BOARD_TUNING["fillVoice"]
	for card in pool:
		if picked.size() >= size:
			break
		if card["voice"] == fill_voice and not _has_card_id(picked, card["id"]):
			picked.append(card)
	_mark_competing(picked, week)
	board["agenda"] = picked
	board["agendaWeek"] = week
	EventBus.state_changed.emit()
	return picked


# A rung with several voice variants shares one card id; once one is offered
# the others leave the pool.
static func _drop_card_id(pool: Array, id: String) -> void:
	for i in range(pool.size() - 1, -1, -1):
		if pool[i]["id"] == id:
			pool.remove_at(i)


static func _has_card_id(cards: Array, id: String) -> bool:
	for card in cards:
		if card["id"] == id:
			return true
	return false


# Flavour beat only: two offered cards wanting the same ore get a
# "competesWith" link to each other. Never alters rewards or goals. Allowed
# when competingCapWeeks have passed since lastCompeting and a seeded roll
# under competingChance succeeds.
static func _mark_competing(cards: Array, week: int) -> void:
	var board := _board()
	var last := int(board["lastCompeting"])
	if last > 0 and week - last < int(GameData.BOARD_TUNING["competingCapWeeks"]):
		return
	if _seeded_unit(week, "competing") >= float(GameData.BOARD_TUNING["competingChance"]):
		return
	for i in cards.size():
		var ore_type: String = cards[i].get("ore", "")
		if ore_type == "":
			continue
		for j in range(i + 1, cards.size()):
			if cards[j].get("ore", "") == ore_type:
				cards[i]["competesWith"] = cards[j]["id"]
				cards[j]["competesWith"] = cards[i]["id"]
				board["lastCompeting"] = week
				return


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
		"baseline": {}, "progress": Objectives.initial_progress(str(card["goal"]["type"])), "lockedTier": Objectives.TIER_NONE,
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
		REWARD_CONTRACT:
			# Landmark deal: the authored recurring offer lands on BizBrief.
			Offers.create_offer(GameData.OFFER_TEMPLATES[reward["templateId"]], true)
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
			REWARD_CONTRACT:
				parts.append("Contract: %s" % GameData.OFFER_TEMPLATES[reward["templateId"]]["label"])
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


# Fills {ore} with the ore's display name and {calc} with its short slang
# ("time calc"); text with no ore is unchanged.
static func _with_ore(text: String, ore_type: String) -> String:
	if ore_type == "":
		return text
	return text.replace("{ore}", str(GameData.ORE_TYPES[ore_type]["name"])).replace("{calc}", "%s calc" % ore_type)


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


# The meeting event's context (R§3.9a "Context options", "Splice"): minutes
# for last week, then the debate as event-card lists the meeting event splices
# in order (R§3.15): `opener`, `slot<i>` per offered card (case, response,
# optional rebuttal), `clash`; an empty list adds nothing. All prose comes
# from the prose packs (R§3.15 "Prose packs"). Also the vote
# prompt and one hub option per card. Seeded by week and rollSeed, so Rewind
# shows the same scene.
static func meeting_context(week: int) -> Dictionary:
	var meeting: Dictionary = GameData.BOARD_MEETING
	var debate: Dictionary = meeting["debate"]
	var context := { "week": str(week), "minutes": minutes_line(week), "opener": [], "clash": [] }
	var options: Array = []
	var vote_lines: PackedStringArray = []
	var cards := agenda(week)
	if not cards.is_empty():
		var opener_voice: String = cards[0]["voice"]
		var opener := _pick_prose(_prose(GameData.BOARD_PROSE_DEBATE, "opener", { "voice": opener_voice }), week, "opener")
		context["opener"] = _prose_event_cards("opener", opener, {})
	for i in cards.size():
		var card: Dictionary = cards[i]
		var tokens := card_tokens(card)
		context["slot%d" % i] = _exchange_cards(card, i, week)
		vote_lines.append(String(debate["votePrompt"]["line"]).format(tokens))
		options.append({
			"id": card["id"],
			"label": String(meeting["optionLabel"]).format(tokens),
			"effects": [{ "op": "board_choose", "card": card["id"] }],
			"result_text": _result_text(card, i, week),
			"goto": "aob",
		})
	context["clash"] = _clash_cards(cards, week)
	context["agenda"] = options
	context["aob"] = aob_line(week)
	context["voteText"] = "%s\n\n%s" % [
		debate["votePrompt"]["lead"],
		meeting["agendaEmpty"] if vote_lines.is_empty() else String(debate["votePrompt"]["separator"]).join(vote_lines),
	]
	return context


# Prose pack lookups. `_prose` lists a pack's cards for a slot in file order,
# keeping those whose fields equal every entry of `filters` (voice, to, stance).
static func _prose(pack_id: String, slot: String, filters: Dictionary = {}) -> Array:
	var out: Array = []
	for prose in GameData.BOARD_PROSE.get(pack_id, {}).get("cards", []):
		if prose["slot"] != slot:
			continue
		var matches := true
		for field in filters:
			if str(prose.get(field, "")) != str(filters[field]):
				matches = false
		if matches:
			out.append(prose)
	return out


# The distinct values of `field` over `pool`, in first-seen order.
static func _prose_values(pool: Array, field: String) -> Array:
	var out: Array = []
	for prose in pool:
		if not out.has(prose[field]):
			out.append(prose[field])
	return out


static func _pick_prose(pool: Array, week: int, salt: String) -> Dictionary:
	return {} if pool.is_empty() else _pick(pool, week, salt)


# A prose card as speaker event cards keyed `key` (`key0`, `key1`... when the
# prose card holds several), text with `tokens` filled.
static func _prose_event_cards(key: String, prose: Dictionary, tokens: Dictionary) -> Array:
	var out: Array = []
	var lines: Array = prose.get("cards", [])
	for i in lines.size():
		var line: Dictionary = lines[i]
		out.append({
			"key": key if lines.size() == 1 else "%s%d" % [key, i],
			"type": "speaker", "label": null,
			"speaker": line["speaker"], "text": String(line["text"]).format(tokens),
		})
	return out


# The first line of a prose card, `tokens` filled; "" for no prose card.
static func _prose_text(prose: Dictionary, tokens: Dictionary) -> String:
	var lines: Array = prose.get("cards", [])
	return "" if lines.is_empty() else String(lines[0]["text"]).format(tokens)


# Slot i's event cards: the pitcher's case, then a response (a seeded other
# voice, a stance that voice has for the pitcher) and, after a `challenge`,
# the pitcher's rebuttal.
static func _exchange_cards(card: Dictionary, i: int, week: int) -> Array:
	var pitcher: String = card["voice"]
	var ore_name := str(GameData.ORE_TYPES[card["ore"]]["name"]) if str(card.get("ore", "")) != "" else "the ore"
	var line_tokens := { "label": card_label(card), "ore": ore_name }
	var case_prose := _case_prose(card)
	var out: Array = _prose_event_cards("case", case_prose, {})
	for j in out.size():
		out[j]["text"] = fill_prose(str(case_prose["cards"][j]["text"]), card)
	if out.is_empty():
		out.append({ "key": "case", "type": "speaker", "label": null, "speaker": GameData.BOARD_VOICES[pitcher]["name"], "text": "" })
	var replies := _prose(GameData.BOARD_PROSE_DEBATE, "reply", { "to": pitcher })
	var responders := _prose_values(replies, "voice")
	responders.erase(pitcher)
	if responders.is_empty():
		return out
	var responder: String = _pick(responders, week, "responder|%d" % i)
	var stances := _prose_values(_prose(GameData.BOARD_PROSE_DEBATE, "reply", { "to": pitcher, "voice": responder }), "stance")
	var stance: String = _pick(stances, week, "stance|%d" % i)
	var reply := _pick_prose(_prose(GameData.BOARD_PROSE_DEBATE, "reply", { "to": pitcher, "voice": responder, "stance": stance }), week, "response|%d" % i)
	out.append_array(_prose_event_cards("resp", reply, line_tokens))
	if stance == "challenge":
		var rebuttal := _pick_prose(_prose(GameData.BOARD_PROSE_DEBATE, "rebuttal", { "voice": pitcher }), week, "rebuttal|%d" % i)
		out.append_array(_prose_event_cards("reb", rebuttal, line_tokens))
	return out


# Once per meeting, on a seeded roll under clashChance: an exchange prose card
# for the first clashOrder voice pair that both have an offered card. Empty
# when the roll fails or no pair is offered.
static func _clash_cards(cards: Array, week: int) -> Array:
	var debate: Dictionary = GameData.BOARD_MEETING["debate"]
	if _seeded_unit(week, "clash") >= float(debate["clashChance"]):
		return []
	var offered := {}
	for card in cards:
		offered[card["voice"]] = true
	for pair in debate["clashOrder"]:
		var voices: PackedStringArray = String(pair).split("|")
		if not (offered.has(voices[0]) and offered.has(voices[1])):
			continue
		var exchanges := _prose(GameData.BOARD_PROSE_DEBATE, "clash", { "voice": voices[0], "to": voices[1] })
		return _prose_event_cards("clash", _pick_prose(exchanges, week, "clashLines"), {})
	return []


# A chosen option's result: the pitcher's pleased line, then a seeded other
# voice's concede line.
static func _result_text(card: Dictionary, i: int, week: int) -> String:
	var pitcher: String = card["voice"]
	var line_tokens := { "label": card_label(card) }
	var out: PackedStringArray = []
	var chosen := _pick_prose(_prose(GameData.BOARD_PROSE_DEBATE, "chosen", { "voice": pitcher }), week, "chosen|%d" % i)
	if not chosen.is_empty():
		out.append("%s: \"%s\"" % [GameData.BOARD_VOICES[pitcher]["name"], _prose_text(chosen, line_tokens)])
	var others := _prose_values(_prose(GameData.BOARD_PROSE_DEBATE, "concede"), "voice")
	others.erase(pitcher)
	if not others.is_empty():
		var conceder: String = _pick(others, week, "conceder|%d" % i)
		var concede := _pick_prose(_prose(GameData.BOARD_PROSE_DEBATE, "concede", { "voice": conceder }), week, "concede|%d" % i)
		if not concede.is_empty():
			out.append("%s: \"%s\"" % [GameData.BOARD_VOICES[conceder]["name"], _prose_text(concede, line_tokens)])
	return "\n\n".join(out)


static func _pick(list: Array, week: int, salt: String) -> Variant:
	return list[_seeded_index(list.size(), week, salt)]


# Closing aside: the competing line when two offered cards share an ore, else
# a seeded pool line that never repeats the previous week's pick.
static func aob_line(week: int) -> String:
	var aob: Dictionary = GameData.BOARD_MEETING["aob"]
	var lead: String = aob["lead"]
	for card in agenda(week):
		var rival: Variant = _agenda_card(str(card.get("competesWith", "")))
		if rival == null:
			continue
		var variants: Array = aob["competing"]
		return "%s %s" % [lead, String(variants[_seeded_index(variants.size(), week, "aobCompeting")]).format({
			"a": GameData.BOARD_VOICES[card["voice"]]["name"],
			"b": GameData.BOARD_VOICES[rival["voice"]]["name"],
			"ore": GameData.ORE_TYPES[card["ore"]]["name"],
		})]
	var lines: Array = aob["lines"]
	var index := _seeded_index(lines.size(), week, "aob")
	if week > 1 and index == _seeded_index(lines.size(), week - 1, "aob"):
		index = (index + 1) % lines.size()
	return "%s %s" % [lead, lines[index]]


# A card's display tokens: pitcher, label, case (the picked case prose, tokens
# filled), tiers (each tier's threshold numbers) and reward (the per-tier
# previews).
static func card_tokens(card: Dictionary) -> Dictionary:
	var votes: Dictionary = GameData.BOARD_MEETING["debate"]["votePrompt"]
	var numbers := {}
	for tier in Objectives.TIER_ORDER:
		var parts: PackedStringArray = []
		for value in (card["goal"]["tiers"][tier] as Dictionary).values():
			parts.append(_number(value))
		numbers[tier] = "/".join(parts)
	var case_lines: PackedStringArray = []
	for line in _case_prose(card).get("cards", []):
		case_lines.append(fill_prose(str(line["text"]), card))
	return {
		"pitcher": GameData.BOARD_VOICES[card["voice"]]["name"],
		"label": card_label(card),
		"case": "\n\n".join(case_lines),
		"tiers": String(votes["tierFormat"]).format(numbers),
		"reward": String(votes["rewardFormat"]).format(card["preview"]),
	}


# The card's case prose card: one of its template pack's `case` cards for the
# pitching voice, picked by a stable hash of the card id so Rewind shows the
# same line. {} when the pack has none.
static func _case_prose(card: Dictionary) -> Dictionary:
	var pool := _prose(str(card["template"]), "case", { "voice": card["voice"] })
	return {} if pool.is_empty() else pool[absi(str(card["id"]).hash()) % pool.size()]


# Prose text with {ore} and the live reserve / market-share tokens filled.
static func fill_prose(raw: String, card: Dictionary) -> String:
	var text := _with_ore(raw, str(card.get("ore", "")))
	if text.contains("{expenses}") or text.contains("{float}") or text.contains("{weeks}"):
		var expenses := BusinessStats.weekly_expenses()
		var cash := int(GameState.state["business"]["float"])
		text = text.format({
			"expenses": "£%d" % expenses,
			"float": "£%d" % cash,
			"weeks": _number(snappedf(float(cash) / float(maxi(expenses, 1)), 0.1)),
		})
	if text.contains("{share}") or text.contains("{rival}") or text.contains("{contested}"):
		var tally := "craft" if card["goal"]["type"] == Objectives.TYPE_CRAFTING_SHARE_AT_LEAST else "ore"
		text = text.format(_share_prose_tokens(str(card.get("ore", "")), tally))
	return text


# Live market-share tokens: {share} the player's % of the card's ore, {rival}
# its largest other producer, {contested} the ores two or more rival
# producers each supply.
static func _share_prose_tokens(ore_type: String, tally: String = "ore") -> Dictionary:
	var totals := Shares.window_totals(tally)
	var rival := ""
	var rival_qty := 0
	for producer in totals:
		var qty := int((totals[producer] as Dictionary).get(ore_type, 0))
		if producer != Shares.PLAYER and qty > rival_qty:
			rival = str(producer)
			rival_qty = qty
	var contested: PackedStringArray = []
	for ore in GameData.CANONICAL_ORE_TYPES:
		var suppliers := 0
		for producer in totals:
			if producer != Shares.PLAYER and int((totals[producer] as Dictionary).get(ore, 0)) > 0:
				suppliers += 1
		if suppliers >= 2:
			contested.append(str(GameData.ORE_TYPES[ore]["name"]))
	return {
		"share": str(int(roundf(Shares.share(tally, Shares.PLAYER, ore_type) * 100.0))),
		"rival": "the independents" if rival == Shares.INDEPENDENTS or rival == "" else str(GameData.FACTIONS[rival]["name"]),
		"contested": "nothing yet" if contested.is_empty() else " and ".join(contested) if contested.size() < 3 else ", ".join(contested),
	}


# Minutes for the week before `week`: a reaction from the pitcher (or Archie's
# for a skipped meeting) to that history entry's result, or
# meeting.minutesNone with no goal judged that week.
static func minutes_line(week: int) -> String:
	var meeting: Dictionary = GameData.BOARD_MEETING
	var history: Array = _board()["history"]
	if history.is_empty() or int(history.back()["week"]) != week - 1:
		return meeting["minutesNone"]
	var entry: Dictionary = history.back()
	var minutes: Dictionary = meeting["minutes"]
	var group: String = minutes["groups"][entry["result"]]
	var variants: Array = minutes["skipped"][group] if entry["skip"] else minutes["reactions"][entry["voice"]][group]
	return String(variants[int(entry["week"]) % variants.size()]).format({
		"label": card_label(entry),
		"tier": meeting["resultNames"][entry["result"]],
	})


static func _number(value: Variant) -> String:
	var number := float(value)
	return str(int(number)) if is_equal_approx(number, roundf(number)) else str(number)
