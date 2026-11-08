class_name AutoSell
extends RefCounted

# Daily auto-sell pass (R§3.6 "Auto-sell"): the Sales role sells surplus stock
# of Production-list items into London at each rollover, under each recipe's
# sellAbove and mood from ProductionSettings.resolve(). A cutoff at the top of
# the bar sells nothing, and the master starts there.
# Static funcs only.

const PRICE_EPSILON := 0.0001  # absorbs float error in base × minPriceMult
const UNIT_EPSILON := 0.0001  # absorbs float error in limit × skill rate

# projection()'s "reason" when qty is 0.
const REASON_NO_SALES := "noSales"
const REASON_CLOSED := "marketClosed"
const REASON_SELL_NONE := "sellNone"
const REASON_UNDER_CUTOFF := "underCutoff"
const REASON_CONTRACTS := "heldForContracts"
const REASON_PRICE := "priceLow"
const REASON_MARKET_FULL := "marketFull"


static func _config() -> Dictionary:
	return GameData.MARKET["autoSell"]


# The recipe's effective setting set (override, else master); its sellAbove
# and mood are the auto-sell rule.
static func rule(recipe_key: String) -> Dictionary:
	return ProductionSettings.resolve(recipe_key)


static func _store_rule(recipe_key: String, sell_above: int, mood: String) -> void:
	ProductionSettings.set_field(recipe_key, "sellAbove", sell_above)
	ProductionSettings.set_field(recipe_key, "mood", mood)


# Sets Keep; a Keep at or past Sell-above pushes Sell-above up with it.
static func set_keep(recipe_key: String, keep: int) -> void:
	ProductionSettings.set_keep(recipe_key, keep)


# Moves Sell-above, stopping one above Keep. Locked while no one works Sales.
static func set_sell_above(recipe_key: String, sell_above: int) -> void:
	if not Contracts.has_staffed_sales():
		return
	ProductionSettings.set_sell_above(recipe_key, sell_above)


# Locked while no one works Sales.
static func set_mood(recipe_key: String, mood: String) -> void:
	if not Contracts.has_staffed_sales() or not _config()["moods"].has(mood):
		return
	_store_rule(recipe_key, int(rule(recipe_key)["sellAbove"]), mood)
	EventBus.mark_changed()


# Master Sell-above; recipes without an override follow. Locked while no one works Sales.
static func set_master_sell_above(sell_above: int) -> void:
	if not Contracts.has_staffed_sales():
		return
	ProductionSettings.set_master_sell_above(sell_above)


# Master mood; locked while no one works Sales.
static func set_master_mood(mood: String) -> void:
	if not Contracts.has_staffed_sales() or not _config()["moods"].has(mood):
		return
	ProductionSettings.set_master_field("mood", mood)


# Sum of projection() over the Production-list recipes that follow the master:
# { recipes, qty, offMarketQty, income } where recipes counts those that would sell.
static func master_projection() -> Dictionary:
	var total := { "recipes": 0, "qty": 0, "offMarketQty": 0, "income": 0 }
	for recipe_key in Rooms.production_recipes():
		if ProductionSettings.has_override(recipe_key):
			continue
		var projected := projection(recipe_key)
		if int(projected["qty"]) + int(projected["offMarketQty"]) > 0:
			total["recipes"] += 1
		total["qty"] += int(projected["qty"])
		total["offMarketQty"] += int(projected["offMarketQty"])
		total["income"] += int(projected["income"])
	return total


# Stock at or below this is never auto-sold: max(Sell-above, Keep, contract
# need while covering). keep / sell_above >= 0 preview values not yet stored
# (a handle mid-drag).
static func protected_floor(recipe_key: String, keep: int = -1, sell_above: int = -1) -> int:
	var cutoff: int = sell_above if sell_above >= 0 else int(rule(recipe_key)["sellAbove"])
	var kept: int = keep if keep >= 0 else Rooms.lab_keep(recipe_key)
	var need := Rooms.contract_need(recipe_key) if Rooms.lab_covers_contracts(recipe_key) else 0
	return maxi(maxi(cutoff, kept), need)


# Extra London stock that would lower the price by max_drop on the market curve.
static func market_limit(recipe_key: String, max_drop: float) -> int:
	var exponent := float(GameData.MARKET["curveExponent"])
	var growth := pow(1.0 - max_drop, -1.0 / exponent) - 1.0
	return int(floor(Market.stock("consumable", recipe_key) * growth))


# Private buyers the Sales contact can reach for an on-market limit: nothing
# at Sales level 1, then offMarketPerSalesLevel more of the limit per level.
static func off_market_limit(on_market_limit: int) -> int:
	var rate := float(_config()["offMarketPerSalesLevel"]) * (Offers.sales_skill() - 1)
	return int(floor(on_market_limit * rate + UNIT_EPSILON))


# Units the rule would sell on the market at today's stock and price.
static func sellable_qty(recipe_key: String) -> int:
	return _assess(recipe_key, -1, -1)["qty"]


# { qty, offMarketQty, reason }: what the rule sells today, and why not when
# qty is 0. Off-market units come from surplus the market didn't take.
static func _assess(recipe_key: String, keep: int, sell_above: int) -> Dictionary:
	var cutoff: int = sell_above if sell_above >= 0 else int(rule(recipe_key)["sellAbove"])
	if cutoff >= GameData.PRODUCTION_TARGET_MAX:
		return { "qty": 0, "offMarketQty": 0, "reason": REASON_SELL_NONE }
	var mood: Dictionary = _config()["moods"][rule(recipe_key)["mood"]]
	var held := Crafting.inventory_qty(recipe_key)
	var surplus := held - protected_floor(recipe_key, keep, sell_above)
	if surplus <= 0:
		return { "qty": 0, "offMarketQty": 0, "reason": REASON_CONTRACTS if held > cutoff else REASON_UNDER_CUTOFF }
	var min_price: float = Market.base_price("consumable", recipe_key) * float(mood["minPriceMult"])
	if float(Market.quote("consumable", recipe_key)) < min_price - PRICE_EPSILON:
		return { "qty": 0, "offMarketQty": 0, "reason": REASON_PRICE }
	var limit := market_limit(recipe_key, float(mood["maxPriceDrop"]))
	var qty := mini(surplus, limit)
	if qty <= 0:
		return { "qty": 0, "offMarketQty": 0, "reason": REASON_MARKET_FULL }
	return { "qty": qty, "offMarketQty": mini(surplus - qty, off_market_limit(limit)), "reason": "" }


# What daily_pass() would do for a Production-list recipe from the current
# state: { qty, offMarketQty, income, reason }, reason "" when it sells; income
# covers both channels. keep / sell_above >= 0 preview values not yet stored.
static func projection(recipe_key: String, keep: int = -1, sell_above: int = -1) -> Dictionary:
	if not Contracts.has_staffed_sales():
		return { "qty": 0, "offMarketQty": 0, "income": 0, "reason": REASON_NO_SALES }
	if not Market.is_running():
		return { "qty": 0, "offMarketQty": 0, "income": 0, "reason": REASON_CLOSED }
	var assessed := _assess(recipe_key, keep, sell_above)
	var income := 0
	for lot in Crafting.inventory_lots(recipe_key, assessed["qty"] + assessed["offMarketQty"]):
		income += _lot_income(recipe_key, lot)
	return { "qty": assessed["qty"], "offMarketQty": assessed["offMarketQty"], "income": income, "reason": assessed["reason"] }


# Sells each Production-list recipe's assessed units, lowest tier first with
# the market served before private buyers, and banks the day's total as
# contract revenue. Returns { recipeKey: { qty, offMarketQty, income } } for
# the units sold; income covers both channels.
static func daily_pass() -> Dictionary:
	var sold := {}
	if not Contracts.has_staffed_sales() or not Market.is_running():
		return sold
	var total := 0
	for recipe_key in Rooms.production_recipes():
		var assessed := _assess(recipe_key, -1, -1)
		if assessed["qty"] <= 0:
			continue
		var income := _sell(recipe_key, assessed["qty"]) + _sell_off_market(recipe_key, assessed["offMarketQty"])
		sold[recipe_key] = { "qty": assessed["qty"], "offMarketQty": assessed["offMarketQty"], "income": income }
		total += income
		GameState.state["business"]["autoSoldUnits"] += assessed["qty"] + assessed["offMarketQty"]
	if sold.is_empty():
		return sold
	Contracts.receive_revenue(total, "Auto-sales")
	Contacts.award_contact_xp(Contacts.sales_contact(), "sales", int(_config()["salesXp"]))
	EventBus.mark_changed()
	return sold


static func _sell(recipe_key: String, qty: int) -> int:
	var income := 0
	for lot in Crafting.inventory_remove(recipe_key, qty):
		income += _lot_income(recipe_key, lot)
		Market.record_supply("consumable", recipe_key, lot["qty"], "player", lot["tier"])
	return income


# Private sales skip the market's supply record, so London's stock and price
# stay put and the units don't count toward market share.
static func _sell_off_market(recipe_key: String, qty: int) -> int:
	var income := 0
	for lot in Crafting.inventory_remove(recipe_key, qty):
		income += _lot_income(recipe_key, lot)
	return income


static func _lot_income(recipe_key: String, lot: Dictionary) -> int:
	var quote := Market.quote("consumable", recipe_key)
	var price := GameState.round_epsilon(quote * Economy.quality_price_multiplier(lot["tier"]))
	return Market.line_total("consumable", price, lot["qty"])
