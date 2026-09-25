class_name DebugTools
extends RefCounted

# Static funcs backing the Debug phone app (scenes/phone_apps/debug_app.gd's
# build()). Screens never mutate state directly, so these one-line
# writes exist as systems. Only reachable once flags.debugStartUsed is set
# (gated in PhoneApps.apps()), so nothing here re-checks that flag.

# Effect ops that read a raid's target site_id from start_event()'s context.
const RAID_CONTEXT_OPS: PackedStringArray = ["stealth_check", "start_raid_combat", "claim_raid_vein", "loot_raid_vein"]
# Ops that address a contact by effect["contact"]; fire_event() unlocks it so the effect lands somewhere visible.
const CONTACT_OPS: PackedStringArray = ["relation", "push_message", "queue_pending_message"]
# Where a fabricated site goes when an event needs one and the world has none to offer.
const SPAWN_DISTRICT := "camden"
const SPAWN_TIER := "fair"
const SPAWN_ORE := "physics"
const SPAWN_FACTION := "firm"


static func add_cash(amount: int) -> void:
	GameState.state["player"]["cash"] += amount
	EventBus.state_changed.emit()


static func add_calc(ore_type: String, amount: int) -> void:
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	orichalchum[ore_type] = orichalchum.get(ore_type, 0) + amount
	EventBus.state_changed.emit()


# Every loaded event id (data/events/*.json), sorted for the picker.
static func event_ids() -> Array:
	var ids: Array = GameData.EVENTS.keys()
	ids.sort()
	return ids


# Starts event_id now, after prepare_event() has built what its ops read.
static func fire_event(event_id: String) -> void:
	Events.start_event(event_id, prepare_event(event_id))


# Makes state coherent for event_id's effect ops -- the veins/sites its state
# paths name, the contacts it addresses -- and returns the start_event()
# context its site-reading ops expect (a raid target, or a fresh site to reveal).
static func prepare_event(event_id: String) -> Dictionary:
	var effects := all_effects(GameData.EVENTS[event_id])
	var ops: Array = []
	for effect in effects:
		ops.append(effect["op"])
		_prepare_state_path(effect)
		if effect["op"] in CONTACT_OPS and GameState.state["contacts"].has(effect["contact"]):
			GameState.state["contacts"][effect["contact"]]["unlocked"] = true

	var context: Dictionary = {}
	for effect in effects:
		if effect["op"] in RAID_CONTEXT_OPS:
			context = { "site_id": _enemy_vein_site_id(), "ally_ids": [] }
			break
		if effect["op"] == "network_reveal_vulnerable_vein":
			context = { "site_id": _enemy_vein_site_id(effect["effect"]) }
			break
	if context.is_empty() and "reveal_site" in ops:
		context = { "site_id": Sites.spawn_unclaimed_site(SPAWN_DISTRICT, SPAWN_TIER, SPAWN_ORE)["id"] }
	EventBus.state_changed.emit()
	return context


# Every effect an event can apply: on_complete, each choice's effects, and
# the branches nested under chance/stealth_check.
static func all_effects(event_def: Dictionary) -> Array:
	var result: Array = []
	_collect_effects(event_def.get("on_complete", []), result)
	for card in event_def["cards"]:
		for choice in card.get("choices", []):
			_collect_effects(choice.get("effects", []), result)
	return result


static func _collect_effects(effects: Array, into: Array) -> void:
	for effect in effects:
		into.append(effect)
		for branch in ["on_success", "on_fail", "on_caught"]:
			_collect_effects(effect.get(branch, []), into)


static func _prepare_state_path(effect: Dictionary) -> void:
	match effect["op"]:
		"sell_contact_vein_to_faction", "col_a2_force_vein_loss":
			if effect.has("veinIdStatePath"):
				_ensure_player_vein_at(effect["veinIdStatePath"])
		"claim_faction_vein", "buy_faction_vein":
			if effect.has("veinIdStatePath"):
				_ensure_faction_vein_at(effect["veinIdStatePath"], effect.get("faction", SPAWN_FACTION))
			elif effect.has("siteIdStatePath"):
				_ensure_faction_site_at(effect["siteIdStatePath"])


# The player holds the vein at path, granted by whichever event's
# grant_contact_vein op writes that path, if it isn't already theirs.
static func _ensure_player_vein_at(path: String) -> void:
	var vein_id: Variant = GameState.read_path(path)
	if vein_id != null and Cultivating.find_vein(vein_id) != null:
		return
	var grant := _grant_op_for_path(path)
	if not grant.is_empty():
		Events.apply_effects([grant])


# A non-Collective faction holds the vein at path: an enemy-held one is left
# alone; a Collective-held, player-held or missing one is lost to faction.
static func _ensure_faction_vein_at(path: String, faction: String) -> void:
	var vein_id: Variant = GameState.read_path(path)
	if vein_id != null:
		for site in GameState.state["world"]["sites"]:
			var faction_vein: Variant = site["factionVein"]
			if faction_vein == null or faction_vein["id"] != vein_id:
				continue
			if faction_vein["factionId"] == "collective":
				Collective.force_vein_loss(vein_id, faction)
			return
	_ensure_player_vein_at(path)
	vein_id = GameState.read_path(path)
	if vein_id != null:
		Collective.force_vein_loss(vein_id, faction)


# The site at path still carries a faction vein to claim or buy; otherwise
# a fresh faction-held site is spawned and its id written to path.
static func _ensure_faction_site_at(path: String) -> void:
	var site: Variant = Sites.find_site(str(GameState.read_path(path, "")))
	if site != null and site["factionVein"] != null:
		return
	_write_path(path, _spawn_faction_site()["id"])


# An enemy-held (non-Collective) faction vein's site, preferring one soft to
# vulnerable_effect when given; spawns one if the world has none.
static func _enemy_vein_site_id(vulnerable_effect: String = "") -> String:
	var ids := NetworkHandler.target_site_ids()
	if vulnerable_effect != "":
		for site_id in ids:
			if NetworkHandler.is_vulnerable(site_id, vulnerable_effect):
				return site_id
	if not ids.is_empty():
		return ids[0]
	return _spawn_faction_site()["id"]


static func _spawn_faction_site() -> Dictionary:
	var site := Sites.spawn_unclaimed_site(SPAWN_DISTRICT, SPAWN_TIER, SPAWN_ORE)
	site["factionVein"] = Factions.create_faction_vein(SPAWN_FACTION, site, GameData.VEIN_GROWTH["seedGrowth"])
	return site


static func _grant_op_for_path(path: String) -> Dictionary:
	for event_id in GameData.EVENTS:
		for effect in all_effects(GameData.EVENTS[event_id]):
			if effect["op"] == "grant_contact_vein" and effect["statePath"] == path:
				return effect
	return {}


static func _write_path(path: String, value: Variant) -> void:
	var parts: PackedStringArray = path.split(".")
	var current: Dictionary = GameState.state
	for i in range(parts.size() - 1):
		current = current[parts[i]]
	current[parts[parts.size() - 1]] = value
