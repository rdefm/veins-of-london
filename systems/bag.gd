class_name Bag
extends RefCounted

# The global BagDrawer's open/closed state (D4.4). Mirrors Modal.open/close's
# reasoning: state.bagDrawerOpen is part of GameState.state (R§2), so toggling
# it is a state mutation that has to go through a system function rather than
# the BagDrawer component (or the top bar's bag button) touching state
# directly. Deliberately just a bool, not a Modal — the drawer has to be
# openable on top of a modal or mid-combat/mid-event without disturbing
# whatever else is on screen (R§2, D4.4), so it can't reuse state.modal.


static func open() -> void:
	GameState.state["bagDrawerOpen"] = true
	EventBus.state_changed.emit()


static func close() -> void:
	GameState.state["bagDrawerOpen"] = false
	EventBus.state_changed.emit()


# ── Projection ───────────────────────────────────────────────────────────
# Pure read of the held stock for the drawer: filter options, ore categories
# and one row per held item key. No Nodes.

const CONSUMABLE_KEYS := ["timePearl", "enhancementPowder", "rewind", "healingSalve", "blast", "shield", "blackHole", "healingBurst", "prophetsBreath", "beALady", "wormhole"]
const OTHER_CATEGORY := ""
const TARGET_ITEMS := ["smellingSalts", "cleanSlate", "rootFeed", "goodYear", "deadweight"]
const HQ_TARGET := "hq"
const SIMPLE_USE_ITEMS := ["healingSalve", "healingBurst"]


# Recipe keys the Bag may list (when held): the combat/consumable roster,
# `bagWhenHeld` recipes and the timed-effect items.
static func listed_keys() -> Array:
	var keys: Array = []
	for key in GameData.RECIPES.keys():
		if _is_listed(str(key)):
			keys.append(str(key))
	return keys


static func _is_listed(recipe_key: String) -> bool:
	return CONSUMABLE_KEYS.has(recipe_key) or GameData.RECIPES[recipe_key].get("bagWhenHeld", false) or ActiveEffects.usable_items().has(recipe_key) or recipe_key == TimeSystem.BORROWED_TIME


# The use action id a key supports from the Bag with no target ("" if none).
static func use_action(recipe_key: String) -> String:
	if SIMPLE_USE_ITEMS.has(recipe_key) or recipe_key == TimeSystem.BORROWED_TIME or ActiveEffects.usable_items().has(recipe_key):
		return recipe_key
	return ""


static func held_tiers(inventory_key: String) -> Array:
	var tiers: Array = []
	for tier in range(1, 6):
		if Stash.player_item_tier_qty(inventory_key, tier) > 0:
			tiers.append(tier)
	return tiers


# One ore category per ore (in GameData.ORE_TYPES order) then OTHER_CATEGORY;
# a multi-ore recipe appears under each of its ores (the Lab grouping).
static func categories_for(recipe_key: String) -> Array:
	var ores: Array = []
	for ore_type in GameData.ORE_TYPES.keys():
		if GameData.RECIPES[recipe_key].get("ingredients", {}).has(ore_type):
			ores.append(str(ore_type))
	return ores if not ores.is_empty() else [OTHER_CATEGORY]


# Valid targets for a target item: [{ id, label }]. Empty = nothing to use it on.
static func targets(recipe_key: String) -> Array:
	var result: Array = []
	match recipe_key:
		"smellingSalts":
			for contact_id in Contacts.ko_cooldown_contacts():
				result.append({ "id": contact_id, "label": Contacts.display_name(contact_id) })
		"cleanSlate":
			for faction_id in Grudges.clearable_factions():
				result.append({ "id": faction_id, "label": "%s grudge" % GameData.FACTIONS[faction_id]["shortName"] })
		_:
			if not Cultivating.boost_items().has(recipe_key):
				return result
			for vein in GameState.state["player"]["veins"]:
				result.append({ "id": vein["id"], "label": "%s vein — %s" % [GameData.ORE_TYPES[vein["oreType"]]["name"], vein["location"]] })
			if recipe_key == Cultivating.DEADWEIGHT:
				result.append({ "id": HQ_TARGET, "label": "HQ" })
	return result


# Rows for every held listed item. management gates `usable`: only no-target
# single-target stock, and never mid-combat or an item-hook card.
static func rows(management: bool) -> Array:
	var result: Array = []
	for recipe_key in listed_keys():
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		for multi in [false, true]:
			var inv_key: String = Crafting.inventory_key(recipe_key, multi)
			var total: int = Stash.player_item_qty(inv_key)
			if total <= 0:
				continue
			var action: String = "" if multi else use_action(recipe_key)
			var targeted: bool = management and not multi and not targets(recipe_key).is_empty()
			result.append({
				"key": recipe_key,
				"inventoryKey": inv_key,
				"name": "%s (multi)" % recipe["name"] if multi else recipe["name"],
				"multi": multi,
				"total": total,
				"stash": Stash.stashed_item_qty(inv_key),
				"tiers": held_tiers(inv_key),
				"useAction": action,
				"usable": (management and action != "") or targeted,
				"targeted": targeted,
				"categories": categories_for(recipe_key),
			})
	return result


# { filters: [ore ids that have rows], categories: [{ ore, name, rows }] }.
# ore_filter "" shows every category; an unknown or empty-ore filter shows none.
static func projection(ore_filter: String, management: bool) -> Dictionary:
	var all_rows: Array = rows(management)
	var filters: Array = []
	var categories: Array = []
	var order: Array = GameData.ORE_TYPES.keys()
	order.append(OTHER_CATEGORY)
	for ore in order:
		var in_category: Array = all_rows.filter(func(r): return r["categories"].has(ore))
		if in_category.is_empty():
			continue
		if ore != OTHER_CATEGORY:
			filters.append(str(ore))
		if ore_filter.is_empty() or ore_filter == ore:
			categories.append({ "ore": str(ore), "name": category_name(str(ore)), "rows": in_category })
	return { "filters": filters, "categories": categories }


# PROSE-REVIEW: "Other" heading for held items with no ore ingredient.
static func category_name(ore: String) -> String:
	return "Other" if ore == OTHER_CATEGORY else str(GameData.ORE_TYPES[ore]["name"])


# True when the card is a combat, or an event card with item hooks: read-only Bag.
static func is_management_mode() -> bool:
	if GameState.state["combat"]["active"]:
		return false
	if GameState.state.get("event") != null:
		if not Events.current_card().get("itemHooks", []).is_empty():
			return false
	return true


# Uses one unit of a no-target item (exact tier when tier > 0). Closes the drawer.
static func use(recipe_key: String, tier: int = 0) -> Dictionary:
	if not is_management_mode() or use_action(recipe_key).is_empty():
		return { "ok": false, "reason": "Can't use that here." }
	close()
	if SIMPLE_USE_ITEMS.has(recipe_key):
		return Consumables.use_healing_salve(tier) if recipe_key == "healingSalve" else Consumables.use_healing_burst(tier)
	if recipe_key == TimeSystem.BORROWED_TIME:
		return TimeSystem.use_borrowed_time(tier)
	return ActiveEffects.use(recipe_key, tier)


# Uses one unit of a target item on `target_id` (tier 0 = lowest held for boosts).
# Closes the drawer.
static func use_on(recipe_key: String, target_id: String, tier: int = 0) -> Dictionary:
	if not is_management_mode() or not TARGET_ITEMS.has(recipe_key):
		return { "ok": false, "reason": "Can't use that here." }
	var valid := false
	for target in targets(recipe_key):
		valid = valid or target["id"] == target_id
	if not valid:
		return { "ok": false, "reason": "Not a valid target." }
	close()
	match recipe_key:
		"smellingSalts":
			return Contacts.use_smelling_salts(target_id)
		"cleanSlate":
			return Grudges.use_clean_slate(target_id)
	var use_tier: int = tier if tier > 0 else int(held_tiers(recipe_key).front())
	if target_id == HQ_TARGET:
		return Home.apply_deadweight(use_tier)
	return Cultivating.apply_item(target_id, recipe_key, use_tier)
