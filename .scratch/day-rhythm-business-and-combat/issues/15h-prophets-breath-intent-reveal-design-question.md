# 15h — (grilling) Should Prophet's Breath reveal enemy intent?

**What to build:** Nothing code-level. Grill the human on whether Prophet's Breath's canonical effect should change from a pure evade-turns buff (current `docs/REFERENCE.md`/`docs/VISION.md` definition, implemented `systems/combat.gd:1181`) to something that shows what an enemy is about to do — before touching mechanics or REFERENCE.md.

**Raised by:** 15e's on-device QA — with 2-3 living enemies, a human tester can't tell what any enemy is planning, and asked for Prophet's Breath to fill that gap.

**Blocked by:** None, but read alongside ticket 18 (combatant health and intent cards) before grilling — ticket 18 already proposes showing each attacker's *already-committed* action/target on cards, unconditionally, for every player, per `docs/combat-animation-vision.md` §4.2's "enemy telegraph" concept. That doc frames the telegraph as free UI, with Prophet's Breath's own mention there being only that its evade effect becomes easier to *see* once the telegraph exists — not that the item is what unlocks seeing it.

- [ ] Use the `grilling` skill on the human. Do not propose an answer and ask for a rubber stamp.
- [ ] Establish whether "can't see enemy intent" is fully solved by ticket 18 shipping as already specced (free, unconditional intent display) — in which case Prophet's Breath needs no mechanical change and this ticket resolves as "no-op, close via ticket 18."
- [ ] If the human wants intent gated behind an item rather than free: resolve what changes — does Prophet's Breath gain a second effect, replace its evade effect, or does this need a distinct new item/mechanic instead of overloading Prophet's Breath's existing (REFERENCE.md-defined, `xpReward`/price-costed) contract?
- [ ] If Prophet's Breath's contract changes: this is a canonical-numbers change (`docs/REFERENCE.md` owns it) — resolve there first, not in code, and flag the discrepancy with `docs/VISION.md`'s existing "Previews one choice's outcome hint" (event-only) vs. combat description.
- [ ] Resolve interaction with ticket 18's cards if both ship: does the telegraph become conditional on having Prophet's Breath active, or do cards stay unconditional and the item does something else entirely.
- [ ] Deliverable: a new ticket with the resolved rule, ready for implementation — this ticket's own job is the design decision, not the implementation.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Do not redefine Prophet's Breath's effect in code or data ahead of this grilling session's resolution.
