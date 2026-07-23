extends Node

# Central signal bus. Systems emit; screens connect and redraw from
# GameState.state. Never carries object references — only primitives/ids,
# consistent with state purity.

signal state_changed
signal screen_changed(screen: String)
signal day_ticked(day: int)
signal notification_pushed
