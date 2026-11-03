extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const RaidingTests := preload("res://tests/test_raiding.gd")

# raid_playground (church / hall / nursery playground): driven for real through
# Events.start_event/choose/advance, checks forced with _force_raid_checks().


static func _start() -> void:
	GameState.reset()
	var vein := RaidingTests._faction_vein_of_growth(10, "time", "guarded", "firm")
	GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
	var built := Raiding.security_profile(vein)
	built.merge({ "guards": 0, "cameras": 0, "alarm": false, "ward": false }, true)
	Events.start_event("raid_playground", { "site_id": "s1", "ally_ids": [], "securityProfile": built, "startAlert": 0 })


static func _key() -> String:
	return String(Events.current_card().get("key", ""))


static func _pick(label: String) -> void:
	var i := RaidingTests._option_index(label)
	assert(i >= 0, "no option '%s' on %s" % [label, _key()])
	Events.choose(i)
	if GameState.state["event"] != null and not GameState.state["combat"]["active"]:
		Events.advance()


static func _chance(op: Dictionary) -> float:
	return float(op["p"])


func run() -> void:
	run_case("the_event_loads_and_opens_on_the_hub", func():
		_start()
		assert_eq(_key(), "c1")
	)

	run_case("forcing_the_hall_door_scales_with_body_skill", func():
		_start()
		_pick("Look for a way in via the hall")
		var i := RaidingTests._option_index("Force the door")
		GameState.state["player"]["bodySkill"] = 1
		var low: float = Events.odds_for(Events.current_card()["choices"][i]["check"])["probability"]
		GameState.state["player"]["bodySkill"] = 3
		var high: float = Events.odds_for(Events.current_card()["choices"][i]["check"])["probability"]
		assert_true(high > low, "Body raises the odds")
		assert_true(absf((high - low) - 0.2) < 0.001, "+10% per level")
	)

	run_case("a_failed_door_force_costs_three_hp", func():
		_start()
		_pick("Look for a way in via the hall")
		var ok := RaidingTests._force_raid_checks(0.0, "raid_playground")
		var hp: int = GameState.state["player"]["hp"]
		_pick("Force the door")
		ok.call()
		assert_eq(int(GameState.state["player"]["hp"]), hp - 3)
		assert_eq(_key(), "c1", "back to the hub")
	)

	run_case("blasting_the_hall_door_spends_a_blast_and_raises_alert", func():
		_start()
		_pick("Look for a way in via the hall")
		Crafting.inventory_add("blast", 1, 1)
		var alert: Dictionary = GameData.RECIPES["blast"]["eventProfile"]["alert"]
		var original_cover: Variant = alert["cover"]
		alert["cover"] = { "base": 0.0, "min": 0.0, "max": 0.0 }
		var i := RaidingTests._option_index("Blast the door open")
		Events.choose(i)
		alert["cover"] = original_cover
		assert_eq(Crafting.inventory_qty("blast"), 0)
		assert_eq(Events.alert_level(), 1)
	)

	run_case("an_active_prophets_breath_guarantees_the_door_code", func():
		_start()
		_pick("Look for a way in via the hall")
		var i := RaidingTests._option_index("Guess the door code")
		var base: float = Events.odds_for(Events.current_card()["choices"][i]["check"])["probability"]
		GameState.state["player"]["activeEffects"].append({ "item": "prophetsBreath", "level": 1, "expiresAtBlock": ActiveEffects.absolute_block() + 3 })
		var boosted: float = Events.odds_for(Events.current_card()["choices"][i]["check"])["probability"]
		assert_true(base < 1.0)
		assert_eq(boosted, 1.0)
	)

	run_case("the_activeEffect_condition_follows_the_running_effect", func():
		GameState.reset()
		assert_true(not Events.condition_met({ "activeEffect": "beALady" }))
		GameState.state["player"]["activeEffects"].append({ "item": "beALady", "level": 1, "expiresAtBlock": ActiveEffects.absolute_block() + 3 })
		assert_true(Events.condition_met({ "activeEffect": "beALady" }))
	)

	run_case("the_blasted_gate_needs_and_spends_a_blast", func():
		_start()
		_pick("Check out the playground")
		var i := RaidingTests._option_index("Blast the gate open")
		assert_eq(Events.option_gate(i)["display"], "disable")
		Crafting.inventory_add("blast", 1, 1)
		Events.choose(i)
		assert_eq(Crafting.inventory_qty("blast"), 0)
	)
