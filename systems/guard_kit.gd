class_name GuardKit
extends RefCounted

# Combat consumables stocked for a player vein's guards (guard-kit spec
# §State/§Capacity/§Stocking system). vein.guardKit has player.inventory's
# tier-bucketed shape: { recipeKey: { "<tier>": count } }. The kit-dict
# helpers (capacity_of, unit_count, active_units_of) take a guard count and
# slots-per-guard so the HQ kit shares them. home.guardKit is the HQ kit
# (spec §HQ guard kit), sized by Home.get_guard_count() × hqSlotsPerGuard.


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


static func hq_capacity() -> int:
	return capacity_of(Home.get_guard_count(), int(GameData.GUARD_KIT["hqSlotsPerGuard"]))


static func hq_active_units() -> Dictionary:
	return active_units_of(GameState.state["home"].get("guardKit", {}), Home.get_guard_count(), int(GameData.GUARD_KIT["hqSlotsPerGuard"]))


# stock() for the HQ kit: refused with 0 HQ guards or over capacity.
static func stock_hq(recipe_key: String, tier: int, qty: int) -> Dictionary:
	if Home.get_guard_count() <= 0:
		return _refuse("No guards at HQ.")
	var result := stock_into(GameState.state["home"], "guardKit", hq_capacity(), recipe_key, tier, qty)
	if result["ok"]:
		EventBus.state_changed.emit()
	return result


# unstock() for the HQ kit: allowed over capacity and with 0 HQ guards.
static func unstock_hq(recipe_key: String, tier: int, qty: int) -> Dictionary:
	var result := unstock_from(GameState.state["home"], "guardKit", recipe_key, tier, qty)
	if result["ok"]:
		EventBus.state_changed.emit()
	return result


# Player veins the HQ Guard Kit screen lists: 1+ guards or a non-empty kit.
static func kit_veins() -> Array:
	return GameState.state["player"]["veins"].filter(func(v):
		return Cultivating.vein_guard_count(v) > 0 or unit_count(v.get("guardKit", {})) > 0)


# A kit target names one kit for shared UI (the stocking sheet):
# { "kind": "vein", "veinId": id } or { "kind": "hq" }. Unknown targets read
# as an empty, 0-capacity kit and refuse every move.
static func target_kit(target: Dictionary) -> Dictionary:
	if _is_hq(target):
		return GameState.state["home"].get("guardKit", {})
	var vein = _target_vein(target)
	return vein.get("guardKit", {}) if vein != null else {}


static func target_capacity(target: Dictionary) -> int:
	if _is_hq(target):
		return hq_capacity()
	var vein = _target_vein(target)
	return capacity(vein) if vein != null else 0


static func target_guard_count(target: Dictionary) -> int:
	if _is_hq(target):
		return Home.get_guard_count()
	var vein = _target_vein(target)
	return Cultivating.vein_guard_count(vein) if vein != null else 0


static func target_name(target: Dictionary) -> String:
	if _is_hq(target):
		return "HQ"
	var vein = _target_vein(target)
	if vein == null:
		return ""
	return "%s · %s" % [GameData.DISTRICTS[vein["district"]]["name"], GameData.ORE_TYPES[vein["oreType"]]["name"]]


static func stock_target(target: Dictionary, recipe_key: String, tier: int, qty: int) -> Dictionary:
	if target.get("kind", "") == "vein":
		return stock(target.get("veinId", ""), recipe_key, tier, qty)
	if _is_hq(target):
		return stock_hq(recipe_key, tier, qty)
	return _refuse("No such kit.")


static func unstock_target(target: Dictionary, recipe_key: String, tier: int, qty: int) -> Dictionary:
	if target.get("kind", "") == "vein":
		return unstock(target.get("veinId", ""), recipe_key, tier, qty)
	if _is_hq(target):
		return unstock_hq(recipe_key, tier, qty)
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


# Vein leaving the player other than by raid claim (spec §Loss): the whole
# kit, active or not, returns to player.inventory at its tiers. No emit.
static func return_kit_to_inventory(vein: Dictionary) -> void:
	var kit: Dictionary = vein.get("guardKit", {})
	for recipe_key in kit:
		for tier_key in kit[recipe_key]:
			Crafting.inventory_add(recipe_key, int(tier_key), int(kit[recipe_key][tier_key]))
	vein["guardKit"] = {}


# Raid claim (spec §Loss): the whole kit moves into faction_id's
# holdings.items at its tiers. Returns whether the kit held anything. No emit.
static func hand_kit_to_faction(vein: Dictionary, faction_id: String) -> bool:
	var kit: Dictionary = vein.get("guardKit", {})
	var had_units := unit_count(kit) > 0
	for recipe_key in kit:
		for tier_key in kit[recipe_key]:
			FactionSim.add_item(faction_id, recipe_key, int(tier_key), int(kit[recipe_key][tier_key]))
	vein["guardKit"] = {}
	return had_units


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


# Repel chance with kit (spec §Not defending — repel boost): base plus each
# active item type's repelBonus strength once, capped at guardKit.repelCap
# with 1+ active unit, else guardRepel.cap. Shared with the HQ kit.
static func repel_chance_with(base_chance: float, active: Dictionary) -> float:
	var bonus := 0.0
	for recipe_key in active:
		if unit_count({ recipe_key: active[recipe_key] }) > 0:
			bonus += float(GameData.GUARD_KIT["repelBonus"][GameData.GUARD_KIT["repelTier"][recipe_key]])
	var cap: float = float(GameData.GUARD_KIT["repelCap"]) if unit_count(active) > 0 else GameData.GUARD_REPEL_CHANCE_CAP
	return minf(base_chance + bonus, cap)


# Uses up one unit of each active item type from kit, highest active tier
# first, in allowlist order. Returns the recipe keys used. No emit.
static func spend_repel_units(kit: Dictionary, active: Dictionary) -> Array:
	var used: Array = []
	for recipe_key in GameData.GUARD_KIT["items"]:
		var active_buckets: Dictionary = active.get(recipe_key, {})
		for tier_key in _tiers_high_first(active_buckets):
			if int(active_buckets[tier_key]) <= 0:
				continue
			var buckets: Dictionary = kit[recipe_key]
			var left := int(buckets[tier_key]) - 1
			if left > 0:
				buckets[tier_key] = left
			else:
				buckets.erase(tier_key)
				if buckets.is_empty():
					kit.erase(recipe_key)
			used.append(recipe_key)
			break
	return used


# "a shield, a blast and a black hole" for the repel notification suffix.
static func used_items_text(recipe_keys: Array) -> String:
	var parts: PackedStringArray = []
	for recipe_key in recipe_keys:
		var item_name: String = GameData.RECIPES[recipe_key]["name"].to_lower()
		parts.append(("an " if "aeiou".contains(item_name[0]) else "a ") + item_name)
	if parts.size() <= 1:
		return "".join(parts)
	return ", ".join(parts.slice(0, parts.size() - 1)) + " and " + parts[parts.size() - 1]


# The highest tier key held in a { "<tier>": count } bucket dict, "" if empty.
static func highest_tier_key(buckets: Dictionary) -> String:
	for tier_key in _tiers_high_first(buckets):
		if int(buckets[tier_key]) > 0:
			return str(tier_key)
	return ""


# Takes `units` (kit-shaped) off kit, clamped at what the kit holds; emptied
# tiers and recipes are erased. A fight's used units come off this way. No emit.
static func remove_units(kit: Dictionary, units: Dictionary) -> void:
	for recipe_key in units:
		var buckets: Dictionary = kit.get(recipe_key, {})
		for tier_key in units[recipe_key]:
			var left := int(buckets.get(tier_key, 0)) - int(units[recipe_key][tier_key])
			if left > 0:
				buckets[tier_key] = left
			else:
				buckets.erase(tier_key)
		if buckets.is_empty():
			kit.erase(recipe_key)


# Per-recipe unit totals of a kit-shaped dict, e.g. { "blast": 3 }.
static func recipe_totals(units: Dictionary) -> Dictionary:
	var totals := {}
	for recipe_key in units:
		var count := unit_count({ recipe_key: units[recipe_key] })
		if count > 0:
			totals[recipe_key] = count
	return totals


# Per-recipe totals of a recipe-key list (one unit each), e.g. a repel's used list.
static func recipe_totals_of_list(recipe_keys: Array) -> Dictionary:
	var totals := {}
	for recipe_key in recipe_keys:
		totals[recipe_key] = int(totals.get(recipe_key, 0)) + 1
	return totals


# Restocks `kit` after a defence: for each spent recipe, moves up to the spent
# count from player.inventory (highest tier first) while the kit holds fewer
# than `cap` units. Unspent recipes and spare capacity are never filled. No emit.
static func refill_kit(kit: Dictionary, spent: Dictionary, cap: int) -> void:
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	for recipe_key in GameData.GUARD_KIT["items"]:
		var want := int(spent.get(recipe_key, 0))
		var held: Dictionary = inventory.get(recipe_key, {})
		for tier_key in _tiers_high_first(held):
			var take := mini(mini(want, int(held[tier_key])), cap - unit_count(kit))
			if take <= 0:
				break
			Crafting.inventory_remove_from_tier(recipe_key, int(tier_key), take)
			if not (kit.get(recipe_key) is Dictionary):
				kit[recipe_key] = {}
			kit[recipe_key][tier_key] = int(kit[recipe_key].get(tier_key, 0)) + take
			want -= take


static func refill_vein(vein: Dictionary, spent: Dictionary) -> void:
	if not (vein.get("guardKit") is Dictionary):
		vein["guardKit"] = {}
	refill_kit(vein["guardKit"], spent, capacity(vein))


static func refill_hq(spent: Dictionary) -> void:
	var home: Dictionary = GameState.state["home"]
	if not (home.get("guardKit") is Dictionary):
		home["guardKit"] = {}
	refill_kit(home["guardKit"], spent, hq_capacity())


# Brings the HQ kit down to capacity: keeps the highest tiers (equal tiers in
# allowlist order), returns the rest to `inventory` (player.inventory shape).
# Units conserved. Takes dicts so the save migration can call it. No emit.
static func return_overflow(kit: Dictionary, cap: int, inventory: Dictionary) -> void:
	var over := unit_count(kit) - cap
	if over <= 0:
		return
	var entries: Array = []
	var order: Array = GameData.GUARD_KIT["items"]
	for recipe_key in kit:
		for tier_key in kit[recipe_key]:
			entries.append({ "recipe": recipe_key, "tier": tier_key, "order": order.find(recipe_key) })
	entries.sort_custom(func(a, b):
		if int(a["tier"]) != int(b["tier"]):
			return int(a["tier"]) < int(b["tier"])
		return a["order"] > b["order"])
	var returned := {}
	for entry in entries:
		if over <= 0:
			break
		var take := mini(int(kit[entry["recipe"]][entry["tier"]]), over)
		if not returned.has(entry["recipe"]):
			returned[entry["recipe"]] = {}
		returned[entry["recipe"]][entry["tier"]] = take
		if not (inventory.get(entry["recipe"]) is Dictionary):
			inventory[entry["recipe"]] = {}
		var held: Dictionary = inventory[entry["recipe"]]
		held[entry["tier"]] = int(held.get(entry["tier"], 0)) + take
		over -= take
	remove_units(kit, returned)


static func _tiers_high_first(buckets: Dictionary) -> Array:
	var keys: Array = buckets.keys()
	keys.sort_custom(func(a, b): return int(a) > int(b))
	return keys


static func _is_hq(target: Dictionary) -> bool:
	return target.get("kind", "") == "hq"


static func _target_vein(target: Dictionary) -> Variant:
	if target.get("kind", "") != "vein":
		return null
	return Cultivating.find_vein(target.get("veinId", ""))


static func _refuse(reason: String) -> Dictionary:
	return { "ok": false, "reason": reason }
