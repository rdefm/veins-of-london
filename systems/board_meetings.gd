class_name BoardMeetings
extends RefCounted

# Weekly board meetings (R§3.15, .scratch/board-meetings/spec.md §"Modules"
# → BoardMeetings): eligible ladder rungs become goal cards, a seeded agenda
# offers one per voice, the chosen card becomes the active goal (a generated
# objective definition evaluated by Objectives), and judge_week() pays the
# tier reached. Owns state.boardMeetings; static funcs only, never touches
# nodes.

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
		"history": [], "lastCompeting": 0,
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
			if _tier_rank(Objectives.tier_met(card["goal"])) >= _tier_rank("target"):
				_set_rung_status(ladder_id, rung_id, RUNG_SKIPPED)
				continue
			cards.append(card)
			break
	return cards


static func rung_status(ladder_id: String, rung_id: String) -> String:
	return str(_board()["rungs"].get(ladder_id, {}).get(rung_id, {}).get("status", ""))


static func _set_rung_status(ladder_id: String, rung_id: String, status: String) -> void:
	var rungs: Dictionary = _board()["rungs"]
	if not rungs.has(ladder_id):
		rungs[ladder_id] = {}
	rungs[ladder_id][rung_id] = { "status": status, "day": int(GameState.state["world"]["day"]) }


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
		"voice": card["voice"], "goal": GameState.deep_copy(card["goal"]),
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
		_set_rung_status(active["ladder"], active["rung"], RUNG_DONE)
	var entry := {
		"week": int(active["week"]), "voice": active["voice"], "ladder": active["ladder"],
		"rung": active["rung"], "result": result, "reward": paid, "skip": bool(active["skip"]),
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
	return str(GameData.BOARD_TEMPLATES.get(card.get("template", card["rung"]), {}).get("label", card["rung"]))


static func _tier_rank(tier: String) -> int:
	return Objectives.TIER_ORDER.find(tier) + 1
