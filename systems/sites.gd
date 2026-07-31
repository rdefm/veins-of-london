class_name Sites
extends RefCounted

# Sites & prospecting per M1-LONDON.md D2. Static funcs only. A site is the
# land (state.world.sites); attempt_seed() is what turns an unclaimed site
# into a vein (systems/cultivating.gd owns veins themselves).

# Worst-to-best; GameData.SITE_TIER_ORDER (loaded from data/sites.json) is
# the single source of truth for both the weight table's key order and
# "worst tier" comparisons — don't duplicate it as a local const.


static func make_site_id() -> String:
	return "s" + str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))


static func find_site(site_id: String) -> Variant:
	for site in GameState.state["world"]["sites"]:
		if site["id"] == site_id:
			return site
	return null


static func sites_in_district(district_id: String) -> Array:
	var result: Array = []
	for site in GameState.state["world"]["sites"]:
		if site["district"] == district_id:
			result.append(site)
	return result


# ── tier roll (D2: base weights, then modifiers, then normalise) ──────

# Pure function: base weights + siteQualityMod (rich +q, poor -q floor 0)
# + cultivating skill (rich +2*(skill-1), saturated +1*(skill-1),
# barren -3*(skill-1) floor 5). Kept separate from GameState reads so
# tests can hit the floors directly without faking a whole district.
static func compute_tier_weights(site_quality_mod: float, skill: int) -> Dictionary:
	var w: Dictionary = {}
	for tier in GameData.SITE_TIER_ORDER:
		w[tier] = float(GameData.SITE_TIER_WEIGHTS[tier])

	var q: int = GameState.round_epsilon(site_quality_mod * 100.0)
	w["rich"] += q
	w["poor"] = maxf(0.0, w["poor"] - q)

	w["rich"] += 2 * (skill - 1)
	w["saturated"] += 1 * (skill - 1)
	w["barren"] = maxf(5.0, w["barren"] - 3 * (skill - 1))

	return w


# Weighted roll over GameData.SITE_TIER_ORDER (normalisation is implicit in the
# cumulative-weight walk — no need to divide through by the total first).
static func roll_tier_from_weights(weights: Dictionary) -> String:
	var total: float = 0.0
	for tier in GameData.SITE_TIER_ORDER:
		total += weights[tier]

	var roll: float = Rng.randf() * total
	var cumulative: float = 0.0
	for tier in GameData.SITE_TIER_ORDER:
		cumulative += weights[tier]
		if roll < cumulative:
			return tier
	return GameData.SITE_TIER_ORDER[-1]


static func roll_tier(district_id: String) -> String:
	var district: Dictionary = GameData.DISTRICTS[district_id]
	var skill: int = GameState.state["player"]["cultivatingSkill"]
	var weights := compute_tier_weights(district.get("siteQualityMod", 0.0), skill)
	return roll_tier_from_weights(weights)


# ── ore type roll (per district oreBias) ──────────────────────────────

# oreBias weights are the listed types' probabilities; the remainder is
# split uniformly among the other ore types (uniform oreBias = 0.2 each).
static func compute_ore_probs(bias: Dictionary) -> Dictionary:
	var ore_types: Array = GameData.ORE_TYPES.keys()
	var biased_sum: float = 0.0
	for key in bias.keys():
		biased_sum += bias[key]

	var unbiased_types: Array = []
	for ore in ore_types:
		if not bias.has(ore):
			unbiased_types.append(ore)

	var uniform_share: float = 0.0
	if not unbiased_types.is_empty():
		uniform_share = (1.0 - biased_sum) / unbiased_types.size()

	var probs: Dictionary = {}
	for ore in ore_types:
		probs[ore] = bias.get(ore, uniform_share)
	return probs


static func roll_ore_type_from_probs(probs: Dictionary) -> String:
	var ore_types: Array = GameData.ORE_TYPES.keys()
	var roll: float = Rng.randf()
	var cumulative: float = 0.0
	for ore in ore_types:
		cumulative += probs[ore]
		if roll < cumulative:
			return ore
	return ore_types[-1]


static func roll_ore_type(district_id: String) -> String:
	var district: Dictionary = GameData.DISTRICTS[district_id]
	var probs := compute_ore_probs(district.get("oreBias", {}))
	return roll_ore_type_from_probs(probs)


# ── discovery bonuses ──────────────────────────────────────────────────

# rich -> exactly one bonus, uniformly; saturated -> all three, plus a
# 5% chance of hasNaturalVein. barren/poor/fair get nothing.
static func roll_discovery_bonuses(tier: String) -> Dictionary:
	var bonuses: Array = []
	var has_natural_vein := false

	if tier == "rich":
		bonuses = [Rng.rand_from(GameData.SITE_DISCOVERY_BONUS_POOL)]
	elif tier == "saturated":
		bonuses = GameData.SITE_DISCOVERY_BONUS_POOL.duplicate()
		has_natural_vein = Rng.chance(GameData.SITE_NATURAL_VEIN_CHANCE)

	return { "bonuses": bonuses, "hasNaturalVein": has_natural_vein }


# ── prospect action ────────────────────────────────────────────────────

static func prospect(district_id: String) -> Dictionary:
	var district: Dictionary = GameData.DISTRICTS[district_id]
	var site_cap: int = district.get("siteCap", 0)
	if site_cap <= 0:
		return { "ok": false, "reason": "No prospecting here." }

	var travel := Travel.ensure_district(district_id)
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()

	var site: Variant
	if sites_in_district(district_id).size() >= site_cap:
		site = _reroll_worst_unclaimed(district_id)
	else:
		site = _create_site(district_id)

	EventBus.state_changed.emit()
	return { "ok": true, "district": district_id, "site": site }


static func _worst_unclaimed_site(district_id: String) -> Variant:
	var unclaimed: Array = []
	for site in sites_in_district(district_id):
		if not site["claimed"] and not site["npcClaimed"]:
			unclaimed.append(site)
	if unclaimed.is_empty():
		return null

	unclaimed.sort_custom(func(a, b):
		var tier_a: int = GameData.SITE_TIER_ORDER.find(a["tier"])
		var tier_b: int = GameData.SITE_TIER_ORDER.find(b["tier"])
		if tier_a != tier_b:
			return tier_a < tier_b
		return a["discoveredDay"] < b["discoveredDay"]
	)
	return unclaimed[0]


# Deletes the district's worst truly-unclaimed site and rolls a fresh one
# in its place. If every site in the district is player- or NPC-claimed,
# there is nothing eligible to reroll — the prospect action still spends
# its block, but nothing changes (D2 gives no fallback for this case).
static func _reroll_worst_unclaimed(district_id: String) -> Variant:
	var worst = _worst_unclaimed_site(district_id)
	if worst == null:
		return null

	var worst_id: String = worst["id"]
	var sites: Array = GameState.state["world"]["sites"]
	GameState.state["world"]["sites"] = sites.filter(func(s): return s["id"] != worst_id)
	return _create_site(district_id)


static func _create_site(district_id: String) -> Dictionary:
	var tier := roll_tier(district_id)
	var ore_type := roll_ore_type(district_id)
	var bonus_roll := roll_discovery_bonuses(tier)

	var site := {
		"id": make_site_id(),
		"district": district_id,
		"tier": tier,
		"oreType": ore_type,
		"bonuses": bonus_roll["bonuses"],
		"discoveredDay": GameState.state["world"]["day"],
		"claimed": false,
		"npcClaimed": false,
		"npcClaimedDay": null,
		"hasNaturalVein": bonus_roll["hasNaturalVein"],
	}
	GameState.state["world"]["sites"].append(site)
	Cultivating.award_xp(GameData.SITE_PROSPECT_XP[tier])
	return site


# ── seeding revamp ──────────────────────────────────────────────────────

static func seed_success_chance(skill: int, tier: String) -> float:
	var tier_mod: float = GameData.SITE_SEED_TIER_MOD.get(tier, 0.0)
	return clampf(Cultivating.get_cult_chance(skill) + tier_mod, 0.05, 0.95)


# Replaces free-floating seeding (Cultivating.seed(oreType)) for sites:
# requires an unclaimed, non-barren site and 40 ore of ITS oreType.
static func attempt_seed(site_id: String) -> Dictionary:
	var site = find_site(site_id)
	if site == null:
		return { "ok": false, "reason": "Site not found." }
	if site["claimed"] or site["npcClaimed"]:
		return { "ok": false, "reason": "Site is already claimed." }
	if site["tier"] == "barren":
		return { "ok": false, "reason": "Barren sites can't be seeded." }

	var player: Dictionary = GameState.state["player"]
	var ore_type: String = site["oreType"]
	var have: int = player["orichalchum"].get(ore_type, 0)
	if have < GameData.SEED_ORE_COST:
		return { "ok": false, "reason": "Not enough %s calc." % ore_type }

	var travel := Travel.ensure_district(site["district"])
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()
	player["orichalchum"][ore_type] = have - GameData.SEED_ORE_COST

	var skill: int = player["cultivatingSkill"]
	var success: bool = Rng.chance(seed_success_chance(skill, site["tier"]))

	if success:
		var district: String = site["district"]
		var hospitability := { "tier": site["tier"], "bonuses": site["bonuses"] }
		site["claimed"] = true

		var vein := Cultivating.make_vein(ore_type, Cultivating.get_bar_gain(skill), district, site_id, hospitability)
		player["veins"].append(vein)

		# D2: claiming a hasNaturalVein site instantly grants a free Lv1
		# vein of the site's oreType — charged:false, devBar 0 (not
		# barGain), with its own freshly-rolled (not shared) location.
		var natural_vein_id: Variant = null
		if site["hasNaturalVein"]:
			var natural_vein := Cultivating.make_vein(ore_type, 0, district, site_id, hospitability)
			player["veins"].append(natural_vein)
			natural_vein_id = natural_vein["id"]

		Cultivating.award_xp(30)
		Modal.open("seed_result", { "success": true, "oreType": ore_type, "siteId": site_id })
		return { "ok": true, "success": true, "siteId": site_id, "veinId": vein["id"], "naturalVeinId": natural_vein_id }
	else:
		Cultivating.award_xp(5)
		Modal.open("seed_result", { "success": false, "oreType": ore_type, "siteId": site_id })
		return { "ok": true, "success": false, "siteId": site_id }
