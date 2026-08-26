class_name Nav
extends RefCounted

# Screen navigation. currentScreen is part of GameState.state (R§2), so
# even switching screens goes through a system function rather than a
# screen mutating state directly.


# 81-map-stuck-playback-flag: every navigation away from "map" can be firing
# mid-tween on a still-queued MapEvents animation (e.g. DistrictDeck.
# maybe_trigger() calling Events.start_event() -> go_to("event") as the very
# last step of a district bubble's Prospect/Seed action, synchronously right
# after that same action queued the animation this call is about to abandon
# — see MapEvents.abandon_playback()'s own doc comment for why leaving
# "playing" stuck true here permanently locks out every later tap). Main.gd's
# _show_screen() defers the outgoing MapCanvas's actual teardown (queue_free),
# so its own _exit_tree() -> abandon_playback() call still fires and would
# eventually clear this too — but relying on that alone means the guard stays
# stuck true for the rest of THIS frame, during which the exact same
# synchronous call chain can go on to read is_playing()/has_pending() (e.g. a
# second queued action) and see stale state. Clearing it here, synchronously,
# removes that gap. Deliberately called AFTER both emits below, not before:
# MapCanvas's own state_changed listener (_maybe_start_playback) is still
# connected to the outgoing screen at this point, and calling abandon_playback()
# first (queue popped, playing false, pending events still behind it) would let
# that listener's begin_playback() re-claim the drain and start a brand new
# _play_queue() coroutine on a canvas that's already mid-teardown — abandoning
# after the emits leaves "playing" true (so that listener's begin_playback()
# still declines) for the whole rest of this call, matching exactly what
# _exit_tree() itself pops when it fires moments later.
static func go_to(screen_id: String) -> void:
	GameState.state["currentScreen"] = screen_id
	EventBus.screen_changed.emit(screen_id)
	EventBus.state_changed.emit()
	MapEvents.abandon_playback()
