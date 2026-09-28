class_name FactionSim
extends RefCounted

# Faction holdings: the real stock every faction shop sells from and buys
# into (spec biz-act2-faction-economy §Faction shops, §State). Static funcs
# over GameState.state; touches no Nodes.
#
# factions[id].holdings = { "ore": { oreType: int }, "items": { recipeKey: { "<tier>": int } } }
# Item tier keys are stringified like player.inventory; absent = 0.


static func new_holdings() -> Dictionary:
	return { "ore": {}, "items": {} }


# Placeholder starting stock from factions.json `startingHoldings`; items
# file under tier "0" (no known quality), the same bucket as store stock.
static func starting_holdings(faction_id: String) -> Dictionary:
	var holdings := new_holdings()
	var seed: Dictionary = GameData.FACTIONS[faction_id].get("startingHoldings", {})
	for ore_type in seed.get("ore", {}):
		holdings["ore"][ore_type] = int(seed["ore"][ore_type])
	for recipe_key in seed.get("items", {}):
		holdings["items"][recipe_key] = { "0": int(seed["items"][recipe_key]) }
	return holdings


static func _holdings(faction_id: String) -> Dictionary:
	return GameState.state["factions"][faction_id]["holdings"]


static func ore_held(faction_id: String, ore_type: String) -> int:
	return int(_holdings(faction_id)["ore"].get(ore_type, 0))


static func item_held(faction_id: String, recipe_key: String) -> int:
	var total := 0
	for count in _holdings(faction_id)["items"].get(recipe_key, {}).values():
		total += int(count)
	return total


static func held(faction_id: String, kind: String, item_type: String) -> int:
	return ore_held(faction_id, item_type) if kind == "ore" else item_held(faction_id, item_type)


static func add_ore(faction_id: String, ore_type: String, qty: int) -> void:
	var ore: Dictionary = _holdings(faction_id)["ore"]
	ore[ore_type] = int(ore.get(ore_type, 0)) + qty


# Clamps at zero; callers check ore_held() first.
static func take_ore(faction_id: String, ore_type: String, qty: int) -> void:
	var ore: Dictionary = _holdings(faction_id)["ore"]
	ore[ore_type] = maxi(0, int(ore.get(ore_type, 0)) - qty)


static func add_item(faction_id: String, recipe_key: String, tier: int, qty: int) -> void:
	var items: Dictionary = _holdings(faction_id)["items"]
	if not (items.get(recipe_key) is Dictionary):
		items[recipe_key] = {}
	var buckets: Dictionary = items[recipe_key]
	var key := str(tier)
	buckets[key] = int(buckets.get(key, 0)) + qty


# Removes up to qty, highest tier first (§Ticketing decisions "Item tier").
# Returns what came out as [{ tier:int, qty:int }, ...], highest tier first.
static func take_items(faction_id: String, recipe_key: String, qty: int) -> Array:
	var buckets: Dictionary = _holdings(faction_id)["items"].get(recipe_key, {})
	var tier_keys: Array = buckets.keys()
	tier_keys.sort_custom(func(a, b): return int(a) > int(b))
	var taken: Array = []
	var remaining := qty
	for tier_key in tier_keys:
		if remaining <= 0:
			break
		var take: int = mini(int(buckets[tier_key]), remaining)
		if take <= 0:
			continue
		buckets[tier_key] = int(buckets[tier_key]) - take
		remaining -= take
		taken.append({ "tier": int(tier_key), "qty": take })
	for tier_key in buckets.keys().duplicate():
		if int(buckets[tier_key]) <= 0:
			buckets.erase(tier_key)
	return taken


# Districts whose factionPresence is this faction, in GameData.DISTRICTS order.
static func home_districts(faction_id: String) -> Array:
	var homes: Array = []
	for district_id in GameData.DISTRICTS:
		if GameData.DISTRICTS[district_id].get("factionPresence", "") == faction_id:
			homes.append(district_id)
	return homes


# Where a faction keeps its holdings (spec §Stockpile location): a home
# district plus a factions.json `stockpilePlaces` name, both drawn from the
# seeded Rng once per save. revealedTo lists observer ids who know the spot.
static func pick_stockpile(faction_id: String) -> Dictionary:
	var homes := home_districts(faction_id)
	var places: Array = GameData.FACTIONS[faction_id].get("stockpilePlaces", [])
	return {
		"district": Rng.rand_from(homes) if not homes.is_empty() else "",
		"place": Rng.rand_from(places) if not places.is_empty() else "",
		"revealedTo": [],
	}
