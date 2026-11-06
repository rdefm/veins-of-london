class_name Market
extends RefCounted

# London market (R§3.13): one price per good -- kind "ore" (the five ore
# types) or "consumable" (every recipe key) -- repriced each rollover from
# London's stock. Items hold stock per tier 1..5, ore is untiered; stock moves
# only through recorded and nameless flows. Sales execute at today's quote;
# recorded supply and demand move tomorrow's price. Static funcs only.

const KINDS := ["consumable", "ore"]  # reprice order: items before ores


static func _config() -> Dictionary:
	return GameData.MARKET


static func _market() -> Dictionary:
	return GameState.state["market"]


static func base_price(kind: String, good_type: String) -> int:
	if kind == "ore":
		return int(GameData.ORE_TYPES[good_type]["basePrice"])
	return int(GameData.CONSUMABLE_PRICES.get(good_type, 0))


static func _normal_stock(kind: String, good_type: String) -> float:
	return float(_config()["goods"][kind][good_type]["normalStock"])


# London's daily civilian consumption of a good before any Ticker scaling;
# also the good's London volume for the Independents slice and annotation
# thresholds.
static func civilian_demand(kind: String, good_type: String) -> float:
	return float(_config()["goods"][kind][good_type]["civilianDemand"])


# The Independents slice (R§3.13): daily whole-unit supply of the kind's share
# (independentsOreShare for ore, independentsShare for items) × civilian
# demand, scaled by the good's price ratio (supplyElasticity) up to supplyCap;
# 0 when the kind's share is 0.
static func independents_supply(kind: String, good_type: String) -> float:
	var share := independents_share(kind)
	if share <= 0.0:
		return 0.0
	var cfg := _config()
	var mult := clampf(pow(_price_ratio(kind, good_type), float(cfg["supplyElasticity"])), 0.0, float(cfg["supplyCap"]))
	return float(GameState.round_epsilon(share * civilian_demand(kind, good_type) * mult))


# Today's quote over the good's base price (1.0 when it has none).
static func _price_ratio(kind: String, good_type: String) -> float:
	var base := float(base_price(kind, good_type))
	return float(quote(kind, good_type)) / base if base > 0.0 else 1.0


# Nameless demand multiplier: falls as price rises, between demandFloor and
# demandCeiling.
static func demand_mult(kind: String, good_type: String) -> float:
	var cfg := _config()
	return clampf(pow(_price_ratio(kind, good_type), -float(cfg["demandElasticity"])), float(cfg["demandFloor"]), float(cfg["demandCeiling"]))


static func independents_share(kind: String) -> float:
	return float(_config()["independentsOreShare" if kind == "ore" else "independentsShare"])


# The sim-start switch (market.json simStart): "day1" runs from the first
# day; "bizA2" waits until market.startedDay is set.
static func is_running() -> bool:
	return _config()["simStart"] == "day1" or _market().get("startedDay") != null


# Units one quoted price buys (market.json priceLot): ore is quoted per lot
# of 10, items per unit (R§3.13).
static func price_lot(kind: String) -> int:
	return int(_config()["priceLot"].get(kind, 1))


# £ for qty units of a good at a quoted price (per price_lot units).
static func line_total(kind: String, price: int, qty: int) -> int:
	return GameState.round_epsilon(float(price) * qty / price_lot(kind))


# The most whole units whose line_total() fits a budget; 0 at a price of 0
# or less.
static func affordable_qty(kind: String, price: int, budget: int) -> int:
	if price <= 0 or budget <= 0:
		return 0
	var qty := int(floor((float(budget) + 0.5) * price_lot(kind) / float(price)))
	while qty > 0 and line_total(kind, price, qty) > budget:
		qty -= 1
	return qty


# Pure: base × (stock / normalStock)^-curveExponent, clamped to
# [priceMinMult, priceMaxMult] × base.
static func target_price(kind: String, good_type: String, stock: float) -> int:
	var cfg := _config()
	var base := float(base_price(kind, good_type))
	var ratio: float = maxf(stock, 0.0) / _normal_stock(kind, good_type)
	var mult: float = cfg["priceMaxMult"]
	if ratio > 0.0:
		mult = clampf(pow(ratio, -float(cfg["curveExponent"])), cfg["priceMinMult"], cfg["priceMaxMult"])
	return GameState.round_epsilon(base * mult)


# Ore demand from item shortages (R§3.13): Σ over recipes of
# max(0, normalStock − itemStock) × that recipe's qty of this ore ×
# oreConversionRate. item_stocks is { recipeKey: stock }.
static func _derived_ore_demand(ore_type: String, item_stocks: Dictionary) -> float:
	var total := 0.0
	for recipe_key in item_stocks:
		var qty: int = int(GameData.RECIPES[recipe_key]["ingredients"].get(ore_type, 0))
		if qty > 0:
			total += maxf(0.0, _normal_stock("consumable", recipe_key) - float(item_stocks[recipe_key])) * qty
	return total * float(_config()["oreConversionRate"])


# Today's derived demand for an ore, from current item stocks.
static func derived_ore_demand(ore_type: String) -> float:
	var item_stocks := {}
	for recipe_key in _market()["goods"]["consumable"]:
		item_stocks[recipe_key] = _market()["goods"]["consumable"][recipe_key]["stock"]
	return _derived_ore_demand(ore_type, item_stocks)


# Current stock layout version; saves without it are migrated once.
const STOCK_SCHEMA := 2


# Whole-unit stock split across tiers by weights (largest remainder, ties to
# the lowest tier); the parts always sum to total.
static func _apportion(total: int, weights: Array) -> Array[int]:
	var parts: Array[int] = []
	parts.resize(weights.size())
	parts.fill(0)
	var weight_sum := 0.0
	for w in weights:
		weight_sum += float(w)
	if total <= 0 or weight_sum <= 0.0:
		return parts
	var fractions: Array[float] = []
	var assigned := 0
	for i in weights.size():
		var exact := float(total) * float(weights[i]) / weight_sum
		parts[i] = int(floor(exact + 0.000001))
		assigned += parts[i]
		fractions.append(exact - float(parts[i]))
	while assigned < total:
		var best := 0
		for i in weights.size():
			if fractions[i] > fractions[best] + 0.000001:
				best = i
		parts[best] += 1
		fractions[best] = -1.0
		assigned += 1
	return parts


static func tier_count() -> int:
	return _config()["tierMix"].size()


# Stock per tier as an array (element 0 = tier 1); ore is a single element.
static func _tier_stocks(kind: String, good_type: String) -> Array[int]:
	var good: Dictionary = _market()["goods"][kind][good_type]
	var stocks: Array[int] = []
	if kind == "ore":
		stocks.append(int(good["stock"]))
		return stocks
	for tier in range(1, tier_count() + 1):
		stocks.append(int(good["tiers"].get(str(tier), 0)))
	return stocks


static func _set_tier_stocks(kind: String, good_type: String, stocks: Array[int]) -> void:
	var good: Dictionary = _market()["goods"][kind][good_type]
	var total := 0
	for qty in stocks:
		total += qty
	good["stock"] = total
	if kind == "consumable":
		good["tiers"] = _tiers_dict(stocks)


static func _tiers_dict(stocks: Array[int]) -> Dictionary:
	var tiers := {}
	for i in stocks.size():
		tiers[str(i + 1)] = stocks[i]
	return tiers


# Fresh market with every good's stock at normal (items split by tierMix).
static func new_state() -> Dictionary:
	var goods := {}
	for kind in KINDS:
		goods[kind] = {}
		for good_type in _config()["goods"][kind]:
			var stock: int = GameState.round_epsilon(_normal_stock(kind, good_type))
			var price: int = base_price(kind, good_type)
			var good := { "stock": stock, "price": price, "prevPrice": price, "history": [] }
			if kind == "consumable":
				good["tiers"] = _tiers_dict(_apportion(stock, _config()["tierMix"]))
			goods[kind][good_type] = good
	return {
		"stockSchema": STOCK_SCHEMA,
		"startedDay": 1 if _config()["simStart"] == "day1" else null,
		"goods": goods,
		"supply": { "ore": {}, "consumable": {} },
		"supplyTiers": {},
		"demand": { "ore": {}, "consumable": {} },
		"annotations": [],
		"deliveries": [],
		"salesHistory": [],
		"tickerStates": {},
		"aboveDays": {},
	}


# Moves an untiered market to tiered stock once: each good's stock becomes
# the stock its current price implies on the curve (price steady) at the
# current normalStock, items split by tierMix. No-op once migrated.
static func migrate_legacy(market: Dictionary) -> void:
	if int(market.get("stockSchema", 0)) >= STOCK_SCHEMA:
		return
	var cfg := _config()
	for kind in KINDS:
		for good_type in market.get("goods", {}).get(kind, {}):
			var good: Dictionary = market["goods"][kind][good_type]
			var base := float(base_price(kind, good_type))
			var price_mult := float(good["price"]) / base if base > 0.0 else 1.0
			price_mult = clampf(price_mult, float(cfg["priceMinMult"]), float(cfg["priceMaxMult"]))
			var stock: int = GameState.round_epsilon(pow(price_mult, -1.0 / float(cfg["curveExponent"])) * _normal_stock(kind, good_type))
			good["stock"] = stock
			if kind == "consumable":
				good["tiers"] = _tiers_dict(_apportion(stock, cfg["tierMix"]))
	if not market.has("supplyTiers"):
		market["supplyTiers"] = {}
	market["stockSchema"] = STOCK_SCHEMA


# Today's London price. Base price before the sim starts.
static func quote(kind: String, good_type: String) -> int:
	if not is_running():
		return base_price(kind, good_type)
	return int(_market()["goods"][kind][good_type]["price"])


# Yesterday's London price. Base price before the sim starts.
static func prev_quote(kind: String, good_type: String) -> int:
	if not is_running():
		return base_price(kind, good_type)
	return int(_market()["goods"][kind][good_type]["prevPrice"])


# Today's quote minus yesterday's (sign drives the ▲/▼ on price rows).
static func day_move(kind: String, good_type: String) -> int:
	return quote(kind, good_type) - prev_quote(kind, good_type)


# Stored price history oldest first as { values, days }; history's last
# entry is today's price.
static func price_series(kind: String, good_type: String) -> Dictionary:
	var values: Array[int] = []
	var days: Array[int] = []
	var history: Array = _market()["goods"][kind][good_type]["history"]
	var today: int = GameState.state["world"]["day"]
	for i in history.size():
		values.append(int(history[i]))
		days.append(today - (history.size() - 1 - i))
	return { "values": values, "days": days }


# Annotations recorded for one good, oldest first.
static func annotations_for(kind: String, good_type: String) -> Array:
	var found: Array = []
	for note in _market().get("annotations", []):
		if note["goodKind"] == kind and note["good"] == good_type:
			found.append(note)
	return found


# Items whose London shortage is feeding this ore's derived demand today,
# as [{ recipeKey, shortage, demand }], largest demand first.
static func ore_demand_drivers(ore_type: String) -> Array:
	var drivers: Array = []
	for recipe_key in _market()["goods"]["consumable"]:
		var qty: int = int(GameData.RECIPES[recipe_key]["ingredients"].get(ore_type, 0))
		var shortage: float = _normal_stock("consumable", recipe_key) - float(_market()["goods"]["consumable"][recipe_key]["stock"])
		if qty > 0 and shortage > 0.0:
			drivers.append({ "recipeKey": recipe_key, "shortage": int(shortage), "demand": shortage * qty * float(_config()["oreConversionRate"]) })
	drivers.sort_custom(func(a, b): return a["demand"] > b["demand"])
	return drivers


# Each active Ticker state's item-demand effect, scaled by the merged
# effectMod (R§3.2), as [{ section, state, target, fraction }]; target is
# "all" for demandAll or a recipe key for itemDemand.
static func demand_modifiers() -> Array:
	var scale: float = 1.0 + float(Barometer.get_merged_effects().get("effectMod", 0.0))
	var mods: Array = []
	for section in Barometer.SECTIONS:
		var state_id: String = GameState.state["barometer"][section]
		var effects: Dictionary = GameData.BAROMETER_STATES[section][state_id]["effects"]
		if float(effects.get("demandAll", 0.0)) != 0.0:
			mods.append({ "section": section, "state": state_id, "target": "all", "fraction": float(effects["demandAll"]) * scale })
		for recipe_key in effects.get("itemDemand", {}):
			mods.append({ "section": section, "state": state_id, "target": recipe_key, "fraction": float(effects["itemDemand"][recipe_key]) * scale })
	return mods


# Mean of the last two days' prices, for vein valuations; today's quote
# when fewer than two days of history exist.
static func quote_avg2(kind: String, good_type: String) -> int:
	if not is_running():
		return base_price(kind, good_type)
	var history: Array = _market()["goods"][kind][good_type]["history"]
	if history.size() < 2:
		return quote(kind, good_type)
	return GameState.round_epsilon((float(history[-1]) + float(history[-2])) / 2.0)


# tier is the stock tier an item enters at (below 1 enters as tier 1);
# ignored for ore.
static func record_supply(kind: String, good_type: String, qty: int, source: String, tier: int = 1) -> void:
	_record("supply", kind, good_type, qty, source)
	if kind == "consumable" and qty > 0 and is_running():
		var market := _market()
		if not market.has("supplyTiers"):
			market["supplyTiers"] = {}
		var by_tier: Dictionary = market["supplyTiers"].get(good_type, {})
		var key := str(clampi(tier, 1, tier_count()))
		by_tier[key] = int(by_tier.get(key, 0)) + qty
		market["supplyTiers"][good_type] = by_tier


# tier names the stock tier an item buyer takes from (0 = untiered: drawn
# like nameless demand, and always for ore).
static func record_demand(kind: String, good_type: String, qty: int, source: String, tier: int = 0) -> void:
	_record("demand", kind, good_type, qty, source)
	_record_demand_tier(kind, good_type, qty, tier)


static func _record_demand_tier(kind: String, good_type: String, qty: int, tier: int) -> void:
	if kind != "consumable" or tier <= 0 or qty <= 0 or not is_running():
		return
	var market := _market()
	if not market.has("demandTiers"):
		market["demandTiers"] = {}
	var by_tier: Dictionary = market["demandTiers"].get(good_type, {})
	var key := str(clampi(tier, 1, tier_count()))
	by_tier[key] = int(by_tier.get(key, 0)) + qty
	market["demandTiers"][good_type] = by_tier


# Which tally each faction market move (R§3.1 "Escalation") feeds.
const MOVE_SIDES := { "flood": "supply", "undercut": "supply", "deny": "demand", "stabiliseSell": "supply", "stabiliseBuy": "demand", "positionBuy": "demand", "positionSell": "supply" }


# A faction market move (a MOVE_SIDES key): recorded on its tally
# side, and today's reprice annotates it under the move's name by that
# faction at any volume. moves: { kind: { type: { source: { move: qty } } } }.
static func record_move(move: String, kind: String, good_type: String, qty: int, source: String, tier: int = 0) -> void:
	if qty <= 0 or not is_running():
		return
	_record(MOVE_SIDES[move], kind, good_type, qty, source)
	if MOVE_SIDES[move] == "demand":
		_record_demand_tier(kind, good_type, qty, tier)
	elif kind == "consumable" and tier > 0:
		var market := _market()
		if not market.has("supplyTiers"):
			market["supplyTiers"] = {}
		var by_tier: Dictionary = market["supplyTiers"].get(good_type, {})
		var key := str(clampi(tier, 1, tier_count()))
		by_tier[key] = int(by_tier.get(key, 0)) + qty
		market["supplyTiers"][good_type] = by_tier
	var market := _market()
	if not market.has("moves"):
		market["moves"] = { "ore": {}, "consumable": {} }
	var by_type: Dictionary = market["moves"][kind]
	var by_source: Dictionary = by_type.get(good_type, {})
	var by_move: Dictionary = by_source.get(source, {})
	by_move[move] = int(by_move.get(move, 0)) + qty
	by_source[source] = by_move
	by_type[good_type] = by_source


# What one source sold over the last salesHistory.days days, today's live
# tally included: { "kind:type": qty }.
static func sold_this_week(source: String) -> Dictionary:
	var first_day: int = int(GameState.state["world"]["day"]) - int(_config()["salesHistory"]["days"]) + 1
	var sold := {}
	var days: Array = [{ "day": GameState.state["world"]["day"], "supply": _market()["supply"] }]
	days.append_array(_market().get("salesHistory", []))
	for entry in days:
		if int(entry["day"]) < first_day:
			continue
		for kind in KINDS:
			var by_type: Dictionary = entry["supply"].get(kind, {})
			for good_type in by_type:
				var qty := int(by_type[good_type].get(source, 0))
				if qty > 0:
					var key: String = kind + ":" + good_type
					sold[key] = int(sold.get(key, 0)) + qty
	return sold


# Keeps today's supply tally in salesHistory (the prior salesHistory.days - 1
# days; today is read live from the tally).
static func _log_sales() -> void:
	var market := _market()
	var first_day: int = int(GameState.state["world"]["day"]) - int(_config()["salesHistory"]["days"]) + 2
	var kept: Array = market.get("salesHistory", []).filter(func(e: Dictionary) -> bool: return int(e["day"]) >= first_day)
	kept.push_front({ "day": GameState.state["world"]["day"], "supply": market["supply"] })
	market["salesHistory"] = kept


# Contract delivery (R§3.13 "Deliveries"): recorded for the buyer faction
# only -- no supply tally, no price effect. Bounded to deliveries.cap.
static func note_contract_delivery(counterparty: String, kind: String, good_type: String, qty: int) -> void:
	if qty <= 0:
		return
	var market := _market()
	if not market.has("deliveries"):
		market["deliveries"] = []
	var entries: Array = market["deliveries"]
	entries.append({ "day": GameState.state["world"]["day"], "counterparty": counterparty, "goodKind": kind, "good": good_type, "qty": qty })
	while entries.size() > int(_config()["deliveries"]["cap"]):
		entries.pop_front()


# Tallies are { kind: { type: { source: qty } } }, cleared each reprice.
static func _record(side: String, kind: String, good_type: String, qty: int, source: String) -> void:
	if qty <= 0 or not is_running():
		return
	var by_type: Dictionary = _market()[side][kind]
	var by_source: Dictionary = by_type.get(good_type, {})
	by_source[source] = int(by_source.get(source, 0)) + qty
	by_type[good_type] = by_source


static func _tally(side: String, kind: String, good_type: String) -> int:
	var total := 0
	for qty in _market()[side][kind].get(good_type, {}).values():
		total += int(qty)
	return total


# Today's flow for one good, per tier (element 0 = tier 1; ore one element):
# { "stock", "supply", "demand", "after" }. Supply is the Independents slice
# (split by tierMix) plus recorded supply at its tiers. Demand is nameless
# demand (Ticker-scaled, price-elastic, plus derived ore demand and story
# rises) plus recorded demand, capped at what is held, drawn across tiers in
# proportion to stock + supply in whole units.
static func _plan_day(kind: String, good_type: String) -> Dictionary:
	var stock := _tier_stocks(kind, good_type)
	var supply: Array[int] = []
	supply.resize(stock.size())
	supply.fill(0)
	var independents := int(independents_supply(kind, good_type))
	if kind == "ore":
		supply[0] = independents + _tally("supply", kind, good_type)
	else:
		var mixed := _apportion(independents, _config()["tierMix"])
		var recorded: Dictionary = _market().get("supplyTiers", {}).get(good_type, {})
		for i in supply.size():
			supply[i] = mixed[i] + int(recorded.get(str(i + 1), 0))
	var baseline: float = civilian_demand(kind, good_type)
	if kind == "consumable":
		baseline *= Barometer.get_item_demand_mult(good_type)
	baseline *= demand_mult(kind, good_type)
	if kind == "ore":
		baseline += civilian_demand(kind, good_type) * story_rise_fraction(good_type)
		baseline += derived_ore_demand(good_type)
	var tiered: Dictionary = _market().get("demandTiers", {}).get(good_type, {})
	var tiered_total := 0
	for qty in tiered.values():
		tiered_total += int(qty)
	var wanted: int = maxi(0, GameState.round_epsilon(baseline) + _tally("demand", kind, good_type) - tiered_total)
	var held: Array = []
	var forced: Array[int] = []
	var free: Array = []
	var free_total := 0
	for i in stock.size():
		var have: int = stock[i] + supply[i]
		var take: int = mini(have, int(tiered.get(str(i + 1), 0))) if kind == "consumable" else 0
		held.append(have)
		forced.append(take)
		free.append(have - take)
		free_total += have - take
	var drawn := _apportion(mini(wanted, free_total), free)
	var demand: Array[int] = []
	for i in stock.size():
		demand.append(forced[i] + drawn[i])
	var after: Array[int] = []
	for i in stock.size():
		after.append(held[i] - demand[i])
	return { "stock": stock, "supply": supply, "demand": demand, "after": after }


# What can be traded per tier today (stock + today's supply - today's demand,
# floored at 0), as { tier: qty } for tiers 1..5; ore is { 0: qty }.
static func availability(kind: String, good_type: String) -> Dictionary:
	var available := {}
	if not is_running():
		var stocks := _tier_stocks(kind, good_type)
		for i in stocks.size():
			available[i + 1 if kind == "consumable" else 0] = stocks[i]
		return available
	var plan := _plan_day(kind, good_type)
	for i in plan["after"].size():
		available[i + 1 if kind == "consumable" else 0] = maxi(0, int(plan["after"][i]))
	return available


# Price of one unit of an item at a tier: the good's quote × the quality
# multiplier.
static func tier_price(good_type: String, tier: int) -> int:
	return GameState.round_epsilon(quote("consumable", good_type) * Economy.quality_price_multiplier(tier))


# Rollover step: per good, stock takes today's planned flow and price moves a
# smoothing fraction toward the target for its total stock. Items reprice
# first, their civilian demand scaled by the Ticker; each ore's demand then
# adds the shortages of today's item stocks.
static func daily_reprice() -> void:
	if not is_running():
		return
	var cfg := _config()
	var smoothing: float = cfg["smoothing"]
	var history_days: int = int(cfg["historyDays"])
	var market := _market()
	var ticker_shifts := _ticker_shifts()
	for kind in KINDS:
		for good_type in market["goods"][kind]:
			var good: Dictionary = market["goods"][kind][good_type]
			var plan := _plan_day(kind, good_type)
			_set_tier_stocks(kind, good_type, plan["after"])
			var stock: int = int(good["stock"])
			var base := float(base_price(kind, good_type))
			var price: int = int(good["price"])
			var moved: int = GameState.round_epsilon(price + (target_price(kind, good_type, stock) - price) * smoothing)
			good["prevPrice"] = price
			good["price"] = clampi(moved, GameState.round_epsilon(base * cfg["priceMinMult"]), GameState.round_epsilon(base * cfg["priceMaxMult"]))
			var history: Array = good["history"]
			history.append(good["price"])
			while history.size() > history_days:
				history.pop_front()
			_annotate_day(kind, good_type, ticker_shifts, price, int(good["price"]))
	_update_above_days(market)
	_prune_story_rises()
	_log_sales()
	market["supply"] = { "ore": {}, "consumable": {} }
	market["supplyTiers"] = {}
	market["demand"] = { "ore": {}, "consumable": {} }
	market.erase("demandTiers")
	market.erase("moves")


# Consecutive days each item has closed above outsideCraft.triggerMult x base
# (state.market.aboveDays { recipeKey: days }); a day at or below drops the key.
static func _update_above_days(market: Dictionary) -> void:
	var trigger: float = float(_config()["outsideCraft"]["triggerMult"])
	var days: Dictionary = market.get("aboveDays", {})
	for good_type in market["goods"]["consumable"]:
		var price: int = int(market["goods"]["consumable"][good_type]["price"])
		if float(price) > trigger * float(base_price("consumable", good_type)):
			days[good_type] = int(days.get(good_type, 0)) + 1
		else:
			days.erase(good_type)
	market["aboveDays"] = days


# Consecutive days the item has priced above the trigger (0 when not).
static func days_above(good_type: String) -> int:
	return int(_market().get("aboveDays", {}).get(good_type, 0))


# True when `faction_id` may outside-craft `good_type`: the faction lists it in
# neither crafts nor craftTargets, the recipe has not opted out, and the price
# has stayed above the trigger for graceDays.
static func outside_craft_eligible(faction_id: String, good_type: String) -> bool:
	var recipe: Dictionary = GameData.RECIPES.get(good_type, {})
	if recipe.is_empty() or not bool(recipe.get("outsideCraft", true)):
		return false
	if not GameData.FACTIONS.has(faction_id) or is_specialist(faction_id, good_type):
		return false
	return days_above(good_type) >= int(_config()["outsideCraft"]["graceDays"])


# Specialist: the faction lists the item in `crafts` or `craftTargets`.
static func is_specialist(faction_id: String, good_type: String) -> bool:
	var faction: Dictionary = GameData.FACTIONS.get(faction_id, {})
	return faction.get("crafts", []).has(good_type) or faction.get("craftTargets", {}).has(good_type)


# Timed event-driven demand rises (data/market.json storyRises), kept as
# day-stamped entries in state.market.storyRises: [{ story, ore, fraction,
# startDay, endDay }], active while startDay <= day < endDay.
static func add_story_rise(story_id: String) -> void:
	var rise: Dictionary = _config()["storyRises"][story_id]
	var day: int = GameState.state["world"]["day"]
	var market := _market()
	if not market.has("storyRises"):
		market["storyRises"] = []
	var rises: Array = market["storyRises"]
	rises.append({ "story": story_id, "ore": rise["ore"], "fraction": float(rise["fraction"]), "startDay": day, "endDay": day + int(rise["days"]) })
	EventBus.state_changed.emit()


# Summed civilian-demand fraction added to an ore today by active story rises.
static func story_rise_fraction(ore_type: String) -> float:
	var day: int = GameState.state["world"]["day"]
	var total := 0.0
	for rise in _market().get("storyRises", []):
		if rise["ore"] == ore_type and int(rise["startDay"]) <= day and day < int(rise["endDay"]):
			total += float(rise["fraction"])
	return total


static func _prune_story_rises() -> void:
	var day: int = GameState.state["world"]["day"]
	var rises: Array = _market().get("storyRises", [])
	for i in range(rises.size() - 1, -1, -1):
		if day >= int(rises[i]["endDay"]):
			rises.remove_at(i)


# Ticker states that changed since the last reprice, [{ section, state }];
# snapshots today's states for tomorrow. The first reprice only seeds.
static func _ticker_shifts() -> Array:
	var market := _market()
	var last: Dictionary = market.get("tickerStates", {})
	var shifts: Array = []
	var now := {}
	for section in Barometer.SECTIONS:
		now[section] = GameState.state["barometer"][section]
		if last.has(section) and last[section] != now[section]:
			shifts.append({ "section": section, "from": last[section], "state": now[section] })
	market["tickerStates"] = now
	return shifts


# A shift touches an item when the outgoing or incoming state's effects carry
# demandAll or an itemDemand entry for it. Ores are never touched directly.
static func _shift_touches(shift: Dictionary, kind: String, good_type: String) -> bool:
	if kind != "consumable":
		return false
	for state_id in [shift["from"], shift["state"]]:
		var effects: Dictionary = GameData.BAROMETER_STATES[shift["section"]][state_id]["effects"]
		if float(effects.get("demandAll", 0.0)) != 0.0 or effects.get("itemDemand", {}).has(good_type):
			return true
	return false


# Appends today's annotations for one good: Ticker shifts touching it, each
# faction market move, each other source's supply and each faction's buy
# above dumpVolumeMult × civilian demand (a source's supply move is not also
# a dump, its deny not also a buy), and a day move of at least
# moveThreshold × yesterday's price.
# Runs before tallies clear.
static func _annotate_day(kind: String, good_type: String, ticker_shifts: Array, old_price: int, new_price: int) -> void:
	var cfg: Dictionary = _config()["annotations"]
	for shift in ticker_shifts:
		if _shift_touches(shift, kind, good_type):
			_annotate(kind, good_type, "ticker", shift["state"], 0)
	var volume_line: float = float(cfg["dumpVolumeMult"]) * civilian_demand(kind, good_type)
	var moved_by: Dictionary = _market().get("moves", {}).get(kind, {}).get(good_type, {})
	var move_sides := {}
	for source in moved_by:
		for move_id in moved_by[source]:
			_annotate(kind, good_type, move_id, source, int(moved_by[source][move_id]))
			move_sides[MOVE_SIDES[move_id] + ":" + source] = true
	var by_source: Dictionary = _market()["supply"][kind].get(good_type, {})
	for source in by_source:
		if not move_sides.has("supply:" + source) and float(by_source[source]) > volume_line:
			_annotate(kind, good_type, "dump", source, int(by_source[source]))
	var bought: Dictionary = _market()["demand"][kind].get(good_type, {})
	for source in bought:
		if GameData.FACTIONS.has(source) and not move_sides.has("demand:" + source) and float(bought[source]) > volume_line:
			_annotate(kind, good_type, "buy", source, int(bought[source]))
	var move: int = new_price - old_price
	if old_price > 0 and absf(float(move)) >= float(cfg["moveThreshold"]) * old_price:
		_annotate(kind, good_type, "spike" if move > 0 else "crash", "market", move)


# Annotation: { day, goodKind, good, kind (ticker/flood/undercut/deny/
# stabiliseSell/stabiliseBuy/positionBuy/positionSell/dump/buy/spike/crash),
# source (Ticker state id, supplier/buyer, or "market"), value (qty or £
# move; 0 for ticker) }. Bounded to annotations.cap, oldest dropped.
static func _annotate(kind: String, good_type: String, note_kind: String, source: String, value: int) -> void:
	var market := _market()
	if not market.has("annotations"):
		market["annotations"] = []
	var notes: Array = market["annotations"]
	notes.append({ "day": GameState.state["world"]["day"], "goodKind": kind, "good": good_type, "kind": note_kind, "source": source, "value": value })
	while notes.size() > int(_config()["annotations"]["cap"]):
		notes.pop_front()
