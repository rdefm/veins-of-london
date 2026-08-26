class_name Cultivating
extends RefCounted

# Growth/cultivate/prune per vein-growth-state spec.md §2-3. Static funcs only.

# data/vein_security.json's upgrade ladder (R§1.6). The file's key order
# already matches this, but that's an implicit JSON-insertion-order
# guarantee — spelled out explicitly here the same way GameData.
# SITE_TIER_ORDER/HOME_TIER_ORDER pin down their own tables' orderings.
const VEIN_SECURITY_ORDER: Array[String] = ["none", "basic", "warded", "guarded"]

# Verbatim from HTML generateLocationName(). Kept as the fallback/default
# array (also used for whitechapel, M1-LONDON.md D2's per-district
# extension below) so pre-M1 no-arg callers are unaffected.
const LOCATION_STREETS: Array[String] = [
	"Brick Lane", "Bethnal Green Rd", "Commercial St", "Whitechapel High St",
	"Mile End Rd", "Roman Rd", "Hackney Rd", "Cambridge Heath Rd", "Vallance Rd",
]
const LOCATION_SUFFIXES: Array[String] = [
	"near the off-licence", "behind the Tesco Metro", "under the railway arch",
	"in the car park", "by the bus stop", "beside the bookies",
]

# M1-LONDON.md D2: "location generated with district-appropriate street
# names (extend the generator: per-district street array, 4-6 real street
# names each)". Draft, real street names — no PROSE-REVIEW needed. soho
# has no sites (siteCap 0, no prospecting/veins) so it's omitted.
const DISTRICT_STREETS: Dictionary = {
	"shoreditch": ["Old St", "Redchurch St", "Rivington St", "Curtain Rd", "Kingsland Rd", "Shoreditch High St"],
	"city": ["Cheapside", "Cornhill", "Threadneedle St", "Leadenhall St", "Fenchurch St", "Bishopsgate"],
	"greenwich": ["Greenwich High Rd", "Nelson Rd", "Royal Hill", "Trafalgar Rd", "Blackheath Rd", "Creek Rd"],
	"camden": ["Camden High St", "Chalk Farm Rd", "Parkway", "Inverness St", "Kentish Town Rd", "Arlington Rd"],
	"kingscross": ["York Way", "Pentonville Rd", "Caledonian Rd", "Euston Rd", "Grays Inn Rd", "Goods Way"],
	"battersea": ["Battersea Park Rd", "Lavender Hill", "Northcote Rd", "Falcon Rd", "Queenstown Rd", "York Rd"],
	"hampstead": ["Heath St", "Flask Walk", "Rosslyn Hill", "Fitzjohn's Ave", "Well Walk", "South End Rd"],
	"whitechapel": LOCATION_STREETS,
}


static func generate_location_name(district: String = "") -> String:
	var streets: Array = DISTRICT_STREETS.get(district, LOCATION_STREETS)
	return "%s, %s" % [Rng.rand_from(streets), Rng.rand_from(LOCATION_SUFFIXES)]


static func get_cult_chance(skill: int) -> float:
	return min(0.90, 0.30 + (skill - 1) * 0.12)


# ── growth bands (vein-growth-state spec.md §2.2) ───────────────────────

static func growth_band(vein: Dictionary) -> Dictionary:
	return _band_for_growth(vein["growth"])


static func band_drift(growth: int) -> int:
	return _band_for_growth(growth)["drift"]


# spec §7b: the "vigour" hospitability bonus and the King's Cross district
# special are the same effect (+1 rightward drift / -1 leftward, min 0) and
# stack additively — a King's Cross vein on vigour land gets both.
static func vigour_stacks(vein: Dictionary) -> int:
	var stacks := 0
	var bonuses: Array = vein.get("hospitability", {}).get("bonuses", [])
	if bonuses.has("vigour"):
		stacks += 1
	if vein.get("district") == "kingscross":
		stacks += 1
	return stacks


# band_drift(growth) plus the vigour/King's Cross bonus above, signed by
# which side of neutral growth sits on: +stacks rightward, -stacks leftward
# (floored at 0 — vigour can slow a decline to a stop but never reverse it
# outright). At neutral itself there is no direction for the bonus to apply
# to, so it's a no-op there, same as band_drift.
static func effective_drift(growth: int, vein: Dictionary) -> int:
	var base: int = band_drift(growth)
	var stacks: int = vigour_stacks(vein)
	if stacks == 0:
		return base
	var neutral: int = GameData.VEIN_GROWTH["neutral"]
	if growth > neutral:
		return base + stacks
	elif growth < neutral:
		return maxi(0, base - stacks)
	return base


# Tolerates a growth value above 100 (a wildCeiling vein) — the "rampant"
# band's max is deliberately open-ended (data/vein_growth.json).
static func _band_for_growth(growth: int) -> Dictionary:
	for band in GameData.VEIN_GROWTH["bands"]:
		if growth >= band["min"] and growth <= band["max"]:
			return band
	return GameData.VEIN_GROWTH["bands"][-1]


# spec §3: growth 0-19 -> 1, 20-39 -> 2, ..., 100+ -> 6 (a wildCeiling vein
# past 100 still reads as 6, not 7 — "1..6" is a hard ceiling, not a
# straight extrapolation of the formula).
static func value_tier(vein: Dictionary) -> int:
	return mini(6, 1 + int(floor(float(vein["growth"]) / 20.0)))


# 100, or 120 with the wildCeiling hospitability bonus (terroir-amplification
# ticket 05 is what actually grants that bonus — this just has to accept a
# vein that already carries it).
static func ceiling(vein: Dictionary) -> int:
	var base: int = GameData.VEIN_GROWTH["ceiling"]
	var bonuses: Array = vein.get("hospitability", {}).get("bonuses", [])
	if bonuses.has("wildCeiling"):
		return base + GameData.VEIN_GROWTH["wildCeilingBonus"]
	return base


# vein-growth-state ticket 08/09: the collapsed-band warning and the
# days-to-wall summary line are shared by every surface a vein appears on
# (map sheet, station bubble Manage label, vein list) — kept here, once,
# rather than duplicated per screen, since spec §5 requires this wording to
# never drift ("must never be mistaken for a vein that is merely doing
# badly"). PROSE-REVIEW: drafted against CONTENT-GUIDE.md §3 (dry, concrete,
# no wink); "collapse and disappear" echoes collapse_vein()'s own
# notification line for vocabulary continuity.
const COLLAPSED_VEIN_WARNING := "Spent. Could collapse and disappear any day — cultivate it to save it."


# Simulates daily drift (the same step-shape _drift_one() below applies)
# until the vein reaches whichever wall it's currently leaning toward.
# A vein sitting exactly at neutral isn't drifting toward either wall —
# -1 is the "not applicable" sentinel for that case.
static func days_to_wall(vein: Dictionary) -> int:
	var neutral: int = GameData.VEIN_GROWTH["neutral"]
	var growth: int = vein["growth"]
	if growth == neutral:
		return -1

	var target: int = ceiling(vein) if growth > neutral else 0
	var days := 0
	while growth != target and days < 1000:
		var delta: int = effective_drift(growth, vein)
		if delta == 0:
			break
		if growth > neutral:
			growth = mini(target, growth + delta)
		else:
			growth = maxi(target, growth - delta)
		days += 1
	return days


# Formats days_to_wall()'s int into the concrete, plain-numbers phrasing
# CONTENT-GUIDE.md §4 wants ("concrete numbers") — shared by the map sheet,
# the station bubble's Manage label, and the vein list (see
# COLLAPSED_VEIN_WARNING's own comment above for why this lives here once
# instead of once per screen).
static func days_to_wall_text(vein: Dictionary) -> String:
	var days: int = days_to_wall(vein)
	if days < 0:
		return "stable — holding at neutral"
	if vein["growth"] > GameData.VEIN_GROWTH["neutral"]:
		return "%d days to ceiling" % days
	return "%d days to empty" % days


# "yield" hospitability bonus applies to the ROLLED result, not the growth
# table's range: finalYield = max(rolled+1, round(rolled*1.15)) — guarantees
# +1 over the base roll even where 1.15x a small integer would round away.
static func apply_yield_bonus(vein: Dictionary, rolled: int) -> int:
	var bonuses: Array = vein.get("hospitability", {}).get("bonuses", [])
	if not bonuses.has("yield"):
		return rolled
	return maxi(rolled + 1, GameState.round_epsilon(rolled * 1.15))


# spec §7a: tier drives ore yield directly (poor 0.6 / fair 1.0 / rich 1.6 /
# saturated 2.4 — data/vein_growth.json's terroirYieldMult).
static func terroir_yield_mult(vein: Dictionary) -> float:
	var tier: String = vein.get("hospitability", {}).get("tier", "fair")
	return GameData.VEIN_GROWTH["terroirYieldMult"].get(tier, 1.0)


# Shared vein-dict constructor for every place that creates a fresh
# vein — systems/sites.gd's attempt_seed()/natural-vein grant,
# systems/factions.gd's create_faction_vein(), and systems/events.gd's
# tutorial debrief. hospitability is deep-copied — a site's seeded vein and
# its natural-vein bonus (D2) both derive their hospitability from the same
# site dict, and state purity requires every vein to own an independent
# copy, never share an Array/Dictionary reference with the site or with
# each other.
static func make_vein(ore_type: String, growth: int, district: String, site_id: Variant, hospitability: Dictionary) -> Dictionary:
	return {
		"id": make_vein_id(),
		"oreType": ore_type,
		"growth": growth,
		"security": "none",
		# vein-raiding ticket 05: array of purchased alarm-upgrade ids, mirroring
		# state.home["security"]'s shape — independent of the "security" tier
		# ladder above, per the PRD ("alarm/cameras" is a separate purchase).
		"alarmUpgrades": [],
		"location": generate_location_name(district),
		"claimedOnDay": GameState.state["world"]["day"],
		"district": district,
		"siteId": site_id,
		"hospitability": GameState.deep_copy(hospitability),
		# vein-growth-state spec §2.6: consecutive daily ticks spent at the
		# ceiling. Drives self-seeding (ticket 02); 0 for any vein not at the
		# ceiling.
		"rampantDays": 0,
		# 72-stackable-guards: extra Hired Guards bought on top of "guarded",
		# the ladder's own top tier — see next_security_upgrade() below.
		# Reads everywhere else use vein.get("extraGuards", 0) so older
		# hand-built vein dicts (tests, debug_start.gd) don't need updating.
		"extraGuards": 0,
	}


static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var on_level_up := func(): Notify.push("Cultivating skill up — now level %d." % player["cultivatingSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "cultivatingXP", "cultivatingSkill", GameData.CULTIVATING_XP_LEVELS, amount, on_level_up)


# spec §2.4: diminishing toward the right on purpose — cultivating is at its
# most efficient as rescue on the barren side, least efficient as a
# shortcut to the ceiling.
static func cultivate_gain(skill: int, growth: int, vein_ceiling: int) -> int:
	var vg: Dictionary = GameData.VEIN_GROWTH
	var raw: float = (vg["cultivateBase"] + vg["cultivatePerSkill"] * skill) * (1.0 - float(growth) / float(vein_ceiling))
	return maxi(vg["cultivateMinGain"], GameState.round_epsilon(raw))


static func cultivate(vein_id: String) -> Dictionary:
	var vein = find_vein(vein_id)
	if vein == null:
		return { "ok": false, "reason": "Vein not found." }

	var travel := Travel.ensure_district(vein["district"])
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()

	var player: Dictionary = GameState.state["player"]
	var skill: int = player["cultivatingSkill"]
	var success: bool = Rng.chance(get_cult_chance(skill))

	if success:
		var vein_ceiling: int = ceiling(vein)
		var growth_before: int = vein["growth"]
		var gain: int = cultivate_gain(skill, vein["growth"], vein_ceiling)
		vein["growth"] = clampi(vein["growth"] + gain, 0, vein_ceiling)
		if vein["growth"] < vein_ceiling:
			vein["rampantDays"] = 0
		_queue_growth_events(vein, growth_before)
		award_xp(20)
		Objectives.refresh()  # collective1-02: boundary
		Modal.open("cultivate_result", { "success": true, "gain": gain, "veinId": vein_id, "growth": vein["growth"] })
		return { "ok": true, "success": true, "gain": gain, "veinId": vein_id, "growth": vein["growth"] }
	else:
		award_xp(8)
		Objectives.refresh()  # collective1-02: boundary
		Modal.open("cultivate_result", { "success": false, "veinId": vein_id })
		return { "ok": true, "success": false, "veinId": vein_id }


# spec §2.4: yield counts only the growth points removed from above neutral.
# Pruning at or below neutral always yields 0 — the UI must show this
# projection before the player spends a block on it.
static func prune_yield(vein: Dictionary, depth: int) -> int:
	var vg: Dictionary = GameData.VEIN_GROWTH
	var neutral: int = vg["neutral"]
	var growth_before: int = vein["growth"]
	var growth_after: int = maxi(0, growth_before - depth)
	var points: int = maxi(0, growth_before - neutral) - maxi(0, growth_after - neutral)
	var hard_bonus: float = vg["hardPruneBonus"] if depth == vg["pruneHardDepth"] else 1.0
	var rolled: int = GameState.round_epsilon(points * vg["yieldPerPoint"] * terroir_yield_mult(vein) * hard_bonus)
	return apply_yield_bonus(vein, rolled)


# vein-growth-state ticket 08: the shared "always offered, disabled with a
# reason" rule for a Prune button/option -- both the site sheet (map.gd's
# _build_prune_button) and the station bubble (station_bubble.gd's
# _prune_option) need the exact same gate, so it's computed once here rather
# than kept as independently-maintained copies of the same branch.
# Ticket 41: pruning at/below neutral is no longer disabled -- it correctly
# yields 0 ore (prune_yield's own rule), but the player may still choose to
# spend the block on it. Only time-block affordability gates the button now.
static func prune_gate(vein: Dictionary, depth: int, district: String) -> Dictionary:
	if not Travel.can_afford(district, 1):
		return { "disabled": true, "reason": "No blocks left today." }
	return { "disabled": false, "reason": "" }


# Replaces harvest_cautious()/harvest_full() — depth is the caller's choice
# of GameData.VEIN_GROWTH's pruneLightDepth (-9) or pruneHardDepth (-24).
# No cultivating XP awarded, matching the harvest schedule this replaces
# (only cultivate() awards cultivating XP).
static func prune(vein_id: String, depth: int) -> Dictionary:
	var vein = find_vein(vein_id)
	if vein == null:
		return { "ok": false, "reason": "Vein not found." }

	var travel := Travel.ensure_district(vein["district"])
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()

	var amount: int = prune_yield(vein, depth)
	var growth_before: int = vein["growth"]
	vein["growth"] = maxi(0, vein["growth"] - depth)
	vein["rampantDays"] = 0
	_queue_growth_events(vein, growth_before)

	var player: Dictionary = GameState.state["player"]
	var ore_type: String = vein["oreType"]
	player["orichalchum"][ore_type] = player["orichalchum"].get(ore_type, 0) + amount

	Objectives.refresh()  # collective1-02: boundary
	EventBus.state_changed.emit()
	return { "ok": true, "amount": amount, "oreType": ore_type, "veinId": vein_id, "growth": vein["growth"] }


# Called from time_system.gd's daily_tick, step ④. Replaces recharge_veins()
# at the same position — one pass over player veins, then faction veins.
# Order within this step (spec §10): drift, then the collapse roll, then
# self-seed -- self_seed() only ever runs over player veins (faction veins
# never self-seed, §2.6/§5; their expansion is the daily NPC-claim roll).
static func drift_veins() -> void:
	for vein in GameState.state["player"]["veins"]:
		_drift_one(vein)
	for vein in GameState.state["player"]["veins"].duplicate():
		collapse_vein(vein)
	for vein in GameState.state["player"]["veins"].duplicate():
		self_seed(vein)

	for site in GameState.state["world"]["sites"]:
		if site["factionVein"] != null:
			_drift_one(site["factionVein"])
	for site in GameState.state["world"]["sites"].duplicate():
		if site["factionVein"] != null:
			collapse_vein(site["factionVein"])

	EventBus.state_changed.emit()


# spec §2.6: a player vein that's sat at its ceiling for RAMPANT_SEED_DAYS
# consecutive ticks spawns a fresh player vein on a uniformly-random
# unclaimed site in the same district -- the reward for holding a wild
# posture instead of pruning/cashing out. Claims an existing site (no new
# site is rolled), so siteCap is untouched; it does compete with the
# player's own prospecting for the district's unclaimed sites, which is
# intentional (spec §2.6), not a bug to guard against.
static func self_seed(vein: Dictionary) -> void:
	if vein["rampantDays"] < GameData.VEIN_GROWTH["rampantSeedDays"]:
		return

	var district: String = vein["district"]
	var unclaimed: Array = Sites.unclaimed_sites_in_district(district)

	# No unclaimed site in-district to seed into: rampantDays holds at the
	# threshold and retries next tick (spec §2.6 point 3) -- the counter is
	# not touched on a failed attempt.
	if unclaimed.is_empty():
		return

	var site: Dictionary = Rng.rand_from(unclaimed)
	site["claimed"] = true

	var hospitability := { "tier": site["tier"], "bonuses": site["bonuses"] }
	var new_vein := make_vein(site["oreType"], GameData.VEIN_GROWTH["selfSeedGrowth"], district, site["id"], hospitability)
	GameState.state["player"]["veins"].append(new_vein)
	MapEvents.queue_seed_claim(district, new_vein["id"], "player")
	MapEvents.queue_join_line(district, new_vein["id"], "player")

	vein["rampantDays"] = 0

	# PROSE-REVIEW: draft against CONTENT-GUIDE.md §3 -- one dry sentence,
	# concrete nouns, no wink.
	var parent_ore: String = GameData.ORE_TYPES[vein["oreType"]]["name"]
	var parent_street: String = String(vein["location"]).split(",")[0]
	var new_ore: String = GameData.ORE_TYPES[new_vein["oreType"]]["name"]
	Notify.push("Your %s vein on %s has run wild long enough to seed a new %s vein elsewhere in the district." % [parent_ore, parent_street, new_ore])


# spec §2.3's drift formula, verbatim. Right-wall clamping falls out of the
# ceiling clamp for free (the "rampant" band's drift is 0, and growth can
# never exceed ceiling(vein)); left-wall pinning at 0 likewise falls out of
# the "collapsed" band's drift being 0, clamped at a floor of 0.
#
# Also carries rampantDays (§2.6): +1 each tick the vein ends this drift at
# its ceiling, reset to 0 any other tick -- "drops below the ceiling by any
# means" covers prune/cultivate too, but those already zero it themselves at
# the moment they act, so this is the only place drift's own effect on the
# counter needs handling. Capped at rampantSeedDays: once self_seed (which
# runs later in the same drift_veins() pass) starts finding no unclaimed
# site to claim, the counter must hold at the threshold and keep retrying
# every tick (§2.6 point 3), not run off to 6, 7, 8... uncapped.
static func _drift_one(vein: Dictionary) -> void:
	var neutral: int = GameData.VEIN_GROWTH["neutral"]
	var growth: int = vein["growth"]
	var vein_ceiling: int = ceiling(vein)

	if growth != neutral:
		var delta: int = effective_drift(growth, vein)
		var direction: int = 1 if growth > neutral else -1
		vein["growth"] = clampi(growth + delta * direction, 0, vein_ceiling)

	if vein["growth"] >= vein_ceiling:
		vein["rampantDays"] = mini(vein["rampantDays"] + 1, GameData.VEIN_GROWTH["rampantSeedDays"])
	else:
		vein["rampantDays"] = 0

	_queue_growth_events(vein, growth)


# vein-growth-state ticket 07: fires the map's burst/drain animations
# (MapEvents.queue_charge/queue_drain, unchanged since map-animations
# tickets 03/04) on the specific growth transitions the map's growth-gauge
# glyph cares about, using the same was_charged-style before/after guard
# the old recharge_veins() used -- never re-fires while a vein merely sits
# in a band. Called from every place growth actually changes: _drift_one
# above (the daily tick) for band-boundary crossings passive drift alone can
# produce, and cultivate()/prune() for neutral-line crossings, which
# passive drift can never cause on its own (drift always moves growth away
# from neutral, per _drift_one's own direction formula) -- only Prune can
# push a vein down across it. Burst and drain are mutually exclusive by
# construction: burst only ever fires on a growth INCREASE (entering wild,
# reaching the ceiling), drain only ever fires on a growth DECREASE
# (dropping back to/through neutral), so the same call never queues both.
static func _queue_growth_events(vein: Dictionary, growth_before: int) -> void:
	var growth_after: int = vein["growth"]
	if growth_before == growth_after:
		return

	var vein_ceiling: int = ceiling(vein)
	var was_wild: bool = _band_for_growth(growth_before)["id"] == "wild"
	var now_wild: bool = _band_for_growth(growth_after)["id"] == "wild"
	var reached_ceiling: bool = growth_before < vein_ceiling and growth_after >= vein_ceiling
	if (now_wild and not was_wild) or reached_ceiling:
		MapEvents.queue_charge(vein["district"], vein["id"])

	# Both bounds inclusive, not growth_before > neutral: a vein already
	# sitting exactly at neutral (the dormant band's own midpoint) that gets
	# pruned further down has still "crossed below neutral" just as much as
	# one that started above it -- growth_before >= neutral (not >) is what
	# makes that edge case fire too, symmetric with growth_after <= neutral
	# already covering a vein landing exactly on neutral from above.
	var neutral: int = GameData.VEIN_GROWTH["neutral"]
	var drained_to_neutral: bool = growth_before >= neutral and growth_after <= neutral
	if drained_to_neutral:
		MapEvents.queue_drain(vein["district"], vein["id"])


# spec §2.5: a vein pinned at 0 rolls a COLLAPSE_CHANCE_PER_DAY chance each
# tick it sits there (not just the tick it crosses down to 0) to be removed
# for good. Branches by owner on landing: a player vein's site reverts to
# unclaimed and is re-seedable; a faction vein's site is deleted outright
# instead. Since bugfixes-40 removed NPC-abandonment (adr/0002's separate,
# independent daily kill roll for faction-claimed sites), this is now the
# ONLY way a faction vein dies -- same left-wall roll a player vein faces,
# no second roll stacked on top.
static func collapse_vein(vein: Dictionary) -> void:
	if vein["growth"] > 0:
		return
	if not Rng.chance(GameData.VEIN_GROWTH["collapseChancePerDay"]):
		return

	var site_id: Variant = vein.get("siteId")
	var site: Variant = Sites.find_site(site_id) if site_id != null else null

	if vein.has("factionId"):
		if site != null:
			var sites: Array = GameState.state["world"]["sites"]
			GameState.state["world"]["sites"] = sites.filter(func(s2): return s2["id"] != site_id)
			# 87-map-slot-index-recycling: the site (and its only stop --
			# faction veins never carry their own stamped slotIndex, see
			# MapLayout.build_stop_items) is gone for good; free its slot.
			Sites.release_slot_index(site["district"], site.get("slotIndex", 0))
	else:
		var player: Dictionary = GameState.state["player"]
		var vein_id: String = vein["id"]
		player["veins"] = player["veins"].filter(func(v): return v["id"] != vein_id)
		if site != null:
			site["claimed"] = false
		Sites.release_vein_slot(vein)
		var location_street: String = String(vein["location"]).split(",")[0]
		var ore_name: String = GameData.ORE_TYPES[vein["oreType"]]["name"]
		Notify.push("Your %s vein on %s collapsed and disappeared." % [ore_name, location_street], Notify.CATEGORY_WARNING)


static func find_vein(vein_id: String) -> Variant:
	for vein in GameState.state["player"]["veins"]:
		if vein["id"] == vein_id:
			return vein
	return null


static func make_vein_id() -> String:
	return "v" + str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))


# ── vein security (M1-LONDON.md D4: site/vein sheet's "Upgrade security") ──

# Null once at "guarded" — the top of the fixed tier ladder. Past that,
# 72-stackable-guards-vein-defense's uncapped "+1 Guard" purchase
# (extra_guard_cost()/next_security_upgrade() below) takes over — this
# function itself is unchanged, still just the 4-tier ladder walk, and
# faction AI's own upgrade path (Factions.apply_security_upgrades()) still
# stops here deliberately: only the player's UI button stacks guards.
static func next_security_tier_id(current: String) -> Variant:
	var idx: int = VEIN_SECURITY_ORDER.find(current)
	if idx == -1 or idx >= VEIN_SECURITY_ORDER.size() - 1:
		return null
	return VEIN_SECURITY_ORDER[idx + 1]


# 72-stackable-guards-vein-defense: cost of the next guard bought on top of
# "guarded", given how many extra guards a vein already has. Draft only
# (ticket's explicit "needs balance sign-off" call) — continues the ladder's
# own cost curve rather than inventing a new shape: data/vein_security.json's
# deltas (none->basic +20, basic->warded +40, warded->guarded +60) already
# step up by +20 a tier, so the nth extra guard (n=1,2,3...) keeps that same
# arithmetic progression of deltas (+80, +100, +120...), giving the closed
# form cost(n) = 10*(n+3)*(n+4) -- 200, 300, 420, 560, ... for
# extra_guards_owned = 0, 1, 2, 3.
static func extra_guard_cost(extra_guards_owned: int) -> int:
	var n: int = extra_guards_owned + 1
	return 10 * (n + 3) * (n + 4)


# 72-stackable-guards-vein-defense: flat raid-resist added per extra guard.
# Matches "guarded"'s own marginal contribution over "warded" (55-35=20,
# data/vein_security.json) -- each additional Hired Guard keeps contributing
# at that same established rate rather than escalating (only cost escalates,
# per the ticket).
const EXTRA_GUARD_RAID_RESIST := 20


# Every raid-odds formula (Raiding.stealth_success_chance/raid_success_
# chance, Factions.rivalry_success_chance) reads a vein's defensive strength
# through here rather than indexing GameData.VEIN_SECURITY directly, so none
# of them need their own uncapped-value handling -- extraGuards defaults to
# 0 via .get() for any vein that predates this ticket (old saves, hand-built
# test fixtures), reading identically to before.
static func vein_raid_resist(vein: Dictionary) -> int:
	var base: int = GameData.VEIN_SECURITY[vein["security"]]["raidResist"]
	return base + vein.get("extraGuards", 0) * EXTRA_GUARD_RAID_RESIST


# Display label for a vein's security row/sheet -- the tier label, plus a
# "+N" suffix once extra guards are stacked on top (e.g. "Hired Guard +2").
static func security_label(vein: Dictionary) -> String:
	var base: String = GameData.VEIN_SECURITY[vein["security"]]["label"]
	var extra: int = vein.get("extraGuards", 0)
	if extra > 0:
		return "%s +%d" % [base, extra]
	return base


# What upgrade_vein_security() below would buy next, for the UI button and
# the purchase itself to share -- never null now that "guarded" rolls into
# the uncapped "+1 Guard" purchase instead of topping out. tierId is the
# next ladder rung's id while one remains, else null (guard-stack purchase).
static func next_security_upgrade(vein: Dictionary) -> Dictionary:
	var next_id = next_security_tier_id(vein["security"])
	if next_id != null:
		var data: Dictionary = GameData.VEIN_SECURITY[next_id]
		return { "tierId": next_id, "label": data["label"], "cost": data["cost"] }
	return { "tierId": null, "label": "+1 Guard", "cost": extra_guard_cost(vein.get("extraGuards", 0)) }


# Cash-only, no block: D3's travel rule enumerates exactly five districted
# actions (prospect, seed, cultivate, harvest, sell) and security upgrades
# aren't one of them — same reasoning as Home.add_security, which this
# mirrors. 72-stackable-guards-vein-defense: no longer refuses at "guarded"
# — next_security_upgrade() always has something to sell, so the only
# refusal left is "can't afford it".
static func upgrade_vein_security(vein_id: String) -> Dictionary:
	var vein = find_vein(vein_id)
	if vein == null:
		return { "ok": false, "reason": "Vein not found." }

	var upgrade: Dictionary = next_security_upgrade(vein)
	var cost: int = upgrade["cost"]
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < cost:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= cost
	Bank.record(-cost, "Vein security: %s" % upgrade["label"])

	if upgrade["tierId"] != null:
		vein["security"] = upgrade["tierId"]
		Notify.push("Installed %s on your %s vein." % [upgrade["label"], GameData.ORE_TYPES[vein["oreType"]]["name"]], Notify.CATEGORY_SUCCESS)
	else:
		vein["extraGuards"] = vein.get("extraGuards", 0) + 1
		# PROSE-REVIEW: new notification copy (ticket 72), drafted against
		# CONTENT-GUIDE.md's tone bible.
		Notify.push("Hired another guard for your %s vein — %d guards on watch now." % [GameData.ORE_TYPES[vein["oreType"]]["name"], vein["extraGuards"]], Notify.CATEGORY_SUCCESS)

	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


# ── vein alarm (vein-raiding ticket 05) ─────────────────────────────────

const ALARM_UPGRADE_ID := "alarm"

# Cash-only, no block, idempotent guard against re-buying — same shape and
# reasoning as Home.add_security, which this mirrors. Independent of
# upgrade_vein_security above: a vein's "security" tier and its
# "alarmUpgrades" array are two separate purchases (PRD: "alarm/cameras" is
# not folded into the security ladder). GameData.VEIN_ALARM has only the one
# "alarm" entry today, but the array shape matches home["security"]'s.
static func add_alarm(vein_id: String) -> Dictionary:
	var vein = find_vein(vein_id)
	if vein == null:
		return { "ok": false, "reason": "Vein not found." }

	if vein["alarmUpgrades"].has(ALARM_UPGRADE_ID):
		return { "ok": false, "reason": "Already installed." }

	var upgrade_data: Dictionary = GameData.VEIN_ALARM[ALARM_UPGRADE_ID]
	var cost: int = upgrade_data["cost"]
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < cost:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= cost
	Bank.record(-cost, "Vein alarm: %s" % upgrade_data["label"])
	vein["alarmUpgrades"].append(ALARM_UPGRADE_ID)
	Notify.push("Installed %s on your %s vein." % [upgrade_data["label"], GameData.ORE_TYPES[vein["oreType"]]["name"]], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }
