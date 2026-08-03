class_name Barometer
extends RefCounted

# Three-axis barometer (economic/social/political) per R§3.2. Static funcs
# only; reads/writes GameState.state.barometer, emits EventBus.state_changed.

const SECTIONS: Array[String] = ["economic", "social", "political"]
const MANUAL_ACTION_COST := 2000

# D4.5's Ticker trend hint: a non-active state at or above this progress
# gets a "rumblings…" hint on its axis's headline card.
const TREND_HINT_THRESHOLD := 70


# Lazily fills state.barometer.progress so every section/state has an
# entry: 100 for the currently-active state, 0 for the rest. Safe to call
# every tick — never clobbers values that already exist (e.g. after a
# save/load, or mid-game).
static func ensure_progress() -> void:
	var barometer: Dictionary = GameState.state["barometer"]
	if not barometer.has("progress"):
		barometer["progress"] = {}
	var progress: Dictionary = barometer["progress"]
	for section in SECTIONS:
		if not progress.has(section):
			progress[section] = {}
		var section_progress: Dictionary = progress[section]
		var active_state: String = barometer[section]
		for state_id in GameData.BAROMETER_STATES[section].keys():
			if not section_progress.has(state_id):
				section_progress[state_id] = 100 if state_id == active_state else 0


static func ensure_cooldowns() -> void:
	var barometer: Dictionary = GameState.state["barometer"]
	if not barometer.has("cooldowns"):
		barometer["cooldowns"] = {}
	var cooldowns: Dictionary = barometer["cooldowns"]
	for section in SECTIONS:
		if not cooldowns.has(section):
			cooldowns[section] = {}
		var section_cd: Dictionary = cooldowns[section]
		for state_id in GameData.BAROMETER_STATES[section].keys():
			if not section_cd.has(state_id):
				section_cd[state_id] = { "push": 0, "pull": 0 }


# Daily entry point: nudges, drift, then resolution, for all three sections.
static func tick() -> void:
	ensure_progress()
	ensure_cooldowns()
	_apply_faction_nudges()
	_apply_organic_drift()
	for section in SECTIONS:
		_resolve_section(section)
	EventBus.state_changed.emit()


# Every faction's barometer prefs nudge progress daily, regardless of
# whether the player has joined that faction.
static func _apply_faction_nudges() -> void:
	var progress: Dictionary = GameState.state["barometer"]["progress"]
	for faction_id in GameData.FACTION_BAROMETER_PREFS.keys():
		for pref in GameData.FACTION_BAROMETER_PREFS[faction_id]:
			var section: String = pref["section"]
			var state_id: String = pref["state"]
			var strength: int = pref["strength"]
			var delta: int = strength if pref["direction"] == "push" else -strength
			var section_progress: Dictionary = progress[section]
			section_progress[state_id] = clampi(section_progress[state_id] + delta, 0, 100)


static func _apply_organic_drift() -> void:
	var barometer: Dictionary = GameState.state["barometer"]
	var progress: Dictionary = barometer["progress"]
	for section in SECTIONS:
		var active_state: String = barometer[section]
		var section_progress: Dictionary = progress[section]
		for state_id in GameData.BAROMETER_STATES[section].keys():
			if state_id == active_state:
				continue
			if Rng.chance(0.20):
				section_progress[state_id] = mini(section_progress[state_id] + 1, 99)


# Clamps progress to 0-100; if any non-active state has reached 100, it
# becomes the new active state (old active drops to 0) and a shift
# notification fires. At most one resolution per section per call.
static func _resolve_section(section: String) -> void:
	var barometer: Dictionary = GameState.state["barometer"]
	var progress: Dictionary = barometer["progress"][section]
	var active_state: String = barometer[section]

	for state_id in progress.keys():
		progress[state_id] = clampi(progress[state_id], 0, 100)

	for state_id in GameData.BAROMETER_STATES[section].keys():
		if state_id == active_state:
			continue
		if progress[state_id] >= 100:
			progress[active_state] = 0
			progress[state_id] = 100
			barometer[section] = state_id
			var state_data: Dictionary = GameData.BAROMETER_STATES[section][state_id]
			var headline: String = Rng.rand_from(state_data["headlines"])
			Notify.push("📰 BREAKING — %s" % headline)
			break


# D4.5's Ticker "rumblings..." hint: the highest-progress non-active state
# at/above TREND_HINT_THRESHOLD, or null if none qualifies. Ties broken by
# GameData.BAROMETER_STATES iteration order (stable across a given table).
static func trend_hint_state(section: String) -> Variant:
	ensure_progress()
	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var progress: Dictionary = barometer["progress"][section]

	var best_id: Variant = null
	var best_progress := -1
	for state_id in GameData.BAROMETER_STATES[section].keys():
		if state_id == active_state:
			continue
		var p: int = progress.get(state_id, 0)
		if p >= TREND_HINT_THRESHOLD and p > best_progress:
			best_id = state_id
			best_progress = p
	return best_id


static func can_push_pull(section: String, state_id: String, direction: String) -> bool:
	ensure_cooldowns()
	var day: int = GameState.state["world"]["day"]
	var cooldown: int = GameState.state["barometer"]["cooldowns"][section][state_id][direction]
	return day > cooldown


static func manual_push(section: String, state_id: String) -> Dictionary:
	return _manual_action(section, state_id, "push")


static func manual_pull(section: String, state_id: String) -> Dictionary:
	return _manual_action(section, state_id, "pull")


static func _manual_action(section: String, state_id: String, direction: String) -> Dictionary:
	ensure_progress()
	ensure_cooldowns()
	var player: Dictionary = GameState.state["player"]

	if player["cash"] < MANUAL_ACTION_COST:
		return { "ok": false, "reason": "Not enough cash." }
	if not can_push_pull(section, state_id, direction):
		return { "ok": false, "reason": "On cooldown." }

	player["cash"] -= MANUAL_ACTION_COST
	var day: int = GameState.state["world"]["day"]
	GameState.state["barometer"]["cooldowns"][section][state_id][direction] = day

	var progress: Dictionary = GameState.state["barometer"]["progress"][section]
	if direction == "push":
		progress[state_id] = clampi(progress[state_id] + 20, 0, 100)
		_resolve_section(section)
	else:
		progress[state_id] = clampi(progress[state_id] - 20, 0, 100)

	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


# Sum of the three currently-active states' `effects` dicts.
static func get_merged_effects() -> Dictionary:
	var barometer: Dictionary = GameState.state["barometer"]
	var merged: Dictionary = {}
	for section in SECTIONS:
		var active_state: String = barometer[section]
		var effects: Dictionary = GameData.BAROMETER_STATES[section][active_state]["effects"]
		for key in effects.keys():
			merged[key] = merged.get(key, 0.0) + effects[key]
	return merged


static func get_effective_mug_chance(base: float) -> float:
	var fx := get_merged_effects()
	return clampf(base + fx.get("mugChance", 0.0), 0.0, 0.8)


static func get_effective_ore_price(ore_type: String, base: int) -> int:
	var fx := get_merged_effects()
	var premium_key := "%sPremium" % ore_type
	var multiplier: float = max(0.1, 1.0 + fx.get("orePrice", 0.0) + fx.get(premium_key, 0.0))
	return GameState.round_epsilon(base * multiplier)
