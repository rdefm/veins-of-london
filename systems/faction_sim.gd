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


# ── Vein tending and pruning (spec §Vein tending and pruning) ────────────
# Rollover step: each faction spends fieldwork.actionsPerBlock ×
# BLOCKS_PER_DAY actions, at most one per vein. Tends go first, to veins
# at/under fieldwork.tendAtOrBelow, lowest growth first (a vein parked at
# neutral never drifts, so 50 still needs a tend): a get_cult_chance roll at
# cultivateSkill, then the player's cultivate gain. Leftover actions prune
# veins at factionPruneThreshold+, highest growth first, cutting
# cultivate_max_gain × pruneDepthMult but never below pruneFloor; the
# player's prune yield lands in holdings and the faction's ore share.
static func tend_and_prune() -> void:
	var veins_by_faction := {}
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null:
			continue
		if not veins_by_faction.has(vein["factionId"]):
			veins_by_faction[vein["factionId"]] = []
		veins_by_faction[vein["factionId"]].append(vein)
	for faction_id in GameData.FACTIONS:
		_tend_and_prune_faction(faction_id, veins_by_faction.get(faction_id, []))


static func _tend_and_prune_faction(faction_id: String, veins: Array) -> void:
	var data: Dictionary = GameData.FACTIONS[faction_id]
	var fieldwork: Dictionary = data["fieldwork"]
	var skill: int = data["cultivateSkill"]
	var budget: int = int(fieldwork["actionsPerBlock"]) * TimeSystem.BLOCKS_PER_DAY
	var acted := {}

	var to_tend: Array = veins.filter(func(v): return v["growth"] <= fieldwork["tendAtOrBelow"])
	to_tend.sort_custom(func(a, b): return _growth_order(a, b, true))
	for vein in to_tend:
		if budget <= 0:
			return
		budget -= 1
		acted[vein["id"]] = true
		if Rng.chance(Cultivating.get_cult_chance(skill)):
			_tend(vein, skill)

	var to_prune: Array = veins.filter(func(v): return not acted.has(v["id"]) and v["growth"] >= GameData.VEIN_GROWTH["factionPruneThreshold"])
	to_prune.sort_custom(func(a, b): return _growth_order(a, b, false))
	var max_depth: int = Cultivating.cultivate_max_gain(skill) * int(fieldwork["pruneDepthMult"])
	for vein in to_prune:
		if budget <= 0:
			return
		var depth: int = mini(max_depth, vein["growth"] - int(fieldwork["pruneFloor"]))
		if depth <= 0:
			continue
		budget -= 1
		_prune(faction_id, vein, depth)


# Ties break on siteId so the order never depends on site-list position.
static func _growth_order(a: Dictionary, b: Dictionary, ascending: bool) -> bool:
	if a["growth"] != b["growth"]:
		return a["growth"] < b["growth"] if ascending else a["growth"] > b["growth"]
	return str(a.get("siteId", "")) < str(b.get("siteId", ""))


static func _tend(vein: Dictionary, skill: int) -> void:
	var vein_ceiling: int = Cultivating.ceiling(vein)
	var growth_before: int = vein["growth"]
	vein["growth"] = clampi(growth_before + Cultivating.cultivate_gain(skill, growth_before, vein_ceiling), 0, vein_ceiling)
	if vein["growth"] < vein_ceiling:
		vein["rampantDays"] = 0
	Cultivating.apply_growth_change(vein, growth_before)


static func _prune(faction_id: String, vein: Dictionary, depth: int) -> void:
	var amount: int = Cultivating.prune_yield(vein, depth)
	var growth_before: int = vein["growth"]
	vein["growth"] = Cultivating.prune_resulting_growth(vein, depth)
	vein["rampantDays"] = 0
	Cultivating.apply_growth_change(vein, growth_before)
	add_ore(faction_id, vein["oreType"], amount)
	Shares.record_ore(faction_id, vein["oreType"], amount)


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
