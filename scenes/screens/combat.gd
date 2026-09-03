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

# combat-presentation ticket 10: left/right stage split -- player + allies
# occupy the left column, enemies the right, each column running the full
# stage height. This DEVIATES from docs/combat-animation-vision.md §2's
# adopted "stacked bands" grammar (enemy band upper third, player+ally band
# lower two-thirds) -- a direct, explicit call from the human over that
# doc's own guidance, made when the stacked layout's sprites were reviewed
# on-device. §2 itself is not amended by this comment; flagged here so the
# next reader of that doc knows the shipped layout has diverged from it.
const COLUMN_GAP := 6.0
const PLAYER_BAND_WIDTH := (STAGE_WIDTH - COLUMN_GAP) / 2.0
const ENEMY_BAND_WIDTH := STAGE_WIDTH - COLUMN_GAP - PLAYER_BAND_WIDTH

# combat-presentation ticket 08, §9: the frame's own hard border width --
# shared by _build_stage_skeleton()'s StyleBoxFlat and the backdrop layer's
# inset, so the backdrop plate/fallback fill never paints over the border
# it's supposed to sit inside of.
const STAGE_BORDER_WIDTH := 2.0

# combat-presentation ticket 08: the dark fill both the frame's own
# StyleBoxFlat (before any backdrop existed) and _sync_backdrop()'s
# last-resort default (an unrecognised context, or a manifest entry with no
# usable fallbackColor) use -- one literal instead of two so they can't
# drift apart.
const STAGE_DEFAULT_FILL := Color(0.07, 0.07, 0.09)

# Near/far diagonal fan (§2.2 refinement): the front slot is large and
# foreground; the other two are smaller and staggered behind it, not laid
# out flat left-to-right. Sized as a fraction of whichever column they're
# in -- tuned for the tall, narrow (roughly half-stage-width, full-stage-
# height) columns the left/right split above produces, not the original
# wide-short bands.
const FAN_FRONT_SIZE_RATIO := Vector2(0.62, 0.36)
const FAN_BACK_SIZE_RATIO := Vector2(0.42, 0.24)

# Placement fractions for _fan_local_rects(): how far the two back slots
# tuck in from the front slot's edges (as a fraction of a back slot's own
# width), and how far each slot sits from its column's near/far edge (as a
# fraction of column height). back-right sits slightly lower than back-left
# purely to read as "behind at a different depth" rather than a mirrored
# pair -- an arbitrary but deliberate asymmetry, not a bug. _fan_local_rects()
# itself clamps the resulting x positions to the column's own width, so a
# narrow column can't push a back slot into the neighbouring column no
# matter how these fractions are tuned.
const FAN_BACK_LEFT_TUCK := 0.9
const FAN_BACK_RIGHT_TUCK := 0.1
const FAN_FRONT_BOTTOM_MARGIN := 0.03
const FAN_BACK_LEFT_TOP_MARGIN := 0.04
const FAN_BACK_RIGHT_TOP_MARGIN := 0.12

# combat-presentation ticket 03, §2.5: the Dial widget's docked-right column
# width -- narrow enough to leave the action-card row its space, wide enough
# for the clock-face/bezel placeholder shapes (DialWidget._draw()) to read.
const DIAL_WIDTH := 64.0

# combat-presentation ticket 05, §4.1: damage numbers rising and fading from
# the struck combatant's on-stage position.
const DAMAGE_NUMBER_RISE_PX := 28.0
const DAMAGE_NUMBER_DURATION := 0.6

# combat-presentation ticket 05, §4.1: "Screen shake, 3-6px, scaled to damage
# as a fraction of the target's hpMax." SHAKE_FULL_FRACTION is the dmg/hpMax
# ratio at which shake maxes out at SHAKE_MAX_PX -- a hit for half a target's
# max HP or more always reads as the biggest shake this game has; anything
# below scales linearly down to SHAKE_MIN_PX at 0 damage (which never
# actually plays, since this only runs for beats with dmg > 0).
const SHAKE_MIN_PX := 3.0
const SHAKE_MAX_PX := 6.0
const SHAKE_FULL_FRACTION := 0.5

# combat-presentation ticket 10, docs/combat-animation-vision.md §4: "not
# hand-animated motion" -- attack/hit/ko each carry exactly this many
# generated keyposes (wind-up/strike/recover, a single hit pose, down/fallen)
# regardless of how many frames a manifest sheet actually has; StageSlot's
# own transform tween (lunge/recoil/fall) is what supplies the motion
# between them. _select_action_keyposes() below down-samples any sheet with
# more frames than this (e.g. templates.default's own multi-frame stand-in
# strips, a leftover from before this ticket) to exactly this count.
const ATTACK_KEYPOSE_COUNT := 3
const HIT_KEYPOSE_COUNT := 1
const KO_KEYPOSE_COUNT := 2

# combat-presentation ticket 10, §4: the transform magnitudes StageSlot's
# play_attack()/play_hit()/play_ko()/play_self_patch() tween _sprite_rect
# through between keyposes -- "lunge and return" / "recoil" / "fall + fade".
# Small, pixel-art-scale offsets (StageSlot's own slot rect is a fraction of
# STAGE_WIDTH/STAGE_HEIGHT), not full-screen movement.
const LUNGE_PX := 14.0
const RECOIL_PX := 8.0
const FALL_SINK_PX := 10.0
const FALL_ROTATION_DEG := 20.0
const FALL_ALPHA := 0.35
const SELF_PATCH_RISE_PX := 6.0

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

	# combat-presentation ticket 05, §4.1: "Flash-to-white on the struck
	# placeholder/sprite (a CanvasItem material flash, not new art)." Drawn
	# as a plain white overlay via _overlay (see below) rather than an
	# actual CanvasItemMaterial shader swap -- an alpha-blended overlay
	# reads identically to a shader flash against either a placeholder box
	# or a real sprite, at a fraction of the complexity; a later ticket can
	# swap the mechanism without touching any juice-layer call site
	# (flash_hit() is the only entry point).
	var flash_alpha: float = 0.0

	# combat-presentation ticket 09 -- see data/combat_visuals.json's
	# per-subject "templates" entries and CombatScreen._load_template_idle_
	# animations()/_sync_band() below: once a subject's manifest idle entry
	# has a real image, set_idle_animation() gets real frames, which replace
	# the ticket-01 placeholder fill/border in _draw() below. Empty
	# _idle_frames means "no sprite for this subject yet, draw the
	# placeholder box" -- every subject's manifest entry is still an empty
	# stub as of this ticket (no art produced), so this fallback is what
	# every combatant actually shows today.
	#
	# _sprite_rect/_idle_timer/_overlay are built in _init() rather than
	# _ready() or _process()-driven, because this file's own test harness
	# (tests/test_combat_screen.gd) never adds these Controls to a live
	# SceneTree -- see flash_hit()'s pre-existing is_inside_tree() guard for
	# the same constraint. _init() runs at construction regardless of tree
	# membership, so the child structure always exists; _idle_timer simply
	# never ticks off-tree, which is fine since off-tree tests drive frame
	# advance directly via _advance_idle_frame() instead of waiting on it.
	#
	# _overlay is a separate Control (not more of this class's own _draw())
	# so the focus glow/flash always render on top of _sprite_rect -- a
	# Control's children draw after its own _draw() call, so without a
	# dedicated top layer the flash would render *under* a real sprite.
	#
	# "player" or "enemy" -- combat-presentation ticket 10, purely cosmetic
	# (mirrors the sprite via _sprite_rect.flip_h so the two stage columns
	# don't both face the same arbitrary direction; see set_side() below).
	# Not read anywhere else.
	var side: String = "player"

	# combat-presentation ticket 09: an extra flip on top of the side-based
	# one, applied to every other same-template concurrent instance (two or
	# three Muggers sharing the one Mugger sheet -- see
	# CombatScreen._sync_band()'s per-template occurrence counter) purely so
	# they don't render as visibly identical copies. No new art either way --
	# see _apply_flip() below for how this combines with `side`.
	var _mirror_extra: bool = false
	var _idle_frames: Array[Texture2D] = []
	var _idle_frame_index: int = 0
	var _sprite_rect: TextureRect
	var _idle_timer: Timer
	var _overlay: Control

	# combat-presentation ticket 10, docs/combat-animation-vision.md §4: the
	# transform-driven one-shots layered on top of ticket 09's idle loop --
	# attack on whoever's swinging (_on_beat_played()), hit/ko on the struck
	# combatant (_play_juice()), self-patch on a healing ally
	# (_on_beat_played()). Same manifest-driven shape as _idle_frames
	# (set_*_animation() below, mirroring set_idle_animation()) except these
	# arrays hold *keyposes*, not a flipbook -- ATTACK_KEYPOSE_COUNT/
	# HIT_KEYPOSE_COUNT/KO_KEYPOSE_COUNT many, per the doctrine table. Empty
	# means "no manifest entry", and the corresponding play_*() call then
	# just no-ops rather than erroring, same convention as every other
	# manifest-driven fallback in this file.
	var _hit_keyposes: Array[Texture2D] = []
	var _hit_fps: float = 10.0
	var _ko_keyposes: Array[Texture2D] = []
	var _ko_fps: float = 12.0
	var _attack_keyposes: Array[Texture2D] = []
	var _attack_fps: float = 12.0
	var _self_patch_keyposes: Array[Texture2D] = []
	var _self_patch_fps: float = 10.0

	# One discrete step of a transform one-shot: a keypose texture plus the
	# _sprite_rect position offset/rotation/alpha to show it at, relative to
	# this slot's own rest transform (offset (0,0), rotation 0, alpha 1) --
	# see _apply_pose_step() below. This *is* "transform lunge/recoil/fall",
	# per §4's doctrine that the motion between generated keyposes is a
	# transform, not extra drawn frames -- play_attack()/play_hit()/play_ko()/
	# play_self_patch() below each synthesize a short list of these (reusing
	# the same texture across more than one step where the doctrine's frame
	# count is smaller than the motion needs, e.g. hit's single pose across
	# a recoil-out/recoil-back pair) rather than storing pre-baked motion
	# frames in the manifest.
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

	# Drives a one-shot play_*() sequence forward -- see _advance_one_shot()
	# below. Empty means "no one-shot in progress, idle owns the texture".
	var _one_shot_steps: Array[PoseStep] = []
	var _one_shot_index: int = 0
	var _one_shot_hold_last_frame: bool = false
	var _one_shot_timer: Timer

	# combat-presentation ticket 10, docs/combat-animation-vision.md §5:
	# prophetsBreath's deferred visual ("the enemy's next pose ghosts in at
	# ~30% alpha before it happens") -- a separate TextureRect from
	# _sprite_rect so ghost_next_pose() (below) never fights play_attack()'s
	# own texture/position changes even though CombatScreen fires both in the
	# same beat (see ghost_next_pose()'s own comment for why that's fine).
	var _ghost_rect: TextureRect

	func _init() -> void:
		_sprite_rect = TextureRect.new()
		_sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# expand_mode defaults to EXPAND_KEEP_SIZE, which draws the texture at
		# its native pixel size regardless of this control's own rect -- the
		# "sprite renders way bigger than its slot, spilling out of the stage
		# frame" bug the human flagged from an on-device screenshot.
		# IGNORE_SIZE is what lets stretch_mode actually scale the texture
		# down to fit.
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

	# combat-presentation ticket 10: enemies face left (toward the player
	# column), player/allies face right (toward the enemy column) -- a real
	# "face each other" convention now that the stage is a left/right split,
	# not the top/bottom bands this flip started under.
	func set_side(value: String) -> void:
		side = value
		_apply_flip()

	# combat-presentation ticket 09: called from CombatScreen._sync_band() for
	# every slot, every sync -- see this class's own `_mirror_extra` comment.
	func set_mirror_extra(value: bool) -> void:
		_mirror_extra = value
		_apply_flip()

	func _apply_flip() -> void:
		_sprite_rect.flip_h = (side == "enemy") != _mirror_extra

	# combat-presentation ticket 10: which way this slot's own attack lunges/
	# a hit recoils away from -- enemies face left (toward the player column),
	# player/allies face right (toward the enemy column), same convention
	# set_side()'s own comment already established for the sprite flip.
	func _forward_dir() -> float:
		return -1.0 if side == "enemy" else 1.0

	func set_flash_alpha(value: float) -> void:
		flash_alpha = value
		_overlay.queue_redraw()

	# Public entry point CombatScreen._play_juice() calls on a landed hit.
	# Jumps straight to full white, then tweens back down to transparent --
	# no live tree (e.g. a unit test constructing a bare StageSlot), no
	# tween, same guard this file's other juice-layer tweens all use.
	func flash_hit() -> void:
		set_flash_alpha(1.0)
		if not is_inside_tree():
			return
		var tween := create_tween()
		tween.tween_method(set_flash_alpha, 1.0, 0.0, 0.18)

	# combat-presentation ticket 10, docs/combat-animation-vision.md §5:
	# prophetsBreath's deferred visual -- "the enemy's next pose ghosts in at
	# ~30% alpha before it happens." CombatScreen._on_beat_played() calls
	# this on a BEAT_PLAYER_EVADE beat's actor, immediately before calling
	# play_attack() for the same beat (evade beats are still in
	# _ATTACK_BEAT_KINDS -- they're a whiffed swing, not a no-op). The two
	# are deliberately NOT sequenced (this doesn't block/delay play_attack())
	# -- _ghost_rect is its own Control, so a translucent preview of the
	# swing's wind-up pose fading in and back out reads fine layered under
	# the real swing playing out at full opacity on _sprite_rect; actually
	# blocking play_attack() until this finishes would need turning beat
	# playback itself async for a purely cosmetic ordering nicety.
	# No live tree, no tween, no visible ghost -- same guard flash_hit() uses.
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

	# combat-presentation ticket 09: CombatScreen._sync_band() calls this
	# for every slot, every sync -- `frames` is the same shared array either
	# way (nothing per-instance to build), so this is cheap to call
	# unconditionally. An empty `frames` array (no manifest entry yet)
	# reverts the slot to the ticket-01 placeholder box.
	func set_idle_animation(frames: Array[Texture2D], fps: float) -> void:
		_idle_frames = frames
		_idle_frame_index = 0
		_sprite_rect.visible = not frames.is_empty()
		_sprite_rect.texture = frames[0] if not frames.is_empty() else null
		if frames.size() >= 2 and fps > 0.0:
			_idle_timer.wait_time = 1.0 / fps
			_idle_timer.start()
		else:
			_idle_timer.stop()
		queue_redraw()

	# Ping-pong across however many frames were given (2, for today's single
	# shared dummy sheet -- straight alternation, same as any 2-frame
	# ping-pong). Public so tests can drive it directly without a live tree
	# ever actually ticking _idle_timer -- see this class's own top comment.
	# No-ops while a one-shot (_one_shot_steps non-empty) owns _sprite_rect's
	# texture -- idle keeps ticking in the background regardless (simpler
	# than stopping/restarting the timer around every one-shot), it just
	# mustn't clobber the one-shot's current frame.
	func _advance_idle_frame() -> void:
		if _idle_frames.size() < 2 or not _one_shot_steps.is_empty():
			return
		_idle_frame_index = (_idle_frame_index + 1) % _idle_frames.size()
		_sprite_rect.texture = _idle_frames[_idle_frame_index]

	# combat-presentation ticket 10: manifest-driven loaders for the four
	# transform one-shots, same shape and calling convention as
	# set_idle_animation() (CombatScreen._sync_band() calls all five for
	# every slot, every sync -- see that func's own comment for why that's
	# cheap). `frames` is already down-sampled to the doctrine's keypose
	# count by the time it reaches here (CombatScreen._select_action_keyposes()).
	# Unlike idle, these don't start anything themselves -- a one-shot only
	# plays when play_attack()/play_hit()/play_ko()/play_self_patch() is
	# actually called, from a beat.
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

	# Public entry points CombatScreen's beat-playback callbacks drive --
	# _on_beat_played() for play_attack()/play_self_patch(), _play_juice()
	# for play_hit()/play_ko(). A no-op when the manifest has nothing for
	# this animation (empty keyposes) -- same "degrade quietly, never error"
	# convention set_idle_animation()'s own empty-frames case already
	# established. §4's doctrine: "Attack | 3 keyposes | transform lunge and
	# return" -- wind-up at rest, strike at the lunge offset, recover back at
	# rest; missing keyposes (a manifest entry with fewer than
	# ATTACK_KEYPOSE_COUNT frames) repeat the last one available rather than
	# erroring.
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

	# §4: "Hit | 1 pose | transform recoil + white flash" -- the flash is
	# CombatScreen._play_juice()'s own flash_hit() call, unchanged by this
	# ticket. The single pose plays across two steps (recoiled, then back) so
	# there's still a transform to animate even though there's only one
	# keypose to show throughout it.
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

	# §4: "KO | 2 poses | transform fall + fade." Holds on the fallen/faded
	# last step rather than reverting to idle -- this slot's owner is koed.
	# CombatScreen's frozen-roster mechanism (_play_round()/_sync_stage()) is
	# what keeps this specific Node alive long enough to actually show the
	# hold; the slot is freed for real once the round's beat playback
	# finishes and _sync() reconciles the stage to the true (post-round)
	# roster.
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

	# §3: Archie's self-patch pose (`_allies_act`/`_ally_turn`'s heal-below-
	# 40%-HP action) -- CombatScreen._on_beat_played() calls this on a
	# BEAT_ALLY_HEAL beat's actor. No doctrine frame count is specified for
	# this one (it's not in §4's table -- a per-subject extra, §3's own
	# roster note), so it's played the same shape as hit: a single pose
	# across a small rise-and-settle transform rather than a recoil.
	func play_self_patch() -> void:
		if _self_patch_keyposes.is_empty():
			return
		var pose: Texture2D = _self_patch_keyposes[0]
		var steps: Array[PoseStep] = [
			PoseStep.new(pose, Vector2(0.0, -CombatScreen.SELF_PATCH_RISE_PX)),
			PoseStep.new(pose, Vector2.ZERO),
		]
		_start_one_shot(steps, _self_patch_fps, false)

	func _start_one_shot(steps: Array[PoseStep], fps: float, hold_last_frame: bool) -> void:
		if steps.is_empty():
			return
		_one_shot_steps = steps
		_one_shot_index = 0
		_one_shot_hold_last_frame = hold_last_frame
		_apply_pose_step(steps[0])
		# combat-presentation ticket 09: a one-shot (still shared "default"
		# art in the common case) can fire on a slot whose own idle is empty
		# (no per-subject art yet), which leaves _sprite_rect hidden (see
		# set_idle_animation()). Without forcing it visible here, the
		# one-shot's frames would be assigned to a hidden TextureRect and
		# never actually show. _end_one_shot() below is what hides it again
		# once the one-shot finishes, if there's still no idle to fall back
		# to.
		_sprite_rect.visible = true
		if steps.size() < 2 or fps <= 0.0:
			_end_one_shot()
			return
		_one_shot_timer.wait_time = 1.0 / fps
		_one_shot_timer.start()

	# Applies one PoseStep's texture/offset/rotation/alpha to _sprite_rect --
	# the "transform" half of "transform lunge/recoil/fall", shared by every
	# play_*() one-shot and by _end_one_shot()'s own reset back to rest.
	# pivot_offset is recomputed every call (cheap, and _sprite_rect's size
	# is only known once it's actually been laid out by _sync_band()) so
	# play_ko()'s fall rotation pivots around the sprite's own centre rather
	# than its top-left corner.
	func _apply_pose_step(step: PoseStep) -> void:
		_sprite_rect.texture = step.texture
		_sprite_rect.position = step.offset
		_sprite_rect.pivot_offset = _sprite_rect.size / 2.0
		_sprite_rect.rotation_degrees = step.rotation_degrees
		_sprite_rect.modulate.a = step.alpha

	# Public (not `_`-prefixed... it is, but so is _advance_idle_frame() --
	# same off-tree-test convention) so tests can drive a one-shot forward
	# without a live tree ever actually ticking _one_shot_timer.
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

	# Hands _sprite_rect's texture and transform back to idle/rest -- either
	# the one-shot finished (attack/hit/self-patch) or it had too few steps
	# or no fps to animate at all (single-frame or malformed manifest entry).
	# Never called for a held (ko) one-shot; see _advance_one_shot() above.
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
			# combat-presentation ticket 09: no idle to hand back to (this
			# subject has no manifest art yet) -- revert to the ticket-01
			# placeholder box exactly as set_idle_animation()'s own empty-
			# frames case does, rather than leaving the one-shot's last frame
			# stuck on screen.
			_sprite_rect.visible = false
			_sprite_rect.texture = null

	func _draw() -> void:
		if _idle_frames.is_empty():
			var rect := Rect2(Vector2.ZERO, size)
			draw_rect(rect, fill_color, true)
			draw_rect(rect, Color(0, 0, 0, 0.55), false, 2.0)
	# combat-presentation ticket 02: the placeholder box itself carries no
	# name/HP label any more (see _build_slot() below) -- combatant_name is
	# still set, purely as the template-id key _placeholder_color() and tests
	# read, not for display.

	func _draw_overlay() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		if is_focused:
			_overlay.draw_rect(rect.grow(3.0), Color(1.0, 0.86, 0.35, 0.95), false, 3.0)
		if flash_alpha > 0.0:
			_overlay.draw_rect(rect, Color(1.0, 1.0, 1.0, flash_alpha), true)


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

# combat-presentation ticket 08, docs/combat-animation-vision.md §2.1/§6:
# the per-context backdrop -- built once in _build_stage_skeleton() (behind
# both band layers so combatants render on top of it) and re-pointed at
# whichever context/fallback data/combat_visuals.json names for the current
# fight each _sync_stage() (see _sync_backdrop() below). Exactly one of the
# two is visible at a time: a real plate once ticket 09 lands one for a
# context, the flat palette-colour fill until then.
var _backdrop_texture: TextureRect
var _backdrop_fill: ColorRect

# combat-presentation ticket 10: the attack/hit/ko one-shots' shared
# "default" stand-in, per data/combat_visuals.json's templates.default --
# loaded once in _ready() (see _load_default_animations() below), not
# per-sync/per-slot. This is the FALLBACK used only when a combatant's own
# template key has no non-empty entry of its own (see
# _resolve_action_keyposes() and _sync_band() below). Empty means no
# manifest entry (or the image failed to load) -- that one-shot then just
# never plays (see StageSlot's own play_*() comments), same "degrade
# quietly" convention every manifest lookup in this file uses.
var _default_attack_keyposes: Array[Texture2D] = []
var _default_attack_fps: float = 12.0
var _default_hit_keyposes: Array[Texture2D] = []
var _default_hit_fps: float = 10.0
var _default_ko_keyposes: Array[Texture2D] = []
var _default_ko_fps: float = 12.0

# combat-presentation ticket 09, docs/combat-animation-vision.md §3/§4: idle
# frames+fps per cast-subject template key (data/combat_visuals.json's
# "templates" entries, "default" included), loaded once in _ready()
# (_load_template_idle_animations() below) rather than per-sync/per-slot.
# Keyed by whatever enemy_template_key()/_player_display_entries()/
# _ally_template_key resolve a slot's combatant to ("player", an ally's
# contactId, a GameData.ENEMY_RAID_GUARDS key, "homeRaidRaider", "mugger",
# or "default" itself, read directly by _sync_band() as the shared fallback
# below). A key with no manifest entry, an empty image, or a missing file
# resolves to the empty-frames default below, same as any other lookup here
# -- what _sync_band() then DOES with that emptiness is its own call (falls
# back to templates.default.idle, per a human-flagged follow-up to ticket 10:
# every subject shows a sprite, real or the shared Gangsters_2-sourced stand-
# in, not a blank box -- see that call site's own comment). This dict itself
# stays a plain per-template lookup with no fallback baked in, so
# _resolve_action_keyposes() can use it exactly like the attack/hit/ko
# dictionaries below.
var _idle_frames_by_template: Dictionary = {}
# A genuinely typed empty array, used as _sync_band()'s Dictionary.get()
# default below -- see that call site's own comment for why an untyped `[]`
# literal there fails a runtime type check that this doesn't.
var _empty_idle_frames: Array[Texture2D] = []

# combat-presentation ticket 10, docs/combat-animation-vision.md §3/§4: the
# per-subject counterparts to _idle_frames_by_template above -- attack/hit/
# ko keyposes per template key, loaded once in _ready()
# (_load_template_action_animations() below). An empty entry here doesn't
# mean "show nothing" -- _resolve_action_keyposes() below falls back to the
# shared _default_*_keyposes stand-in, exactly like idle now does too (see
# that dict's own comment). _self_patch_keyposes_by_template has no such
# fallback -- selfPatch is Archie-only, and "default" carries no heal pose
# to lend (data/combat_visuals.json's own "actionRule" note).
var _attack_keyposes_by_template: Dictionary = {}
var _hit_keyposes_by_template: Dictionary = {}
var _ko_keyposes_by_template: Dictionary = {}
var _self_patch_keyposes_by_template: Dictionary = {}

# combat-presentation ticket 05: the screen-shake wrapper -- see
# _build_stage_skeleton()'s own comment for why this, not `frame`, is what
# _shake_stage() tweens.
var _stage_shake_layer: Control

# The stage frame, the turn-order strip, and the footer (command deck, or
# the log + outcome button once the fight resolves) are each held in their
# own fixed-position holder so _sync() can rebuild just one of them without
# disturbing _content's child order -- see _ready() below.
var _stage_frame: Panel
var _heading: Label
var _pacing_button: Button
var _strip_holder: VBoxContainer
var _footer_holder: VBoxContainer

# combat-presentation ticket 05: the currently-mounted strip, kept so the
# juice layer's ghost-drain calls can reach it without re-walking
# _strip_holder's children. Rebuilt (and reassigned) every real _sync() --
# see _sync() below -- but, like the strip itself, NOT torn down per-beat
# mid-playback, which is exactly what lets a single round's worth of
# ghost-drain calls land on the same NameplateCard instances in sequence.
var _turn_order_strip: TurnOrderStrip

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

# combat-presentation ticket 05, §4.1: "HP bar lag-drain -- a ghost bar
# chasing the real (already-updated) value down." Keyed by
# TurnOrderStrip.card_key_string() (a "type:index" string, "-1" for the
# player) -- the running hp each key's ghost bar is currently sitting at,
# mid-drain. Seeded once per round by _init_ghost_tracker() (reconstructed
# from combat's already-final hp plus this round's total damage, since
# there's no separate "pre-round hp" snapshot to read -- GameState is
# already final by the time any of this runs, same fact combat_director.gd's
# own top comment explains for beats generally) and decremented beat by
# beat as each damaging beat plays; cleared at the end of _play_beats()
# since it's only meaningful mid-playback.
var _ghost_tracker: Dictionary = {}

# combat-presentation ticket 10: a pre-round snapshot of combat.enemies/
# combat.allies (deep-copied, so later mutation of the live arrays can't
# touch it), held only while a round's beats are playing. {} (the default,
# and where this always ends up once playback finishes) means "read the
# live GameState roster" -- see _sync_stage() above.
#
# Why this exists: Combat.player_attack()/flee() resolve the whole round
# and emit state_changed synchronously before _play_beats() ever starts
# playing beats back (combat_director.gd's own top comment) -- so the
# ordinary state_changed -> _sync() -> _sync_stage() chain would already
# have excluded a combatant koed *this* round from the fan before their
# death beat even plays, same "gone by the time playback starts" gap
# _play_juice()'s own comment flags for flash/damage-number/ghost-drain.
# Snapshotting the pre-round roster and reading *that* for the first
# _sync_stage() (fired mid-action.call(), before _play_beats() ever runs)
# keeps every combatant who started the round alive on stage for its
# duration, so a lethal beat's play_ko() (see _play_juice()) has a slot to
# land on. _sync_band()'s own position/fan reflow only runs at round start
# and round end (never mid-playback -- see _play_beats()), so a dying
# combatant's slot holds its position and death pose for the whole round
# without fighting a live re-fan. Cleared (and a final _sync() run against
# the real, final roster) at the end of _play_beats() -- Dial-cast playback
# (_on_dial_triggered()) never sets this, so it's unaffected by this
# mechanism, same pre-existing (already-flagged) gap as before this ticket.
var _frozen_roster: Dictionary = {}


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)

	_director = CombatDirector.new()
	add_child(_director)

	_load_default_animations()
	_load_template_idle_animations()
	_load_template_action_animations()

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


# combat-presentation ticket 10: loads data/combat_visuals.json's
# templates.default.{attack,hit,ko} -- the shared, not-yet-palette-quantised
# build-test sheet set used as _resolve_action_keyposes()'s fallback for any
# subject whose own per-subject entry (loaded by
# _load_template_action_animations() below) is still empty. Each sheet is
# sliced into `frameCount` equal-width AtlasTextures then down-sampled to the
# doctrine's own keypose count by _select_action_keyposes() -- "default"'s
# own dummy sheets carry more frames than the doctrine (leftovers from
# before this ticket properly split attack/hit/ko into keyposes+transform),
# which is exactly the case that down-sampling exists to handle. idle is
# deliberately absent here -- ticket 09 moved it to
# _load_template_idle_animations() below.
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


# combat-presentation ticket 09: loads every data/combat_visuals.json
# templates.<key>.idle entry -- "default" included (harmless: no combatant's
# resolved template key is ever literally "default", so its idle entry just
# never gets looked up -- see _idle_frames_by_template's own comment). Fully
# manifest-driven (every key present under "templates", not a hardcoded
# roster of the seven cast subjects) so a future ticket that adds an eighth
# subject's manifest entry needs no code change here, per docs/
# combat-animation-vision.md §6 step 4 ("manifest, not hardcoding").
func _load_template_idle_animations() -> void:
	_idle_frames_by_template = {}
	var templates: Dictionary = GameData.COMBAT_VISUALS.get("templates", {})
	for key in templates.keys():
		_idle_frames_by_template[key] = _load_animation_frames(key, "idle")


# combat-presentation ticket 10: the attack/hit/ko/selfPatch counterpart to
# _load_template_idle_animations() above -- same fully-manifest-driven loop,
# each sheet down-sampled to its doctrine keypose count (§4's table;
# selfPatch has no doctrine entry, so it's loaded at HIT_KEYPOSE_COUNT --
# StageSlot.play_self_patch() only ever reads keyposes[0] regardless).
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


# _load_animation_frames() (unrestricted frame count) plus the doctrine
# down-sample -- shared by every attack/hit/ko/selfPatch load site above, so
# a manifest sheet with more frames than the doctrine calls for (today, only
# templates.default's own leftover multi-frame dummy strips) still resolves
# to exactly `count` keyposes, evenly spaced across whatever the sheet has.
func _load_action_keyposes(template_key: String, key: String, count: int) -> Dictionary:
	var loaded := _load_animation_frames(template_key, key)
	return { "frames": _select_action_keyposes(loaded["frames"], count), "fps": loaded["fps"] }


# Evenly-spaced down-sample to exactly `count` textures (or fewer, if
# `frames` itself has fewer -- StageSlot's own play_*() functions already
# clamp/repeat when a keypose array is shorter than the doctrine calls for,
# same "degrade quietly" convention as everywhere else in this manifest
# pipeline). A `frames` array already at or below `count` passes through
# unchanged -- the identity case a real, doctrine-authored per-subject sheet
# (exactly 3/1/2 frames) always hits.
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


# Resolves one combatant's own attack/hit/ko keyposes+fps, falling back to
# the shared "default" stand-in (`default_frames`/`default_fps`) when its
# own per-subject manifest entry is empty -- see _default_attack_keyposes'
# own top comment for why attack/hit/ko get this fallback and idle doesn't.
# Passing `_empty_idle_frames`/0.0 as the default (selfPatch's call site)
# makes this degrade to "no fallback at all", since selfPatch has none.
func _resolve_action_keyposes(by_template: Dictionary, template_key: String, default_frames: Array[Texture2D], default_fps: float) -> Dictionary:
	var entry: Dictionary = by_template.get(template_key, {})
	var frames: Array[Texture2D] = entry.get("frames", _empty_idle_frames)
	if frames.is_empty():
		return { "frames": default_frames, "fps": default_fps }
	return { "frames": frames, "fps": entry.get("fps", 0.0) }


func _load_animation_frames(template_key: String, key: String) -> Dictionary:
	var entry: Dictionary = GameData.COMBAT_VISUALS.get("templates", {}).get(template_key, {}).get(key, {})
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
# any backdrop art exists. combat-presentation ticket 08 adds the actual
# per-context backdrop (_backdrop_texture/_backdrop_fill below) reading
# data/combat_visuals.json; until a real plate lands for a context it's the
# same flat dark fill this comment used to describe, now sourced from the
# manifest's fallbackColor instead of hardcoded here.
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
	frame_style.bg_color = STAGE_DEFAULT_FILL
	frame_style.border_width_left = STAGE_BORDER_WIDTH
	frame_style.border_width_top = STAGE_BORDER_WIDTH
	frame_style.border_width_right = STAGE_BORDER_WIDTH
	frame_style.border_width_bottom = STAGE_BORDER_WIDTH
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

	# combat-presentation ticket 05, §4.1: screen shake's own layer, sitting
	# between `frame` (a Panel -- outside any Container, so this is safe to
	# reposition) and the actual band content. Shaking `frame` itself would
	# fight _content's VBoxContainer, which re-asserts every direct child's
	# position on its own sort passes; a Panel's own children are never
	# repositioned by their parent, so a tween on _stage_shake_layer.position
	# sticks for the length of the shake instead of snapping back mid-tween.
	_stage_shake_layer = Control.new()
	_stage_shake_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_shake_layer.size = Vector2(STAGE_WIDTH, STAGE_HEIGHT)
	frame.add_child(_stage_shake_layer)

	# combat-presentation ticket 08: the backdrop sits behind both bands, and
	# inset by the frame's own border width so it never paints over the hard
	# 2px border §9 calls for. _sync_backdrop() (called from _sync_stage())
	# picks which of these two is visible; both exist from the start so
	# there's nothing to build/free per context switch.
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
	# STRETCH_KEEP_ASPECT_COVERED, not STRETCH_SCALE: a 390x360 native plate
	# (docs/ART-BIBLE.md §3) doesn't share backdrop_size's exact aspect ratio
	# (the stage is narrower than 390 -- see STAGE_WIDTH's own comment above),
	# so a plain non-uniform scale would squash it. Uniform scale-to-cover
	# crops the overflow instead (frame.clip_contents already clips it) --
	# never distorts a straight line in the art into a diagonal one.
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

	# combat-presentation ticket 10: player+allies left column, enemies right
	# -- see PLAYER_BAND_WIDTH/ENEMY_BAND_WIDTH's own comment for why this
	# departs from the vision doc's stacked-bands grammar.
	var player_entries := _player_display_entries(player, allies)
	_sync_band(_player_slots, _player_band_layer, player_entries, Vector2(PLAYER_BAND_WIDTH, STAGE_HEIGHT), Vector2.ZERO, "player")

	var enemy_entries := _enemy_display_entries(enemies, combat["focusedEnemyIndex"])
	_sync_band(_enemy_slots, _enemy_band_layer, enemy_entries, Vector2(ENEMY_BAND_WIDTH, STAGE_HEIGHT), Vector2(PLAYER_BAND_WIDTH + COLUMN_GAP, 0.0), "enemy")


# combat-presentation ticket 08, docs/combat-animation-vision.md §2.1/§6:
# reads data/combat_visuals.json (GameData.COMBAT_VISUALS) for this fight's
# context and shows either the real plate or the flat palette-colour
# fallback -- never both, and never neither. GameData.validate() already
# guarantees every Combat.CANONICAL_CONTEXTS context has an entry with an
# image or a fallbackColor, but an unrecognised context (defensive only --
# Combat.is_canonical_context() rejects these earlier) or a plate whose file
# went missing still resolves to the same dark fill _build_stage_skeleton()
# used before this ticket, rather than a missing-texture error or a blank
# stage.
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
			display.append({ "name": enemy["name"], "isFocused": i == focused_index, "index": i, "templateKey": enemy_template_key(enemy) })
			if display.size() >= Combat.SQUAD_MAX:
				break
	return display


# combat-presentation ticket 09, docs/combat-animation-vision.md §3: resolves
# an enemy state dict to its data/combat_visuals.json template key. Derived
# from data already on the enemy rather than a new state field (GameState
# stays a pure tree, and this is exactly what "name" already existed for --
# see _placeholder_color()'s own precedent for a name-keyed screen-side
# lookup): `isMugging` is the reliable signal for "mugger" (every concurrent
# Mugger instance shares it, regardless of how the intro-line names them --
# see Combat._spawn_mugger_instance()); otherwise the enemy's `name` is
# matched against GameData.ENEMY_RAID_GUARDS' own `name` fields (territorial
# Scrapper/Vein Guard/Orichalchum Dealer) and GameData.ENEMY_HOME_RAID_
# RAIDER's (The Raider) rather than hardcoding those names a second time
# here -- data/enemies.json stays the one place that spells them. No match
# (a test fixture's arbitrary name, or a future enemy template this lookup
# doesn't know about yet) resolves to "" -- _sync_band()'s idle lookup
# already treats an unresolved key as "no manifest entry", same quiet
# fallback to the shared default stand-in as any other gap.
#
# combat-presentation ticket 10: public and static (mirrors
# CombatDirector.beat_is_damaging()'s own "public so more than one file can
# share the exact same test" precedent) so scenes/components/
# turn_order_strip.gd's own telegraph-pose lookup resolves an enemy to the
# same template key this file uses, rather than duplicating the lookup.
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
	var display: Array = [{ "name": "You", "isFocused": false, "index": -1, "templateKey": "player" }]
	for i in range(allies.size()):
		if not allies[i]["koed"]:
			# combat-presentation ticket 09: an ally's own contactId (already
			# on the dict -- Contacts.build_combat_ally()) *is* its template
			# key, e.g. "archie" for data/constants.json's contacts.archie --
			# no separate name-matching table needed the way enemies need one.
			display.append({ "name": allies[i]["name"], "isFocused": false, "index": i, "templateKey": allies[i].get("contactId", "") })
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

	var rects := _fan_local_rects(band_size, display_entries.size())
	# combat-presentation ticket 09: how many display entries so far this
	# sync share a given template key -- e.g. a 2x/3x Mugger roster, all
	# resolving to "mugger" -- so the "reused sheet, mirrored/offset per fan
	# slot" acceptance check (no per-instance art) has something to alternate
	# on below. Fresh every _sync_band() call, in fan-position order (front,
	# then the two staggered-behind slots), not persisted across syncs.
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
		# combat-presentation ticket 09: every other concurrent instance of
		# the same template (occurrence 1, 3, ...) gets the extra mirror --
		# see StageSlot's own `_mirror_extra` comment for why.
		slot.set_mirror_extra(not template_key.is_empty() and occurrence % 2 == 1)
		# combat-presentation ticket 10 (human-flagged follow-up): idle now
		# gets the exact same per-subject-with-default-fallback treatment as
		# attack/hit/ko below, reusing _resolve_action_keyposes() -- the
		# fallback source is templates.default's own idle entry (already
		# loaded into _idle_frames_by_template["default"] by
		# _load_template_idle_animations(), no separate loading needed).
		# templates.default.idle is the same Gangsters_2-sourced art already
		# shared by attack/hit/ko (assets/combat/dummy/*.png -- see that
		# commit's own history), so this is "use Gangsters_2 as the shared
		# placeholder for every type," not a new asset. The ticket-01
		# placeholder box (StageSlot._draw()) is now unreachable in normal
		# play (every combatant gets a sprite, real or shared stand-in) --
		# left in place as a defensive fallback for the one remaining gap
		# (templates.default.idle itself missing/broken), same "degrade
		# quietly, never error" convention as everywhere else in this file,
		# rather than deleted as dead code.
		var default_idle: Dictionary = _idle_frames_by_template.get("default", {})
		# _empty_idle_frames (a real typed Array[Texture2D], not a `[]`
		# literal) as the .get() default -- an untyped `[]` literal here
		# fails a runtime "Array to Array[Texture2D]" type check on assignment
		# for any templateKey with no manifest entry (every test-fixture enemy
		# name, and every real subject before its art lands), which a `[]`
		# default doesn't trip since it's only ever reached via a dict that
		# came out of _load_animation_frames (always genuinely typed there).
		var idle := _resolve_action_keyposes(_idle_frames_by_template, template_key, default_idle.get("frames", _empty_idle_frames), default_idle.get("fps", 0.0))
		slot.set_idle_animation(idle["frames"], idle["fps"])
		# combat-presentation ticket 10: attack/hit/ko prefer this combatant's
		# own per-subject keyposes, falling back to the shared "default"
		# stand-in when its own entry is empty -- see _resolve_action_keyposes()
		# and the _default_*_keyposes vars' own comments. selfPatch has no
		# "default" fallback (Archie-only, per that dict's own top comment) --
		# _empty_idle_frames/0.0 as its "default" makes
		# _resolve_action_keyposes() degrade to "no fallback at all". Looped
		# (rather than four repeated resolve+set pairs) since all four share
		# the exact same shape -- only which dictionary/default/setter
		# differs.
		for action in [
			[_attack_keyposes_by_template, _default_attack_keyposes, _default_attack_fps, slot.set_attack_animation],
			[_hit_keyposes_by_template, _default_hit_keyposes, _default_hit_fps, slot.set_hit_animation],
			[_ko_keyposes_by_template, _default_ko_keyposes, _default_ko_fps, slot.set_ko_animation],
			[_self_patch_keyposes_by_template, _empty_idle_frames, 0.0, slot.set_self_patch_animation],
		]:
			var resolved: Dictionary = _resolve_action_keyposes(action[0], template_key, action[1], action[2])
			var setter: Callable = action[3]
			setter.call(resolved["frames"], resolved["fps"])

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
	var front_x := clampf((band_size.x - front_size.x) / 2.0, 0.0, maxf(0.0, band_size.x - front_size.x))
	var front_pos := Vector2(front_x, band_size.y - front_size.y - band_size.y * FAN_FRONT_BOTTOM_MARGIN)
	rects.append(Rect2(front_pos, front_size))

	# Clamped to the column's own width -- the tuck fractions above were
	# tuned for the old wide-short bands; against the narrower left/right
	# columns (combat-presentation ticket 10) an untucked position could
	# otherwise land outside this column entirely, overlapping the
	# neighbouring one.
	var max_x: float = maxf(0.0, band_size.x - back_size.x)
	if count >= 2:
		var back_left_pos := Vector2(clampf(front_pos.x - back_size.x * FAN_BACK_LEFT_TUCK, 0.0, max_x), band_size.y * FAN_BACK_LEFT_TOP_MARGIN)
		rects.append(Rect2(back_left_pos, back_size))

	if count >= 3:
		var back_right_pos := Vector2(clampf(front_pos.x + front_size.x - back_size.x * FAN_BACK_RIGHT_TUCK, 0.0, max_x), band_size.y * FAN_BACK_RIGHT_TOP_MARGIN)
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
	var combat: Dictionary = GameState.state["combat"]
	# combat-presentation ticket 10: snapshot BEFORE action.call() -- see
	# _frozen_roster's own top comment for why this has to happen before the
	# round resolves, not after.
	_frozen_roster = { "enemies": combat["enemies"].duplicate(true), "allies": combat["allies"].duplicate(true) }
	var log_before: int = combat["log"].size()
	var result: Dictionary = action.call()
	await _play_beats(result.get("beats", []), log_before)


# combat-presentation ticket 05: split out of _play_round() so
# _on_dial_triggered() below (a Complication cast, not a full "round" in
# Combat.build_turn_queue()'s sense) can drive the same director/log-reveal/
# juice-tracker plumbing -- Combat.cast_complication() already ran
# synchronously by the time that callback fires (see dial_widget.gd's own
# handle_trigger() comment), so there's no `action` left to call here.
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


func _on_beat_played(beat: Dictionary) -> void:
	_revealed_log_count += 1
	_sync_footer(GameState.state["combat"], GameState.state["player"])
	var kind: String = beat.get("kind", "")
	# combat-presentation ticket 10, docs/combat-animation-vision.md §5:
	# prophetsBreath's ghost-next-pose effect -- fires before play_attack()
	# below for the same beat, on a BEAT_PLAYER_EVADE specifically (the one
	# beat kind that means "an enemy's swing whiffed because of the
	# evadeTurns/evadeChance grant prophetsBreath and Rewind share" -- see
	# systems/combat.gd's own use_prophets_breath() comment). See
	# StageSlot.ghost_next_pose()'s own comment for why this isn't sequenced
	# to finish before play_attack() starts.
	if kind == Combat.BEAT_PLAYER_EVADE:
		var evading_slot: StageSlot = _resolve_target_slot(_beat_actor(beat))
		if evading_slot != null:
			evading_slot.ghost_next_pose()
	# An actual swing, hit or missed -- plays before the juice layer's own
	# damage check below, so a miss still gets its attack pose even though
	# _play_juice() never runs for it.
	if _ATTACK_BEAT_KINDS.has(kind):
		var actor_slot: StageSlot = _resolve_target_slot(_beat_actor(beat))
		if actor_slot != null:
			actor_slot.play_attack()
	# combat-presentation ticket 10, §3: Archie's self-patch pose -- any ally
	# healing themselves below 40% HP (systems/combat.gd's _ally_turn()),
	# not just Archie specifically (the manifest lookup is per ally
	# contactId, same as idle -- see _self_patch_keyposes_by_template's own
	# comment for why only Archie's entry is non-empty today).
	if kind == Combat.BEAT_ALLY_HEAL:
		var healer_slot: StageSlot = _resolve_target_slot(_beat_actor(beat))
		if healer_slot != null:
			healer_slot.play_self_patch()
	if CombatDirector.beat_is_damaging(beat):
		_play_juice(beat)


func _build_dial_widget(dial: Dictionary) -> Control:
	var widget := DialWidget.new()
	widget.custom_minimum_size = Vector2(DIAL_WIDTH, 0)
	widget.configure(dial, _dial_selected_index, _on_dial_selection_changed, _on_dial_triggered)
	return widget


# DialWidget.handle_rotate() only reports through this callback, never
# mutates its own selection (see that file's own top comment) -- nothing in
# GameState changed, so nothing would otherwise trigger a rebuild; _sync()
# is called directly, same as _on_strip_selection_changed()'s non-enemy case.
func _on_dial_selection_changed(new_index: int) -> void:
	_dial_selected_index = new_index
	_sync()


# combat-presentation ticket 05: DialWidget.handle_trigger() already called
# Combat.cast_complication() synchronously and mutated GameState before this
# ever fires (see that file's own handle_trigger() comment) -- this only
# paces `result`'s beats back onto the screen, same _play_beats() plumbing
# _on_attack_pressed()/_on_run_pressed() drive via _play_round(). log_before
# is reconstructed rather than captured ahead of the cast (there's nothing
# to capture it before -- the cast already happened by the time this
# callback exists) by subtracting beats.size(): cast_complication() logs
# exactly one combat.log line per beat (via _log()), the same 1:1 invariant
# player_attack()/enemy_attack()/flee()'s own beats already hold.
func _on_dial_triggered(result: Dictionary) -> void:
	var beats: Array = result.get("beats", [])
	var log_before: int = GameState.state["combat"]["log"].size() - beats.size()
	await _play_beats(beats, log_before)


# ── combat-presentation ticket 05, docs/combat-animation-vision.md §4.1 ──
# The juice layer. Every effect below is keyed off a beat's own `dmg`/
# `targetType`/`targetIndex` fields (CombatDirector.beat_is_damaging()'s
# test, shared with the hit-stop it adds to the timeline itself) -- no beat
# `kind` is special-cased, so Blast/Black Hole's own beats (ticket 05's
# cast_complication() wiring, above) get exactly the same treatment as a
# plain attack beat, and any future damaging beat kind gets it for free.
#
# Gap fixed by combat-presentation ticket 10 for the ordinary round path:
# the round's final state (including any KO) is already applied and
# _sync()'d before playback starts (see combat_director.gd's own top
# comment) -- so, undefended, stage slots/strip cards for whoever this round
# kills would already be gone by the time their killing beat plays, and its
# own flash/damage-number/ghost-drain/play_ko() would silently no-op
# (their node lookups return null). _frozen_roster (this screen's own top
# comment) keeps a dying combatant's StageSlot alive through the round for
# _play_round()'s path. It does NOT cover _on_dial_triggered() (Complication
# casts) -- Combat.cast_complication() has already mutated GameState before
# that callback ever runs, with nothing left to snapshot from; a kill via
# Blast/Black Hole still hits this original gap. Hit-stop and screen shake,
# needing no per-combatant node, play normally in both cases regardless.


# Normalizes a beat's own targetType/targetIndex fields into the same
# {"type": ..., "index": ...} shape TurnOrderStrip's own entry_key/
# card_key_string() already use (index -1 for the player) -- one shared
# format instead of every juice-layer helper below re-deriving its own pair
# of (target_type, target_index) primitives from the raw beat.
func _beat_target(beat: Dictionary) -> Dictionary:
	var target_type: String = beat.get("targetType", "")
	var target_index: int = -1 if target_type == "player" else int(beat.get("targetIndex", -1))
	return { "type": target_type, "index": target_index }


# Same shape as _beat_target(), but for a beat's actorType/actorIndex --
# who threw the swing (or healed themselves) this beat represents, not who
# it landed on. Used by _on_beat_played()'s ghost/attack-pose/self-patch
# triggers; the juice layer proper (flash/damage-number/shake/ghost-drain/
# hit/ko) only ever cares about the target.
func _beat_actor(beat: Dictionary) -> Dictionary:
	var actor_type: String = beat.get("actorType", "")
	var actor_index: int = -1 if actor_type == "player" else int(beat.get("actorIndex", -1))
	return { "type": actor_type, "index": actor_index }


# combat-presentation ticket 10: beat kinds that represent an actual swing
# (hit or missed) rather than a heal, status tick, or Complication cast --
# these get the attacker's Swipe pose regardless of whether the swing
# landed (BEAT_ENEMY_EVADE/BEAT_PLAYER_EVADE are misses, not no-ops).
const _ATTACK_BEAT_KINDS: Array[String] = [
	Combat.BEAT_PLAYER_ATTACK, Combat.BEAT_ALLY_ATTACK, Combat.BEAT_ENEMY_ATTACK,
	Combat.BEAT_ENEMY_EVADE, Combat.BEAT_PLAYER_EVADE,
]


# The player/ally/enemy Dictionary a target's own hp/hpMax actually live on
# -- shared by _hp_for()/_hp_max_for() below so the player/ally/enemy
# lookup exists exactly once, not once per field.
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


# Seeds _ghost_tracker (and every affected card's ghost bar) to this round's
# pre-hit hp, reconstructed as "final hp (already live in GameState) + total
# damage this round's beats deal to that target" -- the only reconstruction
# available, since nothing snapshots a genuine pre-round hp for the screen to
# read (see this section's own top comment). Called once, before playback
# starts.
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


# The single entry point _on_beat_played() calls for every damaging beat.
func _play_juice(beat: Dictionary) -> void:
	var target: Dictionary = _beat_target(beat)
	var dmg: int = int(beat["dmg"])

	var slot: StageSlot = _resolve_target_slot(target)
	if slot != null:
		slot.flash_hit()
		_spawn_damage_number(slot, dmg)
		# combat-presentation ticket 10: koed (this hit's own final GameState
		# is already applied -- see _frozen_roster's own comment) holds on the
		# fallen/faded KO pose; otherwise a recoil pose. _frozen_roster is
		# what keeps `slot` from having already been freed for a killing blow
		# (on the ordinary round path -- see _beat_actor()'s own comment for
		# the Dial-cast exception).
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


# exit_combat() already navigates for every case except mugging-win
# (which deliberately stays put so the sale_result modal stays visible).
func _on_continue_pressed() -> void:
	Combat.exit_combat()
