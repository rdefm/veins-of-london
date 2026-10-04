class_name Loadout
extends RefCounted

# The player's personal consumable slots (R§2 player.loadout, R§3.7). A slot
# holds one tiered unit { recipe, tier } moved out of player.inventory;
# lastRecipe[i] remembers the recipe last assigned to slot i ("" if never).


static func slot_count() -> int:
	return int(GameData.LOADOUT["slotCount"])


static func is_equippable(recipe_key: String) -> bool:
	return GameData.LOADOUT["items"].has(recipe_key)


static func slot(index: int) -> Variant:
	return GameState.state["player"]["loadout"]["slots"][index]


static func last_recipe(index: int) -> String:
	return String(GameState.state["player"]["loadout"]["lastRecipe"][index])


# Equipped units in slot order, as [{ recipe, tier }, ...] (empty slots skipped).
static func equipped_units() -> Array:
	var units: Array = []
	for entry in GameState.state["player"]["loadout"]["slots"]:
		if entry is Dictionary:
			units.append(entry)
	return units


# Moves one unit of recipe_key at `tier` from shared inventory into the slot.
# An occupied slot is refused; unequip first.
static func equip(index: int, recipe_key: String, tier: int) -> Dictionary:
	if index < 0 or index >= slot_count():
		return { "ok": false, "reason": "No such slot." }
	if not is_equippable(recipe_key):
		return { "ok": false, "reason": "That can't be carried in a slot." }
	var loadout: Dictionary = GameState.state["player"]["loadout"]
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
static func unequip(index: int) -> Dictionary:
	if index < 0 or index >= slot_count():
		return { "ok": false, "reason": "No such slot." }
	var loadout: Dictionary = GameState.state["player"]["loadout"]
	var entry: Variant = loadout["slots"][index]
	if entry == null:
		return { "ok": false, "reason": "Slot is empty." }
	Crafting.inventory_add(entry["recipe"], int(entry["tier"]), 1)
	loadout["slots"][index] = null
	EventBus.state_changed.emit()
	return { "ok": true }


# Equippable shared-inventory stock as [{ recipe, tier, qty }, ...]: allowlist
# order, then ascending tier.
static func equippable_stock() -> Array:
	var stock: Array = []
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	for recipe_key in GameData.LOADOUT["items"]:
		var buckets: Dictionary = inventory.get(recipe_key, {})
		var tier_keys: Array = buckets.keys()
		tier_keys.sort_custom(func(a, b): return int(a) < int(b))
		for tier_key in tier_keys:
			if int(buckets[tier_key]) > 0:
				stock.append({ "recipe": recipe_key, "tier": int(tier_key), "qty": int(buckets[tier_key]) })
	return stock
