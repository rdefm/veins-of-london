extends RefCounted

# Body of scripts/profile_block_end.gd (see there for usage).

var _totals := {}


func run(opts: Dictionary) -> void:
	GameState.reset()
	Rng.set_seed(opts["seed"])
	Factions.seed_day_one_veins()
	for i in int(opts["warm"]):
		GameState.state["world"]["day"] += 1
		TimeSystem.daily_tick()
	GameState.state["world"]["timeBlock"] = 0
	GameState.state["world"]["timeBlocksDone"] = []
	var reps: int = opts["reps"]
	var state_bytes: int = JSON.stringify(GameState.state).length()
	print("== warm %d days, state %d bytes, state_changed listeners %d ==" % [opts["warm"], state_bytes, EventBus.state_changed.get_connections().size()])
	for r in reps:
		_t("run_staff_block", func(): TimeSystem.run_staff_block())
		_t("advance_time_block(mid)", func(): TimeSystem.advance_time_block())
		_t("advance_time_block(mid2)", func(): TimeSystem.advance_time_block())
		_t("advance_time_block(rollover)", func(): TimeSystem.advance_time_block())
		_t("do_rest", func(): TimeSystem.do_rest())
		_t("autosave", func(): SaveManager.autosave())
		_t("json_stringify", func(): JSON.stringify(GameState.state))
		_t("state_duplicate", func(): GameState.state.duplicate(true))
	for k in _totals:
		print("%-34s %8.2f ms avg" % [k, _totals[k] / reps])
	print("-- daily_tick steps --")
	_totals.clear()
	for r in reps:
		GameState.state["world"]["day"] += 1
		_profile_daily_tick()
	for k in _totals:
		print("%-34s %8.2f ms avg" % [k, _totals[k] / reps])


func _t(label: String, fn: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	fn.call()
	_totals[label] = float(_totals.get(label, 0.0)) + (Time.get_ticks_usec() - t0) / 1000.0


func _profile_daily_tick() -> void:
	var ctx: Dictionary = MorningAccountsSystem.begin_rollover()
	_t("Barometer.tick", func(): Barometer.tick())
	_t("Home.roll_daily_raid", func(): Home.roll_daily_raid())
	_t("Jobs+Archie offers", func(): Jobs.expire_overdue_job(); Jobs.roll_daily_offer(); ArchieDeals.roll_daily_offer())
	_t("Cultivating.drift_veins", func(): Cultivating.drift_veins())
	_t("Sites.roll_npc_claims", func(): Sites.roll_npc_claims())
	_t("Factions.apply_rivalry+raid", func(): Factions.apply_rivalry_resolution(); Raiding.apply_raid_resolution())
	_t("FactionSim.tend_and_prune", func(): FactionSim.tend_and_prune())
	_t("FactionSim.craft", func(): FactionSim.craft())
	_t("FactionSim.consume", func(): FactionSim.consume())
	_t("FactionSim.allocate_kits", func(): FactionSim.allocate_kits())
	_t("FactionSim.trade", func(): FactionSim.trade())
	_t("Factions income/upgrades", func(): Factions.apply_passive_income(); Factions.apply_security_upgrades())
	_t("Collective triggers", func(): Collective.maybe_trigger_hakim_intel(); Collective.maybe_trigger_act2_intro())
	_t("Rooms.trim+Contracts", func(): Rooms.trim_production_log(); ContractsSystem.process_daily_sales(); ContractsSystem.daily_tick())
	_t("Business.daily_tick", func(): Business.daily_tick())
	_t("BusinessStats.capture_day", func(): BusinessStats.capture_day())
	_t("Offers+BusinessQuest", func(): OffersSystem.daily_tick(); BusinessQuest.maybe_issue_starter(); BusinessQuest.maybe_issue_recurring())
	_t("Shares.roll+record", func(): Shares.roll_buckets(); Shares.record_independents())
	_t("FactionAI.pressure/stances/wars", func(): FactionAI.apply_pressure(); FactionAI.update_stances(); FactionAI.update_wars())
	_t("FactionAI.stabilise/squeeze/pos", func(): FactionAI.stabilise(); FactionAI.squeeze_wars(); FactionAI.run_positions())
	_t("FactionAI.apply_escalation", func(): FactionAI.apply_escalation())
	_t("Intel+Diplomacy+Partners", func(): Intel.decay(); Intel.expire_timers(); Diplomacy.daily_tick(); Partners.daily_tick())
	_t("Hiring ticks", func(): Hiring.roll_market_flips(); Hiring.daily_poach_tick())
	_t("Market.daily_reprice", func(): Market.daily_reprice())
	_t("Dial+Objectives", func(): Dial.daily_regen(); Objectives.refresh())
	_t("ContactTexts.daily_tick", func(): ContactTexts.daily_tick())
	_t("finish_rollover", func(): MorningAccountsSystem.finish_rollover(ctx))
	_t("SaveManager.autosave", func(): SaveManager.autosave())


const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")
