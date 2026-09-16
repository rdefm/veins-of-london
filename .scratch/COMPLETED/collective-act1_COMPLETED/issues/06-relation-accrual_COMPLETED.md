# 06 — Relation accrual

**What to build:** Trade feeding faction/contact relation as an accumulating
meter rather than a per-transaction award, so a player can't farm relation with
lots of tiny sales. Full detail in `.scratch/collective-act1/spec.md` §8.4 —
read it before starting.

**Blocked by:** 01 (the lanes it accumulates from), 05 (vein sales count
toward the same meter).

**Status:** ready-for-agent

- [ ] `state.factions.collective.tradeProgress` accrues +1 relation per £750
      traded through the Collective lane, capped at +3/day.
- [ ] `state.contacts.archie.tradeProgress` accrues +1 relation per £1,000 sold
      through Archie's lane, capped at +2/day.
- [ ] The accumulator carries its remainder across trades — no value is
      silently dropped.
- [ ] Daily caps reset on `daily_tick` (`state.world.relationAwardedToday`).
- [ ] A vein sale's price counts toward the selling faction's `tradeProgress`
      exactly like any other trade.
- [ ] Des, Nadia and Hakim get **no** personal relation trickle from trade —
      only the Collective faction meter moves; their personal relation moves
      only from authored story beats.
