# 12 — Prologue timing log

**What to build:** A debug-only log of how long each Prologue step takes in real play, so the owner can playtest the new Prologue and decide what to cut. It records start/end (real seconds plus in-game day/block) for each event and each fight, and is viewable and exportable from the debug tools. Source: `docs/story-restructure.md` Prologue ("Draft the whole Prologue, playtest it with per-step timings, then cut"), "Features to build" item 6.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (event start/end), `systems/combat.gd` (open/exit), `scenes/screens/debug_tools.gd`, `autoload/` (where real-time timestamps can live outside `GameState.state`).

**Status:** ready-for-agent

- [ ] Real-time timestamps are kept outside the pure state tree, so save/Rewind purity holds. Off in release builds.
- [ ] Each entry: id, kind (event/fight), real start/end, duration, in-game day/block.
- [ ] Debug tools list the entries with per-entry and total durations, and export them to a text/CSV file under `user://`.
- [ ] Tests cover entry creation on event start/end and fight open/exit.
