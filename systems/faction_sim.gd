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


# Items assigned to this faction's vein kits (allocate_kits); reserved from
# everyday consumption and shop sales, spent only by kit burns.
static func item_reserved(faction_id: String, recipe_key: String) -> int:
	var total := 0
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein != null and vein["factionId"] == faction_id:
			total += int(vein.get("kit", {}).get(recipe_key, 0))
	return total


# What a faction will sell: all its ore, but only its unreserved items.
static func for_sale(faction_id: String, kind: String, item_type: String) -> int:
	if kind == "ore":
		return ore_held(faction_id, item_type)
	return maxi(0, item_held(faction_id, item_type) - item_reserved(faction_id, item_type))


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


# ── Crafting toward target (spec §Crafting) ───────────────────────────────
# Target holding per crafted item = weekly `consumes` + craftTargets kitUse
# + sellQuota. Rollover step: each faction walks its `crafts` in data order
# and makes up to (target − held) attempts per item, stopping when its ore
# can't cover calc_cost at craftSkill. Every attempt spends its ore; a
# success (faction_craft_chance at craftSkill) files one item at tier
# craftSkill and credits the faction's crafting share by ingredient weight.
static func craft_target(faction_id: String, recipe_key: String) -> int:
	var data: Dictionary = GameData.FACTIONS[faction_id]
	var split: Dictionary = data.get("craftTargets", {}).get(recipe_key, {})
	return int(data.get("consumes", {}).get(recipe_key, 0)) + int(split.get("kitUse", 0)) + int(split.get("sellQuota", 0))


static func craft() -> void:
	for faction_id in GameData.FACTIONS:
		for recipe_key in GameData.FACTIONS[faction_id].get("crafts", []):
			_craft_toward_target(faction_id, recipe_key)


static func _craft_toward_target(faction_id: String, recipe_key: String) -> void:
	var skill: int = GameData.FACTIONS[faction_id]["craftSkill"]
	var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
	var gap: int = craft_target(faction_id, recipe_key) - item_held(faction_id, recipe_key)
	for i in gap:
		if not _can_cover(faction_id, costs):
			return
		for ore_type in costs:
			take_ore(faction_id, ore_type, costs[ore_type])
		if Rng.chance(Crafting.faction_craft_chance(recipe_key, skill)):
			add_item(faction_id, recipe_key, skill, 1)
			Shares.record_craft(faction_id, costs)


static func _can_cover(faction_id: String, costs: Dictionary) -> bool:
	for ore_type in costs:
		if ore_held(faction_id, ore_type) < int(costs[ore_type]):
			return false
	return true


# ── Consumption and kit burns (spec §Consumption) ─────────────────────────
# Fights log the raid kit they used (factions.json `raidKits`) into
# factions[id].kitBurns: [{ day, source, kit, items: { recipeKey: qty } }].
# consume() is the rollover step that applies them: each `consumes` item
# draws weekly × Barometer item-demand ÷ 7 a day (fractions carry in
# consumeAccrued as integer CONSUME_UNITs of an item, so the carry survives
# a JSON save and a week's draws sum to the weekly amount), plus every
# logged burn. Burns come out of holdings first, capped by what's held; a
# defend burn also frees that much of the vein-kit reserve (item_reserved).
# Daily draws then take only unreserved stock, so an unfought vein's kit
# never needs topping up. Whatever went uncovered is today's shortfall.
const CONSUME_UNIT := 1000


static func log_kit_burn(faction_id: String, kit: String, source: String) -> void:
	var items: Dictionary = GameData.FACTIONS[faction_id].get("raidKits", {}).get(kit, {})
	if items.is_empty():
		return
	GameState.state["factions"][faction_id]["kitBurns"].append({
		"day": GameState.state["world"]["day"],
		"source": source,
		"kit": kit,
		"items": items.duplicate(),
	})


static func consume() -> void:
	for faction_id in GameData.FACTIONS:
		_consume_faction(faction_id)


static func _consume_faction(faction_id: String) -> void:
	var faction: Dictionary = GameState.state["factions"][faction_id]
	var accrued: Dictionary = faction["consumeAccrued"]
	var draws := {}
	var consumes: Dictionary = GameData.FACTIONS[faction_id].get("consumes", {})
	for recipe_key in consumes:
		var owed: int = int(accrued.get(recipe_key, 0)) + roundi(float(consumes[recipe_key]) * Barometer.get_item_demand_mult(recipe_key) * CONSUME_UNIT / 7.0)
		draws[recipe_key] = owed / CONSUME_UNIT
		accrued[recipe_key] = owed % CONSUME_UNIT
	var burns := {}
	var defend_burns := {}
	for burn in faction["kitBurns"]:
		for recipe_key in burn["items"]:
			var qty := int(burn["items"][recipe_key])
			burns[recipe_key] = int(burns.get(recipe_key, 0)) + qty
			if burn["kit"] == "defend":
				defend_burns[recipe_key] = int(defend_burns.get(recipe_key, 0)) + qty
	faction["kitBurns"] = []

	var shortfall := {}
	var keys: Array = draws.keys()
	for recipe_key in burns:
		if not keys.has(recipe_key):
			keys.append(recipe_key)
	for recipe_key in keys:
		var burn_need := int(burns.get(recipe_key, 0))
		var short := burn_need - _taken_qty(take_items(faction_id, recipe_key, burn_need))
		var reserved := maxi(0, item_reserved(faction_id, recipe_key) - int(defend_burns.get(recipe_key, 0)))
		var free := maxi(0, item_held(faction_id, recipe_key) - reserved)
		var draw := int(draws.get(recipe_key, 0))
		short += draw - _taken_qty(take_items(faction_id, recipe_key, mini(draw, free)))
		if short > 0:
			shortfall[recipe_key] = short
	faction["shortfall"] = shortfall


static func _taken_qty(parts: Array) -> int:
	var taken := 0
	for part in parts:
		taken += int(part["qty"])
	return taken


# ── Per-vein kit allocation (spec §Per-vein kit allocation) ───────────────
# Rollover step after consume(): each faction assigns its held `defend` kit
# items (factions.json `raidKits.defend`) to its veins' guards, most valuable
# vein first (Cultivating.combined_magnitude, ties by siteId ascending), each
# vein taking up to one defend kit per item from what's still unassigned. A
# short faction's least valuable veins go without first. The allocation is a
# record on factionVein.kit = { recipeKey: qty } (items it has, absent = 0);
# holdings are not reduced. Hidden from the player; read via vein_kit().
static func allocate_kits() -> void:
	allocate_kits_in(GameState.state)


# Works on any state-shaped Dictionary so SaveManager can backfill a raw save.
static func allocate_kits_in(state: Dictionary) -> void:
	var veins_by_faction := {}
	for site in state["world"]["sites"]:
		var vein: Variant = site.get("factionVein")
		if vein == null:
			continue
		if not veins_by_faction.has(vein["factionId"]):
			veins_by_faction[vein["factionId"]] = []
		veins_by_faction[vein["factionId"]].append(vein)
	for faction_id in veins_by_faction:
		if not GameData.FACTIONS.has(faction_id) or not state["factions"].has(faction_id):
			continue
		_allocate_faction_kits(faction_id, state["factions"][faction_id]["holdings"], veins_by_faction[faction_id])


static func _allocate_faction_kits(faction_id: String, holdings: Dictionary, veins: Array) -> void:
	var defend: Dictionary = GameData.FACTIONS[faction_id].get("raidKits", {}).get("defend", {})
	var unassigned := {}
	for recipe_key in defend:
		var total := 0
		for count in holdings["items"].get(recipe_key, {}).values():
			total += int(count)
		unassigned[recipe_key] = total
	veins.sort_custom(_value_order)
	for vein in veins:
		var kit := {}
		for recipe_key in defend:
			var qty: int = mini(int(defend[recipe_key]), unassigned[recipe_key])
			if qty > 0:
				kit[recipe_key] = qty
				unassigned[recipe_key] -= qty
		vein["kit"] = kit


static func _value_order(a: Dictionary, b: Dictionary) -> bool:
	var value_a := Cultivating.combined_magnitude(a)
	var value_b := Cultivating.combined_magnitude(b)
	if value_a != value_b:
		return value_a > value_b
	return str(a.get("siteId", "")) < str(b.get("siteId", ""))


# The kit a site's faction vein holds for defence; {} for no faction vein.
static func vein_kit(site_id: String) -> Dictionary:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return {}
	return site["factionVein"].get("kit", {})


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
