# 07 — Time Pearl freeze: pause icon with count + strip cards marked

**What to build:** Players can see who is paused and for how long:

- **Pause icon:** a pixel-art ⏸ above a frozen fighter's head with a small count of frozen actions left (e.g. ⏸2). It ticks down as each `frozen` beat plays and disappears at 0. Positioned above the guard marker / status badges, which stay where they are.
- **Turn-order strip:** a frozen fighter's upcoming action cards that will be lost show ⏸ in place of their action text, dimmed. When that card's `frozen` beat plays, its ⏸ flickers once as the card is passed.
- The stage/strip snapshot exposes the frozen-actions-left count per fighter (today it only exposes a bool), so screens read it rather than compute it.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/combat_rounds.gd` (stage snapshot ~l.2103–2108 `frozen`; `frozen` beat ~l.1803–1805; `frozenActions` set by Time Pearl ~l.2348–2352; plan/fog for which upcoming actions are lost)
- `scenes/components/combat_stage.gd` (overlay drawing: status badges ~l.560–572, guard marker)
- `scenes/components/turn_order_strip.gd` (actionText/statusBadge lines)
- `scenes/screens/combat_rounds.gd` (strip entry building, beat playback)
- New pause-icon pixel asset (match existing combat badge/icon art scale)
- `tests/test_combat_rounds.gd` (or nearest existing combat test)
- REFERENCE.md §3.7b (Removal)
- `CODEMAP.md` rows for touched files

**Status:** ready-for-agent

- [ ] Snapshot exposes frozen actions left per fighter; test covers count and decrement per `frozen` beat
- [ ] Test: exactly the frozen fighter's lost upcoming actions are marked for the strip
- [ ] ⏸N icon above head, counts down, gone at 0, doesn't overlap guard/status markers
- [ ] Lost strip cards show ⏸ dimmed; flicker on their `frozen` beat
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: icon legible at phone size, count ticks correctly, strip marking clear
