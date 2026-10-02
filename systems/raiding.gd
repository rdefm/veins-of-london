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
# basePrice * combined_magnitude tops out ~560-680 for a maxed level-1 vein; dividing by 562.5
# keeps the tilt within roughly [-1.2, 0] before the weight scales it further (a leveled-up
# vein's combined magnitude, R§3.4, can push past that ceiling).
const STEALTH_VALUE_DIVISOR := 562.5
const STEALTH_VALUE_WEIGHT := 0.15


static func stealth_success_chance(stealth_skill: int, vein: Dictionary, consumable_bonus: float) -> float:
	var skill_tilt: float = (stealth_skill - 1) * STEALTH_SKILL_WEIGHT

	var raid_resist: int = Cultivating.vein_raid_resist(vein)
	var resist_tilt: float = -(float(raid_resist) / STEALTH_RAID_RESIST_DIVISOR) * STEALTH_RAID_RESIST_WEIGHT

	var value: float = GameData.ORE_TYPES[vein["oreType"]]["basePrice"] * Cultivating.combined_magnitude(vein)
	var value_tilt: float = -(value / STEALTH_VALUE_DIVISOR) * STEALTH_VALUE_WEIGHT

	var intel_bonus: float = NetworkHandler.claim_bonus(vein.get("siteId", ""))
	var chance: float = STEALTH_BASE_CHANCE + skill_tilt + resist_tilt + value_tilt + consumable_bonus + intel_bonus
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
	if vein.has("factionId"):
		Intel.gain(Shares.PLAYER, vein["factionId"], Intel.SOURCE_SCOUT)
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
	player_vein.erase("kit")
	player_vein["guardKit"] = {}
	GameState.state["player"]["veins"].append(player_vein)

	site["claimed"] = true
	site["factionVein"] = null
	BusinessQuest.maybe_trigger_proposition()
	Intel.gain(Shares.PLAYER, faction_id, Intel.SOURCE_RAID)
	FactionAI.note_hostile_act(Shares.PLAYER, faction_id)
	FactionAI.note_loss(faction_id, Shares.PLAYER, Factions.lost_vein_value(faction_vein))

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
	Intel.gain(Shares.PLAYER, vein["factionId"], Intel.SOURCE_RAID)

	if caught:
		Factions.adjust_player_relation(vein["factionId"], LOOT_RELATION_HIT)
		FactionAI.note_hostile_act(Shares.PLAYER, vein["factionId"])
		FactionAI.note_loss(vein["factionId"], Shares.PLAYER, float(Market.line_total("ore", Market.quote("ore", vein["oreType"]), LOOT_ORE_QTY)))

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
	if Collective.is_quest_locked_vein(vein["id"]):
		# PROSE-REVIEW: new refusal line.
		return { "ok": false, "reason": "Not this one. Not yet." }
	var travel := Travel.ensure_district(vein["district"], 1)
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()
	Events.start_event(RAID_EVENT_ID, { "site_id": vein["siteId"], "ally_ids": ally_ids })
	return { "ok": true }


# ── stockpile raids (R§3.12 "Stockpile raids") ──────────────────────────
# The player raids a faction's stockpile once their intel on it reaches the
# stockpile-location level. Same event flow as a vein raid: a stealth check
# against the stockpile guards, a fight with them (carrying the faction's
# defend kit) when caught, then a loot card. With stash-level intel the
# loot card also offers taking everything.

const STOCKPILE_RAID_EVENT_ID := "stockpile_raid"
const STOCKPILE_RAID_STASH_EVENT_ID := "stockpile_raid_stash"


static func _stockpile_cfg() -> Dictionary:
	return GameData.STOCKPILE_RAID


static func stockpile_district(faction_id: String) -> String:
	return str(GameState.state["factions"][faction_id]["stockpile"].get("district", ""))


# The player knows where faction_id keeps its stockpile, and it has a district.
static func can_raid_stockpile(faction_id: String) -> bool:
	return Intel.knows(Shares.PLAYER, faction_id, Intel.STOCKPILE_LOCATION) and stockpile_district(faction_id) != ""


# Travel/time-block gating as begin_raid(), then the stockpile raid event,
# its stash variant when the player has stash-level intel.
static func begin_stockpile_raid(faction_id: String, ally_ids: Array = []) -> Dictionary:
	if not can_raid_stockpile(faction_id):
		# PROSE-REVIEW: new refusal line.
		return { "ok": false, "reason": "You don't know where they keep it." }
	var travel := Travel.ensure_district(stockpile_district(faction_id), 1)
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()
	var event_id := STOCKPILE_RAID_STASH_EVENT_ID if Intel.knows(Shares.PLAYER, faction_id, Intel.STASH) else STOCKPILE_RAID_EVENT_ID
	Events.start_event(event_id, { "faction_id": faction_id, "ally_ids": ally_ids })
	return { "ok": true }


# Stockpile guards × raidResistPerGuard, on the vein raidResist scale.
static func stockpile_raid_resist(faction_id: String) -> int:
	return FactionSim.stockpile_guards(faction_id) * int(_stockpile_cfg()["raidResistPerGuard"])


# stealth_success_chance() without the vein terms: skill tilt, consumable
# bonus and the stockpile guards' raid resist.
static func stockpile_stealth_chance(stealth_skill: int, faction_id: String, consumable_bonus: float) -> float:
	var skill_tilt: float = (stealth_skill - 1) * STEALTH_SKILL_WEIGHT
	var resist_tilt: float = -(float(stockpile_raid_resist(faction_id)) / STEALTH_RAID_RESIST_DIVISOR) * STEALTH_RAID_RESIST_WEIGHT
	return clampf(STEALTH_BASE_CHANCE + skill_tilt + resist_tilt + consumable_bonus, 0.0, 1.0)


# resolve_stealth_check() for a stockpile.
static func resolve_stockpile_stealth_check(faction_id: String, consumable_bonus: float) -> bool:
	var skill: int = GameState.state["player"]["stealthSkill"]
	var success: bool = Rng.chance(stockpile_stealth_chance(skill, faction_id, consumable_bonus))
	award_stealth_xp(STEALTH_XP_SUCCESS if success else STEALTH_XP_CAUGHT)
	Intel.gain(Shares.PLAYER, faction_id, Intel.SOURCE_SCOUT)
	return success


# The share of each holdings line a successful raid takes: stashLootShare
# when taking everything with stash-level intel, else lootShare.
static func stockpile_loot_share(faction_id: String, take_all: bool) -> float:
	if take_all and Intel.knows(Shares.PLAYER, faction_id, Intel.STASH):
		return float(_stockpile_cfg()["stashLootShare"])
	return float(_stockpile_cfg()["lootShare"])


# A successful stockpile raid: floor(share × held) of every ore and item
# line moves from faction_id's holdings to the player (items highest tier
# first, keeping their tiers), then the raid's consequences land. Returns
# what was taken, { ore: { oreType: qty }, items: { recipeKey: qty } }.
#
# PROSE-REVIEW: the loot notification.
static func loot_stockpile(faction_id: String, take_all: bool) -> Dictionary:
	var taken := _take_stockpile_share(faction_id, stockpile_loot_share(faction_id, take_all))
	var stolen := { "ore": taken["ore"], "items": {} }
	var player_ore: Dictionary = GameState.state["player"]["orichalchum"]
	var ore_total := 0
	for ore_type in taken["ore"].keys():
		player_ore[ore_type] = int(player_ore.get(ore_type, 0)) + int(taken["ore"][ore_type])
		ore_total += int(taken["ore"][ore_type])
	var item_total := 0
	for recipe_key in taken["items"].keys():
		var qty := 0
		for leg in taken["items"][recipe_key]:
			Crafting.inventory_add(recipe_key, int(leg["tier"]), int(leg["qty"]))
			qty += int(leg["qty"])
		stolen["items"][recipe_key] = qty
		item_total += qty
	Notify.push("Stockpile emptied into your bag: %d calc, %d items." % [ore_total, item_total], Notify.CATEGORY_SUCCESS)
	_stockpile_raid_consequences(faction_id, float(taken["value"]))
	return stolen


# Removes floor(share × held) of every ore and item line from faction_id's
# holdings. Returns { ore: { oreType: qty }, items: { recipeKey: [ { tier,
# qty } ] } (highest tier first), value: London value of it all }.
static func _take_stockpile_share(faction_id: String, share: float) -> Dictionary:
	var holdings: Dictionary = GameState.state["factions"][faction_id]["holdings"]
	var taken := { "ore": {}, "items": {}, "value": 0.0 }
	for ore_type in holdings["ore"].keys():
		var qty := floori(float(FactionSim.ore_held(faction_id, ore_type)) * share)
		if qty <= 0:
			continue
		FactionSim.take_ore(faction_id, ore_type, qty)
		taken["ore"][ore_type] = qty
		taken["value"] += _stock_value("ore", ore_type, qty)
	for recipe_key in holdings["items"].keys():
		var qty := floori(float(FactionSim.item_held(faction_id, recipe_key)) * share)
		if qty <= 0:
			continue
		taken["items"][recipe_key] = FactionSim.take_items(faction_id, recipe_key, qty)
		taken["value"] += _stock_value("consumable", recipe_key, qty)
	return taken


# London value of floor(share × held) of faction_id's holdings, as
# _take_stockpile_share() would take it.
static func stockpile_value(faction_id: String, share: float) -> float:
	var holdings: Dictionary = GameState.state["factions"][faction_id]["holdings"]
	var value := 0.0
	for ore_type in holdings["ore"].keys():
		var qty := floori(float(FactionSim.ore_held(faction_id, ore_type)) * share)
		if qty > 0:
			value += _stock_value("ore", ore_type, qty)
	for recipe_key in holdings["items"].keys():
		var qty := floori(float(FactionSim.item_held(faction_id, recipe_key)) * share)
		if qty > 0:
			value += _stock_value("consumable", recipe_key, qty)
	return value


# London value of qty of a good: today's quote for a traded good, else its
# base price.
static func _stock_value(kind: String, good_type: String, qty: int) -> float:
	var traded: bool = GameData.MARKET["goods"][kind].has(good_type)
	var price := Market.quote(kind, good_type) if traded else Market.base_price(kind, good_type)
	return float(Market.line_total(kind, price, qty))


# Settles a stockpile raid's fight (Combat.exit_combat()): the faction is
# billed the defend-kit items its guards used; a lost fight is the player's
# failed raid, which still brings the raid's consequences.
static func resolve_stockpile_fight(faction_id: String, won: bool, guard_items_used: Dictionary = {}) -> void:
	FactionSim.log_kit_burn_items(faction_id, "defend", "stockpileRaid", guard_items_used)
	if won:
		FactionAI.note_fight_lost(faction_id, Shares.PLAYER)
		return
	FactionAI.note_fight_lost(Shares.PLAYER, faction_id)
	_stockpile_raid_consequences(faction_id, 0.0)


# Any stockpile raid, won or lost: raid intel, a hostile act (war clock),
# the faction's loss, the large relation hit, then the stockpile relocates,
# dropping every observer below the stockpile-location level.
static func _stockpile_raid_consequences(faction_id: String, value_lost: float) -> void:
	Intel.gain(Shares.PLAYER, faction_id, Intel.SOURCE_RAID)
	FactionAI.note_hostile_act(Shares.PLAYER, faction_id)
	FactionAI.note_loss(faction_id, Shares.PLAYER, value_lost)
	Factions.adjust_player_relation(faction_id, int(_stockpile_cfg()["relationHit"]))
	Intel.relocate_stockpile(faction_id)


# ── faction stockpile raids (R§3.12 "Faction stockpile raids") ──────────
# FactionAI's stockpileRaid move between factions, queued at ⑥.5h and
# resolved at the next ⑤c (Factions.apply_rivalry_resolution) with the
# player raid's loot and consequences: no player stockpile exists, so the
# player is never the defender.

# attacker_id knows where defender_id keeps its stockpile, and it has a district.
static func faction_can_raid_stockpile(attacker_id: String, defender_id: String) -> bool:
	return Intel.knows(attacker_id, defender_id, Intel.STOCKPILE_LOCATION) and stockpile_district(defender_id) != ""


# stashLootShare when attacker_id has stash-level intel on defender_id,
# else lootShare: a faction always takes everything it can.
static func faction_stockpile_loot_share(attacker_id: String, defender_id: String) -> float:
	var key := "stashLootShare" if Intel.knows(attacker_id, defender_id, Intel.STASH) else "lootShare"
	return float(_stockpile_cfg()[key])


# One queued faction stockpile raid: both kits burn, the rivalry odds roll
# against the stockpile guards' resist, then the guards' repel roll. A
# success moves the loot share of the defender's holdings (items at their
# tiers) to the attacker. Either way the raid is logged on both sides (a
# hostile act), the attacker gains raid intel, the defender books the loss
# and the pair relation hit (pairRelationHit), and the stockpile relocates. A haul worth at least
# headlineValue is a Ticker headline. A no-op unless constants.json
# factionRivalry is on and the attacker still knows the stockpile's location.
# The defender's partners' warning (warned_by) and help cut the odds
# (Partners.faction_defence_cut).
static func resolve_faction_stockpile_raid(attacker_id: String, defender_id: String, warned_by: String = "") -> void:
	if not GameData.FACTION_RIVALRY or not faction_can_raid_stockpile(attacker_id, defender_id):
		return
	var cfg := _stockpile_cfg()
	var district_id := stockpile_district(defender_id)
	FactionSim.log_kit_burn(attacker_id, "attack", "stockpileRaid")
	FactionSim.log_kit_burn(defender_id, "defend", "stockpileRaid")
	var odds: float = Factions.stockpile_rivalry_chance(attacker_id, defender_id) - Partners.faction_defence_cut(attacker_id, defender_id, warned_by)
	var success := Rng.chance(clampf(odds, 0.0, 1.0))
	var guards := FactionSim.stockpile_guards(defender_id)
	if success and guards > 0 and Rng.chance(guard_repel_chance(guards)):
		success = false
	var value := 0.0
	if success:
		var taken := _take_stockpile_share(defender_id, faction_stockpile_loot_share(attacker_id, defender_id))
		for ore_type in taken["ore"].keys():
			FactionSim.add_ore(attacker_id, ore_type, int(taken["ore"][ore_type]))
		for recipe_key in taken["items"].keys():
			for leg in taken["items"][recipe_key]:
				FactionSim.add_item(attacker_id, recipe_key, int(leg["tier"]), int(leg["qty"]))
		value = float(taken["value"])
	else:
		FactionAI.note_fight_lost(attacker_id, defender_id)
	FactionAI.report_pair_move(attacker_id, defender_id, FactionAI.MOVE_STOCKPILE_RAID, district_id, success)
	Intel.gain(attacker_id, defender_id, Intel.SOURCE_RAID)
	FactionAI.note_loss(defender_id, attacker_id, value)
	Factions.adjust_relation(defender_id, attacker_id, int(cfg["pairRelationHit"]))
	Intel.relocate_stockpile(defender_id)
	if value >= float(cfg["headlineValue"]):
		Barometer.push_headline(GameData.FACTION_ESCALATION["headlines"]["stockpileRaid"] % [
			GameData.FACTIONS[attacker_id]["shortName"],
			GameData.FACTIONS[defender_id]["shortName"],
			GameData.DISTRICTS[district_id]["name"],
		])


# ── Direction B: daily-tick raid trigger ─────────────────────────────────
# A faction raids one of the player's own veins (mirror of Direction A
# above); called from TimeSystem.daily_tick() with the same
# attempts/odds/resolve split as Factions' rivalry code (R§3.12).


# Low baseline success chance for one queued raid.
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


# ── conquer eligibility threshold ────────────────────────────────────────
# Data-driven per faction (conquerThreshold, R§1.8); a faction may claim
# only when its player relation is strictly below it.
static func _faction_conquer_threshold(faction_id: String) -> int:
	var faction: Dictionary = GameData.FACTIONS[faction_id]
	return faction.get("conquerThreshold", faction["raidThreshold"])


static func _faction_may_conquer(faction_id: String) -> bool:
	var relation: int = GameState.state["factions"][faction_id]["relation"]
	return relation < _faction_conquer_threshold(faction_id)


# Yesterday's queued raids against the player (FactionAI's raid rung,
# R§3.1 "Escalation"), as { attackerId, veinId, siteId, move } (move:
# veinRaid or shortfallSteal). Drains the queue; a vein that's gone, lost
# its site, or is quest-locked is dropped.
static func queued_raid_attempts() -> Array:
	var attempts := []
	for entry in FactionAI.take_queued_raids(true):
		var vein: Variant = Cultivating.find_vein(entry["veinId"])
		if vein == null or vein.get("siteId") == null or Sites.find_site(vein["siteId"]) == null or Collective.is_quest_locked_vein(vein["id"]):
			continue
		attempts.append({
			"attackerId": entry["attackerId"],
			"veinId": vein["id"],
			"siteId": vein["siteId"],
			"move": entry.get("move", FactionAI.MOVE_VEIN_RAID),
		})
	return attempts


# Mirrors Factions.rivalry_success_chance(): low baseline tilted by relation
# (lower=higher chance), dangerMod, raidResist (R§1.6 anchor, inverted), growth,
# and the attacker's intel on the player (Intel.raid_odds_shift).
static func raid_success_chance(attacker_id: String, vein: Dictionary) -> float:
	var relation: int = GameState.state["factions"][attacker_id]["relation"]
	var relation_tilt: float = -(float(relation) / RAID_RELATION_DIVISOR) * RAID_RELATION_WEIGHT

	var district: Dictionary = GameData.DISTRICTS.get(vein["district"], {})
	var danger_mod: float = district.get("dangerMod", 0.0)
	var danger_tilt: float = danger_mod * RAID_DANGER_WEIGHT

	var raid_resist: int = Cultivating.vein_raid_resist(vein)
	var resist_tilt: float = -(float(raid_resist) / RAID_RAID_RESIST_DIVISOR) * RAID_RAID_RESIST_WEIGHT

	var growth_tilt: float = RAID_GROWTH_WEIGHT * (float(vein["growth"]) / Cultivating.ceiling(vein))

	var intel_tilt: float = Intel.raid_odds_shift(attacker_id, Shares.PLAYER)

	var chance: float = RAID_BASE_CHANCE + relation_tilt + danger_tilt + resist_tilt + growth_tilt + intel_tilt
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


# Rolls the chance above and returns the attempt annotated with "success"
# plus (only when successful) "outcomeType" ("claim"/"loot", via
# claim_chance()). Pure computation -- mutation and the Notify push are
# resolve_raid_outcome()'s job. A vanished target vein reads as chance 0
# rather than indexing a null vein (same defensive shape as
# Factions.rivalry_success_chance()). claim_chance() only rolls when the
# attacker's relation clears its own conquerThreshold
# (_faction_may_conquer()); below that a successful raid is capped at
# "loot" regardless of claim_chance()'s odds. A shortfall steal is always
# "loot".
static func roll_raid_odds(attempt: Dictionary) -> Dictionary:
	var outcome: Dictionary = attempt.duplicate()
	var vein: Variant = Cultivating.find_vein(attempt["veinId"])
	if vein == null:
		outcome["success"] = false
		return outcome
	outcome["success"] = Rng.chance(raid_success_chance(attempt["attackerId"], vein))
	if outcome["success"]:
		var may_conquer: bool = _faction_may_conquer(attempt["attackerId"]) and attempt.get("move", FactionAI.MOVE_VEIN_RAID) != FactionAI.MOVE_SHORTFALL_STEAL
		outcome["outcomeType"] = "claim" if (may_conquer and Rng.chance(claim_chance(vein))) else "loot"
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
	Intel.gain(outcome["attackerId"], Shares.PLAYER, Intel.SOURCE_RAID)

	if outcome.get("outcomeType", "claim") == "loot":
		_apply_raid_loot(vein, outcome["attackerId"], faction_name, district_name, missed_defend)
		return

	FactionAI.note_loss(Shares.PLAYER, outcome["attackerId"], Factions.lost_vein_value(vein))
	var took_kit := GuardKit.hand_kit_to_faction(vein, outcome["attackerId"])
	transfer_player_vein_to_faction(vein, site, outcome["attackerId"])

	# PROSE-REVIEW: drafted against CONTENT-GUIDE.md's tone bible.
	var text: String
	if missed_defend:
		text = "Too late — %s took your vein in %s while the alarm was still ringing." % [faction_name, district_name]
	else:
		text = "%s raided your vein in %s. It's theirs now." % [faction_name, district_name]
	if took_kit:
		text += " They took the guard kit."
	Notify.push(text, Notify.CATEGORY_DANGER)


# The claim branch's ownership bookkeeping: the player vein moves onto its
# site as faction_id's faction vein, wholesale. Shared with Collective.
# force_vein_loss() (spec §5.4), which moves a vein the same way unrolled.
static func transfer_player_vein_to_faction(vein: Dictionary, site: Dictionary, faction_id: String) -> void:
	var faction_vein: Dictionary = GameState.deep_copy(vein)
	faction_vein.erase("guardKit")
	faction_vein["factionId"] = faction_id
	site["factionVein"] = faction_vein
	site["claimed"] = false

	var player: Dictionary = GameState.state["player"]
	var vein_id: String = vein["id"]
	player["veins"] = player["veins"].filter(func(v): return v["id"] != vein_id)
	Sites.release_vein_slot(vein)
	FactionAI.note_player_vein_lost()
	# Act 2 T8a (spec §6.8a): a no-op unless vein_id is the one col_a2_nadia_
	# defend was watching, in which case it re-targets rather than dead-ending.
	Collective.maybe_retarget_nadia_defend_vein(vein_id)

	MapEvents.queue_seed_claim(vein["district"], vein_id, faction_id)


# Direction B loot outcome: the common-case result of a successful raid --
# the vein stays player-owned but the raiders hard-harvest it
# (FactionSim.raid_harvest), the whole yield going to their holdings. No
# relation hit (a faction acting against the player, not the reverse) and
# no map event (the vein never changes hands). PROSE-REVIEW: one dry line
# with a concrete ore count, distinct from the claim branch's "It's theirs
# now." and the missed-defend claim copy, so the player can tell which of
# the four claim/loot x on-time/missed combinations happened.
static func _apply_raid_loot(vein: Dictionary, faction_id: String, faction_name: String, district_name: String, missed_defend: bool) -> void:
	var ore_type: String = vein["oreType"]
	var stolen := FactionSim.raid_harvest(faction_id, vein)
	FactionAI.note_loss(Shares.PLAYER, faction_id, float(Market.line_total("ore", Market.quote("ore", ore_type), stolen)))

	if missed_defend:
		Notify.push("Too late — %s stripped your vein in %s and got away with %d units of ore while the alarm was still ringing. It's still yours." % [faction_name, district_name, stolen], Notify.CATEGORY_DANGER)
	else:
		Notify.push("%s raided your vein in %s, stripping it and getting away with %d units of ore. It's still yours." % [faction_name, district_name, stolen], Notify.CATEGORY_DANGER)


# Called from time_system.gd's daily_tick, step ⑤d. Runs the previous
# tick's still-pending alarm-defend raids first (a player who never
# travelled to defend one loses it exactly as the no-alarm path would),
# then rolls yesterday's queued raids: a success against an alarmed vein
# queues for the player to defend; every other success resolves now. Each
# attempt is reported as a move against the player (FactionAI.
# report_player_move). Every attempt that resolves without a played fight
# burns the attacker's attack kit (spec §Consumption); a queued one burns
# only if it later expires or is left undefended.
static func apply_raid_resolution() -> void:
	_expire_pending_defend_raids()

	for attempt in queued_raid_attempts():
		var outcome := roll_raid_odds(attempt)
		var district_id: String = Cultivating.find_vein(attempt["veinId"])["district"]
		FactionAI.report_player_move(attempt["attackerId"], attempt["move"], district_id, outcome["success"])
		if not outcome["success"]:
			FactionAI.note_fight_lost(outcome["attackerId"], Shares.PLAYER)
			FactionSim.log_kit_burn(outcome["attackerId"], "attack", "raid")
			continue
		var vein: Variant = Cultivating.find_vein(outcome["veinId"])
		if vein != null and vein["alarmUpgrades"].has(Cultivating.ALARM_UPGRADE_ID):
			_queue_defend_raid(outcome, vein)
		else:
			FactionSim.log_kit_burn(outcome["attackerId"], "attack", "raid")
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
	var warning_text := "Alarm's gone off — %s are closing in on your vein in %s. Get there today to defend it." % [faction_name, district_name]
	# veinId meta lets phone.gd's Notifications app render a Defend button
	# on this entry. The notification's id is stashed back onto the queued
	# outcome so is_defend_notification_pending() below can scope the
	# button to this raid occurrence -- matching on veinId alone would
	# resurrect the button on an already-resolved warning once the vein is
	# raided again (Notify.LOG_CAP caps the log rather than clearing it).
	var notification := Notify.push(warning_text, Notify.CATEGORY_WARNING, { "veinId": vein["id"] })
	outcome["notificationId"] = notification["id"]


# A questline's scripted raid (Collective.maybe_queue_a2_nadia_defend_raid()):
# a guaranteed-success attempt queued straight into the defend window,
# skipping the odds roll and the Alarm-upgrade gate. From here it rides the
# ordinary pending-defend expiry, guard repel and Defend buttons.
static func queue_scripted_defend_raid(attacker_id: String, vein: Dictionary, outcome_type: String) -> void:
	_queue_defend_raid({
		"attackerId": attacker_id,
		"veinId": vein["id"],
		"siteId": vein["siteId"],
		"move": FactionAI.MOVE_VEIN_RAID,
		"success": true,
		"outcomeType": outcome_type,
	}, vein)


# Before a missed-defend window falls through to resolve_raid_outcome()'s
# auto-loss, a vein with 1+ guards (tier guard + extras, Cultivating.
# vein_guard_count) gets a chance to repel the raid
# outright. Chance-per-guard and cap live in data/constants.json's
# "guardRepel" (GameData.GUARD_REPEL_CHANCE_PER_GUARD/_CAP), shared with
# Home's own guard_repel_chance() mirror so retuning never touches a .gd
# file. Zero guards skips the roll entirely -- no chance consumed.
static func guard_repel_chance(guard_count: int) -> float:
	return clampf(guard_count * GameData.GUARD_REPEL_CHANCE_PER_GUARD, 0.0, GameData.GUARD_REPEL_CHANCE_CAP)


# One repel roll for any vein, player or faction (spec §Faction guard upkeep
# → faction vein guard repel): counts tier guard + extras, and skips the Rng
# entirely at zero guards.
static func guards_repel(vein: Dictionary) -> bool:
	var guard_count: int = Cultivating.vein_guard_count(vein)
	if guard_count <= 0:
		return false
	return Rng.chance(guard_repel_chance(guard_count))


# Rolls the repel chance for one expiring outcome and, on success, pushes
# a "held without you" notification and returns true so the caller skips
# resolve_raid_outcome() entirely -- no ownership change, no ore lost. A
# vanished vein returns false, so resolve_raid_outcome()'s null-vein no-op
# still covers that case. PROSE-REVIEW:
# distinct from both the silent "you defended it yourself" win path and
# every missed-defend loss line above, so the player can tell "guards
# held it" apart from either. Active guard kit raises the chance and loses
# one unit per active type on the roll (guard-kit spec §Not defending).
static func _guards_repel_defend_raid(outcome: Dictionary) -> bool:
	var vein: Variant = Cultivating.find_vein(outcome["veinId"])
	if vein == null:
		return false

	var guard_count: int = Cultivating.vein_guard_count(vein)
	if guard_count <= 0:
		return false
	var active := GuardKit.active_units(vein)
	var chance := GuardKit.repel_chance_with(guard_repel_chance(guard_count), active)
	var used := GuardKit.spend_repel_units(vein.get("guardKit", {}), active)
	if not Rng.chance(chance):
		return false
	FactionAI.note_fight_lost(outcome["attackerId"], Shares.PLAYER)

	var district_name: String = GameData.DISTRICTS[vein["district"]]["name"]
	var faction_name: String = GameData.FACTIONS[outcome["attackerId"]]["shortName"]
	var text := "Your guards saw %s off your vein in %s before you got there. Nothing lost." % [faction_name, district_name]
	if not used.is_empty():
		text += " They went through %s." % GuardKit.used_items_text(used)
	Notify.push(text, Notify.CATEGORY_SUCCESS)
	return true


# Passes missed_defend=true -- see resolve_raid_outcome() above.
static func _expire_pending_defend_raids() -> void:
	var world: Dictionary = GameState.state["world"]
	var pending: Array = world["pendingDefendRaids"]
	world["pendingDefendRaids"] = []
	for outcome in pending:
		FactionSim.log_kit_burn(outcome["attackerId"], "attack", "raid")
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
			_start_defend_combat(outcome, vein)
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
	_start_defend_combat(outcome, vein)
	return true


# The raiders carry the attacker's attack kit, capped by its holdings; what
# they use is billed by resolve_defend_outcome(), in place of the full-kit
# burn every unfought raid logs.
static func _start_defend_combat(outcome: Dictionary, vein: Dictionary) -> void:
	GameState.state["world"]["activeDefendRaid"] = outcome
	Combat.start_defend_vein(vein["id"], Cultivating.combined_magnitude(vein), FactionSim.raider_kit(outcome["attackerId"], "attack"), Partners.defence_helpers(outcome["attackerId"]))


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
		FactionSim.log_kit_burn(outcome["attackerId"], "attack", "raid")
		if not _guards_repel_defend_raid(outcome):
			resolve_raid_outcome(outcome)
		EventBus.state_changed.emit()
		return true
	return false


# Called by Combat.exit_combat()'s "defend_vein" branch. A win leaves the
# vein untouched (ownership was never moved, and the PRD wants no separate
# win notification). A loss reuses resolve_raid_outcome() so the transfer
# and its Notify text match every other whole-vein-loss path in this file.
# Either way the attacker is billed only the kit items its raiders used.
static func resolve_defend_outcome(won: bool, raider_items_used: Dictionary = {}) -> void:
	var outcome: Variant = GameState.state["world"]["activeDefendRaid"]
	GameState.state["world"]["activeDefendRaid"] = null
	if outcome != null:
		FactionSim.log_kit_burn_items(outcome["attackerId"], "attack", "raid", raider_items_used)
	if outcome != null and won:
		FactionAI.note_fight_lost(outcome["attackerId"], Shares.PLAYER)
	elif outcome != null:
		FactionAI.note_fight_lost(Shares.PLAYER, outcome["attackerId"])
	if won and outcome != null:
		Objectives.record_alarm_defend_win(outcome["veinId"])
		Collective.award_a2_defend_win()
	Objectives.refresh()
	Collective.maybe_trigger_a2_checkpoint()
	if won or outcome == null:
		return
	resolve_raid_outcome(outcome)
