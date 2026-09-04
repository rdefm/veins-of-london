extends SceneTree

# Dev-only visual verification harness, run windowed (not --headless --
# nothing actually rasterizes without a real GPU/display):
#   ./godot -s scripts/debug_combat_fan_screenshot.gd
#
# Boots CombatScreen directly (same construction Main._show_screen() does:
# .new() + UI.anchor_full_rect() + add_child()) against hand-built combat
# state (same shape tests/test_combat_screen.gd's _setup_combat()/_enemy()/
# _ally() use), waits a few frames for layout + idle art to load, then dumps
# a PNG of the live viewport per combatant count so stage layout (fan
# positioning, sprite sizing, ...) can actually be looked at instead of only
# asserted on via position/size numbers. Written for combat-presentation
# ticket 15 (fan positioning); reusable for any later combat-stage ticket
# that needs the same kind of look.
#
# Autoload globals (GameState, Combat, ...) aren't resolvable as bare
# identifiers at *this* script's own parse time when it's booted via `-s`
# (unlike scripts loaded via load() from inside a running _initialize(),
# e.g. check_runner.gd's pattern) -- fetched via get_node() at runtime
# instead, after the engine has already added them to the tree. UI is a
# class_name (not an autoload), so it resolves as a bare identifier fine.

const OUT_DIR := "res://.scratch/combat-presentation/fan-screenshots/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	for count in [1, 2, 3]:
		var enemies: Array = []
		var allies: Array = []
		var names := ["Scrapper", "Vein Guard", "Mugger"]
		for i in range(count):
			enemies.append({
				"name": names[i], "hp": 20, "hpMax": 20, "attackMin": 1, "attackMax": 1,
				"isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0,
				"speed": 10, "koed": false,
			})
		var ally_names := ["Archie", "Nadia"]
		for i in range(count - 1):
			allies.append({
				"contactId": ally_names[i].to_lower(), "name": ally_names[i], "hp": 20, "hpMax": 20,
				"attackMin": 1, "attackMax": 1, "stash": 0, "healAmount": 0, "speed": 10, "koed": false,
			})

		game_state.reset()
		game_state.state["combat"] = {
			"active": true, "context": "raid", "veinId": null,
			"enemies": enemies, "focusedEnemyIndex": 0,
			"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": allies,
		}

		var screen: Control = load("res://scenes/screens/combat.gd").new()
		UI.anchor_full_rect(screen)
		root.add_child(screen)

		for i in range(6):
			await process_frame

		var img := root.get_texture().get_image()
		var path := OUT_DIR + "fan_%d_per_side.png" % count
		img.save_png(path)
		print("Saved %s" % ProjectSettings.globalize_path(path))

		root.remove_child(screen)
		screen.queue_free()
		await process_frame

	quit(0)
