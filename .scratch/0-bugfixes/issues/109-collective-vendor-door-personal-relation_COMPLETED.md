# 109 — Personal relation for Collective's vendor doors (Des/Nadia/Hakim)

**What to build:** Trading through Des, Nadia, or Hakim (`systems/collective.gd`'s
`Collective.complete_trade(contact_id)`) currently only moves
`factions.collective.relation` via `RelationAccrual.accrue_faction("collective",
...)` — each vendor's own `contacts.<id>.relation` stat (present in state since
`data/constants.json`'s contacts roster, currently unused by anything) never
moves, so a player who trades exclusively with, say, Nadia sees no personal
standing build with her specifically. Add a personal-relation gain to whichever
vendor the trade went through, firing alongside the existing faction gain —
same "both fire" shape `Economy.execute_sale`'s Archie lane already has
(`Contacts.award_relation("archie", ARCHIE_SALE_RELATION_GAIN)` flat award +
`RelationAccrual.accrue_archie()`'s tradeProgress meter). `RelationAccrual.LANES`
is the natural place to add des/nadia/hakim entries (container "contacts", id
the contact_id) — `complete_trade(contact_id)` already receives the contact_id
needed to dispatch on. Scope is Des/Nadia/Hakim only: Firm/Guild/Network/Conclave
have no individual vendor contact in `state.contacts` at all, so their trade
lanes stay faction-relation-only — do not invent new contacts for them.

Open question to resolve during implementation, not before: `VeinTrade.
sell_to_faction()`/`transfer_to_faction()` (vein sales routed through a vendor
door) receive only `faction_id`, not `contact_id` — decide whether a vein sale
through a vendor door should also count toward that vendor's personal relation,
and thread `contact_id` through if so.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Trading through Des, Nadia, or Hakim's door increases that specific
      contact's `relation` stat, verified by a test that trades through one
      vendor and asserts only that vendor's (not the other two's) personal
      relation moved.
- [ ] The existing Collective faction relation gain is unchanged — both the
      personal and faction gains fire from the same trade.
- [ ] Rate/cap for the new personal-relation gain is called out in the
      ticket/commit as a draft number pending human balance sign-off, same
      convention as other draft economy numbers in this codebase.
- [ ] Firm/Guild/Network/Conclave trade lanes are untouched — no new contacts
      invented for them.
- [ ] Decision recorded (in the ticket or commit message) on whether vein
      sales through a vendor door count toward personal relation, and
      implemented consistently with that decision.
