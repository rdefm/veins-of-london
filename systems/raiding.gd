class_name Raiding
extends RefCounted

# Direction A: stealth-check + raid resolution ops, registered as effect ops
# in systems/events.gd's _apply_one() ("stealth_check", "start_raid_combat",
# "claim_raid_vein", "loot_raid_vein"). This file holds the pure/testable
# logic; events.gd stays a thin op dispatcher into systems.


# ── stealth check ────────────────────────────────────────────────────────
# Coin-flip baseline tilted by stealthSkill, consumable bonus, raidResist
# (normalised against the 55.0 anchor, R§1.6) and vein value.
const STEALTH_BASE_CHANCE := 0.55
const STEALTH_SKILL_WEIGHT := 0.05
const STEALTH_RAID_RESIST_DIVISOR := 55.0
const STEALTH_RAID_RESIST_WEIGHT := 0.35
# basePrice * combined_magnitude tops out ~450-540 for a maxed level-1 vein; dividing by 450
# keeps the tilt within roughly [-1.2, 0] before the weight scales it further (a leveled-up
# vein's combined magnitude, R§3.4, can push past that ceiling).
const STEALTH_VALUE_DIVISOR := 450.0
const STEALTH_VALUE_WEIGHT := 0.15


static func stealth_success_chance(stealth_skill: int, vein: Dictionary, consumable_bonus: float) -> float:
	var skill_tilt: float = (stealth_skill - 1) * STEALTH_SKILL_WEIGHT

	var raid_resist: int = Cultivating.vein_raid_resist(vein)
	var resist_tilt: float = -(float(raid_resist) / STEALTH_RAID_RESIST_DIVISOR) * STEALTH_RAID_RESIST_WEIGHT

	var value: float = GameData.ORE_TYPES[vein["oreType"]]["basePrice"] * Cultivating.combined_magnitude(vein)
	var value_tilt: float = -(value / STEALTH_VALUE_DIVISOR) * STEALTH_VALUE_WEIGHT

	var chance: float = STEALTH_BASE_CHANCE + skill_tilt + resist_tilt + value_tilt + consumable_bonus
	return clampf(chance, 0.0, 1.0)


# Full XP reward on success, ~1/3 on a caught attempt -- getting caught
# still teaches you something, just less.
const STEALTH_XP_SUCCESS := 20
const STEALTH_XP_CAUGHT := 7


static func award_stealth_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var on_level_up := func(): Notify.push("Stealth skill up — now level %d." % player["stealthSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "stealthXP", "stealthSkill", GameData.STEALTH_XP_LEVELS, amount, on_level_up)


# Rolls the check and awards stealth XP either way; returns success so
# events.gd's "stealth_check" op can branch into on_success/on_caught.
static func resolve_stealth_check(vein: Dictionary, consumable_bonus: float) -> bool:
	var skill: int = GameState.state["player"]["stealthSkill"]
	var success: bool = Rng.chance(stealth_success_chance(skill, vein, consumable_bonus))
	award_stealth_xp(STEALTH_XP_SUCCESS if success else STEALTH_XP_CAUGHT)
	return success


# ── claim / loot resolution ─────────────────────────────────────────────

# Claim's relation hit is far heavier than loot's -- claiming is visible on
# the map regardless of how clean the entry was; loot only bites if caught.
const CLAIM_RELATION_HIT := -40
const LOOT_RELATION_HIT := -15
const LOOT_ORE_QTY := 8


# Transfers a faction-owned vein to player ownership (all fields carried
# over unchanged), takes the severe relation hit regardless of caught/clean
# (claiming is visible on the map either way), and queues a map "seed_claim"
# event. No-op if the site has no factionVein.
static func claim_vein(site_id: String) -> void:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return

	var faction_vein: Dictionary = site["factionVein"]
	var faction_id: String = faction_vein["factionId"]
	var vein_id: String = faction_vein["id"]
	var district: String = site["district"]

	var player_vein: Dictionary = GameState.deep_copy(faction_vein)
	player_vein.erase("factionId")
	GameState.state["player"]["veins"].append(player_vein)

	site["claimed"] = true
	site["factionVein"] = null

	Factions.adjust_player_relation(faction_id, CLAIM_RELATION_HIT)
	MapEvents.queue_seed_claim(district, vein_id, "player")
	EventBus.state_changed.emit()


# One-time ore payoff -- ownership stays with the faction, the vein itself is
# untouched. Relation hit only applies when `caught` is true (a clean
# stealth-and-loot leaves relation untouched). No-op if the site has no
# factionVein.
static func loot_vein(site_id: String, caught: bool) -> void:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return

	var vein: Dictionary = site["factionVein"]
	var ore: Dictionary = GameState.state["player"]["orichalchum"]
	ore[vein["oreType"]] = ore.get(vein["oreType"], 0) + LOOT_ORE_QTY

	if caught:
		Factions.adjust_player_relation(vein["factionId"], LOOT_RELATION_HIT)

	EventBus.state_changed.emit()


# ── raid entry point ─────────────────────────────────────────────────────

# The one raid event card authored so far (a tracer bullet, not a full
# content pass). Targets whichever real site's Raid button was pressed
# (events.gd's _event_site_id()), so this single card works against any
# real faction-owned vein; prose is deliberately faction/district-neutral.
const RAID_EVENT_ID := "vein_raid"


# Standard travel/time-block gating, then hands off to the event engine.
# ally_ids carries the raid-initiation UI's chosen allies into the event
# context for Combat.start_raid() to gather later.
static func begin_raid(vein: Dictionary, ally_ids: Array = []) -> Dictionary:
	var travel := Travel.ensure_district(vein["district"], 1)
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()
	Events.start_event(RAID_EVENT_ID, { "site_id": vein["siteId"], "ally_ids": ally_ids })
	return { "ok": true }


# ── Direction B: daily-tick raid trigger ─────────────────────────────────
# A faction raids one of the player's own veins (mirror of Direction A
# above); called from TimeSystem.daily_tick() with the same
# attempts/odds/resolve split as Factions' rivalry code (R§3.12).


# Low baseline: rolled once per player vein per tick, with no per-faction
# pre-filter (unlike the coarser faction-rivalry attempts in Factions).
const RAID_BASE_CHANCE := 0.05

# Relation ranges roughly -100..+60 (joinRelation ceiling); 100 keeps a
# realistic swing's tilt within roughly +/-1 before the weight scales it down.
const RAID_RELATION_DIVISOR := 100.0
const RAID_RELATION_WEIGHT := 0.20

# dangerMod ranges -0.05..+0.10, small enough to weight directly rather
# than normalise against a ceiling.
const RAID_DANGER_WEIGHT := 0.5

# raidResist normalised against the 55.0 "guarded" anchor, not a hard
# ceiling -- see R§1.6 for why extra guards can push the tilt past it.
const RAID_RAID_RESIST_DIVISOR := 55.0
const RAID_RAID_RESIST_WEIGHT := 0.20

# Growth (normalised against the vein's own ceiling, 0..1) tilts a raid more
# likely the wilder/less-tended a vein is; weight kept in line with the
# relation/resist weights above.
const RAID_GROWTH_WEIGHT := 0.15


# Attacker is the vein's district factionPresence if it has one; a district
# with no presence (e.g. Hampstead) falls back to whichever faction
# currently has the worst relation with the player.
static func _attacking_faction(vein: Dictionary) -> String:
	var district: Dictionary = GameData.DISTRICTS.get(vein["district"], {})
	var presence: String = district.get("factionPresence", "")
	if presence != "" and GameData.FACTIONS.has(presence):
		return presence
	return _pick_worst_relation_faction()


# Kept high enough that every faction's weight stays positive across the
# realistic relation range (joinRelation tops out at 60); weight scales up
# sharply as relation drops.
const FALLBACK_ATTACKER_RELATION_BASELINE := 100.0


static func _pick_worst_relation_faction() -> String:
	var faction_ids: Array = GameData.FACTIONS.keys()
	var weight_list: Array[float] = []
	for faction_id in faction_ids:
		var relation: int = GameState.state["factions"][faction_id]["relation"]
		weight_list.append(maxf(1.0, FALLBACK_ATTACKER_RELATION_BASELINE - relation))
	return faction_ids[Factions.weighted_pick_index(weight_list)]


# ── per-faction raid/conquer eligibility thresholds ──────────────────────
# Data-driven per faction (raidThreshold/conquerThreshold, R§1.8) rather
# than hardcoded branches; a faction acts only when strictly below its
# threshold.
static func _faction_raid_threshold(faction_id: String) -> int:
	return GameData.FACTIONS[faction_id]["raidThreshold"]


static func _faction_conquer_threshold(faction_id: String) -> int:
	var faction: Dictionary = GameData.FACTIONS[faction_id]
	return faction.get("conquerThreshold", faction["raidThreshold"])


static func _relation_below(faction_id: String, threshold: int) -> bool:
	var relation: int = GameState.state["factions"][faction_id]["relation"]
	return relation < threshold


static func _faction_will_attempt_raids(faction_id: String) -> bool:
	return _relation_below(faction_id, _faction_raid_threshold(faction_id))


static func _faction_may_conquer(faction_id: String) -> bool:
	return _relation_below(faction_id, _faction_conquer_threshold(faction_id))


# One candidate per eligible player vein (no pre-filter; raid_success_chance()/
# roll_raid_odds() below decide what actually happens). Veins with a
# missing/dangling siteId (pre-existing saves) are skipped, not crashed on.
# Pure -- no state mutation.
static func roll_raid_attempts() -> Array:
	var attempts := []
	for vein in GameState.state["player"]["veins"]:
		var site_id: Variant = vein.get("siteId")
		if site_id == null or Sites.find_site(site_id) == null:
			continue
		var attacker_id: String = _attacking_faction(vein)
		if not _faction_will_attempt_raids(attacker_id):
			continue
		attempts.append({
			"attackerId": attacker_id,
			"veinId": vein["id"],
			"siteId": site_id,
		})
	return attempts


# Mirrors Factions.rivalry_success_chance(): low baseline tilted by relation
# (lower=higher chance), dangerMod, raidResist (R§1.6 anchor, inverted), growth.
static func raid_success_chance(attacker_id: String, vein: Dictionary) -> float:
	var relation: int = GameState.state["factions"][attacker_id]["relation"]
	var relation_tilt: float = -(float(relation) / RAID_RELATION_DIVISOR) * RAID_RELATION_WEIGHT

	var district: Dictionary = GameData.DISTRICTS.get(vein["district"], {})
	var danger_mod: float = district.get("dangerMod", 0.0)
	var danger_tilt: float = danger_mod * RAID_DANGER_WEIGHT

	var raid_resist: int = Cultivating.vein_raid_resist(vein)
	var resist_tilt: float = -(float(raid_resist) / RAID_RAID_RESIST_DIVISOR) * RAID_RAID_RESIST_WEIGHT

	var growth_tilt: float = RAID_GROWTH_WEIGHT * (float(vein["growth"]) / Cultivating.ceiling(vein))

	var chance: float = RAID_BASE_CHANCE + relation_tilt + danger_tilt + resist_tilt + growth_tilt
	return clampf(chance, 0.0, 1.0)


# ── claim-vs-loot split ───────────────────────────────────────────────────
# Draft only, needs balance sign-off -- linear interpolation between the
# poor/saturated endpoints. See R§3.12 for the outcome split this feeds.
const CLAIM_CHANCE_BY_TERROIR := {
	"poor": 0.05,
	"fair": 0.28,
	"rich": 0.52,
	"saturated": 0.75,
}


static func claim_chance(vein: Dictionary) -> float:
	var tier: String = vein.get("hospitability", {}).get("tier", "fair")
	return CLAIM_CHANCE_BY_TERROIR.get(tier, CLAIM_CHANCE_BY_TERROIR["fair"])


# ── stealth/caught roll ───────────────────────────────────────────────────
# A second roll, independent of the claim-vs-loot split above, deciding
# whether the attacker gets caught. Only the loot branch's copy names the
# faction differently based on it (the claim branch always names the
# faction); rolled for every successful attempt regardless of outcomeType,
# at roll_raid_odds() time, so the result can ride through the
# alarm-defend queue the same way outcomeType does.
#
# Each faction's "raidStealth" (0.0-1.0) is its baseline clean-getaway
# chance, trimmed proportionally to the vein's raidResist (same
# normalise-against-55 "guarded" anchor as stealth_success_chance()/
# raid_success_chance()). Draft weight, needs balance sign-off.
const FACTION_STEALTH_RAID_RESIST_DIVISOR := 55.0
const FACTION_STEALTH_RAID_RESIST_WEIGHT := 0.35


static func faction_stealth_chance(attacker_id: String, vein: Dictionary) -> float:
	var base_stealth: float = GameData.FACTIONS[attacker_id]["raidStealth"]
	var raid_resist: int = Cultivating.vein_raid_resist(vein)
	var resist_tilt: float = -(float(raid_resist) / FACTION_STEALTH_RAID_RESIST_DIVISOR) * FACTION_STEALTH_RAID_RESIST_WEIGHT
	return clampf(base_stealth + resist_tilt, 0.0, 1.0)


# Stand-in for the faction's name when a loot outcome comes back clean
# (used by resolve_raid_outcome()'s loot branch and _queue_defend_raid()'s
# advance warning). PROSE-REVIEW: drafted against CONTENT-GUIDE.md's tone bible.
const ANONYMOUS_RAIDER_LABEL := "Someone"


# Draft, needs balance sign-off -- kept in line with Direction A's own
# LOOT_ORE_QTY (8) and pruneLightDepth (9, data/vein_growth.json), so a
# loss to loot never bites harder than the player's own worst prune.
const RAID_LOOT_ORE_QTY := 8
const RAID_LOOT_PRUNE_DEPTH := 9


# Rolls the chance above and returns the attempt annotated with "success"
# plus (only when successful) "outcomeType" ("claim"/"loot", via
# claim_chance()). Pure computation -- mutation and the Notify push are
# resolve_raid_outcome()'s job. A vanished target vein reads as chance 0
# rather than indexing a null vein (same defensive shape as
# Factions.rivalry_success_chance()). claim_chance() only rolls when the
# attacker's relation clears its own conquerThreshold
# (_faction_may_conquer()); below that a successful raid is capped at
# "loot" regardless of claim_chance()'s odds.
static func roll_raid_odds(attempt: Dictionary) -> Dictionary:
	var outcome: Dictionary = attempt.duplicate()
	var vein: Variant = Cultivating.find_vein(attempt["veinId"])
	if vein == null:
		outcome["success"] = false
		return outcome
	outcome["success"] = Rng.chance(raid_success_chance(attempt["attackerId"], vein))
	if outcome["success"]:
		var may_conquer: bool = _faction_may_conquer(attempt["attackerId"])
		outcome["outcomeType"] = "claim" if (may_conquer and Rng.chance(claim_chance(vein))) else "loot"
		# Independent of the claim/loot roll above -- rolled here (rather than
		# in resolve_raid_outcome()) so the result is already known and can
		# ride through the alarm-defend queue the same way outcomeType does.
		outcome["caught"] = not Rng.chance(faction_stealth_chance(attempt["attackerId"], vein))
	return outcome


# Applies one already-rolled outcome. A failed attempt is a no-op (no
# ownership change, no notification). A successful "claim" removes the
# vein from player.veins and reassigns it (fields unchanged) into the
# site's factionVein, flipping the site back to faction-owned -- the
# mirror of Sites.attempt_seed()'s claimed=true/factionVein=null
# transition, so it can later be raided back via Direction A
# (begin_raid() requires vein["siteId"]). Pushes a Notify (background
# changes to the player's own stuff are always surfaced, same convention
# as Sites.roll_npc_claims()) and queues a "seed_claim" map event
# referencing the vein's district/id and the attacker as owner -- the
# single choke point both Direction B loss paths (an off-screen default
# loss and a lost defend-encounter via resolve_defend_outcome() below) share.
#
# Re-checks the vein's live presence in player.veins first, so a vein
# that vanished since the attempt was recorded (e.g. levelled down to
# nothing elsewhere this tick) is silently skipped.
#
# missed_defend (set only by _expire_pending_defend_raids() below) swaps
# in "you had a window and missed it" copy instead of the plain no-alarm
# loss text. outcome["outcomeType"] defaults to "claim" when absent
# (hand-built outcome dicts, including in tests) or "loot", rolled by
# roll_raid_odds() above.
static func resolve_raid_outcome(outcome: Dictionary, missed_defend: bool = false) -> void:
	if not outcome["success"]:
		return

	var vein: Variant = Cultivating.find_vein(outcome["veinId"])
	if vein == null:
		return

	var site: Variant = Sites.find_site(outcome["siteId"])
	if site == null or site["factionVein"] != null:
		return

	var district_name: String = GameData.DISTRICTS[vein["district"]]["name"]
	var faction_name: String = GameData.FACTIONS[outcome["attackerId"]]["shortName"]

	if outcome.get("outcomeType", "claim") == "loot":
		# "caught" defaults true (identity revealed) for an outcome dict
		# built without the key, mirroring outcomeType's default-to-"claim".
		_apply_raid_loot(vein, faction_name, district_name, missed_defend, outcome.get("caught", true))
		return

	var faction_vein: Dictionary = GameState.deep_copy(vein)
	faction_vein["factionId"] = outcome["attackerId"]
	site["factionVein"] = faction_vein
	site["claimed"] = false

	var player: Dictionary = GameState.state["player"]
	var vein_id: String = outcome["veinId"]
	player["veins"] = player["veins"].filter(func(v): return v["id"] != vein_id)
	Sites.release_vein_slot(vein)
	# Act 2 T8a (spec §6.8a): a no-op unless vein_id is the one col_a2_nadia_
	# defend was watching, in which case it re-targets rather than dead-ending.
	Collective.maybe_retarget_nadia_defend_vein(vein_id)

	MapEvents.queue_seed_claim(vein["district"], vein_id, outcome["attackerId"])

	# PROSE-REVIEW: drafted against CONTENT-GUIDE.md's tone bible.
	if missed_defend:
		Notify.push("Too late — %s took your vein in %s while the alarm was still ringing." % [faction_name, district_name], Notify.CATEGORY_DANGER)
	else:
		Notify.push("%s raided your vein in %s. It's theirs now." % [faction_name, district_name], Notify.CATEGORY_DANGER)


# Direction B loot outcome: the common-case result of a successful raid --
# the vein stays player-owned, just pruned (RAID_LOOT_PRUNE_DEPTH) and
# short a flat quantity of the player's own ore stash (RAID_LOOT_ORE_QTY),
# clamped to what's on hand. Unlike Direction A's loot_vein() (which
# materialises ore from a faction that never tracked real stock), this
# steals from a real stash, so it can never go negative. No relation hit
# (a faction acting against the player, not the reverse) and no map event
# (the vein never changes hands). PROSE-REVIEW: one dry line with a
# concrete ore count, distinct from the claim branch's "It's theirs now."
# and the missed-defend claim copy, so the player can tell which of the
# four claim/loot x on-time/missed combinations happened. `caught` swaps
# the faction's name for ANONYMOUS_RAIDER_LABEL when the stealth roll came
# back clean -- only the identity differs, never the fact of the loss.
# PROSE-REVIEW: the clean-loot copy is new.
static func _apply_raid_loot(vein: Dictionary, faction_name: String, district_name: String, missed_defend: bool, caught: bool) -> void:
	vein["growth"] = maxi(0, vein["growth"] - RAID_LOOT_PRUNE_DEPTH)

	var ore_type: String = vein["oreType"]
	var ore: Dictionary = GameState.state["player"]["orichalchum"]
	var stolen: int = mini(RAID_LOOT_ORE_QTY, ore.get(ore_type, 0))
	ore[ore_type] = ore.get(ore_type, 0) - stolen

	var attacker: String = faction_name if caught else ANONYMOUS_RAIDER_LABEL
	if missed_defend:
		Notify.push("Too late — %s pruned your vein in %s and got away with %d units of ore while the alarm was still ringing. It's still yours." % [attacker, district_name, stolen], Notify.CATEGORY_DANGER)
	else:
		Notify.push("%s raided your vein in %s, pruning it and getting away with %d units of ore. It's still yours." % [attacker, district_name, stolen], Notify.CATEGORY_DANGER)


# Called from time_system.gd's daily_tick, step 5i. Runs the previous
# tick's still-pending alarm-defend raids first (a player who never
# travelled to defend one loses it exactly as the no-alarm path would),
# then rolls this tick's fresh attempts: a success against an alarmed
# vein queues for the player to defend; every other success resolves now.
static func apply_raid_resolution() -> void:
	_expire_pending_defend_raids()

	for attempt in roll_raid_attempts():
		var outcome := roll_raid_odds(attempt)
		if not outcome["success"]:
			continue
		var vein: Variant = Cultivating.find_vein(outcome["veinId"])
		if vein != null and vein["alarmUpgrades"].has(Cultivating.ALARM_UPGRADE_ID):
			_queue_defend_raid(outcome, vein)
		else:
			resolve_raid_outcome(outcome)


# ── Direction B: alarm defend encounter ──────────────────────────────────
# Layers the alarm upgrade onto the raid trigger above as the one case
# with player agency. A successful attempt against an alarmed vein doesn't
# resolve here -- it queues in state.world.pendingDefendRaids and alerts
# the player, giving them the rest of the current day (until the next
# daily_tick; there's no separate countdown system) to travel to the
# vein's district and fight it out. maybe_trigger_defend() below is the
# arrival-side hook (Travel.travel_to()/Sites.prospect(), the same
# chokepoints DistrictDeck.maybe_trigger() uses); _expire_pending_
# defend_raids() is the fallthrough side, resolving anything still
# unclaimed at the top of the next tick, so a missed window plays out
# identically to the no-alarm path.
static func _queue_defend_raid(outcome: Dictionary, vein: Dictionary) -> void:
	GameState.state["world"]["pendingDefendRaids"].append(outcome)
	var district_name: String = GameData.DISTRICTS[vein["district"]]["name"]
	var faction_name: String = GameData.FACTIONS[outcome["attackerId"]]["shortName"]
	# PROSE-REVIEW: dry, administrative, one line, per CONTENT-GUIDE.md.
	# The claim/loot x caught/clean outcome is already rolled (same tick),
	# so a warning bound for a clean loot is anonymized here too. Separate
	# sentences (not a %s swap) since "Someone" takes a singular verb ("is")
	# where a faction's shortName reads as a plural collective ("are").
	var will_be_clean_loot: bool = outcome.get("outcomeType") == "loot" and not outcome.get("caught", true)
	var warning_text: String
	if will_be_clean_loot:
		warning_text = "Alarm's gone off — someone's closing in on your vein in %s. Get there today to defend it." % district_name
	else:
		warning_text = "Alarm's gone off — %s are closing in on your vein in %s. Get there today to defend it." % [faction_name, district_name]
	# veinId meta lets phone.gd's Notifications app render a Defend button
	# on this entry. The notification's id is stashed back onto the queued
	# outcome so is_defend_notification_pending() below can scope the
	# button to this raid occurrence -- matching on veinId alone would
	# resurrect the button on an already-resolved warning once the vein is
	# raided again (Notify.LOG_CAP caps the log rather than clearing it).
	var notification := Notify.push(warning_text, Notify.CATEGORY_WARNING, { "veinId": vein["id"] })
	outcome["notificationId"] = notification["id"]


# Before a missed-defend window falls through to resolve_raid_outcome()'s
# auto-loss, a vein with 1+ extraGuards gets a chance to repel the raid
# outright. Chance-per-guard and cap live in data/constants.json's
# "guardRepel" (GameData.GUARD_REPEL_CHANCE_PER_GUARD/_CAP), shared with
# Home's own guard_repel_chance() mirror so retuning never touches a .gd
# file. Zero guards skips the roll entirely -- no chance consumed.
static func guard_repel_chance(guard_count: int) -> float:
	return clampf(guard_count * GameData.GUARD_REPEL_CHANCE_PER_GUARD, 0.0, GameData.GUARD_REPEL_CHANCE_CAP)


# Rolls the repel chance for one expiring outcome and, on success, pushes
# a "held without you" notification and returns true so the caller skips
# resolve_raid_outcome() entirely -- no ownership change, no ore lost. A
# vanished vein reads as zero guards (same default vein.get("extraGuards",
# 0) uses elsewhere in this file), so resolve_raid_outcome()'s null-vein
# no-op still covers that case if this returns false. PROSE-REVIEW:
# distinct from both the silent "you defended it yourself" win path and
# every missed-defend loss line above, so the player can tell "guards
# held it" apart from either.
static func _guards_repel_defend_raid(outcome: Dictionary) -> bool:
	var vein: Variant = Cultivating.find_vein(outcome["veinId"])
	if vein == null:
		return false

	var guard_count: int = vein.get("extraGuards", 0)
	if guard_count <= 0:
		return false
	if not Rng.chance(guard_repel_chance(guard_count)):
		return false

	var district_name: String = GameData.DISTRICTS[vein["district"]]["name"]
	var faction_name: String = GameData.FACTIONS[outcome["attackerId"]]["shortName"]
	var attacker: String = faction_name if outcome.get("caught", true) else ANONYMOUS_RAIDER_LABEL
	Notify.push("Your guards saw %s off your vein in %s before you got there. Nothing lost." % [attacker, district_name], Notify.CATEGORY_SUCCESS)
	return true


# Passes missed_defend=true -- see resolve_raid_outcome() above.
static func _expire_pending_defend_raids() -> void:
	var world: Dictionary = GameState.state["world"]
	var pending: Array = world["pendingDefendRaids"]
	world["pendingDefendRaids"] = []
	for outcome in pending:
		if _guards_repel_defend_raid(outcome):
			continue
		resolve_raid_outcome(outcome, true)


# Called from Travel.travel_to()/Sites.prospect() once the player's arrival
# in district_id is otherwise resolved -- same shape/placement as
# DistrictDeck.maybe_trigger(), and deliberately checked first: a defend
# encounter takes the screen over exactly like combat always does, so the
# district-deck's own flavour roll must not also fire the same beat. Returns
# true when a defend combat started, so callers know to skip that roll.
static func maybe_trigger_defend(district_id: String) -> bool:
	var pending: Array = GameState.state["world"]["pendingDefendRaids"]
	for i in range(pending.size()):
		var outcome: Dictionary = pending[i]
		var vein: Variant = Cultivating.find_vein(outcome["veinId"])
		if vein != null and vein["district"] == district_id:
			pending.remove_at(i)
			GameState.state["world"]["activeDefendRaid"] = outcome
			Combat.start_defend_vein(outcome["veinId"], Cultivating.combined_magnitude(vein))
			return true
	return false


# Index into pendingDefendRaids of the entry queued for vein_id, or -1.
# Shared by has_pending_defend() and trigger_defend() below so the "which
# entry matches this vein" scan exists in exactly one place.
static func _pending_defend_index(vein_id: String) -> int:
	var pending: Array = GameState.state["world"]["pendingDefendRaids"]
	for i in range(pending.size()):
		if pending[i]["veinId"] == vein_id:
			return i
	return -1


# Does vein_id have a raid queued in state.world.pendingDefendRaids right
# now? Used by the vein's own Defend button (map.gd's
# _build_vein_action_card()) to decide whether to show the button -- once
# the raid resolves or expires, this goes false and the button stops
# rendering, no extra bookkeeping needed. Matching on vein_id alone is
# correct here (contrast is_defend_notification_pending() below, which
# scopes to one specific historical notification instead).
static func has_pending_defend(vein_id: String) -> bool:
	return _pending_defend_index(vein_id) != -1


# Is the exact raid that notification_id warned about still pending?
# Used by the raid-warning notification's own Defend button instead of
# has_pending_defend() -- the Notifications log only caps entries, it
# doesn't clear them, so a resolved warning can still be sitting in the
# log when the same vein is raided again; matching on veinId alone would
# incorrectly reactivate that entry's button too. _queue_defend_raid()
# stashes the notification's id for this lookup.
static func is_defend_notification_pending(notification_id: String) -> bool:
	for outcome in GameState.state["world"]["pendingDefendRaids"]:
		if outcome.get("notificationId") == notification_id:
			return true
	return false


# The explicit-trigger sibling of maybe_trigger_defend() above -- same
# pop-and-start shape, but keyed on vein_id instead of district_id since
# there's no arrival to key off. The player presses Defend from the
# vein's site sheet or the raid-warning notification in the Phone's
# Notifications app, and the fight starts immediately, no travel cost.
# Re-checks the queue itself (rather than trusting whatever
# has_pending_defend()/is_defend_notification_pending() rendered the
# button from) in case the window closed between render and tap -- e.g.
# the player left the sheet open across a daily_tick.
static func trigger_defend(vein_id: String) -> bool:
	var i := _pending_defend_index(vein_id)
	if i == -1:
		return false
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		return false
	var pending: Array = GameState.state["world"]["pendingDefendRaids"]
	var outcome: Dictionary = pending[i]
	pending.remove_at(i)
	GameState.state["world"]["activeDefendRaid"] = outcome
	Combat.start_defend_vein(vein_id, Cultivating.combined_magnitude(vein))
	return true


# The committed "Leave undefended" path. The caller supplies the
# notification identity it rendered, but this is still the authority
# boundary: find the live queued record again, remove exactly that one,
# then run the ordinary guard-repel/loss path. Removing it first makes
# repeated, stale, or re-entrant confirms a harmless no-op.
static func leave_undefended(vein_id: String, notification_id: String) -> bool:
	var pending: Array = GameState.state["world"]["pendingDefendRaids"]
	for i in range(pending.size()):
		var outcome: Dictionary = pending[i]
		if outcome.get("veinId", "") != vein_id:
			continue
		if str(outcome.get("notificationId", "")) != notification_id:
			continue

		pending.remove_at(i)
		if not _guards_repel_defend_raid(outcome):
			resolve_raid_outcome(outcome)
		EventBus.state_changed.emit()
		return true
	return false


# Called by Combat.exit_combat()'s "defend_vein" branch. A win leaves the
# vein untouched (ownership was never moved, and the PRD wants no separate
# win notification). A loss reuses resolve_raid_outcome() so the transfer
# and its Notify text match every other whole-vein-loss path in this file.
static func resolve_defend_outcome(won: bool) -> void:
	var outcome: Variant = GameState.state["world"]["activeDefendRaid"]
	GameState.state["world"]["activeDefendRaid"] = null
	if won and outcome != null:
		Objectives.record_alarm_defend_win(outcome["veinId"])
	Objectives.refresh()
	if won or outcome == null:
		return
	resolve_raid_outcome(outcome)
