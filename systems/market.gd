class_name Market
extends RefCounted

# London market (R§3.13): one price per good -- kind "ore" (the five ore
# types) or "consumable" (every recipe key) -- repriced each rollover from a
# hidden London stock. Sales execute at today's quote; recorded supply and
# demand only move tomorrow's price. Static funcs only.

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


# Stand-in London: the single read point for the rest of London's daily
# volume per good, { supply, demand }.
static func _stand_in(kind: String, good_type: String) -> Dictionary:
	var entry: Dictionary = _config()["goods"][kind][good_type]
	return { "supply": float(entry["standInSupply"]), "demand": float(entry["standInDemand"]) }


# The sim-start switch (market.json simStart): "day1" runs from the first
# day; "bizA2" waits until market.startedDay is set.
static func is_running() -> bool:
	return _config()["simStart"] == "day1" or _market().get("startedDay") != null


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


# Stock where stand-in flow and reversion cancel out with no player trade
# and no Ticker effect. An ore's resting demand includes the derived demand
# from every item sitting at its own (whole-unit) resting stock.
static func resting_stock(kind: String, good_type: String) -> float:
	var reversion: float = _config()["reversion"]
	var flow: Dictionary = _stand_in(kind, good_type)
	var demand: float = flow["demand"]
	if kind == "ore":
		var item_stocks := {}
		for recipe_key in _config()["goods"]["consumable"]:
			item_stocks[recipe_key] = GameState.round_epsilon(resting_stock("consumable", recipe_key))
		demand += _derived_ore_demand(good_type, item_stocks)
	return _normal_stock(kind, good_type) + (flow["supply"] - demand) * (1.0 - reversion) / reversion


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


# Fresh market; resting=true starts every good at its idle equilibrium
# (old-save backfill), otherwise at base price with stock at normal.
static func new_state(resting: bool) -> Dictionary:
	var goods := {}
	for kind in KINDS:
		goods[kind] = {}
		for good_type in _config()["goods"][kind]:
			var stock: int = GameState.round_epsilon(resting_stock(kind, good_type) if resting else _normal_stock(kind, good_type))
			var price: int = target_price(kind, good_type, stock) if resting else base_price(kind, good_type)
			goods[kind][good_type] = { "stock": stock, "price": price, "prevPrice": price, "history": [] }
	return {
		"startedDay": 1 if _config()["simStart"] == "day1" else null,
		"goods": goods,
		"supply": { "ore": {}, "consumable": {} },
		"demand": { "ore": {}, "consumable": {} },
	}


# Today's London price. Base price before the sim starts.
static func quote(kind: String, good_type: String) -> int:
	if not is_running():
		return base_price(kind, good_type)
	return int(_market()["goods"][kind][good_type]["price"])


# Mean of the last two days' prices, for vein valuations; today's quote
# when fewer than two days of history exist.
static func quote_avg2(kind: String, good_type: String) -> int:
	if not is_running():
		return base_price(kind, good_type)
	var history: Array = _market()["goods"][kind][good_type]["history"]
	if history.size() < 2:
		return quote(kind, good_type)
	return GameState.round_epsilon((float(history[-1]) + float(history[-2])) / 2.0)


static func record_supply(kind: String, good_type: String, qty: int, source: String) -> void:
	_record("supply", kind, good_type, qty, source)


static func record_demand(kind: String, good_type: String, qty: int, source: String) -> void:
	_record("demand", kind, good_type, qty, source)


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


# Rollover step: per good, stock takes today's flow (floored at 0), reverts
# toward normalStock (whole units), and price moves a smoothing fraction
# toward target. Items reprice first, their stand-in demand scaled by the
# Ticker; each ore's demand then adds the shortages of today's item stocks.
static func daily_reprice() -> void:
	if not is_running():
		return
	var cfg := _config()
	var reversion: float = cfg["reversion"]
	var smoothing: float = cfg["smoothing"]
	var history_days: int = int(cfg["historyDays"])
	var market := _market()
	for kind in KINDS:
		for good_type in market["goods"][kind]:
			var good: Dictionary = market["goods"][kind][good_type]
			var flow: Dictionary = _stand_in(kind, good_type)
			var supply: float = flow["supply"] + _tally("supply", kind, good_type)
			var baseline: float = flow["demand"]
			if kind == "consumable":
				baseline *= Barometer.get_item_demand_mult(good_type)
			else:
				baseline += derived_ore_demand(good_type)
			var demand: float = baseline + _tally("demand", kind, good_type)
			var flowed: float = maxf(0.0, float(good["stock"]) + supply - demand)
			var stock: int = GameState.round_epsilon(flowed + (_normal_stock(kind, good_type) - flowed) * reversion)
			var base := float(base_price(kind, good_type))
			var price: int = int(good["price"])
			var moved: int = GameState.round_epsilon(price + (target_price(kind, good_type, stock) - price) * smoothing)
			good["stock"] = stock
			good["prevPrice"] = price
			good["price"] = clampi(moved, GameState.round_epsilon(base * cfg["priceMinMult"]), GameState.round_epsilon(base * cfg["priceMaxMult"]))
			var history: Array = good["history"]
			history.append(good["price"])
			while history.size() > history_days:
				history.pop_front()
	market["supply"] = { "ore": {}, "consumable": {} }
	market["demand"] = { "ore": {}, "consumable": {} }
