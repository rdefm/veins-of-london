class_name Nav
extends RefCounted

# Screen navigation. currentScreen is part of GameState.state (R§2), so
# even switching screens goes through a system function rather than a
# screen mutating state directly. An open lesson (LessonSession) holds the
# player at the bench: only it and the title screen are reachable.

const LESSON_SCREENS: Array[String] = ["hq_lab_bench", "title"]


static func go_to(screen_id: String) -> void:
	if LessonSession.is_open() and not LESSON_SCREENS.has(screen_id):
		return
	GameState.state["currentScreen"] = screen_id
	EventBus.screen_changed.emit(screen_id)
	EventBus.state_changed.emit()
	# Called after both emits, not before: navigating away can abandon a
	# still-queued MapEvents animation; clearing it before the emits would let
	# the outgoing MapCanvas's still-connected listener re-claim the queue.
	MapEvents.abandon_playback()
