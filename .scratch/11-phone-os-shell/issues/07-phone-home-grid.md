# 07 — Phone home grid

**What to build:** The phone app grid itself — the game's new home screen — showing every app (existing and placeholder) as a tile, using the tile component from ticket 02, with real badge wiring and locked/padlock treatment.

**Blocked by:** 02 (icon asset contract + tile component)

**Status:** ready-for-agent

- [ ] App registry data structure holds every app's id, label, icon reference, and lock predicate — roster-agnostic (final app list is a separate future ticket)
- [ ] Every app, locked or unlocked, occupies a fixed slot in the grid — no reflow when unlocked
- [ ] Locked apps render greyed with the padlock overlay from ticket 02, not hidden and not replaced with hint text
- [ ] Badge dots wire to the existing pending-messages and ticker-rumblings predicates
- [ ] Existing apps (Messages, Notes, Factions, Ticker) are reachable as grid tiles and behave exactly as they do today once opened, including Ticker's axis drill-down
- [ ] Grid is reachable as the game's home (this ticket does not yet reroute every call site to it — that's ticket 12 — but the screen itself exists and is navigable to)
- [ ] Tests cover: locked vs. unlocked tile rendering, badge wiring against both predicates, fixed slot positions across a lock-state change
