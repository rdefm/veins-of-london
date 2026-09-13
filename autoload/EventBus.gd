extends Node

# Central signal bus. Systems emit; screens connect and redraw from
# GameState.state. Never carries object references — only primitives/ids,
# consistent with state purity.

signal state_changed
signal screen_changed(screen: String)
signal day_ticked(day: int)
# Presentation-only capture; listeners must wait for the action outcome.
signal time_advanced(source: Dictionary, destination: Dictionary)
signal notification_pushed

# day-rhythm ticket 05: fires once per newly-detected batch of actionable
# alarm situations (scenes/components/alarm_presentation.gd), independent
# of whether the grouped alarm surface is allowed to auto-open yet --
# purely "give the player a visible/physical cue now." Carries no payload;
# listeners (nav_bar.gd's Phone-tab pulse) re-read state themselves if they
# need details.
signal alarm_arrived

# combat-presentation ticket 11: carries a completed action's `beats` Array
# (pure data -- ids/kinds/numbers, same shape player_attack()/flee()/
# cast_complication() already return directly to their caller) for
# CombatScreen to play back through CombatDirector. Needed specifically
# because the direct bag-item consumable path (Combat.use_*()/
# Consumables.use_healing_burst(), called from scenes/components/
# bag_drawer.gd) has no other channel back to whichever CombatScreen
# instance is on screen -- BagDrawer is a global overlay (scenes/Main.gd),
# not a child of CombatScreen, so it can't hand the return value back
# directly the way _on_attack_pressed()/_on_run_pressed() do.
signal combat_beats_played(beats: Array)

# combat-presentation ticket 11, docs/combat-animation-vision.md §5:
# "rewind/failsafe ... the beat queue in reverse" -- combat_rewind()'s own
# beats (already reversed) for CombatScreen's dedicated reverse-playback
# path. Kept separate from combat_beats_played rather than a shared
# "reversed: bool" flag on one signal, since the two need different
# director plumbing on the screen side (see combat.gd's _play_rewind_beats()).
signal combat_rewind_played(beats: Array)
