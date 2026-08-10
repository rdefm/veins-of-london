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
# and by the vein's value (basePrice * level, the same value metric
# Factions._pick_target_vein()/apply_security_upgrades() already use
# elsewhere) -- a richer, better-defended vein is harder to walk into clean.
const STEALTH_BASE_CHANCE := 0.55
const STEALTH_SKILL_WEIGHT := 0.05
const STEALTH_RAID_RESIST_DIVISOR := 55.0
const STEALTH_RAID_RESIST_WEIGHT := 0.35
# basePrice (~55-90) * level (1-5, LEVEL_CAP) tops out around 450 for a
# maxed-out high-value vein -- dividing by that keeps the tilt within
# roughly [-1, 0] before the weight scales it down, same shape as the
# raidResist normalisation above.
const STEALTH_VALUE_DIVISOR := 450.0
const STEALTH_VALUE_WEIGHT := 0.15


static func stealth_success_chance(stealth_skill: int, vein: Dictionary, consumable_bonus: float) -> float:
	var skill_tilt: float = (stealth_skill - 1) * STEALTH_SKILL_WEIGHT

	var raid_resist: int = GameData.VEIN_SECURITY[vein["security"]]["raidResist"]
	var resist_tilt: float = -(float(raid_resist) / STEALTH_RAID_RESIST_DIVISOR) * STEALTH_RAID_RESIST_WEIGHT

	var value: float = GameData.ORE_TYPES[vein["oreType"]]["basePrice"] * vein["level"]
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
	player["stealthXP"] = player["stealthXP"] + amount
	var max_level: int = GameData.STEALTH_XP_LEVELS.size() - 1
	while player["stealthSkill"] < max_level and player["stealthXP"] >= GameData.STEALTH_XP_LEVELS[player["stealthSkill"] + 1]:
		player["stealthSkill"] += 1
		Notify.push("Stealth skill up — now level %d." % player["stealthSkill"])


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
# every field over unchanged (oreType/level/security explicitly, per the
# ticket, but also devBar/location/hospitability/etc.) -- the same
# "ownership changes hands, nothing about the vein itself resets" convention
# Factions.resolve_rivalry_outcome() already established for faction-to-
# faction transfers, just crossing from faction to player instead. Always a
# severe relation hit, regardless of caught/clean (claiming is visible on the
# map either way). No-op if the site has no factionVein (bad site_id, or
# already transferred elsewhere -- e.g. a same-tick rivalry resolution).
static func claim_vein(site_id: String) -> void:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return

	var faction_vein: Dictionary = site["factionVein"]
	var faction_id: String = faction_vein["factionId"]

	var player_vein: Dictionary = GameState.deep_copy(faction_vein)
	player_vein.erase("factionId")
	GameState.state["player"]["veins"].append(player_vein)

	site["claimed"] = true
	site["factionVein"] = null

	Factions.adjust_player_relation(faction_id, CLAIM_RELATION_HIT)
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
