extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

const ALWAYS := { "min": 1.0, "max": 1.0 }
const NEVER := { "min": 0.0, "max": 0.0 }


func _tier(text: String, rule: Dictionary, base: float = 0.5, effects: Array = []) -> Dictionary:
	var tier := { "base": base, "text": text, "effects": effects }
	tier.merge(rule)
	return tier


func _install(observations: Dictionary, cards: Array) -> void:
	GameData.EVENTS["obs_test"] = { "id": "obs_test", "cards": cards, "observations": observations, "on_complete": [] }
	Events.start_event("obs_test")


func _card(extra: Dictionary = {}) -> Dictionary:
	var card := { "type": "text", "label": null, "speaker": null, "text": "t" }
	card.merge(extra)
	return card


func _rows_by_ore(rows: Array) -> Dictionary:
	var out := {}
	for row in rows:
		out[row["ore"]] = row
	return out


func _cleanup() -> void:
	GameData.EVENTS.erase("obs_test")
	GameState.state["event"] = null


func run() -> void:
	run_case("observation_in_effect_inherits_and_null_clears", func():
		GameState.reset()
		_install({ "o": { "blocks": { "time": { "tiers": [_tier("a", ALWAYS)], "miss": "m" } } } },
			[_card({ "observe": "o" }), _card(), _card({ "observe": null }), _card()])
		assert_eq(Observation.in_effect(), "o", "card 0 names it")
		assert_true(Observation.is_unread(), "unread before the read")
		Events.advance()
		assert_eq(Observation.in_effect(), "o", "card 1 inherits")
		Events.advance()
		assert_eq(Observation.in_effect(), "", "null clears")
		assert_true(not Observation.is_unread(), "nothing to read once cleared")
		Events.advance()
		assert_eq(Observation.in_effect(), "", "stays cleared")
		assert_eq(Observation.read(), [], "read with nothing in effect is empty")
		_cleanup()
	)

	run_case("observation_rolls_each_ore_with_nested_tiers_and_miss_text", func():
		GameState.reset()
		_install({ "o": { "blocks": {
			"physics": { "tiers": [_tier("sharp", NEVER), _tier("rough", ALWAYS)], "miss": "pm" },
			"life": { "tiers": [_tier("sharp", ALWAYS), _tier("rough", ALWAYS)], "miss": "lm" },
			"time": { "tiers": [_tier("only", NEVER)], "miss": "nothing there" },
		} } }, [_card({ "observe": "o" })])
		var rows := Observation.read()
		assert_eq(rows.size(), 3, "one row per listed ore")
		assert_eq(rows.map(func(r): return r["ore"]), ["physics", "life", "time"], "fixed ore order")
		var by := _rows_by_ore(rows)
		assert_eq([by["physics"]["level"], by["physics"]["text"], by["physics"]["hit"], by["physics"]["tiers"]], [1, "rough", true, 2], "worse tier lands alone")
		assert_eq([by["life"]["level"], by["life"]["text"]], [2, "sharp"], "best tier wins when both land")
		assert_eq([by["time"]["level"], by["time"]["text"], by["time"]["hit"]], [0, "nothing there", false], "miss returns miss text")
		assert_true(by["life"]["roll"] >= 1 and by["life"]["roll"] <= 100, "shown roll is d100")
		assert_true(not Observation.is_unread(), "read clears unread")
		_cleanup()
	)

	run_case("observation_sums_sense_and_own_mods_and_clamps_per_tier", func():
		GameState.reset()
		GameState.state["flags"]["keen"] = true
		GameState.state["player"]["senseSkill"] = 5
		_install({ "o": {
			"mods": [{ "flag": "keen", "add": 0.2, "label": "Keen eye" }],
			"blocks": { "life": { "tiers": [{ "base": 0.1, "text": "a", "max": 0.5 }, { "base": 0.3, "text": "b" }], "miss": "m" } },
		} }, [_card({ "observe": "o" })])
		var row: Dictionary = Observation.read()[0]
		var sense: float = float(GameData.OBSERVATION["sensePerLevel"]) * 4
		assert_eq(row["mods"].size(), 2, "Sense and the own mod are listed")
		assert_almost_eq(float(row["mods"][0]["delta"]) + float(row["mods"][1]["delta"]), sense + 0.2, 0.0001, "mods sum")
		var p_worse := 0.3 + sense + 0.2
		var p_best := minf(0.1 + sense + 0.2, 0.5)
		var expected_p := p_best if row["level"] == 2 else p_worse
		assert_eq(row["needed"], floori(snappedf(100.0 - expected_p * 100.0, 0.000001)) + 1, "needed shows the landed or easiest tier")
		_cleanup()
	)

	run_case("observation_replays_per_run_key_and_varies_by_day", func():
		GameState.reset()
		var obs := { "o": { "blocks": {} } }
		for ore in ["physics", "life", "emotion", "time", "fate"]:
			obs["o"]["blocks"][ore] = { "tiers": [_tier("a", {}, 0.5)], "miss": "m" }
		GameState.state["world"]["day"] = 3
		_install(obs, [_card({ "observe": "o" })])
		var first: Array = Observation.read().map(func(r): return r["roll"])
		GameState.state["event"] = null
		Events.start_event("obs_test")
		var again: Array = Observation.read().map(func(r): return r["roll"])
		assert_eq(again, first, "same run key replays")
		GameState.state["event"] = null
		GameState.state["world"]["day"] = 4
		Events.start_event("obs_test")
		var other: Array = Observation.read().map(func(r): return r["roll"])
		assert_true(other != first, "another day rolls fresh")
		_cleanup()
	)

	run_case("observation_reads_once_and_awards_sense_xp_for_blocks_and_tiers", func():
		GameState.reset()
		_install({ "o": { "blocks": {
			"life": { "tiers": [_tier("a", ALWAYS), _tier("b", ALWAYS)], "miss": "m" },
			"time": { "tiers": [_tier("a", NEVER)], "miss": "m" },
		} } }, [_card({ "observe": "o" })])
		var first := Observation.read()
		var expected: int = 2 * int(GameData.OBSERVATION["xpPerBlock"]) + 2 * int(GameData.OBSERVATION["xpPerTier"])
		assert_eq(GameState.state["player"]["senseXP"], expected, "XP per block rolled plus per tier landed")
		var second := Observation.read()
		assert_eq(second, first, "second read returns stored results")
		assert_eq(GameState.state["player"]["senseXP"], expected, "no XP on a re-read")
		_cleanup()
	)

	run_case("observation_tier_effects_run_once_for_reached_tiers", func():
		GameState.reset()
		_install({ "o": { "blocks": { "time": { "tiers": [
			_tier("a", NEVER, 0.1, [{ "op": "set_flag", "flag": "sharpSeen", "value": true }]),
			_tier("b", ALWAYS, 0.5, [{ "op": "set_flag", "flag": "roughSeen", "value": true }]),
		], "miss": "m" } } } }, [_card({ "observe": "o" })])
		Observation.read()
		assert_eq(GameState.state["flags"].get("roughSeen", false), true, "reached tier's effects ran")
		assert_eq(GameState.state["flags"].get("sharpSeen", false), false, "unreached tier's effects did not")
		_cleanup()
	)

	run_case("rewind_keeps_reads_and_rearms_exactly_one_extra_roll", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 3 }
		_install({ "o": { "blocks": { "time": { "tiers": [_tier("a", ALWAYS)], "miss": "m" } } },
			"u": { "blocks": { "time": { "tiers": [_tier("a", ALWAYS)], "miss": "m" } } } },
			[_card(), _card({ "observe": "o" }), _card({ "observe": "u" }), _card()])
		Events.advance()
		Observation.read()
		var xp: int = GameState.state["player"]["senseXP"]
		Events.advance()
		assert_true(Observation.is_unread(), "u unread")
		var result := Events.rewind()
		assert_eq(result["rearmed"], ["o"], "only the read observation re-arms")
		assert_true(Observation.rows("o").size() == 1, "read survives the Rewind")
		assert_true(not Observation.is_unread(), "o still read")
		assert_true(Observation.is_armed(), "o armed")
		var obs: Dictionary = GameState.state["event"]["observations"]
		assert_true(not obs.has("u"), "unread observation untouched")
		Observation.read()
		assert_eq(obs["o"]["rollCount"], 2, "one extra roll")
		assert_true(not Observation.is_armed(), "armed cleared by the re-roll")
		assert_true(GameState.state["player"]["senseXP"] > xp, "XP on the re-roll")
		Observation.read()
		assert_eq(obs["o"]["rollCount"], 2, "no further roll without another Rewind")
		_cleanup()
	)

	run_case("reroll_keeps_best_tier_and_reports_improvement", func():
		GameState.reset()
		_install({ "o": { "blocks": { "time": { "tiers": [
			_tier("a", NEVER, 0.1, [{ "op": "add", "path": "player.cash", "value": 1 }]),
			_tier("b", ALWAYS, 0.5, [{ "op": "add", "path": "player.cash", "value": 10 }]),
		], "miss": "m" } } } }, [_card({ "observe": "o" })])
		Observation.read()
		var cash: int = GameState.state["player"]["cash"]
		var stored: Dictionary = GameState.state["event"]["observations"]["o"]
		stored["armed"] = true
		stored["results"]["time"]["level"] = 2
		stored["results"]["time"]["roll"] = 73
		var worse: Dictionary = Observation.read()[0]
		assert_eq(worse["level"], 2, "worse re-roll never downgrades")
		assert_eq(worse["roll"], 73, "kept roll")
		assert_true(worse["rerolled"] and not worse["improved"], "not improved")
		assert_eq(EventScreen.roll_line_text(worse).begins_with("Rolled %d · kept 73" % worse["last"]), true, "kept display")
		assert_eq(GameState.state["player"]["cash"], cash, "no effects for tiers already reached")
		stored = GameState.state["event"]["observations"]["o"]
		stored["armed"] = true
		stored["results"]["time"]["level"] = 0
		var better: Dictionary = Observation.read()[0]
		assert_eq(better["level"], 1, "better re-roll replaces")
		assert_true(better["improved"], "improved")
		assert_eq(GameState.state["player"]["cash"], cash + 10, "newly reached tier's effects run")
		_cleanup()
	)

	run_case("observed_condition_gates_requires_mods_and_goto", func():
		GameState.reset()
		var cond := { "observed": { "id": "o", "ore": "time", "atLeast": 1 } }
		var cond_deep := { "observed": { "id": "o", "ore": "time", "atLeast": 2 } }
		_install({ "o": { "blocks": { "time": { "tiers": [_tier("a", NEVER, 0.1), _tier("b", ALWAYS)], "miss": "m" } } } },
			[_card({ "observe": "o", "goto": [{ "if": cond, "card": 2 }, { "card": 1 }] }), _card({ "text": "no" }), _card({ "text": "yes" })])
		assert_true(not Events.condition_met(cond), "false before the read")
		Observation.read()
		assert_true(Events.condition_met(cond), "true at the landed level")
		assert_true(not Events.condition_met(cond_deep), "false above the landed level")
		assert_true(not Events.condition_met({ "observed": { "event": "other", "id": "o", "ore": "time", "atLeast": 1 } }), "cross-event form is not yet held")
		var boost: Dictionary = cond.duplicate()
		boost["observed"] = cond["observed"]
		boost["add"] = 0.25
		boost["label"] = "Saw it"
		assert_almost_eq(Events.odds_for({ "base": 0.4, "mods": [boost] })["probability"], 0.65, 0.0001, "a mod boosts on observed")
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 2, "conditional goto follows observed")
		_cleanup()
	)

	run_case("observation_state_is_pure_data", func():
		GameState.reset()
		_install({ "o": { "blocks": { "life": { "tiers": [_tier("a", ALWAYS)], "miss": "m" } } } },
			[_card({ "observe": "o" }), _card()])
		Observation.read()
		var stored: Variant = GameState.state["event"]["observations"]
		assert_eq(JSON.parse_string(JSON.stringify(stored)) != null, true, "round-trips as JSON")
		Events.advance()
		assert_eq(Observation.rows("o").size(), 1, "rows still readable after a snapshot and advance")
		_cleanup()
	)

	run_case("observation_kit_mods_attunement_lady_breath_items", func():
		GameState.reset()
		GameState.state["player"]["dial"] = { "movement": { "oreType": "life", "tier": 3 } }
		GameState.state["player"]["activeEffects"] = [
			{ "item": ActiveEffects.LADY, "level": 2, "expiresAtBlock": 999 },
			{ "item": ActiveEffects.PROPHETS_BREATH, "level": 1, "expiresAtBlock": 999 },
		]
		GameData.RECIPES["obs_charm"] = { "name": "Charm", "observeBonus": { "fate": 0.04, "all": 0.01 } }
		Crafting.inventory_add("obs_charm", 1, 1)
		var blocks := {}
		for ore in ["life", "time", "fate"]:
			blocks[ore] = { "tiers": [_tier("a", {}, 0.5)], "miss": "m" }
		_install({ "o": { "blocks": blocks } }, [_card({ "observe": "o" })])
		var by := _rows_by_ore(Observation.read())
		var labels := func(row: Dictionary) -> Array: return row["mods"].map(func(m): return m["label"])
		assert_eq(labels.call(by["life"]), ["Attunement", "Be A Lady", "Charm"], "life: attunement, Lady, item all")
		assert_eq(labels.call(by["time"]), ["Be A Lady", "Prophet's Breath", "Charm"], "time: Breath only on time")
		assert_almost_eq(Observation.mods_total(by["fate"]["mods"]), 0.10 + 0.05, 0.0001, "fate: Lady + item ore and all")
		assert_almost_eq(Observation.mods_total(by["life"]["mods"]), float(GameData.DIAL_ATTUNEMENT_BONUS_BY_TIER[3]) + 0.10 + 0.01, 0.0001, "life total")
		GameData.RECIPES.erase("obs_charm")
		_cleanup()
	)

	run_case("memory_written_on_completion_keeps_best_and_gates_event_condition", func():
		GameState.reset()
		_install({ "o": { "blocks": { "time": { "tiers": [_tier("hi", NEVER), _tier("lo", ALWAYS)], "miss": "m" } } } },
			[_card({ "observe": "o" }), _card()])
		var cond := { "event": "obs_test", "id": "o", "ore": "time", "atLeast": 1 }
		assert_true(not Observation.observed(cond), "no memory before completion")
		Observation.read()
		Events.advance()
		Events.advance()
		assert_eq(GameState.state["observationMemory"]["obs_test"]["o"]["time"], 1, "best level stored")
		assert_true(Observation.observed(cond), "event form reads memory outside the event")
		assert_true(not Observation.observed({ "event": "obs_test", "id": "o", "ore": "time", "atLeast": 2 }), "atLeast above stored fails")
		GameState.state["observationMemory"]["obs_test"]["o"]["time"] = 2
		Events.start_event("obs_test")
		Observation.read()
		Events.advance()
		Events.advance()
		assert_eq(GameState.state["observationMemory"]["obs_test"]["o"]["time"], 2, "a worse later run never lowers it")
		assert_eq(JSON.parse_string(JSON.stringify(GameState.state["observationMemory"])) != null, true, "pure data")
		_cleanup()
	)

	# ── raid factors (vein raids only) ──────────────────────────────────

	run_case("raid_observation_carries_labelled_raid_factor_mods_and_disinformation_lowers_them", func():
		GameState.reset()
		var vein := { "id": "fv_t", "factionId": "guild", "oreType": "physics", "growth": 50, "security": "warded", "alarmUpgrades": [], "location": "x", "claimedOnDay": 0, "district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0 }
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		GameState.state["intel"][Shares.PLAYER]["guild"] = int(GameData.INTEL["max"])
		GameData.EVENTS["obs_test"] = { "id": "obs_test", "cards": [_card({ "observe": "o" })], "on_complete": [],
			"observations": { "o": { "blocks": { "time": { "tiers": [_tier("a", ALWAYS)], "miss": "m" } } } } }
		Events.start_event("obs_test", { "site_id": "s1" })
		var labels: Dictionary = GameData.OBSERVATION["raidLabels"]
		var mods: Array = _rows_by_ore(Observation.read())["time"]["mods"]
		var by_label := {}
		for mod in mods:
			by_label[mod["label"]] = float(mod["delta"])
		assert_true(by_label.has(labels["security"]) and by_label[labels["security"]] < 0.0, "security mod negative")
		assert_true(by_label.has(labels["value"]) and by_label[labels["value"]] < 0.0, "value mod negative")
		assert_true(by_label.has(labels["intel"]) and by_label[labels["intel"]] > 0.0, "intel mod positive")
		var with_intel := Observation.mods_total(mods)
		_cleanup()

		Intel.set_disinformation(Shares.PLAYER, "guild", Intel.DISINFO_OVERESTIMATE, 5)
		GameData.EVENTS["obs_test"] = { "id": "obs_test", "cards": [_card({ "observe": "o" })], "on_complete": [],
			"observations": { "o": { "blocks": { "time": { "tiers": [_tier("a", ALWAYS)], "miss": "m" } } } } }
		Events.start_event("obs_test", { "site_id": "s1" })
		var misled: Array = _rows_by_ore(Observation.read())["time"]["mods"]
		assert_true(Observation.mods_total(misled) < with_intel, "disinformation lowers the total")
		var found := false
		for mod in misled:
			found = found or mod["label"] == labels["disinformation"]
		assert_true(found, "disinformation labelled")
		_cleanup()
	)

	run_case("check_with_raidFactors_adds_the_raid_factor_mods_to_its_odds", func():
		GameState.reset()
		var vein := { "id": "fv_t", "factionId": "guild", "oreType": "physics", "growth": 50, "security": "warded", "alarmUpgrades": [], "location": "x", "claimedOnDay": 0, "district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0 }
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		var check := { "base": 0.5, "raidFactors": true, "mods": [] }
		var plain := Events.odds_for({ "base": 0.5, "mods": [] })
		assert_eq(plain["mods"].size(), 0)
		GameData.EVENTS["obs_test"] = { "id": "obs_test", "cards": [_card({})], "on_complete": [] }
		Events.start_event("obs_test", { "site_id": "s1" })
		var odds := Events.odds_for(check)
		assert_true(odds["mods"].size() > 0, "raid factors listed as labelled mods")
		assert_true(odds["probability"] < 0.5, "security and value pull the odds down")
		_cleanup()
	)

	run_case("non_raid_observation_has_no_raid_factor_mods", func():
		GameState.reset()
		_install({ "o": { "blocks": { "time": { "tiers": [_tier("a", ALWAYS)], "miss": "m" } } } }, [_card({ "observe": "o" })])
		assert_eq(Observation.read()[0]["mods"].size(), 0, "no mods outside a raid")
		_cleanup()
	)

	run_case("reduce_raid_guards_lowers_count_and_zero_skips_the_fight", func():
		GameState.reset()
		var vein := { "id": "fv_t", "factionId": "guild", "oreType": "physics", "growth": 50, "security": "none", "alarmUpgrades": [], "location": "x", "claimedOnDay": 0, "district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0 }
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		GameData.EVENTS["obs_test"] = { "id": "obs_test", "cards": [_card()], "on_complete": [] }
		Events.start_event("obs_test", { "site_id": "s1" })
		Events.apply_effects([{ "op": "reduce_raid_guards" }, { "op": "start_raid_combat", "guards": 3, "template": "veinGuard" }])
		var total: int = GameState.state["combat"]["enemies"].size() + GameState.state["combat"]["enemyQueue"].size()
		assert_eq(total, 2, "3 guards less 1")
		GameState.state["combat"] = null
		Events.apply_effects([{ "op": "reduce_raid_guards", "count": 2 }, { "op": "start_raid_combat", "guards": 3, "template": "veinGuard" }])
		assert_eq(GameState.state["combat"], null, "zero guards left starts no fight")
		_cleanup()
	)
