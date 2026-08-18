# 27 — Centered ore-type glyph missing on faction and unclaimed map stops

**What to build:** Every stop on the Network Map should show its vein/ore type as a centered glyph, regardless of owner. Player stops already do this correctly (`_draw_vein_stop` in `scenes/components/map_canvas.gd` draws the circle plus a centered `_draw_ore_symbol`). Faction stops (`_draw_faction_stop`) draw only the paper+ring circle with no ore glyph at all (explicitly deferred in a code comment). Unclaimed stops (`_draw_unclaimed_stop`) draw a tick-mark plus an ore glyph offset to the side, not centered in a circle. Note: unclaimed-veins-render-unconnected and claiming-connects-the-line are already implemented correctly (`_partition_stops()`/`MapEvents.queue_join_line`) — this ticket is scoped to the glyph-centering gap only.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `_draw_faction_stop` gets a centered `_draw_ore_symbol` call matching the player-stop treatment.
- [ ] Unclaimed stops render with a centered ore glyph. Decide (flag for human sign-off if ambiguous) whether unclaimed sites keep their tick-mark shape with a centered glyph, or become a circular "stop" matching claimed veins — the bug report's "all stops...circle" framing suggests the latter, but tick-marks currently signal "unconnected to a line" visually.
- [ ] `map_canvas` tests updated/added asserting an ore glyph is drawn (and centered) for player, faction, and unclaimed stops alike.
