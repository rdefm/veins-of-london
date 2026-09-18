class_name CombatStage
extends Panel

# The pixel stage -- backdrop, subject slots, keypose/attack/hit/ko
# one-shots, effect sheets and the art-independent juice layer (flash/
# shake/damage numbers). scenes/screens/combat.gd is the orchestrator: it
# decides *when* to call sync()/resolve_target_slot()/shake()/play_effect()
# as part of turn flow and director bridging; this owns the node tree and
# how those calls actually render.
# docs/combat-animation-vision.md is authoritative for what's drawn here.
#
# Same off-tree-testable shape as DialWidget/TurnOrderStrip: no _ready()
# override (never fires in the CombatScreen.new()+_ready() harness tests/
# test_combat_screen.gd's own top comment documents), skeleton + animation
# loading happen lazily on first sync() instead.

const STAGE_WIDTH := 390.0 - 16.0 - 16.0
const STAGE_HEIGHT := 220.0
const COLUMN_GAP := 6.0
const PLAYER_BAND_WIDTH := (STAGE_WIDTH - COLUMN_GAP) / 2.0
const ENEMY_BAND_WIDTH := STAGE_WIDTH - COLUMN_GAP - PLAYER_BAND_WIDTH
const STAGE_BORDER_WIDTH := 2.0
const STAGE_DEFAULT_FILL := Color(0.07, 0.07, 0.09)
const FAN_FRONT_SIZE_RATIO := Vector2(0.98, 0.74)
const FAN_FRONT_BOTTOM_MARGIN := 0.02
const FAN_STEP_SIZE_SCALE := 0.88
const FAN_STEP_OFFSET_RATIO := Vector2(0.14, 0.11)
const DAMAGE_NUMBER_RISE_PX := 28.0
const DAMAGE_NUMBER_DURATION := 0.6
const SHAKE_MIN_PX := 3.0
const SHAKE_MAX_PX := 6.0
const SHAKE_FULL_FRACTION := 0.5
const ATTACK_KEYPOSE_COUNT := 3
const HIT_KEYPOSE_COUNT := 1
const KO_KEYPOSE_COUNT := 2
const LUNGE_PX := 14.0
const RECOIL_PX := 8.0
const FALL_SINK_PX := 10.0
const FALL_ROTATION_DEG := 20.0
const FALL_ALPHA := 0.35
const SELF_PATCH_RISE_PX := 6.0
const _PLACEHOLDER_PALETTE: Array[Color] = [
	Color(0.55, 0.33, 0.33),
	Color(0.33, 0.47, 0.55),
	Color(0.42, 0.52, 0.33),
	Color(0.48, 0.38, 0.58),
	Color(0.58, 0.48, 0.30),
	Color(0.33, 0.55, 0.50),
]

class StageSlot extends Control:
	var combatant_name: String = ""
	var fill_color: Color = Color.WHITE
	var is_focused: bool = false
	var flash_alpha: float = 0.0
	var side: String = "player"
	var _mirror_extra: bool = false
	var _idle_frames: Array[Texture2D] = []
	var _idle_frame_index: int = 0
	var _sprite_rect: TextureRect
	var _idle_timer: Timer
	var _overlay: Control
	var _hit_keyposes: Array[Texture2D] = []
	var _hit_fps: float = 10.0
	var _ko_keyposes: Array[Texture2D] = []
	var _ko_fps: float = 12.0
	var _attack_keyposes: Array[Texture2D] = []
	var _attack_fps: float = 12.0
	var _self_patch_keyposes: Array[Texture2D] = []
	var _self_patch_fps: float = 10.0
	class PoseStep:
		var texture: Texture2D
		var offset: Vector2
		var rotation_degrees: float
		var alpha: float
		func _init(p_texture: Texture2D, p_offset: Vector2 = Vector2.ZERO, p_rotation_degrees: float = 0.0, p_alpha: float = 1.0) -> void:
			texture = p_texture
			offset = p_offset
			rotation_degrees = p_rotation_degrees
			alpha = p_alpha
	var _one_shot_steps: Array[PoseStep] = []
	var _one_shot_index: int = 0
	var _one_shot_hold_last_frame: bool = false
	var _one_shot_timer: Timer
	var _ghost_rect: TextureRect

	func _init() -> void:
		_sprite_rect = TextureRect.new()
		_sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_sprite_rect.anchor_right = 1.0
		_sprite_rect.anchor_bottom = 1.0
		_sprite_rect.visible = false
		add_child(_sprite_rect)

		_ghost_rect = TextureRect.new()
		_ghost_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ghost_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_ghost_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_ghost_rect.anchor_right = 1.0
		_ghost_rect.anchor_bottom = 1.0
		_ghost_rect.visible = false
		_ghost_rect.modulate.a = 0.0
		add_child(_ghost_rect)

		_idle_timer = Timer.new()
		_idle_timer.one_shot = false
		_idle_timer.timeout.connect(_advance_idle_frame)
		add_child(_idle_timer)

		_one_shot_timer = Timer.new()
		_one_shot_timer.one_shot = false
		_one_shot_timer.timeout.connect(_advance_one_shot)
		add_child(_one_shot_timer)

		_overlay = Control.new()
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.anchor_right = 1.0
		_overlay.anchor_bottom = 1.0
		_overlay.draw.connect(_draw_overlay)
		add_child(_overlay)
	func set_side(value: String) -> void:
		side = value
		_apply_flip()
	func set_mirror_extra(value: bool) -> void:
		_mirror_extra = value
		_apply_flip()

	func _apply_flip() -> void:
		_sprite_rect.flip_h = (side == "enemy") != _mirror_extra
	func _forward_dir() -> float:
		return -1.0 if side == "enemy" else 1.0

	func set_flash_alpha(value: float) -> void:
		flash_alpha = value
		_overlay.queue_redraw()
	func flash_hit() -> void:
		set_flash_alpha(1.0)
		if not is_inside_tree():
			return
		var tween := create_tween()
		tween.tween_method(set_flash_alpha, 1.0, 0.0, 0.18)
	func ghost_next_pose() -> void:
		if _attack_keyposes.is_empty():
			return
		_ghost_rect.texture = _attack_keyposes[0]
		_ghost_rect.position = Vector2.ZERO
		_ghost_rect.modulate.a = 0.0
		_ghost_rect.visible = true
		if not is_inside_tree():
			_ghost_rect.visible = false
			return
		var tween := create_tween()
		tween.tween_property(_ghost_rect, "modulate:a", 0.3, 0.08)
		tween.tween_interval(0.1)
		tween.tween_property(_ghost_rect, "modulate:a", 0.0, 0.12)
		tween.tween_callback(func(): _ghost_rect.visible = false)
	func set_idle_animation(frames: Array[Texture2D], fps: float) -> void:
		_idle_frames = frames
		_idle_frame_index = 0
		_idle_fps = fps
		_sprite_rect.visible = not frames.is_empty()
		_sprite_rect.texture = frames[0] if not frames.is_empty() else null
		if frames.size() >= 2 and fps > 0.0:
			_idle_timer.wait_time = 1.0 / (fps * _time_scale)
			_idle_timer.start()
		else:
			_idle_timer.stop()
		queue_redraw()
	var _time_scale: float = 1.0
	var _idle_fps: float = 0.0

	func set_time_scale(scale: float) -> void:
		_time_scale = maxf(0.01, scale)
		if _idle_frames.size() >= 2 and _idle_fps > 0.0:
			_idle_timer.wait_time = 1.0 / (_idle_fps * _time_scale)
	var _frozen_shader_material: ShaderMaterial
	var _is_frozen_visual: bool = false

	func set_frozen_visual(value: bool) -> void:
		if value == _is_frozen_visual:
			return
		_is_frozen_visual = value
		if value:
			if _frozen_shader_material == null:
				var shader := Shader.new()
				shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(c.rgb, vec3(gray), 0.85), c.a);\n}"
				_frozen_shader_material = ShaderMaterial.new()
				_frozen_shader_material.shader = shader
			_sprite_rect.material = _frozen_shader_material
		else:
			_sprite_rect.material = null
	func _advance_idle_frame() -> void:
		if _idle_frames.size() < 2 or not _one_shot_steps.is_empty():
			return
		_idle_frame_index = (_idle_frame_index + 1) % _idle_frames.size()
		_sprite_rect.texture = _idle_frames[_idle_frame_index]
	func set_attack_animation(frames: Array[Texture2D], fps: float) -> void:
		_attack_keyposes = frames
		_attack_fps = fps

	func set_hit_animation(frames: Array[Texture2D], fps: float) -> void:
		_hit_keyposes = frames
		_hit_fps = fps

	func set_ko_animation(frames: Array[Texture2D], fps: float) -> void:
		_ko_keyposes = frames
		_ko_fps = fps

	func set_self_patch_animation(frames: Array[Texture2D], fps: float) -> void:
		_self_patch_keyposes = frames
		_self_patch_fps = fps
	func play_attack() -> void:
		if _attack_keyposes.is_empty():
			return
		var fwd: float = _forward_dir()
		var windup: Texture2D = _attack_keyposes[0]
		var strike: Texture2D = _attack_keyposes[mini(1, _attack_keyposes.size() - 1)]
		var recover: Texture2D = _attack_keyposes[mini(2, _attack_keyposes.size() - 1)]
		var steps: Array[PoseStep] = [
			PoseStep.new(windup, Vector2.ZERO),
			PoseStep.new(strike, Vector2(CombatStage.LUNGE_PX * fwd, 0.0)),
			PoseStep.new(recover, Vector2.ZERO),
		]
		_start_one_shot(steps, _attack_fps, false)
	func play_hit() -> void:
		if _hit_keyposes.is_empty():
			return
		var fwd: float = _forward_dir()
		var pose: Texture2D = _hit_keyposes[0]
		var steps: Array[PoseStep] = [
			PoseStep.new(pose, Vector2(-CombatStage.RECOIL_PX * fwd, 0.0)),
			PoseStep.new(pose, Vector2.ZERO),
		]
		_start_one_shot(steps, _hit_fps, false)
	func play_ko() -> void:
		if _ko_keyposes.is_empty():
			return
		var pose1: Texture2D = _ko_keyposes[0]
		var pose2: Texture2D = _ko_keyposes[mini(1, _ko_keyposes.size() - 1)]
		var steps: Array[PoseStep] = [
			PoseStep.new(pose1, Vector2.ZERO),
			PoseStep.new(pose2, Vector2(0.0, CombatStage.FALL_SINK_PX), CombatStage.FALL_ROTATION_DEG, CombatStage.FALL_ALPHA),
		]
		_start_one_shot(steps, _ko_fps, true)
	func play_self_patch() -> void:
		if _self_patch_keyposes.is_empty():
			return
		var pose: Texture2D = _self_patch_keyposes[0]
		var steps: Array[PoseStep] = [
			PoseStep.new(pose, Vector2(0.0, -CombatStage.SELF_PATCH_RISE_PX)),
			PoseStep.new(pose, Vector2.ZERO),
		]
		_start_one_shot(steps, _self_patch_fps, false)
	func _new_overlay_rect(z: int) -> TextureRect:
		var rect := TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.z_index = z
		return rect

	func spawn_afterimage() -> void:
		if _sprite_rect.texture == null or not is_inside_tree():
			return
		var ghost := _new_overlay_rect(-1)
		ghost.texture = _sprite_rect.texture
		ghost.size = size
		ghost.position = _sprite_rect.position
		ghost.flip_h = _sprite_rect.flip_h
		ghost.modulate = Color(1.0, 1.0, 1.0, 0.45)
		add_child(ghost)
		var tween := create_tween()
		tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
		tween.tween_callback(ghost.queue_free)
	func play_wormhole_vanish() -> void:
		if not is_inside_tree():
			return
		_sprite_rect.pivot_offset = _sprite_rect.size / 2.0
		var tween := create_tween()
		tween.tween_property(_sprite_rect, "scale:x", 0.05, 0.25)
		tween.parallel().tween_property(_sprite_rect, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func(): _sprite_rect.visible = false)
	var _shield_crack_alpha: float = 0.0

	func flash_shield_crack() -> void:
		_set_shield_crack_alpha(1.0)
		if not is_inside_tree():
			return
		var tween := create_tween()
		tween.tween_method(_set_shield_crack_alpha, 1.0, 0.0, 0.3)

	func _set_shield_crack_alpha(value: float) -> void:
		_shield_crack_alpha = value
		_overlay.queue_redraw()
	func play_effect_sheet(frames: Array[Texture2D], fps: float) -> void:
		if frames.is_empty() or fps <= 0.0 or not is_inside_tree():
			return
		var fx := _new_overlay_rect(4)
		fx.anchor_right = 1.0
		fx.anchor_bottom = 1.0
		fx.texture = frames[0]
		add_child(fx)
		var timer := Timer.new()
		timer.one_shot = false
		timer.wait_time = 1.0 / fps
		add_child(timer)
		var index := 0
		timer.timeout.connect(func():
			index += 1
			if index >= frames.size():
				timer.stop()
				timer.queue_free()
				fx.queue_free()
				return
			fx.texture = frames[index]
		)
		timer.start()
	var _shield_loop_rect: TextureRect
	var _shield_loop_timer: Timer
	var _shield_loop_frames: Array[Texture2D] = []
	var _shield_loop_index: int = 0

	func set_shield_loop(frames: Array[Texture2D], fps: float, active: bool) -> void:
		if _shield_loop_rect == null:
			_shield_loop_rect = _new_overlay_rect(3)
			_shield_loop_rect.anchor_right = 1.0
			_shield_loop_rect.anchor_bottom = 1.0
			_shield_loop_rect.visible = false
			add_child(_shield_loop_rect)
			_shield_loop_timer = Timer.new()
			_shield_loop_timer.one_shot = false
			_shield_loop_timer.timeout.connect(_advance_shield_loop)
			add_child(_shield_loop_timer)

		_shield_loop_frames = frames
		var should_show: bool = active and not frames.is_empty() and fps > 0.0
		_shield_loop_rect.visible = should_show
		if should_show:
			_shield_loop_rect.texture = frames[_shield_loop_index % frames.size()]
			_shield_loop_timer.wait_time = 1.0 / fps
			_shield_loop_timer.start()
		else:
			_shield_loop_timer.stop()
			_shield_loop_index = 0

	func _advance_shield_loop() -> void:
		if _shield_loop_frames.is_empty():
			return
		_shield_loop_index = (_shield_loop_index + 1) % _shield_loop_frames.size()
		_shield_loop_rect.texture = _shield_loop_frames[_shield_loop_index]

	func _start_one_shot(steps: Array[PoseStep], fps: float, hold_last_frame: bool) -> void:
		if steps.is_empty():
			return
		_one_shot_steps = steps
		_one_shot_index = 0
		_one_shot_hold_last_frame = hold_last_frame
		_apply_pose_step(steps[0])
		_sprite_rect.visible = true
		if steps.size() < 2 or fps <= 0.0:
			_end_one_shot()
			return
		_one_shot_timer.wait_time = 1.0 / fps
		_one_shot_timer.start()
	func _apply_pose_step(step: PoseStep) -> void:
		_sprite_rect.texture = step.texture
		_sprite_rect.position = step.offset
		_sprite_rect.pivot_offset = _sprite_rect.size / 2.0
		_sprite_rect.rotation_degrees = step.rotation_degrees
		_sprite_rect.modulate.a = step.alpha
	func _advance_one_shot() -> void:
		if _one_shot_steps.is_empty():
			return
		_one_shot_index += 1
		if _one_shot_index >= _one_shot_steps.size():
			if _one_shot_hold_last_frame:
				_one_shot_timer.stop()
				return
			_end_one_shot()
			return
		_apply_pose_step(_one_shot_steps[_one_shot_index])
	func _end_one_shot() -> void:
		_one_shot_timer.stop()
		_one_shot_steps = []
		_one_shot_index = 0
		_sprite_rect.position = Vector2.ZERO
		_sprite_rect.rotation_degrees = 0.0
		_sprite_rect.modulate.a = 1.0
		if not _idle_frames.is_empty():
			_sprite_rect.texture = _idle_frames[_idle_frame_index]
		else:
			_sprite_rect.visible = false
			_sprite_rect.texture = null

	func _draw() -> void:
		if _idle_frames.is_empty():
			var rect := Rect2(Vector2.ZERO, size)
			draw_rect(rect, fill_color, true)
			draw_rect(rect, Color(0, 0, 0, 0.55), false, 2.0)

	func _draw_overlay() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		if is_focused:
			_overlay.draw_rect(rect.grow(3.0), Color(1.0, 0.86, 0.35, 0.95), false, 3.0)
		if flash_alpha > 0.0:
			_overlay.draw_rect(rect, Color(1.0, 1.0, 1.0, flash_alpha), true)
		if _shield_crack_alpha > 0.0:
			_overlay.draw_rect(rect, Color(0.4, 0.85, 1.0, _shield_crack_alpha * 0.55), true)
			_overlay.draw_rect(rect.grow(-2.0), Color(0.85, 0.95, 1.0, _shield_crack_alpha), false, 2.0)

var _enemy_slots: Dictionary = {}  # enemy index (int) -> StageSlot
var _player_slots: Dictionary = {}  # -1 (player) or ally index (int) -> StageSlot
var _enemy_band_layer: Control
var _player_band_layer: Control
var _backdrop_texture: TextureRect
var _backdrop_fill: ColorRect
var _default_attack_keyposes: Array[Texture2D] = []
var _default_attack_fps: float = 12.0
var _default_hit_keyposes: Array[Texture2D] = []
var _default_hit_fps: float = 10.0
var _default_ko_keyposes: Array[Texture2D] = []
var _default_ko_fps: float = 12.0
var _idle_frames_by_template: Dictionary = {}
var _empty_idle_frames: Array[Texture2D] = []
var _attack_keyposes_by_template: Dictionary = {}
var _hit_keyposes_by_template: Dictionary = {}
var _ko_keyposes_by_template: Dictionary = {}
var _self_patch_keyposes_by_template: Dictionary = {}
var _effect_frames_by_key: Dictionary = {}
var _stage_shake_layer: Control


func sync(combat: Dictionary, player: Dictionary, frozen_roster: Dictionary) -> void:
	if get_child_count() == 0:
		_build()

	_sync_backdrop(combat["context"])

	var enemies: Array = frozen_roster.get("enemies", combat["enemies"])
	var allies: Array = frozen_roster.get("allies", combat["allies"])
	var player_entries := _player_display_entries(player, allies)
	_sync_band(_player_slots, _player_band_layer, player_entries, Vector2(PLAYER_BAND_WIDTH, STAGE_HEIGHT), Vector2.ZERO, "player")

	var enemy_entries := _enemy_display_entries(enemies, combat["focusedEnemyIndex"])
	_sync_band(_enemy_slots, _enemy_band_layer, enemy_entries, Vector2(ENEMY_BAND_WIDTH, STAGE_HEIGHT), Vector2(PLAYER_BAND_WIDTH + COLUMN_GAP, 0.0), "enemy")
	var frozen: bool = combat["frozenTurns"] > 0
	for slot in _enemy_slots.values():
		slot.set_time_scale(0.1 if frozen else 1.0)
		slot.set_frozen_visual(frozen)

	var player_slot: StageSlot = _player_slots.get(-1)
	if player_slot != null:
		var shield_entry: Dictionary = _effect_frames_by_key.get("shield", {})
		player_slot.set_shield_loop(shield_entry.get("frames", _empty_idle_frames), shield_entry.get("fps", 0.0), player["shieldPool"] > 0)


func resolve_target_slot(target: Dictionary) -> StageSlot:
	if target["type"] == "player":
		return _player_slots.get(-1)
	if target["type"] == "ally":
		return _player_slots.get(target["index"])
	if target["type"] == "enemy":
		return _enemy_slots.get(target["index"])
	return null


func shake(dmg: int, hp_max: int) -> void:
	if _stage_shake_layer == null or not _stage_shake_layer.is_inside_tree():
		return
	var magnitude: float = _shake_magnitude(dmg, hp_max)
	var base_pos: Vector2 = _stage_shake_layer.position
	var tween := create_tween()
	tween.tween_property(_stage_shake_layer, "position", base_pos + Vector2(magnitude, 0.0), 0.03)
	tween.tween_property(_stage_shake_layer, "position", base_pos + Vector2(-magnitude, magnitude * 0.5), 0.05)
	tween.tween_property(_stage_shake_layer, "position", base_pos + Vector2(magnitude * 0.5, -magnitude * 0.4), 0.05)
	tween.tween_property(_stage_shake_layer, "position", base_pos, 0.06)


func _shake_magnitude(dmg: int, hp_max: int) -> float:
	if hp_max <= 0:
		return SHAKE_MIN_PX
	var frac: float = clampf(float(dmg) / float(hp_max), 0.0, 1.0)
	return clampf(SHAKE_MIN_PX + (SHAKE_MAX_PX - SHAKE_MIN_PX) * (frac / SHAKE_FULL_FRACTION), SHAKE_MIN_PX, SHAKE_MAX_PX)


func spawn_damage_number(slot: StageSlot, dmg: int) -> void:
	var layer: Node = slot.get_parent()
	if layer == null:
		return
	var label := Label.new()
	label.text = "-%d" % dmg
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 5
	layer.add_child(label)
	label.position = slot.position + slot.size * 0.5 - Vector2(12.0, 10.0)
	if not label.is_inside_tree():
		return
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - DAMAGE_NUMBER_RISE_PX, DAMAGE_NUMBER_DURATION)
	tween.parallel().tween_property(label, "modulate:a", 0.0, DAMAGE_NUMBER_DURATION)
	tween.tween_callback(label.queue_free)


func play_effect(beat: Dictionary, effect_key: String) -> void:
	var entry: Dictionary = _effect_frames_by_key.get(effect_key, {})
	var frames: Array[Texture2D] = entry.get("frames", _empty_idle_frames)
	if frames.is_empty():
		return
	var target: Dictionary = _beat_target(beat)
	if target["type"] == "":
		target = _default_effect_target(effect_key)
	var slot: StageSlot = resolve_target_slot(target)
	if slot != null:
		slot.play_effect_sheet(frames, entry.get("fps", 0.0))


static func _beat_target(beat: Dictionary) -> Dictionary:
	var target_type: String = beat.get("targetType", "")
	var target_index: int = -1 if target_type == "player" else int(beat.get("targetIndex", -1))
	return { "type": target_type, "index": target_index }


func _default_effect_target(effect_key: String) -> Dictionary:
	if effect_key == "timePearl":
		return { "type": "enemy", "index": GameState.state["combat"]["focusedEnemyIndex"] }
	return { "type": "player", "index": -1 }


func _build() -> void:
	custom_minimum_size = Vector2(STAGE_WIDTH, STAGE_HEIGHT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS

	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = STAGE_DEFAULT_FILL
	frame_style.border_width_left = STAGE_BORDER_WIDTH
	frame_style.border_width_top = STAGE_BORDER_WIDTH
	frame_style.border_width_right = STAGE_BORDER_WIDTH
	frame_style.border_width_bottom = STAGE_BORDER_WIDTH
	frame_style.border_color = Color(0, 0, 0, 0.65)
	add_theme_stylebox_override("panel", frame_style)

	_stage_shake_layer = Control.new()
	_stage_shake_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_shake_layer.size = Vector2(STAGE_WIDTH, STAGE_HEIGHT)
	add_child(_stage_shake_layer)
	var backdrop_origin := Vector2(STAGE_BORDER_WIDTH, STAGE_BORDER_WIDTH)
	var backdrop_size := Vector2(STAGE_WIDTH, STAGE_HEIGHT) - backdrop_origin * 2.0

	_backdrop_fill = ColorRect.new()
	_backdrop_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_fill.position = backdrop_origin
	_backdrop_fill.size = backdrop_size
	_stage_shake_layer.add_child(_backdrop_fill)

	_backdrop_texture = TextureRect.new()
	_backdrop_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_texture.position = backdrop_origin
	_backdrop_texture.size = backdrop_size
	_backdrop_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop_texture.visible = false
	_stage_shake_layer.add_child(_backdrop_texture)

	_enemy_band_layer = Control.new()
	_enemy_band_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_shake_layer.add_child(_enemy_band_layer)

	_player_band_layer = Control.new()
	_player_band_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_shake_layer.add_child(_player_band_layer)

	_stage_shake_layer.add_child(_build_vignette())

	_load_default_animations()
	_load_template_idle_animations()
	_load_template_action_animations()
	_load_effect_animations()


func _load_default_animations() -> void:
	var attack := _load_action_keyposes("default", "attack", ATTACK_KEYPOSE_COUNT)
	_default_attack_keyposes = attack["frames"]
	_default_attack_fps = attack["fps"]

	var hit := _load_action_keyposes("default", "hit", HIT_KEYPOSE_COUNT)
	_default_hit_keyposes = hit["frames"]
	_default_hit_fps = hit["fps"]

	var ko := _load_action_keyposes("default", "ko", KO_KEYPOSE_COUNT)
	_default_ko_keyposes = ko["frames"]
	_default_ko_fps = ko["fps"]
func _load_template_idle_animations() -> void:
	_idle_frames_by_template = {}
	var templates: Dictionary = GameData.COMBAT_VISUALS.get("templates", {})
	for key in templates.keys():
		_idle_frames_by_template[key] = _load_animation_frames(key, "idle")
func _load_template_action_animations() -> void:
	_attack_keyposes_by_template = {}
	_hit_keyposes_by_template = {}
	_ko_keyposes_by_template = {}
	_self_patch_keyposes_by_template = {}
	var templates: Dictionary = GameData.COMBAT_VISUALS.get("templates", {})
	for key in templates.keys():
		_attack_keyposes_by_template[key] = _load_action_keyposes(key, "attack", ATTACK_KEYPOSE_COUNT)
		_hit_keyposes_by_template[key] = _load_action_keyposes(key, "hit", HIT_KEYPOSE_COUNT)
		_ko_keyposes_by_template[key] = _load_action_keyposes(key, "ko", KO_KEYPOSE_COUNT)
		_self_patch_keyposes_by_template[key] = _load_action_keyposes(key, "selfPatch", HIT_KEYPOSE_COUNT)
func _load_action_keyposes(template_key: String, key: String, count: int) -> Dictionary:
	var loaded := _load_animation_frames(template_key, key)
	return { "frames": _select_action_keyposes(loaded["frames"], count), "fps": loaded["fps"] }
func _select_action_keyposes(frames: Array[Texture2D], count: int) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if frames.is_empty() or count <= 0:
		return out
	if frames.size() <= count:
		return frames.duplicate()
	for i in range(count):
		var idx: int = 0 if count == 1 else int(round(float(i) * float(frames.size() - 1) / float(count - 1)))
		out.append(frames[idx])
	return out
func _resolve_action_keyposes(by_template: Dictionary, template_key: String, default_frames: Array[Texture2D], default_fps: float) -> Dictionary:
	var entry: Dictionary = by_template.get(template_key, {})
	var frames: Array[Texture2D] = entry.get("frames", _empty_idle_frames)
	if frames.is_empty():
		return { "frames": default_frames, "fps": default_fps }
	return { "frames": frames, "fps": entry.get("fps", 0.0) }

func _load_animation_frames(template_key: String, key: String) -> Dictionary:
	var entry: Dictionary = GameData.COMBAT_VISUALS.get("templates", {}).get(template_key, {}).get(key, {})
	return _load_sheet_frames(entry)
func _load_sheet_frames(entry: Dictionary) -> Dictionary:
	var image_path: String = entry.get("image", "")
	var frame_count: int = entry.get("frameCount", 0)
	var empty: Array[Texture2D] = []
	if image_path.is_empty() or frame_count < 1 or not ResourceLoader.exists(image_path):
		return { "frames": empty, "fps": entry.get("fps", 0.0) }

	var sheet: Texture2D = load(image_path)
	var frame_width := sheet.get_width() / frame_count
	var frame_height := sheet.get_height()
	var frames: Array[Texture2D] = []
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.append(atlas)

	return { "frames": frames, "fps": entry.get("fps", 0.0) }
func _load_effect_animations() -> void:
	_effect_frames_by_key = {}
	var effects: Dictionary = GameData.COMBAT_VISUALS.get("effects", {})
	for key in effects.keys():
		_effect_frames_by_key[key] = _load_sheet_frames(effects[key])


func _sync_backdrop(context: String) -> void:
	var backdrops: Dictionary = GameData.COMBAT_VISUALS.get("backdrops", {})
	var entry: Dictionary = backdrops.get(context, {})
	var image_path: String = entry.get("image", "")
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		_backdrop_texture.texture = load(image_path)
		_backdrop_texture.visible = true
		_backdrop_fill.visible = false
	else:
		_backdrop_fill.color = GameData.PALETTE.get(entry.get("fallbackColor", ""), STAGE_DEFAULT_FILL)
		_backdrop_fill.visible = true
		_backdrop_texture.visible = false
func _enemy_display_entries(enemies: Array, focused_index: int) -> Array:
	var display: Array = []
	for i in range(enemies.size()):
		if not enemies[i]["koed"]:
			var enemy: Dictionary = enemies[i]
			display.append({ "name": enemy["name"], "isFocused": i == focused_index, "index": i, "templateKey": enemy_template_key(enemy) })
			if display.size() >= Combat.SQUAD_MAX:
				break
	return display
static func enemy_template_key(enemy: Dictionary) -> String:
	if enemy.get("isMugging", false):
		return "mugger"
	var name: String = enemy.get("name", "")
	for key in GameData.ENEMY_RAID_GUARDS.keys():
		if GameData.ENEMY_RAID_GUARDS[key].get("name", "") == name:
			return key
	if GameData.ENEMY_HOME_RAID_RAIDER.get("name", "") == name:
		return "homeRaidRaider"
	return ""
func _player_display_entries(player: Dictionary, allies: Array) -> Array:
	var display: Array = [{ "name": "You", "isFocused": false, "index": -1, "templateKey": "player" }]
	for i in range(allies.size()):
		if not allies[i]["koed"]:
			display.append({ "name": allies[i]["name"], "isFocused": false, "index": i, "templateKey": allies[i].get("contactId", "") })
			if display.size() >= Combat.SQUAD_MAX:
				break
	return display
func _sync_band(pool: Dictionary, layer: Control, display_entries: Array, band_size: Vector2, band_origin: Vector2, side: String) -> void:
	var live_keys: Dictionary = {}
	for entry in display_entries:
		live_keys[entry["index"]] = true
	for key in pool.keys().duplicate():
		if not live_keys.has(key):
			var stale: StageSlot = pool[key]
			layer.remove_child(stale)
			stale.queue_free()
			pool.erase(key)

	var rects := _fan_local_rects(band_size, display_entries.size(), side == "enemy")
	var template_occurrence: Dictionary = {}
	for i in range(display_entries.size()):
		var entry: Dictionary = display_entries[i]
		var key = entry["index"]
		var slot: StageSlot
		if pool.has(key):
			slot = pool[key]
		else:
			slot = StageSlot.new()
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.set_side(side)
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
		slot._overlay.queue_redraw()

		var template_key: String = entry.get("templateKey", "")
		var occurrence: int = template_occurrence.get(template_key, 0)
		template_occurrence[template_key] = occurrence + 1
		slot.set_mirror_extra(not template_key.is_empty() and occurrence % 2 == 1)
		var default_idle: Dictionary = _idle_frames_by_template.get("default", {})
		var idle := _resolve_action_keyposes(_idle_frames_by_template, template_key, default_idle.get("frames", _empty_idle_frames), default_idle.get("fps", 0.0))
		slot.set_idle_animation(idle["frames"], idle["fps"])
		for action in [
			[_attack_keyposes_by_template, _default_attack_keyposes, _default_attack_fps, slot.set_attack_animation],
			[_hit_keyposes_by_template, _default_hit_keyposes, _default_hit_fps, slot.set_hit_animation],
			[_ko_keyposes_by_template, _default_ko_keyposes, _default_ko_fps, slot.set_ko_animation],
			[_self_patch_keyposes_by_template, _empty_idle_frames, 0.0, slot.set_self_patch_animation],
		]:
			var resolved: Dictionary = _resolve_action_keyposes(action[0], template_key, action[1], action[2])
			var setter: Callable = action[3]
			setter.call(resolved["frames"], resolved["fps"])
	if not display_entries.is_empty():
		var front_key = display_entries[0]["index"]
		layer.move_child(pool[front_key], layer.get_child_count() - 1)
func _fan_local_rects(band_size: Vector2, count: int, mirror_x: bool = false) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if count <= 0:
		return rects

	var size := band_size * FAN_FRONT_SIZE_RATIO
	var front_x := clampf((band_size.x - size.x) / 2.0, 0.0, maxf(0.0, band_size.x - size.x))
	var pos := Vector2(front_x, band_size.y - size.y - band_size.y * FAN_FRONT_BOTTOM_MARGIN)
	rects.append(Rect2(pos, size))

	for i in range(1, count):
		size *= FAN_STEP_SIZE_SCALE
		pos = Vector2(
			clampf(pos.x - band_size.x * FAN_STEP_OFFSET_RATIO.x, 0.0, maxf(0.0, band_size.x - size.x)),
			maxf(0.0, pos.y - band_size.y * FAN_STEP_OFFSET_RATIO.y),
		)
		rects.append(Rect2(pos, size))

	if mirror_x:
		for i in range(rects.size()):
			rects[i].position.x = band_size.x - rects[i].position.x - rects[i].size.x

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
