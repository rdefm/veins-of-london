# 06 — Queue advancement synchronised with playback

**What to build:** The visible queue moves in step with the fight as it plays. When a beat resolves a combatant's turn, that combatant's front occurrence leaves at the left and any newly projected occurrences enter at the right, timed to the director's beat cadence — never jumping straight to the already-resolved final state and never showing an intermediate turn that has not yet played. When action playback starts, the strip's viewport returns to the front. The user's scroll position otherwise survives unrelated refreshes (status ticks, notifications). Rewind playback runs the queue backwards to the restored decision point.

**Blocked by:** 04 — Occurrence queue cards; 05 — Tap selection.

**Relevant files:**
- `scenes/screens/combat.gd` — `_play_beats`, `_on_beat_played`, `_on_combat_beats_played`, `_on_combat_rewind_played`, `_on_rewind_beat_played`, `_frozen_roster` (intermediate-state rendering pattern), `_sync`
- `scenes/components/combat_director.gd` — `play`, `beat_duration`, `is_playing`, `fast_forward_current_beat`
- `scenes/components/turn_order_strip.gd` — advance/enter animation, viewport reset, scroll-offset persistence across `configure`
- `systems/combat.gd` — beats must carry enough occurrence identity (actor type/index + occurrence id from 04) for the strip to know which card leaves
- `tests/test_combat_screen.gd` — "beat_played_posts_the_newly_revealed_combat_log_line…", "attacking_seeds_the_ghost_tracker…", strip-selection-survives-refresh cases
- `tests/test_combat_director.gd` — playback/fast-forward cases
- `tests/test_turn_order_strip.gd`
- `docs/combat-animation-vision.md` — §2.4 Reflow, §8 beat queue

**Status:** ready-for-agent

- [ ] After the Nth beat of a multi-turn playback, the strip's front card is the (N+1)th occurrence, not the post-round front
- [ ] A card leaves the left only when its owner's turn beat has played; new occurrences appear at the right in projection order
- [ ] Starting playback resets the strip's scroll offset to the front
- [ ] An unrelated `state_changed` mid-inspection (no playback) preserves the scroll offset
- [ ] Fast-forwarding a beat advances the queue to match, with no orphaned cards
- [ ] Rewind playback ends with the strip showing the restored decision point's projection
- [ ] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP rows updated
