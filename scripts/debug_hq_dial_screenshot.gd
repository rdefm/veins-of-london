extends SceneTree

# Dev-only visual verification harness, run windowed (not --headless):
#   ./godot -s scripts/debug_hq_dial_screenshot.gd
#
# Boots HqDialScreen directly against a handful of hand-built player states
# (full loadout, empty loadout, unseeded with/without the gift flag) so the
# device art/needle positioning and the umbrella-overlay socket/dock layout
# can actually be looked at -- same reasoning as the sibling
# debug_combat_fan_screenshot.gd. Also dumps every Control's rect to stdout,
# which is the more reliable way to check exact positions/overlap (reading
# pixels off a screenshot is guesswork; the dump isn't).

const OUT_DIR := "res://.scratch/hq-diorama/dial-screenshots/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	await _capture("hq_dial_seeded_full", func():
		var player: Dictionary = game_state.state["player"]
		player["dial"] = {
			"level": 1, "xp": 0, "currentCharge": 1, "maxCharge": 13, "rechargeRate": 2.0,
			"combatRegenTurnCounter": 0, "lastRegenDay": game_state.state["world"]["day"],
			"capacityMax": 4, "haftId": "guild_cane",
			"movement": { "archetype": "impact", "oreType": "time", "tier": 3 },
			"loadedComplications": [
				{ "recipeKey": "timePearl", "tier": 3, "capacityCost": 1, "detent": 0 },
				{ "recipeKey": "enhancementPowder", "tier": 3, "capacityCost": 1, "detent": 1 },
				{ "recipeKey": "shield", "tier": 3, "capacityCost": 1, "detent": 2 },
			],
		}
		player["orichalchum"]["time"] = 50
	)

	await _capture("hq_dial_seeded_empty", func():
		var player: Dictionary = game_state.state["player"]
		player["dial"] = {
			"level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 8, "rechargeRate": 1.0,
			"combatRegenTurnCounter": 0, "lastRegenDay": game_state.state["world"]["day"],
			"capacityMax": 4, "haftId": "guild_cane", "movement": null, "loadedComplications": [],
		}
	)

	await _capture("hq_dial_unseeded_no_gift", func():
		pass
	)

	await _capture("hq_dial_unseeded_gift", func():
		game_state.state["flags"]["dialGiftGranted"] = true
	)

	quit(0)


func _capture(name: String, setup: Callable) -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	setup.call()

	var screen: Control = load("res://scenes/screens/hq_dial.gd").new()
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
