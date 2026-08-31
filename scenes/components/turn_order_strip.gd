class_name TurnOrderStrip
extends Control

# combat-presentation ticket 02, docs/combat-animation-vision.md §2.4: one
# component doing nameplate + HP/status detail + turn-order + targeting, all
# at once -- replacing the on-stage name/HP labels ticket 01 kept as an
# interim measure (scenes/screens/combat.gd's _build_slot() no longer builds
# them). Rebuilt from scratch by CombatScreen._refresh() on every
# EventBus.state_changed, same as the stage -- this node holds no state of
# its own across rebuilds; CombatScreen's own _strip_selected_key instance
# var is what survives (ticket 04's persistent-node beat-queue architecture
# hasn't landed yet, so nothing here can outlive a refresh).
#
# Card content deliberately omits a "level" badge for enemies/allies -- no
# such field exists anywhere in the state model today (only
# player.combatSkill is level-like). See
# .scratch/combat-presentation/level-system.md for the scoping note on a
# real enemy/ally leveling system, deferred out of this ticket.

const CARD_HEIGHT := 88.0
const MAX_CARD_WIDTH := 96.0
const CARD_SEPARATION := 6.0
const HP_BAR_HEIGHT := 4.0
const SWIPE_THRESHOLD_PX := 40.0

# §2.4's HP-bar urgency pulse and damage-decal tiers -- draft thresholds,
# "~20%"/"~60%"/"~30%" per the vision doc's own hedged language, not exact
# balance numbers.
const PULSE_HP_FRACTION := 0.20
const CRACKED_HP_FRACTION := 0.60
const RUINED_HP_FRACTION := 0.30
const RUINED_TILT_DEGREES := -4.0

# Player/ally cards have no faction (they're not the encounter's antagonist)
# -- a fixed neutral tone distinct from both a real faction colour and the
# "UNKNOWN" grey an anonymous enemy gets.
const NEUTRAL_COLOUR := Color(0.42, 0.46, 0.55)
const UNKNOWN_COLOUR := Color(0.32, 0.32, 0.32)


# One nameplate. Public (not `_`-prefixed) so tests can address it as
# TurnOrderStrip.NameplateCard, mirroring CombatScreen.StageSlot
# (scenes/screens/combat.gd).
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
	# combat-presentation ticket 06, docs/combat-animation-vision.md §4.2: the
	# telegraphed-intent text itself, computed by _telegraph_text_for() below
	# and stashed here (rather than computed inline in _build_card_content())
	# so both that render step and tests can read the same value. Only
	# meaningful when shows_telegraph_slot is true.
	var telegraph_text: String = ""
	var is_pulsing: bool = false
	var damage_tier: int = 0  # 0 clean, 1 cracked, 2 ruined -- §2.4's decal tiers

	var telegraph_label: Label = null

	# combat-presentation ticket 05, §4.1: "HP bar lag-drain -- a ghost bar
	# chasing the real (already-updated) value down." `hp` above is already
	# the final, post-round value the instant this card is built (Combat.*
	# mutates GameState.state synchronously; see combat_director.gd's own
	# top comment) -- ghost_hp is a *separate* value CombatScreen drives
	# beat-by-beat as the round plays back, starting above `hp` and draining
	# to meet it. null (the default, and every non-"just took a hit this
	# round" card) means "no ghost -- draw the plain bar only."
	var ghost_hp: Variant = null

	func set_ghost_hp(value: float) -> void:
		ghost_hp = int(round(value))
		queue_redraw()

	func _ready() -> void:
		if damage_tier == 2:
			rotation_degrees = TurnOrderStrip.RUINED_TILT_DEGREES
		# Tests build this card without adding it to a live tree (same guard
		# notification_toast.gd's own _ready()-adjacent code uses) --
		# create_tween() requires a live tree and would error/no-op there.
		if is_pulsing and is_inside_tree():
			var tween := create_tween()
			tween.set_loops()
			tween.tween_property(self, "modulate:a", 0.5, 0.45)
			tween.tween_property(self, "modulate:a", 1.0, 0.45)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var bg_alpha: float = 0.90
		if damage_tier == 1:
			bg_alpha = 0.78
		elif damage_tier == 2:
			bg_alpha = 0.62
		draw_rect(rect, Color(0.11, 0.11, 0.13, bg_alpha), true)
		draw_rect(rect, faction_colour, false, 3.0 if is_focused else 1.5)

		# The dividing rule line doubling as the HP bar (§2.4) -- depletes by
		# length, not hue; faction_colour stays constant at every HP level.
		var bar_y: float = 20.0
		var frac: float = clampf(float(hp) / float(maxi(1, hp_max)), 0.0, 1.0)
		draw_rect(Rect2(Vector2(4.0, bar_y), Vector2(size.x - 8.0, TurnOrderStrip.HP_BAR_HEIGHT)), Color(0, 0, 0, 0.4), true)
		draw_rect(Rect2(Vector2(4.0, bar_y), Vector2((size.x - 8.0) * frac, TurnOrderStrip.HP_BAR_HEIGHT)), faction_colour, true)

		# combat-presentation ticket 05, §4.1: the ghost bar itself -- a
		# lighter overlay from the real bar's edge out to wherever ghost_hp
		# still sits, i.e. "the chunk about to drain." Nothing drawn once
		# ghost_hp catches up to (or was never above) the real value.
		if ghost_hp != null:
			var ghost_frac: float = clampf(float(ghost_hp) / float(maxi(1, hp_max)), 0.0, 1.0)
			if ghost_frac > frac:
				draw_rect(Rect2(Vector2(4.0 + (size.x - 8.0) * frac, bar_y), Vector2((size.x - 8.0) * (ghost_frac - frac), TurnOrderStrip.HP_BAR_HEIGHT)), Color(1.0, 1.0, 1.0, 0.6), true)


func build_entries(combat: Dictionary, player: Dictionary) -> Array:
	var faction_display: Dictionary = _enemy_faction_display(combat)
	var entries: Array = []
	var seen: Dictionary = {}
	for queue_entry in Combat.build_turn_queue(combat):
		# Motion (combat.motionTurns) inserts extra "extra": true player
		# entries into build_turn_queue() so the *turn queue* shows every
		# upcoming action -- the strip wants one card per living combatant
		# (per this ticket's own acceptance check), so those duplicates and
		# any other repeat of the same combatant collapse to their first
		# appearance, which is also earliest-in-order -- exactly the
		# position turn order says they act next from.
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


# §2.4's faction-colour table: defend_vein/home_raid are always anonymous
# (raid-stealth-anonymity's guard-template decision), mugging/event_mugging
# muggers have no faction at all, and raid/event_raid reveal the target
# vein's real owner since the player chose that vein. Every other/unknown
# context (e.g. archie_deal_mugging) falls through to the same UNKNOWN grey
# as mugging, by the same "no faction to reveal" reasoning.
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


# Builds every card up front (no scroll/virtualisation) -- SQUAD_MAX caps
# each side at 3, so at most 6 cards ever exist; card width shrinks to fit
# `available_width` instead, which is simpler and more testable than a
# scroll-into-view carousel and matches this ticket's "instant snap is
# acceptable" framing (ticket 04's tween-director is what earns real
# scrolling/reorder animation later).
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

# combat-presentation ticket 05: keyed the same way CombatScreen already
# keys its own persistent stage slots (-1 for the player, an array index for
# an ally/enemy) so the ghost-drain call sites on both sides can build the
# same key string independently without either side importing the other's
# key format. Rebuilt in _rebuild() below; this strip is itself rebuilt
# wholesale on every real _sync() (see this file's own top comment -- ticket
# 04's persistent-node treatment only reached the stage, not the strip), but
# NOT per-beat mid-playback (CombatScreen._on_beat_played() only calls
# _sync_footer(), never rebuilds the strip), so the same NameplateCard
# instances this dict points at are exactly the ones still on screen for a
# whole round's beat-by-beat ghost-drain animation.
var _cards_by_key: Dictionary = {}


# entry_key is {"type": "player"} / {"type": "ally", "index": i} /
# {"type": "enemy", "index": i} (see build_entries() above) -- normalized to
# a single string so Dictionary lookups here don't depend on Dictionary
# structural-equality/hash behaviour for a Dictionary-as-key.
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

	# No floor on card width -- fitting every living combatant inside
	# `available_width` without overflowing the stage takes priority over a
	# minimum readable size (Label.clip_text/OVERRUN_TRIM_ELLIPSIS on the
	# name already degrade gracefully at the SQUAD_MAX×2 = 6-combatant
	# ceiling). MAX_CARD_WIDTH only stops 1-2 combatants from stretching
	# into an absurdly wide card.
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
			card.telegraph_text = _telegraph_text_for(_combat["enemies"][entry["key"]["index"]])

	_build_card_content(card)
	_cards_by_key[card_key_string(entry["key"])] = card
	return card


# combat-presentation ticket 06, docs/combat-animation-vision.md §4.2: the
# telegraph itself -- a purely-derived read of the enemy's own persistent
# `ability` state (Combat._enemy_capabilities_from_template()'s shape),
# independent of turn order or beat-queue timing. Correct for BOTH "this is
# the enemy currently acting" and "the player swiped ahead to inspect a
# not-yet-acted enemy" (the ticket's own third acceptance check) for free,
# since it never looks at whose turn it is -- only at what this specific
# enemy would do the next time it acts. `ability.id` is rendered as raw
# capitalized text (no display-name lookup table exists -- REFERENCE.md
# §1.10: ability is "a string id", and no data/enemies.json template sets
# one yet) per this ticket's own "for now" scope note; a locked ability
# reads identically to no ability at all -- both are "about to attack" as
# far as the player can act on right now.
func _telegraph_text_for(enemy: Dictionary) -> String:
	var ability: Variant = enemy.get("ability")
	if ability != null and not Combat.is_ability_locked(enemy):
		return "Intent: %s" % String(ability["id"]).capitalize()
	return "Intent: Attacking"


# combat-presentation ticket 05, §4.1: called once, at the start of a round's
# beat-queue playback, before any beat has actually played -- sets the
# ghost bar's starting point straight to the pre-round hp (already computed
# by the caller; see combat.gd's own _init_ghost_tracker()) with no tween,
# since nothing has animated yet. A no-op if this key has no card on the
# strip right now (e.g. a beat lands on someone the strip doesn't currently
# have a card for -- shouldn't happen for a living combatant, but a caller
# ratcheting through an unknown/mistyped key should degrade silently rather
# than error, same as every other keyed lookup in this file).
func set_initial_ghost(key_string: String, hp: int) -> void:
	var card: NameplateCard = _cards_by_key.get(key_string)
	if card == null:
		return
	card.set_ghost_hp(hp)


# Tweens the named card's ghost bar down from wherever it currently sits to
# `hp` over `duration` -- called once per damaging beat that lands on this
# key, chasing the real bar down in visible steps rather than jumping there.
# Needs a live tree (create_tween() requires one) -- tests exercising this
# without one just get the instant set_initial_ghost()-style jump instead,
# same "no live tree, no tween" guard NameplateCard._ready()'s own pulse
# tween already uses.
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

	# Reserve the HP-bar's vertical space (drawn in NameplateCard._draw(),
	# not a child control) -- an empty spacer here keeps the labels below it
	# from overlapping the bar.
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

	# combat-presentation ticket 06, §4.2/§2.4: the enemy telegraph -- see
	# _telegraph_text_for() for how card.telegraph_text is derived.
	if card.shows_telegraph_slot:
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


# Public so tests can drive a swipe without simulating InputEvents (same
# "test the logic, not the gesture plumbing" split notification_toast.gd's
# tests use). direction: -1 previous / +1 next in turn-order-strip order.
# A swipe onto a non-enemy card is inert for targeting (§2.2) -- the
# callback still fires so the strip's own selection/display moves, it just
# doesn't call Combat.set_focused_enemy() (that's the caller's job: see
# scenes/screens/combat.gd's _on_strip_selection_changed()).
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
		# Dragging leftward (delta < 0) brings the next card into focus, the
		# same "content follows the finger" convention TouchScrollContainer
		# uses for scroll_horizontal.
		handle_swipe(1 if delta < 0 else -1)
