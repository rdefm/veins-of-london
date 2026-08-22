# 50 — Map: fix animation replay bug + rename/persist pacing modes

**What to build:** Two related fixes to the map's event-animation playback (`systems/map_events.gd`, `scenes/components/map_canvas.gd`):

1. **Replay bug.** Animation is a one-shot queue (`GameState.state["mapEvents"]["queue"]`/`["playing"]`, `map_events.gd:181-217`), not a per-vein seen-flag — an event only replays if it never finished animating (e.g. the map screen was closed mid-tween). `abandon_playback()` (`map_events.gd:215-217`) only clears the `"playing"` flag on teardown, leaving the queue itself intact, so the interrupted event replays next visit. Human confirmed this matches their repro ("only sometimes / inconsistent"). Fix: on abandon/teardown, either mark the in-flight event as consumed (pop it from the queue even if its animation didn't finish) or otherwise ensure an interrupted animation doesn't replay from the start next open.
2. **Pacing rename.** `PACING_MODES := ["deliberate", "quick"]` (`map_canvas.gd:166-168`, `QUICK_DURATION := 0.35`, `DELIBERATE_DURATION := 1.5`) currently both play the queue sequentially (one vein at a time), only duration differs. Per the human: rename `quick` → `sequential` (unchanged behavior — fast, one-by-one), and change `deliberate` → `simultaneous` (all queued vein animations play concurrently instead of one-by-one, at the slower 1.5s duration). Also persist the chosen mode: currently `pacing_mode` is a `MapCanvas`-local instance var, explicitly "never written to GameState" (`map_canvas.gd:678-680` comment) and resets every time the Map screen is recreated. Move it into `GameState.state` so it survives close/reopen and save/load.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Interrupted/abandoned animations no longer replay on next map open.
- [ ] `PACING_MODES` renamed `sequential`/`simultaneous`; `simultaneous` plays all queued vein animations concurrently rather than one-by-one, still at the slower (1.5s) duration.
- [ ] Chosen pacing mode persisted in `GameState.state` (not just a `MapCanvas` instance var), read back on map screen creation.
- [ ] `docs/M1.5-NETWORK-MAP.md` animation section updated with the renamed modes and the new persisted state field.
- [ ] Tests updated for the renamed pacing modes and for queue-consumption-on-abandon; new test confirming persisted pacing survives a save/load round-trip.
- [ ] Manual check noted for the human: close the map mid-animation and reopen — confirm no replay; toggle pacing mode, reopen the map (and reload a save) — confirm it stuck.
