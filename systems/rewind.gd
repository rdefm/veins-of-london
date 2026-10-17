class_name Rewind
extends RefCounted

# Paying for a Rewind (R§3.9: a `rewind` item, else a loaded Dial Rewind
# complication) and the time-block Rewind (.scratch/lab-port/spec.md
# § Rewind): state.blockStart holds a copy of the whole state taken as each
# time block opens, and rewind_to_block_start() puts the world back to it.
# The player keeps what they remember and wear -- XP and skill levels, Lab
# knowledge, meta preferences, the loadout and the Dial -- and shared
# inventory is squared up so equipped units are neither lost nor doubled.
# blockStart is never written to a save (SaveManager) or into an event
# snapshot (Events).

const Preferences := preload("res://systems/preferences.gd")


# Whether a Rewind can be paid for right now.
static func can_pay() -> bool:
	return Crafting.inventory_qty("rewind") > 0 or Dial.find_loaded_rewind_complication_index() >= 0


# Picks how a Rewind is paid. source: "consumable" or "dial" pays from that
# source only; "" prefers the consumable and falls back to the Dial.
# { ok, consumable: bool, dialIndex: int } or { ok: false, reason }.
static func choose_payment(source: String = "") -> Dictionary:
	var has_consumable: bool = Crafting.inventory_qty("rewind") > 0
	var dial_index: int = Dial.find_loaded_rewind_complication_index()
	match source:
		"consumable":
			if not has_consumable:
				return { "ok": false, "reason": "No Rewind in stock." }
		"dial":
			if dial_index < 0:
				return { "ok": false, "reason": "No Dial Rewind charge." }
			has_consumable = false
	if not has_consumable and dial_index < 0:
		return { "ok": false, "reason": "No rewind available." }
	return { "ok": true, "consumable": has_consumable, "dialIndex": dial_index }


# Spends what choose_payment() picked.
static func pay(payment: Dictionary) -> void:
	if payment["consumable"]:
		Crafting.inventory_remove("rewind", 1)
	else:
		Dial.cast_complication(int(payment["dialIndex"]))


# ── Time-block Rewind ────────────────────────────────────────────────────

const PLAYER_KEPT_KEYS: Array[String] = ["loadout", "dial"]
# The player stays on the screen they rewound from.
const NAV_KEPT_KEYS: Array[String] = ["currentScreen", "phoneNav"]
const LAB_KEPT_KEYS: Array[String] = ["known", "bestRanks", "performedOnce"]


# Takes the block-start copy. TimeSystem calls this once a block opens. A
# block opened mid-event or mid-fight gets no point: restoring into one
# would replay half a scene.
static func mark_block_start() -> void:
	GameState.state["blockStart"] = null
	if GameState.state["event"] != null or GameState.state["combat"]["active"]:
		return
	GameState.state["blockStart"] = GameState.deep_copy(GameState.state)


static func has_block_start() -> bool:
	return GameState.state.get("blockStart") != null


static func block_rewind_block_reason() -> String:
	if not has_block_start():
		return "Nothing to rewind to."
	if LessonSession.is_open():
		return "Not during a lesson."
	if GameState.state["event"] != null:
		return "Not mid-event."
	if GameState.state["combat"]["active"]:
		return "Not mid-fight."
	return ""


static func rewind_to_block_start(source: String = "") -> Dictionary:
	var reason := block_rewind_block_reason()
	if reason != "":
		return { "ok": false, "reason": reason }
	var payment := choose_payment(source)
	if not payment["ok"]:
		return payment
	var live: Dictionary = GameState.state
	var restored: Dictionary = GameState.deep_copy(live["blockStart"])
	restored["blockStart"] = live["blockStart"]
	_carry_player(live["player"], restored["player"])
	for key in LAB_KEPT_KEYS:
		restored["lab"][key] = live["lab"][key]
	restored["lab"]["lastCraft"] = null
	for key in NAV_KEPT_KEYS:
		restored[key] = live[key]
	GameState.state = restored
	Preferences.carry_forward(live["meta"])
	pay(payment)
	Notify.push("⟲ Time unspools. The moment resets. Only you remember.")
	EventBus.state_changed.emit()
	return { "ok": true }


# Moves the live XP, skill levels, loadout and Dial onto the restored
# player, then squares shared inventory and Movements with them.
static func _carry_player(live: Dictionary, restored: Dictionary) -> void:
	var then_units := _equipped_units(restored)
	var then_movement: Variant = _seated_movement(restored)
	for key in live.keys():
		if String(key).ends_with("XP") or String(key).ends_with("Skill"):
			restored[key] = live[key]
	for key in PLAYER_KEPT_KEYS:
		restored[key] = live[key]
	var now_units := _equipped_units(restored)
	var inventory: Dictionary = restored["inventory"]
	for unit in now_units.keys():
		var extra := int(now_units[unit]) - int(then_units.get(unit, 0))
		if extra > 0:
			_shift_stock(inventory, unit, -extra)
	for unit in then_units.keys():
		var missing := int(then_units[unit]) - int(now_units.get(unit, 0))
		if missing > 0:
			_shift_stock(inventory, unit, missing)
	var now_movement: Variant = _seated_movement(restored)
	if now_movement != then_movement:
		var movements: Array = restored["movementInventory"]
		if then_movement != null:
			movements.append(then_movement)
		if now_movement != null:
			movements.erase(now_movement)


# "<inventory key>|<tier>" -> count, over loadout slots and loaded Dial
# complications.
static func _equipped_units(player: Dictionary) -> Dictionary:
	var units := {}
	for entry in player["loadout"]["slots"]:
		if entry is Dictionary:
			_count_unit(units, entry["recipe"], entry)
	if player["dial"] is Dictionary:
		for entry in player["dial"]["loadedComplications"]:
			_count_unit(units, entry["recipeKey"], entry)
	return units


static func _count_unit(units: Dictionary, recipe_key: String, entry: Dictionary) -> void:
	var unit := "%s|%d" % [Crafting.inventory_key(recipe_key, entry.get("multi", false)), int(entry["tier"])]
	units[unit] = int(units.get(unit, 0)) + 1


static func _seated_movement(player: Dictionary) -> Variant:
	return player["dial"]["movement"] if player["dial"] is Dictionary else null


# Adds (or, negative, takes at most what's there of) one unit's stock.
static func _shift_stock(inventory: Dictionary, unit: String, delta: int) -> void:
	var parts := unit.split("|")
	var buckets: Dictionary = inventory.get(parts[0], {})
	var count := maxi(0, int(buckets.get(parts[1], 0)) + delta)
	if count > 0:
		buckets[parts[1]] = count
	else:
		buckets.erase(parts[1])
	inventory[parts[0]] = buckets
