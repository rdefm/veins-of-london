# 04 — Beat queue director + persistent combatant nodes

**What to build:** The architecture prerequisite §8 calls the load-bearing
blocker for everything animated. Two problems today:

- `Combat.player_attack()` (`systems/combat.gd:533`) resolves the whole
  round synchronously — the turn queue built by `build_turn_queue()` is
  walked in a single function call, appending every log line and emitting
  one `state_changed` at the end. There is no per-beat timeline to animate
  against.
- `CombatScreen._refresh()` (`scenes/screens/combat.gd:14`) `queue_free()`s
  every child on each `state_changed`. No sprite, tween, or animation player
  can survive that.

The fix, respecting the constitution's one-way data flow (systems never
touch Nodes):

1. `Combat.player_attack()` and the other turn-resolving functions return an
   **ordered `beats` array** alongside the log lines — pure data, e.g.
   `{kind: "player_attack", dmg: 7, targetType: "enemy", targetIndex: 0}`,
   `{kind: "enemy_evade", ...}`, `{kind: "ally_heal", amount: 12, ...}`. No
   `SpriteFrames`, Node, or Callable ever enters `GameState.state` — ids
   only. `GameState.state` stays a pure tree; Rewind (`combat_rewind`) keeps
   working unmodified.
2. The screen (built across tickets 01–03) holds **persistent** combatant
   nodes per fan/strip slot and stops rebuilding them on every
   `state_changed` — nodes update their bound state in place instead.
3. A director plays the beat queue with a duration knob, tap-to-fast-forward,
   and skip — reusing `scenes/components/map_canvas.gd`'s existing
   tween-driven one-shot pattern (`pacing_mode`, `custom_step()`
   fast-forward, persisted pacing toggle). **Copy that architecture; do not
   invent a second one.**

Demoable without any real art: a multi-turn round (e.g. Motion-boosted, or a
3-enemy squad fight) now visibly steps through each combatant's turn against
the ticket 01–03 placeholders in sequence, instead of the screen jumping
straight from pre-round to post-round state.

**Blocked by:** 01 (needs stage/strip nodes to hold persistently against)

**Assets needed:** none — pure architecture, no rendering change beyond
sequencing.

**Status:** ready-for-agent

- [ ] `Combat.player_attack()` (and `flee()`'s parting-shot path,
      `enemy_attack()`) return a `beats: Array` of pure-data dictionaries
      describing each atomic turn's outcome, in the order
      `build_turn_queue()` resolved them
- [ ] `GameState.state["combat"]` carries no new Node/Callable/SpriteFrames
      references — beats are ids/numbers only, resolved by the screen
      through whatever combatant-lookup exists at that point (full sheet
      resolution via `data/combat_visuals.json` isn't required until ticket
      08/09 — a stub id→placeholder-colour lookup is enough here)
- [ ] `tests/test_combat.gd` covers that `beats` matches the existing log
      lines 1:1 in content/order for at least one multi-turn (Motion or
      multi-enemy) round
- [ ] `CombatScreen` no longer calls `queue_free()` on combatant nodes each
      `state_changed` — persistent nodes are created once per fight and
      updated in place across turns
- [ ] A director component plays the `beats` array with a per-beat duration,
      supports tap-to-fast-forward and a full skip-to-end, modeled directly
      on `scenes/components/map_canvas.gd`'s tween/pacing pattern (same
      `pacing_mode` persistence, not a second bespoke pacing system)
- [ ] Rewind (`Combat.combat_rewind`, `push_combat_snapshot`) is
      demonstrably unaffected — snapshotting/restoring state still works
      with the beat queue in place
- [ ] A 3-enemy squad fight or a Motion-boosted round visibly plays out
      turn-by-turn on screen (against ticket 01–03's placeholders) rather
      than snapping straight to the post-round state
