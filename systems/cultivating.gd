class_name Cultivating
extends RefCounted

# Vein growth: bands, drift, cultivate/prune, security upgrades (R§3.4, R§1.6).
# Static funcs only.

# data/vein_security.json's upgrade ladder (R§1.6), pinned explicitly rather
# than relying on the table's JSON key order.
const VEIN_SECURITY_ORDER: Array[String] = ["none", "basic", "warded", "guarded"]

# Fallback street list used by generate_location_name() for any district not
# in DISTRICT_STREETS below (also used directly for whitechapel).
const LOCATION_STREETS: Array[String] = [
	"Brick Lane", "Bethnal Green Rd", "Commercial St", "Whitechapel High St",
	"Mile End Rd", "Roman Rd", "Hackney Rd", "Cambridge Heath Rd", "Vallance Rd",
]
const LOCATION_SUFFIXES: Array[String] = [
	"near the off-licence", "behind the Tesco Metro", "under the railway arch",
	"in the car park", "by the bus stop", "beside the bookies",
]

# Per-district street names (M1-LONDON §D2), real street names, no
# PROSE-REVIEW needed. soho is omitted — siteCap 0, no prospecting/veins.
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


# ── growth bands (R§3.4) ────────────────────────────────────────────────

static func growth_band(vein: Dictionary) -> Dictionary:
	return _band_for_growth(vein["growth"])


static func band_drift(growth: int) -> int:
	return _band_for_growth(growth)["drift"]


# The "vigour" hospitability bonus and the King's Cross district special are
# the same effect (+1 rightward drift / -1 leftward, min 0) and stack.
static func vigour_stacks(vein: Dictionary) -> int:
	var stacks := 0
	var bonuses: Array = vein.get("hospitability", {}).get("bonuses", [])
	if bonuses.has("vigour"):
		stacks += 1
	if vein.get("district") == "kingscross":
		stacks += 1
	return stacks


# band_drift(growth) plus the vigour/King's Cross bonus, signed by which side
# of neutral growth sits on (floored at 0 — vigour slows a decline, never
# reverses it). No-op at neutral itself.
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


# Tolerates growth above 100 (a wildCeiling vein) — the "rampant" band's max
# is deliberately open-ended (R§1.2).
static func _band_for_growth(growth: int) -> Dictionary:
	for band in GameData.VEIN_GROWTH["bands"]:
		if growth >= band["min"] and growth <= band["max"]:
			return band
	return GameData.VEIN_GROWTH["bands"][-1]


# R§3.4: growth 0-19 -> 1, ..., 100+ -> 6 (a wildCeiling vein past 100 still
# reads as 6 — "1..6" is a hard ceiling, not extrapolation).
static func value_tier(vein: Dictionary) -> int:
	return mini(6, 1 + int(floor(float(vein["growth"]) / 20.0)))


# 100, or 120 with the wildCeiling hospitability bonus (R§1.2).
static func ceiling(vein: Dictionary) -> int:
	var base: int = GameData.VEIN_GROWTH["ceiling"]
	var bonuses: Array = vein.get("hospitability", {}).get("bonuses", [])
	if bonuses.has("wildCeiling"):
		return base + GameData.VEIN_GROWTH["wildCeilingBonus"]
	return base


# Shared by every surface a vein appears on (map sheet, station bubble,
# vein list) so the wording never drifts between them.
# PROSE-REVIEW: drafted against CONTENT-GUIDE.md §3; "collapse and
# disappear" echoes collapse_vein()'s own notification line.
const COLLAPSED_VEIN_WARNING := "Spent. Could collapse and disappear any day — cultivate it to save it."


# Simulates daily drift (same step shape as _drift_one() below) until the
# vein reaches whichever wall it's leaning toward. -1 means not applicable
# (already at neutral, drifting toward neither wall).
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


# Concrete plain-numbers phrasing (CONTENT-GUIDE.md §4), shared by the map
# sheet, station bubble, and vein list.
static func days_to_wall_text(vein: Dictionary) -> String:
	var days: int = days_to_wall(vein)
	if days < 0:
		return "stable — holding at neutral"
	if vein["growth"] > GameData.VEIN_GROWTH["neutral"]:
		return "%d days to ceiling" % days
	return "%d days to empty" % days


# "yield" hospitability bonus applies to the rolled result: max(rolled+1,
# round(rolled*1.15)) — guarantees +1 even where 1.15x a small int rounds away.
static func apply_yield_bonus(vein: Dictionary, rolled: int) -> int:
	var bonuses: Array = vein.get("hospitability", {}).get("bonuses", [])
	if not bonuses.has("yield"):
		return rolled
	return maxi(rolled + 1, GameState.round_epsilon(rolled * 1.15))


# Tier drives ore yield directly (R§1.2 terroirYieldMult): poor 0.6 / fair
# 1.0 / rich 1.6 / saturated 2.4.
static func terroir_yield_mult(vein: Dictionary) -> float:
	var tier: String = vein.get("hospitability", {}).get("tier", "fair")
	return GameData.VEIN_GROWTH["terroirYieldMult"].get(tier, 1.0)


# Shared vein-dict constructor for Sites.attempt_seed(), Factions.
# create_faction_vein(), and events.gd's tutorial debrief. hospitability is
# deep-copied — state purity requires every vein to own an independent copy,
# never share an Array/Dictionary reference with its site.
static func make_vein(ore_type: String, growth: int, district: String, site_id: Variant, hospitability: Dictionary) -> Dictionary:
	return {
		"id": make_vein_id(),
		"oreType": ore_type,
		"growth": growth,
		"security": "none",
		# Purchased alarm-upgrade ids, mirroring state.home["security"]'s shape
		# — independent of the "security" tier ladder above (R§1.6).
		"alarmUpgrades": [],
		"location": generate_location_name(district),
		"claimedOnDay": GameState.state["world"]["day"],
		"district": district,
		"siteId": site_id,
		"hospitability": GameState.deep_copy(hospitability),
		# Consecutive daily ticks spent at the ceiling; drives self-seeding
		# (R§3.4), 0 for any vein not at the ceiling.
		"rampantDays": 0,
		# Extra Hired Guards bought on top of "guarded" — see
		# next_security_upgrade() below. Reads elsewhere use .get("extraGuards",
		# 0) so older hand-built vein dicts don't need updating.
		"extraGuards": 0,
	}


static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var on_level_up := func(): Notify.push("Cultivating skill up — now level %d." % player["cultivatingSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "cultivatingXP", "cultivatingSkill", GameData.CULTIVATING_XP_LEVELS, amount, on_level_up)


# Diminishing toward the right on purpose (R§3.4) — cultivating is most
# efficient as rescue on the barren side, least as a shortcut to the ceiling.
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
	# The player's own roll gets the seated Movement's attunement bonus
	# (R§3.5); get_cult_chance() itself stays untouched since contact
	# cultivating (Rooms.process_vein_station()) must never see the player's
	# Dial.
	var success: bool = Rng.chance(Dial.apply_attunement(get_cult_chance(skill), vein["oreType"]))

	if success:
		var vein_ceiling: int = ceiling(vein)
		var growth_before: int = vein["growth"]
		var gain: int = cultivate_gain(skill, vein["growth"], vein_ceiling)
		vein["growth"] = clampi(vein["growth"] + gain, 0, vein_ceiling)
		if vein["growth"] < vein_ceiling:
			vein["rampantDays"] = 0
		_queue_growth_events(vein, growth_before)
		award_xp(20)
		Objectives.refresh()
		Modal.open("cultivate_result", { "success": true, "gain": gain, "veinId": vein_id, "growth": vein["growth"] })
		return { "ok": true, "success": true, "gain": gain, "veinId": vein_id, "growth": vein["growth"] }
	else:
		award_xp(8)
		Objectives.refresh()
		Modal.open("cultivate_result", { "success": false, "veinId": vein_id })
		return { "ok": true, "success": false, "veinId": vein_id }


# R§3.4: yield counts only the growth points cleared from above neutral.
# Pruning at or below neutral always yields 0.
static func prune_yield(vein: Dictionary, depth: int) -> int:
	var vg: Dictionary = GameData.VEIN_GROWTH
	var neutral: int = vg["neutral"]
	var growth_before: int = vein["growth"]
	var growth_after: int = maxi(0, growth_before - depth)
	var points: int = maxi(0, growth_before - neutral) - maxi(0, growth_after - neutral)
	var hard_bonus: float = vg["hardPruneBonus"] if depth == vg["pruneHardDepth"] else 1.0
	var rolled: int = GameState.round_epsilon(points * vg["yieldPerPoint"] * terroir_yield_mult(vein) * hard_bonus)
	return apply_yield_bonus(vein, rolled)


# Shared "always offered, disabled with a reason" gate for a Prune button —
# both map.gd's site sheet and station_bubble.gd need the same rule. Pruning
# at/below neutral is allowed (it just yields 0, per prune_yield above);
# only time-block affordability gates the button.
static func prune_gate(vein: Dictionary, depth: int, district: String) -> Dictionary:
	if not Travel.can_afford(district, 1):
		return { "disabled": true, "reason": "No blocks left today." }
	return { "disabled": false, "reason": "" }


# depth is the caller's choice of pruneLightDepth (9) or pruneHardDepth (24),
# R§1.2. No cultivating XP awarded — only cultivate() awards it.
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
	if amount > 0:
		EventBus.shared_stock_increased.emit()

	Objectives.refresh()
	EventBus.state_changed.emit()
	return { "ok": true, "amount": amount, "oreType": ore_type, "veinId": vein_id, "growth": vein["growth"] }


# Called from TimeSystem.daily_tick() step ④ (R§3.1). Order matters: drift,
# then the collapse roll, then self-seed — self_seed() only runs over player
# veins (faction veins never self-seed; their expansion is the daily
# NPC-claim roll).
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


# R§3.4: a player vein sat at its ceiling for rampantSeedDays consecutive
# ticks spawns a fresh vein on a random unclaimed site in the same district.
# Claims an existing site (siteCap untouched); competing with the player's
# own prospecting for unclaimed sites is intentional, not a bug.
static func self_seed(vein: Dictionary) -> void:
	if vein["rampantDays"] < GameData.VEIN_GROWTH["rampantSeedDays"]:
		return

	var district: String = vein["district"]
	var unclaimed: Array = Sites.unclaimed_sites_in_district(district)

	# No unclaimed site to seed into: rampantDays holds at the threshold and
	# retries next tick.
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

	# PROSE-REVIEW: drafted against CONTENT-GUIDE.md §3.
	var parent_ore: String = GameData.ORE_TYPES[vein["oreType"]]["name"]
	var parent_street: String = String(vein["location"]).split(",")[0]
	var new_ore: String = GameData.ORE_TYPES[new_vein["oreType"]]["name"]
	Notify.push("Your %s vein on %s has run wild long enough to seed a new %s vein elsewhere in the district." % [parent_ore, parent_street, new_ore])


# R§3.4's drift formula. Right-wall clamping falls out of the ceiling clamp
# for free (rampant band's drift is 0); left-wall pinning at 0 falls out of
# the collapsed band's drift likewise being 0.
#
# Also carries rampantDays: +1 each tick the vein ends at its ceiling, reset
# to 0 otherwise (prune/cultivate zero it themselves when they act, so this
# only needs to handle drift's own effect). Capped at rampantSeedDays so it
# holds and keeps retrying once self_seed finds no unclaimed site, rather
# than running off uncapped.
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


# Fires the map's burst/drain animations (MapEvents.queue_charge/queue_drain)
# on the specific growth transitions the growth-gauge glyph cares about;
# never re-fires while a vein merely sits in a band. Called from every place
# growth actually changes: _drift_one above (band-boundary crossings) and
# cultivate()/prune() (neutral-line crossings, which drift alone can never
# cause). Burst and drain are mutually exclusive by construction — burst on
# a growth increase, drain on a decrease — so a single call never queues both.
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

	# Both bounds inclusive: a vein already sitting exactly at neutral that
	# gets pruned further down still counts as crossing below neutral.
	var neutral: int = GameData.VEIN_GROWTH["neutral"]
	var drained_to_neutral: bool = growth_before >= neutral and growth_after <= neutral
	if drained_to_neutral:
		MapEvents.queue_drain(vein["district"], vein["id"])


# R§3.4: a vein pinned at 0 rolls collapseChancePerDay each tick it sits
# there to vanish for good. A player vein's site reverts to unclaimed; a
# faction vein's site vanishes outright — this is the only way a faction
# vein dies (see adr/0002).
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
			# The site (and its only stop) is gone for good; free its slot.
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


# ── vein security (M1-LONDON §D4: site/vein sheet's "Upgrade security") ──

# Null once at "guarded" — the top of the fixed tier ladder. Past that, the
# uncapped "+1 Guard" purchase (extra_guard_cost()/next_security_upgrade()
# below) takes over. Factions.apply_security_upgrades() stops here
# deliberately — only the player's UI button stacks guards.
static func next_security_tier_id(current: String) -> Variant:
	var idx: int = VEIN_SECURITY_ORDER.find(current)
	if idx == -1 or idx >= VEIN_SECURITY_ORDER.size() - 1:
		return null
	return VEIN_SECURITY_ORDER[idx + 1]


# Cost of the next guard bought on top of "guarded", given how many extra
# guards a vein already has. Not yet balance-signed-off; continues the
# ladder's own cost curve (R§1.6 deltas step up by +20/tier):
# cost(n) = 10*(n+3)*(n+4) for the nth extra guard.
static func extra_guard_cost(extra_guards_owned: int) -> int:
	var n: int = extra_guards_owned + 1
	return 10 * (n + 3) * (n + 4)


# Flat raid-resist added per extra guard, matching "guarded"'s own marginal
# contribution over "warded" (55-35=20, R§1.6). Only cost escalates.
const EXTRA_GUARD_RAID_RESIST := 20


# Every raid-odds formula (Raiding.stealth_success_chance/raid_success_chance,
# Factions.rivalry_success_chance) reads defensive strength through here
# rather than indexing GameData.VEIN_SECURITY directly. extraGuards defaults
# to 0 via .get() for veins that predate it.
static func vein_raid_resist(vein: Dictionary) -> int:
	var base: int = GameData.VEIN_SECURITY[vein["security"]]["raidResist"]
	return base + vein.get("extraGuards", 0) * EXTRA_GUARD_RAID_RESIST


# Display label: the tier label, plus a "+N" suffix once extra guards are
# stacked on top (e.g. "Hired Guard +2").
static func security_label(vein: Dictionary) -> String:
	var base: String = GameData.VEIN_SECURITY[vein["security"]]["label"]
	var extra: int = vein.get("extraGuards", 0)
	if extra > 0:
		return "%s +%d" % [base, extra]
	return base


# What upgrade_vein_security() would buy next, shared by the UI button and
# the purchase itself. Never null — "guarded" rolls into the uncapped
# "+1 Guard" purchase (tierId null) instead of topping out.
static func next_security_upgrade(vein: Dictionary) -> Dictionary:
	var next_id = next_security_tier_id(vein["security"])
	if next_id != null:
		var data: Dictionary = GameData.VEIN_SECURITY[next_id]
		return { "tierId": next_id, "label": data["label"], "cost": data["cost"] }
	return { "tierId": null, "label": "+1 Guard", "cost": extra_guard_cost(vein.get("extraGuards", 0)) }


# Cash-only, no block: M1-LONDON §D3's travel rule lists five districted
# actions (prospect, seed, cultivate, harvest, sell) and security upgrades
# aren't one, same as Home.add_security. next_security_upgrade() always has
# something to sell, so "can't afford it" is the only refusal.
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
		# PROSE-REVIEW: drafted against CONTENT-GUIDE.md's tone bible.
		Notify.push("Hired another guard for your %s vein — %d guards on watch now." % [GameData.ORE_TYPES[vein["oreType"]]["name"], vein["extraGuards"]], Notify.CATEGORY_SUCCESS)

	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


# ── vein alarm ───────────────────────────────────────────────────────────

const ALARM_UPGRADE_ID := "alarm"

# Cash-only, no block, idempotent guard against re-buying, same shape as
# Home.add_security. Independent of upgrade_vein_security above — a vein's
# "security" tier and its "alarmUpgrades" array are separate purchases.
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
