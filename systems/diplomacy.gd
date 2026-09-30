class_name Diplomacy
extends RefCounted

# Relation levers (R§3.10 "Favours"): factions ask the player favours
# through their key member (data/factions.json sampleFavours, tuning in
# constants.json factionFavours). A deliver or sellBelow favour, once
# accepted, is a one-off Sales contract with the faction (Offers.
# sign_favour_contract); a guardVein or sitOut favour is watched here.
# Gifts (R§3.10 "Gifts"): cash or a consumable to a key member raises their
# and their faction's relation. Static funcs only.

const FAVOUR_KIND := "faction_favour"
const DELIVER := "deliver"
const GUARD_VEIN := "guardVein"
const SIT_OUT := "sitOut"
const SELL_BELOW := "sellBelow"


static func _cfg() -> Dictionary:
	return GameData.FACTION_FAVOURS


# state.favours: accepted [{ factionId, favourId, kind, params, acceptedDay,
# dueDay, contractId?, veinIds? }], lastIssued { factionId: day }.
static func new_state() -> Dictionary:
	return { "accepted": [], "lastIssued": {} }


static func _state() -> Dictionary:
	return GameState.state["favours"]


static func favour_def(faction_id: String, favour_id: String) -> Dictionary:
	for favour in GameData.FACTIONS.get(faction_id, {}).get("sampleFavours", []):
		if favour["id"] == favour_id:
			return favour
	return {}


static func accepted() -> Array:
	return _state()["accepted"]


static func accepted_for(faction_id: String) -> Dictionary:
	for entry in accepted():
		if entry["factionId"] == faction_id:
			return entry
	return {}


static func pending_for(faction_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in GameState.state["pendingMessages"]:
		if entry["kind"] == FAVOUR_KIND and entry["payload"].get("factionId", "") == faction_id:
			entries.append(entry)
	return entries


static func _find_pending(pending_id: String) -> Dictionary:
	for entry in GameState.state["pendingMessages"]:
		if entry["id"] == pending_id and entry["kind"] == FAVOUR_KIND:
			return entry
	return {}


# Rollover step ⑥.5j: settle watched favours, withdraw lapsed requests,
# then each faction may ask one.
static func daily_tick() -> void:
	_settle_watched()
	_drop_lapsed_requests()
	issue_favours()


# A faction asks when its key member can speak, it isn't at war with the
# player, it has no favour pending or accepted, its cooldown has run and
# the issueChance roll lands; the favour is drawn from those the player can
# currently do.
static func issue_favours() -> void:
	var day: int = GameState.state["world"]["day"]
	for faction_id in GameData.FACTIONS.keys():
		if not KeyMembers.can_speak(faction_id) or FactionAI.at_war(Shares.PLAYER, faction_id):
			continue
		if not pending_for(faction_id).is_empty() or not accepted_for(faction_id).is_empty():
			continue
		var last: int = int(_state()["lastIssued"].get(faction_id, -1))
		if last >= 0 and day - last < int(_cfg()["cooldownDays"]):
			continue
		if not Rng.chance(float(_cfg()["issueChance"])):
			continue
		var options: Array = GameData.FACTIONS[faction_id].get("sampleFavours", []).filter(_can_do)
		if options.is_empty():
			continue
		var favour: Dictionary = Rng.rand_from(options)
		var payload := { "factionId": faction_id, "favourId": favour["id"], "expiresDay": day + int(_cfg()["expiryDays"]) }
		if KeyMembers.send(faction_id, favour["text"], FAVOUR_KIND, payload):
			_state()["lastIssued"][faction_id] = day


# Goods favours need a working Sales contact to fill the contract; a guard
# favour needs a vein to guard.
static func _can_do(favour: Dictionary) -> bool:
	match favour["kind"]:
		DELIVER, SELL_BELOW:
			return Contracts.has_staffed_sales()
		GUARD_VEIN:
			return not GameState.state["player"]["veins"].is_empty()
	return true


static func _drop_lapsed_requests() -> void:
	var day: int = GameState.state["world"]["day"]
	GameState.state["pendingMessages"] = GameState.state["pendingMessages"].filter(func(e: Dictionary) -> bool:
		return e["kind"] != FAVOUR_KIND or day <= int(e["payload"].get("expiresDay", 0)))


# Accepting commits the player: goods favours sign their contract now,
# guard and sit-out favours start their watch.
static func accept(pending_id: String) -> Dictionary:
	var entry := _find_pending(pending_id)
	if entry.is_empty():
		return { "ok": false, "reason": "Request not found." }
	var payload: Dictionary = entry["payload"]
	var day: int = GameState.state["world"]["day"]
	if day > int(payload["expiresDay"]):
		Messages.resolve_pending(pending_id)
		return { "ok": false, "reason": "They've stopped asking." }
	var faction_id: String = payload["factionId"]
	var favour := favour_def(faction_id, payload["favourId"])
	if favour.is_empty():
		Messages.resolve_pending(pending_id)
		return { "ok": false, "reason": "Request not found." }
	if not _can_do(favour):
		return { "ok": false, "reason": "You need a working Sales contact to fill it." if favour["kind"] != GUARD_VEIN else "You've no vein to guard." }
	var params: Dictionary = favour["params"]
	var record := {
		"factionId": faction_id, "favourId": favour["id"], "kind": favour["kind"],
		"params": params.duplicate(true), "acceptedDay": day,
		"dueDay": day + int(params.get("days", _cfg()["sellBelowDays"])),
	}
	match favour["kind"]:
		DELIVER, SELL_BELOW:
			var signed := _sign_contract(faction_id, favour, int(record["dueDay"]) - day)
			if not signed.get("ok", false):
				return signed
			record["contractId"] = signed["contract"]["id"]
		GUARD_VEIN:
			var vein_ids: Array = []
			for vein in GameState.state["player"]["veins"]:
				vein_ids.append(vein["id"])
			record["veinIds"] = vein_ids
	Messages.resolve_pending(pending_id)
	accepted().append(record)
	EventBus.state_changed.emit()
	return { "ok": true, "favour": record }


# Ignoring costs nothing.
static func decline(pending_id: String) -> void:
	Messages.resolve_pending(pending_id)


# The request priced at London value × deliverPriceMult (deliver) or the
# favour's own mult (sellBelow).
static func _sign_contract(faction_id: String, favour: Dictionary, days: int) -> Dictionary:
	var params: Dictionary = favour["params"]
	var request := { "kind": params["kind"], "type": params["type"], "qty": int(params["qty"]) }
	var mult := float(params["mult"]) if favour["kind"] == SELL_BELOW else float(_cfg()["deliverPriceMult"])
	var payment := GameState.round_epsilon(float(Offers.quote_for_request(request, 1)["liveValue"]) * mult)
	return Offers.sign_favour_contract(favour["id"], faction_id, request, payment, days)


# Contracts.settle / cancel: a favour contract that closes complete is a
# kept favour; anything else is a failed one.
static func note_contract_closed(contract_id: String, complete: bool) -> void:
	for entry in accepted().duplicate():
		if entry.get("contractId", "") == contract_id:
			_close(entry, complete)
			return


# FactionAI.note_hostile_act: a hostile act by the player against a sit-out
# favour's target fails it.
static func note_player_hostile(target: String) -> void:
	for entry in accepted().duplicate():
		if entry["kind"] == SIT_OUT and entry["params"]["target"] == target:
			_close(entry, false)


# A guard favour fails once any vein it covers leaves the player; guard
# and sit-out favours are kept on reaching their due day.
static func _settle_watched() -> void:
	var day: int = GameState.state["world"]["day"]
	for entry in accepted().duplicate():
		if entry["kind"] == GUARD_VEIN and not _still_held(entry["veinIds"]):
			_close(entry, false)
		elif (entry["kind"] == GUARD_VEIN or entry["kind"] == SIT_OUT) and day >= int(entry["dueDay"]):
			_close(entry, true)


static func _still_held(vein_ids: Array) -> bool:
	var held := {}
	for vein in GameState.state["player"]["veins"]:
		held[vein["id"]] = true
	for vein_id in vein_ids:
		if not held.has(vein_id):
			return false
	return true


# Kept: +relationGain, and +favour intel on each faction the asker is
# Hostile or at war with. Failed: −failRelationLoss. The key member says so.
static func _close(entry: Dictionary, kept: bool) -> void:
	accepted().erase(entry)
	var faction_id: String = entry["factionId"]
	if kept:
		Factions.adjust_player_relation(faction_id, int(_cfg()["relationGain"]))
		for enemy in enemies_of(faction_id):
			Intel.gain(Shares.PLAYER, enemy, Intel.SOURCE_FAVOUR)
	else:
		Factions.adjust_player_relation(faction_id, -int(_cfg()["failRelationLoss"]))
	KeyMembers.send(faction_id, _cfg()["lines"][faction_id]["done" if kept else "failed"])
	EventBus.state_changed.emit()


static func enemies_of(faction_id: String) -> Array[String]:
	var enemies: Array[String] = []
	for other in GameData.FACTIONS.keys():
		if other != faction_id and (FactionAI.pair_stance(faction_id, other) == FactionAI.HOSTILE or FactionAI.at_war(faction_id, other)):
			enemies.append(other)
	return enemies


# One line for the Factions app: what an accepted favour asks and by when.
static func describe(entry: Dictionary) -> String:
	var params: Dictionary = entry["params"]
	var due := Calendar.format_day(int(entry["dueDay"]))
	match entry["kind"]:
		DELIVER, SELL_BELOW:
			return "Deliver %d %s by %s" % [int(params["qty"]), _good_name(params["kind"], params["type"]), due]
		GUARD_VEIN:
			return "Hold every vein until %s" % due
		SIT_OUT:
			return "Leave %s alone until %s" % [GameData.FACTIONS[params["target"]]["shortName"], due]
	return ""


static func _good_name(kind: String, good_type: String) -> String:
	return GameData.ORE_TYPES[good_type]["name"] if kind == "ore" else GameData.RECIPES[good_type]["name"]


# ── Gifts (R§3.10 "Gifts") ───────────────────────────────────────────────

const GIFT_CASH := "cash"
const GIFT_ITEM := "item"
const GIFT_LIKED := "liked"


static func _gcfg() -> Dictionary:
	return GameData.FACTION_GIFTS


# state.gifts: { contactId: { lastDay, count } }.
static func _gifts() -> Dictionary:
	return GameState.state["gifts"]


# A key member takes gifts once the player knows them (a "quest" member
# only after their questline unlocks them) and a week after their last one.
static func can_gift(contact_id: String) -> Dictionary:
	var faction_id := KeyMembers.faction_of(contact_id)
	var contact: Dictionary = GameState.state["contacts"].get(contact_id, {})
	if faction_id == "" or contact.is_empty():
		return { "ok": false, "reason": "Nobody to give it to." }
	if not contact["unlocked"] and KeyMembers.member(contact_id).get("unlock", KeyMembers.UNLOCK_FIRST_MESSAGE) != KeyMembers.UNLOCK_FIRST_MESSAGE:
		return { "ok": false, "reason": "You don't know them yet." }
	if int(GameState.state["world"]["day"]) < next_gift_day(contact_id):
		return { "ok": false, "reason": "Too soon. Next gift from %s." % Calendar.format_day(next_gift_day(contact_id)) }
	return { "ok": true }


# The first day contact_id takes another gift; 0 if never gifted.
static func next_gift_day(contact_id: String) -> int:
	var record: Dictionary = _gifts().get(contact_id, {})
	if record.is_empty():
		return 0
	return int(record["lastDay"]) + int(_gcfg()["cooldownDays"])


# Recent gifts still counting against returns: one drops off per
# diminishRecoveryDays since the last gift.
static func recent_gifts(contact_id: String) -> int:
	var record: Dictionary = _gifts().get(contact_id, {})
	if record.is_empty():
		return 0
	var elapsed := int(GameState.state["world"]["day"]) - int(record["lastDay"])
	return maxi(0, int(record["count"]) - floori(float(elapsed) / float(_gcfg()["diminishRecoveryDays"])))


# Relation points for a gift worth `value`: value ÷ valuePerPoint, ×
# preferredMult for a liked item, × diminishFactor per recent gift,
# floored, capped at maxGain.
static func gift_gain(contact_id: String, value: int, preferred: bool) -> int:
	var cfg := _gcfg()
	var points := float(value) / float(cfg["valuePerPoint"])
	if preferred:
		points *= float(cfg["preferredMult"])
	points *= pow(float(cfg["diminishFactor"]), recent_gifts(contact_id))
	return mini(int(cfg["maxGain"]), floori(points))


static func is_preferred(contact_id: String, recipe_key: String) -> bool:
	return KeyMembers.member(contact_id).get("giftPrefs", []).has(recipe_key)


# Today's London value of one unit.
static func item_value(recipe_key: String) -> int:
	return Market.line_total("consumable", Market.quote("consumable", recipe_key), 1)


# Consumables the player holds, in data order.
static func giftable_items() -> Array[String]:
	var keys: Array[String] = []
	for recipe_key in GameData.CONSUMABLE_PRICES:
		if Crafting.inventory_qty(recipe_key) > 0:
			keys.append(recipe_key)
	return keys


static func gift_cash(contact_id: String, amount: int) -> Dictionary:
	var check := can_gift(contact_id)
	if not check["ok"]:
		return check
	if amount <= 0 or int(GameState.state["player"]["cash"]) < amount:
		return { "ok": false, "reason": "Not enough cash." }
	var gain := gift_gain(contact_id, amount, false)
	if gain < 1:
		return { "ok": false, "reason": "Too little to notice." }
	GameState.state["player"]["cash"] -= amount
	Bank.record(-amount, "Gift to %s" % KeyMembers.member(contact_id)["name"])
	return _land_gift(contact_id, gain, GIFT_CASH)


# One unit of recipe_key, lowest tier first.
static func gift_item(contact_id: String, recipe_key: String) -> Dictionary:
	var check := can_gift(contact_id)
	if not check["ok"]:
		return check
	if Crafting.inventory_qty(recipe_key) < 1:
		return { "ok": false, "reason": "You don't have one." }
	var preferred := is_preferred(contact_id, recipe_key)
	var gain := gift_gain(contact_id, item_value(recipe_key), preferred)
	if gain < 1:
		return { "ok": false, "reason": "Too little to notice." }
	Crafting.inventory_remove(recipe_key, 1)
	return _land_gift(contact_id, gain, GIFT_LIKED if preferred else GIFT_ITEM)


# +gain to the member's and their faction's relation, stamps the cooldown
# and counter, and the member replies.
static func _land_gift(contact_id: String, gain: int, reaction: String) -> Dictionary:
	var count := recent_gifts(contact_id) + 1
	_gifts()[contact_id] = { "lastDay": int(GameState.state["world"]["day"]), "count": count }
	Factions.adjust_player_relation(KeyMembers.faction_of(contact_id), gain)
	Contacts.award_relation(contact_id, gain)
	KeyMembers.introduce(contact_id)
	Messages.append(contact_id, "them", _gcfg()["lines"][contact_id][reaction])
	EventBus.state_changed.emit()
	return { "ok": true, "gain": gain }
