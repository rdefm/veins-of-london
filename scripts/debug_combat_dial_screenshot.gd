extends SceneTree

# Dev-only visual verification harness, run windowed (not --headless --
# nothing actually rasterizes without a real GPU/display):
#   godot -s scripts/debug_combat_dial_screenshot.gd
#
# Boots CombatScreen against a seeded, loaded Dial (same shape scripts/
# debug_hq_dial_screenshot.gd's "seeded_full" state uses) so combat-
# presentation ticket 18's new bottom furniture row (umbrella widget left,
# Complication detail rectangle + 3-block action row right) actually has
# something to show, then dumps a PNG plus every Control's rect to stdout
# (the reliable way to check exact positions/overlap -- reading pixels off
# a screenshot alone is guesswork).

const OUT_DIR := "res://.scratch/combat-presentation/dial-screenshots/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	await _capture("combat_dial_loaded", func():
		game_state.state["combat"] = {
			"active": true, "context": "raid", "veinId": null,
			"enemies": [{ "name": "Scrapper", "hp": 14, "hpMax": 20, "attackMin": 1, "attackMax": 1, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0, "log": ["You swing and miss.", "Scrapper lands a hit for 6."],
			"outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [],
		}
		var player: Dictionary = game_state.state["player"]
		player["dial"] = {
			"level": 1, "xp": 0, "currentCharge": 3, "maxCharge": 5, "rechargeRate": 1.0,
			"combatRegenTurnCounter": 0, "lastRegenDay": game_state.state["world"]["day"],
			"capacityMax": 4, "haftId": "guild_cane", "movement": null,
			"loadedComplications": [
				{ "recipeKey": "blast", "tier": 2 },
				{ "recipeKey": "shield", "tier": 1 },
			],
		}
	)

	await _capture("combat_dial_empty", func():
		game_state.state["combat"] = {
			"active": true, "context": "raid", "veinId": null,
			"enemies": [{ "name": "Scrapper", "hp": 20, "hpMax": 20, "attackMin": 1, "attackMax": 1, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0, "log": [],
			"outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [],
		}
		var player: Dictionary = game_state.state["player"]
		player["dial"] = {
			"level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 5, "rechargeRate": 1.0,
			"combatRegenTurnCounter": 0, "lastRegenDay": game_state.state["world"]["day"],
			"capacityMax": 4, "haftId": "guild_cane", "movement": null, "loadedComplications": [],
		}
	)

	quit(0)


func _capture(name: String, setup: Callable) -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	setup.call()

	var screen: Control = load("res://scenes/screens/combat.gd").new()
	UI.anchor_full_rect(screen)
	root.add_child(screen)

	for i in range(6):
		await process_frame

	print("--- %s ---" % name)
	print("viewport size: %s" % str(root.get_visible_rect().size))
	_dump(screen, 0)

	var img := root.get_texture().get_image()
	var path := OUT_DIR + name + ".png"
	img.save_png(path)
	print("Saved %s" % ProjectSettings.globalize_path(path))

	root.remove_child(screen)
	screen.queue_free()
	await process_frame


func _dump(node: Node, depth: int) -> void:
	var indent := "  ".repeat(depth)
	if node is Control:
		var c := node as Control
		print("%s%s (%s) pos=%s size=%s" % [indent, node.name, node.get_class(), c.position, c.size])
	else:
		print("%s%s (%s)" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_dump(child, depth + 1)
