extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# squad-combat ticket 04: the exact same min/max formula
# Combat._apply_instance_variance() rolls between, so a test asserting an
# entry's stat falls "within its archetype's variance band" is checking
# the real band, not a hand-guessed approximation of it.
static func _variance_bounds(base: float) -> Dictionary:
	return {
		"min": GameState.round_epsilon(base * (1.0 - Combat.ENEMY_INSTANCE_VARIANCE)),
		"max": GameState.round_epsilon(base * (1.0 + Combat.ENEMY_INSTANCE_VARIANCE)),
	}


# The fight's transcript, its intro lines first.
func _intro_lines() -> Array:
	return GameState.state["combat"]["transcript"]

func run() -> void:
	# ── squad-combat ticket 04: distinct-instance roster generation ─────

	run_case("generate_mugger_returns_count_1_to_3_distinct_entries_within_variance_band", func():
		var seen := { 1: false, 2: false, 3: false }
		var hp_bounds := _variance_bounds(28.0)
		var atk_min_bounds := _variance_bounds(4.0)
		var atk_max_bounds := _variance_bounds(10.0)
		var found_variance := false
		for seed in range(300):
			Rng.set_seed(seed)
			var entries := Combat.generate_mugger()
			var count: int = entries.size()
			seen[count] = true
			for entry in entries:
				assert_eq(entry["name"], "A mugger", "every entry rolls off the single mugger archetype -- no new archetype introduced")
				assert_eq(entry["hpMax"], entry["hp"], "a fresh entry starts full")
				assert_true(entry["hp"] >= hp_bounds["min"] and entry["hp"] <= hp_bounds["max"], "hp %d outside variance band [%d,%d]" % [entry["hp"], hp_bounds["min"], hp_bounds["max"]])
				assert_true(entry["attackMin"] >= atk_min_bounds["min"] and entry["attackMin"] <= atk_min_bounds["max"], "attackMin %d outside variance band [%d,%d]" % [entry["attackMin"], atk_min_bounds["min"], atk_min_bounds["max"]])
				assert_true(entry["attackMax"] >= atk_max_bounds["min"] and entry["attackMax"] <= atk_max_bounds["max"], "attackMax %d outside variance band [%d,%d]" % [entry["attackMax"], atk_max_bounds["min"], atk_max_bounds["max"]])
				assert_eq(entry["speed"], Combat.MUGGER_SPEED, "speed should carry the authored mugger speed unchanged, no variance applied")
			if count >= 2 and (entries[0]["hp"] != entries[1]["hp"] or entries[0]["attackMin"] != entries[1]["attackMin"] or entries[0]["attackMax"] != entries[1]["attackMax"]):
				found_variance = true
		assert_true(seen[1] and seen[2] and seen[3], "all three mugger counts should appear across 300 seeds")
		assert_true(found_variance, "same-archetype squadmates should not be guaranteed stat-for-stat identical")
	)

	# ── vein-trade-assets ticket 02: harder("vein_included") mugger roster ──

	# R§3.7b table 1: the harder mugger keeps the base stats; level replaces the old scaling.
	run_case("generate_mugger_harder_widens_the_count_floor_and_keeps_base_stats", func():
		var hp_bounds := _variance_bounds(28.0)
		var atk_min_bounds := _variance_bounds(4.0)
		var atk_max_bounds := _variance_bounds(10.0)
		for seed in range(300):
			Rng.set_seed(seed)
			var entries := Combat.generate_mugger(true)
			var count: int = entries.size()
			assert_true(count >= Combat.HARD_MUGGER_MIN_COUNT and count <= Combat.HARD_MUGGER_MAX_COUNT, "harder roster count %d outside [%d,%d]" % [count, Combat.HARD_MUGGER_MIN_COUNT, Combat.HARD_MUGGER_MAX_COUNT])
			for entry in entries:
				assert_eq(entry["name"], "A mugger", "still the single mugger template")
				assert_true(entry["hp"] >= hp_bounds["min"] and entry["hp"] <= hp_bounds["max"], "harder hp %d outside variance band [%d,%d]" % [entry["hp"], hp_bounds["min"], hp_bounds["max"]])
				assert_true(entry["attackMin"] >= atk_min_bounds["min"] and entry["attackMin"] <= atk_min_bounds["max"], "harder attackMin outside variance band")
				assert_true(entry["attackMax"] >= atk_max_bounds["min"] and entry["attackMax"] <= atk_max_bounds["max"], "harder attackMax outside variance band")
	)

	run_case("start_mugging_vein_included_always_uses_the_harder_rosters_higher_count_floor", func():
		for seed in range(300):
			GameState.reset()
			Rng.set_seed(seed)
			Combat.start_mugging(true)
			var entries: Array = GameState.state["combat"]["enemies"]
			assert_true(entries.size() >= Combat.HARD_MUGGER_MIN_COUNT, "vein_included=true should always roll at least HARD_MUGGER_MIN_COUNT")
	)

	run_case("generate_raid_enemy_returns_guard_count_entries_uncapped", func():
		GameState.reset()
		for guards in [1, 2, 3, 5]:
			Rng.set_seed(guards)
			var entries := Combat.generate_raid_enemy("v1", 1, guards, "veinGuard")
			assert_eq(entries.size(), guards, "guard_count %d should spawn that many entries" % guards)
	)

	# ── reinforcements: roster split ───────────────────────────────────────

	run_case("start_raid_with_five_guards_keeps_three_active_and_queues_two", func():
		GameState.reset()
		Combat.start_raid("v1", 1, 5, "veinGuard")
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["enemies"].size(), 3)
		assert_eq(combat["enemyQueue"].size(), 2)
		assert_eq(combat["allyQueue"], [])
	)

	# ── situational mods ───────────────────────────────────────────────────

	run_case("situational_mods_apply_only_when_their_if_holds", func():
		GameState.reset()
		GameState.state["flags"]["sitFlag"] = true
		var list := [
			{ "if": { "flag": "sitFlag" }, "sight": 2, "fleeBoost": 0.9 },
			{ "if": { "flag": "noSuchSitFlag" }, "oneAtATime": true },
		]
		assert_eq(Combat.situational_active(list), { "sight": 2, "fleeBoost": 0.9 })
		Combat.start_raid("v1", 1, 3, "veinGuard", Combat.CONTEXT_EVENT_RAID, [], list)
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["situational"], { "sight": 2, "fleeBoost": 0.9 })
		assert_eq(combat["enemies"].size(), 3, "oneAtATime's if fails: full squad")
		var player: Dictionary = combat["combatants"][0]
		assert_eq(int(player["sightUntil"]), 2)
		assert_almost_eq(float(player["fleeBoost"]), 0.9, 0.0001)
		assert_true(CombatRounds.has_sight(combat), "round 1 has sight")
		assert_true(combat["transcript"].has(Combat.SITUATIONAL_MODS["sight"]["line"]), "active mod shown at fight start")
	)

	run_case("situational_one_at_a_time_queues_all_but_one_enemy", func():
		GameState.reset()
		Combat.start_raid("v1", 1, 3, "veinGuard", Combat.CONTEXT_EVENT_RAID, [], [{ "if": { "cash": { "atLeast": 0 } }, "oneAtATime": true }])
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["enemies"].size(), 1)
		assert_eq(combat["enemyQueue"].size(), 2)
	)

	run_case("situational_first_strike_overrides_enemy_first", func():
		GameState.reset()
		GameState.state["flags"]["sitFlag"] = true
		Combat.start_scripted_fight({
			"enemies": [{ "name": "thug", "hp": 5, "hpMax": 5, "attackMin": 1, "attackMax": 2, "level": 1, "plans": [["strike"]] }],
			"resumeCard": 0, "enemyFirst": true,
			"situational": [{ "if": { "flag": "sitFlag" }, "firstStrike": true }],
		})
		assert_true(not GameState.state["combat"]["enemyFirst"])
		GameState.reset()
		Combat.start_scripted_fight({
			"enemies": [{ "name": "thug", "hp": 5, "hpMax": 5, "attackMin": 1, "attackMax": 2, "level": 1, "plans": [["strike"]] }],
			"resumeCard": 0, "enemyFirst": true,
			"situational": [{ "if": { "flag": "sitFlag" }, "firstStrike": true }],
		})
		assert_true(GameState.state["combat"]["enemyFirst"], "if fails: enemyFirst stands")
	)

	run_case("generate_raid_enemy_forced_template_key_applies_to_every_slot", func():
		GameState.reset()
		for seed in range(20):
			Rng.set_seed(seed)
			var entries := Combat.generate_raid_enemy("v1", 1, 3, "veinGuard")
			assert_eq(entries.size(), 3)
			for entry in entries:
				assert_eq(entry["name"], "Vein Guard", "a forced template_key should apply to every slot, no mixing")
	)

	run_case("generate_raid_enemy_unforced_can_mix_templates_across_slots", func():
		var mixed_found := false
		for seed in range(300):
			Rng.set_seed(seed)
			var entries := Combat.generate_raid_enemy("v1", 1, 3, "")
			var names := {}
			for entry in entries:
				names[entry["name"]] = true
			if names.size() > 1:
				mixed_found = true
				break
		assert_true(mixed_found, "an unforced 3-guard raid should sometimes mix archetypes across 300 seeds")
	)

	# ── territorial-variants: a scrapper rolls a territorial variant ─────

	run_case("only_territorial_scrappers_carry_a_variant_naming_a_discovered_variant", func():
		GameState.reset()
		for seed in range(100):
			Rng.set_seed(seed)
			for entry in Combat.generate_raid_enemy("v1", 1, 3, ""):
				if entry["name"] == GameData.ENEMY_RAID_GUARDS[Combat.SCRAPPER_TEMPLATE_KEY]["name"]:
					assert_true(GameData.TERRITORIAL_VARIANTS.has(entry.get("variant", "")), "seed %d: scrapper variant %s is a discovered variant" % [seed, entry.get("variant")])
				else:
					assert_true(not entry.has("variant"), "seed %d: %s carries no variant" % [seed, entry["name"]])
	)

	run_case("a_scrappers_variant_is_never_the_players_own_model", func():
		for model in GameData.TERRITORIAL_VARIANTS:
			GameState.reset()
			GameState.state["player"]["model"] = model
			for seed in range(100):
				Rng.set_seed(seed)
				for entry in Combat.generate_raid_enemy("v1", 1, 3, Combat.SCRAPPER_TEMPLATE_KEY):
					assert_true(entry["variant"] != model, "seed %d: variant must not equal player.model %s" % [seed, model])
	)

	run_case("scrappers_spread_across_distinct_variants_before_repeating", func():
		GameState.reset()
		var pool_size: int = GameData.TERRITORIAL_VARIANTS.size() - (1 if GameData.TERRITORIAL_VARIANTS.has(GameState.state["player"]["model"]) else 0)
		assert_true(pool_size >= 1, "sanity: at least one variant available")
		for guards in range(1, Combat.SQUAD_MAX + 1):
			for seed in range(50):
				Rng.set_seed(seed)
				var distinct := {}
				for entry in Combat.generate_raid_enemy("v1", 1, guards, Combat.SCRAPPER_TEMPLATE_KEY):
					distinct[entry["variant"]] = true
				assert_eq(distinct.size(), mini(guards, pool_size), "seed %d, %d scrappers: min(N, P) distinct variants" % [seed, guards])
	)

	run_case("scrapper_variant_spread_with_a_small_pool_gives_every_variant_then_repeats", func():
		GameState.reset()
		var original: Array[String] = GameData.TERRITORIAL_VARIANTS
		GameData.TERRITORIAL_VARIANTS = ["territorial1", "territorial2"] as Array[String]
		GameState.state["player"]["model"] = "territorial9"
		for seed in range(30):
			Rng.set_seed(seed)
			var distinct := {}
			for entry in Combat.generate_raid_enemy("v1", 1, 3, Combat.SCRAPPER_TEMPLATE_KEY):
				distinct[entry["variant"]] = true
			assert_eq(distinct.size(), 2, "seed %d: 2 variants, 3 scrappers -> both variants plus one repeat" % seed)
		GameData.TERRITORIAL_VARIANTS = original
	)

	run_case("an_empty_variant_pool_falls_back_to_the_default_template", func():
		GameState.reset()
		var original: Array[String] = GameData.TERRITORIAL_VARIANTS
		GameData.TERRITORIAL_VARIANTS = ["territorial1"] as Array[String]
		GameState.state["player"]["model"] = "territorial1"
		var entries := Combat.generate_raid_enemy("v1", 1, 2, Combat.SCRAPPER_TEMPLATE_KEY)
		GameData.TERRITORIAL_VARIANTS = original
		for entry in entries:
			assert_eq(entry["variant"], Combat.SCRAPPER_FALLBACK_VARIANT)
	)

	run_case("scrapper_variant_rolls_are_deterministic_under_the_same_seed", func():
		GameState.reset()
		Rng.set_seed(7)
		var first := Combat.generate_raid_enemy("v1", 1, 3, Combat.SCRAPPER_TEMPLATE_KEY).map(func(e: Dictionary) -> String: return e["variant"])
		Rng.set_seed(7)
		var second := Combat.generate_raid_enemy("v1", 1, 3, Combat.SCRAPPER_TEMPLATE_KEY).map(func(e: Dictionary) -> String: return e["variant"])
		assert_eq(first, second)
	)

	# R§3.7b table 2: magnitude sets the level; the template stats stay unscaled.
	run_case("generate_raid_enemy_entries_fall_within_their_templates_variance_band_at_the_magnitudes_level", func():
		GameState.reset()
		var template: Dictionary = GameData.ENEMY_RAID_GUARDS["veinGuard"]
		var value_tier := 3
		var hp_bounds := _variance_bounds(template["hpBase"])
		var atk_min_bounds := _variance_bounds(template["attackMin"])
		var atk_max_bounds := _variance_bounds(template["attackMax"])
		for seed in range(100):
			Rng.set_seed(seed)
			var entries := Combat.generate_raid_enemy("v1", value_tier, 1, "veinGuard")
			var entry: Dictionary = entries[0]
			assert_eq(entry["hpMax"], entry["hp"], "a fresh entry starts full")
			assert_true(entry["hp"] >= hp_bounds["min"] and entry["hp"] <= hp_bounds["max"], "hp %d outside variance band [%d,%d]" % [entry["hp"], hp_bounds["min"], hp_bounds["max"]])
			assert_true(entry["attackMin"] >= atk_min_bounds["min"] and entry["attackMin"] <= atk_min_bounds["max"], "attackMin outside variance band")
			assert_true(entry["attackMax"] >= atk_max_bounds["min"] and entry["attackMax"] <= atk_max_bounds["max"], "attackMax outside variance band")
			assert_eq(entry["speed"], template["speed"], "speed should carry the template's authored value unchanged, no variance applied")
			assert_eq([entry["level"], entry["archetype"], entry["template"]], [3, "turtle", "veinGuard"])
	)

	run_case("generate_raid_enemy_same_template_entries_are_not_guaranteed_identical", func():
		var found_variance := false
		for seed in range(200):
			Rng.set_seed(seed)
			var entries := Combat.generate_raid_enemy("v1", 1, 3, "veinGuard")
			if entries[0]["hp"] != entries[1]["hp"] or entries[1]["hp"] != entries[2]["hp"]:
				found_variance = true
				break
		assert_true(found_variance, "same-template guard squadmates should not be stat-for-stat identical across seeds")
	)

	run_case("guard_group_name_matches_the_old_blob_shape_for_a_single_template_squad", func():
		var entries := [{ "name": "Vein Guard" }, { "name": "Vein Guard" }, { "name": "Vein Guard" }]
		assert_eq(Combat._guard_group_name(entries), "3× Vein Guard", "an all-same-template roster should read exactly as the old forced-template blob name did")
		assert_eq(Combat._guard_group_name([{ "name": "Vein Guard" }]), "Vein Guard", "a single entry should read as just the template name, no count prefix")
	)

	run_case("guard_group_name_joins_distinct_names_for_a_mixed_squad", func():
		var entries := [{ "name": "Territorial Scrapper" }, { "name": "Vein Guard" }]
		assert_eq(Combat._guard_group_name(entries), "Territorial Scrapper and Vein Guard", "a mixed-archetype squad should join distinct names")
	)

	run_case("home_raid_loss_halves_carried_ore", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10, "physics": 7, "life": 20 }
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_HOME_RAID, "veinId": null,
			"enemies": [{ "name": "The raider", "hp": 0, "hpMax": 35, "attackMin": 6, "attackMax": 14, "isMugging": false, "speed": 10, "koed": true }],
			"log": [], "outcome": "loss", "onWin": "homeRaidWon", "snapshots": [], "allies": [],
		}
		var result := Combat.exit_combat()

		assert_eq(result["nextScreen"], "event", "home_raid should route to the generic event screen")
		assert_eq(GameState.state["currentScreen"], "event", "exit_combat should navigate directly for home_raid, same as it already does for raid/other")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_loss", "a loss should chain into the loss debrief event")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5, "floor(10*0.5) = 5 lost, 5 remain")
		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 4, "floor(7*0.5) = 3 lost, 4 remain")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 10, "floor(20*0.5) = 10 lost, 10 remain")
		assert_eq(GameState.state["flags"]["homeRaidWon"], false, "loss should set homeRaidWon false")
		assert_eq(GameState.state["flags"]["homeRaidEventSeen"], true, "loss should still mark the event seen")
	)

	run_case("home_raid_win_does_not_halve_ore", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10 }
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_HOME_RAID, "veinId": null,
			"enemies": [{ "name": "The raider", "hp": 0, "hpMax": 35, "attackMin": 6, "attackMax": 14, "isMugging": false, "speed": 10, "koed": true }],
			"log": [], "outcome": "win", "onWin": "homeRaidWon", "snapshots": [], "allies": [],
		}
		Combat.exit_combat()
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 10, "a win should not halve carried ore")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_win", "a win should chain into the win debrief event")
	)

	run_case("home_raid_win_double_exit_keeps_debrief_and_unlocks_progression", func():
		GameState.reset()
		GameState.state["currentScreen"] = "combat"
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_HOME_RAID
		GameState.state["combat"]["outcome"] = "win"
		GameState.state["combat"]["onWin"] = "homeRaidWon"
		Combat._dispatch_on_win()
		Combat.exit_combat()
		Combat.exit_combat()  # a double tap on the outcome button
		assert_eq(GameState.state["currentScreen"], "event", "a repeat exit should not route home over the debrief")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_win", "debrief should still be live")
		for i in range(GameData.EVENTS["home_raid_debrief_win"]["cards"].size()):
			Events.advance()
		assert_eq(GameState.state["flags"]["archiePartnerSeen"], true, "finishing the debrief should set archiePartnerSeen")
	)

	# ── home raid opening modifiers + no-fight resolution ──────────────

	# Round-1 ordering under enemyFirst: tests/test_combat_rounds.gd.
	run_case("home_raid_without_mods_starts_at_full_hp", func():
		GameState.reset()
		Combat.start_home_raid_combat()
		var combat: Dictionary = GameState.state["combat"]
		var raider: Dictionary = combat["enemies"][0]
		assert_eq(raider["hp"], raider["hpMax"], "no modifier: full hp")
		assert_true(not combat.has("enemyFirst"), "no modifier: no enemyFirst key")
	)

	run_case("home_raid_hp_mult_scales_starting_hp_only", func():
		GameState.reset()
		Combat.start_home_raid_combat({ "enemyHpMult": 0.7 })
		var raider: Dictionary = GameState.state["combat"]["enemies"][0]
		var full: int = GameData.ENEMY_HOME_RAID_RAIDER["hp"]
		assert_eq(raider["hp"], int(round(full * 0.7)), "raider starts at 70% hp")
		assert_eq(raider["hpMax"], full, "hpMax unchanged")
	)

	run_case("home_raid_mods_survive_combat_prep_and_rewind", func():
		GameState.reset()
		GameState.state["currentScreen"] = "event"
		Events.apply_effects([{ "op": "start_home_raid_combat", "enemyHpMult": 0.7, "enemyFirst": true }])
		assert_eq(CombatPrep.pending()["args"], { "enemyHpMult": 0.7, "enemyFirst": true }, "mods parked on the prep")
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		GameState.state["combatPrep"] = null
		GameState.state = snapshot  # what a Rewind restore does
		var saved: Variant = JSON.parse_string(JSON.stringify(CombatPrep.pending()))
		GameState.state["combatPrep"] = saved
		assert_true(CombatPrep.commit()["ok"])
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["enemies"][0]["hp"], int(round(GameData.ENEMY_HOME_RAID_RAIDER["hp"] * 0.7)), "hp mult applied on Fight")
		assert_true(combat.get("enemyFirst", false), "enemyFirst applied on Fight")
	)

	run_case("resolve_home_raid_win_skips_combat_into_the_win_debrief", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10 }
		Events.apply_effects([{ "op": "resolve_home_raid", "outcome": "win" }])
		assert_true(not GameState.state["combat"]["active"], "no fight")
		assert_eq(GameState.state["currentScreen"], "event")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_win")
		assert_true(GameState.state["flags"]["homeRaidWon"])
		assert_true(GameState.state["flags"]["homeRaidEventSeen"])
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 10, "a win keeps the ore")
	)

	run_case("resolve_home_raid_loss_halves_ore_into_the_loss_debrief", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10, "physics": 7 }
		Events.apply_effects([{ "op": "resolve_home_raid", "outcome": "loss" }])
		assert_true(not GameState.state["combat"]["active"], "no fight")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_loss")
		assert_true(not GameState.state["flags"]["homeRaidWon"])
		assert_true(GameState.state["flags"]["homeRaidEventSeen"])
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5)
		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 4)
	)

	run_case("resolve_home_raid_validator_rejects_an_unknown_outcome", func():
		var errors: Array[String] = []
		GameData._validate_effect_list([{ "op": "resolve_home_raid", "outcome": "draw" }], "t", errors)
		assert_eq(errors.size(), 1)
		errors.clear()
		GameData._validate_effect_list([{ "op": "resolve_home_raid", "outcome": "loss" }], "t", errors)
		assert_eq(errors.size(), 0)
	)

	run_case("exit_combat_mugging_win_routes_home_under_the_sale_modal", func():
		GameState.reset()
		GameState.state["currentScreen"] = "combat"
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_MUGGING
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "phone", "mugging-win exit leaves the combat screen")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "the sale modal sits on top")
	)

	run_case("exit_combat_raid_win_routes_to_phone_home_with_the_bag_drawer_open", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_RAID
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "phone", "a raid win should route to the phone app grid")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "should land on the grid itself, not whatever app was last open")
		assert_eq(GameState.state["bagDrawerOpen"], true, "a raid win should open the bag drawer over phone home to show the loot")

		GameState.reset()
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_MUGGING
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "phone", "anything else should route to phone home")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "should land on the grid itself")
		assert_eq(GameState.state["bagDrawerOpen"], false, "no bag drawer outside a raid win")
	)

	# ── vein-raiding ticket 02: event_raid exit routing ─────────────────

	run_case("exit_combat_event_raid_win_resumes_the_still_active_event", func():
		GameState.reset()
		Events.start_event("cold_open")
		GameState.state["combat"]["context"] = Combat.CONTEXT_EVENT_RAID
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "event", "a win should resume the event screen")
		assert_true(GameState.state["event"] != null, "the event should still be active, unresolved cardIndex intact, for its next authored card")
	)

	run_case("exit_combat_event_raid_loss_ends_the_event_and_goes_home", func():
		GameState.reset()
		Events.start_event("cold_open")
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_EVENT_RAID
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "phone", "a loss should route to phone home, same as a losing plain raid")
		assert_eq(GameState.state["event"], null, "the failed raid's event should be cleared, not left dangling")
	)

	# ── vein-raiding ticket 07: defend_vein combat ──────────────────────

	run_case("start_defend_vein_starts_combat_with_the_defend_vein_context", func():
		GameState.reset()
		Combat.start_defend_vein("v1", 2)
		assert_true(GameState.state["combat"]["active"], "defend combat should start")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_DEFEND_VEIN)
		assert_eq(GameState.state["combat"]["veinId"], "v1")
		assert_eq(GameState.state["currentScreen"], "combat")
	)

	# 81-map-stuck-playback-flag: _start_combat() sets currentScreen/emits
	# screen_changed itself rather than going through Nav.go_to() (see its own
	# comment), so it needs the same abandon-a-still-playing-map-queue
	# treatment Nav.go_to() gets, tested the same "no live MapCanvas, simulate
	# via begin_playback()" way tests/test_nav.gd's matching case does.
	# Raiding.maybe_trigger_defend() -> start_defend_vein() is exactly this:
	# the arrival-side defend hook, called synchronously from the same
	# Sites.prospect()/Travel.travel_to() action that can queue a MapEvents
	# animation right before it.
	run_case("start_defend_vein_abandons_a_still_playing_map_animation_queue", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_discover("camden", "s2")
		MapEvents.begin_playback()

		Combat.start_defend_vein("v1", 2)

		assert_true(not MapEvents.is_playing(), "a defend combat starting mid-tween should clear the guard immediately")
		assert_eq(MapEvents.pending_site_ids(), ["s2"], "the interrupted event (s1) is consumed; s2 still awaits its turn")
	)

	run_case("exit_combat_defend_vein_win_leaves_the_vein_alone_and_routes_home", func():
		GameState.reset()
		var vein := { "id": "pv_test", "oreType": "time", "growth": 10, "security": "none", "alarmUpgrades": ["alarm"], "location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch", "siteId": "s_player", "hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0 }
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [{ "id": "s_player", "district": "shoreditch", "tier": "fair", "oreType": "time", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }]
		GameState.state["world"]["activeDefendRaid"] = { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_DEFEND_VEIN
		GameState.state["combat"]["outcome"] = "win"

		Combat.exit_combat()

		assert_eq(GameState.state["currentScreen"], "phone", "should route to phone home either way")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "a defend win leaves the vein with the player")
		assert_eq(GameState.state["world"]["sites"][0]["factionVein"], null, "the site should stay player-claimed, not flip to faction-owned")
		assert_eq(GameState.state["world"]["activeDefendRaid"], null, "activeDefendRaid should be cleared either way")
		assert_eq(GameState.state["notifications"].size(), 0, "a win requires no separate notification, per the PRD")
	)

	run_case("exit_combat_defend_vein_loss_transfers_the_vein_exactly_like_the_no_alarm_path", func():
		GameState.reset()
		var vein := { "id": "pv_test", "oreType": "physics", "growth": 50, "security": "warded", "alarmUpgrades": ["alarm"], "location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch", "siteId": "s_player", "hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0 }
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [{ "id": "s_player", "district": "shoreditch", "tier": "fair", "oreType": "physics", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }]
		GameState.state["world"]["activeDefendRaid"] = { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_DEFEND_VEIN
		GameState.state["combat"]["outcome"] = "loss"

		Combat.exit_combat()

		assert_eq(GameState.state["currentScreen"], "phone")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "the vein leaves player.veins on a defend loss")
		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_true(site["factionVein"] != null, "ownership transfers to the attacking faction, same as the no-alarm path")
		assert_eq(site["factionVein"]["factionId"], "firm")
		assert_eq(site["factionVein"]["oreType"], "physics", "oreType carries over")
		assert_eq(site["factionVein"]["growth"], 50, "growth carries over")
		assert_eq(site["factionVein"]["security"], "warded", "security carries over")
		assert_eq(GameState.state["world"]["activeDefendRaid"], null, "activeDefendRaid should be cleared")
		assert_eq(GameState.state["notifications"].size(), 1, "a loss should still notify, same as the off-screen path")
	)

	run_case("player_has_no_weapon_state_and_attacks_unarmed", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		assert_true(not player.has("equipment") and not player.has("items"), "no weapon/equipment fields in new-game state")
		assert_eq(player["combatSkill"], 1, "sanity: Combat Skill 1")
		var range := Combat.get_attack_range()
		assert_eq(range["min"], 7, "unarmed Combat Skill 1 attackMin")
		assert_eq(range["max"], 15, "unarmed Combat Skill 1 attackMax")
		# Seeded: every player damage roll stays within 7-15.
		seed(1234)
		for i in 50:
			var dmg := randi_range(range["min"], range["max"])
			assert_true(dmg >= 7 and dmg <= 15, "seeded roll %d within 7-15" % dmg)
	)

	run_case("enemy_weapon_bonus_still_applies", func():
		var enemy := { "attackMin": 2, "attackMax": 4, "weapon": { "min": 1, "max": 3 } }
		var range := Combat.get_enemy_attack_range(enemy)
		assert_eq(range["min"], 3, "enemy atkMin + weapon min")
		assert_eq(range["max"], 7, "enemy atkMax + weapon max")
	)

	# ── hygiene-03: canonical context constants/validation ──────────────

	run_case("every_start_helper_stores_its_canonical_context_constant", func():
		GameState.reset()
		Combat.start_mugging()
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_MUGGING)

		GameState.reset()
		Combat.start_street_mugging()
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_EVENT_MUGGING)

		GameState.reset()
		Combat.start_home_raid_combat()
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_HOME_RAID)

		GameState.reset()
		Combat.start_raid("v1", 1)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_RAID, "start_raid's default context")

		GameState.reset()
		Combat.start_raid("v1", 1, 1, "", Combat.CONTEXT_EVENT_RAID)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_EVENT_RAID)

		GameState.reset()
		Combat.start_defend_vein("v1", 2)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_DEFEND_VEIN)
	)

	# ── combat-refining ticket 10: R§2 combat.locationKey ──────────────

	run_case("mugging_start_paths_record_the_players_current_district_as_location_key", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		Combat.start_mugging()
		assert_eq(GameState.state["combat"]["locationKey"], "camden")

		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "soho"
		Combat.start_street_mugging()
		assert_eq(GameState.state["combat"]["locationKey"], "soho")

		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "greenwich"
		Combat.start_archie_deal_mugging()
		assert_eq(GameState.state["combat"]["locationKey"], "greenwich")
	)

	run_case("home_start_paths_record_the_fixed_home_location_key", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		Combat.start_home_raid_combat()
		assert_eq(GameState.state["combat"]["locationKey"], Combat.HOME_LOCATION_KEY, "home isn't a district -- never the current district")

		GameState.reset()
		Combat.start_home_alarm_defend_combat()
		assert_eq(GameState.state["combat"]["locationKey"], Combat.HOME_LOCATION_KEY)
	)

	run_case("vein_start_paths_record_the_fought_veins_district_not_the_players", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "shoreditch"
		GameState.state["player"]["veins"].append({ "id": "pv_loc", "district": "battersea" })
		GameState.state["world"]["sites"].append({ "id": "s_loc", "district": "hampstead", "factionVein": { "id": "fv_loc", "district": "hampstead" } })

		Combat.start_defend_vein("pv_loc", 1)
		assert_eq(GameState.state["combat"]["locationKey"], "battersea", "defend uses the player's own vein's district")
		Combat.exit_combat()

		Combat.start_raid("fv_loc", 1)
		assert_eq(GameState.state["combat"]["locationKey"], "hampstead", "raid uses the faction vein's district")
		Combat.exit_combat()

		Combat.start_raid("fv_loc", 1, 1, "", Combat.CONTEXT_EVENT_RAID)
		assert_eq(GameState.state["combat"]["locationKey"], "hampstead", "event raid uses the vein's district too")
	)

	run_case("vein_start_path_with_an_unresolvable_vein_records_an_empty_location_key", func():
		GameState.reset()
		Combat.start_raid("no_such_vein", 1)
		assert_eq(GameState.state["combat"]["locationKey"], "", "unknown vein -> empty key, backdrop degrades to the context tier")
	)

	run_case("exit_combat_resets_location_key", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		Combat.start_street_mugging()
		Combat.exit_combat()
		assert_eq(GameState.state["combat"]["locationKey"], "")
	)

	run_case("is_canonical_context_accepts_every_named_constant", func():
		for context in Combat.CANONICAL_CONTEXTS:
			assert_true(Combat.is_canonical_context(context), "%s should be canonical" % context)
	)

	run_case("is_canonical_context_rejects_a_typo_or_empty_string", func():
		assert_true(not Combat.is_canonical_context("raidd"), "a typo'd context should not validate")
		assert_true(not Combat.is_canonical_context(""), "an empty context should not validate")
	)

	run_case("start_combat_with_an_unrecognized_context_still_starts_but_stores_it_verbatim", func():
		GameState.reset()
		Combat.start_raid("v1", 1, 1, "", "raidd")
		assert_true(GameState.state["combat"]["active"], "combat should still start -- this ticket is call-site/validation hygiene, not new blocking behaviour")
		assert_eq(GameState.state["combat"]["context"], "raidd", "the bad context is stored verbatim; _start_combat() push_errors loudly instead of silently defaulting it")
	)

	# ── calc-effect-wiring-01: enemy combat capabilities ─────────────────

	run_case("existing_raid_guard_templates_default_to_20_percent_evade_chance", func():
		GameState.reset()
		for key in GameData.ENEMY_RAID_GUARDS.keys():
			var enemy: Dictionary = Combat.generate_raid_enemy("v1", 1, 1, key)[0]
			assert_almost_eq(enemy["evadeChance"], 0.2, 0.0001, "%s should default to 20%% evade" % key)
			assert_eq(enemy["weapon"], null, "%s should have no weapon by default" % key)
			assert_eq(enemy["ability"], null, "%s should have no ability by default" % key)
	)

	run_case("home_raid_raider_template_defaults_to_20_percent_evade_chance", func():
		GameState.reset()
		Combat.start_home_raid_combat()
		assert_almost_eq(GameState.state["combat"]["enemies"][0]["evadeChance"], 0.2, 0.0001, "homeRaidRaider should default to 20% evade")
	)

	run_case("procedural_mugger_defaults_to_20_percent_evade_chance", func():
		for seed in range(10):
			Rng.set_seed(seed)
			var entries := Combat.generate_mugger()
			for enemy in entries:
				assert_almost_eq(enemy["evadeChance"], 0.2, 0.0001, "procedurally generated muggers should default to 20% evade")
				assert_eq(enemy["weapon"], null, "muggers should have no weapon by default")
				assert_eq(enemy["ability"], null, "muggers should have no ability by default")
	)

	run_case("raid_enemy_template_without_an_explicit_evadeChance_defaults_to_20_percent", func():
		# Exercises Combat's capability-assembly helper directly against a
		# template dict, rather than mutating the shared GameData.ENEMY_RAID_GUARDS
		# singleton (which would leak on an assertion failure mid-case).
		var template := { "name": "New Guard", "hpBase": 20, "attackMin": 3, "attackMax": 8, "archetype": "turtle" }
		var capabilities := Combat._enemy_capabilities_from_template(template)
		assert_almost_eq(capabilities["evadeChance"], 0.2, 0.0001, "a newly-authored template that omits evadeChance should default to 20%")
	)

	# ── 44-archie-combat-ally ────────────────────────────────────────────

	run_case("start_defend_vein_with_archie_recruited_adds_him_as_an_ally", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Combat.start_defend_vein("v1", 2)
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join as the one ally")
		assert_eq(allies[0]["contactId"], "archie")
		assert_eq(allies[0]["hp"], allies[0]["hpMax"], "should join at full hp")
		var found := false
		for line in _intro_lines():
			if line.contains("Archie peels off"):
				found = true
		assert_true(found, "should log archie joining")
	)

	run_case("start_defend_vein_without_archie_recruited_has_no_allies", func():
		GameState.reset()
		Combat.start_defend_vein("v1", 2)
		assert_eq(GameState.state["combat"]["allies"], [], "not recruited -- no allies")
	)

	# ── guard-kit 06: guards join the vein defend fight ──────────────────

	run_case("start_defend_vein_with_three_guards_and_no_contacts_adds_three_guard_allies", func():
		GameState.reset()
		GameState.state["player"]["veins"].append({ "id": "gv", "district": "battersea", "security": Cultivating.GUARDED_TIER_ID, "extraGuards": 2 })
		Combat.start_defend_vein("gv", 2)
		var allies: Array = GameState.state["combat"]["allies"] + GameState.state["combat"]["allyQueue"]
		assert_eq(allies.size(), 3, "two active, one queued")
		var stats: Dictionary = GameData.GUARD_KIT["guardAlly"]
		for ally in allies:
			assert_true(ally["guardAlly"], "marked as a guard ally")
			assert_true(not ally.has("contactId"), "guard allies carry no contactId")
			assert_eq(ally["name"], stats["name"])
			assert_eq(ally["hpMax"], int(stats["hpMax"]))
			assert_eq(ally["speed"], int(stats["speed"]))
	)

	run_case("start_defend_vein_contacts_join_first_and_guards_queue_behind", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["player"]["veins"].append({ "id": "gv", "district": "battersea", "security": Cultivating.GUARDED_TIER_ID, "extraGuards": 4 })
		Combat.start_defend_vein("gv", 2)
		var combat: Dictionary = GameState.state["combat"]
		var allies: Array = combat["allies"]
		assert_eq(allies.size(), Combat.SQUAD_MAX - 1, "player holds one of three places")
		assert_eq(allies[0]["contactId"], "archie", "contacts come first")
		assert_true(allies[1].get("guardAlly", false), "a guard fills the other place")
		assert_true(combat["allyQueue"].size() >= 1, "remaining guards wait")
	)

	run_case("start_defend_vein_with_no_guards_adds_no_guard_allies", func():
		GameState.reset()
		GameState.state["player"]["veins"].append({ "id": "gv", "district": "battersea", "security": "warded", "extraGuards": 0 })
		Combat.start_defend_vein("gv", 2)
		assert_eq(GameState.state["combat"]["allies"], [])
	)

	# ── guard-kit 07: guard kit pool in the fight ────────────────────────

	run_case("start_defend_vein_copies_the_active_kit_into_the_guard_pool", func():
		GameState.reset()
		GameState.state["player"]["veins"].append({ "id": "gv", "district": "battersea", "security": Cultivating.GUARDED_TIER_ID, "extraGuards": 0,
			"guardKit": { "blast": { "2": 1 }, "shield": { "1": 5 } } })
		Combat.start_defend_vein("gv", 2)
		var pool: Dictionary = GameState.state["combat"]["guardKit"]
		assert_eq(Fixtures.kit_units(pool), { "blast": { "2": 1 }, "shield": { "1": 1 } }, "only the 2 active units (1 guard x 2 slots)")
	)

	run_case("exit_combat_takes_used_units_off_the_vein_kit_on_win_loss_or_flee", func():
		for outcome in ["win", "loss", "fled"]:
			GameState.reset()
			GameState.state["player"]["veins"].append({ "id": "gv", "district": "battersea", "security": Cultivating.GUARDED_TIER_ID, "extraGuards": 0,
				"guardKit": { "blast": { "2": 2 }, "shield": { "1": 1 } } })
			Combat.start_defend_vein("gv", 2)
			var pool: Dictionary = GameState.state["combat"]["guardKit"]
			pool["items"] = { "blast": { "2": 2 }, "shield": { "1": 1 } }
			pool["reserved"] = {}
			pool["used"] = {}
			Combat._spend_guard_item(pool, "blast")
			GameState.state["combat"]["outcome"] = outcome
			Combat.exit_combat()
			assert_eq(Cultivating.find_vein("gv")["guardKit"], { "blast": { "2": 1 }, "shield": { "1": 1 } }, "%s: one Blast gone" % outcome)
	)

	# ── guard-kit 11: HQ guards in the alarm-defend fight ──────────────────

	run_case("home_alarm_defend_seeds_guard_allies_and_the_active_hq_kit", func():
		GameState.reset()
		GameState.state["home"]["guardCount"] = 4
		GameState.state["home"]["guardKit"] = { "blast": { "2": 20 } }
		Combat.start_home_alarm_defend_combat()
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["allies"].size(), Combat.SQUAD_MAX - 1, "player holds one of three places")
		assert_eq(combat["allyQueue"].size(), 2, "the other two guards wait")
		for ally in combat["allies"] + combat["allyQueue"]:
			assert_true(ally.get("guardAlly", false))
		assert_eq(Fixtures.kit_units(combat["guardKit"]), { "blast": { "2": 8 } }, "only the 8 active units (4 guards x 2 slots)")
	)

	run_case("home_alarm_defend_with_no_guards_has_no_allies", func():
		GameState.reset()
		Combat.start_home_alarm_defend_combat()
		assert_eq(GameState.state["combat"]["allies"], [])
		assert_eq(GameState.state["combat"]["guardKit"]["items"], {})
	)

	run_case("exit_home_alarm_defend_takes_used_units_off_the_hq_kit_and_keeps_koed_guards", func():
		for outcome in ["win", "loss", "fled"]:
			GameState.reset()
			GameState.state["home"]["guardCount"] = 1
			GameState.state["home"]["guardKit"] = { "blast": { "2": 2 }, "shield": { "1": 1 } }
			Combat.start_home_alarm_defend_combat()
			var pool: Dictionary = GameState.state["combat"]["guardKit"]
			pool["items"] = { "blast": { "2": 2 }, "shield": { "1": 1 } }
			pool["reserved"] = {}
			pool["used"] = {}
			Combat._spend_guard_item(pool, "blast")
			GameState.state["combat"]["allies"][0]["hp"] = 0
			GameState.state["combat"]["allies"][0]["koed"] = true
			GameState.state["combat"]["outcome"] = outcome
			Combat.exit_combat()
			assert_eq(GameState.state["home"]["guardKit"], { "blast": { "2": 1 }, "shield": { "1": 1 } }, "%s: one Blast gone" % outcome)
			assert_eq(Home.get_guard_count(), 1, "%s: KO'd guard still counted" % outcome)
	)

	run_case("tutorial_home_raid_has_no_guard_allies", func():
		GameState.reset()
		GameState.state["home"]["guardCount"] = 2
		GameState.state["home"]["guardKit"] = { "blast": { "2": 2 } }
		Combat.start_home_raid_combat()
		assert_eq(GameState.state["combat"]["allies"], [])
		assert_eq(GameState.state["combat"]["guardKit"], {})
	)

	# ── 68-archie-fights-when-mugged-via-archie-sale ─────────────────────

	run_case("start_mugging_always_adds_archie_even_when_not_recruited", func():
		GameState.reset()
		assert_true(not GameState.state["contacts"]["archie"]["recruited"], "sanity: not recruited by default")
		Combat.start_mugging()
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join regardless of the recruited gate")
		assert_eq(allies[0]["contactId"], "archie")
	)

	run_case("start_mugging_always_adds_archie_even_on_ko_cooldown", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["archie"]["koCooldownUntilDay"] = GameState.state["world"]["day"] + 5
		assert_true(not Contacts.can_join_combat("archie"), "sanity: gate would normally exclude him")
		Combat.start_mugging()
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join despite the KO-cooldown gate")
		assert_eq(allies[0]["contactId"], "archie")
	)

	run_case("start_mugging_logs_archie_joining", func():
		GameState.reset()
		Combat.start_mugging()
		var found := false
		for line in _intro_lines():
			if line.contains("Archie"):
				found = true
		assert_true(found, "should log archie joining the mugging")
	)

	run_case("start_street_mugging_does_not_add_archie", func():
		GameState.reset()
		Combat.start_street_mugging()
		assert_eq(GameState.state["combat"]["allies"], [], "event_mugging is outside the Archie-sale flow -- unaffected")
	)

	# ── bugfixes-95: Archie's tag-along deal mugging ─────────────────────

	run_case("start_archie_deal_mugging_always_adds_archie_even_when_not_recruited", func():
		GameState.reset()
		assert_true(not GameState.state["contacts"]["archie"]["recruited"], "sanity: not recruited by default")
		Combat.start_archie_deal_mugging()
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join regardless of the recruited gate")
		assert_eq(allies[0]["contactId"], "archie")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_ARCHIE_DEAL_MUGGING)
	)

	run_case("start_archie_deal_mugging_always_adds_archie_even_on_ko_cooldown", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["archie"]["koCooldownUntilDay"] = GameState.state["world"]["day"] + 5
		assert_true(not Contacts.can_join_combat("archie"), "sanity: gate would normally exclude him")
		Combat.start_archie_deal_mugging()
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join despite the KO-cooldown gate")
		assert_eq(allies[0]["contactId"], "archie")
	)

	run_case("exit_combat_on_an_archie_deal_mugging_win_resolves_via_ArchieDeals_and_stays_put", func():
		GameState.reset()
		GameState.state["pendingArchieDealCut"] = 50
		GameState.state["flags"]["archieDealActive"] = true
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_ARCHIE_DEAL_MUGGING, "veinId": null,
			"enemies": [{ "name": "Test Enemy", "hp": 0, "hpMax": 20, "attackMin": 0, "attackMax": 0, "isMugging": true, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": true }],
			"log": [], "outcome": "win", "onWin": "", "snapshots": [], "allies": [],
		}

		var result := Combat.exit_combat()

		assert_eq(GameState.state["player"]["cash"], 40 + 50, "a won archie-deal mugging pays out pendingArchieDealCut")
		assert_eq(GameState.state["flags"]["archieDealActive"], false, "archieDealActive cleared")
		assert_eq(GameState.state["modal"]["type"], "archie_deal_result")
		assert_eq(result["nextScreen"], null, "stays put -- same as a normal Archie-sale mugging win -- so the result modal stays visible")
	)

	run_case("exit_combat_on_an_archie_deal_mugging_loss_pays_nothing_and_routes_home", func():
		GameState.reset()
		GameState.state["pendingArchieDealCut"] = 50
		GameState.state["flags"]["archieDealActive"] = true
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_ARCHIE_DEAL_MUGGING, "veinId": null,
			"enemies": [{ "name": "Test Enemy", "hp": 20, "hpMax": 20, "attackMin": 0, "attackMax": 0, "isMugging": true, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"log": [], "outcome": "loss", "onWin": "", "snapshots": [], "allies": [],
		}

		var result := Combat.exit_combat()

		assert_eq(GameState.state["player"]["cash"], 40, "a lost archie-deal mugging pays nothing")
		assert_eq(GameState.state["pendingArchieDealCut"], 0, "cleared even on a loss")
		assert_eq(GameState.state["flags"]["archieDealActive"], false, "archieDealActive cleared so the next day can roll again")
		assert_eq(GameState.state["modal"], null, "a lost mugging opens no result modal")
		assert_eq(result["nextScreen"], "phone", "a loss routes home, unlike the win")
	)

	# ── 45-archie-raid-assist ────────────────────────────────────────────

	run_case("start_raid_with_archie_in_ally_ids_adds_him_as_an_ally", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Combat.start_raid("v1", 1, 1, "", Combat.CONTEXT_RAID, ["archie"])
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join as the one ally")
		assert_eq(allies[0]["contactId"], "archie")
		var found := false
		for line in _intro_lines():
			if line.contains("Archie comes in behind you"):
				found = true
		assert_true(found, "should log archie joining a raid")
	)

	run_case("start_raid_with_no_ally_ids_has_no_allies", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Combat.start_raid("v1", 1)
		assert_eq(GameState.state["combat"]["allies"], [], "default ally_ids is empty -- unaffected raid start")
	)

	run_case("start_raid_re_validates_ally_ids_against_can_join_combat", func():
		GameState.reset()
		# archie not recruited -- eligible in the UI at press time is not
		# trusted blindly; start_raid() re-checks itself (see its own comment).
		Combat.start_raid("v1", 1, 1, "", Combat.CONTEXT_RAID, ["archie"])
		assert_eq(GameState.state["combat"]["allies"], [], "not recruited -- ally_ids entry is dropped, not force-joined")
	)

	run_case("exit_combat_replenishes_ally_hp_but_leaves_the_ko_cooldown_alone", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["archie"]["koCooldownUntilDay"] = 9
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_DEFEND_VEIN, "veinId": "v1",
			"enemies": [{ "name": "Test Enemy", "hp": 0, "hpMax": 100, "attackMin": 0, "attackMax": 0, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": true }],
			"log": [], "outcome": "win", "onWin": "", "snapshots": [], "allies": [{ "contactId": "archie", "name": "Archie", "hp": 12, "hpMax": 50, "attackMin": 4, "attackMax": 9, "stash": 0, "healAmount": 15, "koed": false }],
		}

		Combat.exit_combat()

		assert_eq(GameState.state["contacts"]["archie"]["combatHp"], 50, "ally hp should be topped back up to hpMax on combat exit")
		assert_eq(GameState.state["contacts"]["archie"]["koCooldownUntilDay"], 9, "replenish should not touch an existing KO cooldown")
	)

	# ── squad-combat ticket 05: Combat Skill (attack bonus, speed, XP, Train) ──

	run_case("get_attack_range_regression_level_1_matches_pre_ticket_baseline", func():
		GameState.reset()
		GameState.state["player"]["attackMin"] = 5
		GameState.state["player"]["attackMax"] = 12
		assert_eq(GameState.state["player"]["combatSkill"], 1, "sanity: a fresh save starts at Combat Skill level 1")
		var range := Combat.get_attack_range()
		assert_eq(range["min"], 5, "level 1's attack bonus must be 0 -- today's baseline, unchanged")
		assert_eq(range["max"], 12, "level 1's attack bonus must be 0 -- today's baseline, unchanged")
	)

	run_case("get_attack_range_adds_the_level_indexed_combat_skill_bonus", func():
		GameState.reset()
		GameState.state["player"]["attackMin"] = 5
		GameState.state["player"]["attackMax"] = 12
		GameState.state["player"]["combatSkill"] = 3
		var bonus: int = GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[3]
		var range := Combat.get_attack_range()
		assert_eq(range["min"], 5 + bonus, "skill bonus on the unarmed base")
		assert_eq(range["max"], 12 + bonus, "skill bonus on the unarmed base")
	)

	run_case("combat_skill_level_up_raises_hp_max_and_hp_by_the_curve_delta", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["hpMax"] = 50
		player["hp"] = 20
		var curve: Array = GameData.COMBAT_HP_BONUS_BY_LEVEL
		# level 1 -> 5 in one award: each level's delta applies once
		Combat.award_xp(GameData.COMBAT_XP_LEVELS[5])
		assert_eq(player["combatSkill"], 5, "sanity: a max-level award lands on level 5")
		var gain: int = curve[5] - curve[1]
		assert_eq(player["hpMax"], 50 + gain, "hpMax should rise by the summed per-level curve deltas")
		assert_eq(player["hp"], 20 + gain, "current hp should rise by the same amount, not refill")
	)

	run_case("skill_summary_reports_level_xp_band_bonuses_and_next_level_gains", func():
		GameState.reset()
		GameState.state["player"]["combatSkill"] = 2
		GameState.state["player"]["combatXP"] = 100
		var s := Combat.skill_summary()
		var xp: Array = GameData.COMBAT_XP_LEVELS
		var hp: Array = GameData.COMBAT_HP_BONUS_BY_LEVEL
		var atk: Array = GameData.COMBAT_ATTACK_BONUS_BY_LEVEL
		var spd: Array = GameData.COMBAT_SPEED_BY_LEVEL
		assert_eq(s["level"], 2, "level")
		assert_true(not s["isMax"], "level 2 is not max")
		assert_eq(s["xp"], 100, "xp")
		assert_eq(s["xpFloor"], xp[2], "xpFloor is the current level's threshold")
		assert_eq(s["xpNext"], xp[3], "xpNext is the next level's threshold")
		var player: Dictionary = GameState.state["player"]
		var now: Dictionary = s["stats"]
		var nxt: Dictionary = s["nextStats"]
		assert_eq(now["hpMax"], player["hpMax"], "current hpMax")
		assert_eq(now["attackMin"], Combat.get_attack_range()["min"], "current attack min is the effective range")
		assert_eq(now["attackMax"], Combat.get_attack_range()["max"], "current attack max is the effective range")
		assert_eq(now["speed"], spd[2], "current speed")
		assert_eq(nxt["hpMax"], now["hpMax"] + hp[3] - hp[2], "next hpMax adds the level-3 delta")
		assert_eq(nxt["attackMin"], now["attackMin"] + atk[3] - atk[2], "next attack min adds the level-3 delta")
		assert_eq(nxt["attackMax"], now["attackMax"] + atk[3] - atk[2], "next attack max adds the level-3 delta")
		assert_eq(nxt["speed"], spd[3], "next speed is the level-3 speed")
	)

	run_case("skill_summary_at_max_level_flags_max_and_reports_no_next_gains", func():
		GameState.reset()
		var max_level: int = GameData.COMBAT_XP_LEVELS.size() - 1
		GameState.state["player"]["combatSkill"] = max_level
		GameState.state["player"]["combatXP"] = GameData.COMBAT_XP_LEVELS[max_level] + 50
		var s := Combat.skill_summary()
		assert_true(s["isMax"], "max level flagged")
		assert_eq(s["maxLevel"], max_level, "maxLevel")
		assert_eq(s["xpNext"], s["xpFloor"], "no next threshold past max")
		assert_eq(s["nextStats"], s["stats"], "no next-level change at max")
		assert_eq(s["stats"]["speed"], GameData.COMBAT_SPEED_BY_LEVEL[max_level], "current stats still reported at max")
	)

	run_case("train_is_available_without_a_home_gym_at_the_lower_flat_xp_amount", func():
		GameState.reset()
		assert_true(not GameState.state["home"]["rooms"].has("homeGym"), "sanity: no Home Gym built yet")

		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Combat.train()
		assert_true(result["ok"], "Train should succeed without a built Home Gym")
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_WORKOUT_SESSION, "Train awards its lower flat XP amount without a Home Gym")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before + 1, "Train consumes one of the daily time blocks, same currency as every other block-consuming HQ action")
	)

	run_case("train_spends_a_time_block_and_awards_the_larger_flat_xp_amount", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		Home.add_room("homeGym")

		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Combat.train()
		assert_true(result["ok"], "Train should succeed once Home Gym is built and a block is available")
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_GYM_SESSION, "Train awards its own larger flat XP amount")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before + 1, "Train consumes one of the daily time blocks, same currency as every other block-consuming HQ action")
	)

	run_case("train_has_no_separate_cooldown_only_the_daily_block_scarcity_throttles_it", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		Home.add_room("homeGym")

		var first := Combat.train()
		var second := Combat.train()
		assert_true(first["ok"], "first Train this day should succeed")
		assert_true(second["ok"], "a second Train the same day should succeed too -- no separate cooldown")
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_GYM_SESSION * 2, "two sessions should award XP twice")
	)

	# TimeSystem.advance_time_block() rolls the day over (and resets
	# timeBlocksDone to []) the instant the 3rd block of a day is consumed,
	# so is_time_exhausted() can never be observed true *after* a
	# block-consuming call returns -- only *before* one, if something already
	# left 3 entries sitting there. Exercised directly here rather than via
	# three real Train() calls (which would just roll the day over and leave
	# blocks available again -- see the next case).
	run_case("train_is_blocked_when_the_days_time_blocks_are_already_exhausted", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		Home.add_room("homeGym")
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]

		var result := Combat.train()
		assert_true(not result["ok"], "Train should refuse once the day's time blocks are already exhausted")
		assert_eq(GameState.state["player"]["combatXP"], 0, "no XP should be awarded on a blocked Train attempt")
	)

	run_case("train_remains_available_again_once_the_day_rolls_over", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		Home.add_room("homeGym")
		var day_before: int = GameState.state["world"]["day"]

		Combat.train()
		Combat.train()
		Combat.train()  # 3rd block of the day -- TimeSystem.advance_time_block() rolls the day over immediately
		assert_eq(GameState.state["world"]["day"], day_before + 1, "sanity: the 3rd block should have rolled the day over")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0, "sanity: the new day starts with no blocks spent yet")

		var result := Combat.train()
		assert_true(result["ok"], "Train should be available again on the new day")
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_GYM_SESSION * 4, "the 4th session should still award XP like every other")
	)

	# ── James's ally Dial (constants.json contacts.james.grantDial) ──────

	run_case("ally_dial_movement_does_not_feed_player_attunement", func():
		_james_ally()
		assert_eq(GameState.state["contacts"]["james"]["dial"]["movement"]["oreType"], "time")
		assert_eq(Dial.attunement_bonus("time"), 0.0, "player has no Dial -- James's Movement attunes nothing for them")
	)


func _james_ally() -> Dictionary:
	GameState.reset()
	Contacts.force_recruit("james")
	return Contacts.build_combat_ally("james")
