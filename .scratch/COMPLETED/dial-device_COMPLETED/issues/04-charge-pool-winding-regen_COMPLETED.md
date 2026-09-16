# 04 — Charge pool lifecycle, winding, and daily regen

**What to build:** The Dial's charge pool comes alive once a Movement is
seated: persistent `currentCharge`/`maxCharge` (carries across days, not a
daily allowance) with `maxCharge` and natural `rechargeRate` (possibly
fractional) set by the seated Movement's archetype and tier, per ticket 02's
bonus/downside curves. Capacitor's tier-5 downside drops natural
`rechargeRate` to zero. Winding is an instant, calc-only action with no
time-block cost that spends the Movement's attuned ore type to add charge;
its cost-per-charge is a lookup keyed by (archetype, tier) only — never by
Dial level or `maxCharge` size, so leveling never makes winding worse. A
`Dial.daily_regen()` function adds `rechargeRate` to `currentCharge`, capped
at `maxCharge`, guarded the same `lastResetDay`-style way
`Devices.reset_daily_charges()` is — but is not yet wired into
`time_system.gd`'s daily_tick (that wiring is ticket 07's cutover).

**Blocked by:** 02 (needs seated-Movement archetype/tier data to size the
pool and price winding).

**Status:** ready-for-agent

- [ ] Seating a Movement activates the charge pool with archetype/tier-sized
      `maxCharge` and `rechargeRate`; unseating deactivates it (no
      attunement, no charge, no regen — matches ticket 01's inert-Dial story)
- [ ] A tier-5 Capacitor Movement sets natural `rechargeRate` to zero
- [ ] Winding adds charge, spends the seated Movement's attuned ore type,
      and has no time-block cost
- [ ] Winding's cost-per-charge depends only on (archetype, tier) — fixing
      archetype/tier and varying Dial level/`maxCharge` doesn't change it
- [ ] `Dial.daily_regen()` adds `rechargeRate` to `currentCharge` exactly
      once per day, capped at `maxCharge`
