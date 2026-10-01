class_name Partners
extends RefCounted

# Partner perks (R§3.10 "Partners"), data in constants.json partners.
# Player side: a price favour on a partner's shop for a relation cost, a
# partner in trouble asking the player for a deal, warnings of planned moves
# against the player, help in vein-defence fights and intel leaks. Faction
# side: partner factions warn each other of queued raids, help each other's
# defence in faction raids, sell each other short goods at a partner's rate
# and leak intel. Static funcs only.

const TROUBLE_KIND := "partner_trouble"
const ASK_GOODS := "goods"
const ASK_PREMIUM := "premium"
const ASK_CASH := "cash"
const OPTION_SELL := "sell"
const OPTION_CONTRACT := "contract"
const OPTION_BUY := "buy"
const OPTION_SEND := "send"
const TROUBLE_TEMPLATE := "partnerTrouble"


static func _cfg() -> Dictionary:
	return GameData.PARTNERS


# state.partners: priceFavours { factionId: untilDay }, lastPriceAsk
# { factionId: day }, lastTrouble { factionId or pair key: day }, warned
# { partnerId: { aggressorId: day } }.
static func new_state() -> Dictionary:
	return { "priceFavours": {}, "lastPriceAsk": {}, "lastTrouble": {}, "warned": {} }


static func _state() -> Dictionary:
	return GameState.state["partners"]


static func _day() -> int:
	return int(GameState.state["world"]["day"])


static func _line(faction_id: String, key: String) -> String:
	return _cfg()["lines"][faction_id][key]


static func _name(actor: String) -> String:
	return GameData.FACTIONS[actor]["shortName"]


static func _good_name(kind: String, good_type: String) -> String:
	return GameData.ORE_TYPES[good_type]["name"] if kind == "ore" else GameData.RECIPES[good_type]["name"]


static func is_player_partner(faction_id: String) -> bool:
	return FactionAI.player_stance(faction_id) == FactionAI.PARTNER


static func _player_relation(faction_id: String) -> int:
	return int(GameState.state["factions"][faction_id]["relation"])


# Partner stance with the player and player relation at least min_relation.
static func _close_partner(faction_id: String, min_relation: int) -> bool:
	return is_player_partner(faction_id) and _player_relation(faction_id) >= min_relation


# Every faction pair at Partner stance, as [a, b] in data order.
static func partner_pairs() -> Array:
	var pairs := []
	var ids: Array = GameData.FACTIONS.keys()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			if FactionAI.pair_stance(ids[i], ids[j]) == FactionAI.PARTNER:
				pairs.append([ids[i], ids[j]])
	return pairs


# faction_id's Partner factions with pair relation at least min_relation,
# excluding `except`.
static func _faction_partners(faction_id: String, min_relation: int, except: String = "") -> Array:
	var partners := []
	for other in GameData.FACTIONS.keys():
		if other != faction_id and other != except and FactionAI.pair_stance(faction_id, other) == FactionAI.PARTNER and Factions.get_relation(faction_id, other) >= min_relation:
			partners.append(other)
	return partners


# A partner only speaks of an aggressor it isn't Hostile-band with.
static func _on_terms(partner: String, aggressor: String) -> bool:
	return FactionAI.relation_toward(partner, aggressor) > int(GameData.FACTION_STANCES["hostileAtOrBelow"])


# ── Price favour (player → partner) ──────────────────────────────────────

static func can_ask_price_favour(faction_id: String) -> Dictionary:
	var cfg: Dictionary = _cfg()["priceFavour"]
	if not is_player_partner(faction_id):
		return { "ok": false, "reason": "Only partners do favours on price." }
	if price_favour_active(faction_id):
		return { "ok": false, "reason": "You already have their partner rate." }
	var last := int(_state()["lastPriceAsk"].get(faction_id, -1))
	if last >= 0 and _day() - last < int(cfg["cooldownDays"]):
		return { "ok": false, "reason": "Too soon to ask again." }
	return { "ok": true }


# −relationCost now; the partner's shop sells to the player at
# (1 − discount) for `days`.
static func ask_price_favour(faction_id: String) -> Dictionary:
	var check := can_ask_price_favour(faction_id)
	if not check["ok"]:
		return check
	var cfg: Dictionary = _cfg()["priceFavour"]
	Factions.adjust_player_relation(faction_id, -int(cfg["relationCost"]))
	_state()["priceFavours"][faction_id] = _day() + int(cfg["days"])
	_state()["lastPriceAsk"][faction_id] = _day()
	KeyMembers.send(faction_id, _line(faction_id, "priceFavour"))
	EventBus.state_changed.emit()
	return { "ok": true }


static func price_favour_until(faction_id: String) -> int:
	return int(_state()["priceFavours"].get(faction_id, -1))


# Runs to its until-day while the faction stays a Partner.
static func price_favour_active(faction_id: String) -> bool:
	return is_player_partner(faction_id) and _day() <= price_favour_until(faction_id)


# Multiplier on the faction's shop buy prices to the player.
static func price_mult(faction_id: String) -> float:
	return 1.0 - float(_cfg()["priceFavour"]["discount"]) if price_favour_active(faction_id) else 1.0


# ── Trouble (partner → player, and between partner factions) ─────────────

# The good faction_id is furthest under its reserve, by £ value of the gap:
# { kind, type, gap, short } (short = held under holdingsShare × reserve),
# or {} when it holds every reserve.
static func needed_good(faction_id: String) -> Dictionary:
	var best := {}
	var best_value := 0
	for good in FactionSim.traded_goods(faction_id):
		var reserve := FactionSim.reserve(faction_id, good["kind"], good["type"])
		var held := FactionSim.held(faction_id, good["kind"], good["type"])
		var gap := reserve - held
		if gap <= 0:
			continue
		var value := Market.line_total(good["kind"], Market.quote(good["kind"], good["type"]), gap)
		if value > best_value:
			best_value = value
			best = { "kind": good["kind"], "type": good["type"], "gap": gap, "short": held < float(_cfg()["trouble"]["holdingsShare"]) * reserve }
	return best


static func cash_short(faction_id: String) -> bool:
	return int(GameState.state["factions"][faction_id]["resources"]) < int(_cfg()["trouble"]["cashBelow"])


# The good faction_id holds most of beyond its reserve, by £ value:
# { kind, type, surplus }, or {}.
static func _surplus_good(faction_id: String) -> Dictionary:
	var best := {}
	var best_value := 0
	for good in FactionSim.traded_goods(faction_id):
		var surplus := FactionSim.for_sale(faction_id, good["kind"], good["type"]) - FactionSim.reserve(faction_id, good["kind"], good["type"])
		if surplus <= 0:
			continue
		var value := Market.line_total(good["kind"], Market.quote(good["kind"], good["type"]), surplus)
		if value > best_value:
			best_value = value
			best = { "kind": good["kind"], "type": good["type"], "surplus": surplus }
	return best


static func _unit_price(kind: String, good_type: String, mult: float) -> int:
	return maxi(1, GameState.round_epsilon(Market.quote(kind, good_type) * mult))


# The asks faction_id can make of the player today, as payloads (no
# expiresDay). Goods trouble: a discounted goods ask. Cash trouble: a
# discounted goods ask, a premium sale of its surplus, or a cash ask.
static func trouble_asks(faction_id: String) -> Array:
	var cfg: Dictionary = _cfg()["trouble"]
	var need := needed_good(faction_id)
	var broke := cash_short(faction_id)
	if not broke and not need.get("short", false):
		return []
	var budget := mini(int(cfg["maxValue"]), int(GameState.state["factions"][faction_id]["resources"]))
	var asks := []
	if not need.is_empty():
		var price := _unit_price(need["kind"], need["type"], float(cfg["discountMult"]))
		var qty := mini(int(need["gap"]), Market.affordable_qty(need["kind"], price, budget))
		if qty > 0:
			asks.append({ "factionId": faction_id, "ask": ASK_GOODS, "kind": need["kind"], "type": need["type"], "qty": qty, "unitPrice": price })
	if broke:
		var spare := _surplus_good(faction_id)
		if not spare.is_empty():
			var price := _unit_price(spare["kind"], spare["type"], float(cfg["premiumMult"]))
			var qty := mini(int(spare["surplus"]), Market.affordable_qty(spare["kind"], price, int(cfg["maxValue"])))
			if qty > 0:
				asks.append({ "factionId": faction_id, "ask": ASK_PREMIUM, "kind": spare["kind"], "type": spare["type"], "qty": qty, "unitPrice": price })
		asks.append({ "factionId": faction_id, "ask": ASK_CASH, "amount": int(cfg["cashAsk"]) })
	return asks


static func trouble_text(payload: Dictionary) -> String:
	var faction_id: String = payload["factionId"]
	match payload["ask"]:
		ASK_GOODS:
			return _line(faction_id, "troubleGoods") % [_good_name(payload["kind"], payload["type"]), int(payload["qty"]), int(payload["unitPrice"])]
		ASK_PREMIUM:
			return _line(faction_id, "troublePremium") % [int(payload["qty"]), _good_name(payload["kind"], payload["type"]), int(payload["unitPrice"])]
	return _line(faction_id, "troubleCash") % int(payload["amount"])


static func pending_for(faction_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in GameState.state["pendingMessages"]:
		if entry["kind"] == TROUBLE_KIND and entry["payload"].get("factionId", "") == faction_id:
			entries.append(entry)
	return entries


static func _find_pending(pending_id: String) -> Dictionary:
	for entry in GameState.state["pendingMessages"]:
		if entry["id"] == pending_id and entry["kind"] == TROUBLE_KIND:
			return entry
	return {}


static func _cooled(key: String) -> bool:
	var last := int(_state()["lastTrouble"].get(key, -1))
	return last < 0 or _day() - last >= int(_cfg()["trouble"]["cooldownDays"])


# Each partner of the player in trouble may send one ask: key member can
# speak, none pending, cooldown run, issueChance rolls.
static func issue_trouble_asks() -> void:
	for faction_id in GameData.FACTIONS.keys():
		if not is_player_partner(faction_id) or not KeyMembers.can_speak(faction_id):
			continue
		if not pending_for(faction_id).is_empty() or not _cooled(faction_id):
			continue
		var asks := trouble_asks(faction_id)
		if asks.is_empty() or not Rng.chance(float(_cfg()["trouble"]["issueChance"])):
			continue
		var payload: Dictionary = Rng.rand_from(asks)
		payload["expiresDay"] = _day() + int(_cfg()["trouble"]["expiryDays"])
		if KeyMembers.send(faction_id, trouble_text(payload), TROUBLE_KIND, payload):
			_state()["lastTrouble"][faction_id] = _day()


static func _drop_lapsed_asks() -> void:
	var day := _day()
	GameState.state["pendingMessages"] = GameState.state["pendingMessages"].filter(func(e: Dictionary) -> bool:
		return e["kind"] != TROUBLE_KIND or day <= int(e["payload"].get("expiresDay", 0)))


# The ways the player can answer an ask: goods → sell now or sign a
# contract; premium → buy; cash → send.
static func trouble_options(payload: Dictionary) -> Array[String]:
	match payload["ask"]:
		ASK_GOODS:
			return [OPTION_SELL, OPTION_CONTRACT]
		ASK_PREMIUM:
			return [OPTION_BUY]
	return [OPTION_SEND]


static func trouble_total(payload: Dictionary) -> int:
	if payload["ask"] == ASK_CASH:
		return int(payload["amount"])
	return Market.line_total(payload["kind"], int(payload["unitPrice"]), int(payload["qty"]))


# Player's units of a good, all tiers.
static func player_held(kind: String, good_type: String) -> int:
	if kind == "ore":
		return int(GameState.state["player"]["orichalchum"].get(good_type, 0))
	return Crafting.inventory_qty(good_type)


# Answers an ask with one of trouble_options(). Refused past expiresDay or
# when the player can't do it; a success resolves the ask, +relationGain,
# and the key member thanks the player.
static func accept_trouble(pending_id: String, option: String) -> Dictionary:
	var entry := _find_pending(pending_id)
	if entry.is_empty():
		return { "ok": false, "reason": "Request not found." }
	var payload: Dictionary = entry["payload"]
	if _day() > int(payload["expiresDay"]):
		Messages.resolve_pending(pending_id)
		return { "ok": false, "reason": "They've sorted it elsewhere." }
	if not trouble_options(payload).has(option):
		return { "ok": false, "reason": "Not an option here." }
	var faction_id: String = payload["factionId"]
	var result := _settle_option(faction_id, payload, option)
	if not result.get("ok", false):
		return result
	Messages.resolve_pending(pending_id)
	Factions.adjust_player_relation(faction_id, int(_cfg()["trouble"]["relationGain"]))
	KeyMembers.send(faction_id, _line(faction_id, "thanks"))
	EventBus.state_changed.emit()
	return result


static func _settle_option(faction_id: String, payload: Dictionary, option: String) -> Dictionary:
	match option:
		OPTION_SELL:
			var qty := mini(int(payload["qty"]), player_held(payload["kind"], payload["type"]))
			if qty <= 0:
				return { "ok": false, "reason": "You don't have any." }
			return Economy.execute_faction_sale(faction_id, [{ "kind": payload["kind"], "type": payload["type"], "qty": qty }], "", true, int(payload["unitPrice"]))
		OPTION_CONTRACT:
			if not Contracts.has_staffed_sales():
				return { "ok": false, "reason": "You need a working Sales contact to fill it." }
			var request := { "kind": payload["kind"], "type": payload["type"], "qty": int(payload["qty"]) }
			return Offers.sign_favour_contract(TROUBLE_TEMPLATE, faction_id, request, trouble_total(payload), int(_cfg()["trouble"]["contractDays"]))
		OPTION_BUY:
			return Economy.execute_faction_purchase(faction_id, [{ "kind": payload["kind"], "type": payload["type"], "qty": int(payload["qty"]) }], int(payload["unitPrice"]))
	var amount := int(payload["amount"])
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < amount:
		return { "ok": false, "reason": "Not enough cash." }
	player["cash"] -= amount
	GameState.state["factions"][faction_id]["resources"] += amount
	Bank.record(-amount, "Loan to %s" % _name(faction_id))
	return { "ok": true }


# Ignoring costs nothing.
static func decline_trouble(pending_id: String) -> void:
	Messages.resolve_pending(pending_id)


# Between partner factions: a faction short of a good buys it from its
# partner's surplus at discountMult × quote, cooldown per buyer and pair.
static func _help_partner_trade() -> void:
	var cfg: Dictionary = _cfg()["trouble"]
	for pair in partner_pairs():
		for side in [[pair[0], pair[1]], [pair[1], pair[0]]]:
			var buyer: String = side[0]
			var seller: String = side[1]
			var key := "%s>%s" % [seller, buyer]
			if not _cooled(key):
				continue
			var need := needed_good(buyer)
			if not need.get("short", false):
				continue
			var spare := FactionSim.for_sale(seller, need["kind"], need["type"]) - FactionSim.reserve(seller, need["kind"], need["type"])
			var price := _unit_price(need["kind"], need["type"], float(cfg["discountMult"]))
			var qty := mini(mini(int(need["gap"]), spare), Market.affordable_qty(need["kind"], price, int(GameState.state["factions"][buyer]["resources"])))
			if qty <= 0 or not Rng.chance(float(cfg["issueChance"])):
				continue
			_transfer_goods(seller, buyer, need["kind"], need["type"], qty, Market.line_total(need["kind"], price, qty))
			_state()["lastTrouble"][key] = _day()
			Factions.adjust_relation(seller, buyer, int(cfg["pairRelationGain"]))
			var good := _good_name(need["kind"], need["type"])
			FactionAI.log_activity(seller, _cfg()["log"]["tradeHelp"] % [good, _name(buyer)])
			FactionAI.log_activity(buyer, _cfg()["log"]["tradeHelped"] % [good, _name(seller)])


static func _transfer_goods(seller: String, buyer: String, kind: String, good_type: String, qty: int, total: int) -> void:
	var factions: Dictionary = GameState.state["factions"]
	factions[buyer]["resources"] -= total
	factions[seller]["resources"] += total
	if kind == "ore":
		FactionSim.take_ore(seller, good_type, qty)
		FactionSim.add_ore(buyer, good_type, qty)
	else:
		for leg in FactionSim.take_items(seller, good_type, qty):
			FactionSim.add_item(buyer, good_type, leg["tier"], leg["qty"])


# ── Warnings ─────────────────────────────────────────────────────────────

static func _warned_recently(partner: String, aggressor: String) -> bool:
	var last := int(_state()["warned"].get(partner, {}).get(aggressor, -1))
	return last >= 0 and _day() - last < int(_cfg()["warnings"]["repeatDays"])


# Each partner at ≥ minRelation warns the player of the soonest move another
# faction plans against them within horizonDays, when the partner is above
# the Hostile band with that aggressor; once per aggressor per repeatDays.
static func warn_player() -> void:
	var cfg: Dictionary = _cfg()["warnings"]
	var plans := FactionAI.planned_moves(int(cfg["horizonDays"])).filter(func(p: Dictionary) -> bool:
		return p["targetId"] == Shares.PLAYER and p["move"] != FactionAI.PLAN_WARNING)
	for partner in GameData.FACTIONS.keys():
		if not _close_partner(partner, int(cfg["minRelation"])) or not KeyMembers.can_speak(partner):
			continue
		for plan in plans:
			var aggressor: String = plan["factionId"]
			if aggressor == partner or not _on_terms(partner, aggressor) or _warned_recently(partner, aggressor):
				continue
			var text := _line(partner, "warn") % [_name(aggressor), NetworkHandler.move_label(plan), NetworkHandler.when_text(int(plan["day"]))]
			KeyMembers.send(partner, "%s %s" % [text, _line(partner, "how")])
			if not _state()["warned"].has(partner):
				_state()["warned"][partner] = {}
			_state()["warned"][partner][aggressor] = _day()


# A queued raid on a faction is flagged warnedBy its first partner at
# ≥ minRelation that is above the Hostile band with the attacker.
static func warn_factions() -> void:
	var min_relation := int(_cfg()["warnings"]["minRelation"])
	for entry in GameState.state["factionEscalation"]["queuedRaids"]:
		var target: String = entry.get("targetId", "")
		if target == Shares.PLAYER or entry.has("warnedBy"):
			continue
		var attacker: String = entry["attackerId"]
		for partner in _faction_partners(target, min_relation, attacker):
			if _on_terms(partner, attacker):
				entry["warnedBy"] = partner
				FactionAI.log_activity(target, _cfg()["log"]["warnedPair"] % [_name(partner), _name(attacker)])
				FactionAI.log_activity(partner, _cfg()["log"]["warnedHelper"] % [_name(target), _name(attacker)])
				break


# ── Defence help ─────────────────────────────────────────────────────────

# Partners at ≥ minRelation (not the attacker) each roll `chance` to send a
# fighter into the player's vein-defence fight.
static func defence_helpers(attacker_id: String) -> Array[String]:
	var cfg: Dictionary = _cfg()["defenceHelp"]
	var helpers: Array[String] = []
	for faction_id in GameData.FACTIONS.keys():
		if faction_id != attacker_id and _close_partner(faction_id, int(cfg["minRelation"])) and Rng.chance(float(cfg["chance"])):
			helpers.append(faction_id)
	return helpers


static func helper_name(faction_id: String) -> String:
	return _cfg()["defenceHelp"]["names"][faction_id]


static func join_line(faction_id: String) -> String:
	return _cfg()["defenceHelp"]["joinLine"] % helper_name(faction_id)


# Raid odds taken off attacker_id's faction raid on defender_id:
# warnedOddsCut when a partner warned of it, plus oddsCut when the
# defender's first partner at ≥ minRelation (not the attacker) rolls to help.
static func faction_defence_cut(attacker_id: String, defender_id: String, warned_by: String) -> float:
	var cfg: Dictionary = _cfg()["raidHelp"]
	var cut := float(cfg["warnedOddsCut"]) if warned_by != "" else 0.0
	var helpers := _faction_partners(defender_id, int(cfg["minRelation"]), attacker_id)
	if not helpers.is_empty() and Rng.chance(float(cfg["chance"])):
		var helper: String = helpers[0]
		cut += float(cfg["oddsCut"])
		FactionAI.log_activity(helper, _cfg()["log"]["raidHelp"] % [_name(defender_id), _name(attacker_id)])
		FactionAI.log_activity(defender_id, _cfg()["log"]["raidHelped"] % [_name(helper), _name(attacker_id)])
	return cut


# ── Leaks ────────────────────────────────────────────────────────────────

# The third actor (not giver or receiver) on which giver's intel most
# exceeds receiver's: { target, gap }, or {}.
static func _leak_target(giver: String, receiver: String) -> Dictionary:
	var best := {}
	for target in Intel.actors():
		if target == giver or target == receiver:
			continue
		var gap := Intel.meter(giver, target) - Intel.meter(receiver, target)
		if gap > int(best.get("gap", 0)):
			best = { "target": target, "gap": gap }
	return best


static func _leak(giver: String, receiver: String) -> String:
	var lead := _leak_target(giver, receiver)
	if lead.is_empty() or not Rng.chance(float(_cfg()["leaks"]["chance"])):
		return ""
	Intel.raise(receiver, lead["target"], mini(int(_cfg()["leaks"]["amount"]), int(lead["gap"])))
	return lead["target"]


# Partners of the player leak what they know on other factions; partner
# factions leak to each other on any third actor.
static func leak_intel() -> void:
	for faction_id in GameData.FACTIONS.keys():
		if is_player_partner(faction_id) and KeyMembers.can_speak(faction_id):
			var target := _leak(faction_id, Shares.PLAYER)
			if target != "":
				KeyMembers.send(faction_id, _line(faction_id, "leak") % _name(target))
	for pair in partner_pairs():
		_leak(pair[0], pair[1])
		_leak(pair[1], pair[0])


# Rollover step ⑥.5j2: drop lapsed asks, issue new ones, partner factions
# trade, warnings (after ⑥.5h queued today's raids), then leaks.
static func daily_tick() -> void:
	_drop_lapsed_asks()
	issue_trouble_asks()
	_help_partner_trade()
	warn_player()
	warn_factions()
	leak_intel()
	EventBus.state_changed.emit()
