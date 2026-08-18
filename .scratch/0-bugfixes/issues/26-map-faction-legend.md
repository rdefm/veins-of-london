# 26 — Persistent faction legend on Network Map (tube-map style, top-left)

**What to build:** Add a small always-visible faction-colour key to the Network Map, styled like a London Underground line-key, positioned top-left (currently empty space where the map opens). This is distinct from the existing glyph-semantics legend (`map_controls.gd`'s "? Legend" → `Modal.open("network_reference")`), which explains dot/ring/badge meanings, not which colour belongs to which faction. Reuse `GameData.FACTIONS[id]["colour"]` (already used for line colours in `map_canvas.gd::_draw_lines()` and the faction-filter picker in `map_controls.gd::_build_faction_rows()`) as the source of truth for name/colour pairs.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A persistent (non-modal) legend widget renders in the top-left of the Map screen, listing each faction's name with a colour swatch matching its line colour.
- [ ] Styled to read as a tube-map line key (compact swatches + labels), consistent with the map's existing tube-map visual language.
- [ ] Doesn't obstruct map interaction (pan/zoom/tap) or the existing top bar/hamburger controls; collapsible or dismissible if it would otherwise crowd small screens (human's call on exact behavior if ambiguous).
- [ ] `map`/`map_controls` tests updated to cover the new legend's presence and faction list.
