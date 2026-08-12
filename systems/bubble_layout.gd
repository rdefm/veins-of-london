class_name BubbleLayout
extends RefCounted

# Pure positioning math for MapBubble (scenes/components/map_bubble.gd) --
# factored out for the same reason as map_zoom.gd/map_hit_test.gd: unit-
# testable without a scene tree. popup_position() is the only entry point;
# MapBubble._apply_position() is the sole caller.

# Screen px gap kept between the popup panel and every edge of `bounds_size`
# -- a clamped popup still shouldn't sit flush against the screen edge.
const EDGE_MARGIN := 8.0

# Default offset from the anchor point to the popup's own top-left corner:
# down and to the right, so the popup doesn't render directly on top of
# whatever was tapped -- the ticket's "near that point without obscuring"
# requirement.
const DEFAULT_OFFSET := Vector2(12.0, 12.0)


# Clamps a `popup_size` popup, nominally placed at `anchor + offset`, so it
# always stays fully inside `bounds_size` (with EDGE_MARGIN of breathing room
# on every side) -- never partially off-screen, regardless of how close
# `anchor` sits to an edge or corner. If `popup_size` alone is too big to fit
# with margin on both sides (a degenerate case no real option list should
# hit), the lower clamp bound wins via the .max() below, so the popup pins to
# the margin instead of the clamp range inverting.
static func popup_position(anchor: Vector2, popup_size: Vector2, bounds_size: Vector2, offset: Vector2 = DEFAULT_OFFSET) -> Vector2:
	var raw := anchor + offset
	var min_pos := Vector2(EDGE_MARGIN, EDGE_MARGIN)
	var max_pos := (bounds_size - popup_size - min_pos).max(min_pos)
	return raw.clamp(min_pos, max_pos)
