class_name EventItems
extends RefCounted

# Items usable from an event's Item button. ENTRIES is the registry: each
# entry names its source ("consumable" = inventory stock, "dial" = a loaded
# Complication paid from Dial charge) and the recipe key it draws on. A new
# entry adds a row here plus its readiness/effect arm in _effect_ready() and
# _apply(); the event screen only lists usable_entries() and calls use().

const ENTRIES: Array[Dictionary] = [
	{ "id": "rewind", "label": "Rewind", "source": "consumable", "recipeKey": "rewind" },
	{ "id": "dialRewind", "label": "Rewind (Dial)", "source": "dial", "recipeKey": "rewind" },
]


# Entries usable right now, each a copy of its ENTRIES row plus "count"
# (inventory qty for a consumable, remaining Dial charge for a Dial entry).
static func usable_entries() -> Array:
	var out: Array = []
	for entry in ENTRIES:
		var count: int = _count(entry)
		if count > 0 and _effect_ready(entry):
			var usable: Dictionary = entry.duplicate()
			usable["count"] = count
			out.append(usable)
	return out


static func has_usable() -> bool:
	return not usable_entries().is_empty()


static func use(id: String) -> Dictionary:
	for entry in ENTRIES:
		if entry["id"] != id:
			continue
		if _count(entry) < 1 or not _effect_ready(entry):
			return { "ok": false, "reason": "Not usable right now." }
		return _apply(entry)
	return { "ok": false, "reason": "Unknown item." }


static func _count(entry: Dictionary) -> int:
	match entry["source"]:
		"consumable":
			return Crafting.inventory_qty(entry["recipeKey"])
		"dial":
			return _dial_charges(entry["recipeKey"])
	return 0


# Remaining charge if a Complication of this recipe is loaded, else 0.
static func _dial_charges(recipe_key: String) -> int:
	var dial: Variant = GameState.state["player"]["dial"]
	if dial == null:
		return 0
	for loaded in dial["loadedComplications"]:
		if loaded["recipeKey"] == recipe_key:
			return int(dial["currentCharge"])
	return 0


static func _effect_ready(entry: Dictionary) -> bool:
	match entry["recipeKey"]:
		"rewind":
			return Events.has_rewind_point()
	return false


static func _apply(entry: Dictionary) -> Dictionary:
	match entry["recipeKey"]:
		"rewind":
			return Events.rewind(entry["source"])
	return { "ok": false, "reason": "No event effect for that item." }
