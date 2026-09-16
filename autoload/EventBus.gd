extends Node

# Central signal bus. Systems emit; screens connect and redraw from
# GameState.state. Never carries object references — only primitives/ids,
# consistent with state purity.

signal state_changed
signal shared_stock_increased
signal screen_changed(screen: String)
signal day_ticked(day: int)
# Presentation-only capture; listeners must wait for the action outcome.
signal time_advanced(source: Dictionary, destination: Dictionary)
signal notification_pushed

# Fires once per newly-detected batch of actionable alarm situations, giving
# a visible cue independent of whether the alarm surface can auto-open yet.
signal alarm_arrived

# Carries a completed action's `beats` Array for CombatScreen to play back.
# Needed because the bag-item consumable path (global BagDrawer overlay) has
# no other channel back to whichever CombatScreen instance is on screen.
signal combat_beats_played(beats: Array)

# combat_rewind()'s reversed beats, per docs/combat-animation-vision.md §5.
# Kept separate from combat_beats_played since reverse playback needs
# different director plumbing on the screen side.
signal combat_rewind_played(beats: Array)
