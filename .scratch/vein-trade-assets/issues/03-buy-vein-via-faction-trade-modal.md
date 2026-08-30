# 03 — Buy a faction-owned vein through the Trade modal

**What to build:** The reverse trade — buying a vein a faction currently
owns, rather than selling one of your own. Add a buy-side counterpart to the
existing sell-to-faction mechanism: given one of a faction's own site veins,
it stops being theirs and becomes a new entry in the player's vein
portfolio, growth carried over unchanged, priced at that vein's existing
quote price with no markup. Mirror every side effect the existing
sell-to-faction path has — relation/trade-progress accrual, map/claim-state
updates, objective refresh, cash ledger entry, site claim flag — in reverse,
deliberately; read that existing function closely rather than guessing
which effects matter.

Surface it in the faction lane's Assets section (Des/Nadia/Hakim's Trade
modal): alongside the player's own veins available to sell, list that
faction's own site veins available to buy, straight quote price, no cut and
no mugging roll (same "no cut, no risk" rule the faction lane already
applies to ore/items) — folded into the same batched cart and Go button
ticket 01 built.

Gated by the same vein-sale-unlocked flag selling already uses — no new
flag, this becomes available the same moment selling did.

Free and unconditional — no time-block cost, matching the existing per-vein
Sell action's own "no block cost" rule.

Archie's lane does not get a buy option — he has no faction vein stock of
his own to offer. This is faction-lane only.

**Blocked by:** 01 — needs the Assets section and batched-cart plumbing.

**Status:** ready-for-agent

- [ ] A new buy-side function exists alongside the existing sell-to-faction
      one, doing the exact inverse: faction's site vein removed, player
      gains an equivalent vein with growth unchanged, at quote price.
- [ ] All the bookkeeping the sell path performs (relation/trade-progress,
      map state, objectives, cash, site claim state) has a correct mirror
      on the buy path — nothing skipped.
- [ ] The faction lane's Assets section lists that faction's own buyable
      site veins alongside the player's own sellable veins, gated by the
      same vein-sale-unlocked flag.
- [ ] Buying is folded into the same batched cart/Go button as selling —
      one trade, one price, no cut, no mugging roll, regardless of which
      direction (buy vs sell) any given vein in the cart is.
- [ ] Buying costs cash only — no time-block deduction.
- [ ] Archie's lane is unaffected — still sell-only, no buy rows appear
      there.
