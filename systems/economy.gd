class_name Economy
extends RefCounted

# Selling (Archie lane, R§3.6) and faction trade lanes. Static funcs only.

const MUG_BASE_CHANCE := 0.20

# DRAFT, flagged for human review.
const ARCHIE_VEIN_MARKUP := 1.35  # keeps a vein sale genuinely better than the faction lane's no-cut/no-risk sale
const MUG_BASE_CHANCE_VEIN := 0.12  # lower than MUG_BASE_CHANCE; offset by a harder mugger roster (Combat.start_mugging)

# Smaller than James's +5/job (sales are more frequent); adds to, not
# replaces, RelationAccrual's tradeProgress accumulator (R§3.6).
const ARCHIE_SALE_RELATION_GAIN := 2

# Linear 0.60->0.85 across relation 10->80, flat outside (R§3.6, confirmed curve).
const ARCHIE_CUT_RATIO_MIN := 0.60
const ARCHIE_CUT_RATIO_MAX := 0.85
const ARCHIE_CUT_RELATION_MIN := 10
const ARCHIE_CUT_RELATION_MAX := 80

# +25% per quality tier over 1, doubling at tier 5 (R§3.6); tier 0
# (untiered/legacy stock) prices as tier 1 since its quality is unknown.
const QUALITY_PRICE_STEP := 0.25


static func quality_price_multiplier(tier: int) -> float:
	return 1.0 + QUALITY_PRICE_STEP * float(maxi(tier, 1) - 1)


# VeinTrade.quote() (the same base quote the faction lane uses) marked up
# by ARCHIE_VEIN_MARKUP, before his cut ratio is applied on top.
static func get_archie_vein_price(vein: Dictionary) -> int:
	return GameState.round_epsilon(VeinTrade.quote(vein) * ARCHIE_VEIN_MARKUP)


static func get_archie_cut_ratio() -> float:
	var relation: int = GameState.state["contacts"]["archie"]["relation"]
	if relation <= ARCHIE_CUT_RELATION_MIN:
		return ARCHIE_CUT_RATIO_MIN
	if relation >= ARCHIE_CUT_RELATION_MAX:
		return ARCHIE_CUT_RATIO_MAX
	var span := float(ARCHIE_CUT_RELATION_MAX - ARCHIE_CUT_RELATION_MIN)
	return ARCHIE_CUT_RATIO_MIN + (ARCHIE_CUT_RATIO_MAX - ARCHIE_CUT_RATIO_MIN) * float(relation - ARCHIE_CUT_RELATION_MIN) / span


# items: [{ kind:"ore"|"consumable", type:String, qty:int } |
#         { kind:"vein", veinId:String }, ...]
# A "vein" item carries only the id; price is computed fresh here from
# current state, same as ore/consumable items.
static func execute_sale(items: Array) -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to sell." }

	var player: Dictionary = GameState.state["player"]
	var district: Dictionary = GameData.DISTRICTS.get(GameState.state["world"]["currentDistrict"], {})
	var price_mod: float = district.get("priceMod", 0.0)
	var danger_mod: float = district.get("dangerMod", 0.0)

	# pigeon_omen (M1-LONDON D5): a one-shot flag, consumed on the very next
	# sale attempt regardless of outcome, with a further 50% chance of a
	# +10% price bump.
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("luckyOmen", false):
		flags["luckyOmen"] = false
		if Rng.chance(0.5):
			price_mod += 0.10

	var gross := 0
	var cons_sold := 0
	var vein_included := false

	for item in items:
		var kind: String = item["kind"]
		if kind == "vein":
			# Vein transfer is unconditional; only the cash (folded into gross
			# -> player_cut) depends on the mugging roll, so a lost mugging
			# still loses the vein. Routes through VeinTrade.SELL_FACTION_ID
			# ("collective") since Archie fences it rather than holding veins
			# himself; RelationAccrual gets the plain VeinTrade.quote(), not
			# Archie's markup below.
			var vein_id: String = item["veinId"]
			var vein: Variant = Cultivating.find_vein(vein_id)
			if vein == null:
				continue
			var transfer_result := VeinTrade.transfer_to_faction(vein_id, VeinTrade.SELL_FACTION_ID, VeinTrade.quote(vein), true)
			if not transfer_result.get("ok", false):
				continue
			gross += get_archie_vein_price(vein)
			vein_included = true
			continue
		var item_type: String = item["type"]
		var qty: int = item["qty"]
		if kind == "ore":
			var base_price: int = GameData.ORE_TYPES[item_type]["basePrice"]
			var price_per_unit: int = GameState.round_epsilon(Barometer.get_effective_ore_price(item_type, base_price) * (1.0 + price_mod))
			gross += price_per_unit * qty
			player["orichalchum"][item_type] = maxi(0, player["orichalchum"].get(item_type, 0) - qty)
		elif kind == "consumable":
			var tier: int = item.get("tier", 0)
			var price_per_unit: int = GameState.round_epsilon(GameData.CONSUMABLE_PRICES.get(item_type, 30) * quality_price_multiplier(tier) * (1.0 + price_mod))
			gross += price_per_unit * qty
			cons_sold += qty
			Crafting.inventory_remove_from_tier(item_type, tier, qty)

	if cons_sold > 0:
		flags["consSoldCount"] = flags["consSoldCount"] + cons_sold
		if not flags["archieMotionEventSeen"] and not flags["archieMotionPending"] and flags["consSoldCount"] >= 1:
			flags["archieMotionPending"] = true
			# The SMS content itself carries the "Archie texted" beat, so no
			# separate Notify banner is needed on top.
			Messages.queue_pending("archie", "archie_motion", "good output. call me.")

	# Flat award before the cut ratio below, so this sale's own cut reflects it (R§3.6).
	Contacts.award_relation("archie", ARCHIE_SALE_RELATION_GAIN)

	var player_cut: int = int(floor(gross * get_archie_cut_ratio()))

	# Separate tradeProgress accumulator (R§3.6), on top of the flat award
	# above. Computed *after* player_cut so a sale crossing a tradeProgress
	# relation point still cuts at the pre-bump relation.
	RelationAccrual.accrue_archie(gross)
	var mug_base: float = MUG_BASE_CHANCE_VEIN if vein_included else MUG_BASE_CHANCE
	var mugged: bool = Rng.chance(Barometer.get_effective_mug_chance(mug_base + danger_mod))

	if mugged:
		# No sale_result modal yet -- complete_mugged_sale() opens it once the
		# mugging resolves. sell_menu must be closed explicitly here (unlike
		# the non-mugged branch, which implicitly replaces it via Modal.open)
		# or ModalLayer stays visible over combat, swallowing every tap.
		Modal.close()
		GameState.state["pendingSaleCut"] = player_cut
		Combat.start_mugging(vein_included)
		EventBus.state_changed.emit()
		return { "ok": true, "mugged": true, "gross": gross }
	else:
		player["cash"] += player_cut
		Bank.record(player_cut, "Archie sale")
		Objectives.refresh()
		Modal.open("sale_result", { "earned": player_cut, "gross": gross, "mugged": false })
		return { "ok": true, "mugged": false, "earned": player_cut, "gross": gross }


# Called by combat.gd's onWin dispatch on "muggingWon".
static func complete_mugged_sale() -> Dictionary:
	var earned: int = GameState.state["pendingSaleCut"]
	GameState.state["pendingSaleCut"] = 0
	if earned > 0:
		GameState.state["player"]["cash"] += earned
		Bank.record(earned, "Archie sale (contested)")
	Objectives.refresh()
	Modal.open("sale_result", { "earned": earned, "gross": earned * 2, "mugged": true })
	return { "earned": earned, "gross": earned * 2, "mugged": true }


# state.sellState (R§2) backs the sell_menu modal's qty steppers; screens
# can't mutate it directly, hence these UI-support funcs.
static func adjust_sell_qty(key: String, delta: int, max_qty: int) -> void:
	var sell_state: Dictionary = GameState.state["sellState"]
	var current: int = sell_state.get(key, 0)
	sell_state[key] = clampi(current + delta, 0, max_qty)
	EventBus.state_changed.emit()


static func clear_sell_state() -> void:
	GameState.state["sellState"] = {}
	EventBus.state_changed.emit()


# A vein isn't stackable, so this is a plain 0/1 flip (unlike adjust_sell_qty);
# sell_to_faction_from_sell_state() below reads the same "vein_<id>" keys back out.
static func toggle_sell_vein(vein_id: String) -> void:
	var sell_state: Dictionary = GameState.state["sellState"]
	var key := "vein_%s" % vein_id
	sell_state[key] = 0 if sell_state.get(key, 0) > 0 else 1
	EventBus.state_changed.emit()


# Buy-side counterpart to toggle_sell_vein() -- a distinct "buyVein_<id>"
# key so a sell row and a buy row never collide in the same cart.
static func toggle_buy_vein(vein_id: String) -> void:
	var sell_state: Dictionary = GameState.state["sellState"]
	var key := "buyVein_%s" % vein_id
	sell_state[key] = 0 if sell_state.get(key, 0) > 0 else 1
	EventBus.state_changed.emit()


# state.marketplaceQty backs the Guild marketplace's per-row Buy/Sell ×N
# stepper -- one shared qty per row, floored at 1. max_qty is the caller's
# larger of the row's buy/sell ceilings; buttons disable independently past
# their own ceiling.
static func get_marketplace_qty(faction_id: String, kind: String, item_type: String) -> int:
	var key := "%s_%s_%s" % [faction_id, kind, item_type]
	return int(GameState.state["marketplaceQty"].get(key, 1))


static func adjust_marketplace_qty(faction_id: String, kind: String, item_type: String, delta: int, max_qty: int) -> void:
	var key := "%s_%s_%s" % [faction_id, kind, item_type]
	# Stored qty can go stale between renders (a buy/sell shrinks max_qty
	# without touching it; the screen only clamps for display) -- re-clamp
	# against today's max_qty before applying delta.
	var current: int = clampi(get_marketplace_qty(faction_id, kind, item_type), 1, maxi(max_qty, 1))
	GameState.state["marketplaceQty"][key] = clampi(current + delta, 1, maxi(max_qty, 1))
	EventBus.state_changed.emit()


# Builds the items array from sellState + current stock (ore_<type> /
# con_<recipeKey>_<tier> keys), then sells it.
static func sell_from_sell_state() -> Dictionary:
	var sell_state: Dictionary = GameState.state["sellState"]
	var items: Array = []

	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = sell_state.get("ore_%s" % ore_type, 0)
		if qty > 0:
			items.append({ "kind": "ore", "type": ore_type, "qty": qty })

	for recipe_key in GameData.CONSUMABLE_PRICES.keys():
		var buckets: Dictionary = GameState.state["player"]["inventory"].get(recipe_key, {})
		for tier_key in buckets.keys():
			var qty: int = sell_state.get("con_%s_%s" % [recipe_key, tier_key], 0)
			if qty > 0:
				items.append({ "kind": "consumable", "type": recipe_key, "tier": int(tier_key), "qty": qty })

	# Same "vein_<id>" keys toggle_sell_vein()/sell_to_faction_from_sell_state()
	# use; Archie's Assets section reuses the wiring, folded into execute_sale's items.
	if GameState.state["flags"].get("veinSaleUnlocked", false):
		for vein in GameState.state["player"]["veins"]:
			if sell_state.get("vein_%s" % vein["id"], 0) > 0:
				items.append({ "kind": "vein", "veinId": vein["id"] })

	clear_sell_state()
	return execute_sale(items)


# ── Faction trade lanes ──────────────────────────────────────────────────
# A separate pricing/transaction lane from the Archie sell flow above: no
# player-cut split -- a faction trades at ticker-effective base price
# plus/minus a relation-narrowed spread, configured per faction_id in
# data/faction_trade.json (GameData.FACTION_TRADE).

static func _faction_spread(faction_id: String, max_key: String, min_key: String) -> float:
	var config: Dictionary = GameData.FACTION_TRADE[faction_id]
	var anchor: int = config["anchorRelation"]
	var zero_relation: int = config["zeroRelation"]
	var spread_max: float = config[max_key]
	var spread_min: float = config[min_key]
	var relation: int = GameState.state["factions"][faction_id]["relation"]
	if relation <= anchor:
		return spread_max
	if relation >= zero_relation:
		return spread_min
	var span := float(zero_relation - anchor)
	return spread_min + (spread_max - spread_min) * float(zero_relation - relation) / span


# Decoupled from get_faction_buy_spread: the Collective's sell spread is
# wide (0.45->0.05) while its buy spread stays modest (0.15->0.05); the
# Guild's row uses identical max/min for both (symmetric spread).
static func get_faction_sell_spread(faction_id: String) -> float:
	return _faction_spread(faction_id, "sellSpreadMax", "sellSpreadMin")


static func get_faction_buy_spread(faction_id: String) -> float:
	return _faction_spread(faction_id, "buySpreadMax", "buySpreadMin")


static func _faction_base_price(kind: String, item_type: String) -> int:
	if kind == "ore":
		return GameData.ORE_TYPES[item_type]["basePrice"]
	return GameData.CONSUMABLE_PRICES.get(item_type, 30)


# apply_district false prices without the district modifier whatever the
# lane's setting -- business purchases never read the player's location.
static func _faction_effective_price(faction_id: String, kind: String, item_type: String, apply_district: bool = true) -> int:
	var base_price := _faction_base_price(kind, item_type)
	var price: int
	if kind == "ore":
		price = Barometer.get_effective_ore_price(item_type, base_price)
	else:
		price = base_price

	var config: Dictionary = GameData.FACTION_TRADE[faction_id]
	if apply_district and config.get("applyDistrictPriceMod", false):
		var district: Dictionary = GameData.DISTRICTS.get(GameState.state["world"]["currentDistrict"], {})
		var price_mod: float = district.get("priceMod", 0.0)
		price = GameState.round_epsilon(price * (1.0 + price_mod))
	return price


static func get_faction_buy_price(faction_id: String, kind: String, item_type: String, apply_district: bool = true) -> int:
	var effective := _faction_effective_price(faction_id, kind, item_type, apply_district)
	return GameState.round_epsilon(effective * (1.0 + get_faction_buy_spread(faction_id)))


static func get_faction_sell_price(faction_id: String, kind: String, item_type: String) -> int:
	var effective := _faction_effective_price(faction_id, kind, item_type)
	return GameState.round_epsilon(effective * (1.0 - get_faction_sell_spread(faction_id)))


# The Guild marketplace's per-row qty stepper needs a buy-side affordability
# ceiling (cash / price), unlike the raw-stock sell-side ceiling. An ore row is
# further capped by the faction's oreStock when present -- only "collective"
# ever has entries, so every other faction stays cash-only; consumables have no stock concept.
# budget < 0 means the player's cash; a business purchase passes its own.
static func get_faction_buy_max_qty(faction_id: String, kind: String, item_type: String, budget: int = -1, apply_district: bool = true) -> int:
	var price := get_faction_buy_price(faction_id, kind, item_type, apply_district)
	var cash: int = GameState.state["player"]["cash"] if budget < 0 else budget
	var affordable := int(floor(float(cash) / float(maxi(price, 1))))
	if kind == "ore":
		var stock: Dictionary = GameState.state["factions"][faction_id]["oreStock"]
		if stock.has(item_type):
			affordable = mini(affordable, int(stock[item_type]))
	return affordable


# items: [{ kind:"ore"|"consumable", type:String, qty:int }, ...]. All-or-
# nothing against both cash and oreStock (when present): a purchase
# exceeding either is rejected outright, never partially filled.
static func execute_faction_purchase(faction_id: String, items: Array) -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to buy." }

	var player: Dictionary = GameState.state["player"]
	var total_cost := 0
	var ore_qty_totals: Dictionary = {}
	for item in items:
		var price_per_unit := get_faction_buy_price(faction_id, item["kind"], item["type"])
		total_cost += price_per_unit * int(item["qty"])
		if item["kind"] == "ore":
			var ore_type: String = item["type"]
			ore_qty_totals[ore_type] = ore_qty_totals.get(ore_type, 0) + int(item["qty"])

	if player["cash"] < total_cost:
		return { "ok": false, "reason": "Not enough cash." }

	var stock: Dictionary = GameState.state["factions"][faction_id]["oreStock"]
	for ore_type in ore_qty_totals.keys():
		if stock.has(ore_type) and ore_qty_totals[ore_type] > int(stock[ore_type]):
			return { "ok": false, "reason": "Not enough stock." }

	player["cash"] -= total_cost
	Bank.record(-total_cost, "%s purchase" % faction_id.capitalize())
	for item in items:
		var kind: String = item["kind"]
		var item_type: String = item["type"]
		var qty: int = item["qty"]
		if kind == "ore":
			receive_faction_ore(faction_id, item_type, qty)
		else:
			# Store-bought stock wasn't crafted at any tier -- files under the
			# same "0" untiered bucket as legacy saves.
			Crafting.inventory_add(item_type, 0, qty)
	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true, "cost": total_cost }


# The stock side of buying ore from a faction lane, shared by the player's
# purchase and the business's calc purchases: the lane's oreStock (when
# tracked) drops, shared stock rises, and Sales re-checks deliveries.
static func receive_faction_ore(faction_id: String, ore_type: String, qty: int) -> void:
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	orichalchum[ore_type] = orichalchum.get(ore_type, 0) + qty
	var stock: Dictionary = GameState.state["factions"][faction_id]["oreStock"]
	if stock.has(ore_type):
		stock[ore_type] -= qty
	if qty > 0:
		EventBus.shared_stock_increased.emit()


# Whether the player can currently buy from a faction lane: a member-only
# lane needs membership; the Collective's lane opens with its Act 1 intro.
static func can_buy_from_faction(faction_id: String) -> bool:
	var config: Dictionary = GameData.FACTION_TRADE[faction_id]
	if config.get("memberOnly", false):
		return bool(GameState.state["factions"][faction_id]["joined"])
	if faction_id == "collective":
		return bool(GameState.state["flags"].get("collectiveLaneUnlocked", false))
	return true


# Symmetric counterpart to execute_faction_purchase -- straight sale at the
# spread-narrowed price, no mugging/cut. contact_id ("" for every lane but
# Collective's) additionally feeds the vendor's own personal-relation lane.
static func execute_faction_sale(faction_id: String, items: Array, contact_id: String = "") -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to sell." }

	var player: Dictionary = GameState.state["player"]
	var faction: Dictionary = GameState.state["factions"][faction_id]
	var ore_sold: Dictionary = faction["oreSold"]
	var total_earned := 0
	for item in items:
		var kind: String = item["kind"]
		var item_type: String = item["type"]
		var qty: int = item["qty"]
		var price_per_unit := get_faction_sell_price(faction_id, kind, item_type)
		total_earned += price_per_unit * qty
		if kind == "ore":
			player["orichalchum"][item_type] = maxi(0, player["orichalchum"].get(item_type, 0) - qty)
			# Lifetime cumulative sold-to-this-faction bookkeeping --
			# Objectives' traded_with_faction evaluator's data source.
			var entry: Dictionary = ore_sold.get(item_type, { "units": 0, "transactions": 0 })
			entry["units"] += qty
			entry["transactions"] += 1
			ore_sold[item_type] = entry
		else:
			# A faction lane's flat price doesn't vary by tier, so
			# lowest-tier-first consumption is fine.
			Crafting.inventory_remove(item_type, qty)

	player["cash"] += total_earned
	Bank.record(total_earned, "%s sale" % faction_id.capitalize())
	RelationAccrual.accrue_faction(faction_id, total_earned)
	if contact_id != "":
		RelationAccrual.accrue_contact_trade(contact_id, total_earned)
	Objectives.refresh()
	EventBus.state_changed.emit()
	return { "ok": true, "earned": total_earned }


# Faction-lane counterpart to sell_from_sell_state(): same sellState cart
# and item-building, settled via execute_faction_sale() (not Archie's
# cut-and-mugging execute_sale()) -- no tier segment since faction price
# doesn't vary by tier. Toggled "vein_<id>"/"buyVein_<id>" keys ride along in
# the same cart/Go tap but settle individually via
# VeinTrade.sell_to_faction()/buy_from_faction() (execute_faction_sale only
# knows ore/consumable); buy price subtracts from `earned` so it stays the
# trade's net cash change. "buyOre_<type>" keys settle together via
# execute_faction_purchase() as one all-or-nothing call; a rejected purchase
# contributes nothing, same silent-skip as a failed vein buy/sell. contact_id
# ("" for every caller but Collective.complete_trade) rides every leg so a
# trade through a specific vendor builds that vendor's own relation too, not
# just the faction meter.
static func sell_to_faction_from_sell_state(faction_id: String, contact_id: String = "") -> Dictionary:
	var sell_state: Dictionary = GameState.state["sellState"]
	var items: Array = []

	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = sell_state.get("ore_%s" % ore_type, 0)
		if qty > 0:
			items.append({ "kind": "ore", "type": ore_type, "qty": qty })

	for recipe_key in GameData.CONSUMABLE_PRICES.keys():
		var buckets: Dictionary = GameState.state["player"]["inventory"].get(recipe_key, {})
		for tier_key in buckets.keys():
			var qty: int = sell_state.get("con_%s_%s" % [recipe_key, tier_key], 0)
			if qty > 0:
				items.append({ "kind": "consumable", "type": recipe_key, "qty": qty })

	var buy_ore_items: Array = []
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = sell_state.get("buyOre_%s" % ore_type, 0)
		if qty > 0:
			buy_ore_items.append({ "kind": "ore", "type": ore_type, "qty": qty })

	var vein_ids: Array = []
	for vein in GameState.state["player"]["veins"]:
		if sell_state.get("vein_%s" % vein["id"], 0) > 0:
			vein_ids.append(vein["id"])

	var buy_vein_ids: Array = []
	for site in Sites.sites_with_faction_vein(faction_id):
		var faction_vein: Dictionary = site["factionVein"]
		if sell_state.get("buyVein_%s" % faction_vein["id"], 0) > 0:
			buy_vein_ids.append(faction_vein["id"])

	clear_sell_state()

	if items.is_empty() and vein_ids.is_empty() and buy_vein_ids.is_empty() and buy_ore_items.is_empty():
		return { "ok": false, "reason": "Nothing to trade." }

	var earned := 0
	if not items.is_empty():
		var item_result := execute_faction_sale(faction_id, items, contact_id)
		earned += item_result.get("earned", 0)

	if not buy_ore_items.is_empty():
		var buy_result := execute_faction_purchase(faction_id, buy_ore_items)
		if buy_result.get("ok", false):
			earned -= int(buy_result["cost"])

	var veins_sold := 0
	for vein_id in vein_ids:
		var vein_result := VeinTrade.sell_to_faction(vein_id, faction_id, null, contact_id)
		if vein_result.get("ok", false):
			earned += int(vein_result["price"])
			veins_sold += 1

	var veins_bought := 0
	for vein_id in buy_vein_ids:
		var buy_result := VeinTrade.buy_from_faction(vein_id, faction_id, contact_id)
		if buy_result.get("ok", false):
			earned -= int(buy_result["price"])
			veins_bought += 1

	return { "ok": true, "earned": earned, "veinsSold": veins_sold, "veinsBought": veins_bought }
