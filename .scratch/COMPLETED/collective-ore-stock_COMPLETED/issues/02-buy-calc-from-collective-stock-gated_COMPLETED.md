# 02 — Buy calc from Collective members, gated by stock

**What to build:** Des/Nadia/Hakim's Trade modal (the existing sell_menu
opened with `factionId: "collective"`) gains a buy side for ore, alongside
its existing sell rows — one modal, both directions, no new screen. Priced
by the already-existing relation-scaled Collective buy price (no new pricing
formula), and capped by ticket 01's stock in addition to cash. Buying draws
down that shared stock; when an ore type hits 0, it's sold out until the
next restock.

**Blocked by:** 01 — needs the stock field and restock system to exist and
be readable.

**Status:** ready-for-agent

- [ ] The Trade modal shows a buy row for each of the 5 ore types alongside
      the existing sell rows, priced via the existing
      `Economy.get_faction_buy_price("collective", "ore", oreType)` —
      unchanged, no new/duplicate pricing logic.
- [ ] Each buy row's purchasable quantity is capped by both cash
      affordability (existing pattern) and the Collective's current stock
      for that ore type. A row is visibly sold out and buying disabled when
      stock is 0.
- [ ] Purchases are all-or-nothing against stock, mirroring the existing
      all-or-nothing-on-cash behaviour: attempting to buy more of an ore
      type than is currently in stock is rejected outright, nothing partial.
- [ ] A successful purchase decrements the Collective's stock for each ore
      type bought; reopening the modal (or any of the three contacts'
      identical Trade entry points) reflects the same updated shared stock.
- [ ] Buying is folded into the same Trade modal/cart the existing sell rows
      already use — no separate buy screen.
- [ ] Guild marketplace and selling ore/consumables to the Collective are
      both unaffected — no stock cap appears on either of those paths.
- [ ] Tests cover: buy price matches `get_faction_buy_price` unchanged;
      purchase rejected when requested qty exceeds current stock; stock
      decrements correctly on a successful purchase; stock is the same
      shared pool regardless of which of the three contacts opened the
      modal.
