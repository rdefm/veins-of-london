class_name Economy
extends RefCounted

# Selling (Archie lane) per R§3.6. Static funcs only.

const PLAYER_CUT_RATIO := 0.5
const MUG_BASE_CHANCE := 0.20


# items: [{ kind:"ore"|"consumable", type:String, qty:int }, ...]
static func execute_sale(items: Array) -> Dictionary:
	if items.is_empty():
		return { "ok": false, "reason": "Nothing to sell." }

	var player: Dictionary = GameState.state["player"]
	var gross := 0
	var cons_sold := 0

	for item in items:
		var kind: String = item["kind"]
		var item_type: String = item["type"]
		var qty: int = item["qty"]
		if kind == "ore":
			var base_price: int = GameData.ORE_TYPES[item_type]["basePrice"]
			var price_per_unit: int = Barometer.get_effective_ore_price(item_type, base_price)
			gross += price_per_unit * qty
			player["orichalchum"][item_type] = maxi(0, player["orichalchum"].get(item_type, 0) - qty)
		elif kind == "consumable":
			var price_per_unit: int = GameData.CONSUMABLE_PRICES.get(item_type, 30)
			gross += price_per_unit * qty
			cons_sold += qty
			player["inventory"][item_type] = maxi(0, player["inventory"].get(item_type, 0) - qty)

	if cons_sold > 0:
		var flags: Dictionary = GameState.state["flags"]
		flags["consSoldCount"] = flags["consSoldCount"] + cons_sold
		if not flags["archieMotionEventSeen"] and not flags["archieMotionPending"] and flags["consSoldCount"] >= 1:
			flags["archieMotionPending"] = true
			Notify.push("Archie texted. Check Contacts.")

	var player_cut: int = int(floor(gross * PLAYER_CUT_RATIO))
	var mugged: bool = Rng.chance(Barometer.get_effective_mug_chance(MUG_BASE_CHANCE))

	if mugged:
		GameState.state["pendingSaleCut"] = player_cut
		Combat.start_mugging()
		EventBus.state_changed.emit()
		return { "ok": true, "mugged": true, "gross": gross }
	else:
		player["cash"] += player_cut
		EventBus.state_changed.emit()
		return { "ok": true, "mugged": false, "earned": player_cut, "gross": gross }


# Called by combat.gd's (T08) onWin dispatch on "muggingWon".
static func complete_mugged_sale() -> Dictionary:
	var earned: int = GameState.state["pendingSaleCut"]
	GameState.state["pendingSaleCut"] = 0
	if earned > 0:
		GameState.state["player"]["cash"] += earned
	EventBus.state_changed.emit()
	return { "earned": earned, "gross": earned * 2, "mugged": true }
