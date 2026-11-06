class_name AutoSell
extends RefCounted

# Daily auto-sell pass (R§3.6 "Auto-sell"): the Sales role sells surplus stock
# of Production-list items into London at each rollover, under one rule per
# recipe in state.autoSell ({ recipeKey: { sellAbove, mood } }). A recipe with
# no rule is Off. Static funcs only.

const MOOD_OFF := "off"
const PRICE_EPSILON := 0.0001  # absorbs float error in base × minPriceMult


static func _config() -> Dictionary:
	return GameData.MARKET["autoSell"]


# The recipe's rule, or the default: Off, cutoff at the top of the bar.
static func rule(recipe_key: String) -> Dictionary:
	return GameState.state["autoSell"].get(recipe_key, { "sellAbove": GameData.PRODUCTION_TARGET_MAX, "mood": MOOD_OFF })


# Stock at or below this is never auto-sold.
static func protected_floor(recipe_key: String) -> int:
	return maxi(int(rule(recipe_key)["sellAbove"]), Rooms.effective_lab_target(recipe_key))


# Extra London stock that would lower the price by max_drop on the market curve.
static func market_limit(recipe_key: String, max_drop: float) -> int:
	var exponent := float(GameData.MARKET["curveExponent"])
	var growth := pow(1.0 - max_drop, -1.0 / exponent) - 1.0
	return int(floor(Market.stock("consumable", recipe_key) * growth))


# Units the rule would sell at today's stock and price.
static func sellable_qty(recipe_key: String) -> int:
	var mood: Variant = _config()["moods"].get(rule(recipe_key)["mood"])
	if mood == null:
		return 0
	var min_price: float = Market.base_price("consumable", recipe_key) * float(mood["minPriceMult"])
	if float(Market.quote("consumable", recipe_key)) < min_price - PRICE_EPSILON:
		return 0
	var surplus: int = Crafting.inventory_qty(recipe_key) - protected_floor(recipe_key)
	return clampi(surplus, 0, market_limit(recipe_key, float(mood["maxPriceDrop"])))


# Sells each Production-list recipe's sellable_qty(), lowest tier first, and
# banks the day's total as contract revenue. Returns
# { recipeKey: { qty, income } } for the units sold.
static func daily_pass() -> Dictionary:
	var sold := {}
	if not Contracts.has_staffed_sales() or not Market.is_running():
		return sold
	var total := 0
	for recipe_key in Rooms.production_recipes():
		var qty := sellable_qty(recipe_key)
		if qty <= 0:
			continue
		var income := _sell(recipe_key, qty)
		sold[recipe_key] = { "qty": qty, "income": income }
		total += income
	if sold.is_empty():
		return sold
	Contracts.receive_revenue(total, "Auto-sales")
	Contacts.award_contact_xp(Contacts.sales_contact(), "sales", int(_config()["salesXp"]))
	EventBus.state_changed.emit()
	return sold


static func _sell(recipe_key: String, qty: int) -> int:
	var income := 0
	var quote := Market.quote("consumable", recipe_key)
	for lot in Crafting.inventory_remove(recipe_key, qty):
		var tier: int = lot["tier"]
		var price := GameState.round_epsilon(quote * Economy.quality_price_multiplier(tier))
		income += Market.line_total("consumable", price, lot["qty"])
		Market.record_supply("consumable", recipe_key, lot["qty"], "player", tier)
	return income
