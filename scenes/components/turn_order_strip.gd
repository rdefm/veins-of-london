class_name TurnOrderStrip
extends Control


const CARD_HEIGHT := 88.0
const MAX_CARD_WIDTH := 96.0
const CARD_SEPARATION := 6.0
const HP_BAR_HEIGHT := 4.0
const SWIPE_THRESHOLD_PX := 40.0

const PULSE_HP_FRACTION := 0.20
const CRACKED_HP_FRACTION := 0.60
const RUINED_HP_FRACTION := 0.30
const RUINED_TILT_DEGREES := -4.0

const NEUTRAL_COLOUR := Color(0.42, 0.46, 0.55)
const UNKNOWN_COLOUR := Color(0.32, 0.32, 0.32)


class NameplateCard extends Control:
	var entry_key: Dictionary = {}
	var combatant_name: String = ""
	var level: Variant = null  # int, or null -- see this file's own top comment
	var hp: int = 0
	var hp_max: int = 1
	var faction_name: String = ""
	var faction_colour: Color = TurnOrderStrip.NEUTRAL_COLOUR
	var is_focused: bool = false
	var is_enemy: bool = false
	var shows_exact_hp: bool = false
	var status_lines: Array[String] = []
	var shows_telegraph_slot: bool = false
	var telegraph_text: String = ""
	var tell_image: Texture2D = null
	var tell_rect: TextureRect = null
	var is_pulsing: bool = false
	var damage_tier: int = 0  # 0 clean, 1 cracked, 2 ruined -- §2.4's decal tiers

	var telegraph_label: Label = null

	var ghost_hp: Variant = null

	func set_ghost_hp(value: float) -> void:
		ghost_hp = int(round(value))
		queue_redraw()

	func _ready() -> void:
		if damage_tier == 2:
			rotation_degrees = TurnOrderStrip.RUINED_TILT_DEGREES
		if is_pulsing and is_inside_tree():
			var tween := create_tween()
			tween.set_loops()
			tween.tween_property(self, "modulate:a", 0.5, 0.45)
			tween.tween_property(self, "modulate:a", 1.0, 0.45)
		if tell_rect != null and is_inside_tree():
			var tell_tween := create_tween()
			tell_tween.set_loops()
			tell_tween.tween_property(tell_rect, "modulate:a", 0.4, 0.5)
			tell_tween.tween_property(tell_rect, "modulate:a", 1.0, 0.5)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var bg_alpha: float = 0.90
		if damage_tier == 1:
			bg_alpha = 0.78
		elif damage_tier == 2:
			bg_alpha = 0.62
		draw_rect(rect, Color(0.11, 0.11, 0.13, bg_alpha), true)
		draw_rect(rect, faction_colour, false, 3.0 if is_focused else 1.5)

		var bar_y: float = 20.0
		var frac: float = clampf(float(hp) / float(maxi(1, hp_max)), 0.0, 1.0)
		draw_rect(Rect2(Vector2(4.0, bar_y), Vector2(size.x - 8.0, TurnOrderStrip.HP_BAR_HEIGHT)), Color(0, 0, 0, 0.4), true)
		draw_rect(Rect2(Vector2(4.0, bar_y), Vector2((size.x - 8.0) * frac, TurnOrderStrip.HP_BAR_HEIGHT)), faction_colour, true)

		if ghost_hp != null:
			var ghost_frac: float = clampf(float(ghost_hp) / float(maxi(1, hp_max)), 0.0, 1.0)
			if ghost_frac > frac:
				draw_rect(Rect2(Vector2(4.0 + (size.x - 8.0) * frac, bar_y), Vector2((size.x - 8.0) * (ghost_frac - frac), TurnOrderStrip.HP_BAR_HEIGHT)), Color(1.0, 1.0, 1.0, 0.6), true)


func build_entries(combat: Dictionary, player: Dictionary) -> Array:
	var faction_display: Dictionary = _enemy_faction_display(combat)
	var entries: Array = []
	var seen: Dictionary = {}
	for queue_entry in Combat.build_turn_queue(combat):
		var type: String = queue_entry["type"]
		var dedup_key: String = type if type == "player" else "%s:%d" % [type, queue_entry["index"]]
		if seen.has(dedup_key):
			continue
		seen[dedup_key] = true

		if type == "player":
			entries.append({
				"key": { "type": "player" }, "name": "You", "level": player["combatSkill"],
				"hp": player["hp"], "hpMax": player["hpMax"],
				"factionName": "", "factionColour": NEUTRAL_COLOUR, "isEnemy": false,
			})
		elif type == "ally":
			var ally: Dictionary = combat["allies"][queue_entry["index"]]
			entries.append({
				"key": { "type": "ally", "index": queue_entry["index"] }, "name": ally["name"], "level": null,
				"hp": ally["hp"], "hpMax": ally["hpMax"],
				"factionName": "", "factionColour": NEUTRAL_COLOUR, "isEnemy": false,
			})
		else:
			var enemy: Dictionary = combat["enemies"][queue_entry["index"]]
			entries.append({
				"key": { "type": "enemy", "index": queue_entry["index"] }, "name": enemy["name"], "level": null,
				"hp": enemy["hp"], "hpMax": enemy["hpMax"],
				"factionName": faction_display["name"], "factionColour": faction_display["colour"], "isEnemy": true,
			})
	return entries


func _enemy_faction_display(combat: Dictionary) -> Dictionary:
	var context: String = combat["context"]
	var vein_id: Variant = combat.get("veinId")
	if (context == Combat.CONTEXT_RAID or context == Combat.CONTEXT_EVENT_RAID) and vein_id != null:
		var vein: Variant = Sites.find_faction_vein(vein_id)
		if vein != null:
			var faction: Dictionary = GameData.FACTIONS[vein["factionId"]]
			return { "name": faction["shortName"], "colour": Color(faction["colour"]) }
	return { "name": "UNKNOWN", "colour": UNKNOWN_COLOUR }


func _status_lines_for(key: Dictionary, combat: Dictionary, player: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if key["type"] == "player":
		if player["shieldPool"] > 0:
			lines.append("Shielded (%d)" % player["shieldPool"])
		if combat["motionTurns"] > 0:
			lines.append("Motion (%d)" % combat["motionTurns"])
	elif key["type"] == "enemy":
		if combat["frozenTurns"] > 0:
			lines.append("Frozen (%d)" % combat["frozenTurns"])
		var enemy: Dictionary = combat["enemies"][key["index"]]
		var ability = enemy.get("ability")
		if ability != null and ability.get("lockedTurns", 0) > 0:
			lines.append("Ability locked (%d)" % ability["lockedTurns"])
	return lines


func configure(entries: Array, selected_pos: int, combat: Dictionary, player: Dictionary, available_width: float, selection_callback: Callable) -> void:
	_entries = entries
	_selected_pos = clampi(selected_pos, 0, maxi(0, entries.size() - 1))
	_combat = combat
	_player = player
	_on_selection_changed = selection_callback
	_rebuild(available_width)


var _entries: Array = []
var _selected_pos: int = 0
var _combat: Dictionary = {}
var _player: Dictionary = {}
var _on_selection_changed: Callable = Callable()

var _drag_index := -100
var _drag_start_x: float = 0.0

var _cards_by_key: Dictionary = {}


static func card_key_string(entry_key: Dictionary) -> String:
	var index: int = entry_key["index"] if entry_key["type"] != "player" else -1
	return "%s:%d" % [entry_key["type"], index]


func _rebuild(available_width: float) -> void:
	for child in get_children():
		child.queue_free()
	_cards_by_key.clear()

	custom_minimum_size = Vector2(available_width, CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var row := UI.hbox(CARD_SEPARATION)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(row)

	var n: int = maxi(1, _entries.size())
	var card_width: float = minf((available_width - CARD_SEPARATION * (n - 1)) / n, MAX_CARD_WIDTH)

	for i in range(_entries.size()):
		var card := _build_card(_entries[i], i == _selected_pos, Vector2(card_width, CARD_HEIGHT))
		row.add_child(card)

	add_child(row)


func _build_card(entry: Dictionary, is_focused: bool, card_size: Vector2) -> NameplateCard:
	var card := NameplateCard.new()
	card.custom_minimum_size = card_size
	card.size = card_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.entry_key = entry["key"]
	card.combatant_name = entry["name"]
	card.level = entry["level"]
	card.hp = entry["hp"]
	card.hp_max = entry["hpMax"]
	card.faction_name = entry["factionName"]
	card.faction_colour = entry["factionColour"]
	card.is_focused = is_focused
	card.is_enemy = entry["isEnemy"]
	card.shows_exact_hp = is_focused

	var frac: float = clampf(float(entry["hp"]) / float(maxi(1, entry["hpMax"])), 0.0, 1.0)
	card.is_pulsing = frac < PULSE_HP_FRACTION
	if frac < RUINED_HP_FRACTION:
		card.damage_tier = 2
	elif frac < CRACKED_HP_FRACTION:
		card.damage_tier = 1
	else:
		card.damage_tier = 0

	if is_focused:
		card.status_lines = _status_lines_for(entry["key"], _combat, _player)
		card.shows_telegraph_slot = entry["isEnemy"]
		if card.shows_telegraph_slot:
			var enemy: Dictionary = _combat["enemies"][entry["key"]["index"]]
			card.telegraph_text = _telegraph_text_for(enemy)
			card.tell_image = _tell_image_for(enemy)

	_build_card_content(card)
	_cards_by_key[card_key_string(entry["key"])] = card
	return card


func _telegraph_text_for(enemy: Dictionary) -> String:
	var ability: Variant = enemy.get("ability")
	if ability != null and not Combat.is_ability_locked(enemy):
		return "Intent: %s" % String(ability["id"]).capitalize()
	return "Intent: Attacking"


func _tell_image_for(enemy: Dictionary) -> Texture2D:
	var key: String = CombatStage.enemy_template_key(enemy)
	if key.is_empty():
		return null
	var entry: Dictionary = GameData.COMBAT_VISUALS.get("templates", {}).get(key, {}).get("tell", {})
	var image_path: String = entry.get("image", "")
	if image_path.is_empty() or not ResourceLoader.exists(image_path):
		return null
	return load(image_path)


func set_initial_ghost(key_string: String, hp: int) -> void:
	var card: NameplateCard = _cards_by_key.get(key_string)
	if card == null:
		return
	card.set_ghost_hp(hp)


func drain_ghost_to(key_string: String, hp: int, duration: float) -> void:
	var card: NameplateCard = _cards_by_key.get(key_string)
	if card == null:
		return
	if not card.is_inside_tree():
		card.set_ghost_hp(hp)
		return
	var from: int = card.ghost_hp if card.ghost_hp != null else card.hp
	var tween := card.create_tween()
	tween.tween_method(card.set_ghost_hp, from, hp, duration)


func _build_card_content(card: NameplateCard) -> void:
	var box := UI.vbox(1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(box)

	var top_row := UI.hbox(2)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := Label.new()
	name_label.text = card.combatant_name
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_label)

	if card.level != null:
		var level_label := Label.new()
		level_label.text = "Lv%d" % card.level
		level_label.add_theme_font_size_override("font_size", 8)
		level_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
		top_row.add_child(level_label)

	box.add_child(top_row)

	var bar_spacer := Control.new()
	bar_spacer.custom_minimum_size = Vector2(0, HP_BAR_HEIGHT + 2.0)
	bar_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bar_spacer)

	if card.shows_exact_hp:
		var hp_label := Label.new()
		hp_label.text = "%d/%d" % [card.hp, card.hp_max]
		hp_label.add_theme_font_size_override("font_size", 9)
		hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		box.add_child(hp_label)

	for line in card.status_lines:
		var status_label := Label.new()
		status_label.text = line
		status_label.clip_text = true
		status_label.add_theme_font_size_override("font_size", 8)
		status_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		box.add_child(status_label)

	if card.shows_telegraph_slot:
		if card.tell_image != null:
			var tell := TextureRect.new()
			tell.texture = card.tell_image
			tell.custom_minimum_size = Vector2(20.0, 20.0)
			tell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(tell)
			card.tell_rect = tell
		else:
			var telegraph := Label.new()
			telegraph.text = card.telegraph_text
			telegraph.clip_text = true
			telegraph.add_theme_font_size_override("font_size", 8)
			telegraph.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
			box.add_child(telegraph)
			card.telegraph_label = telegraph

	var faction_label := Label.new()
	faction_label.text = card.faction_name
	faction_label.clip_text = true
	faction_label.add_theme_font_size_override("font_size", 8)
	faction_label.add_theme_color_override("font_color", UNKNOWN_COLOUR if card.faction_name == "UNKNOWN" else card.faction_colour)
	faction_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	faction_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	box.add_child(faction_label)

	card.add_child(box)


func handle_swipe(direction: int) -> void:
	if _entries.is_empty():
		return
	var new_pos: int = clampi(_selected_pos + direction, 0, _entries.size() - 1)
	if new_pos == _selected_pos:
		return
	if _on_selection_changed.is_valid():
		_on_selection_changed.call(_entries[new_pos]["key"])


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _drag_index == -100:
				_drag_index = event.index
				_drag_start_x = event.position.x
		elif event.index == _drag_index:
			_end_drag(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _drag_index == -100:
				_drag_index = -1
				_drag_start_x = event.position.x
		elif _drag_index == -1:
			_end_drag(event.position.x)


func _end_drag(release_x: float) -> void:
	var delta: float = release_x - _drag_start_x
	_drag_index = -100
	if absf(delta) >= SWIPE_THRESHOLD_PX:
		handle_swipe(1 if delta < 0 else -1)
