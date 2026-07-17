class_name HomeScreen
extends Control

# Stats collapsible, to-do list per R§3.11, actions incl. Rest.

var _stats_open := false
var _content: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# R§3.8: "on next visit to home screen, launch." Checked once per visit,
	# before building the normal home UI or connecting _refresh — starting
	# the event immediately navigates away, and this node is about to be
	# freed by Main.gd's screen swap.
	var flags: Dictionary = GameState.state["flags"]
	if flags["homeRaidEventPending"] and not flags["homeRaidEventSeen"]:
		Events.start_event("home_raid_intro")
		return

	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	var world: Dictionary = GameState.state["world"]
	var player: Dictionary = GameState.state["player"]

	_content.add_child(UI.heading("London · Day %d" % world["day"]))
	_content.add_child(UI.muted_label("%s · £%d" % [GameData.TIME_BLOCKS[world["timeBlock"]], player["cash"]]))

	_content.add_child(_build_todo_card())
	_content.add_child(_build_stats_card())
	_content.add_child(_build_actions_card())


func _build_todo_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Things to do", 14))
	var items := _get_todo_items()
	if items.is_empty():
		c["content"].add_child(UI.muted_label("Nothing pressing."))
	for item in items:
		var row := UI.hbox(6)
		row.add_child(UI.label("☑" if item["done"] else "☐"))
		var text := UI.label(item["text"])
		if item["done"]:
			text.add_theme_color_override("font_color", Color(0.541176, 0.541176, 0.541176, 1))
		row.add_child(text)
		c["content"].add_child(row)
	return c["panel"]


# Ported from the HTML's getTodoItems() (same conditional chain, last 4
# shown), with jamesCraftEventSeen mapped to craftingUnlocked — the R§2
# flag covering the same tutorial milestone under the current schema.
func _get_todo_items() -> Array[Dictionary]:
	var f: Dictionary = GameState.state["flags"]
	var day: int = GameState.state["world"]["day"]
	var items: Array[Dictionary] = []

	items.append({ "done": f["metArchie"], "text": "Get back to Archie. He's sorting the new buyer." })

	if f["metArchie"]:
		items.append({
			"done": f["buyerEventSeen"],
			"text": "Wait for Archie's text — he's lining up the buyer." if day < 2 else "Back up Archie on the sale tonight. Check Contacts.",
		})

	if f["buyerEventSeen"]:
		items.append({ "done": f["metJames"], "text": "Archie mentioned a contact called James. SMS him to set it up." })

	if f["metJames"]:
		items.append({ "done": f["craftingUnlocked"], "text": "Go back to James when he's ready. He'll teach you the basics." })

	if f["craftingUnlocked"]:
		items.append({ "done": f["archieCraftChatSeen"], "text": "Catch up with Archie about what James taught you." })

	if f["archieCraftChatSeen"]:
		items.append({ "done": f["homeRaidEventSeen"], "text": "You have calc now. The flat isn't as secure as you thought." })

	if f["archiePartnerSeen"]:
		items.append({ "done": false, "text": "Archie's time vein is yours. Cultivate it. Harvest. Make pearls. Archie sells them." })

	if items.size() > 4:
		items = items.slice(items.size() - 4, items.size())
	return items


func _build_stats_card() -> Control:
	var c := UI.card()
	var arrow := "▾" if _stats_open else "▸"
	c["content"].add_child(UI.button("%s Your Stats" % arrow, _on_stats_header_pressed))

	if _stats_open:
		var player: Dictionary = GameState.state["player"]
		var atk := Combat.get_attack_range()
		c["content"].add_child(UI.label("HP: %d / %d" % [player["hp"], player["hpMax"]]))
		c["content"].add_child(UI.bar(player["hp"], player["hpMax"]))
		c["content"].add_child(UI.label("Attack: %d–%d" % [atk["min"], atk["max"]]))
		c["content"].add_child(UI.label("Crafting: Lv%d (%d XP)" % [player["craftingSkill"], player["craftingXP"]]))
		c["content"].add_child(UI.label("Cultivating: Lv%d (%d XP)" % [player["cultivatingSkill"], player["cultivatingXP"]]))
		c["content"].add_child(UI.label("Veins held: %d" % player["veins"].size()))
		c["content"].add_child(UI.label("Ore in stock: %d u" % _total_ore(player["orichalchum"])))
		c["content"].add_child(UI.button("Save & Load", func(): Nav.go_to("save")))

	return c["panel"]


func _on_stats_header_pressed() -> void:
	_stats_open = not _stats_open
	_refresh()


func _total_ore(ore_dict: Dictionary) -> int:
	var total := 0
	for qty in ore_dict.values():
		total += qty
	return total


func _build_actions_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Actions", 14))
	c["content"].add_child(UI.button("Rest", _on_rest_pressed))
	c["content"].add_child(UI.button("Veins", func(): Nav.go_to("veins")))
	c["content"].add_child(UI.button("Inventory", func(): Nav.go_to("inventory")))
	return c["panel"]


func _on_rest_pressed() -> void:
	TimeSystem.do_rest()
