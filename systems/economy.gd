class_name Economy
extends RefCounted

# Selling (Archie lane) per R§3.6. Static funcs only.

const PLAYER_CUT_RATIO := 0.5
const MUG_BASE_CHANCE := 0.20

# Guild marketplace spread (bugfixes-28): ±15% at the Guild join threshold
# (state.factions.guild.relation == GameData.FACTIONS.guild.joinRelation),
# narrowing linearly to 0% by relation 90, then flat. Human-confirmed curve —
# no REFERENCE.md precedent for this, see .scratch/0-bugfixes/issues/28.
const GUILD_SPREAD_MAX := 0.15
const GUILD_SPREAD_ZERO_RELATION := 90


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
			var price_per_unit: int = GameState.round_epsilon(GameData.CONSUMABLE_PRICES.get(item_type, 30) * (1.0 + price_mod))
			gross += price_per_unit * qty
			cons_sold += qty
			player["inventory"][item_type] = maxi(0, player["inventory"].get(item_type, 0) - qty)

	if cons_sold > 0:
		flags["consSoldCount"] = flags["consSoldCount"] + cons_sold
		if not flags["archieMotionEventSeen"] and not flags["archieMotionPending"] and flags["consSoldCount"] >= 1:
			flags["archieMotionPending"] = true
			Notify.push("Archie texted. Check Contacts.")

	var player_cut: int = int(floor(gross * PLAYER_CUT_RATIO))
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
		Modal.open("sale_result", { "earned": player_cut, "gross": gross, "mugged": false })
		return { "ok": true, "mugged": false, "earned": player_cut, "gross": gross }


# Called by combat.gd's (T08) onWin dispatch on "muggingWon".
static func complete_mugged_sale() -> Dictionary:
	var earned: int = GameState.state["pendingSaleCut"]
	GameState.state["pendingSaleCut"] = 0
	if earned > 0:
		GameState.state["player"]["cash"] += earned
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


# Builds the items array from sellState + current stock (ore_<type> /
# con_<recipeKey> keys, matching the HTML's doSell()), then sells it.
static func sell_from_sell_state() -> Dictionary:
	var sell_state: Dictionary = GameState.state["sellState"]
	var items: Array = []

	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = sell_state.get("ore_%s" % ore_type, 0)
		if qty > 0:
			items.append({ "kind": "ore", "type": ore_type, "qty": qty })

	for recipe_key in GameData.CONSUMABLE_PRICES.keys():
		var qty: int = sell_state.get("con_%s" % recipe_key, 0)
		if qty > 0:
			items.append({ "kind": "consumable", "type": recipe_key, "qty": qty })

	clear_sell_state()
	return execute_sale(items)


# ── Guild marketplace (bugfixes-28) ─────────────────────────────────────
# A separate pricing/transaction lane from the Archie sell flow above: no
# mugging risk, no district price_mod/danger_mod, no player-cut split — the
# Guild trades at ticker-effective base price plus/minus a relation-narrowed
# spread. Screen/gating work is bugfixes-29.

static func get_guild_spread() -> float:
	var relation: int = GameState.state["factions"]["guild"]["relation"]
	var anchor: int = GameData.FACTIONS["guild"]["joinRelation"]
	if relation <= anchor:
		return GUILD_SPREAD_MAX
	if relation >= GUILD_SPREAD_ZERO_RELATION:
		return 0.0
	var span := float(GUILD_SPREAD_ZERO_RELATION - anchor)
	return GUILD_SPREAD_MAX * float(GUILD_SPREAD_ZERO_RELATION - relation) / span


static func _guild_base_price(kind: String, item_type: String) -> int:
	if kind == "ore":
		return GameData.ORE_TYPES[item_type]["basePrice"]
	return GameData.CONSUMABLE_PRICES.get(item_type, 30)


static func _guild_effective_price(kind: String, item_type: String) -> int:
	var base_price := _guild_base_price(kind, item_type)
	if kind == "ore":
		return Barometer.get_effective_ore_price(item_type, base_price)
	return base_price


static func get_guild_buy_price(kind: String, item_type: String) -> int:
	var effective := _guild_effective_price(kind, item_type)
	return GameState.round_epsilon(effective * (1.0 + get_guild_spread()))


static func get_guild_sell_price(kind: String, item_type: String) -> int:
	var effective := _guild_effective_price(kind, item_type)
	return GameState.round_epsilon(effective * (1.0 - get_guild_spread()))


# items: [{ kind:"ore"|"consumable", type:String, qty:int }, ...]. All-or-
# nothing: rejects the whole purchase if total cost exceeds cash, mirroring
# execute_sale's shape (deducts cash, adds inventory on success).
static func execute_guild_purchase(items: Array) -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to buy." }

	var player: Dictionary = GameState.state["player"]
	var total_cost := 0
	for item in items:
		var price_per_unit := get_guild_buy_price(item["kind"], item["type"])
		total_cost += price_per_unit * int(item["qty"])

	if player["cash"] < total_cost:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= total_cost
	for item in items:
		var kind: String = item["kind"]
		var item_type: String = item["type"]
		var qty: int = item["qty"]
		if kind == "ore":
			player["orichalchum"][item_type] = player["orichalchum"].get(item_type, 0) + qty
		else:
			player["inventory"][item_type] = player["inventory"].get(item_type, 0) + qty

	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true, "cost": total_cost }


# Symmetric counterpart to execute_guild_purchase — straight sale at the
# Guild's spread-narrowed price, no mugging/cut (that's the Archie lane's
# execute_sale, unrelated to this one).
static func execute_guild_sale(items: Array) -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to sell." }

	var player: Dictionary = GameState.state["player"]
	var total_earned := 0
	for item in items:
		var kind: String = item["kind"]
		var item_type: String = item["type"]
		var qty: int = item["qty"]
		var price_per_unit := get_guild_sell_price(kind, item_type)
		total_earned += price_per_unit * qty
		if kind == "ore":
			player["orichalchum"][item_type] = maxi(0, player["orichalchum"].get(item_type, 0) - qty)
		else:
			player["inventory"][item_type] = maxi(0, player["inventory"].get(item_type, 0) - qty)

	player["cash"] += total_earned
	EventBus.state_changed.emit()
	return { "ok": true, "earned": total_earned }
