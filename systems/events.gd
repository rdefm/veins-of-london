class_name Events
extends RefCounted

# Event runner per R§3.9 (event rewind) and M0-T13's card/event schema.
# Static funcs only. Cards: { type, label, speaker, text }. Events:
# { id, cards, on_complete: [effect] }. state.event holds the runtime
# progress: { eventId, cardIndex, snapshots }.


static func start_event(event_id: String) -> void:
	GameState.state["event"] = { "eventId": event_id, "cardIndex": 0, "snapshots": [] }
	Nav.go_to("event")


static func _event_def() -> Dictionary:
	var event_state: Dictionary = GameState.state["event"]
	return GameData.EVENTS[event_state["eventId"]]


# All cards revealed so far (index 0..cardIndex inclusive) — the event
# screen renders this whole list so new cards push older ones up rather
# than replacing them.
static func revealed_cards() -> Array:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	return cards.slice(0, event_state["cardIndex"] + 1)


static func is_last_card() -> bool:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	return event_state["cardIndex"] >= cards.size() - 1


static func can_rewind() -> bool:
	var event_state = GameState.state["event"]
	if event_state == null or event_state["snapshots"].is_empty():
		return false
	var player: Dictionary = GameState.state["player"]
	return player["inventory"]["rewind"] > 0 or _find_equipped_rewind_device_with_charge() != null


# Continue: snapshots full state, then either reveals the next card or
# (on the last card) runs on_complete and clears state.event.
#
# state.event.snapshots lives INSIDE the tree this deep-copies, so it must
# be emptied before the copy — otherwise every snapshot embeds a full copy
# of the stack as it stood a moment ago, which itself embeds every
# snapshot before THAT, and so on. That's not a big constant; it's
# genuine exponential blowup (each card roughly doubled the previous
# card's advance() time in profiling — card 16 of a 24-card event took 17
# seconds), and it eventually crashes the run out of memory. Restoring
# the emptied field afterward keeps the live stack (and everything
# pushed onto it) exactly as before; only what gets baked into `snap`
# changes. rewind() below relies on this: it no longer trusts a popped
# snapshot's own (now always-empty) `event.snapshots` field, and instead
# carries the real, already-trimmed live stack forward explicitly.
static func advance() -> void:
	var event_state: Dictionary = GameState.state["event"]
	var stack: Array = event_state["snapshots"]
	event_state["snapshots"] = []
	var snap: Dictionary = GameState.deep_copy(GameState.state)
	event_state["snapshots"] = stack
	Snapshots.push("event", stack, snap)

	if is_last_card():
		var on_complete: Array = _event_def().get("on_complete", [])
		GameState.state["event"] = null
		apply_effects(on_complete)
		SaveManager.autosave()  # R§6: autosave on event completion
	else:
		event_state["cardIndex"] += 1
		EventBus.state_changed.emit()


static func rewind() -> Dictionary:
	if not can_rewind():
		return { "ok": false, "reason": "No rewind available." }

	var event_state: Dictionary = GameState.state["event"]
	var player: Dictionary = GameState.state["player"]
	var has_consumable: bool = player["inventory"]["rewind"] > 0
	var device = _find_equipped_rewind_device_with_charge()
	var device_id = device["id"] if device != null else null

	var stack: Array = event_state["snapshots"]
	var snap: Dictionary = Snapshots.pop_newest(stack)
	GameState.state = snap
	# snap's own event.snapshots is always [] (see advance()) — carry the
	# real, already-popped live stack forward instead of trusting that.
	GameState.state["event"]["snapshots"] = stack

	if has_consumable:
		GameState.state["player"]["inventory"]["rewind"] -= 1
	else:
		Devices.activate(device_id)

	Notify.push("⟲ Time unspools. The moment resets. Only you remember.")
	EventBus.state_changed.emit()
	return { "ok": true }


static func _find_equipped_rewind_device_with_charge() -> Variant:
	var player: Dictionary = GameState.state["player"]
	var device_id = player["equipment"]["device"]
	if device_id == null:
		return null
	for d in player["devicesCompleted"]:
		if d["id"] == device_id:
			var dt: Dictionary = GameData.DEVICES[d["type"]]
			if dt["effect"] == "rewind" and d["chargesUsedToday"] < d["chargesPerDay"]:
				return d
			return null
	return null


# ── effect ops ──────────────────────────────────────────────────────────

static func apply_effects(effects: Array) -> void:
	for effect in effects:
		_apply_one(effect)
	EventBus.state_changed.emit()


static func _apply_one(effect: Dictionary) -> void:
	match effect["op"]:
		"set_flag":
			GameState.state["flags"][effect["flag"]] = effect["value"]
		"add":
			_apply_add(effect["path"], effect["value"])
		"add_ore":
			var ore: Dictionary = GameState.state["player"]["orichalchum"]
			ore[effect["type"]] = ore.get(effect["type"], 0) + effect["qty"]
		"add_item":
			var inventory: Dictionary = GameState.state["player"]["inventory"]
			inventory[effect["item"]] = inventory.get(effect["item"], 0) + effect["qty"]
		"relation":
			Contacts.award_relation(effect["contact"], effect["value"])
		"grant_vein":
			_grant_vein(effect["vein"])
		"set_screen":
			Nav.go_to(effect["screen"])
		"notify":
			Notify.push(effect["text"])
		"set_stage":
			GameState.state["flags"]["tutorialStage"] = effect["value"]
		"start_home_raid_combat":
			Combat.start_home_raid_combat()


# Generic path+value combine: adds when both the existing value and the
# incoming one are numeric (e.g. player.cash), otherwise assigns outright
# (e.g. contacts.james.unlocked = true, which can't be "added" to a bool).
# world.archieChatUnlockDay is a special case straight from the HTML
# (`gameState.world._archieChatUnlockDay = gameState.world.day + 1`): it
# starts null, so "add" there means "today + value", not "null + value".
static func _apply_add(path: String, value: Variant) -> void:
	var current: Variant = GameState.read_path(path)
	var new_value: Variant
	if _is_number(current) and _is_number(value):
		new_value = current + value
	elif current == null and path == "world.archieChatUnlockDay":
		new_value = GameState.state["world"]["day"] + value
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


static func _grant_vein(vein_template: Dictionary) -> void:
	var level: int = vein_template["level"]
	var vein: Dictionary = GameState.deep_copy(vein_template)
	vein["id"] = Cultivating.make_vein_id()
	vein["levelLabel"] = GameData.VEIN_LEVELS[str(level)]["label"]
	vein["claimedOnDay"] = GameState.state["world"]["day"]
	GameState.state["player"]["veins"].append(vein)
