class_name Economy
extends RefCounted

# Selling (Archie lane) per R§3.6. Static funcs only.

const MUG_BASE_CHANCE := 0.20

# bugfixes-63: relation for selling through Archie, smaller than James's
# +5/job since sales happen far more often. Kept alongside, not replaced by,
# RelationAccrual's £-denominated tradeProgress accumulator (collective1-06,
# spec.md §8.4, human decision) -- see execute_sale below for how the two combine.
const ARCHIE_SALE_RELATION_GAIN := 2

# collective1-01 (R§3.6 amendment): Archie's cut used to be a flat 0.5
# (PLAYER_CUT_RATIO). Now relation-scaled 0.60->0.85 linear across his
# relation 10->80, flat outside — see get_archie_cut_ratio() below.
const ARCHIE_CUT_RATIO_MIN := 0.60
const ARCHIE_CUT_RATIO_MAX := 0.85
const ARCHIE_CUT_RELATION_MIN := 10
const ARCHIE_CUT_RELATION_MAX := 80

# bugfixes-64: a crafted consumable's quality tier (Crafting.quality_tier)
# scales its Archie sale price -- linear, +25% per tier over 1, doubling at
# tier 5. Human-confirmed curve — no REFERENCE.md precedent, see
# .scratch/0-bugfixes/issues/64. Tier 0 (untiered/legacy stock — see
# Crafting's "Inventory" section) prices the same as tier 1: no bonus, no
# penalty, since its quality is genuinely unknown.
const QUALITY_PRICE_STEP := 0.25


static func quality_price_multiplier(tier: int) -> float:
	return 1.0 + QUALITY_PRICE_STEP * float(maxi(tier, 1) - 1)


static func get_archie_cut_ratio() -> float:
	var relation: int = GameState.state["contacts"]["archie"]["relation"]
	if relation <= ARCHIE_CUT_RELATION_MIN:
		return ARCHIE_CUT_RATIO_MIN
	if relation >= ARCHIE_CUT_RELATION_MAX:
		return ARCHIE_CUT_RATIO_MAX
	var span := float(ARCHIE_CUT_RELATION_MAX - ARCHIE_CUT_RELATION_MIN)
	return ARCHIE_CUT_RATIO_MIN + (ARCHIE_CUT_RATIO_MAX - ARCHIE_CUT_RATIO_MIN) * float(relation - ARCHIE_CUT_RELATION_MIN) / span


# items: [{ kind:"ore"|"consumable", type:String, qty:int }, ...]
static func execute_sale(items: Array) -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to sell." }

	var player: Dictionary = GameState.state["player"]
	var district: Dictionary = GameData.DISTRICTS.get(GameState.state["world"]["currentDistrict"], {})
	var price_mod: float = district.get("priceMod", 0.0)
	var danger_mod: float = district.get("dangerMod", 0.0)

	# pigeon_omen (M1-LONDON D5): a one-shot flag, consumed on the very next
	# sale attempt regardless of outcome; that sale then has a further 50%
	# chance of a +10% price bump.
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("luckyOmen", false):
		flags["luckyOmen"] = false
		if Rng.chance(0.5):
			price_mod += 0.10

	var gross := 0
	var cons_sold := 0

	for item in items:
		var kind: String = item["kind"]
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
			# 83-contacts-archie-james-sms-port: the SMS content itself (the
			# quoted text is ARCHIE_MOTION_CARDS' own opening narration line)
			# now carries the "Archie texted" beat, so it doesn't need a
			# separate Notify banner on top -- same as every other pendingMessages
			# trigger (archie_cultivation.json's col_a1_intro, col_a1_seeding.json's
			# col_a1_hub) never pairs queue_pending_message with a notify op.
			Messages.queue_pending("archie", "archie_motion", "good output. call me.")

	# bugfixes-63: flat award, before the cut ratio below so this same sale's
	# cut reflects it (unchanged behavior since bugfixes-63).
	Contacts.award_relation("archie", ARCHIE_SALE_RELATION_GAIN)

	var player_cut: int = int(floor(gross * get_archie_cut_ratio()))

	# collective1-06, spec §8.4: the separate tradeProgress accumulator, on
	# top of the flat award above, not instead of it (human decision — see
	# spec.md §8.4's addendum). Accrues on gross, independent of the mugging
	# roll below (relation reflects trade that happened, not what actually
	# landed in pocket) -- and deliberately *after* player_cut is computed, so
	# a single sale big enough to cross a tradeProgress relation point this
	# same call still gets its own cut at the relation it had after the flat
	# award, not the one this accumulator just bumped it to on top of that.
	RelationAccrual.accrue_archie(gross)
	var mugged: bool = Rng.chance(Barometer.get_effective_mug_chance(MUG_BASE_CHANCE + danger_mod))

	if mugged:
		# No sale_result modal yet — outcome isn't known until the mugging
		# resolves; complete_mugged_sale() opens it once that happens.
		GameState.state["pendingSaleCut"] = player_cut
		Combat.start_mugging()
		EventBus.state_changed.emit()
		return { "ok": true, "mugged": true, "gross": gross }
	else:
		player["cash"] += player_cut
		Bank.record(player_cut, "Archie sale")
		Objectives.refresh()  # collective1-02: boundary — Archie lane completion
		Modal.open("sale_result", { "earned": player_cut, "gross": gross, "mugged": false })
		return { "ok": true, "mugged": false, "earned": player_cut, "gross": gross }


# Called by combat.gd's (T08) onWin dispatch on "muggingWon".
static func complete_mugged_sale() -> Dictionary:
	var earned: int = GameState.state["pendingSaleCut"]
	GameState.state["pendingSaleCut"] = 0
	if earned > 0:
		GameState.state["player"]["cash"] += earned
		Bank.record(earned, "Archie sale (contested)")
	Objectives.refresh()  # collective1-02: boundary — Archie lane completion
	Modal.open("sale_result", { "earned": earned, "gross": earned * 2, "mugged": true })
	return { "earned": earned, "gross": earned * 2, "mugged": true }


# state.sellState (R§2: "sell-menu qty selections, transient") backs the
# sell_menu modal's qty steppers. Screens can't mutate it directly, so
# these exist even though they're UI-support rather than R§3.6 formulas.
static func adjust_sell_qty(key: String, delta: int, max_qty: int) -> void:
	var sell_state: Dictionary = GameState.state["sellState"]
	var current: int = sell_state.get(key, 0)
	sell_state[key] = clampi(current + delta, 0, max_qty)
	EventBus.state_changed.emit()


static func clear_sell_state() -> void:
	GameState.state["sellState"] = {}
	EventBus.state_changed.emit()


# bugfixes-66: state.marketplaceQty backs the Guild marketplace's per-row
# Buy/Sell ×N stepper -- one shared qty per row (not a separate buy/sell
# cart entry like sellState above), floored at 1 rather than sellState's
# floor of 0, since a row's Buy/Sell buttons always act on a positive qty.
# max_qty is the larger of the row's buy-side (affordability) and sell-side
# (stock) ceilings, computed by the caller -- the buttons themselves disable
# independently when qty exceeds their own direction's ceiling.
static func get_marketplace_qty(faction_id: String, kind: String, item_type: String) -> int:
	var key := "%s_%s_%s" % [faction_id, kind, item_type]
	return int(GameState.state["marketplaceQty"].get(key, 1))


static func adjust_marketplace_qty(faction_id: String, kind: String, item_type: String, delta: int, max_qty: int) -> void:
	var key := "%s_%s_%s" % [faction_id, kind, item_type]
	# The stored qty can go stale between renders -- a buy/sell on this row
	# shrinks max_qty without touching the stored value, and the screen only
	# clamps it for display, not in state. Re-clamp the stored value against
	# today's max_qty before applying delta, so a tap always moves the
	# number the player is actually looking at, never a step behind it.
	var current: int = clampi(get_marketplace_qty(faction_id, kind, item_type), 1, maxi(max_qty, 1))
	GameState.state["marketplaceQty"][key] = clampi(current + delta, 1, maxi(max_qty, 1))
	EventBus.state_changed.emit()


# Builds the items array from sellState + current stock (ore_<type> /
# con_<recipeKey>_<tier> keys, matching the HTML's doSell() for ore --
# consumables gained a tier segment in ticket 64 since price now depends on
# it), then sells it.
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

	clear_sell_state()
	return execute_sale(items)


# ── Faction trade lanes (bugfixes-28, generalized by collective1-01) ────
# A separate pricing/transaction lane from the Archie sell flow above: no
# player-cut split — a faction trades at ticker-effective base price
# plus/minus a relation-narrowed spread, configured per faction_id in
# data/faction_trade.json (GameData.FACTION_TRADE). The Guild was the
# original (and, until the Collective, only) caller — GUILD_SPREAD_MAX/
# GUILD_SPREAD_ZERO_RELATION are now that data file's guild row. Screen/
# gating work for the Guild is bugfixes-29.

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


# Decoupled from get_faction_buy_spread (collective1-01 spec.md §8.1): the
# Collective's sell spread is wide (0.45->0.05) while its buy spread stays
# modest (0.15->0.05) — the Guild's row uses identical max/min for both,
# reproducing its old symmetric spread exactly.
static func get_faction_sell_spread(faction_id: String) -> float:
	return _faction_spread(faction_id, "sellSpreadMax", "sellSpreadMin")


static func get_faction_buy_spread(faction_id: String) -> float:
	return _faction_spread(faction_id, "buySpreadMax", "buySpreadMin")


static func _faction_base_price(kind: String, item_type: String) -> int:
	if kind == "ore":
		return GameData.ORE_TYPES[item_type]["basePrice"]
	return GameData.CONSUMABLE_PRICES.get(item_type, 30)


static func _faction_effective_price(faction_id: String, kind: String, item_type: String) -> int:
	var base_price := _faction_base_price(kind, item_type)
	var price: int
	if kind == "ore":
		price = Barometer.get_effective_ore_price(item_type, base_price)
	else:
		price = base_price

	var config: Dictionary = GameData.FACTION_TRADE[faction_id]
	if config.get("applyDistrictPriceMod", false):
		var district: Dictionary = GameData.DISTRICTS.get(GameState.state["world"]["currentDistrict"], {})
		var price_mod: float = district.get("priceMod", 0.0)
		price = GameState.round_epsilon(price * (1.0 + price_mod))
	return price


static func get_faction_buy_price(faction_id: String, kind: String, item_type: String) -> int:
	var effective := _faction_effective_price(faction_id, kind, item_type)
	return GameState.round_epsilon(effective * (1.0 + get_faction_buy_spread(faction_id)))


static func get_faction_sell_price(faction_id: String, kind: String, item_type: String) -> int:
	var effective := _faction_effective_price(faction_id, kind, item_type)
	return GameState.round_epsilon(effective * (1.0 - get_faction_sell_spread(faction_id)))


# bugfixes-66: the Guild marketplace's per-row qty stepper needs a buy-side
# affordability ceiling (how many units of this row the player's current
# cash actually covers) -- a formula, not a raw state field like the
# sell-side ceiling (just player.orichalchum/inventory stock), so it lives
# here rather than inline in the screen.
static func get_faction_buy_max_qty(faction_id: String, kind: String, item_type: String) -> int:
	var price := get_faction_buy_price(faction_id, kind, item_type)
	var cash: int = GameState.state["player"]["cash"]
	return int(floor(float(cash) / float(maxi(price, 1))))


# items: [{ kind:"ore"|"consumable", type:String, qty:int }, ...]. All-or-
# nothing: rejects the whole purchase if total cost exceeds cash, mirroring
# execute_sale's shape (deducts cash, adds inventory on success).
static func execute_faction_purchase(faction_id: String, items: Array) -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to buy." }

	var player: Dictionary = GameState.state["player"]
	var total_cost := 0
	for item in items:
		var price_per_unit := get_faction_buy_price(faction_id, item["kind"], item["type"])
		total_cost += price_per_unit * int(item["qty"])

	if player["cash"] < total_cost:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= total_cost
	Bank.record(-total_cost, "%s purchase" % faction_id.capitalize())
	for item in items:
		var kind: String = item["kind"]
		var item_type: String = item["type"]
		var qty: int = item["qty"]
		if kind == "ore":
			player["orichalchum"][item_type] = player["orichalchum"].get(item_type, 0) + qty
		else:
			# ticket 64: store-bought stock wasn't crafted at any skill/refine
			# tier -- files under the same "0" untiered bucket as legacy saves.
			Crafting.inventory_add(item_type, 0, qty)

	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true, "cost": total_cost }


# Symmetric counterpart to execute_faction_purchase — straight sale at the
# faction's spread-narrowed price, no mugging/cut (that's the Archie lane's
# execute_sale, unrelated to this one).
static func execute_faction_sale(faction_id: String, items: Array) -> Dictionary:
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
			# collective1-02: lifetime cumulative sold-to-this-faction bookkeeping
			# — Objectives' traded_with_faction evaluator's data source (see
			# systems/objectives.gd). One transaction increment per ore type
			# actually present in this call's items, not per unit.
			var entry: Dictionary = ore_sold.get(item_type, { "units": 0, "transactions": 0 })
			entry["units"] += qty
			entry["transactions"] += 1
			ore_sold[item_type] = entry
		else:
			# A faction lane's flat price doesn't vary by tier (only Archie's
			# execute_sale does, ticket 64) -- lowest-tier-first consumption
			# is fine.
			Crafting.inventory_remove(item_type, qty)

	player["cash"] += total_earned
	Bank.record(total_earned, "%s sale" % faction_id.capitalize())
	# collective1-06, spec §8.4: trade feeds the meter that owns the lane --
	# a no-op for factions RelationAccrual.LANES doesn't configure a rate for.
	RelationAccrual.accrue_faction(faction_id, total_earned)
	Objectives.refresh()  # collective1-02: boundary — faction lane completion
	EventBus.state_changed.emit()
	return { "ok": true, "earned": total_earned }


# collective1-07: the faction-lane counterpart to sell_from_sell_state() --
# same sellState cart (state.sellState is transient and always empty when a
# fresh sell_menu opens, since every dismiss path clears it), same item-
# building, but priced and settled through execute_faction_sale() rather
# than Archie's cut-and-mugging execute_sale(). No tier segment on the
# built items: a faction lane's price doesn't vary by tier (only Archie's
# execute_sale does), so summing every tier bucket's selection into one
# per-recipe item is correct here.
static func sell_to_faction_from_sell_state(faction_id: String) -> Dictionary:
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

	clear_sell_state()
	return execute_faction_sale(faction_id, items)
