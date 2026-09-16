# 01 — Sell a vein through the Trade modal (faction lane)

**What to build:** Both existing Trade modals — Archie's general fence lane and
the faction straight-trade lane (the one Des/Nadia/Hakim all open) — get
reorganized from a flat list into three collapsible sections: **Ore**,
**Items**, **Assets** (reuse the existing accordion-style collapsible
component; all three start expanded). In the faction lane, Assets lists every
vein the player owns as a cart row capped to an include/exclude toggle (0/1,
not a +/- stepper — a vein isn't stackable), and selling one is folded into
the same batched cart the ore/item rows already use: tapping the existing
"Go" button sells everything selected, veins included, at the vein's
already-existing quote price. If the cart includes a vein, the Go button's
own label calls that out (e.g. "Go — trade (includes 1 vein sale)") — this
*is* the safeguard; there's no separate per-vein confirm step anymore for
this flow (deliberate change — read the code comment on the old confirm
modal before touching it, it explains the guard being replaced).

Archie's lane also gets the same three-section layout in this ticket, but
its Assets section stays inert (no sell wiring, no vein rows yet) — that's
ticket 02.

The whole Assets section — in both lanes — is gated by the existing
vein-sale-unlocked flag, unchanged. Nothing about when/how that flag gets
set changes.

The existing standalone vein list screen (its own per-vein Sell button,
reachable from the map) is untouched — this ticket adds a second path to the
same underlying sale, it doesn't replace or remove the first.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Both Trade modals render Ore/Items/Assets as three collapsible
      sections instead of a flat list; existing ore/item rows and their
      cart behaviour are unchanged in substance, just regrouped.
- [ ] Faction lane's Assets section lists every player-owned vein as a 0/1
      toggle row, visible only when the vein-sale-unlocked flag is set.
- [ ] Selecting a vein and tapping Go sells it via the existing faction-sale
      code path, at the existing quote price, batched with any ore/items
      also selected in the same trade — one cart, one sale.
- [ ] The Go button's label/summary distinguishes a trade that includes a
      vein sale from one that doesn't.
- [ ] Archie's lane shows the same three sections but Assets has no vein
      rows / no sell wiring yet — verified inert, not broken.
- [ ] The standalone vein list screen's own Sell button still works exactly
      as before, unmodified.
