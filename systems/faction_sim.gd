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


# What a faction will sell: all its ore, but only its unreserved items, and
# nothing it is withholding (FactionAI escalation) or holding in the Conclave
# stabiliser stockpile (FactionAI.stockpile_held).
static func for_sale(faction_id: String, kind: String, item_type: String) -> int:
	if FactionAI.is_withholding(faction_id, kind, item_type):
		return 0
	var free: int = ore_held(faction_id, item_type) if kind == "ore" else item_held(faction_id, item_type) - item_reserved(faction_id, item_type)
	return maxi(0, free - FactionAI.stockpile_held(faction_id, kind, item_type))


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
# veins at factionPruneThreshold+, highest growth first -- except the
# maturing_vein(), left to grow until it levels up -- cutting
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

	var maturing: Variant = maturing_vein(veins)
	var spared: String = maturing["id"] if maturing != null else ""
	var to_prune: Array = veins.filter(func(v): return not acted.has(v["id"]) and v["id"] != spared and v["growth"] >= GameData.VEIN_GROWTH["factionPruneThreshold"])
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


# The one vein a faction leaves unpruned so it can grow past
# developmentThreshold and level up: of its veins below their level cap, the
# highest growth (tie: siteId). null once every vein is at its cap.
static func maturing_vein(veins: Array) -> Variant:
	var below_cap: Array = veins.filter(func(v): return int(v.get("level", 1)) < Cultivating.level_cap(v))
	if below_cap.is_empty():
		return null
	below_cap.sort_custom(func(a, b): return _growth_order(a, b, false))
	return below_cap[0]


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
	log_kit_burn_items(faction_id, kit, source, GameData.FACTIONS[faction_id].get("raidKits", {}).get(kit, {}))


# A partial burn: only `items` of the kit were spent (a defended raid bills
# just what its raiders used in combat).
static func log_kit_burn_items(faction_id: String, kit: String, source: String, items: Dictionary) -> void:
	if items.is_empty():
		return
	GameState.state["factions"][faction_id]["kitBurns"].append({
		"day": GameState.state["world"]["day"],
		"source": source,
		"kit": kit,
		"items": items.duplicate(),
	})


# The raider kit a defended raid's squad carries into combat: the faction's
# `kit` from raidKits, each item capped by what it holds (all tiers), with
# items it holds none of left out. `tier` is the faction's craftSkill, which
# sets item power the way the player's craftingSkill does.
static func raider_kit(faction_id: String, kit: String) -> Dictionary:
	var items := {}
	var wanted: Dictionary = GameData.FACTIONS[faction_id].get("raidKits", {}).get(kit, {})
	for recipe_key in wanted:
		var qty := mini(int(wanted[recipe_key]), item_held(faction_id, recipe_key))
		if qty > 0:
			items[recipe_key] = qty
	return { "tier": int(GameData.FACTIONS[faction_id].get("craftSkill", 1)), "items": items, "used": {} }


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
# vein first (Cultivating.value_order), each
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
	veins.sort_custom(Cultivating.value_order)
	for vein in veins:
		var kit := {}
		for recipe_key in defend:
			var qty: int = mini(int(defend[recipe_key]), unassigned[recipe_key])
			if qty > 0:
				kit[recipe_key] = qty
				unassigned[recipe_key] -= qty
		vein["kit"] = kit


# The kit a site's faction vein holds for defence; {} for no faction vein.
static func vein_kit(site_id: String) -> Dictionary:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return {}
	return site["factionVein"].get("kit", {})


# ── Buying and selling (spec §Buying and selling, §Faction cash) ──────────
# Rollover step after allocate_kits(). Per faction, with its factions.json
# `trading` knobs: every good held above its reserve sells ceil(surplus ×
# sellFraction) at the London quote (Market supply), except while the quote
# sits under minSellMult × base, when only stock above hardCap counts as
# surplus. Then every good below reserve is bought at the quote (Market
# demand, Shares London-buy tally), items before ores, while the quote ≤
# maxBuyMult × base and `resources` covers it -- partial buys allowed, never
# below £0. London is abstract: buys aren't limited by Market stock. Bought
# items file under tier "0". A faction whose `trading` carries arbBuyMult
# (the Conclave) then arbitrages -- see _arbitrage().
static func trade() -> void:
	for faction_id in GameData.FACTIONS:
		_trade_faction(faction_id)


# Ore kept back for crafting: per crafted item, its ingredient cost at
# craftSkill × (today's gap to target + the target's turnover over
# reserveDays at a week per target).
static func ore_reserve(faction_id: String, ore_type: String) -> int:
	var data: Dictionary = GameData.FACTIONS[faction_id]
	var reserve_days: float = float(data["trading"]["reserveDays"])
	var reserve := 0
	for recipe_key in data.get("crafts", []):
		var qty: int = int(Crafting.calc_cost(recipe_key, int(data["craftSkill"])).get(ore_type, 0))
		if qty <= 0:
			continue
		var target := craft_target(faction_id, recipe_key)
		var gap: int = maxi(0, target - item_held(faction_id, recipe_key))
		reserve += qty * (gap + ceili(target * reserve_days / 7.0))
	return reserve


# Items kept back: a week's `consumes` plus expected kit use -- craftTargets
# kitUse for a crafted item, else one attack plus one defend kit. The sell
# quota is not reserved: it is what crafting makes to sell.
static func item_reserve(faction_id: String, recipe_key: String) -> int:
	var data: Dictionary = GameData.FACTIONS[faction_id]
	var kit_use: int
	if data.get("craftTargets", {}).has(recipe_key):
		kit_use = int(data["craftTargets"][recipe_key].get("kitUse", 0))
	else:
		var kits: Dictionary = data.get("raidKits", {})
		kit_use = int(kits.get("attack", {}).get(recipe_key, 0)) + int(kits.get("defend", {}).get(recipe_key, 0))
	return int(data.get("consumes", {}).get(recipe_key, 0)) + kit_use


static func reserve(faction_id: String, kind: String, good_type: String) -> int:
	return ore_reserve(faction_id, good_type) if kind == "ore" else item_reserve(faction_id, good_type)


# Every good a faction deals in: all ore types, then every item it consumes,
# crafts, carries in a kit or holds.
static func _traded_goods(faction_id: String) -> Array:
	var data: Dictionary = GameData.FACTIONS[faction_id]
	var items: Array = []
	var sources: Array = [data.get("consumes", {}).keys(), data.get("crafts", [])]
	for kit in data.get("raidKits", {}).values():
		sources.append(kit.keys())
	sources.append(_holdings(faction_id)["items"].keys())
	for keys in sources:
		for recipe_key in keys:
			if not items.has(recipe_key):
				items.append(recipe_key)
	var goods: Array = []
	for recipe_key in items:
		goods.append({ "kind": "consumable", "type": recipe_key })
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		goods.append({ "kind": "ore", "type": ore_type })
	return goods


static func _trade_faction(faction_id: String) -> void:
	var goods := _traded_goods(faction_id)
	for good in goods:
		_sell_surplus(faction_id, good["kind"], good["type"])
	for good in goods:
		_buy_shortfall(faction_id, good["kind"], good["type"])
	if GameData.FACTIONS[faction_id]["trading"].has("arbBuyMult"):
		_arbitrage(faction_id)


static func _sell_surplus(faction_id: String, kind: String, good_type: String) -> void:
	var knobs: Dictionary = GameData.FACTIONS[faction_id]["trading"]
	var price: int = Market.quote(kind, good_type)
	if price <= 0:
		return
	var keep: int = reserve(faction_id, kind, good_type)
	if price < float(knobs["minSellMult"]) * Market.base_price(kind, good_type):
		keep = maxi(keep, int(knobs["hardCap"]["ore" if kind == "ore" else "item"]))
	var surplus: int = mini(held(faction_id, kind, good_type) - keep, for_sale(faction_id, kind, good_type))
	if surplus <= 0:
		return
	_sell(faction_id, kind, good_type, ceili(surplus * float(knobs["sellFraction"])), price)


static func _buy_shortfall(faction_id: String, kind: String, good_type: String) -> void:
	var knobs: Dictionary = GameData.FACTIONS[faction_id]["trading"]
	var price: int = Market.quote(kind, good_type)
	if price <= 0 or price > float(knobs["maxBuyMult"]) * Market.base_price(kind, good_type):
		return
	var faction: Dictionary = GameState.state["factions"][faction_id]
	var qty: int = mini(reserve(faction_id, kind, good_type) - held(faction_id, kind, good_type), Market.affordable_qty(kind, price, int(faction["resources"])))
	_buy(faction_id, kind, good_type, qty, price)


# A good the faction is withholding (FactionAI escalation) is never sold.
static func _sell(faction_id: String, kind: String, good_type: String, qty: int, price: int) -> void:
	if qty <= 0 or FactionAI.is_withholding(faction_id, kind, good_type):
		return
	if kind == "ore":
		take_ore(faction_id, good_type, qty)
	else:
		take_items(faction_id, good_type, qty)
	GameState.state["factions"][faction_id]["resources"] += Market.line_total(kind, price, qty)
	Market.record_supply(kind, good_type, qty, faction_id)


# Sells qty of an ore at price_mult × today's quote, below its value
# (R§3.1 "Escalation" flood), recorded as a Market flood. Returns the £ taken.
static func flood(faction_id: String, ore_type: String, qty: int, price_mult: float) -> int:
	return _sell_below(faction_id, "flood", "ore", ore_type, qty, price_mult)


# Sells qty of a good (ore or item) at price_mult × today's quote, under the
# target's price (R§3.1 "Escalation" undercut), recorded as a Market
# undercut. Returns the £ taken.
static func undercut(faction_id: String, kind: String, good_type: String, qty: int, price_mult: float) -> int:
	return _sell_below(faction_id, "undercut", kind, good_type, qty, price_mult)


static func _sell_below(faction_id: String, move: String, kind: String, good_type: String, qty: int, price_mult: float) -> int:
	if qty <= 0:
		return 0
	if kind == "ore":
		take_ore(faction_id, good_type, qty)
	else:
		take_items(faction_id, good_type, qty)
	var proceeds: int = Market.line_total(kind, GameState.round_epsilon(Market.quote(kind, good_type) * price_mult), qty)
	GameState.state["factions"][faction_id]["resources"] += proceeds
	Market.record_move(move, kind, good_type, qty, faction_id)
	return proceeds


# Buys up to qty of a good at today's quote, capped by resources (R§3.1
# "Escalation" deny), recorded as a Market deny. Returns the qty bought.
static func deny(faction_id: String, kind: String, good_type: String, qty: int) -> int:
	var price: int = Market.quote(kind, good_type)
	var bought: int = mini(qty, Market.affordable_qty(kind, price, int(GameState.state["factions"][faction_id]["resources"])))
	_buy(faction_id, kind, good_type, bought, price, "deny")
	return maxi(0, bought)


# Sells up to qty of a good the faction holds at price_mult × today's quote,
# into a spike (R§3.1 "Conclave stabiliser"), recorded as a Market
# stabiliseSell; nothing while it is withholding the good. The caller caps
# qty at the stockpile. Returns the qty sold.
static func stabilise_sell(faction_id: String, kind: String, good_type: String, qty: int, price_mult: float) -> int:
	if FactionAI.is_withholding(faction_id, kind, good_type):
		return 0
	var sold: int = mini(qty, held(faction_id, kind, good_type))
	if sold <= 0:
		return 0
	_sell_below(faction_id, "stabiliseSell", kind, good_type, sold, price_mult)
	return sold


# Buys up to qty of a good at price_mult × today's quote, capped by
# resources, out of a crash (R§3.1 "Conclave stabiliser"), recorded as a
# Market stabiliseBuy. Returns the qty bought.
static func stabilise_buy(faction_id: String, kind: String, good_type: String, qty: int, price_mult: float) -> int:
	var price: int = GameState.round_epsilon(Market.quote(kind, good_type) * price_mult)
	var bought: int = mini(qty, Market.affordable_qty(kind, price, int(GameState.state["factions"][faction_id]["resources"])))
	_buy(faction_id, kind, good_type, bought, price, "stabiliseBuy")
	return maxi(0, bought)


# Buys up to qty of a good at today's quote, spending at most budget, as
# plain Market demand (R§3.1 "Conclave stabiliser" top-up). Returns the qty
# bought.
static func stock_up(faction_id: String, kind: String, good_type: String, qty: int, budget: int) -> int:
	var price: int = Market.quote(kind, good_type)
	var bought: int = mini(qty, Market.affordable_qty(kind, price, budget))
	_buy(faction_id, kind, good_type, bought, price)
	return maxi(0, bought)


# move names a Market move ("deny", "stabiliseBuy") to record instead of plain demand.
static func _buy(faction_id: String, kind: String, good_type: String, qty: int, price: int, move: String = "") -> void:
	if qty <= 0:
		return
	GameState.state["factions"][faction_id]["resources"] -= Market.line_total(kind, price, qty)
	if kind == "ore":
		add_ore(faction_id, good_type, qty)
	else:
		add_item(faction_id, good_type, 0, qty)
	if move == "":
		Market.record_demand(kind, good_type, qty, faction_id)
	else:
		Market.record_move(move, kind, good_type, qty, faction_id)
	Shares.record_london_buy(faction_id, Shares.ore_equivalent(kind, good_type, qty))


# Arbitrage (spec §Buying and selling, Conclave arbitrage): after its own
# trading, sells what it holds above reserve of any good quoted over
# arbSellMult × base, dearest-relative-to-base first, then buys any London
# good quoted under arbBuyMult × base, cheapest-relative-to-base first. Sells
# and buys share one arbDailyVolume unit budget; buys are capped by
# `resources`.
static func _arbitrage(faction_id: String) -> void:
	var knobs: Dictionary = GameData.FACTIONS[faction_id]["trading"]
	var volume: int = int(knobs["arbDailyVolume"])
	var spiked: Array = []
	var crashed: Array = []
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			var base: int = Market.base_price(kind, good_type)
			var price: int = Market.quote(kind, good_type)
			if base <= 0 or price <= 0:
				continue
			var ratio: float = float(price) / base
			var good := { "kind": kind, "type": good_type, "price": price, "ratio": ratio }
			if ratio > float(knobs["arbSellMult"]):
				spiked.append(good)
			elif ratio < float(knobs["arbBuyMult"]):
				crashed.append(good)
	spiked.sort_custom(func(a, b): return a["ratio"] > b["ratio"])
	crashed.sort_custom(func(a, b): return a["ratio"] < b["ratio"])
	for good in spiked:
		var surplus: int = mini(held(faction_id, good["kind"], good["type"]) - reserve(faction_id, good["kind"], good["type"]), for_sale(faction_id, good["kind"], good["type"]))
		var qty: int = mini(surplus, volume)
		if qty > 0:
			_sell(faction_id, good["kind"], good["type"], qty, good["price"])
			volume -= qty
	for good in crashed:
		var qty: int = mini(volume, Market.affordable_qty(good["kind"], good["price"], int(GameState.state["factions"][faction_id]["resources"])))
		if qty > 0:
			_buy(faction_id, good["kind"], good["type"], qty, good["price"])
			volume -= qty


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
