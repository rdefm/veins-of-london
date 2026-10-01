class_name NetworkHandler
extends RefCounted

# The Network handler's two products (collective-act2 spec §5.3): Targets
# (name a faction-held vein, get a true answer on whether it's soft) and
# Sourcing (name an ore type + minimum tier, get a fresh site delivered by
# text). The handler never lies: a Targets "no" is still charged.

# Draft numbers, playtest-pending (spec §7.2/§11.1): both products price at
# VeinTrade.quote() for a comparable vein, times these multipliers.
const TARGETS_PRICE_MULT := 1.0
const SOURCING_PRICE_MULT := 1.0
# Flat addition to the player's raid odds (Raiding.stealth_success_chance())
# and the Collective's rivalry odds against the named site.
const CLAIM_BONUS_MAGNITUDE := 0.15
const INTEL_DURATION_DAYS := 5
# Flat Network relation per transaction, same shape as Economy.
# ARCHIE_SALE_RELATION_GAIN; the tradeProgress lane accrues on top.
const RELATION_GAIN := 2
# A vein is soft while its security sits below this rung of Cultivating.
# VEIN_SECURITY_ORDER (i.e. "none"/"basic").
const SOFT_SECURITY_CEILING := "warded"

const EFFECT_CLAIM_BONUS := "claim_bonus"
const EFFECT_SECURITY_FREEZE := "security_freeze"
const CONTACT_ID := "handler"
const SOURCING_DELIVERY_EVENT := "network_sourcing_delivered"
const SOURCING_TIERS: Array[String] = ["poor", "fair", "rich", "saturated"]

# PROSE-REVIEW: handler SMS lines, drafted against spec §3.3's voice.
const TARGET_SOFT_TEXT := "\"It's soft. Their people are stretched and it shows. You'll find it easier for the next few days.\""
const TARGET_HARD_TEXT := "\"It isn't soft. I'd rather you paid to hear that than found out the other way.\""
const FREEZE_OK_TEXT := "\"Done. Their guard swap won't happen this week. Nobody will notice for a while.\""
const FREEZE_MOOT_TEXT := "\"They can't harden that one any further. There's nothing to delay. I've still charged you, which I think is fair.\""
const SOURCING_TEXT := "\"Found what you asked for. Details below.\""


# ── Targets ──────────────────────────────────────────────────────────────

# Sites whose vein Targets can be asked about: any faction vein the
# Collective doesn't hold.
static func target_site_ids() -> Array[String]:
	var ids: Array[String] = []
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein != null and vein["factionId"] != "collective":
			ids.append(site["id"])
	return ids


static func target_price(site_id: String) -> int:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return 0
	return roundi(VeinTrade.quote(site["factionVein"]) * TARGETS_PRICE_MULT)


# The honest answer: claim_bonus is true when the vein's security is below
# SOFT_SECURITY_CEILING; security_freeze is true when there's still a rung
# or a capped extra guard for Factions.apply_security_upgrades() to buy.
static func is_vulnerable(site_id: String, effect: String) -> bool:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return false
	var security: String = site["factionVein"]["security"]
	if effect == EFFECT_SECURITY_FREEZE:
		return Cultivating.next_security_tier_id(security) != null 			or int(site["factionVein"].get("extraGuards", 0)) < GuardUpkeep.faction_max_extra_guards()
	var order: Array = Cultivating.VEIN_SECURITY_ORDER
	return order.find(security) < order.find(SOFT_SECURITY_CEILING)


# network_reveal_vulnerable_vein op: writes a timed networkIntel entry when
# the named vein is genuinely vulnerable to `effect`, nothing otherwise.
# Returns the verdict.
static func reveal_vulnerable_vein(site_id: String, effect: String) -> bool:
	if not is_vulnerable(site_id, effect):
		return false
	GameState.state["collective"]["networkIntel"][site_id] = {
		"expiresDay": GameState.state["world"]["day"] + INTEL_DURATION_DAYS,
		"effect": effect,
		"magnitude": CLAIM_BONUS_MAGNITUDE if effect == EFFECT_CLAIM_BONUS else 0.0,
	}
	EventBus.state_changed.emit()
	return true


# Paid Targets question. Charges whether the answer is yes or no.
static func buy_target(site_id: String, effect: String) -> Dictionary:
	if not site_id in target_site_ids():
		return { "ok": false, "reason": "No such vein." }
	var price := target_price(site_id)
	if not _charge(price, "Network handler: targets"):
		return { "ok": false, "reason": "Not enough cash." }
	Collective.note_targets_purchase(site_id)
	var vulnerable := reveal_vulnerable_vein(site_id, effect)
	var text: String
	if effect == EFFECT_SECURITY_FREEZE:
		text = FREEZE_OK_TEXT if vulnerable else FREEZE_MOOT_TEXT
	else:
		text = TARGET_SOFT_TEXT if vulnerable else TARGET_HARD_TEXT
	Messages.append(CONTACT_ID, "them", text)
	return { "ok": true, "price": price, "vulnerable": vulnerable }


static func _active_entry(site_id: String, effect: String) -> Variant:
	var entry: Variant = GameState.state["collective"]["networkIntel"].get(site_id)
	if entry == null or entry["effect"] != effect:
		return null
	if int(entry["expiresDay"]) <= GameState.state["world"]["day"]:
		return null
	return entry


static func claim_bonus(site_id: String) -> float:
	var entry: Variant = _active_entry(site_id, EFFECT_CLAIM_BONUS)
	return 0.0 if entry == null else float(entry["magnitude"])


static func is_security_frozen(site_id: String) -> bool:
	return _active_entry(site_id, EFFECT_SECURITY_FREEZE) != null


# TimeSystem.daily_tick() step: drops entries whose expiresDay has arrived.
static func expire_intel() -> void:
	var intel: Dictionary = GameState.state["collective"]["networkIntel"]
	var today: int = GameState.state["world"]["day"]
	for site_id in intel.keys():
		if int(intel[site_id]["expiresDay"]) <= today:
			intel.erase(site_id)


# ── Sourcing ─────────────────────────────────────────────────────────────

static func sourcing_price(ore_type: String, min_tier: String) -> int:
	var comparable := {
		"oreType": ore_type,
		"growth": GameData.VEIN_GROWTH["neutral"],
		"hospitability": { "tier": min_tier },
	}
	return roundi(VeinTrade.quote(comparable) * SOURCING_PRICE_MULT)


static func sourcing_districts() -> Array:
	var eligible: Array = []
	for district_id in GameData.DISTRICTS.keys():
		if Sites.sites_in_district(district_id).size() < GameData.DISTRICTS[district_id]["siteCap"]:
			eligible.append(district_id)
	return eligible


# network_reveal_site op: rolls a site via Sites.roll_tier()/roll_new_site(),
# lifts the tier to min_tier if it rolled lower, forces the named ore type,
# and delivers it as a handler pendingMessages entry -- the map reveal
# waits for the player to read it. Returns the site id, or "" when every
# district is at siteCap.
static func reveal_site(ore_type: String, min_tier: String) -> String:
	var districts := sourcing_districts()
	if districts.is_empty():
		return ""
	var district: String = Rng.rand_from(districts)
	var tier := Sites.roll_tier(district)
	if GameData.SITE_TIER_ORDER.find(tier) < GameData.SITE_TIER_ORDER.find(min_tier):
		tier = min_tier
	var site := Sites.roll_new_site(district, tier)
	site["oreType"] = ore_type
	GameState.state["world"]["sites"].append(site)
	Messages.queue_pending(CONTACT_ID, SOURCING_DELIVERY_EVENT, SOURCING_TEXT, { "site_id": site["id"] })
	return site["id"]


static func buy_sourcing(ore_type: String, min_tier: String) -> Dictionary:
	if not GameData.ORE_TYPES.has(ore_type) or not min_tier in SOURCING_TIERS:
		return { "ok": false, "reason": "Unknown order." }
	if sourcing_districts().is_empty():
		return { "ok": false, "reason": "Nowhere left to look." }
	var price := sourcing_price(ore_type, min_tier)
	if not _charge(price, "Network handler: sourcing"):
		return { "ok": false, "reason": "Not enough cash." }
	var site_id := reveal_site(ore_type, min_tier)
	return { "ok": true, "price": price, "siteId": site_id }


# ── Intel menu ───────────────────────────────────────────────────────────
# R§3.1 "Network intel menu" (constants.json networkMenu). Each product
# costs its base price × (1 − Network relation × relationPriceMod) and is
# refused below its minRelation. Targets and Sourcing above stay separate
# products with their own pricing.

const PRODUCT_RAID_INTEL := "raidIntel"
const PRODUCT_RAID_WARNINGS := "raidWarnings"
const PRODUCT_MARKET_INTEL := "marketIntel"
const PRODUCT_BOOST := "boost"
const PRODUCT_PRIVACY := "privacy"
const PRODUCT_DISINFORMATION := "disinformation"
const PRODUCT_REDUCTION := "reduction"
const PRODUCTS: Array[String] = [
	PRODUCT_RAID_INTEL, PRODUCT_RAID_WARNINGS, PRODUCT_MARKET_INTEL, PRODUCT_BOOST,
	PRODUCT_PRIVACY, PRODUCT_DISINFORMATION, PRODUCT_REDUCTION,
]


static func _menu() -> Dictionary:
	return GameData.NETWORK_MENU


static func _product(product_id: String) -> Dictionary:
	return _menu()["products"][product_id]


static func _line(key: String) -> String:
	return _menu()["lines"][key]


# buyer's relation with the Network: the player's, or the faction pair's.
static func _network_relation(buyer: String = Shares.PLAYER) -> int:
	if buyer == Shares.PLAYER:
		return int(GameState.state["factions"]["network"]["relation"])
	return Factions.get_relation(buyer, "network")


static func product_name(product_id: String) -> String:
	return _product(product_id)["name"]


# Base price × relation modifier × any Network price gouge on buyer.
static func product_price(product_id: String, buyer: String = Shares.PLAYER) -> int:
	var mult := 1.0 - float(_network_relation(buyer)) * float(_menu()["relationPriceMod"])
	mult *= FactionAI.gouge_mult(buyer)
	return maxi(0, roundi(float(_product(product_id)["price"]) * mult))


static func product_min_relation(product_id: String) -> int:
	return int(_product(product_id)["minRelation"])


static func product_open(product_id: String, buyer: String = Shares.PLAYER) -> bool:
	return _network_relation(buyer) >= product_min_relation(product_id)


# Factions a targeted product can name: every faction but the Network.
static func intel_targets() -> Array:
	return GameData.FACTIONS.keys().filter(func(id: String) -> bool: return id != "network")


static func disinformation_modes() -> Array:
	return _menu()["disinformationModes"].keys()


static func disinformation_mode_label(mode: String) -> String:
	return _menu()["disinformationModes"][mode]


# The gate, then the charge. { ok, price } or { ok: false, reason }.
static func _buy_product(product_id: String) -> Dictionary:
	if not product_open(product_id):
		return { "ok": false, "reason": _menu()["gatedReason"] }
	var price := product_price(product_id)
	if not _charge(price, "Network handler: %s" % product_name(product_id).to_lower()):
		return { "ok": false, "reason": "Not enough cash." }
	return { "ok": true, "price": price }


static func _faction_name(faction_id: String) -> String:
	return GameData.FACTIONS[faction_id]["name"]


static func _send(text: String) -> void:
	Messages.append(CONTACT_ID, "them", text)
	EventBus.state_changed.emit()


# Planned moves against the player within the horizon, texted as a list.
static func buy_raid_intel() -> Dictionary:
	var result := _buy_product(PRODUCT_RAID_INTEL)
	if not result["ok"]:
		return result
	var plans := FactionAI.planned_moves(int(_menu()["horizonDays"])).filter(func(p: Dictionary) -> bool: return p["targetId"] == Shares.PLAYER)
	_send(_plan_report(_line("raidIntel"), _line("raidIntelNone"), plans, false))
	result["plans"] = plans
	return result


# Planned big buys and dumps (networkMenu.marketMoves) against anyone within
# the horizon, texted as a list.
static func buy_market_intel() -> Dictionary:
	var result := _buy_product(PRODUCT_MARKET_INTEL)
	if not result["ok"]:
		return result
	var market_moves: Array = _menu()["marketMoves"]
	var plans := FactionAI.planned_moves(int(_menu()["horizonDays"])).filter(func(p: Dictionary) -> bool: return market_moves.has(p["move"]))
	_send(_plan_report(_line("marketIntel"), _line("marketIntelNone"), plans, true))
	result["plans"] = plans
	return result


static func buy_raid_warnings() -> Dictionary:
	var result := _buy_product(PRODUCT_RAID_WARNINGS)
	if not result["ok"]:
		return result
	var days := int(_product(PRODUCT_RAID_WARNINGS)["days"])
	Intel.set_raid_warnings(Shares.PLAYER, days)
	_send(_line("raidWarnings") % days)
	return result


# FactionAI's raid rung calls this as it queues a raid on the player: the
# handler texts the attacker and district while raid warnings run.
static func warn_of_raid(attacker_id: String, site_id: String) -> void:
	if not Intel.raid_warnings_active(Shares.PLAYER):
		return
	var site: Variant = Sites.find_site(site_id)
	if site == null:
		return
	Messages.append(CONTACT_ID, "them", _line("raidWarning") % [_faction_name(attacker_id), GameData.DISTRICTS[site["district"]]["name"]])


static func buy_intel_boost(faction_id: String) -> Dictionary:
	if not intel_targets().has(faction_id):
		return { "ok": false, "reason": "Unknown faction." }
	if Intel.privacy_active(faction_id):
		return { "ok": false, "reason": _menu()["privateReason"] }
	var result := _buy_product(PRODUCT_BOOST)
	if not result["ok"]:
		return result
	Intel.raise(Shares.PLAYER, faction_id, int(_product(PRODUCT_BOOST)["amount"]))
	_send(_line("boost") % _faction_name(faction_id))
	return result


static func buy_privacy() -> Dictionary:
	var result := _buy_product(PRODUCT_PRIVACY)
	if not result["ok"]:
		return result
	var days := int(_product(PRODUCT_PRIVACY)["days"])
	Intel.set_privacy(Shares.PLAYER, days)
	_send(_line("privacy") % days)
	return result


# mode: an Intel.DISINFO_* id listed in networkMenu.disinformationModes.
static func buy_disinformation(faction_id: String, mode: String) -> Dictionary:
	if not intel_targets().has(faction_id) or not disinformation_modes().has(mode):
		return { "ok": false, "reason": "Unknown order." }
	var result := _buy_product(PRODUCT_DISINFORMATION)
	if not result["ok"]:
		return result
	var days := int(_product(PRODUCT_DISINFORMATION)["days"])
	Intel.set_disinformation(faction_id, Shares.PLAYER, mode, days)
	_send(_line(mode) % [_faction_name(faction_id), days])
	return result


static func buy_intel_reduction(faction_id: String) -> Dictionary:
	if not intel_targets().has(faction_id):
		return { "ok": false, "reason": "Unknown faction." }
	var result := _buy_product(PRODUCT_REDUCTION)
	if not result["ok"]:
		return result
	Intel.raise(faction_id, Shares.PLAYER, -int(_product(PRODUCT_REDUCTION)["amount"]))
	_send(_line("reduction") % _faction_name(faction_id))
	return result


static func _plan_report(head: String, none: String, plans: Array, market: bool) -> String:
	if plans.is_empty():
		return none
	var lines := PackedStringArray([head])
	for plan in plans:
		lines.append(_plan_line(plan, market))
	return "\n".join(lines)


static func _plan_line(plan: Dictionary, market: bool) -> String:
	var when := when_text(int(plan["day"]))
	var who := _faction_name(plan["factionId"])
	if not market:
		return _line("planLine") % [who, move_label(plan), when]
	var target: String = plan["targetId"]
	var aimed_at := _line("you") if target == Shares.PLAYER else _faction_name(target)
	return _line("marketLine") % [who, move_label(plan), aimed_at, when]


# "tomorrow" or "in N days" for a plan landing on day.
static func when_text(day: int) -> String:
	var days_out := day - int(GameState.state["world"]["day"])
	return _line("tomorrow") if days_out <= 1 else _line("inDays") % days_out


static func move_label(plan: Dictionary) -> String:
	var label: String = _menu()["moveLabels"].get(plan["move"], plan["move"])
	return label % _move_detail(plan) if label.contains("%s") else label


# The district (site moves) or good name a plan line names.
static func _move_detail(plan: Dictionary) -> String:
	if plan.has("siteId"):
		var site: Variant = Sites.find_site(plan["siteId"])
		return "" if site == null else GameData.DISTRICTS[site["district"]]["name"]
	var good: String = plan.get("good", "")
	var kind: String = plan.get("kind", "consumable" if plan["move"] == FactionAI.MOVE_WITHHOLD_ITEMS else "ore")
	return GameData.ORE_TYPES[good]["name"] if kind == "ore" else GameData.RECIPES[good]["name"]


# ── Faction buying ───────────────────────────────────────────────────────
# R§3.1 "Faction intel buying" (networkMenu.factionBuying). Each faction but
# the Network spends up to budgetShare of its cash above cashFloor on the
# menu's products, at most one of each, in priority order, at its own
# product_price() and behind its own product_open(). The Network is paid.

static func faction_purchases() -> void:
	var cfg: Dictionary = _menu()["factionBuying"]
	for buyer in intel_targets():
		var wallet: Dictionary = GameState.state["factions"][buyer]
		var budget := floori(float(maxi(0, int(wallet["resources"]) - int(cfg["cashFloor"]))) * float(cfg["budgetShare"]))
		for product_id in cfg["priority"]:
			var price := product_price(product_id, buyer)
			if price > budget or not product_open(product_id, buyer):
				continue
			if not _faction_buy(buyer, product_id):
				continue
			budget -= price
			wallet["resources"] -= price
			GameState.state["factions"]["network"]["resources"] += price
	EventBus.state_changed.emit()


# Applies product_id for buyer when it has a use; false (nothing bought)
# otherwise.
static func _faction_buy(buyer: String, product_id: String) -> bool:
	match product_id:
		PRODUCT_REDUCTION:
			var watcher := _top_watcher(buyer)
			if watcher == "":
				return false
			Intel.raise(watcher, buyer, -int(_product(PRODUCT_REDUCTION)["amount"]))
			return true
		PRODUCT_PRIVACY:
			if Intel.privacy_active(buyer) or not _has_enemy(buyer):
				return false
			Intel.set_privacy(buyer, int(_product(PRODUCT_PRIVACY)["days"]))
			return true
		PRODUCT_DISINFORMATION:
			var raider := _worst_raider(buyer)
			if raider == "":
				return false
			Intel.set_disinformation(raider, buyer, _menu()["factionBuying"]["disinformationMode"], int(_product(PRODUCT_DISINFORMATION)["days"]))
			return true
		PRODUCT_BOOST:
			var target := _boost_target(buyer)
			if target == "":
				return false
			Intel.raise(buyer, target, int(_product(PRODUCT_BOOST)["amount"]))
			return true
	return false


# The actor (player or faction but the Network) with the highest meter on
# buyer, if at or over reductionAbove; else "".
static func _top_watcher(buyer: String) -> String:
	var best := ""
	var best_meter := int(_menu()["factionBuying"]["reductionAbove"]) - 1
	for watcher in Intel.actors():
		if watcher == buyer or watcher == "network":
			continue
		var value := Intel.meter(watcher, buyer)
		if value > best_meter:
			best = watcher
			best_meter = value
	return best


# True when a faction other than the Network is at the market band or
# deeper against buyer: someone the Network could sell buyer's file to.
static func _has_enemy(buyer: String) -> bool:
	for id in intel_targets():
		if id != buyer and FactionAI.band_depth(id, buyer) >= FactionAI.band_depth_of(FactionAI.BAND_MARKET):
			return true
	return false


# The faction at the raid band against buyer with the lowest relation to
# it, not already under disinformation about buyer; else "".
static func _worst_raider(buyer: String) -> String:
	var best := ""
	for raider in GameData.FACTIONS.keys():
		if raider == buyer or FactionAI.moves_blocked(raider, buyer) or Intel.disinformation(raider, buyer) != "":
			continue
		if FactionAI.band(raider, buyer) != FactionAI.BAND_RAID:
			continue
		if best == "" or Factions.get_relation(raider, buyer) < Factions.get_relation(best, buyer):
			best = raider
	return best


# buyer's deepest-band target (market band or deeper; the lowest relation
# on a tie) that isn't private and has room on buyer's meter; else "".
static func _boost_target(buyer: String) -> String:
	var best := ""
	var best_depth := -1
	var min_depth := FactionAI.band_depth_of(FactionAI.BAND_MARKET)
	var max_meter := int(GameData.INTEL["max"])
	for target in [Shares.PLAYER] + intel_targets():
		if target == buyer or FactionAI.moves_blocked(buyer, target) or Intel.privacy_active(target) or Intel.meter(buyer, target) >= max_meter:
			continue
		var depth := FactionAI.band_depth(buyer, target)
		if depth < min_depth:
			continue
		if depth > best_depth or (depth == best_depth and FactionAI.relation_toward(buyer, target) < FactionAI.relation_toward(buyer, best)):
			best = target
			best_depth = depth
	return best


# ── shared ───────────────────────────────────────────────────────────────

static func _charge(price: int, bank_label: String) -> bool:
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < price:
		return false
	player["cash"] -= price
	Bank.record(-price, bank_label)
	Factions.adjust_player_relation("network", RELATION_GAIN)
	RelationAccrual.accrue_faction("network", price)
	EventBus.state_changed.emit()
	return true
