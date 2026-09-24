# 14b — Combat prototype item contracts

**What to build:** Nothing code-level. Grill the human until every calc effect's interaction with the ticket 13a round structure (committed intent, stance-vs-attack matchups, exhaustion) is explicit enough to implement without guessing, then write the resolved rules into ticket 15 so it stops saying "requires explicit specification before use."

**Blocked by:** 14 — Solo combat prototype (done; establishes the round structure these contracts hang off of).

**Status:** ready-for-agent

**Trigger:** human said "All items should be added" to ticket 15's scope; ticket 15 checklist item 4 currently only pre-approves the generic budget rule from 13a ("Item use ... consumes the actor's one committed action for the round, exactly as today") and explicitly defers everything else: "any new Shield, Time Pearl, Enhancement Powder or area-effect contract requires explicit specification before use."

## Process

Use the `grilling` skill on the human. Do not propose answers and ask for a rubber stamp — interrogate until each of the following has an explicit, unambiguous rule (or an explicit "out of scope for 15" from the human):

- [ ] **Enhancement Powder vs. exhaustion.** Enhancement Powder grants a same-round extra queue turn (13a: "a full second commit ... not a bonus attack"). Exhaustion skips "the combatant's very next queue turn" after a committed Heavy. If Heavy is committed on the first of two queue turns in an Enhancement-Powder round, does the exhaustion skip land on the *second slot that same round*, or the first slot *next* round? Both readings are defensible from 13a's text as written — pick one.
- [ ] **Time Pearl / Black Hole freeze vs. exhaustion overlap.** Ticket 13a's own scenario 7 (frozen + exhausted same combatant, same round) was explicitly deferred by ticket 14 ("no freeze mechanic exists in this prototype"). Now that Time Pearl/Black Hole are back in scope, this can't stay deferred — resolve it for real (13a's draft answer was "exactly one turn skipped, frozen's log line takes precedence, exhaustion clears silently alongside it" — confirm, amend, or replace).
- [ ] **Shield vs. stance.** Committing Shield (rather than Dodge/Counter) uses up the round's one action — does that mean the shield-user has *no* stance up at all that round (full passive-absorb-then-HP-loss, no stopped/bypassed/dodged matchup applies), or can Shield's passive absorption stack underneath an unrelated Dodge/Counter some other round? Confirm the item and a stance are mutually exclusive commits, never both in the same round.
- [ ] **Blast / Black Hole vs. solo vs. squad.** Blast's disarm and flee-boost, and Black Hole's AoE-hits-every-enemy behaviour, were authored against multi-enemy production combat. For the *solo* prototype shape (one enemy) they degenerate to a single-target effect — confirm that's fine as the ticket-15 baseline, or whether AoE behaviour needs its own squad-specific check pass (may belong to 15's own "mixed squads" checklist item instead of this contract).
- [ ] **Healing Burst / Healing Salve.** Confirm: instant effect, consumes the round's one action, never triggers or is subject to exhaustion (only a committed Heavy does that) — any objection or wrinkle?
- [ ] **Committed item vs. an opponent's stance.** A committed item is never itself a "Fast" or "Heavy" attack, so it can never be stopped by a Counter or dodged — confirm a stance aimed at a combatant who uses an item that round always fizzles (the existing "opponent didn't attack" fizzle rule), never something new.
- [ ] **Resource source: real inventory or synthetic supply.** Ticket 14 deliberately kept the prototype's item usage at zero specifically to avoid draining the player's real `Crafting`/`Dial` inventory. Reintroducing items forces a choice: (a) spend from the real save's actual stock (risk: playtesting drains real consumables), (b) a synthetic unlimited/reset-per-encounter supply scoped to the prototype only, or (c) something else. This is probably the single highest-impact question — do not let the human skip past it.
- [ ] **Entry point(s): direct bag-item use, Dial-cast complications, or both.** Production has two parallel item paths (`Combat.use_*()` direct-bag, and `Dial.cast_complication()`). Does ticket 15's prototype need both, or is direct-bag-only sufficient for evaluating the mechanic?
- [ ] **Rewind interaction.** Confirm items consumed from whatever resource source (7) get restored on rewind consistently with that choice (e.g. if real inventory is spent, does a prototype rewind un-spend it too, or is that a known one-way leak the human accepts?).

## Deliverable

- Ticket 15 (`.scratch/day-rhythm-business-and-combat/issues/15-squad-and-progression-prototype.md`) updated in place with the resolved rules — same "Approved rule" section style ticket 13a used — replacing its current one-line deferral in checklist item 4. Preserve the pre-update text as a dated comment or trailing note rather than silently deleting it, same spirit as `13-combat-prototype-rules_old.md` being kept alongside 13a.
- This ticket (14b) renamed `_COMPLETED` once 15 is updated — 14b's own job is the spec capture, not the item implementation itself, which stays ticket 15's job.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
