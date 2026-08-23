class_name Raiding
extends RefCounted

# Direction A: stealth-check + raid resolution ops, per the vein-raiding PRD
# (.scratch/7-vein-raiding/spec.md) ticket 02. Registered as effect ops in
# systems/events.gd's _apply_one() ("stealth_check", "start_raid_combat",
# "claim_raid_vein", "loot_raid_vein") -- this file holds the pure/testable
# logic, the same "events.gd is a thin op dispatcher into a system" shape its
# existing "relation" -> Contacts.award_relation() and
# "npc_claim_best_unclaimed_site" -> Sites.npc_claim_best_unclaimed_site()
# ops already use. No UI, no real event-card wiring yet -- that's ticket 03.


# ── stealth check ────────────────────────────────────────────────────────
# Formula/weighting is this ticket's explicit call to make (open per the
# PRD), documented here the same way Factions.roll_rivalry_odds()'s
# similarly-open weighting is: a coin-flip-ish baseline, pushed up by
# stealthSkill and any consumable bonus the event card grants, pushed down by
# the target vein's security tier (raidResist, normalised against its
# ceiling -- "guarded" = 55, data/vein_security.json -- the same
# normalisation Factions.rivalry_success_chance() uses for the same field)
# and by the vein's value (basePrice * Cultivating.value_tier(vein), the
# same value metric Factions._pick_target_vein()/apply_security_upgrades()
# already use elsewhere) -- a richer, better-defended vein is harder to
# walk into clean.
const STEALTH_BASE_CHANCE := 0.55
const STEALTH_SKILL_WEIGHT := 0.05
const STEALTH_RAID_RESIST_DIVISOR := 55.0
const STEALTH_RAID_RESIST_WEIGHT := 0.35
# basePrice (~55-90) * value_tier (1-6, vein-growth-state ticket 03) tops
# out around 450-540 for a maxed-out high-value vein -- dividing by 450
# keeps the tilt within roughly [-1.2, 0] before the weight scales it down,
# same shape as the raidResist normalisation above (still clamped to [0, 1]
# by the function's return, so the tier-6 overshoot is harmless).
const STEALTH_VALUE_DIVISOR := 450.0
const STEALTH_VALUE_WEIGHT := 0.15


static func stealth_success_chance(stealth_skill: int, vein: Dictionary, consumable_bonus: float) -> float:
	var skill_tilt: float = (stealth_skill - 1) * STEALTH_SKILL_WEIGHT

	var raid_resist: int = GameData.VEIN_SECURITY[vein["security"]]["raidResist"]
	var resist_tilt: float = -(float(raid_resist) / STEALTH_RAID_RESIST_DIVISOR) * STEALTH_RAID_RESIST_WEIGHT

	var value: float = GameData.ORE_TYPES[vein["oreType"]]["basePrice"] * Cultivating.value_tier(vein)
	var value_tilt: float = -(value / STEALTH_VALUE_DIVISOR) * STEALTH_VALUE_WEIGHT

	var chance: float = STEALTH_BASE_CHANCE + skill_tilt + resist_tilt + value_tilt + consumable_bonus
	return clampf(chance, 0.0, 1.0)


# XP magnitude is this ticket's call too -- mirrors Crafting.award_crafting_xp's
# success/fail split shape (full reward on success, roughly a third on
# failure), rather than Cultivating's flat "same either way" -- a caught
# attempt still teaches you something, just less than a clean one.
const STEALTH_XP_SUCCESS := 20
const STEALTH_XP_CAUGHT := 7


static func award_stealth_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var on_level_up := func(): Notify.push("Stealth skill up — now level %d." % player["stealthSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "stealthXP", "stealthSkill", GameData.STEALTH_XP_LEVELS, amount, on_level_up)


# Rolls the check against the current player and awards stealth XP either
# way (win or lose, per the ticket). Returns success so the caller (events.gd's
# "stealth_check" op) can branch into on_success/on_caught effects, the same
# on_success/on_fail shape the existing "chance" op already uses.
static func resolve_stealth_check(vein: Dictionary, consumable_bonus: float) -> bool:
	var skill: int = GameState.state["player"]["stealthSkill"]
	var success: bool = Rng.chance(stealth_success_chance(skill, vein, consumable_bonus))
	award_stealth_xp(STEALTH_XP_SUCCESS if success else STEALTH_XP_CAUGHT)
	return success


# ── claim / loot resolution ─────────────────────────────────────────────

# Magnitudes are this ticket's call (PRD leaves them open) -- claim's hit is
# far heavier than loot's, matching the PRD's "claiming is visible on the map
# regardless of how clean the entry was" vs. loot's "only if actually caught".
const CLAIM_RELATION_HIT := -40
const LOOT_RELATION_HIT := -15
const LOOT_ORE_QTY := 8


# Converts a still-faction-owned site's vein to player ownership. Carries
# every field over unchanged (oreType/growth/security explicitly, per the
# ticket, but also location/hospitability/etc.) -- the same
# "ownership changes hands, nothing about the vein itself resets" convention
# Factions.resolve_rivalry_outcome() already established for faction-to-
# faction transfers, just crossing from faction to player instead. Always a
# severe relation hit, regardless of caught/clean (claiming is visible on the
# map either way). No-op if the site has no factionVein (bad site_id, or
# already transferred elsewhere -- e.g. a same-tick rivalry resolution).
#
# direction-a-map-visibility T04: also queues a map-animations-ticket-02-
# shaped "seed_claim" event (district/vein id, owner "player") -- the same
# reuse Factions.resolve_rivalry_outcome() established for rivalry-driven
# transfers (map-visibility-for-rivalry-ownership-changes T05), just with the
# player as the new owner instead of a rival faction. MapCanvas's existing
# ring-draw-in playback doesn't care whether the vein is new or just changed
# hands, since it resolves the vein's *current* owner live rather than off a
# snapshot -- no new trigger-specific code needed on the playback side.
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
# untouched. Only applies the moderate relation hit when `caught` is true (a
# clean stealth-and-loot leaves relation untouched, per the PRD) -- `caught`
# is supplied by the calling event card's own branch (the caught-combat-win
# path passes true, the clean-stealth path passes false), not read back from
# any runtime flag. No-op if the site has no factionVein.
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


# ── raid entry point (ticket 03) ────────────────────────────────────────

# The one representative raid event card authored for this ticket (tracer
# bullet, not a content pass -- per the PRD's own open question, more cards
# per faction/district/ore-type circumstance are a later content pass). It
# targets whichever real site's Raid button was pressed via start_event()'s
# context, not a literal baked into its own JSON (see events.gd's
# _event_site_id()) -- so this single card already works against any real
# faction-owned vein, whatever its actual faction/district/ore turn out to be.
# Its prose is deliberately faction/district-neutral for the same reason
# (no hardcoded name that could mismatch the real vein it's run against).
const RAID_EVENT_ID := "vein_raid"


# Called by the faction-vein site sheet's Raid button (scenes/screens/map.gd)
# with that site's factionVein dict. Same travel/time-block gating shape
# every other districted action uses (Cultivating.cultivate() etc.) --
# ensure_district() first, then spend the block -- before handing off to the
# event engine. `ally_ids` (45-archie-raid-assist) is the raid-initiation
# UI's own choice of who's coming along, carried into the event's context so
# Combat.start_raid() (via events.gd's _start_raid_combat()) can gather them
# once the vein_raid event's combat card actually fires.
static func begin_raid(vein: Dictionary, ally_ids: Array = []) -> Dictionary:
	var travel := Travel.ensure_district(vein["district"], 1)
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()
	Events.start_event(RAID_EVENT_ID, { "site_id": vein["siteId"], "ally_ids": ally_ids })
	return { "ok": true }


# ── Direction B: daily-tick raid trigger (ticket 06) ────────────────────
# The mirror of Direction A above: instead of the player raiding a
# faction's vein, a faction raids one of the player's own. Called from
# systems/time_system.gd's daily_tick() (step 5i, right after Chunk 6's
# rivalry resolution). Same attempts/odds/resolve split Chunk 6's rivalry
# code uses (roll_rivalry_attempts()/roll_rivalry_odds()/
# resolve_rivalry_outcome(), systems/factions.gd) -- a pure roll that
# decides who's attempted against what, a pure odds calc + roll, then a
# resolution step that's the only one allowed to mutate state or push a
# Notify.
#
# This ticket implements the no-alarm / default (off-screen) path only --
# ticket 07 layers an alarm branch-off on top, before resolve_raid_outcome
# would otherwise run.
#
# Eligible targets: every player vein with a siteId resolving to a live
# state.world.sites entry -- transfers into that site's factionVein, the
# existing faction-ownership home every other system (Direction A, Chunk 6
# rivalry, faction passive/vein income, security upgrades, the Network Map)
# already reads, and preserves the PRD's promised loop ("a vein taken this
# way can later be raided back via Direction A", which requires
# vein["siteId"], see begin_raid() above). Ticket 09 closed off every path
# that could create a free-floating player vein, so that case no longer
# needs handling here (ticket 11 retired the state.factions[id].veins
# scaffolding ticket 06 originally added for it).


# Baseline "no dice rolled yet" chance before the three tilts below --
# deliberately low next to Chunk 6's RIVALRY_BASE_CHANCE (0.5): that chance
# only fires after a coarse per-faction initiation roll already filtered
# down to a handful of attempts a tick, whereas this rolls once per player
# vein, every tick, with no such pre-filter (same shape as
# Sites.npc_claim_chance()'s low per-site daily base).
const RAID_BASE_CHANCE := 0.05

# relation ranges roughly -100 (a couple of Direction-A claim hits) to +60
# (joinRelation's ceiling, data/factions.json) -- 100 keeps a realistic
# swing's tilt within roughly +/-1 before the weight below scales it down,
# same normalise-then-weight shape Factions.rivalry_success_chance() uses
# for its own relation term.
const RAID_RELATION_DIVISOR := 100.0
const RAID_RELATION_WEIGHT := 0.20

# dangerMod (data/districts.json) ranges -0.05..+0.10 -- small enough that
# a direct (unnormalised) weight keeps its tilt modest next to the other
# two inputs, same as how Economy/Districts consume dangerMod directly
# elsewhere rather than normalising it against a ceiling.
const RAID_DANGER_WEIGHT := 0.5

# raidResist's ceiling is "guarded" (55, data/vein_security.json) -- same
# normalise-against-the-ceiling shape Factions.rivalry_success_chance() and
# stealth_success_chance() above both already use for this exact field.
const RAID_RAID_RESIST_DIVISOR := 55.0
const RAID_RAID_RESIST_WEIGHT := 0.20

# vein-growth-state ticket 03 §3: continuous "wild attracts raids" tilt --
# growth/Cultivating.ceiling(vein) ranges 0..1, since growth is always
# clamped to that same vein's own ceiling (Cultivating._drift_one(),
# cultivate()). Magnitude deliberately in line with RAID_RELATION_WEIGHT and
# RAID_RAID_RESIST_WEIGHT above -- significant but not dominant.
const RAID_GROWTH_WEIGHT := 0.15


# Attacking-faction selection (the ticket's explicit "resolve sensibly"
# call): a vein's own district's factionPresence (data/districts.json) is
# the natural attacker -- it's already who the chance formula below reads
# relation from, so the faction driving whether a raid happens is also the
# one throwing the punch. A district with no presence (e.g. Hampstead)
# falls back to the ticket's own suggested heuristic -- weighted toward
# whichever faction currently has the worst (lowest) relation with the
# player, since a faction that already resents the player is the
# sensible one to imagine showing up uninvited. Each vein resolves its
# attacker independently off its own district, so a player with veins
# across multiple districts/factions just gets one sensible per-vein
# answer with no cross-vein coordination needed.
static func _attacking_faction(vein: Dictionary) -> String:
	var district: Dictionary = GameData.DISTRICTS.get(vein["district"], {})
	var presence: String = district.get("factionPresence", "")
	if presence != "" and GameData.FACTIONS.has(presence):
		return presence
	return _pick_worst_relation_faction()


# Baseline high enough that every faction's weight stays positive across
# the realistic relation range (joinRelation tops out at 60) while still
# scaling up sharply as relation drops through 0 and negative -- the worse
# the relation, the heavier the weight.
const FALLBACK_ATTACKER_RELATION_BASELINE := 100.0


static func _pick_worst_relation_faction() -> String:
	var faction_ids: Array = GameData.FACTIONS.keys()
	var weight_list: Array[float] = []
	for faction_id in faction_ids:
		var relation: int = GameState.state["factions"][faction_id]["relation"]
		weight_list.append(maxf(1.0, FALLBACK_ATTACKER_RELATION_BASELINE - relation))
	return faction_ids[Factions.weighted_pick_index(weight_list)]


# One attempt record per eligible player vein -- every player vein is a
# candidate every tick (no coarse initiation pre-filter, unlike Chunk 6's
# rivalry attempts); raid_success_chance()/roll_raid_odds() below are what
# actually decide whether anything happens. A vein whose site has since
# vanished is skipped (defensive only -- sites don't currently get deleted
# mid-tick before this step runs, but the check costs nothing). A null
# siteId is also skipped, not just excluded by the site lookup above it --
# ticket 09 stops any *new* floating vein from being created, but ticket
# 11's own text leaves pre-existing ones (older saves, or any vein made
# before ticket 09 landed) unmigrated and explicitly out of scope, so one
# can still legitimately be sitting in player.veins with siteId null.
# Reading `Variant` here rather than casting straight to String keeps that
# case a skip, not a crash. Pure -- no Rng beyond the attacker pick's
# fallback weighting, no state mutation.
static func roll_raid_attempts() -> Array:
	var attempts := []
	for vein in GameState.state["player"]["veins"]:
		var site_id: Variant = vein.get("siteId")
		if site_id == null or Sites.find_site(site_id) == null:
			continue
		attempts.append({
			"attackerId": _attacking_faction(vein),
			"veinId": vein["id"],
			"siteId": site_id,
		})
	return attempts


# Pure computation, mirroring Factions.rivalry_success_chance()'s shape: a
# low baseline pushed by four signed tilts, clamped to [0, 1].
# - relation (attacker's player-facing relation, state.factions[id]
#   .relation): lower -> higher chance.
# - dangerMod (the vein's district): higher -> higher chance.
# - raidResist (the vein's own security tier): higher -> lower chance.
# - growth (normalised against the vein's own ceiling): higher -> higher
#   chance -- the vein-growth-state ticket 03 §3 "wild attracts raids" tilt.
static func raid_success_chance(attacker_id: String, vein: Dictionary) -> float:
	var relation: int = GameState.state["factions"][attacker_id]["relation"]
	var relation_tilt: float = -(float(relation) / RAID_RELATION_DIVISOR) * RAID_RELATION_WEIGHT

	var district: Dictionary = GameData.DISTRICTS.get(vein["district"], {})
	var danger_mod: float = district.get("dangerMod", 0.0)
	var danger_tilt: float = danger_mod * RAID_DANGER_WEIGHT

	var raid_resist: int = GameData.VEIN_SECURITY[vein["security"]]["raidResist"]
	var resist_tilt: float = -(float(raid_resist) / RAID_RAID_RESIST_DIVISOR) * RAID_RAID_RESIST_WEIGHT

	var growth_tilt: float = RAID_GROWTH_WEIGHT * (float(vein["growth"]) / Cultivating.ceiling(vein))

	var chance: float = RAID_BASE_CHANCE + relation_tilt + danger_tilt + resist_tilt + growth_tilt
	return clampf(chance, 0.0, 1.0)


# ── claim-vs-loot split (ticket 70) ─────────────────────────────────────
# A successful raid against a player vein used to be an automatic takeover.
# Now it rolls between the same two outcomes Direction A's own raiding
# already distinguishes: loot (prune + ore theft, vein stays player-owned)
# as the common case, claim (full takeover) as the rarer one -- scaling up
# with the vein's own terroir tier, so losing a rich/saturated vein outright
# is a real but occasional risk rather than the default result of any
# successful raid. Draft values only (PRD's explicit open call), needs
# balance sign-off -- linear interpolation between the PRD's poor (5%) and
# saturated (75%) endpoints across the 4 terroir tiers.
const CLAIM_CHANCE_BY_TERROIR := {
	"poor": 0.05,
	"fair": 0.28,
	"rich": 0.52,
	"saturated": 0.75,
}


static func claim_chance(vein: Dictionary) -> float:
	var tier: String = vein.get("hospitability", {}).get("tier", "fair")
	return CLAIM_CHANCE_BY_TERROIR.get(tier, CLAIM_CHANCE_BY_TERROIR["fair"])


# Draft only (needs balance sign-off), in the same spirit as Direction A's
# own LOOT_ORE_QTY (8) and pruneLightDepth (9, data/vein_growth.json) -- a
# loss to loot never bites harder than the player's own worst prune or
# Direction A's own loot payoff.
const RAID_LOOT_ORE_QTY := 8
const RAID_LOOT_PRUNE_DEPTH := 9


# Rolls the chance above and returns the attempt record annotated with its
# resolved "success" outcome, plus (only when successful) an "outcomeType"
# ("claim"/"loot") rolled against claim_chance(). Still pure computation --
# mutation and the Notify push are resolve_raid_outcome()'s job, not this
# function's. If the target vein has already vanished since the attempt
# was recorded, this reads as chance 0 rather than indexing into a null
# vein, same defensive shape Factions.rivalry_success_chance() uses for its
# own vanished-target case.
static func roll_raid_odds(attempt: Dictionary) -> Dictionary:
	var outcome: Dictionary = attempt.duplicate()
	var vein: Variant = Cultivating.find_vein(attempt["veinId"])
	if vein == null:
		outcome["success"] = false
		return outcome
	outcome["success"] = Rng.chance(raid_success_chance(attempt["attackerId"], vein))
	if outcome["success"]:
		outcome["outcomeType"] = "claim" if Rng.chance(claim_chance(vein)) else "loot"
	return outcome


# Applies one already-rolled outcome. A failed attempt is a documented
# no-op -- no ownership change, no notification. A successful attempt:
#   - removes the vein from player.veins and reassigns it (oreType/growth/
#     security carried over unchanged, matching Chunk 6's resolve_rivalry_
#     outcome() and Direction A's claim_vein()) into the site's factionVein,
#     flipping the site back to faction-owned -- the exact mirror image of
#     Sites.attempt_seed()'s claimed=true/factionVein=null transition, and
#     what lets a vein taken this way later be raided back via Direction A
#     (begin_raid() requires vein["siteId"]).
#   - pushes a Notify, unlike Chunk 6's silent rivalry resolution -- per
#     the PRD, background world-state changes to the player's own stuff
#     are surfaced, the same convention Sites.roll_npc_claims()/
#     roll_npc_abandonment() already use for other background changes.
#   - queues a map-animations-ticket-02-shaped "seed_claim" event (map-
#     visibility-for-direction-b-vein-losses T08), referencing the vein's
#     district/id and the attacker as owner -- same reuse Direction A's
#     claim_vein() and Chunk 6's resolve_rivalry_outcome() already
#     established, and the single choke point both Direction B loss paths
#     (this ticket's off-screen default and ticket 07's lost defend-
#     encounter, via resolve_defend_outcome() below) share, so one call
#     here covers both.
# Re-checks the vein's live presence in player.veins (rather than trusting
# the attempt batch's stale snapshot) before touching anything, so a vein
# that's vanished between the roll and the resolve (e.g. levelled down to
# nothing elsewhere this same tick) is silently skipped, not crashed on.
#
# `missed_defend` (ticket 43): set only by _expire_pending_defend_raids()
# below, for the one caller whose copy needs to say "you had a window and
# missed it" rather than the plain no-alarm loss text.
#
# `outcome["outcomeType"]` (ticket 70): "claim" (default, when the key is
# absent -- keeps every outcome dict hand-built without it, elsewhere in
# this file's own tests included, behaving exactly as the pre-ticket-70
# always-a-takeover path did) or "loot", rolled by roll_raid_odds() above.
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
		_apply_raid_loot(vein, faction_name, district_name, missed_defend)
		return

	var faction_vein: Dictionary = GameState.deep_copy(vein)
	faction_vein["factionId"] = outcome["attackerId"]
	site["factionVein"] = faction_vein
	site["claimed"] = false

	var player: Dictionary = GameState.state["player"]
	var vein_id: String = outcome["veinId"]
	player["veins"] = player["veins"].filter(func(v): return v["id"] != vein_id)

	MapEvents.queue_seed_claim(vein["district"], vein_id, outcome["attackerId"])

	# PROSE-REVIEW: missed_defend branch is new copy (ticket 43), drafted
	# against CONTENT-GUIDE.md's tone bible.
	if missed_defend:
		Notify.push("Too late — %s took your vein in %s while the alarm was still ringing." % [faction_name, district_name], Notify.CATEGORY_DANGER)
	else:
		Notify.push("%s raided your vein in %s. It's theirs now." % [faction_name, district_name], Notify.CATEGORY_DANGER)


# Direction B loot outcome (ticket 70): the common-case result of a
# successful raid -- the vein stays player-owned, just pruned
# (RAID_LOOT_PRUNE_DEPTH) and short a flat quantity of the player's own
# stash of its ore type (RAID_LOOT_ORE_QTY), clamped to what's actually on
# hand -- unlike Direction A's loot_vein() (which materialises ore into the
# player's stash from a faction that never tracked real stock), this steals
# from a real one, so it can never go negative. No relation hit (resolve_
# raid_outcome's claim branch above never applied one either -- this is a
# faction acting against the player, not the reverse) and no map event (the
# vein never changes hands, so there's nothing for the map to register).
#
# PROSE-REVIEW: new notification copy (ticket 70), drafted against
# CONTENT-GUIDE.md's tone bible -- one dry line, concrete ore count, and
# distinct from both the claim branch's "It's theirs now." and the missed-
# defend claim copy so the player can always tell which of the four
# claim/loot × on-time/missed combinations just happened.
static func _apply_raid_loot(vein: Dictionary, faction_name: String, district_name: String, missed_defend: bool) -> void:
	vein["growth"] = maxi(0, vein["growth"] - RAID_LOOT_PRUNE_DEPTH)

	var ore_type: String = vein["oreType"]
	var ore: Dictionary = GameState.state["player"]["orichalchum"]
	var stolen: int = mini(RAID_LOOT_ORE_QTY, ore.get(ore_type, 0))
	ore[ore_type] = ore.get(ore_type, 0) - stolen

	if missed_defend:
		Notify.push("Too late — %s pruned your vein in %s and got away with %d units of ore while the alarm was still ringing. It's still yours." % [faction_name, district_name, stolen], Notify.CATEGORY_DANGER)
	else:
		Notify.push("%s raided your vein in %s, pruning it and getting away with %d units of ore. It's still yours." % [faction_name, district_name, stolen], Notify.CATEGORY_DANGER)


# Called from time_system.gd's daily_tick, step 5i. Runs the previous tick's
# still-pending alarm-defend raids first (ticket 07 -- a player who never
# travelled to defend one loses it exactly as the no-alarm path would), then
# rolls this tick's fresh attempts: a success against an alarmed vein queues
# for the player to go defend instead of resolving here; every other success
# resolves immediately, unchanged from ticket 06.
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


# ── Direction B: alarm defend encounter (ticket 07) ─────────────────────
# Layers the alarm upgrade (ticket 05) onto the raid trigger above as the one
# case with player agency. A successful attempt against an alarmed vein
# doesn't resolve here -- it queues in state.world.pendingDefendRaids and
# alerts the player, giving them the rest of the current day (until the next
# daily_tick, the same "no separate countdown system" the PRD calls for) to
# travel to the vein's district and fight it out. maybe_trigger_defend()
# below is the arrival-side hook (called from Travel.travel_to()/
# Sites.prospect(), the same two chokepoints DistrictDeck.maybe_trigger()
# already uses for "player just arrived in this district" side effects);
# _expire_pending_defend_raids() is the fallthrough side, resolving anything
# still unclaimed at the top of the next tick via the exact same
# resolve_raid_outcome() ticket 06 already uses, so a missed window plays out
# identically to the no-alarm path.
static func _queue_defend_raid(outcome: Dictionary, vein: Dictionary) -> void:
	GameState.state["world"]["pendingDefendRaids"].append(outcome)
	var district_name: String = GameData.DISTRICTS[vein["district"]]["name"]
	var faction_name: String = GameData.FACTIONS[outcome["attackerId"]]["shortName"]
	# PROSE-REVIEW: new notification copy, drafted against CONTENT-GUIDE.md's
	# tone bible (dry, administrative, one line).
	Notify.push("Alarm's gone off — %s are closing in on your vein in %s. Get there today to defend it." % [faction_name, district_name], Notify.CATEGORY_WARNING)


# Passes missed_defend=true -- see resolve_raid_outcome() above (ticket 43).
static func _expire_pending_defend_raids() -> void:
	var world: Dictionary = GameState.state["world"]
	var pending: Array = world["pendingDefendRaids"]
	world["pendingDefendRaids"] = []
	for outcome in pending:
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
			Combat.start_defend_vein(outcome["veinId"], Cultivating.value_tier(vein))
			return true
	return false


# Called by Combat.exit_combat()'s "defend_vein" branch. A win leaves the
# vein untouched -- ownership was never moved, so there's nothing to do, and
# the PRD explicitly wants no separate win notification. A loss reuses
# resolve_raid_outcome() so the transfer and its Notify text are identical to
# every other whole-vein-loss path in this file.
static func resolve_defend_outcome(won: bool) -> void:
	var outcome: Variant = GameState.state["world"]["activeDefendRaid"]
	GameState.state["world"]["activeDefendRaid"] = null
	if won or outcome == null:
		return
	resolve_raid_outcome(outcome)
