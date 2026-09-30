class_name TimeSystem
extends RefCounted

# Time blocks, rest, and the daily tick per R§3.1. Static funcs only.

const BLOCKS_PER_DAY := 3
const REST_HEAL_FRACTION := 0.2
const PASSIVE_REGEN_FRACTION := 0.05
const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")


static func advance_time_block() -> void:
	var world: Dictionary = GameState.state["world"]
	var source := { "day": world["day"], "phase": world["timeBlock"] }
	run_staff_block()
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


# Consumes all remaining blocks (running the staff block step for each, so a
# day always yields BLOCKS_PER_DAY staff actions), rolls to the next day
# (running daily_tick), then heals the player 20% of hpMax, capped at hpMax.
static func do_rest() -> void:
	var world: Dictionary = GameState.state["world"]
	var source := { "day": world["day"], "phase": world["timeBlock"] }
	for i in BLOCKS_PER_DAY - world["timeBlock"]:
		run_staff_block(world["timeBlock"] + i)
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

	Notify.push("Rested. %s. +%d HP." % [Calendar.format_day(world["day"]),actual_heal], Notify.CATEGORY_SUCCESS)
	EventBus.time_advanced.emit(source, { "day": world["day"], "phase": world["timeBlock"] })
	EventBus.state_changed.emit()


# R§3.10 "Staff block step": staffed cultivators and producers act at the
# end of every time block, before any rollover. block defaults to
# world.timeBlock; do_rest() passes each skipped block's index.
static func run_staff_block(block: int = -1) -> void:
	var ore_before: Dictionary = MorningAccountsSystem.ore_snapshot()
	MorningAccountsSystem.record_block(Rooms.process_staff_block(block), ore_before)
	ContractsSystem.process_sales_deliveries()  # R§3.10 "Sales delivery": after the staff step
	BusinessQuest.maybe_trigger_partnership()  # Beat 4 can be met by a staff level-up


# Exact step order per R§3.1 — do not reorder without checking each inline
# note below for a real dependency (income before spend, claims before
# faction tending, etc.); several steps are independent and placed
# only by landing order.
static func daily_tick() -> void:
	var morning_context: Dictionary = MorningAccountsSystem.begin_rollover()
	RelationAccrual.reset_daily_caps()
	Barometer.tick()                     # ① barometer
	MorningAccountsSystem.capture_guard_resolution(morning_context, GuardUpkeep.resolve_due_shortfall())  # ①b a guard shortfall past its grace day resolves before ②, so walked guards don't defend today
	Home.roll_daily_raid()               # ② home raid
	MorningAccountsSystem.capture_losses(morning_context, "HQ raid")
	Jobs.expire_overdue_job()            # ②b before the fresh roll below, so an expired slot can be re-offered the same day
	MorningAccountsSystem.capture_job_expiry(morning_context)
	Jobs.roll_daily_offer()              # ②c
	ArchieDeals.roll_daily_offer()       # ②d
	var bill_result: Dictionary = _apply_living_costs()  # ③ living costs, Mondays only
	MorningAccountsSystem.capture_bills(morning_context, bill_result)
	_apply_healing_salve_tick()          # ③b Healing Salve HoT, right after living costs
	_apply_passive_regen()               # ③c stacks with the Salve HoT rather than replacing it
	Cultivating.drift_veins()             # ④ vein growth drift (player + faction) — faction veins also die here on collapse-at-zero
	MorningAccountsSystem.capture_losses(morning_context, "Vein collapse")
	_apply_tutorial_day_triggers()       # ⑤ tutorial day-triggers
	Sites.roll_npc_claims()              # ⑤b NPC site-claiming (M1-LONDON.md D2)
	Factions.apply_rivalry_resolution()  # ⑤c yesterday's queued faction raids (⑥.5h); after ⑤b; before ⑤h/⑤j so it reads end-of-yesterday resources
	Raiding.apply_raid_resolution()      # ⑤d before ⑤g so its kit burns come out of today's consume
	MorningAccountsSystem.capture_losses(morning_context, "Raid")
	FactionSim.tend_and_prune()          # ⑤e after ⑤b-⑤d so today's claims and ownership changes are tended
	FactionSim.craft()                   # ⑤f after ⑤e so today's prune ore can be crafted
	FactionSim.consume()                 # ⑤g after ⑤c/⑤d so today's kit burns are drawn; after ⑤f so today's crafts can cover them
	FactionSim.allocate_kits()           # ⑤g2 after ⑤g so kits reflect post-consumption holdings
	FactionSim.trade()                   # ⑤g3 after ⑤g2 so reserved vein kits aren't sold; before ⑤h/⑤j so buys spend yesterday's cash first
	Factions.apply_passive_income()      # ⑤h industries-only, no ordering dependency on ⑤b-⑤g
	GuardUpkeep.pay_faction_monday_bills()  # ⑤h2 faction Monday guard bill: after ⑤h so it sees today's income, before ⑤j so upgrades spend post-wage cash
	NetworkHandler.expire_intel()        # ⑤i before ⑤j so a lapsed security_freeze stops skipping today's upgrade
	Factions.apply_security_upgrades()   # ⑤j after ⑤h so today's income is already banked and spendable
	Collective.maybe_trigger_hakim_intel()  # ⑤k no ordering dependency on any other step
	Collective.maybe_trigger_act2_intro()   # ⑤k2 backstop for the same trigger events.advance() already checks
	BusinessQuest.maybe_trigger_proposition()  # ⑤k3 backstop for the vein-count-change checks (catches today's self-seed)
	Payroll.pay_wages()                  # ⑥ staff phase start: Monday room wages, paid after living costs -- an unaffordable role idles until paid or next Monday, no debt
	MorningAccountsSystem.capture_production_shortfalls(morning_context)  # ⑥.1 unmet Production targets; staff work itself runs per block in run_staff_block()
	Rooms.trim_production_log()          # ⑥.2 drop production-log days older than the retention window
	ContractsSystem.process_daily_sales() # ⑥.3 Sales buys flagged calc shortfalls, closes full periods, then allocates partial stock by priority
	ContractsSystem.daily_tick()         # ⑥.4 due periods settle; recurring periods renew
	MorningAccountsSystem.capture_guard_wages(morning_context, GuardUpkeep.pay_monday_bill())  # ⑥.4a player Monday guard bill (pot not active); before ⑥.4c so its expense lands in the ended day
	MorningAccountsSystem.capture_business(morning_context, Business.daily_tick())  # ⑥.4b after ⑥.4 so payday banks today's settlements; with the pot active, payday pays the Monday guard bill after staff wages
	FactionAI.settle_truce_payments()    # ⑥.4b2 truce weekly payments, Mondays only, with the week's other bills; before ⑥.4c so they land in the ended day
	BusinessStats.capture_day()          # ⑥.4c after ⑥.4b so the ended day's snapshot includes this rollover's settlements and payday wages
	OffersSystem.daily_tick()            # ⑥.5 expiry, then Sales sources at most one new random offer
	BusinessQuest.maybe_issue_starter()  # ⑥.5b after ⑥.5's expiry; outside the random roll and its slot
	BusinessQuest.maybe_issue_recurring()  # ⑥.5c recurring-offer reissues, after ⑥.5b so the starter chain goes first
	Shares.roll_buckets()                # ⑥.5d drop share buckets past the 14-day window, before ⑥.6 reads supply
	Shares.record_independents()         # ⑥.5e credit today's Independents slice, after ⑥.5d so it lands in a kept bucket
	FactionAI.apply_pressure()           # ⑥.5f threat/dependence drift, after ⑥.5d/⑥.5e so it reads today's shares; before ⑥.6
	FactionAI.update_stances()           # ⑥.5g after ⑥.5f so stances read today's drifted relation; before ⑥.6
	FactionAI.update_wars()              # ⑥.5g2 after ⑥.5g so wars read today's stances and ⑤c/⑤d's raids; before ⑥.5h
	FactionAI.stabilise()                # ⑥.5g3 Conclave stabiliser, after ⑥.5g2 and before ⑥.5h; its trades land in ⑥.6
	FactionAI.squeeze_wars()             # ⑥.5g4 Conclave war squeeze, after ⑥.5g2 so it reads today's wars; its trades land in ⑥.6
	FactionAI.run_positions()            # ⑥.5g5 Conclave positions, before ⑥.5h so its push cooldown gates tickerPush; trades land in ⑥.6, pushes at the next ①
	FactionAI.apply_escalation()         # ⑥.5h after ⑥.5g so bands read today's stances; raids it queues resolve at the next ⑤c/⑤d
	NetworkHandler.faction_purchases()   # ⑥.5h2 faction intel purchases, after ⑥.5h so bands and the Network's gouges are today's
	Intel.decay()                        # ⑥.5i intel decay, after ⑥.5h2
	Intel.expire_timers()                # ⑥.5i2 drop lapsed privacy/raid-warning/disinformation timers; reads check the day anyway
	Diplomacy.daily_tick()               # ⑥.5j favours: settle guard/sit-out watches, withdraw lapsed requests, issue new ones; after ⑥.5g2 so war state is today's
	Market.daily_reprice()               # ⑥.6 London reprice, after every step that trades in the tick and after ① so today's Ticker feeds it
	Dial.daily_regen()                   # ⑦ Dial charge regen
	Contacts.daily_dial_regen()          # ⑦.1 ally Dial charges refill
	Objectives.refresh()                 # ⑧ objectives boundary
	Collective.maybe_trigger_a2_checkpoint()  # ⑧a after ⑧ so an NPC-claimed reseed counts; also the day-threshold fallback
	Collective.maybe_trigger_a2_crack()       # ⑧b T10/T11, a day or more behind the beat before each
	Collective.maybe_trigger_a2_closer()      # ⑧c T15, before ⑧d so it trails T14 by a day or more
	Collective.maybe_trigger_a2_spine_reward()  # ⑧d T14 backstop once relation accrues past the gate
	BusinessQuest.maybe_trigger_owen_intro()   # ⑧e backstop for the settle/event-completion checks
	BusinessQuest.maybe_trigger_partnership()  # ⑧f backstop for the staff-block/room-build checks
	BusinessQuest.maybe_trigger_production()   # ⑧g backstop for the event-completion check
	BusinessQuest.maybe_trigger_put_to_work()  # ⑧g1 backstop for the settle/event-completion checks
	BusinessQuest.maybe_trigger_owen_craft()     # ⑧g2 Owen's crafting event, not an Act 1 beat
	OwenTexts.daily_tick()                       # ⑧g3 after ⑥'s payroll/payday so the working check is today's
	BusinessQuest.maybe_trigger_closing()      # ⑧h after ⑥.4b's payday record
	MorningAccountsSystem.finish_rollover(morning_context)
	EventBus.day_ticked.emit(GameState.state["world"]["day"])
	SaveManager.autosave()               # R§6: autosave on every daily tick


# Home bill per ADR 0006 "Weekly ordering": on the rollover into a Monday
# only -- interest on carried arrears, pay arrears, pay the week's bill
# (Home.weekly_bill_base(), barometer-scaled), shortfall into arrears,
# advance the week clock, then the forced downgrade check. Cash never goes
# negative. Returns what happened for the morning account: { interest,
# shortfall, arrears, downgrade } (downgrade is {} unless one fired); on any
# other rollover nothing is charged and only the carried arrears come back.
#
# PROSE-REVIEW: the arrears and repossession lines below.
static func _apply_living_costs() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var home: Dictionary = GameState.state["home"]
	var bills: Dictionary = GameData.HOME_BILLS
	var day: int = GameState.state["world"]["day"]
	if not Calendar.is_monday(day):
		return { "interest": 0, "shortfall": 0, "arrears": home["arrears"], "downgrade": {} }

	var interest := 0
	if home["arrears"] > 0 and home["arrearsWeeks"] >= int(bills["interestThresholdWeeks"]):
		interest = GameState.round_epsilon(home["arrears"] * bills["interestRate"])
		home["arrears"] += interest

	var arrears_paid: int = mini(player["cash"], home["arrears"])
	player["cash"] -= arrears_paid
	home["arrears"] -= arrears_paid
	if arrears_paid > 0:
		Bank.record(-arrears_paid, "Arrears")

	var fx: Dictionary = Barometer.get_merged_effects()
	var bill: int = GameState.round_epsilon(Home.weekly_bill_base() * (1.0 + fx.get("dailyCost", 0.0)))
	var bill_paid: int = mini(player["cash"], bill)
	player["cash"] -= bill_paid
	if bill_paid > 0:
		Bank.record(-bill_paid, "Weekly living costs")
	var shortfall: int = bill - bill_paid
	home["arrears"] += shortfall

	if home["arrears"] == 0:
		home["arrearsWeeks"] = 0
	else:
		home["arrearsWeeks"] += 1

	var date: String = Calendar.format_day(day)
	var text := "%s: -£%d weekly living costs." % [date, bill_paid]
	if arrears_paid > 0:
		text = "%s: -£%d weekly living costs, -£%d off arrears." % [date, bill_paid, arrears_paid]
	var category := Notify.CATEGORY_INFO
	if interest > 0:
		text += " £%d interest added." % interest
	if shortfall > 0:
		text += " £%d short — owed £%d." % [shortfall, home["arrears"]]
		category = Notify.CATEGORY_WARNING
	elif home["arrears"] > 0:
		text += " Still owed £%d." % home["arrears"]
		category = Notify.CATEGORY_WARNING
	if player["cash"] == 0:
		text += " You are flat broke."
		category = Notify.CATEGORY_WARNING
	Notify.push(text, category)

	var arrears_after_bill: int = home["arrears"]
	var downgrade := {}
	if home["arrearsWeeks"] >= int(bills["downgradeThresholdWeeks"]):
		downgrade = _force_downgrade()
	return { "interest": interest, "shortfall": shortfall, "arrears": arrears_after_bill, "downgrade": downgrade }


# ADR 0006 step 5: drop one tier into a rented home. Losing an owned tier
# clears the debt; losing a rented one carries it. The clock restarts either
# way. No-op at the bedsit (step 6), returning {}; otherwise returns
# { fromTier, toTier, roomsLost, arrearsCleared, arrears }.
static func _force_downgrade() -> Dictionary:
	var home: Dictionary = GameState.state["home"]
	var prev_tier_id: String = Home.get_prev_tier_id(home["tier"])
	if prev_tier_id == "":
		return {}
	var from_tier_id: String = home["tier"]
	var lost_tier_name: String = GameData.HOME_TIERS[home["tier"]]["name"]
	var was_owned: bool = home["tenure"] == Home.TENURE_OWNED
	var result: Dictionary = Home.change_tier(prev_tier_id, Home.TENURE_RENTED)
	if was_owned:
		home["arrears"] = 0
	home["arrearsWeeks"] = 0

	var text := "The %s's gone for unpaid bills. You're in a rented %s now." % [lost_tier_name, GameData.HOME_TIERS[prev_tier_id]["name"]]
	if not result["roomsLost"].is_empty():
		text += " Rooms lost: %d." % result["roomsLost"].size()
	if was_owned:
		text += " The debt went with it."
	else:
		text += " You still owe £%d." % home["arrears"]
	Notify.push(text, Notify.CATEGORY_WARNING)
	return {
		"fromTier": from_tier_id, "toTier": prev_tier_id,
		"roomsLost": result["roomsLost"].size(), "arrearsCleared": was_owned,
		"arrears": home["arrears"],
	}


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
