extends "res://tests/test_base.gd"

# Lens crafting, load/unload (Dial) and the Lenses read layer (R§1.4 Lenses).

const HAFT_ID := "collective_brolly"
const CONTACT_ID := "james"


static func _setup(level: int = 1) -> void:
	GameState.reset()
	GameState.state["flags"]["dialGiftGranted"] = true
	var dial: Dictionary = Dial.new_dial(HAFT_ID)
	dial["level"] = level
	GameState.state["player"]["dial"] = dial


static func _give(ore: String, tier: int) -> void:
	GameState.state["player"]["lensInventory"].append({ "ore": ore, "tier": tier })


static func _give_contact_dial(level: int) -> void:
	var dial: Dictionary = Dial.new_dial(HAFT_ID)
	dial["level"] = level
	GameState.state["contacts"][CONTACT_ID]["dial"] = dial


# Re-runs a craft from the same snapshot over seeds until the wanted outcome; capped.
func _craft_until(ore: String, want_success: bool) -> Dictionary:
	var snapshot: Dictionary = GameState.deep_copy(GameState.state)
	for seed in range(500):
		GameState.state = GameState.deep_copy(snapshot)
		Rng.set_seed(seed)
		var result := Dial.attempt_craft_lens(ore)
		if result.get("ok", false) and result["success"] == want_success:
			return result
	return {}


func run() -> void:
	run_case("craft_refused_without_gift", func():
		_setup()
		GameState.state["flags"]["dialGiftGranted"] = false
		GameState.state["player"]["orichalchum"]["fate"] = 100
		var result := Dial.attempt_craft_lens("fate")
		assert_true(not result["ok"], "no gift, no lens")
		assert_eq(GameState.state["player"]["orichalchum"]["fate"], 100, "nothing spent")
	)

	run_case("craft_refused_without_calc_or_bad_ore", func():
		_setup()
		GameState.state["player"]["orichalchum"]["fate"] = 0
		assert_true(not Dial.attempt_craft_lens("fate")["ok"], "short of calc refused")
		GameState.state["player"]["orichalchum"]["fate"] = 100
		assert_true(not Dial.attempt_craft_lens("energy")["ok"], "unknown ore refused")
	)

	run_case("craft_success_spends_ore_and_adds_lens_at_skill_tier", func():
		_setup()
		GameState.state["player"]["craftingSkill"] = 3
		GameState.state["player"]["orichalchum"]["physics"] = 100
		var cost := Dial.lens_calc_cost(3)
		var result := _craft_until("physics", true)
		assert_true(not result.is_empty(), "found a succeeding seed")
		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 100 - cost, "lens ore spent")
		assert_eq(GameState.state["player"]["lensInventory"], [{ "ore": "physics", "tier": 3 }], "lens at crafting-skill tier")
	)

	run_case("craft_failure_still_spends_ore", func():
		_setup()
		GameState.state["player"]["orichalchum"]["life"] = 100
		var cost := Dial.lens_calc_cost(1)
		var result := _craft_until("life", false)
		assert_true(not result.is_empty(), "found a failing seed")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 100 - cost, "lens ore spent on failure")
		assert_eq(GameState.state["player"]["lensInventory"].size(), 0, "no lens on failure")
	)

	run_case("slot_count_follows_dial_level", func():
		var curve: Array = GameData.DIAL_LENS["lensSlotsByLevel"]
		for level in range(curve.size()):
			assert_eq(Dial.lens_slots(level), int(curve[level]), "slots at level %d" % level)
		assert_eq(Dial.lens_slots(1), 1, "level 1 has one slot")
		assert_eq(Dial.lens_slots(5), 3, "level 5 has three")
	)

	run_case("load_moves_lens_and_refuses_when_full", func():
		_setup(1)
		_give("time", 2)
		_give("fate", 1)
		assert_true(Dial.load_lens(0)["ok"], "first load fits")
		assert_eq(Lenses.loaded(), [{ "ore": "time", "tier": 2 }], "lens on the Dial")
		assert_eq(GameState.state["player"]["lensInventory"], [{ "ore": "fate", "tier": 1 }], "removed from inventory")
		assert_true(not Dial.load_lens(0)["ok"], "level 1 Dial has one slot")
		assert_eq(GameState.state["player"]["lensInventory"].size(), 1, "refused lens stays owned")
	)

	run_case("load_refuses_duplicate_ore", func():
		_setup(3)
		_give("time", 1)
		_give("time", 3)
		assert_true(Dial.load_lens(0)["ok"], "first time lens loads")
		assert_true(not Dial.load_lens(0)["ok"], "second time lens refused on same Dial")
	)

	run_case("load_and_unload_refused_in_event_or_combat", func():
		_setup(3)
		_give("emotion", 1)
		GameState.state["event"] = { "eventId": "x" }
		assert_true(not Dial.load_lens(0)["ok"], "refused mid-event")
		GameState.state["event"] = null
		assert_true(Dial.load_lens(0)["ok"], "loads outside events")
		GameState.state["combat"]["active"] = true
		assert_true(not Dial.unload_lens(0)["ok"], "unload refused mid-fight")
		assert_true(not Dial.load_lens(0)["ok"], "load refused mid-fight")
		GameState.state["combat"]["active"] = false
	)

	run_case("unload_returns_exact_unit", func():
		_setup(3)
		_give("physics", 4)
		_give("life", 2)
		Dial.load_lens(0)
		Dial.load_lens(0)
		assert_true(Dial.unload_lens(0)["ok"], "unload ok")
		assert_eq(GameState.state["player"]["lensInventory"], [{ "ore": "physics", "tier": 4 }], "same unit back")
		assert_eq(Lenses.loaded(), [{ "ore": "life", "tier": 2 }], "other lens stays loaded")
		assert_true(not Dial.unload_lens(5)["ok"], "bad slot refused")
	)

	run_case("lenses_queries_player", func():
		GameState.reset()
		assert_eq(Lenses.loaded(), [], "no Dial, no lenses")
		assert_eq(Lenses.tier_for("time"), 0, "no Dial tier 0")
		_setup(3)
		_give("fate", 3)
		Dial.load_lens(0)
		assert_eq(Lenses.tier_for("fate"), 3, "fate tier")
		assert_eq(Lenses.tier_for("time"), 0, "unloaded ore tier 0")
		assert_true(Lenses.has("fate"), "has fate")
		assert_true(not Lenses.has("time"), "no time")
	)

	run_case("lenses_queries_contact_dial", func():
		_setup(1)
		assert_true(GameState.state["contacts"].has(CONTACT_ID), "fixture contact exists")
		_give_contact_dial(2)
		_give("time", 1)
		assert_true(Dial.load_lens(0, CONTACT_ID)["ok"], "contact Dial loads via same function")
		assert_eq(Lenses.tier_for("time", CONTACT_ID), 1, "contact time lens")
		assert_true(Lenses.has("time", CONTACT_ID), "contact has time")
		assert_true(not Lenses.has("time"), "player Dial unaffected")
		_give("physics", 1)
		assert_true(not Dial.load_lens(0, CONTACT_ID)["ok"], "level 2 contact Dial has one slot")
		assert_true(Dial.unload_lens(0, CONTACT_ID)["ok"], "contact unload")
		assert_eq(GameState.state["player"]["lensInventory"].size(), 2, "back to player inventory")
	)

	run_case("sense_unlocked_by_gate_player_only", func():
		_setup(1)
		var gates: Dictionary = GameData.DIAL_LENS["senseGates"]
		GameState.state["player"]["senseSkill"] = 2
		assert_true(Lenses.sense_unlocked("world"), "Sense 2 opens world")
		assert_true(not Lenses.sense_unlocked("combat"), "Sense 2 below combat gate %d" % gates["combat"])
		GameState.state["player"]["senseSkill"] = 5
		for gate in gates:
			assert_true(Lenses.sense_unlocked(gate), "Sense 5 opens %s" % gate)
			assert_true(not Lenses.sense_unlocked(gate, CONTACT_ID), "contact never has Sense (%s)" % gate)
		assert_true(not Lenses.sense_unlocked("nope"), "unknown gate false")
	)

	run_case("swap_lens_replaces_in_place_and_returns_the_old_lens", func():
		_setup(1)
		_give("time", 1)
		Dial.load_lens(0)
		_give("life", 3)
		var r := Dial.swap_lens(0, 0)
		assert_true(r["ok"], "swap ok")
		assert_eq(Lenses.loaded(), [{ "ore": "life", "tier": 3 }], "new lens in the slot")
		assert_eq(GameState.state["player"]["lensInventory"], [{ "ore": "time", "tier": 1 }], "old lens back in inventory")
	)

	run_case("swap_lens_allows_same_ore_in_its_own_slot_but_not_another", func():
		_setup(3)
		_give("time", 1)
		_give("life", 1)
		Dial.load_lens(0)
		Dial.load_lens(0)
		_give("time", 4)
		assert_true(Dial.can_load_lens(0, "", 0)["ok"], "a time lens may replace the time lens")
		assert_true(not Dial.can_load_lens(0, "", 1)["ok"], "a time lens may not replace life while time is loaded")
		assert_true(not Dial.swap_lens(1, 0)["ok"], "swap refused")
		assert_eq(Lenses.tier_for("life"), 1, "life untouched")
		GameState.state["combat"]["active"] = true
		assert_true(not Dial.swap_lens(0, 0)["ok"], "swap refused mid-fight")
	)

	run_case("swap_complication_keeps_detent_and_returns_the_old_unit", func():
		_setup(2)
		var inv: Dictionary = GameState.state["player"]["inventory"]
		inv["timePearl"] = { "1": 1 }
		Dial.load_complication("timePearl", 1)
		inv["timePearl"] = { "3": 1 }
		var r := Dial.swap_complication(0, "timePearl", 3)
		assert_true(r["ok"], "swap ok")
		var entry: Dictionary = GameState.state["player"]["dial"]["loadedComplications"][0]
		assert_eq([entry["tier"], entry["detent"]], [3, 0], "new tier, same detent")
		assert_eq(inv["timePearl"].get("1", 0), 1, "old unit back in its tier bucket")
		assert_eq(inv["timePearl"].get("3", 0), 0, "new unit out of inventory")
		assert_true(not Dial.swap_complication(0, "timePearl", 5)["ok"], "nothing at tier 5 to swap in")
	)

	run_case("fate_all_rolls_bonus_by_tier_per_owner", func():
		_setup(2)
		assert_almost_eq(Lenses.fate_all_rolls_bonus(), 0.0, 0.0001, "no lens, no bonus")
		GameState.state["player"]["dial"]["lenses"] = [{ "ore": "time", "tier": 5 }]
		assert_almost_eq(Lenses.fate_all_rolls_bonus(), 0.0, 0.0001, "another ore gives none")
		var curve: Array = GameData.DIAL_LENS["fateAllRollsBonusByTier"]
		for tier in range(1, 6):
			GameState.state["player"]["dial"]["lenses"] = [{ "ore": "fate", "tier": tier }]
			assert_almost_eq(Lenses.fate_all_rolls_bonus(), float(curve[tier]), 0.0001, "tier %d" % tier)
		_give_contact_dial(2)
		assert_almost_eq(Lenses.fate_all_rolls_bonus(CONTACT_ID), 0.0, 0.0001, "the player's lens is not the contact's")
		GameState.state["contacts"][CONTACT_ID]["dial"]["lenses"] = [{ "ore": "fate", "tier": 2 }]
		assert_almost_eq(Lenses.fate_all_rolls_bonus(CONTACT_ID), float(curve[2]), 0.0001, "contact's own lens")
	)

	run_case("fate_lens_adds_a_labelled_mod_to_checks_and_covers_inside_the_clamp", func():
		_setup(1)
		var check := { "base": 0.5, "mods": [] }
		var plain := Events.odds_for(check)
		assert_almost_eq(float(plain["probability"]), 0.5, 0.0001, "no lens")
		assert_true(plain["mods"].is_empty(), "no Fate line without a lens")
		GameState.state["player"]["dial"]["lenses"] = [{ "ore": "fate", "tier": 5 }]
		var odds := Events.odds_for(check)
		assert_almost_eq(float(odds["probability"]), 0.55, 0.0001, "+tier bonus")
		assert_eq(odds["mods"].size(), 1, "one mod")
		assert_eq(odds["mods"][0]["label"], Lenses.fate_label(), "labelled Fate Lens")
		assert_almost_eq(float(Events.odds_for(check, [], false)["probability"]), 0.55, 0.0001, "cover rolls (lasting off) get it too")
		var high := { "base": 0.94, "mods": [] }
		assert_almost_eq(float(Events.odds_for(high)["probability"]), float(GameData.EVENT_CHECKS["defaultMax"]), 0.0001, "defaultMax still bounds it")
		var boosted_max := float(GameData.EVENT_CHECKS["itemBoostedMax"])
		assert_almost_eq(float(Events.odds_for({ "base": 0.95, "mods": [], "max": boosted_max })["probability"]), boosted_max, 0.0001, "itemBoostedMax still bounds it")
	)

	run_case("fate_lens_raises_craft_seed_and_lab_score", func():
		_setup(1)
		GameState.state["player"]["craftingSkill"] = 1
		var lens_plain := Dial.lens_craft_chance(1)
		var movement_plain := Dial.movement_craft_chance(Dial.MOVEMENT_ARCHETYPES[0], 1)
		var lab_plain := Lab.fate_boosted_score(60)
		GameState.state["player"]["dial"]["lenses"] = [{ "ore": "fate", "tier": 3 }]
		assert_almost_eq(Dial.lens_craft_chance(1), lens_plain + 0.03, 0.0001, "lens craft +bonus")
		assert_almost_eq(Dial.movement_craft_chance(Dial.MOVEMENT_ARCHETYPES[0], 1), movement_plain + 0.03, 0.0001, "movement craft +bonus")
		assert_eq([lab_plain, Lab.fate_boosted_score(60), Lab.fate_boosted_score(99)], [60, 63, 100], "Lab score +3 points, capped at 100")
		GameState.state["player"]["craftingSkill"] = 10
		assert_almost_eq(Dial.lens_craft_chance(10), 0.95, 0.0001, "0.95 still caps craft chance")
	)

	run_case("fate_shifted_weights_moves_bonus_from_lowest_tiers_to_top", func():
		var w := { "barren": 20.0, "poor": 30.0, "fair": 32.0, "rich": 14.0, "saturated": 4.0 }
		assert_eq(Sites.fate_shifted_weights(w, 0.0), w, "no bonus, unchanged")
		var shifted := Sites.fate_shifted_weights(w, 0.05)
		assert_almost_eq(float(shifted["barren"]), 15.0, 0.0001, "barren gives up 5% of 100")
		assert_almost_eq(float(shifted["saturated"]), 9.0, 0.0001, "saturated gains it")
		assert_almost_eq(float(shifted["poor"]), 30.0, 0.0001, "middle untouched")
		var thin := Sites.fate_shifted_weights({ "barren": 2.0, "poor": 48.0, "fair": 30.0, "rich": 16.0, "saturated": 4.0 }, 0.05)
		assert_eq([float(thin["barren"]), float(thin["poor"]), float(thin["saturated"])], [0.0, 45.0, 9.0], "spills to the next tier up")
		assert_almost_eq(float(w["barren"]), 20.0, 0.0001, "input not mutated")
	)

	run_case("fate_lens_raises_site_seed_chance_and_stacks_with_fate_attunement", func():
		_setup(1)
		var base := Sites.seed_success_chance(1, "poor")
		GameState.state["player"]["dial"]["lenses"] = [{ "ore": "fate", "tier": 2 }]
		var fate_bonus: float = float(GameData.DIAL_LENS["fateAllRollsBonusByTier"][2])
		var attune: float = float(GameData.DIAL_ATTUNEMENT_BONUS_BY_TIER[2])
		assert_almost_eq(Sites.seed_attempt_chance(1, "poor", "time"), minf(0.95, base + fate_bonus), 0.0001, "any ore +all-rolls bonus")
		assert_almost_eq(Sites.seed_attempt_chance(1, "poor", "fate"), minf(0.95, base + fate_bonus + attune), 0.0001, "fate site stacks both")
		assert_almost_eq(Sites.seed_attempt_chance(10, "saturated", "fate"), minf(0.95, Sites.seed_success_chance(10, "saturated") + fate_bonus + attune), 0.0001, "0.95 still bounds it")
	)

	run_case("effect_rows_lock_by_sense_for_player_and_collapse_for_contact", func():
		_setup(1)
		GameState.state["player"]["senseSkill"] = 2
		var rows := Lenses.effect_rows("emotion")
		var by_gate := {}
		for row in rows:
			by_gate[row["gate"]] = row
		assert_eq(rows[0]["gate"], "always", "always first")
		assert_true(by_gate["always"]["unlocked"] and by_gate["world"]["unlocked"], "Sense 2 opens always + world")
		assert_true(not by_gate["combat"]["unlocked"], "combat locked at Sense 2")
		assert_eq(by_gate["combat"]["level"], int(GameData.DIAL_LENS["senseGates"]["combat"]), "locked row names its level")
		assert_eq(by_gate["combat"]["text"], GameData.DIAL_LENS["effects"]["emotion"]["combat"], "per-ore text")
		assert_eq(by_gate["glimpse"]["text"], GameData.DIAL_LENS["sharedEffects"]["glimpse"], "shared text")
		var contact_rows := Lenses.effect_rows("physics", CONTACT_ID)
		assert_eq(contact_rows.size(), 1, "contact has one row")
		assert_eq(contact_rows[0]["text"], GameData.DIAL_LENS["contactEffects"]["physics"], "contact physics text")
		assert_eq(Lenses.effect_rows("life", CONTACT_ID)[0]["text"], GameData.DIAL_LENS["contactNoEffect"], "life does nothing on a contact")
	)
