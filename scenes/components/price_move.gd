class_name PriceMove
extends RefCounted

# ▲/▼ versus yesterday's London price (Market.day_move) for price rows in
# the Ticker's Stock Market tab and every sell lane. Presentation only.

const UP_ID := "pastel_teal"
const DOWN_ID := "pastel_pink"


# "▲", "▼" or "" when flat; with_delta appends the £ move ("▲ +3").
static func text(move: int, with_delta: bool = false) -> String:
	if move == 0:
		return "–" if with_delta else ""
	var arrow := "▲" if move > 0 else "▼"
	if not with_delta:
		return arrow
	return "%s %s£%d" % [arrow, "+" if move > 0 else "−", absi(move)]


static func colour(move: int, flat: Color) -> Color:
	if move == 0:
		return flat
	return GameData.PALETTE.get(UP_ID if move > 0 else DOWN_ID, flat)
