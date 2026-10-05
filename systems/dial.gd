class_name Dial
extends RefCounted

# The Dial device mechanic (R§3.5): seeding, Movement crafting/seating,
# Complications (load/unload/cast), the charge pool, and Dial XP/leveling.
# Static funcs only, same discipline as sites.gd/crafting.gd.


# Dials are per-owner: owner_id "" is the player's (player.dial), a contact id is
# that contact's (contacts.<id>.dial). Stock and calc always come from the player.
static func dial_of(owner_id: String = "") -> Variant:
	if owner_id == "":
		return GameState.state["player"]["dial"]
	var contact: Variant = GameState.state["contacts"].get(owner_id)
	if contact is Dictionary:
		return contact.get("dial")
	return null


static func seed_success_chance() -> float:
	var player: Dictionary = GameState.state["player"]
	# Same shape as Crafting.craft_chance() (R§3.5), using DIAL_SEED_BASE_SUCCESS in place of a recipe's baseSuccess.
	var craft_term: float = min(0.95, GameData.DIAL_SEED_BASE_SUCCESS + (player["craftingSkill"] - 1) * 0.13 + Home.get_workshop_bonus())
	var cult_term: float = Cultivating.get_cult_chance(player["cultivatingSkill"])
	return clampf((craft_term + cult_term) / 2.0, 0.05, 0.95)


# Same shape as Sites.attempt_seed(): full cost spent regardless of outcome, one
# roll (R§3.5). Refused if player.dial is already non-null or the gift flag isn't set.
static func attempt_seed(haft_id: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] != null:
		return { "ok": false, "reason": "You already have a Dial." }
	if not GameState.state["flags"].get("dialGiftGranted", false):
		return { "ok": false, "reason": "You don't have the gift." }
	if not GameData.DIAL_HAFTS.has(haft_id):
		return { "ok": false, "reason": "Unknown haft." }

	var cost: Dictionary = GameData.DIAL_SEED_COST
	var orichalchum: Dictionary = player["orichalchum"]
	for ore_type in cost:
		if orichalchum.get(ore_type, 0) < cost[ore_type]:
			return { "ok": false, "reason": "Not enough calc." }

	for ore_type in cost:
		orichalchum[ore_type] = orichalchum.get(ore_type, 0) - cost[ore_type]

	var success: bool = Rng.chance(seed_success_chance())
	if success:
		player["dial"] = new_dial(haft_id)

	EventBus.state_changed.emit()
	return { "ok": true, "success": success }


# No barrel-length check needed -- every whitelisted haft satisfies it by construction.
static func set_haft(haft_id: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	if not GameData.DIAL_HAFTS.has(haft_id):
		return { "ok": false, "reason": "Unknown haft." }

	player["dial"]["haftId"] = haft_id
	EventBus.state_changed.emit()
	return { "ok": true }


static func haft_name(dial: Dictionary) -> String:
	return GameData.DIAL_HAFTS.get(dial["haftId"], {}).get("name", dial["haftId"])


# Used by combat.gd's combat_rewind() and events.gd's rewind() as a fallback when
# no rewind consumable is available (R§3.9). Returns -1 if none loaded with charge.
static func find_loaded_rewind_complication_index() -> int:
	var dial: Variant = GameState.state["player"]["dial"]
	if dial == null or dial["currentCharge"] < 1:
		return -1
	var loaded: Array = dial["loadedComplications"]
	for i in range(loaded.size()):
		if loaded[i]["recipeKey"] == "rewind":
			return i
	return -1


# Freshly seeded: no Movement, zero charge/regen; capacityMax is populated from
# level 1 regardless (R§3.5). Public: DebugStart.apply() seeds a bare Dial
# directly, bypassing attempt_seed()'s gate/cost/roll.
static func new_dial(haft_id: String, day: int = -1) -> Dictionary:
	return {
		"level": 1,
		"xp": 0,
		"currentCharge": 0,
		"maxCharge": 0,
		"rechargeRate": 0,
		# Player-turn counter toward the tier-5 Recharge Movement's in-combat regen; reset on every (re)seat/unseat.
		"combatRegenTurnCounter": 0,
		# Guards daily_regen(); set to the seeding day so a Dial seeded today doesn't regen until tomorrow.
		"lastRegenDay": day if day >= 0 else GameState.state["world"]["day"],
		"capacityMax": capacity_max(1),
		"movement": null,
		"loadedComplications": [],
		"haftId": haft_id,
	}


# A contact's granted Dial from constants.json's grantDial spec ({haft, level,
# movement: {archetype, oreType, tier}, complications: [{recipe, tier}]}): level,
# seated Movement and loaded Complications as specced, charge full. Pure --
# touches no state, so the save migration can call it too.
static func build_granted_dial(spec: Dictionary, day: int) -> Dictionary:
	var dial: Dictionary = new_dial(str(spec["haft"]), day)
	dial["level"] = int(spec["level"])
	dial["capacityMax"] = capacity_max(dial["level"])
	var seated: Dictionary = spec["movement"]
	dial["movement"] = _new_movement(seated["archetype"], seated["oreType"], int(seated["tier"]))
	_apply_level_charge_bonus(dial)
	dial["currentCharge"] = dial["maxCharge"]
	for entry in spec["complications"]:
		dial["loadedComplications"].append({ "recipeKey": entry["recipe"], "tier": int(entry["tier"]), "detent": dial["loadedComplications"].size() })
	return dial


# Gives a recruited contact their grantDial, if constants.json defines one and
# they don't already hold a Dial. Player stock is never touched.
static func grant_contact_dial(contact_id: String) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	var spec: Variant = GameData.CONTACTS_DEFAULTS.get(contact_id, {}).get("grantDial")
	if not (spec is Dictionary) or not contacts.has(contact_id) or contacts[contact_id].get("dial") != null:
		return
	contacts[contact_id]["dial"] = build_granted_dial(spec, GameState.state["world"]["day"])


# Movement crafting/seating/attunement (R§3.5). Movements are a Dial-only
# craftable in their own data table (data/dial.json's "movements"), not
# GameData.RECIPES -- but follow the same contract: ingredients always spent, a
# chance formula gates success, tier = quality_tier() at craft time.


const MOVEMENT_ARCHETYPES: Array[String] = GameData.CANONICAL_MOVEMENT_ARCHETYPES


static func movement_craft_chance(archetype: String, skill: int) -> float:
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	# Same shape as Crafting.craft_chance(), keyed off the Movement's own baseSuccess.
	return min(0.95, m["baseSuccess"] + (skill - 1) * 0.13 + Home.get_workshop_bonus())


# Same shape as Crafting.calc_cost(), but keyed on the player's chosen attunement ore rather than a recipe's ingredients dict.
static func movement_calc_cost(archetype: String, skill: int) -> int:
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	return maxi(1, GameState.round_epsilon(m["ingredientBase"] - (skill - 1) * 0.8))


static func can_craft_movement(archetype: String, ore_type: String) -> bool:
	if not MOVEMENT_ARCHETYPES.has(archetype):
		return false
	if not GameData.ORE_TYPES.has(ore_type):
		return false
	var skill: int = GameState.state["player"]["craftingSkill"]
	var cost: int = movement_calc_cost(archetype, skill)
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	return orichalchum.get(ore_type, 0) >= cost


# Ingredients spent regardless of outcome; success lands the Movement unseated
# in player.movementInventory with the chosen ore as attunement, tier = crafting skill at craft time (R§3.5).
static func attempt_craft_movement(archetype: String, ore_type: String) -> Dictionary:
	if not MOVEMENT_ARCHETYPES.has(archetype):
		return { "ok": false, "reason": "Unknown Movement archetype." }
	if not GameData.ORE_TYPES.has(ore_type):
		return { "ok": false, "reason": "Unknown ore type." }
	if not can_craft_movement(archetype, ore_type):
		return { "ok": false, "reason": "Not enough calc." }

	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var cost: int = movement_calc_cost(archetype, skill)
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]

	player["orichalchum"][ore_type] = maxi(0, player["orichalchum"].get(ore_type, 0) - cost)

	var success: bool = Rng.chance(movement_craft_chance(archetype, skill))
	if success:
		# No refine/discovery step (Bench-only, R§3.5) -- tier is always the crafting
		# skill at craft time, since Movements have no GameData.RECIPES entry to key quality_tier() off of.
		var tier: int = skill
		var movement := _new_movement(archetype, ore_type, tier)
		player["movementInventory"].append(movement)
		Crafting.award_crafting_xp(m["xpReward"])
		EventBus.state_changed.emit()
		return { "ok": true, "success": true, "archetype": archetype, "oreType": ore_type, "tier": tier }
	else:
		Crafting.award_crafting_xp(int(floor(float(m["xpReward"]) / 3.0)))
		EventBus.state_changed.emit()
		return { "ok": true, "success": false }


static func _new_movement(archetype: String, ore_type: String, tier: int) -> Dictionary:
	return { "archetype": archetype, "oreType": ore_type, "tier": tier }


# Swaps in the Movement at inventory_index; whatever was seated returns to
# inventory intact. _activate_charge_pool() below resizes the charge pool from scratch -- a reseat never inherits the previous Movement's reserve.
static func seat_movement(inventory_index: int, owner_id: String = "") -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var dial_v: Variant = dial_of(owner_id)
	if dial_v == null:
		return { "ok": false, "reason": "No Dial." }
	var inventory: Array = player["movementInventory"]
	if inventory_index < 0 or inventory_index >= inventory.size():
		return { "ok": false, "reason": "No such Movement." }

	var incoming: Dictionary = inventory[inventory_index]
	var dial: Dictionary = dial_v
	var previous: Variant = dial["movement"]

	inventory.remove_at(inventory_index)
	if previous != null:
		inventory.append(previous)
	dial["movement"] = incoming
	_activate_charge_pool(dial)

	EventBus.state_changed.emit()
	return { "ok": true }


# Returns the seated Movement to inventory intact. _deactivate_charge_pool() below zeroes the charge pool back to the inert-Dial shape.
static func unseat_movement(owner_id: String = "") -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var dial_v: Variant = dial_of(owner_id)
	if dial_v == null:
		return { "ok": false, "reason": "No Dial." }
	var dial: Dictionary = dial_v
	if dial["movement"] == null:
		return { "ok": false, "reason": "No Movement seated." }

	player["movementInventory"].append(dial["movement"])
	dial["movement"] = null
	_deactivate_charge_pool(dial)

	EventBus.state_changed.emit()
	return { "ok": true }


# Flat additive bonus from the seated Movement only (never loadedComplications),
# applied when ore_type matches its attunement; magnitude scales with tier per
# data/dial.json's attunementBonusByTier (R§3.5). Callers (Crafting.attempt_craft(),
# Sites.attempt_seed()) add this on top of their own chance formula.
# Cultivating.cultivate() instead multiplies its rolled gain by (1 + this
# bonus), since that action has no chance to shift (R§3.4). Never baked in,
# since NPC contacts roll those same formulas without a Dial.
static func attunement_bonus(ore_type: String) -> float:
	var dial: Variant = GameState.state["player"]["dial"]
	if dial == null:
		return 0.0
	var movement: Variant = dial["movement"]
	if movement == null:
		return 0.0
	if movement["oreType"] != ore_type:
		return 0.0
	var curve: Array = GameData.DIAL_ATTUNEMENT_BONUS_BY_TIER
	var tier: int = clampi(movement["tier"], 0, curve.size() - 1)
	return curve[tier]


# Shared 0.95 ceiling for single-ore-type chance actions (Sites.attempt_seed()).
# Crafting.attempt_craft() doesn't use this directly since a recipe can span multiple ore types.
static func apply_attunement(base_chance: float, ore_type: String) -> float:
	return min(0.95, base_chance + attunement_bonus(ore_type))


# Complications: load/unload and the Dial-level capacity budget (R§3.5). Loading
# moves a unit out of Crafting's tiered player.inventory into
# player.dial.loadedComplications unchanged in tier; unloading reverses it. Each
# loaded entry ({recipeKey, tier, detent, multi?}) costs exactly one slot regardless of recipe/tier; detent is a cosmetic display-order index only.


# Capacity is Dial-level only (data/dial.json's capacityByLevel), independent of the seated Movement (R§3.5).
static func capacity_max(level: int) -> int:
	var curve: Array = GameData.DIAL_CAPACITY_BY_LEVEL
	var idx: int = clampi(level, 0, curve.size() - 1)
	return curve[idx]


static func capacity_used(dial: Dictionary) -> int:
	return dial["loadedComplications"].size()


# Moves one unit of recipe_key at tier from the tiered inventory into
# loadedComplications; refused once it would exceed capacityMax (populated from
# capacity_max() at seed time, R§3.5). Works identically with no Movement seated.
static func load_complication(recipe_key: String, tier: int, owner_id: String = "", multi: bool = false) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var dial_v: Variant = dial_of(owner_id)
	if dial_v == null:
		return { "ok": false, "reason": "No Dial." }
	if not GameData.RECIPES.has(recipe_key):
		return { "ok": false, "reason": "Unknown recipe." }

	var inventory_key := Crafting.inventory_key(recipe_key, multi)
	var buckets: Dictionary = player["inventory"].get(inventory_key, {})
	var tier_key := str(tier)
	if buckets.get(tier_key, 0) <= 0:
		return { "ok": false, "reason": "Nothing to load." }

	var dial: Dictionary = dial_v
	if capacity_used(dial) + 1 > dial["capacityMax"]:
		return { "ok": false, "reason": "Not enough capacity." }

	Crafting.inventory_remove_from_tier(inventory_key, tier, 1)
	var loaded: Array = dial["loadedComplications"]
	var entry := { "recipeKey": recipe_key, "tier": tier, "detent": loaded.size() }
	if multi:
		entry["multi"] = true
	loaded.append(entry)

	EventBus.state_changed.emit()
	return { "ok": true }


# Reverses load_complication() exactly, returning the unit to its original tier
# bucket. Indexes loadedComplications directly since two loaded units can share a recipeKey/tier.
static func unload_complication(index: int, owner_id: String = "") -> Dictionary:
	var dial_v: Variant = dial_of(owner_id)
	if dial_v == null:
		return { "ok": false, "reason": "No Dial." }
	var loaded: Array = dial_v["loadedComplications"]
	if index < 0 or index >= loaded.size():
		return { "ok": false, "reason": "No such Complication." }

	var entry: Dictionary = loaded[index]
	loaded.remove_at(index)
	Crafting.inventory_add(Crafting.inventory_key(entry["recipeKey"], entry.get("multi", false)), entry["tier"], 1)

	EventBus.state_changed.emit()
	return { "ok": true }


# Charge pool lifecycle, winding, and daily regen (R§3.5). Charge only exists
# while a Movement is seated: seat_movement() activates the pool (sizes
# maxCharge/rechargeRate from the Movement's archetype/tier, zeroes
# currentCharge); unseat_movement() deactivates it back to the inert shape. Once
# seated, maxCharge/rechargeRate stay fixed until the next reseat. Each
# archetype's bonus/downside curve feeds one charge-economy stat: Recharge's
# bonus raises rechargeRate, downside lowers maxCharge; Capacitor's bonus raises
# maxCharge, downside lowers rechargeRate (floored at 0, guaranteed zero at tier
# 5). Impact/Spread have no charge bonus -- only their downside applies, to maxCharge.


static func _charge_stats_for(archetype: String, tier: int) -> Dictionary:
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	var t: int = clampi(tier, 0, m["bonus"].size() - 1)
	var bonus: float = m["bonus"][t]
	var downside: float = m["downside"][t]

	var max_charge: float = GameData.DIAL_BASE_MAX_CHARGE
	var recharge_rate: float = GameData.DIAL_BASE_RECHARGE_RATE
	match archetype:
		"recharge":
			recharge_rate += bonus
			max_charge -= downside
		"capacitor":
			max_charge += bonus
			recharge_rate -= downside
		_:
			max_charge -= downside

	recharge_rate = maxf(0.0, recharge_rate)
	if archetype == "capacitor" and t == 5:
		recharge_rate = 0.0  # Tier-5 Capacitor: guaranteed zero, not just a consequence of the downside curve.

	# maxCharge is an integer pip count; rechargeRate may be fractional.
	# currentCharge stays a float so fractional regen accumulates smoothly
	# instead of being truncated each tick.
	return { "maxCharge": maxi(1, GameState.round_epsilon(max_charge)), "rechargeRate": recharge_rate }


# Dial XP and leveling (R§3.5). maxCharge/rechargeRate stay Movement-sized as
# their base; leveling adds a bonus read from two level-indexed curves
# (data/dial.json's maxChargeBonusByLevel/rechargeRateBonusByLevel). maxCharge's
# curve grows every level; rechargeRate's is sparser. Both are 0 at level 1, so a fresh level-1 Dial matches its pre-leveling stats exactly.


static func max_charge_level_bonus(level: int) -> float:
	var curve: Array = GameData.DIAL_MAX_CHARGE_BONUS_BY_LEVEL
	var idx: int = clampi(level, 0, curve.size() - 1)
	return curve[idx]


static func recharge_rate_level_bonus(level: int) -> float:
	var curve: Array = GameData.DIAL_RECHARGE_RATE_BONUS_BY_LEVEL
	var idx: int = clampi(level, 0, curve.size() - 1)
	return curve[idx]


# Shared by _activate_charge_pool() (reseat) and cast_complication()'s level-up
# callback; recomputes maxCharge/rechargeRate from (seated Movement, dial.level).
# A null movement is a silent no-op -- unseated Dials stay inert regardless of level.
static func _apply_level_charge_bonus(dial: Dictionary) -> void:
	var movement: Variant = dial["movement"]
	if movement == null:
		return
	var stats: Dictionary = _charge_stats_for(movement["archetype"], movement["tier"])
	var level: int = dial["level"]
	dial["maxCharge"] = maxi(1, GameState.round_epsilon(float(stats["maxCharge"]) + max_charge_level_bonus(level)))
	var recharge_rate: float = stats["rechargeRate"] + recharge_rate_level_bonus(level)
	# Re-asserted here (not inherited from _charge_stats_for()) so leveling's rechargeRate bonus can't undo tier-5 Capacitor's zero-regen trait.
	if movement["archetype"] == "capacitor" and movement["tier"] >= 5:
		recharge_rate = 0.0
	dial["rechargeRate"] = recharge_rate


static func _activate_charge_pool(dial: Dictionary) -> void:
	_apply_level_charge_bonus(dial)
	dial["currentCharge"] = 0
	dial["combatRegenTurnCounter"] = 0


static func _deactivate_charge_pool(dial: Dictionary) -> void:
	dial["maxCharge"] = 0
	dial["rechargeRate"] = 0
	dial["currentCharge"] = 0
	dial["combatRegenTurnCounter"] = 0


# Keyed only by (archetype, tier), never dial.level -- leveling never makes winding worse.
static func winding_cost_per_charge(archetype: String, tier: int) -> int:
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	var t: int = clampi(tier, 0, m["windingCostPerCharge"].size() - 1)
	return m["windingCostPerCharge"][t]


# Instant, calc-only -- doesn't spend a time block. amount clamps to headroom
# under maxCharge so calc is never spent on charge that would be discarded at the cap.
static func wind(amount: int = 1, owner_id: String = "") -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var dial_v: Variant = dial_of(owner_id)
	if dial_v == null:
		return { "ok": false, "reason": "No Dial." }
	var dial: Dictionary = dial_v
	if dial["movement"] == null:
		return { "ok": false, "reason": "No Movement seated." }
	if amount <= 0:
		return { "ok": false, "reason": "Nothing to wind." }
	if dial["currentCharge"] >= dial["maxCharge"]:
		return { "ok": false, "reason": "Charge is already full." }

	var headroom: int = int(ceil(dial["maxCharge"] - dial["currentCharge"]))
	var actual_amount: int = mini(amount, headroom)

	var movement: Dictionary = dial["movement"]
	var cost_per_charge: int = winding_cost_per_charge(movement["archetype"], movement["tier"])
	var total_cost: int = cost_per_charge * actual_amount
	var ore_type: String = movement["oreType"]
	var orichalchum: Dictionary = player["orichalchum"]
	if orichalchum.get(ore_type, 0) < total_cost:
		return { "ok": false, "reason": "Not enough calc." }

	orichalchum[ore_type] -= total_cost
	dial["currentCharge"] = minf(dial["maxCharge"], dial["currentCharge"] + actual_amount)

	EventBus.state_changed.emit()
	return { "ok": true, "chargeAdded": actual_amount, "calcSpent": total_cost }


# Called once per day from time_system.gd's daily_tick; lastRegenDay guards
# against ticking twice in one day. Trailing emit is unconditional even on a no-op. Null dial is a silent no-op.
static func daily_regen() -> void:
	var day: int = GameState.state["world"]["day"]
	var owners: Array = [""]
	owners.append_array(GameState.state["contacts"].keys())
	for owner_id in owners:
		var dial: Variant = dial_of(owner_id)
		if dial != null and dial["lastRegenDay"] < day:
			dial["currentCharge"] = minf(dial["maxCharge"], dial["currentCharge"] + dial["rechargeRate"])
			dial["lastRegenDay"] = day
	EventBus.state_changed.emit()


# Casting a loaded Complication (R§3.5). Spends one charge from the pool rather
# than the loaded unit itself -- loaded units already left player.inventory at
# load time. Base power is Crafting.effect_power() at the tier the unit was
# *loaded* at, not the player's current skill, so a cast doesn't drift as skill
# improves. Amplification reuses each archetype's "bonus" curve: Impact
# multiplies power, Spread grants extra full-power targets; Recharge/Capacitor
# apply none (that curve is already claimed by the charge economy).
# Directly-thrown consumables (combat.gd's use_*()) never call this and never amplify.
static func cast_complication(index: int, owner_id: String = "") -> Dictionary:
	var dial_v: Variant = dial_of(owner_id)
	if dial_v == null:
		return { "ok": false, "reason": "No Dial." }
	var dial: Dictionary = dial_v
	var loaded: Array = dial["loadedComplications"]
	if index < 0 or index >= loaded.size():
		return { "ok": false, "reason": "No such Complication." }
	if dial["currentCharge"] < 1:
		return { "ok": false, "reason": "Not enough charge." }

	var entry: Dictionary = loaded[index]
	var recipe_key: String = entry["recipeKey"]
	var base_power = Crafting.effect_power(recipe_key, entry["tier"])
	var amplified := _amplify_cast(base_power, dial["movement"], int(dial["level"]), recipe_key)

	dial["currentCharge"] -= 1

	# +10 XP per cast (Progression.award_xp()). Leveling up grows capacityMax
	# unconditionally and, if a Movement is seated, re-derives maxCharge/rechargeRate via _apply_level_charge_bonus().
	var on_level_up := func():
		dial["capacityMax"] = capacity_max(dial["level"])
		_apply_level_charge_bonus(dial)
		var who: String = "Your" if owner_id == "" else "%s's" % Contacts.display_name(owner_id)
		Notify.push("%s Dial has levelled up — now level %d." % [who, dial["level"]], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(dial, "xp", "level", GameData.DIAL_XP_LEVELS, 10, on_level_up)

	EventBus.state_changed.emit()
	return { "ok": true, "recipeKey": recipe_key, "power": amplified["power"], "targets": amplified["targets"], "turnPower": amplified["turnPower"], "turnBonus": amplified["turnBonus"], "tier": int(entry["tier"]), "magnitudeMult": amplified["magnitudeMult"], "multi": bool(entry.get("multi", false)) }


# Pure function of (base_power, movement), split out of cast_complication() for isolated testing.
static func _amplify_cast(base_power: Variant, movement: Variant, level: int = 0, recipe_key: String = "") -> Dictionary:
	var impact_mult: float = 1.0
	var targets: int = 1
	if movement != null:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
		var t: int = clampi(movement["tier"], 0, m["bonus"].size() - 1)
		match movement["archetype"]:
			"impact":
				# Multiplicative boost to base power (tier 5's 1.2 bonus more than doubles it).
				impact_mult = 1.0 + m["bonus"][t]
			"spread":
				# Every target gets the untouched base_power (no dilution); bonus is an integer extra-target count.
				targets = 1 + int(m["bonus"][t])
			# Recharge/Capacitor's "bonus" array is the charge economy, not effect magnitude -- casting is identical to no Movement seated.

	# One rounding over Impact x level multiplier (R§3.5). turnPower is the Impact-only
	# power that timed effects derive their base turns from -- the level multiplier never touches turns.
	var magnitude: int = GameState.round_epsilon(float(base_power) * impact_mult * cast_level_multiplier(level))
	var turn_power: int = GameState.round_epsilon(float(base_power) * impact_mult)
	var power: int = magnitude
	var turn_bonus: int = 0
	match recipe_key:
		"timePearl", "prophetsBreath", "panic", "pansRapture":
			power = turn_power
			turn_bonus = maxi(level, 0)
		"blackHole":
			turn_bonus = cast_black_hole_freeze_bonus(level)
	return { "power": power, "targets": targets, "turnPower": turn_power, "turnBonus": turn_bonus, "magnitudeMult": impact_mult * cast_level_multiplier(level) }


# 1 + 0.25 x level (data/dial.json castMagnitudePerLevel). Level 0 (no Dial) is 1.0.
static func cast_level_multiplier(level: int) -> float:
	return 1.0 + GameData.DIAL_CAST_MAGNITUDE_PER_LEVEL * maxi(level, 0)


static func cast_black_hole_freeze_bonus(level: int) -> int:
	var curve: Array = GameData.DIAL_CAST_BLACK_HOLE_FREEZE_BONUS_BY_LEVEL
	return int(curve[clampi(level, 0, curve.size() - 1)])


# Extra turns a Dial of `level` adds to a timed Complication's cast (once per cast,
# after Spread); 0 for recipes without a turn effect. Read by the UI readout.
static func cast_turn_bonus(recipe_key: String, level: int) -> int:
	match recipe_key:
		"timePearl", "prophetsBreath", "panic", "pansRapture":
			return maxi(level, 0)
		"blackHole":
			return cast_black_hole_freeze_bonus(level)
	return 0


# Tier-5 Recharge Movement's in-combat regen (R§3.5) -- the only archetype that
# regenerates charge mid-combat rather than only via daily_regen()/winding.
# Called once per player turn from combat.gd's player_attack(). No-op unless a tier-5+ Recharge Movement is seated.
static func combat_turn_tick(owner_id: String = "") -> void:
	var dial_v: Variant = dial_of(owner_id)
	if dial_v == null:
		return
	var dial: Dictionary = dial_v
	var movement: Variant = dial["movement"]
	if movement == null or movement["archetype"] != "recharge" or movement["tier"] < 5:
		return

	dial["combatRegenTurnCounter"] = dial.get("combatRegenTurnCounter", 0) + 1
	if dial["combatRegenTurnCounter"] >= GameData.DIAL_RECHARGE_COMBAT_REGEN_TURNS:
		dial["combatRegenTurnCounter"] = 0
		dial["currentCharge"] = minf(dial["maxCharge"], dial["currentCharge"] + GameData.DIAL_RECHARGE_COMBAT_REGEN_AMOUNT)

	EventBus.state_changed.emit()
