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
# for Factions.apply_security_upgrades() to buy.
static func is_vulnerable(site_id: String, effect: String) -> bool:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return false
	var security: String = site["factionVein"]["security"]
	if effect == EFFECT_SECURITY_FREEZE:
		return Cultivating.next_security_tier_id(security) != null
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
