extends Node


const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")
const TimeTransitionScript := preload("res://scenes/components/time_transition.gd")
const HapticsAdapter := preload("res://scenes/components/haptics.gd")

var time_transition: Control = null

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
