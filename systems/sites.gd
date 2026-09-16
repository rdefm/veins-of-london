class_name Sites
extends RefCounted

# Sites & prospecting (M1-LONDON §D2). Static funcs only. A site is the land
# (state.world.sites); attempt_seed() turns an unclaimed site into a vein
# (systems/cultivating.gd owns veins themselves).

# GameData.SITE_TIER_ORDER (data/sites.json) is the single source of truth
# for worst-to-best ordering — don't duplicate it as a local const.

# tierIndex for the NPC-claim formula (distinct from SITE_TIER_ORDER's
# worst-to-best position): poor 0, fair 1, rich 2, saturated 3. barren is
# excluded — it is never claimed.
const NPC_CLAIM_TIER_INDEX: Dictionary = { "poor": 0, "fair": 1, "rich": 2, "saturated": 3 }

# Faction veins now only die via Cultivating.collapse_vein()'s left-wall
# roll (see adr/0004), so a freshly-claimed vein's expected survival is
# longer than the original adr/0002 curve assumed. These are tuned down
# from that curve to keep the claim rate proportional — needs balance
# sign-off once played, not derived from a hard target vein count.
const NPC_CLAIM_BASE := 0.02
const NPC_CLAIM_TIER_STEP := 0.01
const NPC_CLAIM_AGE_STEP := 0.005
const NPC_CLAIM_CAP := 0.15


static func make_site_id() -> String:
	return "s" + str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))


# The stable, permanent slot a stop keeps for as long as it lives, stamped
# once at creation onto the site (or, for a saturated site's extra
# natural-vein stop, onto the vein itself — see attempt_seed() below) rather
# than derived from where the stop currently sits in state.world.sites/
# player.veins. Drains state.world.mapSlotFreePool before minting a fresh
# value off the per-district mapSlotCounters, so a freed slot recirculates
# instead of counting up forever — a district's lifetime churn only needs to
# fit inside its live stop count, not its stopSlots buffer.
static func next_slot_index(district_id: String) -> int:
	var free_pool: Dictionary = GameState.state["world"]["mapSlotFreePool"]
	var freed: Array = free_pool.get(district_id, [])
	if not freed.is_empty():
		return freed.pop_back()

	var counters: Dictionary = GameState.state["world"]["mapSlotCounters"]
	var next_index: int = counters.get(district_id, 0)
	counters[district_id] = next_index + 1
	return next_index


# The other half of next_slot_index() — called by every removal path that
# ends a site's or a slotIndex-owning vein's existence in a district
# (_reroll_worst_unclaimed(), Cultivating.collapse_vein(), VeinTrade.
# sell_to_faction(), Raiding.resolve_raid_outcome()'s claim branch).
static func release_slot_index(district_id: String, slot_index: int) -> void:
	var free_pool: Dictionary = GameState.state["world"]["mapSlotFreePool"]
	if not free_pool.has(district_id):
		free_pool[district_id] = []
	free_pool[district_id].append(slot_index)


# Shared by every removal path that takes a vein out of state.player.veins
# while its site survives (collapse, sale, raid). Only the saturated-site
# natural-vein bonus ever carries its own stamped slotIndex (attempt_seed()
# below) — an ordinary vein reuses its site's slot, nothing to free.
static func release_vein_slot(vein: Dictionary) -> void:
	if vein.has("slotIndex"):
		release_slot_index(vein["district"], vein["slotIndex"])


static func find_site(site_id: String) -> Variant:
	for site in GameState.state["world"]["sites"]:
		if site["id"] == site_id:
			return site
	return null


# Used when the caller has a vein id (combat["veinId"]) but not the faction
# that owns it — unlike find_site() above, this searches every site's
# factionVein regardless of owner.
static func find_faction_vein(vein_id: String) -> Variant:
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein != null and vein["id"] == vein_id:
			return vein
	return null


# "This faction's own live site veins" — shared so the buy-side lane (the
# Trade modal's Assets rows, its cart gather, VeinTrade.buy_from_faction())
# all agree on one definition of "buyable from this faction".
static func sites_with_faction_vein(faction_id: String) -> Array:
	var result: Array = []
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein != null and vein["factionId"] == faction_id:
			result.append(site)
	return result


static func sites_in_district(district_id: String) -> Array:
	var result: Array = []
	for site in GameState.state["world"]["sites"]:
		if site["district"] == district_id:
			result.append(site)
	return result


# ── tier roll (M1-LONDON §D2: base weights, then modifiers, then normalise) ──

# Shared by compute_tier_weights() and compute_at_cap_tier_weights(): floats
# out a tier-keyed weight table (GameData.SITE_TIER_WEIGHTS or
# GameData.SITE_AT_CAP_TIER_WEIGHTS) in GameData.SITE_TIER_ORDER's key order.
static func _tier_weights_from_table(table: Dictionary) -> Dictionary:
	var w: Dictionary = {}
	for tier in GameData.SITE_TIER_ORDER:
		w[tier] = float(table[tier])
	return w


# Pure function: base weights + siteQualityMod (rich +q, poor -q floor 0)
# + cultivating skill (rich +2*(skill-1), saturated +1*(skill-1),
# barren -3*(skill-1) floor 5). Kept separate from GameState reads so
# tests can hit the floors directly without faking a whole district.
static func compute_tier_weights(site_quality_mod: float, skill: int) -> Dictionary:
	var w := _tier_weights_from_table(GameData.SITE_TIER_WEIGHTS)

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

	# busker_greenwich (M1-LONDON D5): a one-shot +10 rich weight tip-off,
	# consumed on the very next Greenwich prospect regardless of outcome.
	if district_id == "greenwich" and GameState.state["flags"].get("greenwichTipOff", false):
		weights["rich"] += 10
		GameState.state["flags"]["greenwichTipOff"] = false

	return roll_tier_from_weights(weights)


# Once a district is at siteCap, the site being rolled is replacing land
# that's already been picked over, so it draws from
# GameData.SITE_AT_CAP_TIER_WEIGHTS instead — a fixed, heavily poor/
# barren-weighted table with no siteQualityMod/skill/tip-off inputs (those
# describe the district's underlying land, not its picked-over state).
static func compute_at_cap_tier_weights() -> Dictionary:
	return _tier_weights_from_table(GameData.SITE_AT_CAP_TIER_WEIGHTS)


static func roll_tier_at_cap() -> String:
	return roll_tier_from_weights(compute_at_cap_tier_weights())


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

	# Checked before advance_time_block(), not after: advance_time_block() can
	# itself trigger daily_tick() on the day's last block, which would expire
	# this same pending defend raid (Raiding._expire_pending_defend_raids())
	# before a post-action check ever ran. Checking here means arriving is
	# unconditionally enough, same as combat always taking over immediately.
	if Raiding.maybe_trigger_defend(district_id):
		return { "ok": true, "district": district_id, "site": null }

	TimeSystem.advance_time_block()

	var site: Variant
	if sites_in_district(district_id).size() >= site_cap:
		site = _reroll_worst_unclaimed(district_id)
	else:
		site = _create_site(district_id)

	Objectives.refresh()
	EventBus.state_changed.emit()
	# The story beat is checked first — it's Rng-free, so a genuine early
	# return that never touches the deck's own seeded roll when it fires.
	# DistrictDeck.maybe_trigger() must stay the last thing either branch does.
	if not Collective.maybe_trigger_weather_beat(site):
		DistrictDeck.maybe_trigger(district_id)
	return { "ok": true, "district": district_id, "site": site }


# Every truly-unclaimed site in the district (not player-claimed, no
# factionVein) — shared by _unclaimed_sites_by_tier() below and
# Cultivating.self_seed() (R§3.4), which just needs the filter, not the sort.
static func unclaimed_sites_in_district(district_id: String) -> Array:
	var unclaimed: Array = []
	for site in sites_in_district(district_id):
		if not site["claimed"] and site["factionVein"] == null:
			unclaimed.append(site)
	return unclaimed


# Shared by _worst_unclaimed_site() and best_unclaimed_site(): every truly-
# unclaimed site in the district, sorted tier-first (direction per
# want_best), oldest-breaks-ties either way. Callers just take index 0.
static func _unclaimed_sites_by_tier(district_id: String, want_best: bool) -> Array:
	var unclaimed: Array = unclaimed_sites_in_district(district_id)

	unclaimed.sort_custom(func(a, b):
		var tier_a: int = GameData.SITE_TIER_ORDER.find(a["tier"])
		var tier_b: int = GameData.SITE_TIER_ORDER.find(b["tier"])
		if tier_a != tier_b:
			return tier_a > tier_b if want_best else tier_a < tier_b
		return a["discoveredDay"] < b["discoveredDay"]
	)
	return unclaimed


static func _worst_unclaimed_site(district_id: String) -> Variant:
	var sorted := _unclaimed_sites_by_tier(district_id, false)
	return sorted[0] if not sorted.is_empty() else null


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
	release_slot_index(district_id, worst.get("slotIndex", 0))
	return _create_site(district_id, true)


static func _create_site(district_id: String, at_cap: bool = false) -> Dictionary:
	var tier := roll_tier_at_cap() if at_cap else roll_tier(district_id)
	var site := roll_new_site(district_id, tier)
	GameState.state["world"]["sites"].append(site)
	MapEvents.queue_discover(district_id, site["id"])
	Cultivating.award_xp(GameData.SITE_PROSPECT_XP[tier])
	return site


# Pure dict construction, split out of _create_site() so day-1 site seeding
# (Factions._seed_day_one_vein()) can fabricate a from-scratch site with the
# same tier/ore/bonus generation a real prospect uses, without
# _create_site()'s player-action side effects (state append, discover
# animation, prospect XP) that don't apply to a pre-existing site.
static func roll_new_site(district_id: String, tier: String) -> Dictionary:
	var ore_type := roll_ore_type(district_id)
	var bonus_roll := roll_discovery_bonuses(tier)
	return {
		"id": make_site_id(),
		"district": district_id,
		"tier": tier,
		"oreType": ore_type,
		"bonuses": bonus_roll["bonuses"],
		"discoveredDay": GameState.state["world"]["day"],
		"claimed": false,
		"factionVein": null,
		"hasNaturalVein": bonus_roll["hasNaturalVein"],
		"slotIndex": next_slot_index(district_id),
	}


# ── debug: spawn an unclaimed site ──────────────────────────────────────

# Debug-only site creation from the Debug phone app: district, tier and
# oreType are player-chosen rather than rolled, and this bypasses the
# district's siteCap entirely — a testing tool, not a simulated prospect.
# Same site shape as roll_new_site() (and debug_start.gd's _debug_site())
# minus the ore-type/bonus rolls; bonuses and hasNaturalVein stay empty/false.
static func spawn_unclaimed_site(district_id: String, tier: String, ore_type: String) -> Dictionary:
	var site := {
		"id": make_site_id(),
		"district": district_id,
		"tier": tier,
		"oreType": ore_type,
		"bonuses": [],
		"discoveredDay": GameState.state["world"]["day"],
		"claimed": false,
		"factionVein": null,
		"hasNaturalVein": false,
		"slotIndex": next_slot_index(district_id),
	}
	GameState.state["world"]["sites"].append(site)
	EventBus.state_changed.emit()
	return site


# ── seeding revamp ──────────────────────────────────────────────────────

static func seed_success_chance(skill: int, tier: String) -> float:
	var tier_mod: float = GameData.SITE_SEED_TIER_MOD.get(tier, 0.0)
	return clampf(Cultivating.get_cult_chance(skill) + tier_mod, 0.05, 0.95)


# Requires an unclaimed, non-barren site and 40 ore of ITS oreType (R§3.4).
static func attempt_seed(site_id: String) -> Dictionary:
	var site = find_site(site_id)
	if site == null:
		return { "ok": false, "reason": "Site not found." }
	if site["claimed"] or site["factionVein"] != null:
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
	# A vein-seeding attempt has a real single ore type (the site's), unlike
	# Dial.attempt_seed()'s own mixed five-ore-type cost (R§3.5), which has
	# nothing for attunement to match against.
	var success: bool = Rng.chance(Dial.apply_attunement(seed_success_chance(skill, site["tier"]), ore_type))

	if success:
		var district: String = site["district"]
		var hospitability := { "tier": site["tier"], "bonuses": site["bonuses"] }
		site["claimed"] = true

		var vein := Cultivating.make_vein(ore_type, GameData.VEIN_GROWTH["seedGrowth"], district, site_id, hospitability)
		player["veins"].append(vein)
		MapEvents.queue_seed_claim(district, vein["id"], "player")
		MapEvents.queue_join_line(district, vein["id"], "player")

		# M1-LONDON §D2: claiming a hasNaturalVein site instantly grants a free
		# vein of the site's oreType at the same seedGrowth, with its own
		# freshly-rolled (not shared) location.
		var natural_vein_id: Variant = null
		if site["hasNaturalVein"]:
			var natural_vein := Cultivating.make_vein(ore_type, GameData.VEIN_GROWTH["seedGrowth"], district, site_id, hospitability)
			# Second stop landing on an already-positioned site (the first vein
			# reuses the site's own slotIndex) — needs its own permanent slot.
			natural_vein["slotIndex"] = next_slot_index(district)
			player["veins"].append(natural_vein)
			natural_vein_id = natural_vein["id"]
			MapEvents.queue_seed_claim(district, natural_vein_id, "player")
			MapEvents.queue_join_line(district, natural_vein_id, "player")

		Cultivating.award_xp(30)
		Modal.open("seed_result", { "success": true, "oreType": ore_type, "siteId": site_id })
		return { "ok": true, "success": true, "siteId": site_id, "veinId": vein["id"], "naturalVeinId": natural_vein_id }
	else:
		Cultivating.award_xp(5)
		Modal.open("seed_result", { "success": false, "oreType": ore_type, "siteId": site_id })
		return { "ok": true, "success": false, "siteId": site_id }


# ── NPC site-claiming (daily tick, M1-LONDON §D2, adr/0002) ─────────────
# Faction veins only die via Cultivating.collapse_vein()'s left-wall roll,
# same as player veins (see adr/0004).

static func npc_claim_chance(tier: String, age_days: int) -> float:
	var tier_index: int = NPC_CLAIM_TIER_INDEX.get(tier, 0)
	return clampf(NPC_CLAIM_BASE + NPC_CLAIM_TIER_STEP * tier_index + NPC_CLAIM_AGE_STEP * age_days, 0.0, NPC_CLAIM_CAP)


# The district's best (highest-tier, oldest-breaks-ties) unclaimed site,
# used by rival_prospector (M1-LONDON §D5 #13), or null if none.
static func best_unclaimed_site(district_id: String) -> Variant:
	var sorted := _unclaimed_sites_by_tier(district_id, true)
	return sorted[0] if not sorted.is_empty() else null


# The "instant faction vein" shape shared by NPC claiming (below) and
# events.gd's _faction_seed_reported_sites (col_a1_des_report's
# on_complete): create the vein at seedGrowth, attach it to the site, queue
# its map events. Callers own the "should this site get a vein" gating.
static func seed_faction_vein(site: Dictionary, faction_id: String) -> void:
	site["factionVein"] = Factions.create_faction_vein(faction_id, site, GameData.VEIN_GROWTH["seedGrowth"])
	MapEvents.queue_seed_claim(site["district"], site["factionVein"]["id"], faction_id)
	MapEvents.queue_join_line(site["district"], site["factionVein"]["id"], faction_id)


# rival_prospector's "refuse to pay" outcome: faction-claims the district's
# best unclaimed site outright, instant vein and all (no roll on WHETHER it
# happens — this is a deterministic consequence, not the daily-tick's
# probabilistic claiming; WHICH faction claims it still goes through the
# same weighted pick_claimant() the daily tick uses). A no-op if the
# district has no unclaimed site to claim.
static func npc_claim_best_unclaimed_site(district_id: String) -> void:
	var site = best_unclaimed_site(district_id)
	if site == null:
		return
	var faction_id := Factions.pick_claimant(district_id)
	seed_faction_vein(site, faction_id)


# Called from TimeSystem.daily_tick() step ⑤b. Each unclaimed, non-barren
# site may attract a faction claim; older, richer sites are likelier. The
# claimant is always one of the 5 canonical factions (Factions.
# pick_claimant()), and claiming instantly seeds a real vein.
static func roll_npc_claims() -> void:
	var day: int = GameState.state["world"]["day"]
	for site in GameState.state["world"]["sites"]:
		if site["claimed"] or site["factionVein"] != null or site["tier"] == "barren":
			continue
		var age_days: int = day - site["discoveredDay"]
		if Rng.chance(npc_claim_chance(site["tier"], age_days)):
			var faction_id := Factions.pick_claimant(site["district"])
			seed_faction_vein(site, faction_id)
			var district_name: String = GameData.DISTRICTS[site["district"]]["name"]
			var faction_name: String = GameData.FACTIONS[faction_id]["shortName"]
			Notify.push("%s have moved onto the %s site in %s." % [faction_name, site["tier"], district_name], Notify.CATEGORY_WARNING)


# ── faction vein daily growth ────────────────────────────────────────────

# Called from TimeSystem.daily_tick() step ⑤c, immediately after ⑤b claims.
# Faction veins drift on the same step ④ pass every other vein does
# (Cultivating.drift_veins()), so this step only prunes back veins that
# drifted to the ceiling, off-screen (no ore granted): without it, every
# faction vein on the map would park at the ceiling within a month.
#
# TARGET is 40, not 55 — 55 sits in the "dormant" band (45-55, drift 0,
# R§1.2), where a reset vein would never drift again (direction only flips
# at neutral) and become a de facto immortal vein. 40 sits in "thinning"
# (30-44, drift 1 leftward), so a prune-backed vein resumes its walk toward
# 0 and eventually rolls collapse_vein()'s left-wall chance. THRESHOLD/
# CHANCE only gate how often a ceiling-parked vein gets pruned and need
# balance sign-off once played, not derived from a hard target vein count.
const FACTION_PRUNE_BACK_THRESHOLD := 85
const FACTION_PRUNE_BACK_CHANCE := 0.40
const FACTION_PRUNE_BACK_TARGET := 40


static func roll_faction_vein_growth() -> void:
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null or vein["growth"] < FACTION_PRUNE_BACK_THRESHOLD:
			continue
		if Rng.chance(FACTION_PRUNE_BACK_CHANCE):
			vein["growth"] = FACTION_PRUNE_BACK_TARGET
