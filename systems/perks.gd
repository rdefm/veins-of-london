class_name Perks
extends RefCounted

# Faction perk queries (R§3.10 "Perks"), data in faction_perks.json. Tier from
# the player's standing with a faction: sworn = joined, partner = Partner
# stance, friendly = relation at or above friendlyAtOrAbove. Tiers are
# cumulative. Turf-scoped perks apply in districts where the faction has
# Control (scale 1) or Foothold (scale footholdFactor). Effect hooks read these
# queries; nothing here applies an effect. Static funcs only.

const TIER_NONE := "none"


static func _cfg() -> Dictionary:
	return GameData.FACTION_PERKS


static func tier_order() -> Array:
	return _cfg()["tierOrder"]


static func tier_label(tier: String) -> String:
	return _cfg()["tierLabels"].get(tier, tier)


# Player's perk tier with a faction: "none" | "friendly" | "partner" | "sworn".
static func player_tier(faction_id: String) -> String:
	var f: Dictionary = GameState.state["factions"][faction_id]
	if f.get("joined", false):
		return "sworn"
	if FactionAI.player_stance(faction_id) == FactionAI.PARTNER:
		return "partner"
	if int(f["relation"]) >= int(_cfg()["friendlyAtOrAbove"]):
		return "friendly"
	return TIER_NONE


# Tier rank: 0 for none, 1.. along tierOrder.
static func tier_rank(tier: String) -> int:
	return tier_order().find(tier) + 1


# Every perk at every tier for a faction: [{ tier, unlocked, perk }], lowest tier first.
static func preview(faction_id: String) -> Array:
	var rank := tier_rank(player_tier(faction_id))
	var rows := []
	for tier in tier_order():
		for perk in _cfg()["factions"][faction_id].get(tier, []):
			rows.append({ "tier": tier, "unlocked": tier_rank(tier) <= rank, "perk": perk })
	return rows


# What a tier asks of the player, derived from the perk config.
static func requirement_text(tier: String) -> String:
	match tier:
		"friendly":
			return "Relation ≥%d" % int(_cfg()["friendlyAtOrAbove"])
		"partner":
			return "Partner stance"
		"sworn":
			return "Joined"
	return ""


# Benefit rows for a faction: preview rows plus { tier_label, requirement, scope, active,
# districts: [{ district, scale, strength }] }. Global perks are active when unlocked;
# turf perks are active where the faction holds Control ("full") or Foothold ("reduced").
static func benefit_rows(faction_id: String) -> Array:
	var rows := []
	for row in preview(faction_id):
		var scope: String = row["perk"]["scope"]
		var districts := []
		if scope == "turf" and row["unlocked"]:
			for district_id in GameData.DISTRICTS.keys():
				var scale := turf_scale(district_id, faction_id)
				if scale > 0.0:
					districts.append({ "district": district_id, "scale": scale, "strength": _strength(scale) })
		rows.append({
			"tier": row["tier"],
			"tier_label": tier_label(row["tier"]),
			"requirement": requirement_text(row["tier"]),
			"unlocked": row["unlocked"],
			"scope": scope,
			"perk": row["perk"],
			"active": row["unlocked"] if scope == "global" else not districts.is_empty(),
			"districts": districts,
		})
	return rows


# benefit_rows for one district, each with "here": "full" | "reduced" | "inactive".
static func district_benefit_rows(faction_id: String, district_id: String) -> Array:
	var scale := turf_scale(district_id, faction_id)
	var rows := benefit_rows(faction_id)
	for row in rows:
		var here := "inactive"
		if row["unlocked"]:
			here = "full" if row["scope"] == "global" else _strength(scale)
		row["here"] = here
	return rows


static func _strength(scale: float) -> String:
	if scale >= 1.0:
		return "full"
	return "reduced" if scale > 0.0 else "inactive"


# Perks the player has unlocked with a faction, filtered by scope ("" = both).
static func _unlocked(faction_id: String, scope: String) -> Array:
	var perks := []
	for row in preview(faction_id):
		if row["unlocked"] and (scope == "" or row["perk"]["scope"] == scope):
			perks.append(row)
	return perks


# Active global perks: [{ faction, tier, perk }].
static func active_global() -> Array:
	var result := []
	for faction_id in GameData.FACTIONS.keys():
		for row in _unlocked(faction_id, "global"):
			result.append({ "faction": faction_id, "tier": row["tier"], "perk": row["perk"] })
	return result


# Active turf perks for a district: [{ faction, tier, perk, scale }]. Only factions
# holding Control (1.0) or Foothold (footholdFactor) there contribute.
static func active_turf(district_id: String) -> Array:
	var result := []
	for faction_id in GameData.FACTIONS.keys():
		var scale := turf_scale(district_id, faction_id)
		if scale <= 0.0:
			continue
		for row in _unlocked(faction_id, "turf"):
			result.append({ "faction": faction_id, "tier": row["tier"], "perk": row["perk"], "scale": scale })
	return result


# Turf perks for a player site/vein record (its district).
static func active_turf_for_site(site: Dictionary) -> Array:
	return active_turf(String(site.get("district", "")))


static func turf_scale(district_id: String, faction_id: String) -> float:
	match Turf.tier(district_id, faction_id):
		Turf.TIER_CONTROL:
			return 1.0
		Turf.TIER_FOOTHOLD:
			return float(GameData.TURF["footholdFactor"])
	return 0.0


# True if the player has the perk id active (global: unlocked; turf: with district, scale > 0).
static func has_perk(perk_id: String, district_id: String = "") -> bool:
	for entry in active_global():
		if entry["perk"]["id"] == perk_id:
			return true
	if district_id != "":
		for entry in active_turf(district_id):
			if entry["perk"]["id"] == perk_id:
				return true
	return false


# ── effect hooks ──────────────────────────────────────────────────────────

# Summed raidOddsAdj of active turf perks in a district, scaled by Control/Foothold.
static func raid_odds_adj(district_id: String) -> float:
	var total := 0.0
	for entry in active_turf(district_id):
		if entry["perk"]["effect"] == "raidOddsAdj":
			total += float(entry["perk"]["params"]["value"]) * float(entry["scale"])
	return total


# Records that the player tended (cultivated or pruned) a vein today.
static func note_player_tended(vein_id: String) -> void:
	GameState.state["perks"]["tended"][vein_id] = int(GameState.state["world"]["day"])


# ⑤d2b: in each district with a dailyTend perk, up to veinsPerDay of the
# player's veins they did not tend on the day just ended get tended by members
# through FactionSim's tend step (Foothold scale does not shrink the count).
static func daily_tend() -> void:
	var perks_state: Dictionary = GameState.state["perks"]
	var ended_day: int = int(GameState.state["world"]["day"]) - 1
	var skill: int = GameState.state["player"]["cultivatingSkill"]
	var used := {}
	var live := {}
	for vein in GameState.state["player"]["veins"]:
		var vein_id: String = vein["id"]
		var tended_day: int = int(perks_state["tended"].get(vein_id, -1))
		if tended_day >= 0:
			live[vein_id] = tended_day
		if tended_day == ended_day:
			continue
		var district: String = vein["district"]
		if int(used.get(district, 0)) >= _tend_budget(district):
			continue
		FactionSim._tend(vein, skill)
		used[district] = int(used.get(district, 0)) + 1
	perks_state["tended"] = live


# veinsPerDay of the dailyTend perks active in a district (0 when none).
static func _tend_budget(district_id: String) -> int:
	var total := 0
	for entry in active_turf(district_id):
		if entry["perk"]["effect"] == "dailyTend":
			total += int(entry["perk"]["params"]["veinsPerDay"])
	return total


# Sworn Collective whip-round: before a forced home downgrade, once per game,
# the arrears are cleared instead. Returns true if it fired.
static func try_whip_round() -> bool:
	var perks_state: Dictionary = GameState.state["perks"]
	if perks_state["whipRoundUsed"] or not _has_global_effect("homeBailout"):
		return false
	var home: Dictionary = GameState.state["home"]
	var cleared: int = home["arrears"]
	perks_state["whipRoundUsed"] = true
	home["arrears"] = 0
	home["arrearsWeeks"] = 0
	Notify.push("The Collective passes the hat. £%d of arrears gone, and you keep your home. Once." % cleared, Notify.CATEGORY_INFO)
	return true


static func _has_global_effect(effect: String) -> bool:
	for entry in active_global():
		if entry["perk"]["effect"] == effect:
			return true
	return false


# ── Firm perks ────────────────────────────────────────────────────────────

const FIRM := "firm"
const _RACKET_PROTECTED_MOVES := ["veinRaid", "stockpileRaid", "shortfallSteal"]


static func _global_params(effect: String) -> Dictionary:
	for entry in active_global():
		if entry["perk"]["effect"] == effect:
			return entry["perk"]["params"]
	return {}


# Friendly Firm: the protection racket is on offer.
static func racket_available() -> bool:
	return not _global_params("protectionRacket").is_empty()


# Opted in and still entitled (losing Friendly ends the racket).
static func racket_active() -> bool:
	return bool(GameState.state["perks"].get("racket", false)) and racket_available()


static func racket_fee() -> int:
	return int(_global_params("protectionRacket").get("weeklyFee", 0))


static func set_racket(on: bool) -> Dictionary:
	if on and not racket_available():
		return { "ok": false, "reason": "The Firm has no time for you yet." }
	GameState.state["perks"]["racket"] = on
	EventBus.state_changed.emit()
	return { "ok": true }


# True when the racket stops this faction using this move on the player.
static func racket_blocks(observer: String, target: String, move_id: String) -> bool:
	return observer == FIRM and target == Shares.PLAYER and _RACKET_PROTECTED_MOVES.has(move_id) and racket_active()


# Odds shift on other factions' raids against the player while the racket runs.
static func racket_deterrence(attacker_id: String) -> float:
	if attacker_id == FIRM or not racket_active():
		return 0.0
	return float(_global_params("protectionRacket").get("deterrence", 0.0))


# Monday bills: the weekly fee from cash, in full. Short cash ends the racket.
# Returns the amount paid.
static func pay_racket_fee() -> int:
	if not Calendar.is_monday(GameState.state["world"]["day"]) or not racket_active():
		return 0
	var fee := racket_fee()
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < fee:
		GameState.state["perks"]["racket"] = false
		Notify.push("You can't cover the Firm's £%d. The protection ends." % fee, Notify.CATEGORY_WARNING)
		EventBus.state_changed.emit()
		return 0
	player["cash"] -= fee
	Bank.record(-fee, "Protection")
	Notify.push("Protection: -£%d to the Firm this week." % fee)
	EventBus.state_changed.emit()
	return fee


# Partner Firm: muscle can be hired for a raid.
static func muscle_available() -> bool:
	return not _global_params("raidMuscle").is_empty()


# Raid-odds bonus while the running raid event has muscle hired.
static func muscle_odds_bonus() -> float:
	if not muscle_available() or not event_has_muscle():
		return 0.0
	return float(_global_params("raidMuscle")["raidOddsAdj"])


static func event_has_muscle() -> bool:
	var event_state: Variant = GameState.state.get("event")
	return event_state != null and bool(event_state.get("context", {}).get("muscle", false))


# The hired fighter as a combat ally (no contactId: a KO lasts the fight).
static func muscle_ally() -> Dictionary:
	var ally: Dictionary = _global_params("raidMuscle")["ally"]
	return {
		"name": ally["name"], "hp": ally["hp"], "hpMax": ally["hp"],
		"attackMin": ally["attackMin"], "attackMax": ally["attackMax"], "speed": ally["speed"],
		"slots": [], "slotsUsed": [], "koed": false,
	}


# Sworn Firm: its districts count as the player's for danger.
static func counts_as_player_for_danger(district_id: String) -> bool:
	return Turf.controller(district_id) == FIRM and has_perk("firm_safe_ground", district_id)


# ── Guild perks ───────────────────────────────────────────────────────────

# Friendly Guild: multiplier on crafting XP (1.0 when none).
static func craft_xp_mult() -> float:
	return float(_global_params("craftXpMult").get("value", 1.0))


# Sworn Guild: commission offer params, or {} when not sworn.
static func commission_params() -> Dictionary:
	return _global_params("commissionCrafting")


# Today's internship ledger, reset when the day turns.
static func _internship_today() -> Dictionary:
	var perks_state: Dictionary = GameState.state["perks"]
	var day: int = int(GameState.state["world"]["day"])
	var ledger: Dictionary = perks_state.get("internship", {})
	if int(ledger.get("day", -1)) != day:
		ledger = { "day": day, "cultivateUsed": 0 }
		perks_state["internship"] = ledger
	return ledger


# Summed internship param over the active turf perks in a district.
static func _internship_budget(district_id: String, param: String) -> float:
	var total := 0.0
	for entry in active_turf(district_id):
		if entry["perk"]["effect"] == "internship":
			total += float(entry["perk"]["params"][param])
	return total


# Consumes one free cultivation (no time block) for a vein in this district.
static func take_free_cultivate(district_id: String) -> bool:
	var budget := int(_internship_budget(district_id, "bonusCultivateActions"))
	if budget <= 0:
		return false
	var ledger := _internship_today()
	if int(ledger["cultivateUsed"]) >= budget:
		return false
	ledger["cultivateUsed"] = int(ledger["cultivateUsed"]) + 1
	return true


# Crafting success-chance bonus: the best internship bonus among districts
# where the player holds a vein.
static func craft_chance_bonus() -> float:
	var best := 0.0
	for vein in GameState.state["player"]["veins"]:
		best = maxf(best, _internship_budget(vein["district"], "craftChanceBonus"))
	return best


# ── Network perks ─────────────────────────────────────────────────────────

const NETWORK := "network"


# Friendly Network: the faction the player watches ("" = none).
static func intel_target() -> String:
	return String(GameState.state["perks"].get("intelTarget", ""))


static func intel_perk_available() -> bool:
	return not _global_params("dailyIntel").is_empty()


static func set_intel_target(faction_id: String) -> Dictionary:
	if not intel_perk_available():
		return { "ok": false, "reason": "The Network has no time for you yet." }
	if faction_id != "" and not GameData.FACTIONS.has(faction_id):
		return { "ok": false, "reason": "Unknown faction." }
	GameState.state["perks"]["intelTarget"] = faction_id
	EventBus.state_changed.emit()
	return { "ok": true }


# Rollover ⑥.5i1: the watched faction's intel rises by the perk's amount
# while Friendly+ (privacy still blocks it).
static func daily_intel() -> void:
	var target := intel_target()
	if target == "" or not intel_perk_available() or Intel.privacy_active(target):
		return
	Intel.raise(Shares.PLAYER, target, int(_global_params("dailyIntel")["amount"]))


# Partner Network: raids against the player are texted ahead by the handler.
static func forewarning_active() -> bool:
	return _has_global_effect("raidForewarning")


# Sworn Network: commission params, or {} when not sworn.
static func commission_move_params() -> Dictionary:
	return _global_params("commissionMarketMove")


# Days until the next commission is allowed (0 = ready).
static func commission_cooldown_left() -> int:
	var params := commission_move_params()
	if params.is_empty():
		return 0
	var ready: int = int(GameState.state["perks"].get("commissionDay", -999)) + int(params["cooldownDays"])
	return maxi(0, ready - int(GameState.state["world"]["day"]))


# The Network runs a market move against target for the player. Costs
# params.cost cash, then params.cooldownDays before the next one.
static func commission_market_move(move_id: String, target_id: String) -> Dictionary:
	var params := commission_move_params()
	if params.is_empty():
		return { "ok": false, "reason": "The Network doesn't take your orders." }
	if not params["moves"].has(move_id) or not GameData.FACTIONS.has(target_id) or target_id == NETWORK:
		return { "ok": false, "reason": "Unknown order." }
	if commission_cooldown_left() > 0:
		return { "ok": false, "reason": "The Network is still busy with your last one." }
	var player: Dictionary = GameState.state["player"]
	var cost := int(params["cost"])
	if int(player["cash"]) < cost:
		return { "ok": false, "reason": "You can't cover £%d." % cost }
	var candidate := FactionAI._move_candidate(NETWORK, target_id, move_id)
	if candidate.is_empty():
		return { "ok": false, "reason": "Nothing there for them to work with." }
	player["cash"] -= cost
	Bank.record(-cost, "Network commission")
	GameState.state["perks"]["commissionDay"] = int(GameState.state["world"]["day"])
	FactionAI._make_move(NETWORK, target_id, candidate)
	EventBus.state_changed.emit()
	return { "ok": true, "cost": cost }


# ── Conclave perks ────────────────────────────────────────────────────────

const CONCLAVE := "conclave"


# Friendly Conclave: summed dangerAdj of active turf perks in a district, scaled by Control/Foothold.
static func danger_adj(district_id: String) -> float:
	var total := 0.0
	for entry in active_turf(district_id):
		if entry["perk"]["effect"] == "dangerAdj":
			total += float(entry["perk"]["params"]["value"]) * float(entry["scale"])
	return total


# Raid-loss bookkeeping: a claimed vein is remembered as { veinId, attacker } until recovered.
static func note_raid_loss(vein_id: String, attacker_id: String) -> void:
	var perks_state: Dictionary = GameState.state["perks"]
	if not perks_state.has("raidLost"):
		perks_state["raidLost"] = []
	perks_state["raidLost"].append({ "veinId": vein_id, "attacker": attacker_id })


# Partner Conclave: the one-off recovery is on offer and unspent.
static func recovery_available() -> bool:
	return not recovery_used() and not _global_params("veinRecovery").is_empty()


static func recovery_used() -> bool:
	return bool(GameState.state["perks"].get("recoveryUsed", false))


# Raid-lost veins the raider still holds: [{ veinId, attacker, siteId, district }].
static func recoverable_veins() -> Array:
	var result := []
	if not recovery_available():
		return result
	for entry in GameState.state["perks"].get("raidLost", []):
		for site in Sites.sites_with_faction_vein(String(entry["attacker"])):
			if site["factionVein"]["id"] == entry["veinId"]:
				result.append({ "veinId": entry["veinId"], "attacker": entry["attacker"], "siteId": site["id"], "district": site["district"] })
	return result


# Conclave lawyers return a raid-lost vein with no fight and no price. Once.
static func recover_vein(vein_id: String) -> Dictionary:
	if recovery_used():
		return { "ok": false, "reason": "The lawyers have already done their one favour." }
	if not recovery_available():
		return { "ok": false, "reason": "The Conclave's lawyers don't act for you." }
	for row in recoverable_veins():
		if row["veinId"] != vein_id:
			continue
		var result := VeinTrade.transfer_from_faction(vein_id, String(row["attacker"]))
		if not result["ok"]:
			return result
		var perks_state: Dictionary = GameState.state["perks"]
		perks_state["recoveryUsed"] = true
		perks_state["raidLost"] = []
		Notify.push("Conclave lawyers find the paperwork. The vein is yours again.", Notify.CATEGORY_INFO)
		EventBus.state_changed.emit()
		return { "ok": true }
	return { "ok": false, "reason": "Nothing there to recover." }


# Sworn Conclave: barometer nudge params, or {} when not sworn.
static func nudge_params() -> Dictionary:
	return _global_params("barometerAndLore")


# Days until the next nudge is allowed (0 = ready).
static func nudge_cooldown_left() -> int:
	var params := nudge_params()
	if params.is_empty():
		return 0
	var ready: int = int(GameState.state["perks"].get("nudgeDay", -999)) + int(params["cooldownDays"])
	return maxi(0, ready - int(GameState.state["world"]["day"]))


# The Conclave leans on a Ticker state for the player: costs params.cost, then params.cooldownDays.
static func conclave_nudge(section: String, state_id: String, direction: String) -> Dictionary:
	var params := nudge_params()
	if params.is_empty():
		return { "ok": false, "reason": "The Conclave doesn't take your calls." }
	if not Barometer.SECTIONS.has(section) or not GameData.BAROMETER_STATES[section].has(state_id) or not ["push", "pull"].has(direction):
		return { "ok": false, "reason": "Unknown target." }
	if nudge_cooldown_left() > 0:
		return { "ok": false, "reason": "The Conclave is still acting on your last request." }
	var player: Dictionary = GameState.state["player"]
	var cost := int(params["cost"])
	if int(player["cash"]) < cost:
		return { "ok": false, "reason": "You can't cover £%d." % cost }
	player["cash"] -= cost
	Bank.record(-cost, "Conclave nudge")
	GameState.state["perks"]["nudgeDay"] = int(GameState.state["world"]["day"])
	var strength := int(params["strength"])
	Barometer.shift_state(section, state_id, strength if direction == "push" else -strength)
	return { "ok": true, "cost": cost }


# Sworn Conclave sets its lore flag; called at rollover and on joining.
static func sync_lore() -> void:
	var params := nudge_params()
	if params.is_empty():
		return
	GameState.state["flags"][String(params["loreFlag"])] = true
