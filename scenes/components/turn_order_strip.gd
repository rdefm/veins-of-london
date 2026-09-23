class_name TurnOrderStrip
extends Control


const CARD_HEIGHT := 68.0
const MAX_CARD_WIDTH := 101.0
const CARD_SEPARATION := 4.0
# §2.4: the selected card grows taller/wider, extending into the band
# reserved below the strip for a selected occurrence's expanded details.
const EXPANDED_CARD_HEIGHT := 84.0
const MAX_EXPANDED_CARD_HEIGHT := 136.0
const EXPANDED_WIDTH_BONUS_PX := 28.0
const HP_BAR_HEIGHT := 6.0
const SWIPE_THRESHOLD_PX := 40.0

const PULSE_HP_FRACTION := 0.20
const CRACKED_HP_FRACTION := 0.60
const RUINED_HP_FRACTION := 0.30
const RUINED_TILT_DEGREES := -4.0

const NEUTRAL_COLOUR := Color(0.42, 0.46, 0.55)
const UNKNOWN_COLOUR := Color(0.32, 0.32, 0.32)

const SIGN_GROUND_ID := "combat_sign_ground"
const SIGN_LETTERING_ID := "combat_sign_lettering"
const SIGN_BORDER_ID := "combat_sign_border"
const SIGN_STATUS_ID := "combat_sign_status"
const SIGN_INTENT_ID := "combat_sign_intent"
const SIGN_HP_TRACK_ID := "combat_sign_hp_track"
const SIGN_GHOST_ID := "combat_sign_ghost"
const SIGN_DAMAGE_ID := "combat_sign_damage"


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
	var name_label: Label = null
	var faction_label: Label = null

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
		var sign := StyleBoxFlat.new()
		sign.bg_color = TurnOrderStrip._palette_colour(TurnOrderStrip.SIGN_GROUND_ID)
		sign.border_color = TurnOrderStrip._palette_colour(TurnOrderStrip.SIGN_BORDER_ID)
		sign.set_border_width_all(2)
		sign.set_corner_radius_all(4)
		draw_style_box(sign, rect)

		var bar_y: float = 25.0
		var frac: float = clampf(float(hp) / float(maxi(1, hp_max)), 0.0, 1.0)
		draw_rect(Rect2(Vector2(8.0, bar_y), Vector2(size.x - 16.0, TurnOrderStrip.HP_BAR_HEIGHT)), TurnOrderStrip._palette_colour(TurnOrderStrip.SIGN_HP_TRACK_ID), true)
		draw_rect(Rect2(Vector2(8.0, bar_y), Vector2((size.x - 16.0) * frac, TurnOrderStrip.HP_BAR_HEIGHT)), faction_colour, true)

		if ghost_hp != null:
			var ghost_frac: float = clampf(float(ghost_hp) / float(maxi(1, hp_max)), 0.0, 1.0)
			if ghost_frac > frac:
				draw_rect(Rect2(Vector2(8.0 + (size.x - 16.0) * frac, bar_y), Vector2((size.x - 16.0) * (ghost_frac - frac), TurnOrderStrip.HP_BAR_HEIGHT)), TurnOrderStrip._palette_colour(TurnOrderStrip.SIGN_GHOST_ID), true)

		_draw_damage_overlay()

	func _draw_damage_overlay() -> void:
		if damage_tier == 0:
			return
		var ink := TurnOrderStrip._palette_colour(TurnOrderStrip.SIGN_DAMAGE_ID)
		# Damage stays clear of the name/HP band (y <= 28) and the bottom
		# faction line. Children render above this procedural decal as a
		# second guard against lost information.
		var right: float = size.x - 4.0
		draw_polyline(PackedVector2Array([
			Vector2(right, 4.0), Vector2(right - 7.0, 10.0),
			Vector2(right - 3.0, 17.0), Vector2(right - 10.0, 23.0),
		]), ink, 1.0)
		if damage_tier < 2:
			return
		draw_polyline(PackedVector2Array([
			Vector2(3.0, 38.0), Vector2(10.0, 44.0), Vector2(5.0, 53.0),
		]), ink, 1.0)
		# A small mid-edge chip; never intersects the protected information bands.
		draw_colored_polygon(PackedVector2Array([
			Vector2(size.x, 48.0), Vector2(size.x - 7.0, 52.0), Vector2(size.x, 57.0),
		]), TurnOrderStrip._palette_colour(TurnOrderStrip.SIGN_BORDER_ID))


# One card per turn *occurrence* (CONTEXT.md's Turn occurrence), not one
# per unique combatant. Reads Combat.project_queue()'s bounded horizon
# (R§3.7a) -- a repeated occurrence (a Motion-inserted extra turn, or the
# same combatant's next-round turn) gets its own card, no deduplication.
# "key" (combatant identity, used for selection/ghosting) and
# "occurrenceId" (this specific card's identity) are deliberately separate
# fields -- several entries can share a key.
func build_entries(combat: Dictionary, player: Dictionary) -> Array:
	return build_entries_for(Combat.project_queue(combat), combat, player)


# Same card data as build_entries(), for an arbitrary occurrence list --
# playback lays out intermediate queues (playback_occurrences()) that no
# single live projection produces.
func build_entries_for(occurrences: Array, combat: Dictionary, player: Dictionary) -> Array:
	var faction_display: Dictionary = _enemy_faction_display(combat)
	var entries: Array = []
	for occurrence in occurrences:
		var type: String = occurrence["type"]

		if type == "player":
			entries.append({
				"key": { "type": "player" }, "occurrenceId": occurrence["occurrenceId"],
				"name": "You", "level": player["combatSkill"],
				"hp": player["hp"], "hpMax": player["hpMax"],
				"factionName": "", "factionColour": NEUTRAL_COLOUR, "isEnemy": false,
			})
		elif type == "ally":
			var ally: Dictionary = combat["allies"][occurrence["index"]]
			entries.append({
				"key": { "type": "ally", "index": occurrence["index"] }, "occurrenceId": occurrence["occurrenceId"],
				"name": ally["name"], "level": null,
				"hp": ally["hp"], "hpMax": ally["hpMax"],
				"factionName": "", "factionColour": NEUTRAL_COLOUR, "isEnemy": false,
			})
		else:
			var enemy: Dictionary = combat["enemies"][occurrence["index"]]
			entries.append({
				"key": { "type": "enemy", "index": occurrence["index"] }, "occurrenceId": occurrence["occurrenceId"],
				"name": enemy["name"], "level": null,
				"hp": enemy["hp"], "hpMax": enemy["hpMax"],
				"factionName": faction_display["name"], "factionColour": faction_display["colour"], "isEnemy": true,
			})
	return entries


# "round:index" occurrenceId -> a lexicographically comparable pair.
static func occurrence_rank(occurrence_id: String) -> Vector2i:
	var parts: PackedStringArray = occurrence_id.split(":")
	return Vector2i(int(parts[0]), int(parts[1]))


# §2.4 Reflow: the occurrences the strip shows once playback has reached
# `threshold_id` -- every occurrence after it (and the threshold itself
# when `inclusive`, as reversed Rewind playback re-reveals the card its
# beat belongs to), cut to Combat.project_queue()'s horizon (R§3.7a): the
# first shown occurrence's round plus one more. Each round is
# read from one source, never merged by id -- two sources' "r:i" ids can
# name different combatants once a KO reshapes a rebuilt round:
# - `target`: the live state's whole committed round (project_queue(...,
#   true)) plus its projected next round; its committed round wins.
# - `earlier`: the projection shown before the action (or before Rewind).
# - `beats`: each beat's own `occurrence` tag, the last resort.
static func playback_occurrences(threshold_id: String, inclusive: bool, target: Array, earlier: Array, beats: Array) -> Array:
	var threshold: Vector2i = occurrence_rank(threshold_id)
	var committed_round: int = occurrence_rank(target[0]["occurrenceId"]).x if not target.is_empty() else -1
	var from_beats: Array = _beat_occurrences(beats)
	var shown: Array = []
	for round_num in [threshold.x, threshold.x + 1, threshold.x + 2]:
		var source: Array = _occurrences_in_round(target, round_num) if round_num == committed_round else []
		for candidate in [earlier, target, from_beats]:
			if not source.is_empty():
				break
			source = _occurrences_in_round(candidate, round_num)
		for occurrence in source:
			var rank: Vector2i = occurrence_rank(occurrence["occurrenceId"])
			if rank > threshold or (inclusive and rank == threshold):
				shown.append(occurrence)
	if shown.is_empty():
		return shown
	var last_round: int = occurrence_rank(shown[0]["occurrenceId"]).x + 1
	return shown.filter(func(o): return occurrence_rank(o["occurrenceId"]).x <= last_round)


static func _occurrences_in_round(occurrences: Array, round_num: int) -> Array:
	return occurrences.filter(func(o): return occurrence_rank(o["occurrenceId"]).x == round_num)


static func _beat_occurrences(beats: Array) -> Array:
	var by_id: Dictionary = {}
	for beat in beats:
		var occurrence: Variant = beat.get("occurrence")
		if occurrence != null:
			by_id[occurrence["occurrenceId"]] = occurrence
	var occurrences: Array = by_id.values()
	occurrences.sort_custom(func(a, b): return occurrence_rank(a["occurrenceId"]) < occurrence_rank(b["occurrenceId"]))
	return occurrences


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


# selected_pos indexes into `entries` only to seed which *combatant*
# starts out selected -- every entry sharing that combatant's key renders
# selected, since several entries can be the same combatant's occurrences.
# The scroll offset survives a re-configure, so an unrelated refresh never
# yanks the viewport away from what the player is inspecting.
func configure(entries: Array, selected_pos: int, combat: Dictionary, player: Dictionary, available_width: float, selection_callback: Callable) -> void:
	_entries = entries
	var clamped_pos: int = clampi(selected_pos, 0, maxi(0, entries.size() - 1))
	var new_key: Dictionary = entries[clamped_pos]["key"] if not entries.is_empty() else {}
	var selection_changed: bool = new_key != _selected_key
	_selected_key = new_key
	_combat = combat
	_player = player
	_on_selection_changed = selection_callback
	_rebuild(available_width)
	# Whatever drove a new selection (a sprite tap, most often -- a card tap
	# is already visible by definition) may have picked an occurrence that
	# scrolled off the current viewport; land it back in view.
	if selection_changed:
		_reveal_pos(clamped_pos)


# §2.4 Reflow: swaps in the queue as it stands after a played beat. Cards
# are rebuilt at once (the layout is always the final one for this step);
# the row then slides from where the surviving cards were, and newly
# revealed occurrences fade in -- one tween, cut short by the next call or
# finish_advance(). `combat`/`player` refresh card content only.
func advance_to(entries: Array, combat: Dictionary, player: Dictionary, duration: float) -> void:
	var old_x: Dictionary = {}
	for i in range(mini(_entries.size(), _card_rects.size())):
		old_x[_entries[i]["occurrenceId"]] = _card_rects[i].position.x
	_entries = entries
	_combat = combat
	_player = player
	_rebuild(_available_width)
	if duration <= 0.0 or not is_inside_tree():
		return

	var shift: float = 0.0
	for i in range(_entries.size()):
		var occurrence_id: String = _entries[i]["occurrenceId"]
		if old_x.has(occurrence_id):
			shift = old_x[occurrence_id] - _card_rects[i].position.x
			break
	_advance_tween = create_tween().set_parallel(true)
	_row.position.x = -_scroll_offset + shift
	_advance_tween.tween_property(_row, "position:x", -_scroll_offset, duration)
	var cards: Array[Node] = _row.get_children()
	for i in range(cards.size()):
		var card: NameplateCard = cards[i]
		if not old_x.has(_entries[i]["occurrenceId"]) and not card.is_pulsing:
			card.modulate.a = 0.0
			_advance_tween.tween_property(card, "modulate:a", 1.0, duration)


func finish_advance() -> void:
	if _advance_tween != null and _advance_tween.is_valid():
		_advance_tween.custom_step(999999.0)
	_advance_tween = null


# Playback starts from the front of the queue (§2.4).
func reset_scroll() -> void:
	_scroll_offset = 0.0
	if _row != null:
		_row.position.x = 0.0


func clear_ghosts() -> void:
	_ghost_hp_by_key.clear()
	for cards in _cards_by_key.values():
		for card: NameplateCard in cards:
			card.ghost_hp = null
			card.queue_redraw()


var _entries: Array = []
var _selected_key: Dictionary = {}
var _combat: Dictionary = {}
var _player: Dictionary = {}
var _on_selection_changed: Callable = Callable()

var _drag_index := -100
var _drag_start_x: float = 0.0

var _row: HBoxContainer = null
var _available_width: float = 0.0
# Content-space (pre-scroll) rect per entry, in _entries order -- built
# once in _rebuild(). Only the selected entry's rect differs in size from
# the rest, so tap hit-testing and scroll-into-view both read this instead
# of assuming a uniform stride.
var _card_rects: Array[Rect2] = []
var _scroll_offset: float = 0.0
var _max_scroll: float = 0.0

# combatant key string -> Array[NameplateCard]; several occurrence cards
# can share one combatant, so ghost draining (set_initial_ghost/
# drain_ghost_to) fans out to every card of the damaged combatant.
var _cards_by_key: Dictionary = {}
# combatant key string -> ghost hp, re-applied to the fresh cards every
# _rebuild() so a queue advance mid-playback never drops a draining ghost.
var _ghost_hp_by_key: Dictionary = {}
var _advance_tween: Tween = null


static func _palette_colour(id: String) -> Color:
	return GameData.PALETTE[id]


static func card_key_string(entry_key: Dictionary) -> String:
	var index: int = entry_key["index"] if entry_key["type"] != "player" else -1
	return "%s:%d" % [entry_key["type"], index]


func _rebuild(available_width: float) -> void:
	finish_advance()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_cards_by_key.clear()

	_available_width = available_width
	# The strip's own reserved height never changes with selection (§2.4:
	# nothing below it moves when a card expands) -- it's always tall
	# enough for the one card that's always selected.
	custom_minimum_size = Vector2(available_width, MAX_EXPANDED_CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true

	_row = UI.hbox(CARD_SEPARATION)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var base_width: float = MAX_CARD_WIDTH

	_card_rects = []
	var x: float = 0.0
	for i in range(_entries.size()):
		var entry: Dictionary = _entries[i]
		var is_selected: bool = entry["key"] == _selected_key
		var w: float = base_width + (EXPANDED_WIDTH_BONUS_PX if is_selected else 0.0)
		var h: float = _expanded_height_for(entry) if is_selected else CARD_HEIGHT
		_card_rects.append(Rect2(Vector2(x, 0.0), Vector2(w, h)))
		x += w + CARD_SEPARATION
	var total_width: float = maxf(0.0, x - CARD_SEPARATION)
	_row.custom_minimum_size = Vector2(total_width, MAX_EXPANDED_CARD_HEIGHT)
	_max_scroll = maxf(0.0, total_width - available_width)
	_scroll_offset = clampf(_scroll_offset, 0.0, _max_scroll)
	_row.position.x = -_scroll_offset

	for i in range(_entries.size()):
		var entry: Dictionary = _entries[i]
		var is_selected: bool = entry["key"] == _selected_key
		var card := _build_card(entry, is_selected, _card_rects[i].size)
		card.size_flags_vertical = Control.SIZE_FILL if is_selected else Control.SIZE_SHRINK_BEGIN
		_row.add_child(card)

	add_child(_row)


func _expanded_height_for(entry: Dictionary) -> float:
	var statuses := _status_lines_for(entry["key"], _combat, _player)
	if not statuses.is_empty():
		return MAX_EXPANDED_CARD_HEIGHT
	if entry["isEnemy"]:
		var enemy: Dictionary = _combat["enemies"][entry["key"]["index"]]
		if _telegraph_text_for(enemy).length() > 20:
			return MAX_EXPANDED_CARD_HEIGHT
	return EXPANDED_CARD_HEIGHT


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
	var key_string: String = card_key_string(entry["key"])
	if not _cards_by_key.has(key_string):
		_cards_by_key[key_string] = []
	_cards_by_key[key_string].append(card)
	if _ghost_hp_by_key.has(key_string):
		card.ghost_hp = _ghost_hp_by_key[key_string]
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


# Fans out to every occurrence card of this combatant -- a damaged
# combatant's ghost bar drains identically on each of its cards.
func set_initial_ghost(key_string: String, hp: int) -> void:
	_ghost_hp_by_key[key_string] = hp
	for card: NameplateCard in _cards_by_key.get(key_string, []):
		card.set_ghost_hp(hp)


func drain_ghost_to(key_string: String, hp: int, duration: float) -> void:
	_ghost_hp_by_key[key_string] = hp
	for card: NameplateCard in _cards_by_key.get(key_string, []):
		if not card.is_inside_tree():
			card.set_ghost_hp(hp)
			continue
		var from: int = card.ghost_hp if card.ghost_hp != null else card.hp
		var tween: Tween = card.create_tween()
		tween.tween_method(card.set_ghost_hp, from, hp, duration)


func _build_card_content(card: NameplateCard) -> void:
	var box := UI.vbox(1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.offset_left = 8.0
	box.offset_top = 4.0
	box.offset_right = -8.0
	box.offset_bottom = -5.0
	UI.anchor_full_rect(box)

	var top_row := UI.hbox(2)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := Label.new()
	name_label.text = card.combatant_name
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", _palette_colour(SIGN_LETTERING_ID))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_label)
	card.name_label = name_label

	if card.level != null:
		var level_label := Label.new()
		level_label.text = "Lv%d" % card.level
		level_label.add_theme_font_size_override("font_size", 9)
		level_label.add_theme_color_override("font_color", _palette_colour(SIGN_LETTERING_ID))
		top_row.add_child(level_label)

	box.add_child(top_row)

	var bar_spacer := Control.new()
	bar_spacer.custom_minimum_size = Vector2(0, HP_BAR_HEIGHT + 8.0)
	bar_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bar_spacer)

	if card.shows_exact_hp:
		var hp_label := Label.new()
		hp_label.text = "%d/%d HP" % [card.hp, card.hp_max]
		hp_label.add_theme_font_size_override("font_size", 10)
		hp_label.add_theme_color_override("font_color", _palette_colour(SIGN_LETTERING_ID))
		box.add_child(hp_label)

	for line in card.status_lines:
		var status_label := Label.new()
		status_label.text = line
		status_label.clip_text = true
		status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		status_label.add_theme_font_size_override("font_size", 9)
		status_label.add_theme_color_override("font_color", _palette_colour(SIGN_STATUS_ID))
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
			telegraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			telegraph.max_lines_visible = 2
			telegraph.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			telegraph.custom_minimum_size.y = 22.0
			telegraph.add_theme_font_size_override("font_size", 10)
			telegraph.add_theme_color_override("font_color", _palette_colour(SIGN_INTENT_ID))
			box.add_child(telegraph)
			card.telegraph_label = telegraph

	var faction_label := Label.new()
	faction_label.text = card.faction_name
	faction_label.clip_text = true
	faction_label.add_theme_font_size_override("font_size", 9)
	faction_label.add_theme_color_override("font_color", UNKNOWN_COLOUR if card.faction_name == "UNKNOWN" else card.faction_colour)
	faction_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	faction_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	box.add_child(faction_label)
	card.faction_label = faction_label

	card.add_child(box)


# Tapping any card selects its combatant (full tap/sprite/arrow treatment
# lives in docs/combat-animation-vision.md §2.4). A tap outside any card
# is a no-op.
func handle_tap(x: float) -> void:
	var idx: int = _entry_index_at_x(x)
	if idx == -1:
		return
	if _on_selection_changed.is_valid():
		_on_selection_changed.call(_entries[idx]["key"])


# Moves only the strip's own scroll offset, clamped to the content's
# actual overflow -- never touches selection, GameState, or the turn
# queue (R§3.7a's read-only projection contract carries into the UI).
func handle_drag(delta_x: float) -> void:
	if _entries.is_empty() or _row == null:
		return
	_scroll_offset = clampf(_scroll_offset - delta_x, 0.0, _max_scroll)
	_row.position.x = -_scroll_offset


# Cards aren't uniform width (the selected one is wider, EXPANDED_WIDTH_
# BONUS_PX), so a tap's target card is a lookup against _card_rects rather
# than a stride formula; a tap landing in the gap between cards hits nothing.
func _entry_index_at_x(x: float) -> int:
	var content_x: float = x + _scroll_offset
	for i in range(_card_rects.size()):
		var r: Rect2 = _card_rects[i]
		if content_x >= r.position.x and content_x <= r.position.x + r.size.x:
			return i
	return -1


# Scrolls just enough to bring entry `pos`'s card fully into the viewport
# -- a no-op if it's already visible. Used by configure() so a selection
# made from an off-screen sprite (R§2.4) doesn't leave its card hidden.
func _reveal_pos(pos: int) -> void:
	if pos < 0 or pos >= _card_rects.size() or _row == null:
		return
	var r: Rect2 = _card_rects[pos]
	if r.position.x < _scroll_offset:
		_scroll_offset = maxf(0.0, r.position.x)
	elif r.position.x + r.size.x > _scroll_offset + _available_width:
		_scroll_offset = minf(_max_scroll, r.position.x + r.size.x - _available_width)
	_row.position.x = -_scroll_offset


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
		handle_drag(delta)
	else:
		handle_tap(release_x)
