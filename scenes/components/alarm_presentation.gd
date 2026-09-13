extends Node

# day-rhythm ticket 05: ephemeral presentation only, same "not one line of
# this enters a save" discipline as time_transition.gd's own queue. Detects
# newly-actionable raid-alarm situations (systems/raid_alarms.gd's stable
# summary-row ids -- the sole source of truth; nothing here duplicates
# resolution state) and reacts in two independent ways:
#
#   1. Immediately: a visible Phone-tab pulse (EventBus.alarm_arrived,
#      picked up by nav_bar.gd) and, if the player hasn't disabled it, an
#      actual device buzz (haptics_hook, defaulting to Haptics.buzz).
#      Neither is gated by "safe to open" -- a real phone buzzing in your
#      pocket doesn't wait for you to finish what you're doing either.
#   2. Once safe: auto-opens the grouped alarm surface (Nav "phone" +
#      RaidAlarms.open()) -- but never for a rollover-sourced arrival. At
#      rollover, MorningAccounts.open_after_transition() already claims the
#      single auto-open slot for BizBrief's Morning Brief, whose Attention
#      block surfaces the same newly-actionable alarms (spec: "do not stack
#      a second alarm surface behind or after the brief"). Today every
#      alarm-creating trigger (Home.roll_daily_raid/Raiding.
#      apply_raid_resolution) only ever runs inside TimeSystem.daily_tick(),
#      so _on_day_ticked() below always cancels it for a rollover arrival;
#      the direct-open path only actually completes for a future mid-day
#      alarm source per the spec's general contract, exercised today only
#      by synthetic tests.
#
# A new alarm always tentatively arms the direct auto-open first (see
# _check_for_new_alarms() below) -- it is NOT decided at detection time
# whether this is a rollover arrival. Home.roll_daily_raid() (daily_tick()'s
# step ②) already calls Notify.push() -> EventBus.state_changed well before
# MorningAccounts.finish_rollover() (the tick's last step) ever stamps
# today's account, so any check made inside _check_for_new_alarms() itself
# would always see stale morningAccounts data -- there is no shape of
# "is this a rollover" state that's both correct and available that early.
# EventBus.day_ticked fires exactly once, synchronously, at the true end of
# daily_tick() -- after every alarm-creating step AND finish_rollover() have
# both already run -- so _on_day_ticked() below cancels the tentative
# auto-open there instead, unconditionally: today's only alarm sources both
# run inside that same daily_tick(), so any auto-open still armed when its
# own day_ticked fires is rollover-sourced by construction.
#
# known_ids is reset to the CURRENT set (not cleared) whenever GameState.
# state is replaced (load/reset/Rewind, detected the same `is_same(session,
# GameState.state)` way time_transition.gd's own _sync_session() does) --
# so a save with unresolved alarms never reads as "newly arrived" on
# reload, without persisting any presentation bookkeeping into the save
# itself.

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")
const TimeTransitionScript := preload("res://scenes/components/time_transition.gd")
const HapticsAdapter := preload("res://scenes/components/haptics.gd")

# Wired by Main.gd to the live TimeTransition overlay so this never opens
# the alarm surface underneath, before, or immediately after that overlay
# plays. Left null in off-tree unit tests that don't need that interaction.
var time_transition: Control = null

# Injectable so tests can spy on whether a buzz was actually requested
# without depending on real hardware/platform -- same "pass the effect in"
# seam PhoneApps.build_tile_configs() uses for badge_for.
var haptics_hook: Callable = HapticsAdapter.buzz

var session: Dictionary = {}
var known_ids: Dictionary = {}
var pending_open := false
var safe_elapsed := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	session = GameState.state
	known_ids = _current_ids()
	EventBus.state_changed.connect(_check_for_new_alarms)
	EventBus.day_ticked.connect(_on_day_ticked)


func _sync_session() -> void:
	if is_same(session, GameState.state):
		return
	session = GameState.state
	known_ids = _current_ids()
	pending_open = false
	safe_elapsed = 0.0


func _current_ids() -> Dictionary:
	var ids := {}
	for row in RaidAlarmsSystem.summary_rows():
		ids[row["id"]] = true
	return ids


func _check_for_new_alarms() -> void:
	_sync_session()
	var current_ids := _current_ids()
	var has_new := false
	for id in current_ids:
		if not known_ids.has(id):
			has_new = true
			break
	known_ids = current_ids
	if not has_new:
		return

	if GameState.state["meta"].get("vibrationEnabled", true):
		haptics_hook.call()
	EventBus.alarm_arrived.emit()
	pending_open = true
	safe_elapsed = 0.0


# See the file-level comment: a rollover's own day_ticked always fires
# after every alarm this same tick created, so any auto-open still armed
# right now was armed by this tick -- cancel it unconditionally in favour
# of BizBrief's own open_after_transition() auto-open.
func _on_day_ticked(_day: int) -> void:
	pending_open = false
	safe_elapsed = 0.0


func _process(delta: float) -> void:
	_sync_session()
	if not pending_open:
		return
	if not _safe_to_open():
		safe_elapsed = 0.0
		return
	safe_elapsed += minf(delta, 0.1)
	if safe_elapsed < float(GameData.DAILY_CYCLE["outcomeHoldSeconds"]):
		return
	pending_open = false
	safe_elapsed = 0.0
	Nav.go_to("phone")
	RaidAlarmsSystem.open()


func _safe_to_open() -> bool:
	if time_transition != null and (time_transition.active or not time_transition.pending.is_empty()):
		return false
	return TimeTransitionScript.outcome_finished()
