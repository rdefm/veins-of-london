# 22 — Personal stash: shared/reserve split

**What to build:** The player can set aside ore and crafted items into a
personal stash that no business system can touch.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Add a personal stash for ore and crafted items, separate from the
  existing shared stockpile.
- [ ] Moving stock between shared stock and the stash is instant and
  reversible (no time cost, no restriction beyond available quantity).
- [ ] Stock moved into the stash is subtracted from the same pool every other
  system reads (`player.orichalchum` / crafted-item inventory) — the stash
  is a transfer destination, not a second view onto the same numbers, so no
  other system needs to learn about it.
- [ ] Personal-stash stock is never available to contracts, Sales,
  Production, or Procurement (automatic, since it has left the pool those
  systems read).
- [ ] There is no second per-item reserve setting anywhere — the personal
  stash is the sole reserve mechanism.
- [ ] Expose move-in/move-out controls somewhere reachable (e.g. the existing
  Ore-store/inventory surface) — exact placement is a UI-fit decision, not a
  mechanics one.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
