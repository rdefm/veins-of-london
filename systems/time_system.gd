class_name TimeSystem
extends RefCounted

# Time blocks, rest, and the daily tick per R§3.1. Static funcs only.

const BLOCKS_PER_DAY := 3
const DAILY_COST_BASE := 50.0
const REST_HEAL_FRACTION := 0.2


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

	Notify.push("Rested. Day %d. +%d HP." % [world["day"], actual_heal])
	EventBus.state_changed.emit()


# Exact step order per R§3.1, extended by M1-LONDON.md D2 / adr/0002
# (steps ⑤b/⑤c) and faction-vein-ownership T02 (step ⑤d) — do not reorder.
# Steps for systems that don't exist yet are stubs; wire the real call in
# when that task lands.
static func daily_tick() -> void:
	Barometer.tick()                     # ① barometer
	Home.roll_daily_raid()               # ② home raid
	_apply_living_costs()                # ③ living costs
	Cultivating.recharge_veins()         # ④ vein recharge
	_apply_tutorial_day_triggers()       # ⑤ tutorial day-triggers
	Sites.roll_npc_claims()              # ⑤b NPC site-claiming (M1-LONDON.md D2)
	Sites.roll_npc_abandonment()         # ⑤c NPC abandonment (adr/0002), runs right after ⑤b
	Sites.roll_faction_vein_growth()     # ⑤d faction vein daily growth (faction-vein-ownership T02), runs right after ⑤c
	Rooms.process_lab()                  # ⑥ rooms (lab, then veinStation)
	Rooms.process_vein_station()
	Devices.reset_daily_charges()        # ⑦ device charge reset
	EventBus.day_ticked.emit(GameState.state["world"]["day"])
	SaveManager.autosave()               # R§6: autosave on every daily tick


static func _apply_living_costs() -> void:
	var player: Dictionary = GameState.state["player"]
	var fx: Dictionary = Barometer.get_merged_effects()
	var daily_cost: int = GameState.round_epsilon(DAILY_COST_BASE * (1.0 + fx.get("dailyCost", 0.0)))
	player["cash"] = maxi(0, player["cash"] - daily_cost)

	var text := "Day %d: -£%d living costs." % [GameState.state["world"]["day"], daily_cost]
	if player["cash"] == 0:
		text += " You are flat broke."
	Notify.push(text)


static func _apply_tutorial_day_triggers() -> void:
	var world: Dictionary = GameState.state["world"]
	var flags: Dictionary = GameState.state["flags"]
	var day: int = world["day"]

	if day >= 2 and flags["tutorialStage"] == "buyer_event" and not flags["buyerEventSeen"]:
		Notify.push("Archie texted. He's lined up the new buyer. Check Contacts.")

	var unlock_day = world["archieChatUnlockDay"]
	if flags["tutorialStage"] == "archie_craft_chat" and unlock_day != null and day >= unlock_day:
		Notify.push("Archie wants to meet up. Check Contacts.")
