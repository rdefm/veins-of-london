# 18 — Combatant health and intent cards

**What to build:** Read each combatant's health and each attacker's committed action and target directly from the top cards.

**Blocked by:** 14 — Solo combat prototype (authoritative committed intent).

**Status:** ready-for-agent

- [ ] Show current/max numeric health alongside health bars, including player and allies where present.
- [ ] Show each attacker's committed action and target together; retain relevant damage range and resolution timing using approved rules, not illustrative mockup text.
- [ ] Distinguish selected opponent, acting combatant and announced target. Changing card selection never changes committed enemy intent.
- [ ] Refresh correctly after damage, healing, death, interruption and Rewind. Do not invent intent when absent.
- [ ] Preserve access to every combatant in larger fights and existing card selection behaviour.
- [ ] Verify state-to-card updates headlessly; check long names, multiple threats and readable numbers at 390px portrait on-device.

## Delivery constraints

Follow ticket 13's UI agreement and approved prototype rules. Preserve production balance and visual families. Keep content in data, state pure, mutations in systems and rendering in screens. Update ownership documentation when responsibilities change. Run required syntax checks after GDScript edits and the full headless suite. Report device QA separately and flag new prose with PROSE-REVIEW.
