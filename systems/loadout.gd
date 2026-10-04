class_name Loadout
extends RefCounted

# The player's personal consumable slots (R§2 player.loadout, R§3.7). A slot
# holds one tiered unit { recipe, tier } moved out of player.inventory;
# lastRecipe[i] remembers the recipe last assigned to slot i ("" if never).


static func slot_count() -> int:
	return int(GameData.LOADOUT["slotCount"])


static func is_equippable(recipe_key: String, contact_id: String = "") -> bool:
	if contact_id != "" and GameData.LOADOUT["allyExcluded"].has(recipe_key):
		return false
	return GameData.LOADOUT["items"].has(recipe_key)


# The loadout dict of the player ("") or a contact; {} for a contact with none.
static func _loadout(contact_id: String) -> Dictionary:
	if contact_id == "":
		return GameState.state["player"]["loadout"]
	return GameState.state["contacts"].get(contact_id, {}).get("loadout", {})


# Recruited contacts that carry loadout slots, in roster (Profile) order.
static func recruit_ids() -> Array:
	var ids: Array = []
	for contact_id in GameState.state["contacts"]:
		var c: Dictionary = GameState.state["contacts"][contact_id]
		if c["recruited"] and c.has("loadout"):
			ids.append(contact_id)
	return ids


static func slot(index: int, contact_id: String = "") -> Variant:
	return _loadout(contact_id)["slots"][index]


static func last_recipe(index: int, contact_id: String = "") -> String:
	return String(_loadout(contact_id)["lastRecipe"][index])


# Equipped units in slot order, as [{ recipe, tier }, ...] (empty slots skipped).
static func equipped_units() -> Array:
	var units: Array = []
	for entry in GameState.state["player"]["loadout"]["slots"]:
		if entry is Dictionary:
			units.append(entry)
	return units


# Moves one unit of recipe_key at `tier` from shared inventory into the slot.
# An occupied slot is refused; unequip first.
static func equip(index: int, recipe_key: String, tier: int, contact_id: String = "") -> Dictionary:
	var loadout: Dictionary = _loadout(contact_id)
	if loadout.is_empty() or index < 0 or index >= slot_count():
		return { "ok": false, "reason": "No such slot." }
	if GameState.state["combat"]["active"]:
		return { "ok": false, "reason": "Not mid-fight." }
	if not is_equippable(recipe_key, contact_id):
		return { "ok": false, "reason": "That can't be carried in a slot." }
	if loadout["slots"][index] != null:
		return { "ok": false, "reason": "Slot already filled." }
	var buckets: Dictionary = GameState.state["player"]["inventory"].get(recipe_key, {})
	if int(buckets.get(str(tier), 0)) <= 0:
		return { "ok": false, "reason": "None in stock." }
	Crafting.inventory_remove_from_tier(recipe_key, tier, 1)
	loadout["slots"][index] = { "recipe": recipe_key, "tier": tier }
	loadout["lastRecipe"][index] = recipe_key
	EventBus.state_changed.emit()
	return { "ok": true }


# Returns the slot's unit to shared inventory at its stored tier; lastRecipe stays.
static func unequip(index: int, contact_id: String = "") -> Dictionary:
	var loadout: Dictionary = _loadout(contact_id)
	if loadout.is_empty() or index < 0 or index >= slot_count():
		return { "ok": false, "reason": "No such slot." }
	if GameState.state["combat"]["active"]:
		return { "ok": false, "reason": "Not mid-fight." }
	var entry: Variant = loadout["slots"][index]
	if entry == null:
		return { "ok": false, "reason": "Slot is empty." }
	Crafting.inventory_add(entry["recipe"], int(entry["tier"]), 1)
	loadout["slots"][index] = null
	EventBus.state_changed.emit()
	return { "ok": true }


# Equippable shared-inventory stock as [{ recipe, tier, qty }, ...]: allowlist
# order, then ascending tier.
static func equippable_stock(contact_id: String = "") -> Array:
	var stock: Array = []
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	for recipe_key in GameData.LOADOUT["items"]:
		if not is_equippable(recipe_key, contact_id):
			continue
		var buckets: Dictionary = inventory.get(recipe_key, {})
		var tier_keys: Array = buckets.keys()
		tier_keys.sort_custom(func(a, b): return int(a) < int(b))
		for tier_key in tier_keys:
			if int(buckets[tier_key]) > 0:
				stock.append({ "recipe": recipe_key, "tier": int(tier_key), "qty": int(buckets[tier_key]) })
	return stock


# The slot a combat use of recipe_key spends: `preferred` if it holds that
# recipe, else (preferred < 0) the first slot that does; -1 when none.
static func find_slot(recipe_key: String, preferred: int = -1) -> int:
	var slots: Array = GameState.state["player"]["loadout"]["slots"]
	if preferred >= 0:
		if preferred < slots.size() and slots[preferred] != null and slots[preferred]["recipe"] == recipe_key:
			return preferred
		return -1
	for i in slots.size():
		if slots[i] != null and slots[i]["recipe"] == recipe_key:
			return i
	return -1


# Spends the slot's unit (no refund) and returns its effect power at the
# stored tier. During combat the slot is marked for settlement refill.
static func consume(index: int) -> Variant:
	var loadout: Dictionary = GameState.state["player"]["loadout"]
	var unit: Dictionary = loadout["slots"][index]
	loadout["slots"][index] = null
	var combat: Dictionary = GameState.state["combat"]
	if combat["active"]:
		var used: Array = combat.get("slotsUsed", [])
		combat["slotsUsed"] = used
		if not used.has(index):
			used.append(index)
	var recipe_key: String = unit["recipe"]
	return Crafting.effect_power(recipe_key, clampi(int(unit["tier"]), 1, GameData.RECIPES[recipe_key]["effectPower"].size() - 1))


# Settlement: each used slot (in slot order) takes the highest-tier unit of
# its recipe from shared inventory; with none it stays empty.
static func refill_used(used: Array, contact_id: String = "") -> void:
	var sorted_used: Array = used.map(func(i): return int(i))
	sorted_used.sort()
	var loadout: Dictionary = _loadout(contact_id)
	if loadout.is_empty():
		return
	for index in sorted_used:
		if index >= slot_count() or loadout["slots"][index] != null:
			continue
		var recipe_key: String = last_recipe(index, contact_id)
		if recipe_key == "":
			continue
		var buckets: Dictionary = GameState.state["player"]["inventory"].get(recipe_key, {})
		var best := 0
		for tier_key in buckets:
			if int(buckets[tier_key]) > 0:
				best = maxi(best, int(tier_key))
		if best <= 0:
			continue
		Crafting.inventory_remove_from_tier(recipe_key, best, 1)
		loadout["slots"][index] = { "recipe": recipe_key, "tier": best }


# Settlement for the allies of a finished fight: each recruit's spent slots
# empty, then refill runs player first (caller), recruits in roster order.
static func settle_allies(allies: Array) -> void:
	var used_by_contact := {}
	for ally in allies:
		var contact_id: String = ally.get("contactId", "")
		if contact_id == "" or _loadout(contact_id).is_empty():
			continue
		var used: Array = ally.get("slotsUsed", [])
		used_by_contact[contact_id] = used
		for index in used:
			_loadout(contact_id)["slots"][int(index)] = null
	for contact_id in recruit_ids():
		if used_by_contact.has(contact_id):
			refill_used(used_by_contact[contact_id], contact_id)
