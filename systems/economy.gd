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


# Archie's ore price (per Market.price_lot units) before his cut: today's London quote with the
# district/omen modifier on top (R§3.6).
static func get_archie_ore_price(ore_type: String, price_mod: float) -> int:
	return GameState.round_epsilon(Market.quote("ore", ore_type) * (1.0 + price_mod))


# Archie's per-unit consumable price before his cut: London quote, then the
# tier's quality multiplier, then the district/omen modifier (R§3.6).
static func get_archie_consumable_price(recipe_key: String, tier: int, price_mod: float) -> int:
	return GameState.round_epsilon(Market.quote("consumable", recipe_key) * quality_price_multiplier(tier) * (1.0 + price_mod))


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
			gross += Market.line_total("ore", get_archie_ore_price(item_type, price_mod), qty)
			player["orichalchum"][item_type] = maxi(0, player["orichalchum"].get(item_type, 0) - qty)
			# Recorded before the mugging roll: goods change hands either way.
			Market.record_supply("ore", item_type, qty, "player")
		elif kind == "consumable":
			var tier: int = item.get("tier", 0)
			gross += Market.line_total("consumable", get_archie_consumable_price(item_type, tier, price_mod), qty)
			cons_sold += qty
			Crafting.inventory_remove_from_tier(item_type, tier, qty)
			Market.record_supply("consumable", item_type, qty, "player")

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


# state.sellState (R§2) backs the sell_menu modal's qty sliders; screens
# can't mutate it directly, hence these UI-support funcs. max_qty is the
# row's ceiling: held qty to sell, get_faction_buy_max_qty() to buy.
static func set_sell_qty(key: String, qty: int, max_qty: int) -> void:
	GameState.state["sellState"][key] = clampi(qty, 0, maxi(max_qty, 0))
	EventBus.state_changed.emit()


static func clear_sell_state() -> void:
	GameState.state["sellState"] = {}
	EventBus.state_changed.emit()


# A vein isn't stackable, so this is a plain 0/1 flip (unlike set_sell_qty);
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
# player-cut split -- a faction trades at the London quote
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


# London quote (R§3.13), plus the district modifier where the lane applies
# it. apply_district false prices without the district modifier whatever the
# lane's setting -- business purchases never read the player's location.
static func _faction_effective_price(faction_id: String, kind: String, item_type: String, apply_district: bool = true) -> int:
	var price := Market.quote(kind, item_type)
	var config: Dictionary = GameData.FACTION_TRADE[faction_id]
	if apply_district and config.get("applyDistrictPriceMod", false):
		var district: Dictionary = GameData.DISTRICTS.get(GameState.state["world"]["currentDistrict"], {})
		var price_mod: float = district.get("priceMod", 0.0)
		price = GameState.round_epsilon(price * (1.0 + price_mod))
	return price


# The Network's price gouge on the player (R§3.6a) multiplies its lane.
static func get_faction_buy_price(faction_id: String, kind: String, item_type: String, apply_district: bool = true) -> int:
	var effective := _faction_effective_price(faction_id, kind, item_type, apply_district)
	var gouge := FactionAI.gouge_mult(Shares.PLAYER) if faction_id == "network" else 1.0
	return GameState.round_epsilon(effective * (1.0 + get_faction_buy_spread(faction_id)) * gouge)


static func get_faction_sell_price(faction_id: String, kind: String, item_type: String) -> int:
	var effective := _faction_effective_price(faction_id, kind, item_type)
	return GameState.round_epsilon(effective * (1.0 - get_faction_sell_spread(faction_id)))


# The Guild marketplace's and sell menu's buy-row qty sliders need a
# buy-side ceiling: what the budget affords, capped by what the faction
# will sell (FactionSim.for_sale: all ore, items not reserved for vein kits).
# budget < 0 means the player's cash; a business purchase passes its own.
static func get_faction_buy_max_qty(faction_id: String, kind: String, item_type: String, budget: int = -1, apply_district: bool = true) -> int:
	var price := get_faction_buy_price(faction_id, kind, item_type, apply_district)
	var cash: int = GameState.state["player"]["cash"] if budget < 0 else budget
	var affordable := Market.affordable_qty(kind, maxi(price, 1), cash)
	return mini(affordable, FactionSim.for_sale(faction_id, kind, item_type))


# items: [{ kind:"ore"|"consumable", type:String, qty:int }, ...]. All-or-
# nothing against both cash and holdings: a purchase exceeding either is
# rejected outright, never partially filled. The price lands in the
# faction's resources; items arrive at the tiers held, highest first.
static func execute_faction_purchase(faction_id: String, items: Array) -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to buy." }

	var player: Dictionary = GameState.state["player"]
	var total_cost := 0
	var qty_totals: Dictionary = {}
	for item in items:
		var price := get_faction_buy_price(faction_id, item["kind"], item["type"])
		total_cost += Market.line_total(item["kind"], price, int(item["qty"]))
		var key := [item["kind"], item["type"]]
		qty_totals[key] = qty_totals.get(key, 0) + int(item["qty"])

	if player["cash"] < total_cost:
		return { "ok": false, "reason": "Not enough cash." }

	for key in qty_totals:
		if qty_totals[key] > FactionSim.for_sale(faction_id, key[0], key[1]):
			return { "ok": false, "reason": "Not enough stock." }

	player["cash"] -= total_cost
	GameState.state["factions"][faction_id]["resources"] += total_cost
	Bank.record(-total_cost, "%s purchase" % faction_id.capitalize())
	for item in items:
		var kind: String = item["kind"]
		var item_type: String = item["type"]
		var qty: int = item["qty"]
		if kind == "ore":
			# Taint first: the stock rise below can deliver and settle at once.
			Contracts.note_player_supplied(item_type)
			receive_faction_ore(faction_id, item_type, qty)
			Market.record_demand("ore", item_type, qty, "player")
		else:
			for leg in FactionSim.take_items(faction_id, item_type, qty):
				Crafting.inventory_add(item_type, leg["tier"], leg["qty"])
			Market.record_demand("consumable", item_type, qty, "player")
	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true, "cost": total_cost }


# The stock side of buying ore from a faction lane, shared by the player's
# purchase and the business's calc purchases: the faction's holdings drop,
# shared stock rises, and Sales re-checks deliveries. Payment is the
# caller's to settle.
static func receive_faction_ore(faction_id: String, ore_type: String, qty: int) -> void:
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	orichalchum[ore_type] = orichalchum.get(ore_type, 0) + qty
	FactionSim.take_ore(faction_id, ore_type, qty)


# Whether the player can currently buy from a faction lane: a member-only
# lane needs membership; any other lane opens with its unlockFlag.
static func can_buy_from_faction(faction_id: String) -> bool:
	var config: Dictionary = GameData.FACTION_TRADE[faction_id]
	if config.get("memberOnly", false):
		return bool(GameState.state["factions"][faction_id]["joined"])
	var unlock_flag: String = config.get("unlockFlag", "")
	return unlock_flag != "" and bool(GameState.state["flags"].get(unlock_flag, false))


# How many units of one good the faction's resources can pay for -- the sell
# rows' ceiling beside what the player has.
static func get_faction_sell_max_qty(faction_id: String, kind: String, item_type: String) -> int:
	var price := get_faction_sell_price(faction_id, kind, item_type)
	var resources: int = GameState.state["factions"][faction_id]["resources"]
	return Market.affordable_qty(kind, maxi(price, 1), resources)


# Symmetric counterpart to execute_faction_purchase -- straight sale at the
# spread-narrowed price, no mugging/cut. Goods join the faction's holdings
# (items at their tier) and are paid from its resources, which never go
# below £0: each line scales down to what the wallet has left, and a sale
# it can't afford at all is refused. An item line may carry a "tier";
# without one, stock leaves lowest tier first. contact_id ("" for every
# lane but Collective's) additionally feeds the vendor's own
# personal-relation lane. "sold" lists the lines actually settled.
# wallet_capped false (a questline order) pays every line in full and
# floors the faction's resources at £0 instead of scaling down.
static func execute_faction_sale(faction_id: String, items: Array, contact_id: String = "", wallet_capped: bool = true) -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to sell." }

	var player: Dictionary = GameState.state["player"]
	var faction: Dictionary = GameState.state["factions"][faction_id]
	var ore_sold: Dictionary = faction["oreSold"]
	var total_earned := 0
	var sold: Array = []
	for item in items:
		var kind: String = item["kind"]
		var item_type: String = item["type"]
		var price := get_faction_sell_price(faction_id, kind, item_type)
		var qty: int = item["qty"]
		if wallet_capped and price > 0:
			qty = mini(qty, Market.affordable_qty(kind, price, int(faction["resources"]) - total_earned))
		if qty <= 0:
			continue
		total_earned += Market.line_total(kind, price, qty)
		Market.record_supply(kind, item_type, qty, "player")
		if kind == "ore":
			player["orichalchum"][item_type] = maxi(0, player["orichalchum"].get(item_type, 0) - qty)
			FactionSim.add_ore(faction_id, item_type, qty)
			# Lifetime cumulative sold-to-this-faction bookkeeping --
			# Objectives' traded_with_faction evaluator's data source.
			var entry: Dictionary = ore_sold.get(item_type, { "units": 0, "transactions": 0 })
			entry["units"] += qty
			entry["transactions"] += 1
			ore_sold[item_type] = entry
		else:
			for leg in _take_player_items(item_type, qty, int(item.get("tier", -1))):
				FactionSim.add_item(faction_id, item_type, leg["tier"], leg["qty"])
		sold.append({ "kind": kind, "type": item_type, "qty": qty })

	if sold.is_empty():
		return { "ok": false, "reason": "They can't afford that." }

	faction["resources"] = maxi(0, int(faction["resources"]) - total_earned)
	player["cash"] += total_earned
	Bank.record(total_earned, "%s sale" % faction_id.capitalize())
	RelationAccrual.accrue_faction(faction_id, total_earned)
	if contact_id != "":
		RelationAccrual.accrue_contact_trade(contact_id, total_earned)
	Objectives.refresh()
	EventBus.state_changed.emit()
	return { "ok": true, "earned": total_earned, "sold": sold }


# Removes qty of one item from the player's inventory -- from `tier` when
# it's >= 0, else lowest tier first -- returning [{ tier, qty }, ...].
static func _take_player_items(recipe_key: String, qty: int, tier: int) -> Array:
	if tier >= 0:
		Crafting.inventory_remove_from_tier(recipe_key, tier, qty)
		return [{ "tier": tier, "qty": qty }]
	var buckets: Dictionary = GameState.state["player"]["inventory"].get(recipe_key, {})
	var tier_keys: Array = buckets.keys()
	tier_keys.sort_custom(func(a, b): return int(a) < int(b))
	var legs: Array = []
	var remaining := qty
	for tier_key in tier_keys:
		var take: int = mini(int(buckets[tier_key]), remaining)
		if take > 0:
			legs.append({ "tier": int(tier_key), "qty": take })
			remaining -= take
	for leg in legs:
		Crafting.inventory_remove_from_tier(recipe_key, leg["tier"], leg["qty"])
	return legs


# Faction-lane counterpart to sell_from_sell_state(): same sellState cart
# and item-building, settled via execute_faction_sale() (not Archie's
# cut-and-mugging execute_sale()); item lines keep their tier so the
# faction holds them at it. Toggled "vein_<id>"/"buyVein_<id>" keys ride along in
# the same cart/Go tap but settle individually via
# VeinTrade.sell_to_faction()/buy_from_faction() (execute_faction_sale only
# knows ore/consumable); buy price subtracts from `earned` so it stays the
# trade's net cash change. "buyOre_<type>"/"buyCon_<recipeKey>" keys settle together via
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
				items.append({ "kind": "consumable", "type": recipe_key, "tier": int(tier_key), "qty": qty })

	var buy_items: Array = []
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = sell_state.get("buyOre_%s" % ore_type, 0)
		if qty > 0:
			buy_items.append({ "kind": "ore", "type": ore_type, "qty": qty })
	for recipe_key in GameData.CONSUMABLE_PRICES.keys():
		var qty: int = sell_state.get("buyCon_%s" % recipe_key, 0)
		if qty > 0:
			buy_items.append({ "kind": "consumable", "type": recipe_key, "qty": qty })

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

	if items.is_empty() and vein_ids.is_empty() and buy_vein_ids.is_empty() and buy_items.is_empty():
		return { "ok": false, "reason": "Nothing to trade." }

	var earned := 0
	if not items.is_empty():
		var item_result := execute_faction_sale(faction_id, items, contact_id)
		earned += item_result.get("earned", 0)

	if not buy_items.is_empty():
		var buy_result := execute_faction_purchase(faction_id, buy_items)
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


# A faction shop's Trade-menu confirm (no contact attached): settles the cart
# against the faction's holdings and cash, then shows the sale result.
static func complete_shop_trade(faction_id: String) -> Dictionary:
	var result := sell_to_faction_from_sell_state(faction_id)
	if result.get("ok", false):
		Modal.open("sale_result", { "earned": result["earned"], "gross": result["earned"], "mugged": false })
	return result
