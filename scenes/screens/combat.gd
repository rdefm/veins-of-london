class_name CombatScreen
extends Control

var _content: VBoxContainer

# combat-presentation ticket 02: which turn-order-strip card is currently
# displayed as "focused" (exact HP, status, telegraph slot) -- survives
# across _refresh() rebuilds (only _content's children are freed, not this
# screen node itself) since TurnOrderStrip holds no state of its own.
# Empty until the first _refresh() picks a starting card (the enemy at
# combat.focusedEnemyIndex, or entries[0] if there's no enemy). A swipe to a
# non-enemy card updates this without ever touching combat.focusedEnemyIndex
# (§2.2: only enemies are valid attack targets) -- see
# _on_strip_selection_changed() below.
var _strip_selected_key: Dictionary = {}

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


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	var combat: Dictionary = GameState.state["combat"]
	var player: Dictionary = GameState.state["player"]

	var context_label := "Mugging"
	if combat["context"] == "home_raid":
		context_label = "Home Raid"
	elif combat["context"] == "raid":
		context_label = "Raid"
	elif combat["context"] == "defend_vein":
		context_label = "Defend"
	elif combat["context"] == Combat.CONTEXT_ARCHIE_DEAL_MUGGING:
		context_label = "Archie's Deal"

	_content.add_child(UI.heading(context_label))
	# The old second heading named only combat.focusedEnemyIndex's entry --
	# now that the stage fans every living combatant with its own name label
	# (§2.2), a single-enemy title above it would misrepresent a 2-3 enemy
	# fight as if only the focused one were present.
	_content.add_child(_build_turn_order_strip(combat, player))
	_content.add_child(_build_stage(combat, player))

	var log: Array = combat["log"]
	var log_start: int = maxi(0, log.size() - 6)
	for i in range(log_start, log.size()):
		_content.add_child(UI.muted_label(log[i]))

	if combat["outcome"] != null:
		_content.add_child(_build_outcome_button(combat["outcome"], combat["context"]))
	else:
		_content.add_child(_build_action_bar())


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
# directly; that call emits state_changed, which drives _refresh() itself.
# Swiping to the player/an ally card is inert for targeting but still moves
# which card is displayed as focused, so _refresh() is called directly
# (nothing in GameState changed, so nothing would otherwise trigger it).
func _on_strip_selection_changed(new_key: Dictionary) -> void:
	_strip_selected_key = new_key
	if new_key["type"] == "enemy":
		Combat.set_focused_enemy(new_key["index"])
	else:
		_refresh()


# §9's "lit-window frame": a recessed dark inset with a hard 2px border and
# a slight inner vignette, embedded in the surrounding parchment/vector
# chrome -- so the pixel stage reads as a window onto the street even before
# any backdrop art exists (ticket 08 adds the real per-context plates).
func _build_stage(combat: Dictionary, player: Dictionary) -> Control:
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

	# Enemy band, upper third, facing down-camera.
	var enemy_origin := Vector2.ZERO
	var enemy_size := Vector2(STAGE_WIDTH, ENEMY_BAND_HEIGHT)
	var enemy_entries := _enemy_display_entries(combat["enemies"], combat["focusedEnemyIndex"])
	for slot in _build_band_slots(enemy_entries, enemy_origin, enemy_size):
		frame.add_child(slot)

	# Player + ally band, lower two-thirds.
	var player_origin := Vector2(0.0, ENEMY_BAND_HEIGHT)
	var player_size := Vector2(STAGE_WIDTH, PLAYER_BAND_HEIGHT)
	var player_entries := _player_display_entries(player, combat["allies"])
	for slot in _build_band_slots(player_entries, player_origin, player_size):
		frame.add_child(slot)

	frame.add_child(_build_vignette())

	return frame


# Up to Combat.SQUAD_MAX non-koed enemies, fanned in their existing
# combat.enemies array order, tagged with whether they're the glow target.
# Builds fresh display dicts rather than reusing combat["enemies"]' own
# entries -- SCREENS never mutate GameState.state, and later attaching an
# "isFocused" key onto a live state dict would do exactly that.
func _enemy_display_entries(enemies: Array, focused_index: int) -> Array:
	var display: Array = []
	for i in range(enemies.size()):
		if not enemies[i]["koed"]:
			var enemy: Dictionary = enemies[i]
			display.append({ "name": enemy["name"], "isFocused": i == focused_index })
			if display.size() >= Combat.SQUAD_MAX:
				break
	return display


# The player (always the fan's front/large slot -- they're the one
# character guaranteed present) plus up to SQUAD_MAX - 1 non-koed allies.
# The glow is enemy-only (§2.2), so isFocused is always false here.
# 44-archie-combat-ally: koed allies stay in combat["allies"] (so
# knock_out()'s cooldown has something to key off), so they're filtered out
# here rather than at the state layer, same as the old card-list code did.
func _player_display_entries(player: Dictionary, allies: Array) -> Array:
	var display: Array = [{ "name": "You", "isFocused": false }]
	for ally in allies:
		if not ally["koed"]:
			display.append({ "name": ally["name"], "isFocused": false })
			if display.size() >= Combat.SQUAD_MAX:
				break
	return display


# Shared by both bands: fans `display_entries` (front-to-back order, index 0
# is the fan's front/large slot -- see _enemy_display_entries/
# _player_display_entries) across `band_size`, positioned at `band_origin`.
# Slots are built back-to-front so the front (largest) slot is added last
# and draws on top of the staggered pair behind it, matching "front slot
# large/foreground".
func _build_band_slots(display_entries: Array, band_origin: Vector2, band_size: Vector2) -> Array[Control]:
	var rects := _fan_local_rects(band_size, display_entries.size())
	var slots: Array[Control] = []
	for i in range(display_entries.size() - 1, -1, -1):
		var entry: Dictionary = display_entries[i]
		var slot := _build_slot(entry["name"], rects[i], entry["isFocused"])
		slot.position = band_origin + rects[i].position
		slots.append(slot)
	return slots


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


# combat-presentation ticket 02, §2.4: the turn-order strip (see
# _build_turn_order_strip() above) is now the sole source of name/HP/status
# truth -- the fan itself shows only the placeholder box, its template-id
# colour, and the focus glow, per "the stage itself shows only the fanned
# pixel-art sprites plus the target-outline glow -- no floating enamel signs
# over the diorama."
func _build_slot(combatant_name: String, rect: Rect2, is_focused: bool) -> StageSlot:
	var slot := StageSlot.new()
	slot.size = rect.size
	slot.custom_minimum_size = rect.size
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.combatant_name = combatant_name
	slot.fill_color = _placeholder_color(combatant_name)
	slot.is_focused = is_focused
	return slot


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


func _build_action_bar() -> Control:
	var row := UI.hbox()
	row.add_child(UI.button("⚔ Attack", func(): Combat.player_attack()))
	row.add_child(UI.button("🏃 Run", func(): Combat.flee()))

	var player: Dictionary = GameState.state["player"]
	# calc-effect-wiring-02/03: blast/shield/blackHole/healingBurst, then
	# prophetsBreath/wormhole, added to the same "has anything to use" check
	# that gates the Item button. failsafe is deliberately absent -- it has
	# no manual Use action (see bag_drawer.gd's CONSUMABLE_KEYS comment).
	var has_items: bool = (
		Crafting.inventory_qty("timePearl") > 0 or Crafting.inventory_qty("enhancementPowder") > 0 or Crafting.inventory_qty("rewind") > 0
		or Crafting.inventory_qty("blast") > 0 or Crafting.inventory_qty("shield") > 0
		or Crafting.inventory_qty("blackHole") > 0 or Crafting.inventory_qty("healingBurst") > 0
		or Crafting.inventory_qty("prophetsBreath") > 0 or Crafting.inventory_qty("wormhole") > 0
		or (player["dial"] != null and not player["dial"]["loadedComplications"].is_empty())
	)
	var item_button := UI.button("🎒 Item", func(): Bag.open())
	item_button.disabled = not has_items
	row.add_child(item_button)

	return row


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
