class_name CombatScreen
extends Control

var _content: VBoxContainer

# combat-presentation ticket 02, docs/combat-animation-vision.md §2.5: which
# turn-order-strip card is currently displayed as "focused" (exact HP,
# status, telegraph slot) -- survives across _sync() rebuilds (only some of
# _content's children are freed, not this screen node itself) since
# TurnOrderStrip holds no state of its own.
# Empty until the first _sync() picks a starting card (the enemy at
# combat.focusedEnemyIndex, or entries[0] if there's no enemy). A swipe to a
# non-enemy card updates this without ever touching combat.focusedEnemyIndex
# (§2.2: only enemies are valid attack targets) -- see
# _on_strip_selection_changed() below.
var _strip_selected_key: Dictionary = {}

# combat-presentation ticket 03, docs/combat-animation-vision.md §2.5: which
# player.dial.loadedComplications index the Dial widget currently has
# selected -- survives across _sync() rebuilds the same way
# _strip_selected_key does (DialWidget itself holds no state of its own;
# see that file's own class comment). Only ever moves via the widget's own
# rotate gesture (_on_dial_selection_changed below), never reset by a
# refresh, so casting mid-fight doesn't silently jump the selection back to
# index 0.
var _dial_selected_index: int = 0

# combat-presentation ticket 01, docs/combat-animation-vision.md §2/§2.2/§9:
# the stage window every living combatant on both sides fans out on.
#
# UI.screen_body() reserves 16px margins on each side (scenes/components/
# ui.gd) inside the 390-wide project viewport (project.godot) -- the stage's
# real on-screen width is what's left after those margins, not the literal
# 390 the vision doc's "390×360 stage window" describes. That number is the
# full-bleed design target a later ticket (real backdrop plates going edge-
# to-edge) needs to break out of the shared screen_body() margin for; giving
# the stage the literal 390 here would force it 32px wider than the screen
# has room for and push it past the right edge.
const STAGE_WIDTH := 390.0 - 16.0 - 16.0
const STAGE_HEIGHT := 360.0
const ENEMY_BAND_HEIGHT := STAGE_HEIGHT / 3.0
const PLAYER_BAND_HEIGHT := STAGE_HEIGHT - ENEMY_BAND_HEIGHT

# Near/far diagonal fan (§2, §2.2 refinement): the front slot is large and
# foreground; the other two are smaller and staggered behind it, not laid
# out flat left-to-right. Sized as a fraction of whichever band they're in
# so the same math serves both the (shorter) enemy band and the (taller)
# player+ally band.
const FAN_FRONT_SIZE_RATIO := Vector2(0.30, 0.62)
const FAN_BACK_SIZE_RATIO := Vector2(0.20, 0.42)

# Placement fractions for _fan_local_rects(): how far the two back slots
# tuck under the front slot's edges (as a fraction of a back slot's own
# width), and how far each slot sits from its band's near/far edge (as a
# fraction of band height). back-right sits slightly lower than back-left
# purely to read as "behind at a different depth" rather than a mirrored
# pair -- an arbitrary but deliberate asymmetry, not a bug.
const FAN_BACK_LEFT_TUCK := 0.9
const FAN_BACK_RIGHT_TUCK := 0.1
const FAN_FRONT_BOTTOM_MARGIN := 0.03
const FAN_BACK_LEFT_TOP_MARGIN := 0.04
const FAN_BACK_RIGHT_TOP_MARGIN := 0.12

# combat-presentation ticket 03, §2.5: the Dial widget's docked-right column
# width -- narrow enough to leave the action-card row its space, wide enough
# for the clock-face/bezel placeholder shapes (DialWidget._draw()) to read.
const DIAL_WIDTH := 64.0

# Placeholder fill colours keyed by template id (name), per the ticket --
# "coloured, labelled box/silhouette keyed by template id, not real art".
# Ticket 09 swaps these for real per-template sprites via the manifest
# ticket 08 introduces; this list is not meant to be exhaustive or final.
const _PLACEHOLDER_PALETTE: Array[Color] = [
	Color(0.55, 0.33, 0.33),
	Color(0.33, 0.47, 0.55),
	Color(0.42, 0.52, 0.33),
	Color(0.48, 0.38, 0.58),
	Color(0.58, 0.48, 0.30),
	Color(0.33, 0.55, 0.50),
]


# A single fanned combatant placeholder: a coloured box with a hard border,
# plus (when `is_focused`) the thin outline/glow §2.2 calls for on whichever
# enemy `combat.focusedEnemyIndex` currently points at. Public (not `_`-
# prefixed) so tests can address it as CombatScreen.StageSlot.
class StageSlot extends Control:
	var combatant_name: String = ""
	var fill_color: Color = Color.WHITE
	var is_focused: bool = false

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, fill_color, true)
		draw_rect(rect, Color(0, 0, 0, 0.55), false, 2.0)
		if is_focused:
			draw_rect(rect.grow(3.0), Color(1.0, 0.86, 0.35, 0.95), false, 3.0)
	# combat-presentation ticket 02: the placeholder box itself carries no
	# name/HP label any more (see _build_slot() below) -- combatant_name is
	# still set, purely as the template-id key _placeholder_color() and tests
	# read, not for display.


# combat-presentation ticket 04, docs/combat-animation-vision.md §8: the
# stage's placeholder Controls are created once per fight and never
# queue_free()'d on an ordinary turn any more -- only when a specific
# combatant is actually koed does _sync_band() free that one slot, never the
# rest of the band. This is what "persistent combatant nodes" means
# architecturally: a later ticket's real sprite/AnimationPlayer work (08/09)
# needs Node identity that survives across turns, which the old
# per-state_changed queue_free() of the entire stage made impossible (see
# that doc's §8).
#
# Keyed by the combatant's own stable index (combat.enemies'/combat.allies'
# own array index, -1 for the player) rather than by fan display position --
# a combatant's display position (front/back-left/back-right) can change
# turn to turn (a kill re-ranks who's fan-front among the survivors), and an
# earlier positional-pool version of this got that wrong: popping "the last
# position" to shrink the pool could free a *survivor's* slot while leaving
# a dead combatant's slot to be silently repurposed for someone else. Keying
# by stable identity means a slot is only ever freed when the specific
# combatant it represents is actually koed.
var _enemy_slots: Dictionary = {}  # enemy index (int) -> StageSlot
var _player_slots: Dictionary = {}  # -1 (player) or ally index (int) -> StageSlot
var _enemy_band_layer: Control
var _player_band_layer: Control

# The stage frame, the turn-order strip, and the footer (command deck, or
# the log + outcome button once the fight resolves) are each held in their
# own fixed-position holder so _sync() can rebuild just one of them without
# disturbing _content's child order -- see _ready() below.
var _stage_frame: Panel
var _heading: Label
var _pacing_button: Button
var _strip_holder: VBoxContainer
var _footer_holder: VBoxContainer

# combat-presentation ticket 04: paces a round's beat queue back onto the
# screen -- see scenes/components/combat_director.gd's own class comment for
# why GameState is already final by the time this plays anything.
var _director: CombatDirector

# How many of combat.log's lines the footer's log box is currently allowed
# to show; -1 means "show everything" (the default, and where this always
# ends up once a round's playback finishes or wasn't triggered through the
# screen at all -- e.g. a system test calling Combat.player_attack()
# directly never touches this). Set to the pre-round log size when a round
# starts playing, then advanced one line per beat by _on_beat_played() --
# see _play_round() below.
var _revealed_log_count: int = -1


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)

	_director = CombatDirector.new()
	add_child(_director)

	# combat-presentation ticket 04: the player-facing half of
	# CombatDirector's persisted pacing toggle (CombatPacing, same
	# systems-own-the-schema split as MapEvents.pacing_mode()) -- without a
	# real control calling _director.set_pacing(), "quick" pacing would be
	# fully wired end to end yet unreachable in an actual playthrough.
	var heading_row := UI.hbox(8)
	_heading = UI.heading("")
	heading_row.add_child(_heading)
	_pacing_button = UI.button("", _on_pacing_button_pressed)
	heading_row.add_child(_pacing_button)
	_content.add_child(heading_row)

	_strip_holder = UI.vbox(0)
	_content.add_child(_strip_holder)

	_stage_frame = _build_stage_skeleton()
	_content.add_child(_stage_frame)

	_footer_holder = UI.vbox(8)
	_content.add_child(_footer_holder)

	EventBus.state_changed.connect(_sync)
	_sync()


# combat-presentation ticket 04: replaces the old _refresh(), which
# queue_free()'d every child of _content on every EventBus.state_changed --
# the stage's combatant placeholders (_enemy_slots/_player_slots) now update
# their bound state in place instead (_sync_stage() below). The turn-order
# strip and footer (command deck, or the log + outcome button) still rebuild
# their own contents each call -- neither carries a sprite, tween, or
# AnimationPlayer that needs to survive a turn (TurnOrderStrip/DialWidget are
# plain vector UI, not the "combatant nodes" §8 is about), so there's nothing
# for a full rebuild there to interrupt.
func _sync() -> void:
	var combat: Dictionary = GameState.state["combat"]
	var player: Dictionary = GameState.state["player"]

	_heading.text = _context_label(combat["context"])
	_pacing_button.text = _pacing_button_label()

	for child in _strip_holder.get_children():
		child.queue_free()
	_strip_holder.add_child(_build_turn_order_strip(combat, player))

	_sync_stage(combat, player)

	_sync_footer(combat, player)


func _pacing_button_label() -> String:
	return "⏱ Quick" if _director.pacing_mode == "quick" else "⏱ Normal"


func _on_pacing_button_pressed() -> void:
	_director.set_pacing("normal" if _director.pacing_mode == "quick" else "quick")
	_pacing_button.text = _pacing_button_label()


func _context_label(context: String) -> String:
	if context == "home_raid":
		return "Home Raid"
	if context == "raid":
		return "Raid"
	if context == "defend_vein":
		return "Defend"
	if context == Combat.CONTEXT_ARCHIE_DEAL_MUGGING:
		return "Archie's Deal"
	return "Mugging"


# combat-presentation ticket 03, §2.5: mid-fight, the log moves inside the
# command deck (it shares the Dial widget's full-height span with the
# action-card row); once the fight's over there's no command deck to share
# it with, so it renders directly here, same as before.
func _sync_footer(combat: Dictionary, player: Dictionary) -> void:
	for child in _footer_holder.get_children():
		child.queue_free()
	# combat-presentation ticket 04: the outcome button (which calls
	# Combat.exit_combat() and tears this screen down) only ever appears
	# once the director has fully finished playing the beat queue back --
	# never while _director.is_playing(), even if this round's beats
	# already resolved the fight. Without this gate, a player could tap
	# Continue mid-playback and free this screen out from under
	# _play_round()'s still-pending `await _director.play(...)`, which
	# would then try to call back into a freed CombatScreen instance.
	# map_canvas.gd's own MapEvents.abandon_playback()/Nav.go_to() guard
	# solves the equivalent problem for map-event playback; not reusing
	# that machinery here (this screen's playback can only ever be exited
	# via this one button, unlike the map's several navigate-away paths) --
	# simply not offering the exit while playback is live closes the same
	# hole with much less code.
	if combat["outcome"] != null and not _director.is_playing():
		_footer_holder.add_child(_build_log(combat))
		_footer_holder.add_child(_build_outcome_button(combat["outcome"], combat["context"]))
	else:
		_footer_holder.add_child(_build_command_deck(combat, player))


# combat-presentation ticket 02, §2.4: the one component doing nameplate +
# HP/status detail + turn order + targeting, replacing the on-stage name/HP
# labels _build_slot() used to carry as an interim measure (now removed --
# see that func's own comment).
#
# _strip_selected_key survives across refreshes (this screen node does, even
# though _content's children don't); this picks the entries[] position it
# still refers to, or falls back to whichever card carries
# combat.focusedEnemyIndex, or the first card, the first time a fight starts.
func _build_turn_order_strip(combat: Dictionary, player: Dictionary) -> Control:
	var strip := TurnOrderStrip.new()
	var entries: Array = strip.build_entries(combat, player)
	var selected_pos := _selected_strip_pos(entries, combat)
	if selected_pos >= 0:
		_strip_selected_key = entries[selected_pos]["key"]
	strip.configure(entries, maxi(0, selected_pos), combat, player, STAGE_WIDTH, _on_strip_selection_changed)
	return strip


func _selected_strip_pos(entries: Array, combat: Dictionary) -> int:
	for i in range(entries.size()):
		if entries[i]["key"] == _strip_selected_key:
			return i
	for i in range(entries.size()):
		var key: Dictionary = entries[i]["key"]
		if key["type"] == "enemy" and key["index"] == combat["focusedEnemyIndex"]:
			return i
	return 0 if not entries.is_empty() else -1


# Swiping to an enemy card is the targeting gesture (§2.2) -- routed through
# Combat.set_focused_enemy() since screens never mutate GameState.state
# directly; that call emits state_changed, which drives _sync() itself.
# Swiping to the player/an ally card is inert for targeting but still moves
# which card is displayed as focused, so _sync() is called directly
# (nothing in GameState changed, so nothing would otherwise trigger it).
func _on_strip_selection_changed(new_key: Dictionary) -> void:
	_strip_selected_key = new_key
	if new_key["type"] == "enemy":
		Combat.set_focused_enemy(new_key["index"])
	else:
		_sync()


# §9's "lit-window frame": a recessed dark inset with a hard 2px border and
# a slight inner vignette, embedded in the surrounding parchment/vector
# chrome -- so the pixel stage reads as a window onto the street even before
# any backdrop art exists (ticket 08 adds the real per-context plates).
#
# combat-presentation ticket 04: built once, in _ready() -- the frame, its
# vignette, and the two band layers (_enemy_band_layer/_player_band_layer)
# are never rebuilt; only the placeholder slots living inside the band
# layers change, via _sync_stage()/_sync_band() below.
func _build_stage_skeleton() -> Panel:
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(STAGE_WIDTH, STAGE_HEIGHT)
	frame.clip_contents = true

	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.07, 0.07, 0.09)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = Color(0, 0, 0, 0.65)
	frame.add_theme_stylebox_override("panel", frame_style)
	# Panel (like PanelContainer, per ui.gd's card() comment) defaults to
	# MOUSE_FILTER_STOP, which would swallow a scroll drag that starts over
	# the stage before it reaches screen_body()'s ancestor
	# TouchScrollContainer (bugfixes ticket 16). Nothing inside the stage is
	# interactive (every slot is MOUSE_FILTER_IGNORE), so PASS costs nothing.
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	# combat-presentation ticket 04: tap-to-fast-forward (§8) -- a tap
	# anywhere on the stage while the director is mid-playback snaps the
	# current beat's pause, same "tap advances the current one-shot" gesture
	# MapCanvas._skip_current() offers over the map's own event playback.
	frame.gui_input.connect(_on_stage_gui_input)

	_enemy_band_layer = Control.new()
	_enemy_band_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_enemy_band_layer)

	_player_band_layer = Control.new()
	_player_band_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_player_band_layer)

	frame.add_child(_build_vignette())

	return frame


func _on_stage_gui_input(event: InputEvent) -> void:
	if not _director.is_playing():
		return
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
	if pressed:
		_director.fast_forward_current_beat()


func _sync_stage(combat: Dictionary, player: Dictionary) -> void:
	var enemy_entries := _enemy_display_entries(combat["enemies"], combat["focusedEnemyIndex"])
	_sync_band(_enemy_slots, _enemy_band_layer, enemy_entries, Vector2(STAGE_WIDTH, ENEMY_BAND_HEIGHT), Vector2.ZERO)

	var player_entries := _player_display_entries(player, combat["allies"])
	_sync_band(_player_slots, _player_band_layer, player_entries, Vector2(STAGE_WIDTH, PLAYER_BAND_HEIGHT), Vector2(0.0, ENEMY_BAND_HEIGHT))


# Up to Combat.SQUAD_MAX non-koed enemies, fanned in their existing
# combat.enemies array order, tagged with whether they're the glow target.
# Builds fresh display dicts rather than reusing combat["enemies"]' own
# entries -- SCREENS never mutate GameState.state, and later attaching an
# "isFocused" key onto a live state dict would do exactly that. `index` is
# combat.enemies' own array index -- stable for this enemy's whole life in
# the fight, used by _sync_band() below to key each combatant's persistent
# StageSlot by identity rather than by fan display position.
func _enemy_display_entries(enemies: Array, focused_index: int) -> Array:
	var display: Array = []
	for i in range(enemies.size()):
		if not enemies[i]["koed"]:
			var enemy: Dictionary = enemies[i]
			display.append({ "name": enemy["name"], "isFocused": i == focused_index, "index": i })
			if display.size() >= Combat.SQUAD_MAX:
				break
	return display


# The player (always the fan's front/large slot -- they're the one
# character guaranteed present) plus up to SQUAD_MAX - 1 non-koed allies.
# The glow is enemy-only (§2.2), so isFocused is always false here. -1 is
# the player's own stable key (never a valid combat.allies index); an
# ally's `index` is its own combat.allies array index, same "stable for its
# whole life in the fight" role as an enemy's.
# 44-archie-combat-ally: koed allies stay in combat["allies"] (so
# knock_out()'s cooldown has something to key off), so they're filtered out
# here rather than at the state layer, same as the old card-list code did.
func _player_display_entries(player: Dictionary, allies: Array) -> Array:
	var display: Array = [{ "name": "You", "isFocused": false, "index": -1 }]
	for i in range(allies.size()):
		if not allies[i]["koed"]:
			display.append({ "name": allies[i]["name"], "isFocused": false, "index": i })
			if display.size() >= Combat.SQUAD_MAX:
				break
	return display


# combat-presentation ticket 04: reconciles `pool` (one of _enemy_slots/
# _player_slots, keyed by each combatant's own stable index -- see
# _enemy_display_entries()/_player_display_entries() above) against
# `display_entries` instead of rebuilding the band from scratch. A slot is
# only ever created the first time its combatant is displayed and only ever
# freed once that specific combatant is koed -- a survivor's slot is the
# exact same Node turn to turn even as its own fan *position* (front/
# back-left/back-right) reflows around who else is still standing.
func _sync_band(pool: Dictionary, layer: Control, display_entries: Array, band_size: Vector2, band_origin: Vector2) -> void:
	var live_keys: Dictionary = {}
	for entry in display_entries:
		live_keys[entry["index"]] = true
	for key in pool.keys().duplicate():
		if not live_keys.has(key):
			var stale: StageSlot = pool[key]
			layer.remove_child(stale)
			stale.queue_free()
			pool.erase(key)

	var rects := _fan_local_rects(band_size, display_entries.size())
	for i in range(display_entries.size()):
		var entry: Dictionary = display_entries[i]
		var key = entry["index"]
		var slot: StageSlot
		if pool.has(key):
			slot = pool[key]
		else:
			slot = StageSlot.new()
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(slot)
			pool[key] = slot
		var rect: Rect2 = rects[i]
		slot.size = rect.size
		slot.custom_minimum_size = rect.size
		slot.position = band_origin + rect.position
		slot.combatant_name = entry["name"]
		slot.fill_color = _placeholder_color(entry["name"])
		slot.is_focused = entry["isFocused"]
		slot.queue_redraw()

	# Display position 0 is always the fan's front/large slot (see
	# _fan_local_rects) -- moving whichever combatant currently holds that
	# position to the end of the layer's own children keeps it drawn on top
	# of the staggered pair behind it, matching the pre-ticket-04 rebuild's
	# own back-to-front insertion order. Re-checked every sync since a kill
	# can hand the front position to a different (already-existing) slot.
	if not display_entries.is_empty():
		var front_key = display_entries[0]["index"]
		layer.move_child(pool[front_key], layer.get_child_count() - 1)


# Local (band-relative) rects for up to 3 fan slots: front is centred and
# large, near the band's bottom edge (closest to camera); the other two are
# smaller, staggered near the top, overlapping the front slot's edge the
# way a fanned hand of cards does -- that's the "staggered behind" look,
# not a layout bug.
func _fan_local_rects(band_size: Vector2, count: int) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if count <= 0:
		return rects

	var front_size := band_size * FAN_FRONT_SIZE_RATIO
	var back_size := band_size * FAN_BACK_SIZE_RATIO
	var front_pos := Vector2((band_size.x - front_size.x) / 2.0, band_size.y - front_size.y - band_size.y * FAN_FRONT_BOTTOM_MARGIN)
	rects.append(Rect2(front_pos, front_size))

	if count >= 2:
		var back_left_pos := Vector2(front_pos.x - back_size.x * FAN_BACK_LEFT_TUCK, band_size.y * FAN_BACK_LEFT_TOP_MARGIN)
		rects.append(Rect2(back_left_pos, back_size))

	if count >= 3:
		var back_right_pos := Vector2(front_pos.x + front_size.x - back_size.x * FAN_BACK_RIGHT_TUCK, band_size.y * FAN_BACK_RIGHT_TOP_MARGIN)
		rects.append(Rect2(back_right_pos, back_size))

	return rects


func _placeholder_color(key: String) -> Color:
	var index: int = int(abs(hash(key))) % _PLACEHOLDER_PALETTE.size()
	return _PLACEHOLDER_PALETTE[index]


func _build_vignette() -> Control:
	var vignette := TextureRect.new()
	vignette.texture = _vignette_texture()
	vignette.position = Vector2.ZERO
	vignette.size = Vector2(STAGE_WIDTH, STAGE_HEIGHT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return vignette


func _vignette_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.32)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])

	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


# combat-presentation ticket 03, §2.5: the command deck -- the action-card
# row and log share a left column; the Dial widget (when it has anything
# loaded to select) docks right, spanning both, per "Dial docked right, full
# height, spanning both the action-card row and the log below it."
func _build_command_deck(combat: Dictionary, player: Dictionary) -> Control:
	var deck := UI.hbox(8)

	var left := UI.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_build_action_deck(player))
	left.add_child(_build_log(combat))
	deck.add_child(left)

	var dial: Variant = player["dial"]
	if dial != null and not dial["loadedComplications"].is_empty():
		deck.add_child(_build_dial_widget(dial))

	return deck


# combat-presentation ticket 04: while `_revealed_log_count` is set (a round
# is mid-playback -- see _play_round()), only reveals that many of
# combat.log's lines instead of all of them, so the log types out one line
# per beat instead of the whole round's outcome appearing at once. -1 (the
# default, and where this always lands once playback finishes or was never
# triggered) shows everything, same as before this ticket.
func _build_log(combat: Dictionary) -> Control:
	var box := UI.vbox(2)
	var log: Array = combat["log"]
	var end: int = log.size() if _revealed_log_count < 0 else mini(_revealed_log_count, log.size())
	var log_start: int = maxi(0, end - 6)
	for i in range(log_start, end):
		box.add_child(UI.muted_label(log[i]))
	return box


# §2.5: "Action deck -- 3 cards, not 4. Attack / Item / Run, a visual
# re-skin of today's _build_action_bar() ... as cards instead of plain
# buttons -- same handlers, no new inventory/hand mechanic, no energy-cost
# numbers." Each card is UI.card() wrapping the same single button/handler
# the old flat action bar used -- only the chrome changes.
func _build_action_deck(player: Dictionary) -> Control:
	var row := UI.hbox(8)
	row.add_child(_build_action_card("⚔ Attack", _on_attack_pressed))

	# calc-effect-wiring-02/03: blast/shield/blackHole/healingBurst, then
	# prophetsBreath/wormhole, added to the same "has anything to use" check
	# that gates the Item card. failsafe is deliberately absent -- it has
	# no manual Use action (see bag_drawer.gd's CONSUMABLE_KEYS comment).
	var has_items: bool = (
		Crafting.inventory_qty("timePearl") > 0 or Crafting.inventory_qty("enhancementPowder") > 0 or Crafting.inventory_qty("rewind") > 0
		or Crafting.inventory_qty("blast") > 0 or Crafting.inventory_qty("shield") > 0
		or Crafting.inventory_qty("blackHole") > 0 or Crafting.inventory_qty("healingBurst") > 0
		or Crafting.inventory_qty("prophetsBreath") > 0 or Crafting.inventory_qty("wormhole") > 0
		or (player["dial"] != null and not player["dial"]["loadedComplications"].is_empty())
	)
	row.add_child(_build_action_card("🎒 Item", func(): Bag.open(), not has_items))
	row.add_child(_build_action_card("🏃 Run", _on_run_pressed))

	if _director.is_playing():
		row.add_child(_build_action_card("⏭ Skip", func(): _director.skip_to_end()))

	return row


func _build_action_card(text: String, callback: Callable, disabled: bool = false) -> Control:
	var c := UI.card()
	var button := UI.button(text, callback)
	button.disabled = disabled
	c["content"].add_child(button)
	return c["panel"]


# combat-presentation ticket 04, docs/combat-animation-vision.md §8: Attack/
# Run now play their round's beat queue back through _director instead of
# just letting the ordinary state_changed -> _sync() resync show the
# post-round state immediately. GameState is already final the instant
# Combat.player_attack()/flee() returns (see combat_director.gd's own
# comment) -- _play_round() only paces how much of the new log the footer
# reveals while that plays out; the stage/strip already reflect the real
# final state from the state_changed emitted inside player_attack()/flee()
# itself, same as before this ticket.
func _on_attack_pressed() -> void:
	_play_round(func(): return Combat.player_attack())


func _on_run_pressed() -> void:
	_play_round(func(): return Combat.flee())


func _play_round(action: Callable) -> void:
	var log_before: int = GameState.state["combat"]["log"].size()
	var result: Dictionary = action.call()
	var beats: Array = result.get("beats", [])
	if beats.is_empty():
		return
	_revealed_log_count = log_before
	_sync_footer(GameState.state["combat"], GameState.state["player"])
	await _director.play(beats, _on_beat_played)
	_revealed_log_count = -1
	_sync()


func _on_beat_played(_beat: Dictionary) -> void:
	_revealed_log_count += 1
	_sync_footer(GameState.state["combat"], GameState.state["player"])


func _build_dial_widget(dial: Dictionary) -> Control:
	var widget := DialWidget.new()
	widget.custom_minimum_size = Vector2(DIAL_WIDTH, 0)
	widget.configure(dial, _dial_selected_index, _on_dial_selection_changed)
	return widget


# DialWidget.handle_rotate() only reports through this callback, never
# mutates its own selection (see that file's own top comment) -- nothing in
# GameState changed, so nothing would otherwise trigger a rebuild; _sync()
# is called directly, same as _on_strip_selection_changed()'s non-enemy case.
func _on_dial_selection_changed(new_index: int) -> void:
	_dial_selected_index = new_index
	_sync()


func _build_outcome_button(outcome: String, context: String) -> Control:
	var label: String
	if outcome == "win":
		label = "✅ They've legged it" if Combat.NON_LETHAL_MUGGING_CONTEXTS.has(context) else "✅ Vein secured"
	elif outcome == "fled":
		label = "🏃 Scarper"
	else:
		label = "💀 Come round"

	return UI.button(label, _on_continue_pressed)


# exit_combat() already navigates for every case except mugging-win
# (which deliberately stays put so the sale_result modal stays visible).
func _on_continue_pressed() -> void:
	Combat.exit_combat()
