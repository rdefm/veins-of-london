class_name CombatScreen
extends Control

var _content: VBoxContainer
var _strip_selected_key: Dictionary = {}
var _dial_selected_index: int = 0
const STAGE_WIDTH := 390.0 - 16.0 - 16.0
const STAGE_HEIGHT := 220.0
const COMMAND_DOCK_LEFT_MARGIN := 0.0
const COMMAND_DOCK_RIGHT_MARGIN := 4.0
const COMMAND_DOCK_BOTTOM_MARGIN := 6.0
const COMMAND_DOCK_HEIGHT := DialWidget.WIDGET_SIZE.y
const COLUMN_GAP := 6.0
const PLAYER_BAND_WIDTH := (STAGE_WIDTH - COLUMN_GAP) / 2.0
const ENEMY_BAND_WIDTH := STAGE_WIDTH - COLUMN_GAP - PLAYER_BAND_WIDTH
const STAGE_BORDER_WIDTH := 2.0
const STAGE_DEFAULT_FILL := Color(0.07, 0.07, 0.09)
const FAN_FRONT_SIZE_RATIO := Vector2(0.90, 0.52)
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
			PoseStep.new(strike, Vector2(CombatScreen.LUNGE_PX * fwd, 0.0)),
			PoseStep.new(recover, Vector2.ZERO),
		]
		_start_one_shot(steps, _attack_fps, false)
	func play_hit() -> void:
		if _hit_keyposes.is_empty():
			return
		var fwd: float = _forward_dir()
		var pose: Texture2D = _hit_keyposes[0]
		var steps: Array[PoseStep] = [
			PoseStep.new(pose, Vector2(-CombatScreen.RECOIL_PX * fwd, 0.0)),
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
			PoseStep.new(pose2, Vector2(0.0, CombatScreen.FALL_SINK_PX), CombatScreen.FALL_ROTATION_DEG, CombatScreen.FALL_ALPHA),
		]
		_start_one_shot(steps, _ko_fps, true)
	func play_self_patch() -> void:
		if _self_patch_keyposes.is_empty():
			return
		var pose: Texture2D = _self_patch_keyposes[0]
		var steps: Array[PoseStep] = [
			PoseStep.new(pose, Vector2(0.0, -CombatScreen.SELF_PATCH_RISE_PX)),
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
var _stage_frame: Panel
var _heading: Label
var _pacing_button: Button
var _strip_holder: VBoxContainer
var _footer_holder: VBoxContainer
var _command_dock: HBoxContainer
var _turn_order_strip: TurnOrderStrip
var _director: CombatDirector
var _revealed_log_count: int = -1
var _ghost_tracker: Dictionary = {}
var _frozen_roster: Dictionary = {}

func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	_command_dock = UI.hbox(8)
	_command_dock.anchor_left = 0.0
	_command_dock.anchor_right = 1.0
	_command_dock.anchor_top = 1.0
	_command_dock.anchor_bottom = 1.0
	_command_dock.offset_left = COMMAND_DOCK_LEFT_MARGIN
	_command_dock.offset_right = -COMMAND_DOCK_RIGHT_MARGIN
	_command_dock.offset_bottom = -COMMAND_DOCK_BOTTOM_MARGIN
	_command_dock.offset_top = -(COMMAND_DOCK_BOTTOM_MARGIN + COMMAND_DOCK_HEIGHT)
	add_child(_command_dock)
	var scroll_container := _content.get_parent().get_parent() as Control
	scroll_container.offset_bottom = -(COMMAND_DOCK_HEIGHT + COMMAND_DOCK_BOTTOM_MARGIN)

	_director = CombatDirector.new()
	add_child(_director)

	_load_default_animations()
	_load_template_idle_animations()
	_load_template_action_animations()
	_load_effect_animations()
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
	EventBus.combat_beats_played.connect(_on_combat_beats_played)
	EventBus.combat_rewind_played.connect(_on_combat_rewind_played)
	_sync()
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
func _sync() -> void:
	var combat: Dictionary = GameState.state["combat"]
	var player: Dictionary = GameState.state["player"]

	_heading.text = _context_label(combat["context"])
	_pacing_button.text = _pacing_button_label()

	for child in _strip_holder.get_children():
		child.queue_free()
	_turn_order_strip = _build_turn_order_strip(combat, player)
	_strip_holder.add_child(_turn_order_strip)

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
func _sync_footer(combat: Dictionary, player: Dictionary) -> void:
	for child in _footer_holder.get_children():
		child.queue_free()
	if combat["outcome"] != null and not _director.is_playing():
		_footer_holder.add_child(_build_outcome_button(combat["outcome"], combat["context"]))
		for child in _command_dock.get_children():
			child.queue_free()
	else:
		_build_command_deck(player)
func _build_turn_order_strip(combat: Dictionary, player: Dictionary) -> TurnOrderStrip:
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
func _on_strip_selection_changed(new_key: Dictionary) -> void:
	_strip_selected_key = new_key
	if new_key["type"] == "enemy":
		Combat.set_focused_enemy(new_key["index"])
	else:
		_sync()
func _build_stage_skeleton() -> Panel:
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(STAGE_WIDTH, STAGE_HEIGHT)
	frame.clip_contents = true

	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = STAGE_DEFAULT_FILL
	frame_style.border_width_left = STAGE_BORDER_WIDTH
	frame_style.border_width_top = STAGE_BORDER_WIDTH
	frame_style.border_width_right = STAGE_BORDER_WIDTH
	frame_style.border_width_bottom = STAGE_BORDER_WIDTH
	frame_style.border_color = Color(0, 0, 0, 0.65)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.gui_input.connect(_on_stage_gui_input)
	_stage_shake_layer = Control.new()
	_stage_shake_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_shake_layer.size = Vector2(STAGE_WIDTH, STAGE_HEIGHT)
	frame.add_child(_stage_shake_layer)
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

	return frame

func _on_stage_gui_input(event: InputEvent) -> void:
	if not _director.is_playing():
		return
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
	if pressed:
		_director.fast_forward_current_beat()

func _sync_stage(combat: Dictionary, player: Dictionary) -> void:
	_sync_backdrop(combat["context"])

	var enemies: Array = _frozen_roster.get("enemies", combat["enemies"])
	var allies: Array = _frozen_roster.get("allies", combat["allies"])
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
func _build_command_deck(player: Dictionary) -> void:
	_build_dial_and_actions_row(player)
func _build_dial_and_actions_row(player: Dictionary) -> void:
	for child in _command_dock.get_children():
		child.queue_free()

	var dial: Variant = player["dial"]
	if dial != null:
		_command_dock.add_child(_build_dial_widget(dial))
	_command_dock.add_child(_build_action_deck(player))
func _build_complication_detail(dial: Variant) -> Control:
	var glyph := SymbolGlyph.new()
	glyph.font_size = 20
	glyph.glyph_radius = 12.0
	glyph.draw_fallback = SymbolGlyph.generic_fallback()
	var accent := _action_color()
	glyph.color = accent

	if dial == null:
		return _build_card_bar(glyph, "No Dial", accent)

	var loaded: Array = dial["loadedComplications"]
	if loaded.is_empty():
		return _build_card_bar(glyph, "Empty", accent)

	var index: int = clampi(_dial_selected_index, 0, loaded.size() - 1)
	var entry: Dictionary = loaded[index]
	var recipe: Dictionary = GameData.RECIPES[entry["recipeKey"]]
	glyph.symbol = recipe["symbol"]
	return _build_card_bar(glyph, "%s — tier %d" % [recipe["name"], entry["tier"]], accent)
func _build_action_deck(player: Dictionary) -> Control:
	var col := UI.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_END
	col.add_child(_build_complication_detail(player["dial"]))
	col.add_child(_build_action_card("attack", "Attack", _on_attack_pressed))
	var has_items: bool = (
		Crafting.inventory_qty("timePearl") > 0 or Crafting.inventory_qty("enhancementPowder") > 0 or Crafting.inventory_qty("rewind") > 0
		or Crafting.inventory_qty("blast") > 0 or Crafting.inventory_qty("shield") > 0
		or Crafting.inventory_qty("blackHole") > 0 or Crafting.inventory_qty("healingBurst") > 0
		or Crafting.inventory_qty("prophetsBreath") > 0 or Crafting.inventory_qty("wormhole") > 0
		or (player["dial"] != null and not player["dial"]["loadedComplications"].is_empty())
	)
	col.add_child(_build_action_card("item", "Item", func(): Bag.open(), not has_items))
	col.add_child(_build_action_card("run", "Leg it", _on_run_pressed))

	return col
const _ACTION_COLOR_FALLBACK := Color(0.784314, 0.062745, 0.180392, 1)
const _ACTION_CARD_DISABLED_COLOR := Color(0.541176, 0.541176, 0.541176, 1)
const _ACTION_CARD_FILL := Color(0.980392, 0.972549, 0.952941, 1)

func _action_color() -> Color:
	return GameData.PALETTE.get("ui_action_red", _ACTION_COLOR_FALLBACK)
func _action_card_button_style(accent: Color, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, alpha)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style
const _ACTION_CARD_ICON_SIZE := 40.0
static func _action_icon_draw_fn(icon_kind: String) -> Callable:
	match icon_kind:
		"attack":
			return Icons.draw_attack
		"item":
			return Icons.draw_bag
		"run":
			return Icons.draw_run
		_:
			return Callable()

func _build_action_card(icon_kind: String, label_text: String, callback: Callable, disabled: bool = false) -> Control:
	var accent: Color = _ACTION_CARD_DISABLED_COLOR if disabled else _action_color()

	var button := Button.new()
	button.disabled = disabled
	button.add_theme_stylebox_override("normal", _action_card_button_style(accent, 0.0))
	button.add_theme_stylebox_override("hover", _action_card_button_style(accent, 0.14))
	button.add_theme_stylebox_override("pressed", _action_card_button_style(accent, 0.22))
	button.add_theme_stylebox_override("disabled", _action_card_button_style(accent, 0.0))
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", accent)
	button.add_theme_color_override("font_pressed_color", accent)
	button.add_theme_color_override("font_disabled_color", accent)
	button.pressed.connect(callback)
	var draw_icon := _action_icon_draw_fn(icon_kind)
	if draw_icon.is_valid():
		button.name = "ActionButton_%s" % icon_kind
		var glyph := UI.icon_glyph_control(draw_icon, UI.ICON_GLYPH_SCALE)
		UI.anchor_full_rect(glyph)
		button.add_child(glyph)
	else:
		button.text = icon_kind
		button.clip_text = true

	return _build_card_bar(button, label_text, accent, callback)
func _build_card_bar(icon: Control, label_text: String, accent: Color, click_callback: Callable = Callable()) -> Control:
	var c := UI.card()
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = _ACTION_CARD_FILL
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = accent
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_bottom = 8
	c["panel"].add_theme_stylebox_override("panel", panel_style)

	var row := UI.hbox(8)

	icon.custom_minimum_size = Vector2(_ACTION_CARD_ICON_SIZE, _ACTION_CARD_ICON_SIZE)
	row.add_child(icon)

	var caption := UI.label(label_text)
	caption.custom_minimum_size.x = 0.0
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.clip_text = true
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", accent)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(caption)

	c["content"].add_child(row)

	if click_callback.is_valid():
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(func(event: InputEvent) -> void:
			if not (event is InputEventMouseButton):
				return
			var mb: InputEventMouseButton = event
			if mb.button_index != MOUSE_BUTTON_LEFT or mb.pressed:
				return
			if icon is Button and (icon as Button).disabled:
				return
			click_callback.call()
		)

	return c["panel"]
func _on_attack_pressed() -> void:
	_play_round(func(): return Combat.player_attack())

func _on_run_pressed() -> void:
	_play_round(func(): return Combat.flee())

func _play_round(action: Callable) -> void:
	var combat: Dictionary = GameState.state["combat"]
	_frozen_roster = { "enemies": combat["enemies"].duplicate(true), "allies": combat["allies"].duplicate(true) }
	var log_before: int = combat["log"].size()
	var result: Dictionary = action.call()
	await _play_beats(result.get("beats", []), log_before)
func _play_beats(beats: Array, log_before: int) -> void:
	if beats.is_empty():
		_frozen_roster = {}
		return
	_revealed_log_count = log_before
	_init_ghost_tracker(beats)
	_sync_footer(GameState.state["combat"], GameState.state["player"])
	await _director.play(beats, _on_beat_played)
	_ghost_tracker.clear()
	_revealed_log_count = -1
	_frozen_roster = {}
	_sync()
func _push_revealed_log_line() -> void:
	var log: Array = GameState.state["combat"]["log"]
	var index: int = _revealed_log_count - 1
	if index >= 0 and index < log.size():
		Notify.push(log[index], Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })

func _on_beat_played(beat: Dictionary) -> void:
	_revealed_log_count += 1
	_push_revealed_log_line()
	_sync_footer(GameState.state["combat"], GameState.state["player"])
	var kind: String = beat.get("kind", "")
	if kind == Combat.BEAT_PLAYER_EVADE:
		var evading_slot: StageSlot = _resolve_target_slot(_beat_actor(beat))
		if evading_slot != null:
			evading_slot.ghost_next_pose()
	if _ATTACK_BEAT_KINDS.has(kind):
		var actor_slot: StageSlot = _resolve_target_slot(_beat_actor(beat))
		if actor_slot != null:
			actor_slot.play_attack()
			if beat.get("motionBoosted", false):
				actor_slot.spawn_afterimage()
	if kind == Combat.BEAT_ALLY_HEAL:
		var healer_slot: StageSlot = _resolve_target_slot(_beat_actor(beat))
		if healer_slot != null:
			healer_slot.play_self_patch()
	if kind == Combat.BEAT_USE_WORMHOLE or kind == Combat.BEAT_COMPLICATION_WORMHOLE:
		var wormhole_slot: StageSlot = _resolve_target_slot(_beat_actor(beat))
		if wormhole_slot != null:
			wormhole_slot.play_wormhole_vanish()
	var effect_key: String = beat.get("effectKey", "")
	if not effect_key.is_empty():
		_play_consumable_effect(beat, effect_key)
		if effect_key == "healingBurst" and _turn_order_strip != null:
			var player_key := TurnOrderStrip.card_key_string({ "type": "player", "index": -1 })
			var healed_hp: int = GameState.state["player"]["hp"]
			var overshoot_hp: int = mini(GameState.state["player"]["hpMax"], healed_hp + 12)
			_turn_order_strip.set_initial_ghost(player_key, overshoot_hp)
			_turn_order_strip.drain_ghost_to(player_key, healed_hp, 0.3)
	var shield_absorbed: int = int(beat.get("shieldAbsorbed", 0))
	if shield_absorbed > 0:
		var shielded_slot: StageSlot = _player_slots.get(-1)
		if shielded_slot != null:
			shielded_slot.flash_shield_crack()
	if CombatDirector.beat_is_damaging(beat):
		_play_juice(beat)
func _play_consumable_effect(beat: Dictionary, effect_key: String) -> void:
	var entry: Dictionary = _effect_frames_by_key.get(effect_key, {})
	var frames: Array[Texture2D] = entry.get("frames", _empty_idle_frames)
	if frames.is_empty():
		return
	var target: Dictionary = _beat_target(beat)
	if target["type"] == "":
		target = _default_effect_target(effect_key)
	var slot: StageSlot = _resolve_target_slot(target)
	if slot != null:
		slot.play_effect_sheet(frames, entry.get("fps", 0.0))
func _default_effect_target(effect_key: String) -> Dictionary:
	if effect_key == "timePearl":
		return { "type": "enemy", "index": GameState.state["combat"]["focusedEnemyIndex"] }
	return { "type": "player", "index": -1 }
func _on_combat_beats_played(beats: Array) -> void:
	if _director.is_playing() or beats.is_empty():
		return
	var log_before: int = GameState.state["combat"]["log"].size() - beats.size()
	await _play_beats(beats, log_before)
func _on_combat_rewind_played(beats: Array) -> void:
	if _director.is_playing() or beats.is_empty():
		return
	await _director.play(beats, _on_rewind_beat_played)
	_sync()
func _on_rewind_beat_played(beat: Dictionary) -> void:
	var kind: String = beat.get("kind", "")
	if _ATTACK_BEAT_KINDS.has(kind):
		var actor_slot: StageSlot = _resolve_target_slot(_beat_actor(beat))
		if actor_slot != null:
			actor_slot.play_attack()
	if CombatDirector.beat_is_damaging(beat):
		var target: Dictionary = _beat_target(beat)
		var slot: StageSlot = _resolve_target_slot(target)
		if slot != null:
			slot.flash_hit()
			slot.play_hit()
		_shake_stage(int(beat["dmg"]), _hp_max_for(target))

func _build_dial_widget(dial: Dictionary) -> Control:
	var widget := DialWidget.new()
	widget.configure(dial, _dial_selected_index, _on_dial_selection_changed, _on_dial_triggered)
	return widget
func _on_dial_selection_changed(new_index: int) -> void:
	_dial_selected_index = new_index
	_sync()
func _on_dial_triggered(result: Dictionary) -> void:
	var beats: Array = result.get("beats", [])
	var log_before: int = GameState.state["combat"]["log"].size() - beats.size()
	await _play_beats(beats, log_before)
func _beat_target(beat: Dictionary) -> Dictionary:
	var target_type: String = beat.get("targetType", "")
	var target_index: int = -1 if target_type == "player" else int(beat.get("targetIndex", -1))
	return { "type": target_type, "index": target_index }
func _beat_actor(beat: Dictionary) -> Dictionary:
	var actor_type: String = beat.get("actorType", "")
	var actor_index: int = -1 if actor_type == "player" else int(beat.get("actorIndex", -1))
	return { "type": actor_type, "index": actor_index }
const _ATTACK_BEAT_KINDS: Array[String] = [
	Combat.BEAT_PLAYER_ATTACK, Combat.BEAT_ALLY_ATTACK, Combat.BEAT_ENEMY_ATTACK,
	Combat.BEAT_ENEMY_EVADE, Combat.BEAT_PLAYER_EVADE,
]
func _target_state(target: Dictionary) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if target["type"] == "player":
		return GameState.state["player"]
	if target["type"] == "ally":
		return combat["allies"][target["index"]]
	if target["type"] == "enemy":
		return combat["enemies"][target["index"]]
	return {}

func _hp_for(target: Dictionary) -> int:
	return _target_state(target).get("hp", 0)

func _hp_max_for(target: Dictionary) -> int:
	return _target_state(target).get("hpMax", 1)

func _resolve_target_slot(target: Dictionary) -> StageSlot:
	if target["type"] == "player":
		return _player_slots.get(-1)
	if target["type"] == "ally":
		return _player_slots.get(target["index"])
	if target["type"] == "enemy":
		return _enemy_slots.get(target["index"])
	return null
func _init_ghost_tracker(beats: Array) -> void:
	_ghost_tracker.clear()
	var total_dmg: Dictionary = {}
	var target_by_key: Dictionary = {}
	for beat in beats:
		if not CombatDirector.beat_is_damaging(beat):
			continue
		var target: Dictionary = _beat_target(beat)
		var key: String = TurnOrderStrip.card_key_string(target)
		total_dmg[key] = total_dmg.get(key, 0) + int(beat["dmg"])
		target_by_key[key] = target

	for key in total_dmg.keys():
		var start_hp: int = _hp_for(target_by_key[key]) + total_dmg[key]
		_ghost_tracker[key] = start_hp
		if _turn_order_strip != null:
			_turn_order_strip.set_initial_ghost(key, start_hp)

func _drain_ghost(key: String, dmg: int) -> void:
	if not _ghost_tracker.has(key):
		return
	_ghost_tracker[key] = maxi(0, _ghost_tracker[key] - dmg)
	if _turn_order_strip != null:
		_turn_order_strip.drain_ghost_to(key, _ghost_tracker[key], _director.beat_duration)

func _shake_magnitude(dmg: int, hp_max: int) -> float:
	if hp_max <= 0:
		return SHAKE_MIN_PX
	var frac: float = clampf(float(dmg) / float(hp_max), 0.0, 1.0)
	return clampf(SHAKE_MIN_PX + (SHAKE_MAX_PX - SHAKE_MIN_PX) * (frac / SHAKE_FULL_FRACTION), SHAKE_MIN_PX, SHAKE_MAX_PX)

func _shake_stage(dmg: int, hp_max: int) -> void:
	if _stage_shake_layer == null or not _stage_shake_layer.is_inside_tree():
		return
	var magnitude: float = _shake_magnitude(dmg, hp_max)
	var base_pos: Vector2 = _stage_shake_layer.position
	var tween := create_tween()
	tween.tween_property(_stage_shake_layer, "position", base_pos + Vector2(magnitude, 0.0), 0.03)
	tween.tween_property(_stage_shake_layer, "position", base_pos + Vector2(-magnitude, magnitude * 0.5), 0.05)
	tween.tween_property(_stage_shake_layer, "position", base_pos + Vector2(magnitude * 0.5, -magnitude * 0.4), 0.05)
	tween.tween_property(_stage_shake_layer, "position", base_pos, 0.06)

func _spawn_damage_number(slot: StageSlot, dmg: int) -> void:
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
func _play_juice(beat: Dictionary) -> void:
	var target: Dictionary = _beat_target(beat)
	var dmg: int = int(beat["dmg"])

	var slot: StageSlot = _resolve_target_slot(target)
	if slot != null:
		slot.flash_hit()
		_spawn_damage_number(slot, dmg)
		if _target_state(target).get("koed", false):
			slot.play_ko()
		else:
			slot.play_hit()

	_shake_stage(dmg, _hp_max_for(target))
	_drain_ghost(TurnOrderStrip.card_key_string(target), dmg)

func _build_outcome_button(outcome: String, context: String) -> Control:
	var label: String
	if outcome == "win":
		label = "✅ They've legged it" if Combat.NON_LETHAL_MUGGING_CONTEXTS.has(context) else "✅ Vein secured"
	elif outcome == "fled":
		label = "🏃 Scarper"
	else:
		label = "💀 Come round"

	return UI.button(label, _on_continue_pressed)
func _on_continue_pressed() -> void:
	Combat.exit_combat()
