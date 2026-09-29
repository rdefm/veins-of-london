class_name GuardKit
extends RefCounted

# Combat consumables stocked for a player vein's guards (guard-kit spec
# §State/§Capacity/§Stocking system). vein.guardKit has player.inventory's
# tier-bucketed shape: { recipeKey: { "<tier>": count } }. The kit-dict
# helpers (capacity_of, unit_count, active_units_of) take a guard count and
# slots-per-guard so the HQ kit shares them.


static func is_eligible(recipe_key: String) -> bool:
	return GameData.GUARD_KIT["items"].has(recipe_key)


static func capacity_of(guard_count: int, slots_per_guard: int) -> int:
	return maxi(0, guard_count) * slots_per_guard


static func unit_count(kit: Dictionary) -> int:
	var total := 0
	for buckets in kit.values():
		for count in buckets.values():
			total += int(count)
	return total


# The first `capacity` units of the kit: allowlist order, then highest tier
# first. Same shape as the kit; units past capacity are inactive.
static func active_units_of(kit: Dictionary, guard_count: int, slots_per_guard: int) -> Dictionary:
	var remaining := capacity_of(guard_count, slots_per_guard)
	var active := {}
	for recipe_key in GameData.GUARD_KIT["items"]:
		if remaining <= 0:
			break
		var buckets: Dictionary = kit.get(recipe_key, {})
		for tier_key in _tiers_high_first(buckets):
			var take := mini(int(buckets[tier_key]), remaining)
			if take <= 0:
				continue
			if not active.has(recipe_key):
				active[recipe_key] = {}
			active[recipe_key][tier_key] = take
			remaining -= take
			if remaining <= 0:
				break
	return active


static func capacity(vein: Dictionary) -> int:
	return capacity_of(Cultivating.vein_guard_count(vein), int(GameData.GUARD_KIT["slotsPerGuard"]))


static func active_units(vein: Dictionary) -> Dictionary:
	return active_units_of(vein.get("guardKit", {}), Cultivating.vein_guard_count(vein), int(GameData.GUARD_KIT["slotsPerGuard"]))


# Moves `qty` units of one tier from player.inventory onto the vein's kit.
# Refused with no state change: not allowlisted, too few held, not a player
# vein, 0 guards, or the kit would go over capacity.
static func stock(vein_id: String, recipe_key: String, tier: int, qty: int) -> Dictionary:
	var vein = Cultivating.find_vein(vein_id)
	if vein == null:
		return _refuse("Not your vein.")
	var guard_count := Cultivating.vein_guard_count(vein)
	if guard_count <= 0:
		return _refuse("No guards on this vein.")
	var result := stock_into(vein, "guardKit", capacity(vein), recipe_key, tier, qty)
	if result["ok"]:
		EventBus.state_changed.emit()
	return result


# Moves `qty` units of one tier from the vein's kit back to player.inventory.
# Allowed over capacity and with 0 guards; refused if the kit holds fewer.
static func unstock(vein_id: String, recipe_key: String, tier: int, qty: int) -> Dictionary:
	var vein = Cultivating.find_vein(vein_id)
	if vein == null:
		return _refuse("Not your vein.")
	var result := unstock_from(vein, "guardKit", recipe_key, tier, qty)
	if result["ok"]:
		EventBus.state_changed.emit()
	return result


# Player veins the HQ Guard Kit screen lists: 1+ guards or a non-empty kit.
static func kit_veins() -> Array:
	return GameState.state["player"]["veins"].filter(func(v):
		return Cultivating.vein_guard_count(v) > 0 or unit_count(v.get("guardKit", {})) > 0)


# A kit target names one kit for shared UI (the stocking sheet):
# { "kind": "vein", "veinId": id }. Unknown targets read as an empty,
# 0-capacity kit and refuse every move.
static func target_kit(target: Dictionary) -> Dictionary:
	var vein = _target_vein(target)
	return vein.get("guardKit", {}) if vein != null else {}


static func target_capacity(target: Dictionary) -> int:
	var vein = _target_vein(target)
	return capacity(vein) if vein != null else 0


static func target_guard_count(target: Dictionary) -> int:
	var vein = _target_vein(target)
	return Cultivating.vein_guard_count(vein) if vein != null else 0


static func target_name(target: Dictionary) -> String:
	var vein = _target_vein(target)
	if vein == null:
		return ""
	return "%s · %s" % [GameData.DISTRICTS[vein["district"]]["name"], GameData.ORE_TYPES[vein["oreType"]]["name"]]


static func stock_target(target: Dictionary, recipe_key: String, tier: int, qty: int) -> Dictionary:
	if target.get("kind", "") == "vein":
		return stock(target.get("veinId", ""), recipe_key, tier, qty)
	return _refuse("No such kit.")


static func unstock_target(target: Dictionary, recipe_key: String, tier: int, qty: int) -> Dictionary:
	if target.get("kind", "") == "vein":
		return unstock(target.get("veinId", ""), recipe_key, tier, qty)
	return _refuse("No such kit.")


# Units per item in allowlist order, e.g. "Shield ×2 · Blast ×1"; "" when empty.
static func summary_text(kit: Dictionary) -> String:
	var parts: PackedStringArray = []
	for recipe_key in GameData.GUARD_KIT["items"]:
		var units := unit_count({ recipe_key: kit.get(recipe_key, {}) })
		if units > 0:
			parts.append("%s ×%d" % [GameData.RECIPES[recipe_key]["name"], units])
	return " · ".join(parts)


# Kit row text shared by the vein panel and HQ Guard Kit screen, e.g.
# "Guard kit 3/2 · Blast ×3 · idle"; idle when units exceed capacity.
static func status_text(kit: Dictionary, cap: int) -> String:
	var units := unit_count(kit)
	var summary := summary_text(kit)
	var parts: PackedStringArray = ["Guard kit %d/%d" % [units, cap], summary if summary != "" else "Empty"]
	if units > cap:
		parts.append("idle")
	return " · ".join(parts)


# Kit-level stock move on owner[kit_field], shared with the HQ kit. No emit.
static func stock_into(owner: Dictionary, kit_field: String, cap: int, recipe_key: String, tier: int, qty: int) -> Dictionary:
	if qty <= 0:
		return _refuse("Nothing to move.")
	if not is_eligible(recipe_key):
		return _refuse("Guards can't use that.")
	var held: int = int(GameState.state["player"]["inventory"].get(recipe_key, {}).get(str(tier), 0))
	if held < qty:
		return _refuse("You don't have enough.")
	if not (owner.get(kit_field) is Dictionary):
		owner[kit_field] = {}
	var kit: Dictionary = owner[kit_field]
	if unit_count(kit) + qty > cap:
		return _refuse("The kit is full.")
	Crafting.inventory_remove_from_tier(recipe_key, tier, qty)
	if not (kit.get(recipe_key) is Dictionary):
		kit[recipe_key] = {}
	var buckets: Dictionary = kit[recipe_key]
	buckets[str(tier)] = int(buckets.get(str(tier), 0)) + qty
	return { "ok": true, "reason": "" }


# Kit-level return move on owner[kit_field], shared with the HQ kit. No emit.
static func unstock_from(owner: Dictionary, kit_field: String, recipe_key: String, tier: int, qty: int) -> Dictionary:
	if qty <= 0:
		return _refuse("Nothing to move.")
	var kit: Dictionary = owner.get(kit_field, {})
	var buckets: Dictionary = kit.get(recipe_key, {})
	var key := str(tier)
	var have: int = int(buckets.get(key, 0))
	if have < qty:
		return _refuse("The kit doesn't hold that many.")
	if have == qty:
		buckets.erase(key)
		if buckets.is_empty():
			kit.erase(recipe_key)
	else:
		buckets[key] = have - qty
	Crafting.inventory_add(recipe_key, tier, qty)
	return { "ok": true, "reason": "" }


static func _tiers_high_first(buckets: Dictionary) -> Array:
	var keys: Array = buckets.keys()
	keys.sort_custom(func(a, b): return int(a) > int(b))
	return keys


static func _target_vein(target: Dictionary) -> Variant:
	if target.get("kind", "") != "vein":
		return null
	return Cultivating.find_vein(target.get("veinId", ""))


static func _refuse(reason: String) -> Dictionary:
	return { "ok": false, "reason": reason }
