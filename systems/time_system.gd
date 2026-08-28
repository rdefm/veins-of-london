class_name TimeSystem
extends RefCounted

# Time blocks, rest, and the daily tick per R§3.1. Static funcs only.

const BLOCKS_PER_DAY := 3
const DAILY_COST_BASE := 50.0
const REST_HEAL_FRACTION := 0.2
const PASSIVE_REGEN_FRACTION := 0.05


static func advance_time_block() -> void:
	var world: Dictionary = GameState.state["world"]
	world["timeBlocksDone"].append(world["timeBlock"])
	world["timeBlock"] += 1
	if world["timeBlock"] >= BLOCKS_PER_DAY:
		world["day"] += 1
		world["timeBlock"] = 0
		world["timeBlocksDone"] = []
		world["currentDistrict"] = "shoreditch"
		daily_tick()
	EventBus.state_changed.emit()


static func is_time_exhausted() -> bool:
	var world: Dictionary = GameState.state["world"]
	return world["timeBlocksDone"].size() >= BLOCKS_PER_DAY


# Consumes all remaining blocks, rolls to the next day (running
# daily_tick), then heals the player 20% of hpMax, capped at hpMax.
static func do_rest() -> void:
	var world: Dictionary = GameState.state["world"]
	world["day"] += 1
	world["timeBlock"] = 0
	world["timeBlocksDone"] = []
	world["currentDistrict"] = "shoreditch"
	daily_tick()

	var player: Dictionary = GameState.state["player"]
	var heal: int = GameState.round_epsilon(player["hpMax"] * REST_HEAL_FRACTION)
	var old_hp: int = player["hp"]
	player["hp"] = mini(old_hp + heal, player["hpMax"])
	var actual_heal: int = player["hp"] - old_hp

	Notify.push("Rested. Day %d. +%d HP." % [world["day"], actual_heal], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()


# Exact step order per R§3.1, extended by M1-LONDON.md D2 (step ⑤b),
# faction-vein-ownership T02 (step ⑤c), and faction-resource-economy
# T02/T03/T04 (steps ⑤d/⑤e/⑤f) — do not reorder.
# bugfixes-42 adds step ③c, right after ③b (Healing Salve HoT): always-on
# passive HP regen, independent of and stacking with both Rest and the
# Salve HoT rather than replacing either.
# faction-territory-rivalry T04 adds step ⑤g, running last in the chain: it
# runs after ⑤f (security upgrades) so a rivalry resolving this tick sees
# the day's income already earned and spend already committed before any
# vein changes hands, and after ⑤c (faction vein growth) so a same-tick
# freshly-claimed vein is a legitimate rivalry target/target-owner by the
# time ⑤g runs, same as it already is for ⑤d-⑤f's income/spend reads.
# vein-raiding T06 adds step ⑤h, right after ⑤g: a faction raiding one of
# the player's own veins is independent of the ⑤d-⑤g faction-economy chain
# (it reads/writes player.veins and a target site, not faction resources),
# so ordering relative to ⑤g doesn't matter causally -- placed last per
# landing order, same as ⑤g was appended after ⑤f.
# collective1-17 adds step ⑤i, right after ⑤h: Hakim's repeatable intel
# roll only reads siteCap/site counts and Messages/collective state, no
# ordering dependency on any other step -- placed last per landing order,
# same as ⑤g/⑤h were.
# bugfixes-40 removed the old step ⑤c, NPC-abandonment (adr/0002's
# independent daily kill roll for faction-claimed sites, stacked on top of
# the growth-collapse-at-zero roll every vein already faces) — faction
# veins now only die via Cultivating.drift_veins()'s own collapse roll at
# step ④, same as player veins. Every step from the old ⑤d onward shifted
# up one letter to close the gap; see adr/0004.
# Steps for systems that don't exist yet are stubs; wire the real call in
# when that task lands.
static func daily_tick() -> void:
	RelationAccrual.reset_daily_caps()   # collective1-06: relation-accrual daily cap reset, no ordering dependency on any other step
	Barometer.tick()                     # ① barometer
	Home.roll_daily_raid()               # ② home raid
	Jobs.expire_overdue_job()            # ②b James job deadline expiry (bugfixes-30), runs before the fresh roll below so an expired slot can be re-offered the same day
	Jobs.roll_daily_offer()              # ②c James job proactive daily offer roll (bugfixes-30), no ordering dependency on any other step
	_apply_living_costs()                # ③ living costs
	_apply_healing_salve_tick()          # ③b Healing Salve HoT (calc-effect-wiring-02), runs right after living costs
	_apply_passive_regen()               # ③c passive HP regen (bugfixes-42), runs right after the Salve HoT, stacks with it
	Cultivating.drift_veins()             # ④ vein growth drift (player + faction veins) — also where a faction vein's collapse-at-zero death rolls, since bugfixes-40
	_apply_tutorial_day_triggers()       # ⑤ tutorial day-triggers
	Sites.roll_npc_claims()              # ⑤b NPC site-claiming (M1-LONDON.md D2)
	Sites.roll_faction_vein_growth()     # ⑤c faction vein daily growth (faction-vein-ownership T02), runs right after ⑤b
	Factions.apply_passive_income()      # ⑤d faction passive/industry income (faction-resource-economy T02), runs right after ⑤c — no ordering dependency on ⑤b/⑤c (industries-only, no site/vein reads)
	Factions.apply_vein_income()         # ⑤e faction vein-derived income (faction-resource-economy T03), runs right after ⑤d — after ⑤c so a same-tick-claimed vein reuses ⑤c's claimedOnDay skip
	Factions.apply_security_upgrades()   # ⑤f faction security-upgrade spend (faction-resource-economy T04), runs right after ⑤e so a tick's vein income is already banked and spendable the same day it's earned
	Factions.apply_rivalry_resolution()  # ⑤g faction-territory-rivalry attempt roll + resolution (faction-territory-rivalry T04), runs right after ⑤f so a tick's income/spend is already settled before any vein changes hands
	Raiding.apply_raid_resolution()      # ⑤h Direction-B raid attempt roll + resolution (vein-raiding T06), runs right after ⑤g
	Collective.maybe_trigger_hakim_intel()  # ⑤i Hakim's repeatable intel roll (collective1-17), runs right after ⑤h
	Rooms.process_lab()                  # ⑥ rooms (lab, then veinStation)
	Rooms.process_vein_station()
	Dial.daily_regen()                   # ⑦ dial-device ticket 07: Dial charge regen (replaces Devices.reset_daily_charges())
	Objectives.refresh()                 # ⑧ collective1-02: objectives boundary
	EventBus.day_ticked.emit(GameState.state["world"]["day"])
	SaveManager.autosave()               # R§6: autosave on every daily tick


static func _apply_living_costs() -> void:
	var player: Dictionary = GameState.state["player"]
	var fx: Dictionary = Barometer.get_merged_effects()
	var daily_cost: int = GameState.round_epsilon(DAILY_COST_BASE * (1.0 + fx.get("dailyCost", 0.0)))
	var cash_before: int = player["cash"]
	player["cash"] = maxi(0, cash_before - daily_cost)
	# The floor-at-0 clamp means a broke player's actual deduction can be
	# less than daily_cost -- log what was really taken, not the nominal
	# cost, so the ledger stays accurate (bugfixes-38: "a complete, accurate
	# record from turn one, not a partial one").
	var actual_deducted: int = cash_before - player["cash"]
	if actual_deducted > 0:
		Bank.record(-actual_deducted, "Living costs")

	var text := "Day %d: -£%d living costs." % [GameState.state["world"]["day"], daily_cost]
	var category := Notify.CATEGORY_INFO
	if player["cash"] == 0:
		text += " You are flat broke."
		category = Notify.CATEGORY_WARNING
	Notify.push(text, category)


static func _apply_healing_salve_tick() -> void:
	var player: Dictionary = GameState.state["player"]
	if player["healingSalveDaysLeft"] <= 0:
		return

	var healed: int = mini(player["healingSalveDailyAmount"], player["hpMax"] - player["hp"])
	player["hp"] += healed
	player["healingSalveDaysLeft"] -= 1
	if healed > 0:
		# PROSE-REVIEW: new daily-tick salve notification, drafted against CONTENT-GUIDE.md's tone bible.
		Notify.push("The salve does its work. +%d HP." % healed, Notify.CATEGORY_SUCCESS)


# Always-on passive regen, unconditional (no flag/room gate), stacking with
# both Rest and the Healing Salve HoT rather than replacing either.
static func _apply_passive_regen() -> void:
	var player: Dictionary = GameState.state["player"]
	var heal: int = mini(GameState.round_epsilon(player["hpMax"] * PASSIVE_REGEN_FRACTION), player["hpMax"] - player["hp"])
	if heal <= 0:
		return

	player["hp"] += heal
	# PROSE-REVIEW: new daily-tick passive-regen notification, drafted against CONTENT-GUIDE.md's tone bible.
	Notify.push("You rest easy. +%d HP." % heal, Notify.CATEGORY_SUCCESS)


static func _apply_tutorial_day_triggers() -> void:
	var world: Dictionary = GameState.state["world"]
	var flags: Dictionary = GameState.state["flags"]
	var day: int = world["day"]

	if day >= 2 and flags["tutorialStage"] == "buyer_event" and not flags["buyerEventSeen"]:
		# 83-contacts-archie-james-sms-port: ARCHIE_SMS_2's content, queued
		# exactly once (archieBuyerSmsQueued guards this still re-entering
		# every day tick until buyerEventSeen). No separate Notify banner --
		# same reasoning Economy.execute_sale's own archie_motion trigger
		# comment gives: the queued text itself is the "Archie texted" beat
		# (unread badge on the Messages tile/Archie's card), same as every
		# other queue_pending_message caller (archie_cultivation.json's
		# col_a1_intro, col_a1_seeding.json's col_a1_hub) never pairs one
		# with a notify op. push_message's lines are the thread up to
		# Archie's last one; that last line becomes the pendingMessages
		# entry itself (kind "buyer").
		if not flags["archieBuyerSmsQueued"]:
			flags["archieBuyerSmsQueued"] = true
			Messages.append("archie", "player", "Got some calc to move. You got a buyer?")
			Messages.append("archie", "them", "Yeah give me a day or two. What type and how much?")
			Messages.append("archie", "player", "Mixed. Maybe fifteen units.")
			Messages.append("archie", "them", "Sorted. I'll bell you. Don't go anywhere daft in the meantime.")
			Messages.queue_pending("archie", "buyer", "Actually — you free tonight? Got someone lined up already. Shoreditch. Easy job.")

	var unlock_day = world["archieChatUnlockDay"]
	if flags["tutorialStage"] == "archie_craft_chat" and unlock_day != null and day >= unlock_day:
		Notify.push("Archie wants to meet up. Check Contacts.")
