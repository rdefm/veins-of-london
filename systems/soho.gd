class_name Soho
extends RefCounted

# Soho Marketplace (R§3.13): the player buys and sells ore and tiered items
# against London stock. Fees come from rung ladders in market.json `soho`, set by
# the order value of the whole cart; the rung's rate applies to the whole order.
# Pure rows (fee_rows) feed the trading screen and match exactly what trade()
# charges. No mugging, relation gain or Archie cut; sales draw on the shared
# pool only, purchases land in it at the tier bought.

const SELL := "sell"
const BUY := "buy"


static func _cfg() -> Dictionary:
	return GameData.MARKET["soho"]


static func is_unlocked() -> bool:
	return bool(GameState.state["flags"].get(_cfg()["unlockFlag"], false))


# Archie's fee as a fraction of gross (1 - his cut ratio, which tracks relation).
static func archie_fee_rate() -> float:
	return 1.0 - Economy.get_archie_cut_ratio()


static func _rungs(side: String) -> Array:
	return _cfg()["sellRungs"] if side == SELL else _cfg()["buyRungs"]


# Rate of rung `index`. Sell: Archie's fee + margin less the rung's reduction,
# floored. Buy: the rung's markup.
static func rung_rate(side: String, index: int) -> float:
	var rung: Dictionary = _rungs(side)[index]
	if side == BUY:
		return float(rung["rate"])
	var rate: float = archie_fee_rate() + float(_cfg()["sellMargin"]) - float(rung["reduction"])
	return maxf(rate, float(_cfg()["sellFloor"]))


static func rung_index(side: String, order_value: int) -> int:
	var rungs := _rungs(side)
	var index := 0
	for i in rungs.size():
		if order_value >= int(rungs[i]["from"]):
			index = i
	return index


# A good Soho trades: any good the market lists (stock is base items, never multi-target variants).
static func is_tradable(kind: String, good_type: String, _side: String) -> bool:
	return GameData.MARKET["goods"].get(kind, {}).has(good_type)


# £ for one cart line at today's London quote (items at the tier's price).
static func line_value(line: Dictionary) -> int:
	var qty: int = int(line.get("qty", 0))
	if line["kind"] == "ore":
		return Market.line_total("ore", Market.quote("ore", line["type"]), qty)
	return Market.tier_price(line["type"], int(line.get("tier", 1))) * qty


# Merges duplicate goods and tiers and drops empty lines; ore carries tier 0.
static func normalise_cart(cart: Array) -> Array:
	var merged := {}
	var order: Array = []
	for line in cart:
		var qty: int = int(line.get("qty", 0))
		if qty <= 0:
			continue
		var kind: String = line["kind"]
		var tier: int = 0 if kind == "ore" else clampi(int(line.get("tier", 1)), 1, Market.tier_count())
		var key := "%s:%s:%d" % [kind, line["type"], tier]
		if not merged.has(key):
			merged[key] = { "kind": kind, "type": line["type"], "tier": tier, "qty": 0 }
			order.append(key)
		merged[key]["qty"] = int(merged[key]["qty"]) + qty
	var lines: Array = []
	for key in order:
		lines.append(merged[key])
	return lines


static func order_value(cart: Array) -> int:
	var total := 0
	for line in normalise_cart(cart):
		total += line_value(line)
	return total


static func _units(cart: Array) -> int:
	var total := 0
	for line in normalise_cart(cart):
		total += int(line["qty"])
	return total


static func _fee(value: int, rate: float) -> int:
	if value <= 0:
		return 0
	return maxi(1, GameState.round_epsilon(float(value) * rate))


# Everything the screen shows for the current order. `net` is the cash change
# (sell: value - fee; buy: -(value + fee)).
static func fee_rows(side: String, cart: Array) -> Dictionary:
	var value := order_value(cart)
	var units := _units(cart)
	var rungs := _rungs(side)
	var index := rung_index(side, value)
	var rate := rung_rate(side, index)
	var fee := _fee(value, rate)
	var rows := {
		"side": side,
		"value": value,
		"units": units,
		"rung": index,
		"rungCount": rungs.size(),
		"rate": rate,
		"fee": fee,
		"net": value - fee if side == SELL else -(value + fee),
		"isTop": index == rungs.size() - 1,
		"next": {},
		"ladder": [],
		"archieFeeRate": archie_fee_rate(),
		"archieFee": 0,
		"archieNet": 0,
	}
	if index < rungs.size() - 1:
		var need_value: int = int(rungs[index + 1]["from"]) - value
		var unit_value: float = float(value) / float(units) if units > 0 else 0.0
		rows["next"] = {
			"from": int(rungs[index + 1]["from"]),
			"rate": rung_rate(side, index + 1),
			"needValue": need_value,
			"needUnits": int(ceil(float(need_value) / unit_value)) if unit_value > 0.0 else 0,
		}
	for i in rungs.size():
		rows["ladder"].append({ "from": int(rungs[i]["from"]), "rate": rung_rate(side, i), "active": i == index })
	if side == SELL:
		rows["archieNet"] = int(floor(value * Economy.get_archie_cut_ratio()))
		rows["archieFee"] = value - rows["archieNet"]
	return rows


# Units of a good (and tier) the player can sell: the shared pool only.
static func sellable_qty(kind: String, good_type: String, tier: int = 0) -> int:
	if kind == "ore":
		return int(GameState.state["player"]["orichalchum"].get(good_type, 0))
	return int(GameState.state["player"]["inventory"].get(good_type, {}).get(str(tier), 0))


# Units London can supply of a good (and tier) right now.
static func buyable_qty(kind: String, good_type: String, tier: int = 0) -> int:
	return int(Market.availability(kind, good_type).get(0 if kind == "ore" else tier, 0))


# Why the cart can't trade, or "" when it can.
static func check(side: String, cart: Array) -> String:
	if not is_unlocked():
		return "Soho is not open yet."
	var lines := normalise_cart(cart)
	if lines.is_empty():
		return "Nothing in the order."
	for line in lines:
		if not is_tradable(line["kind"], line["type"], side):
			return "Soho does not trade that."
		if side == SELL and int(line["qty"]) > sellable_qty(line["kind"], line["type"], int(line["tier"])):
			return "Not enough in the shared pool."
		if side == BUY and int(line["qty"]) > buyable_qty(line["kind"], line["type"], int(line["tier"])):
			return "London does not have that much."
	if side == BUY and -int(fee_rows(side, lines)["net"]) > int(GameState.state["player"]["cash"]):
		return "Not enough cash."
	return ""


# Executes the cart; the cash moved is exactly fee_rows(side, cart)["net"].
static func trade(side: String, cart: Array) -> Dictionary:
	var reason := check(side, cart)
	if reason != "":
		return { "ok": false, "reason": reason }
	var lines := normalise_cart(cart)
	var rows := fee_rows(side, lines)
	var player: Dictionary = GameState.state["player"]
	for line in lines:
		var kind: String = line["kind"]
		var good_type: String = line["type"]
		var tier: int = int(line["tier"])
		var qty: int = int(line["qty"])
		if side == SELL:
			if kind == "ore":
				player["orichalchum"][good_type] = int(player["orichalchum"].get(good_type, 0)) - qty
				Market.record_supply("ore", good_type, qty, "player")
			else:
				Crafting.inventory_remove_from_tier(good_type, tier, qty)
				Market.record_supply("consumable", good_type, qty, "player", tier)
		else:
			Market.record_demand(kind, good_type, qty, "player", tier)
			if kind == "ore":
				player["orichalchum"][good_type] = int(player["orichalchum"].get(good_type, 0)) + qty
			else:
				Crafting.inventory_add(good_type, tier, qty)
	player["cash"] = int(player["cash"]) + int(rows["net"])
	Bank.record(int(rows["net"]), "Soho sale" if side == SELL else "Soho purchase")
	if side == SELL:
		BusinessStats.record_sale(int(rows["net"]))
	Objectives.refresh()
	EventBus.mark_changed()
	return { "ok": true, "rows": rows }
