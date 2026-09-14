# 15d — Record scenario results and a production-integration recommendation

**What to build:** Ticket 15's own required deliverable — a written record of what the squad/progression/item/wave experiment actually showed, plus a recommendation for separately scoped production work. This is evaluation and writeup, not new mechanics.

**Blocked by:** 15c — conclusions (especially the mixed-squad tactics finding) have to rest on a verified, bug-free simulation, not a result that might still be a harness bug.

- [ ] **Single-target defence demonstration** (checklist item 1): record the `pairAmbush`/`squad_stance_covers_only_its_target...` evidence that a stance committed against one enemy leaves every other enemy fully dangerous, with a one-line readable-in-play assessment (does it read clearly to a human tester, or does it need a UI callout before production?).
- [ ] **Mixed-squad tactics finding** (checklist item 2): report the `mixedCrew` fixed-strategy simulation's actual win/loss/flee split (from 15b's fixed, trustworthy run) and state plainly whether "Dodge twice, Heavy, repeat" dominates, loses, or is roughly even — and what that implies for whether the four-action grid needs a fifth option or rebalancing before production.
- [ ] **Progression finding** (checklist item 3): record that ordinary (data-driven) `combat_prototype.json` enemies structurally cannot scale with player build (confirmed by `ordinary_enemies_do_not_scale_with_player_equipment_or_skill`), and note whether that's the intended production posture or needs an explicit "scaling enemy" design decision later.
- [ ] **Multi-wave assessment** (checklist item 5): a readability/pacing judgement on the `gauntlet` two-wave fight — does sustained HP loss across waves read clearly on the (as yet device-unverified) screen, and does the ticket's "don't turn routine encounters into waves" boundary hold (i.e. multi-wave stays a deliberate, rare escalation, not a new default shape)?
- [ ] **Explicit deferral note** (checklist item 6): record that Grab/Bolt/Call were NOT introduced, and why (no resolved contract exists — see optional follow-up 15f).
- [ ] Write the whole above as a dated "Results and recommendation" section appended to ticket 15's own file (`.scratch/day-rhythm-business-and-combat/issues/15-squad-and-progression-prototype.md`), same style as 13a's/15's own "Approved rule" sections — preserve rather than delete anything superseded.
- [ ] State a clear recommendation: what (if anything) is ready to inform a separately scoped production integration ticket, and what open questions that future ticket would still need to resolve.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. This ticket is writeup-only — no code changes are expected.
