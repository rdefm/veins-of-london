# 13 — Combat prototype: strip is a 10-action carousel

**What to build:** Replace the combat prototype strip's current rolling queue (acted cards rejoin at the end as copies of this round's positions) with a carousel of the **next 10 actions**, in the exact order they'll happen.

- The strip holds the next 10 upcoming actions: the rest of this round, then next round's actions in the system's real next-round timeline order, with real per-combatant counts (e.g. an enemy with 2 actions next round gets 2 cards, even if it has 1 this round).
- When an action resolves, its card slides off the left edge, the remaining cards shift left, and the **next upcoming action** in the queue is appended at the right end. That card is whatever action comes next, not necessarily the same combatant's card coming back. Timed with the beat, respecting the pacing toggle.
- Prophet's Breath adds no cards and changes no order. It only changes what enemy cards show: their move instead of "?".
- Rewind runs it in reverse: the card at the right end leaves, and the undone action's card slides back in from the left.
- Horizon limit: the system only knows plans through the end of next round, so late in a round the carousel may hold fewer than 10 cards. Show what's known.
- Remove the "rejoined copy" mechanism (`rolled_entries()`'s copies, `_next_turn()`'s `next*` fields, the "Next round" relabel on rejoined cards).

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/combat_prototype.gd` (`strip_entries()`, `rolled_entries()`, `_next_turn()`, `resolved_count()`, `begin_strip_playback()`, `begin_rewind_playback()`, `_advance_strip()`, `_settle_strip()`, `_roll_strip()`), `systems/combat_prototype.gd` (`timeline()`, `next_round_timeline()` (enemies only today), `actions_per_round()`, `enemy_intents(..., true)`, `guard_preview(..., true)`, `_acts_before()`), `scenes/components/turn_order_strip.gd` (`advance_to()` anchor + `wrapped_ids()` ghosting; an appended card should enter at the right, a departed one ghost off the left), `tests/test_combat_prototype_screen.gd`, `tests/test_turn_order_strip.gd`

**Status:** ready-for-agent

- [ ] Strip shows the next 10 actions (or fewer at the horizon) in true resolution order across the round boundary
- [ ] Next round's cards use real per-combatant action counts
- [ ] Each resolved action: card slides off left, others shift left, next upcoming action appended right
- [ ] Breath only changes enemy card text, never card count/order
- [ ] Rewind reverses it
- [ ] Respects the pacing toggle
- [ ] On-device check listed in report
