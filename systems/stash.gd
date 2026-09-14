class_name Stash
extends RefCounted

# day-rhythm-business-and-combat ticket 22, business-spec.md "Inventory":
# the personal stash -- a second ore/crafted-item pool no business system
# (contracts, Sales, Production, Procurement) can touch. Moving stock in
# subtracts it from player.orichalchum/player.inventory -- the same pool
# every other system reads -- so a stashed unit is automatically invisible
# to those systems without any of them needing to know the stash exists.
# It's a transfer destination, not a second view onto the same numbers, and
# the sole reserve mechanism (no other per-item reserve flag exists). Every
# move is instant and reversible: no time cost, clamped to whatever's
# actually available rather than erroring on an over-large request.


static func stashed_ore_qty(ore_type: String) -> int:
	return int(GameState.state["player"]["stash"]["orichalchum"].get(ore_type, 0))


static func stashed_item_qty(recipe_key: String) -> int:
	var buckets: Dictionary = GameState.state["player"]["stash"]["inventory"].get(recipe_key, {})
	var total := 0
	for tier_key in buckets:
		total += int(buckets[tier_key])
	return total


static func move_ore_to_stash(ore_type: String, qty: int) -> void:
	_move_ore(GameState.state["player"]["orichalchum"], GameState.state["player"]["stash"]["orichalchum"], ore_type, qty)


static func move_ore_to_shared(ore_type: String, qty: int) -> void:
	_move_ore(GameState.state["player"]["stash"]["orichalchum"], GameState.state["player"]["orichalchum"], ore_type, qty)


static func _move_ore(source: Dictionary, dest: Dictionary, ore_type: String, qty: int) -> void:
	var take: int = mini(maxi(qty, 0), int(source.get(ore_type, 0)))
	if take <= 0:
		return
	source[ore_type] = int(source.get(ore_type, 0)) - take
	dest[ore_type] = int(dest.get(ore_type, 0)) + take
	EventBus.state_changed.emit()


static func move_item_to_stash(recipe_key: String, qty: int) -> void:
	_move_item(GameState.state["player"]["inventory"], GameState.state["player"]["stash"]["inventory"], recipe_key, qty)


static func move_item_to_shared(recipe_key: String, qty: int) -> void:
	_move_item(GameState.state["player"]["stash"]["inventory"], GameState.state["player"]["inventory"], recipe_key, qty)


# Tier-preserving move, lowest-tier-first -- same policy Crafting.
# inventory_remove uses for every other tier-indifferent consumer -- so a
# unit that later returns to shared stock still carries the exact quality
# it was stashed at (Economy prices a sale by tier; the stash must never
# quietly launder that away).
static func _move_item(source: Dictionary, dest: Dictionary, recipe_key: String, qty: int) -> void:
	var buckets: Dictionary = source.get(recipe_key, {})
	if buckets.is_empty() or qty <= 0:
		return
	var remaining: int = qty
	var tier_keys: Array = buckets.keys()
	tier_keys.sort_custom(func(a, b): return int(a) < int(b))
	var moved := false
	for tier_key in tier_keys:
		if remaining <= 0:
			break
		var have: int = buckets[tier_key]
		var take: int = mini(have, remaining)
		if take <= 0:
			continue
		buckets[tier_key] = have - take
		remaining -= take
		if not (dest.get(recipe_key) is Dictionary):
			dest[recipe_key] = {}
		var dest_buckets: Dictionary = dest[recipe_key]
		dest_buckets[tier_key] = dest_buckets.get(tier_key, 0) + take
		moved = true
	for tier_key in buckets.keys().duplicate():
		if buckets[tier_key] <= 0:
			buckets.erase(tier_key)
	if moved:
		EventBus.state_changed.emit()


# Transient per-row move-qty stepper (state.stashQty, not restored on load)
# -- one shared qty per row for both that row's stash/unstash button, same
# convention as Economy.get_marketplace_qty/adjust_marketplace_qty.
static func get_ore_move_qty(ore_type: String) -> int:
	return int(GameState.state["stashQty"].get("ore_%s" % ore_type, 1))


static func adjust_ore_move_qty(ore_type: String, delta: int, max_qty: int) -> void:
	var key := "ore_%s" % ore_type
	var current: int = clampi(get_ore_move_qty(ore_type), 1, maxi(max_qty, 1))
	GameState.state["stashQty"][key] = clampi(current + delta, 1, maxi(max_qty, 1))
	EventBus.state_changed.emit()


static func get_item_move_qty(recipe_key: String) -> int:
	return int(GameState.state["stashQty"].get("item_%s" % recipe_key, 1))


static func adjust_item_move_qty(recipe_key: String, delta: int, max_qty: int) -> void:
	var key := "item_%s" % recipe_key
	var current: int = clampi(get_item_move_qty(recipe_key), 1, maxi(max_qty, 1))
	GameState.state["stashQty"][key] = clampi(current + delta, 1, maxi(max_qty, 1))
	EventBus.state_changed.emit()
