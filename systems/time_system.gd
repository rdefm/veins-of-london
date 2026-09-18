class_name TimeSystem
extends RefCounted

# Time blocks, rest, and the daily tick per R§3.1. Static funcs only.

const BLOCKS_PER_DAY := 3
const DAILY_COST_BASE := 50.0
const REST_HEAL_FRACTION := 0.2
const PASSIVE_REGEN_FRACTION := 0.05
const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")


static func advance_time_block() -> void:
	var world: Dictionary = GameState.state["world"]
	var source := { "day": world["day"], "phase": world["timeBlock"] }
	world["timeBlocksDone"].append(world["timeBlock"])
	world["timeBlock"] += 1
	if world["timeBlock"] >= BLOCKS_PER_DAY:
		world["day"] += 1
		world["timeBlock"] = 0
		world["timeBlocksDone"] = []
		world["currentDistrict"] = "shoreditch"
		daily_tick()
	EventBus.time_advanced.emit(source, { "day": world["day"], "phase": world["timeBlock"] })
	EventBus.state_changed.emit()


static func is_time_exhausted() -> bool:
	var world: Dictionary = GameState.state["world"]
	return world["timeBlocksDone"].size() >= BLOCKS_PER_DAY


# Consumes all remaining blocks, rolls to the next day (running
# daily_tick), then heals the player 20% of hpMax, capped at hpMax.
static func do_rest() -> void:
	var world: Dictionary = GameState.state["world"]
	var source := { "day": world["day"], "phase": world["timeBlock"] }
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
	EventBus.time_advanced.emit(source, { "day": world["day"], "phase": world["timeBlock"] })
	EventBus.state_changed.emit()


# Exact step order per R§3.1 — do not reorder without checking each inline
# note below for a real dependency (income before spend, claims before
# vein-derived income, etc.); several steps are independent and placed
# only by landing order.
static func daily_tick() -> void:
	var morning_context: Dictionary = MorningAccountsSystem.begin_rollover()
	RelationAccrual.reset_daily_caps()
	Barometer.tick()                     # ① barometer
	Home.roll_daily_raid()               # ② home raid
	MorningAccountsSystem.capture_losses(morning_context, "HQ raid")
	Jobs.expire_overdue_job()            # ②b before the fresh roll below, so an expired slot can be re-offered the same day
	MorningAccountsSystem.capture_job_expiry(morning_context)
	Jobs.roll_daily_offer()              # ②c
	ArchieDeals.roll_daily_offer()       # ②d
	_apply_living_costs()                # ③ living costs
	_apply_healing_salve_tick()          # ③b Healing Salve HoT, right after living costs
	_apply_passive_regen()               # ③c stacks with the Salve HoT rather than replacing it
	Cultivating.drift_veins()             # ④ vein growth drift (player + faction) — faction veins also die here on collapse-at-zero
	MorningAccountsSystem.capture_losses(morning_context, "Vein collapse")
	_apply_tutorial_day_triggers()       # ⑤ tutorial day-triggers
	Sites.roll_npc_claims()              # ⑤b NPC site-claiming (M1-LONDON.md D2)
	Sites.roll_faction_vein_growth()     # ⑤c faction vein daily growth, right after ⑤b
	Factions.apply_passive_income()      # ⑤d industries-only, no ordering dependency on ⑤b/⑤c
	Factions.apply_vein_income()         # ⑤e after ⑤c so a same-tick-claimed vein reuses ⑤c's claimedOnDay skip
	Factions.apply_security_upgrades()   # ⑤f after ⑤e so a tick's vein income is already banked and spendable
	Factions.apply_rivalry_resolution()  # ⑤g after ⑤f so income/spend is settled before any vein changes hands
	Raiding.apply_raid_resolution()      # ⑤h independent of ⑤d-⑤g (player veins/sites, not faction resources)
	MorningAccountsSystem.capture_losses(morning_context, "Raid")
	Collective.maybe_trigger_hakim_intel()  # ⑤i no ordering dependency on any other step
	Factions.maybe_restock_ore()         # ⑤j no ordering dependency on any other step
	Payroll.pay_wages()                  # ⑥ staff phase start: wages, paid after living costs -- an unaffordable role is skipped this rollover, no debt, retried next
	Rooms.process_vein_station()         # ⑥.1 Procurement, before Production so Sales (⑥.3) sees both yields landed
	MorningAccountsSystem.capture_vein_station(morning_context)
	Rooms.process_lab()                  # ⑥.2 Production crafts effective targets
	MorningAccountsSystem.capture_lab(morning_context)
	ContractsSystem.process_delegated_deliveries() # ⑥.3 Sales closes full periods, then allocates partial stock by priority
	ContractsSystem.daily_tick()         # ⑥.4 due periods settle; recurring periods renew
	OffersSystem.daily_tick()            # ⑥.5 expiry, then Sales sources at most one new random offer
	Dial.daily_regen()                   # ⑦ Dial charge regen
	Objectives.refresh()                 # ⑧ objectives boundary
	MorningAccountsSystem.finish_rollover(morning_context)
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
	# cost, so the ledger stays accurate.
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
		# Queued exactly once (archieBuyerSmsQueued guards re-entry); no separate
		# Notify banner — the queued text itself is the "Archie texted" beat.
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
