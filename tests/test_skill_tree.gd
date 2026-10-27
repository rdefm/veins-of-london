extends "res://tests/test_base.gd"

# Body / Mind / Soul projection (SkillTree) over player state and
# data/skill_feats.json.


func _bucket(tree: Array, id: String) -> Dictionary:
	for b in tree:
		if b["id"] == id:
			return b
	return {}


func _sub(bucket: Dictionary, id: String) -> Dictionary:
	for s in bucket["subSkills"]:
		if s["id"] == id:
			return s
	return {}


func _feat(skill: Dictionary, id: String) -> Dictionary:
	for f in skill["feats"]:
		if f["id"] == id:
			return f
	return {}


func run() -> void:
	run_case("fresh_state_projects_three_buckets_with_placeholders", func():
		GameState.reset()
		var tree := SkillTree.project()
		assert_eq(tree.map(func(b): return b["id"]), ["body", "mind", "soul"], "bucket order")
		for id in ["body", "mind", "soul"]:
			var b := _bucket(tree, id)
			assert_eq([b["level"], b["xp"]], [1, 0], "%s starts at 1/0" % id)
		assert_eq(_bucket(tree, "mind")["subSkills"].map(func(s): return s["id"]), ["sense", "crafting"], "Mind subs")
		assert_eq(_bucket(tree, "soul")["subSkills"].map(func(s): return s["id"]), ["cultivating"], "Soul sub")
		assert_eq(_bucket(tree, "body")["subSkills"].map(func(s): return s["id"]), MoveLevels.move_ids(), "Body subs are the Move Book moves")
	)

	run_case("bucket_level_is_its_own_not_derived_from_subs", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["senseSkill"] = 4
		player["craftingSkill"] = 5
		player["bodySkill"] = 3
		player["bodyXP"] = 100
		player["moveLevels"]["strike"] = { "level": 5, "xp": 400 }
		var tree := SkillTree.project()
		assert_eq(_bucket(tree, "mind")["level"], 1, "Mind unaffected by Sense/Crafting")
		assert_eq(_sub(_bucket(tree, "mind"), "sense")["level"], 4, "Sense own level")
		var body := _bucket(tree, "body")
		assert_eq([body["level"], body["xp"], body["xpFloor"], body["xpNext"]], [3, 100, GameData.COMBAT_XP_LEVELS[3], GameData.COMBAT_XP_LEVELS[4]], "Body thresholds")
		var strike := _sub(body, "strike")
		assert_eq([strike["level"], strike["isMax"]], [5, true], "move at max")
	)

	run_case("body_feats_seed_the_existing_effects", func():
		GameState.reset()
		GameState.state["player"]["bodySkill"] = 3
		var body := _bucket(SkillTree.project(), "body")
		assert_true(_feat(body, "attack2")["unlocked"], "Lv2 attack unlocked at 3")
		assert_true(not _feat(body, "attack4")["unlocked"], "Lv4 attack locked at 3")
		assert_eq(_feat(body, "hp5")["text"], "+85 max HP", "delta of the hp table")
		assert_eq(_feat(body, "crit2")["text"], "+1% crit chance", "scaled delta")
		assert_eq(_feat(body, "actions3")["text"], "3 actions per round", "absolute table value")
		var strike := _sub(body, "strike")
		assert_eq(_feat(strike, "crit")["level"], GameData.COMBAT_ROUNDS["moveLevelEffects"]["strike"]["critLevel"], "unlock level read from data")
		assert_eq(_feat(strike, "crit")["text"], "+6% crit chance", "scalar scaled")
	)

	run_case("shipped_registry_validates", func():
		var errors := GameData.validate_tables(GameData.snapshot()).filter(func(e): return e.begins_with("skillFeats"))
		assert_eq(errors, [], "shipped data clean")
	)

	run_case("registry_rejects_bad_entries", func():
		var bad := GameData.snapshot().duplicate(true)
		var feats: Array = bad["skill_feats"]["buckets"][0]["feats"]
		feats.append({ "id": "oops", "level": 99, "text": "x" })
		feats.append({ "id": "ghost", "level": 2, "text": "{missing}" })
		feats.append({ "id": "lost", "level": 2, "text": "{v}", "values": { "v": { "from": "COMBAT_ROUNDS", "path": ["nope"] } } })
		var errors := " | ".join(GameData.validate_tables(bad))
		assert_true(errors.contains("oops: level 99"), "level out of range")
		assert_true(errors.contains("{missing}"), "placeholder without value")
		assert_true(errors.contains("values.v: source does not resolve"), "bad source")
	)

	run_case("new_feats_in_data_show_up_without_code_changes", func():
		GameState.reset()
		var spec: Dictionary = GameData.SKILL_FEATS.duplicate(true)
		spec["buckets"][1]["feats"].append({ "id": "mindTrick", "level": 1, "text": "Knows a trick" })
		spec["buckets"][2]["subSkills"][0]["feats"].append({ "id": "bloom", "level": 3, "text": "Blooms +{v}", "values": { "v": { "from": "CRAFT_COST_PER_SKILL" } } })
		var tree := SkillTree.project(GameState.state, spec)
		var trick := _feat(_bucket(tree, "mind"), "mindTrick")
		assert_eq([trick["text"], trick["unlocked"]], ["Knows a trick", true], "top-level feat on a placeholder bucket")
		var bloom := _feat(_sub(_bucket(tree, "soul"), "cultivating"), "bloom")
		assert_eq([bloom["level"], bloom["unlocked"]], [3, false], "locked sub-skill feat")
		assert_eq(bloom["text"], "Blooms +0.8", "value filled from data")
	)
