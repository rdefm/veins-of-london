# 15f — (optional) Grab/Bolt/Call contract resolution

**What to build:** Nothing code-level. Grill the human until Grab/Bolt/Call's interaction with the ticket 13a/15 round structure (committed intent, stance-vs-attack matchups, exhaustion, real-item resource budget) is explicit enough to implement without guessing — same process 14b used to unblock the item roster for ticket 15 itself.

**Blocked by:** None — independent of the rest of the ticket 15 chain. Optional: only pick this up if the human wants Grab/Bolt/Call explored in this prototype; ticket 15's own checklist only requires that they NOT be introduced without a resolved contract, which is already satisfied by leaving them out.

- [ ] Use the `grilling` skill on the human. Do not propose answers and ask for a rubber stamp.
- [ ] Establish what Grab/Bolt/Call actually do mechanically in this prototype's committed-round shape (the parent spec/REFERENCE.md may already define them for production combat — confirm whether this is "port the existing formula into the round structure" or "these need new prototype-only numbers").
- [ ] Resolve their interaction with committed stances (can a stance be aimed at a Grab/Bolt/Call user? does one consume the actor's one committed action, same as every other action in this prototype?).
- [ ] Resolve their resource source (real inventory/Dial, per ticket 15's existing "no synthetic pool" precedent, unless there's a reason to diverge).
- [ ] Resolve Rewind interaction, consistent with ticket 15's existing item-restoration contract.
- [ ] Deliverable: a new ticket (15g or later, numbered after whatever's landed by then) with the resolved rules, ready for implementation — this ticket's own job is the spec capture, not the item implementation itself.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change.
