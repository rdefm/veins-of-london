class_name Economy
extends RefCounted

# Selling (Archie lane) per R§3.6. Static funcs only.

const MUG_BASE_CHANCE := 0.20

# vein-trade-assets ticket 02: DRAFT, flagged for human review, not a
# confirmed number. A vein sale needs to be a genuine alternative to the
# faction lane's no-cut/no-risk sale, not strictly worse -- 35% over quote
# (before Archie's own cut) is a first proposal, not spec'd.
const ARCHIE_VEIN_MARKUP := 1.35

# vein-trade-assets ticket 02: DRAFT, flagged for human review. Lower than
# MUG_BASE_CHANCE (0.20) per spec -- a vein sale should roll a lower base
# mugging chance than the ordinary ore/item lane, in exchange for the
# roster it rolls against being harder (Combat.HARD_MUGGER_* above). Not a
# confirmed number.
const MUG_BASE_CHANCE_VEIN := 0.12

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


# vein-trade-assets ticket 02: Archie's vein price -- VeinTrade.quote()
# (the same base quote the faction lane and standalone vein-list Sell flow
# both use) marked up by ARCHIE_VEIN_MARKUP, *before* his cut ratio below
# is applied to it (his cut applies on top, same as it does for ore/items).
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
# vein-trade-assets ticket 02: a "vein" item carries only the id, not a
# pre-computed price -- same convention ore/consumable items already use
# (price computed fresh in here from current state), not something the
# caller works out ahead of time.
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
	var vein_included := false

	for item in items:
		var kind: String = item["kind"]
		if kind == "vein":
			# vein-trade-assets ticket 02, spec: "goods leave the player's
			# hands as part of executing the sale, before the mugging outcome
			# is known" -- same shape ore/consumables already have in this
			# loop (deducted/removed unconditionally below), just with a
			# vein at stake instead. The transfer (VeinTrade.transfer_to_
			# faction) is unconditional here; only the cash (folded into
			# gross -> player_cut below) is contingent on the mugging roll.
			# This means a lost mugging pays nothing for the vein even though
			# it's already gone -- per the ticket, that's the *intended*
			# shape (matching existing ore/item behaviour in this lane), not
			# an oversight.
			#
			# Routes through VeinTrade.SELL_FACTION_ID ("collective") the
			# same way ticket 01's faction lane does -- Archie fences it on,
			# he doesn't hold veins himself. RelationAccrual inside
			# transfer_to_faction is fed the plain VeinTrade.quote() (the
			# vein's real worth to the faction receiving it), not Archie's
			# markup below -- his markup/cut/relation are a player<->Archie
			# concern (folded into gross), not the Collective's.
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
	# vein-trade-assets ticket 02, spec: a trade including a vein rolls a
	# lower base mugging chance (MUG_BASE_CHANCE_VEIN, DRAFT) than the
	# ordinary ore/item rate -- against a harder roster (Combat.start_mugging's
	# vein_included argument below), not a softer one.
	var mug_base: float = MUG_BASE_CHANCE_VEIN if vein_included else MUG_BASE_CHANCE
	var mugged: bool = Rng.chance(Barometer.get_effective_mug_chance(mug_base + danger_mod))

	if mugged:
		# No sale_result modal yet — outcome isn't known until the mugging
		# resolves; complete_mugged_sale() opens it once that happens. The
		# sell_menu modal that was still open when "Go" was pressed has to be
		# closed explicitly here (unlike the non-mugged branch below, which
		# implicitly replaces it via Modal.open("sale_result", ...)) --
		# otherwise ModalLayer stays visible over the freshly-started combat
		# screen, its dim background swallowing every tap, and the sell menu
		# sits there instead of Attack/Run/Item.
		Modal.close()
		GameState.state["pendingSaleCut"] = player_cut
		Combat.start_mugging(vein_included)
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


# vein-trade-assets ticket 01: the faction lane's Assets cart row -- a vein
# isn't stackable, so unlike adjust_sell_qty above this is a plain 0/1
# include/exclude flip, not a clamped +/- delta. Same "vein_<id>" key space
# as the ore_<type>/con_<recipeKey>_<tier> keys sell_to_faction_from_sell_state
# below reads back out.
static func toggle_sell_vein(vein_id: String) -> void:
	var sell_state: Dictionary = GameState.state["sellState"]
	var key := "vein_%s" % vein_id
	sell_state[key] = 0 if sell_state.get(key, 0) > 0 else 1
	EventBus.state_changed.emit()


# vein-trade-assets ticket 03: the buy-side counterpart to toggle_sell_vein()
# above -- a "buyVein_<id>" key (distinct from "vein_<id>", so a sell row and
# a buy row can never collide in the cart) toggling one of the faction's own
# site veins into the same batched trade, read back by
# sell_to_faction_from_sell_state() below.
static func toggle_buy_vein(vein_id: String) -> void:
	var sell_state: Dictionary = GameState.state["sellState"]
	var key := "buyVein_%s" % vein_id
	sell_state[key] = 0 if sell_state.get(key, 0) > 0 else 1
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

	# vein-trade-assets ticket 02: same "vein_<id>" toggle keys toggle_sell_vein
	# writes and the faction lane's sell_to_faction_from_sell_state already
	# reads -- Archie's Assets section (modal_layer.gd) reuses the identical
	# toggle wiring, just folding into execute_sale's item list instead.
	if GameState.state["flags"].get("veinSaleUnlocked", false):
		for vein in GameState.state["player"]["veins"]:
			if sell_state.get("vein_%s" % vein["id"], 0) > 0:
				items.append({ "kind": "vein", "veinId": vein["id"] })

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
#
# collective-ore-stock T02: an ore row's ceiling is also capped by the
# faction's oreStock for that type, when present -- Guild (and every other
# non-Collective faction) never has oreStock entries (T01 only ever rolls
# "collective"'s), so `stock.has(item_type)` is false there and this stays
# cash-only, unaffected. Consumables have no stock concept at all (T01's
# explicit "ore only"), so the cap only ever applies for kind == "ore".
static func get_faction_buy_max_qty(faction_id: String, kind: String, item_type: String) -> int:
	var price := get_faction_buy_price(faction_id, kind, item_type)
	var cash: int = GameState.state["player"]["cash"]
	var affordable := int(floor(float(cash) / float(maxi(price, 1))))
	if kind == "ore":
		var stock: Dictionary = GameState.state["factions"][faction_id]["oreStock"]
		if stock.has(item_type):
			affordable = mini(affordable, int(stock[item_type]))
	return affordable


# items: [{ kind:"ore"|"consumable", type:String, qty:int }, ...]. All-or-
# nothing: rejects the whole purchase if total cost exceeds cash, mirroring
# execute_sale's shape (deducts cash, adds inventory on success).
#
# collective-ore-stock T02: also all-or-nothing against oreStock, the same
# shape as the cash check -- a purchase asking for more of an ore type than
# the faction currently has in stock is rejected outright, never partially
# filled. Only ever bites for "collective" in this milestone (the only
# faction T01 ever rolls oreStock entries for); every other faction's
# oreStock stays `{}`, so `stock.has(ore_type)` is false and this is a
# no-op for them, same as get_faction_buy_max_qty above.
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
			player["orichalchum"][item_type] = player["orichalchum"].get(item_type, 0) + qty
			if stock.has(item_type):
				stock[item_type] -= qty
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
#
# 109-collective-vendor-door-personal-relation: contact_id ("" for every
# lane but Collective's) additionally feeds the trading vendor's own
# personal-relation lane, alongside (not instead of) the faction accrual
# below -- Collective.complete_trade() is the only caller that passes one.
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
	if contact_id != "":
		RelationAccrual.accrue_contact_trade(contact_id, total_earned)
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
#
# vein-trade-assets ticket 01: any "vein_<id>" keys toggled on ride along in
# the same cart/same Go tap -- one sale, not a second confirm step (spec's
# guard for that is the Go button's own label, built by the caller from this
# result's veinsSold). Each selected vein is sold through VeinTrade.
# sell_to_faction() individually (that's the single existing vein-sale code
# path -- collective1-05's standalone quote-and-confirm flow reuses the same
# call), since execute_faction_sale() below only knows ore/consumable items;
# a veins-only cart skips calling it at all rather than tripping its own
# empty-items rejection.
#
# vein-trade-assets ticket 03: "buyVein_<id>" keys (toggle_buy_vein() above)
# ride along the same way, in the opposite direction -- gathered from the
# faction's own live site.factionVein roster rather than player.veins, each
# bought individually through VeinTrade.buy_from_faction(), its price
# subtracted from `earned` rather than added (result.earned is always the
# trade's net cash change, same figure the modal's "You'll get/pay" label and
# the player's actual cash delta agree on -- not a separate "spent" total).
#
# collective-ore-stock T02: "buyOre_<type>" keys (the modal's new Ore-
# section buy rows) ride along the same way, gathered into one items array
# and settled through execute_faction_purchase() as a single all-or-nothing
# call (its own stock/cash gate) -- unlike the per-vein buy loop below,
# these aren't individually toggled units, so one call covers every ore
# type bought this trade. A rejected purchase (stock ran out from under it
# between render and Go) just contributes nothing to `earned`, same silent-
# skip shape a failed vein buy/sell already has here.
# 109-collective-vendor-door-personal-relation: contact_id ("" for every
# caller but Collective.complete_trade) rides along to every leg below
# (item sale, vein sold, vein bought) so a trade through Des/Nadia/Hakim's
# door builds that specific vendor's own relation, same "a trade is a
# trade" reasoning VeinTrade's own accrue_faction calls already use for the
# faction meter -- see the open question this ticket's issue file called
# out: decided yes, vein legs count too, not just the ore/consumable cart.
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
