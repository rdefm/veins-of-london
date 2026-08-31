# 01 — Collective ore stock & random restocking

**What to build:** The Collective now tracks a limited, independently-scarce
stock of each of the 5 ore types, rather than being able to sell the player
an infinite amount (which ticket 02's buy lane will draw against). Stock
restocks to a small random quantity on an unpredictable daily cadence, not a
fixed interval. This ticket is backend/system only — verified via tests, not
yet exposed in any UI.

Shared faction-wide pool (not per-member — Des/Nadia/Hakim remain three doors
into the same lane, per the existing collective1-07 design). Ore only — no
stock concept for consumables. Stock quantity is independent of relation;
relation keeps doing its existing job narrowing the buy/sell price spread
(`Economy.get_faction_buy_spread`/`get_faction_sell_spread`) — this ticket
must not touch that pricing logic.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `factions.<id>` state gains a new per-ore-type stock field, present on
      every faction for schema uniformity (same pattern as `tradeProgress`)
      but only ever rolled/read for `"collective"` in this milestone.
      Defaults to 0/empty for a fresh game.
- [ ] The moment `flags.collectiveLaneUnlocked` first becomes true, the
      Collective's stock is rolled fresh using the same restock logic as the
      daily roll below — not a special-cased "day zero" branch, just the
      first restock happening at unlock instead of waiting for a qualifying
      `daily_tick`. Day one is never an empty shelf.
- [ ] `TimeSystem.daily_tick()` gains a new step, appended after the
      existing lettered step chain (no ordering dependency on the other
      steps), that rolls a daily chance — roughly 25-35% — of a restock
      event firing that day.
- [ ] When a restock event fires, all 5 ore types reroll together as one
      event to a fresh random quantity in roughly the 5-20 unit range each
      — replacing whatever stock remained, not adding to it.
- [ ] Restocking is silent: no `Notify.push` or other player-facing signal
      of any kind.
- [ ] Stock quantity is never affected by Collective relation.
- [ ] Tests cover: the initial pre-roll firing exactly once at unlock: the
      daily chance actually producing restocks over many simulated days
      (statistically reliable, not flaky); all 5 ore types rerolling
      together in the same event; rolled quantities landing in the intended
      range.
