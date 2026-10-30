# 30 — Grilling: ward types

**What to build:** A grilling session (the `grilling` skill) with the human, then a proposal, for the ward types beyond the time ward. A ward's type is its owning faction's primary ore (21): Collective life, Firm physics, Network emotion, Conclave fate. Each gets its own trigger effect and counters, replacing the generic ward (e.g. a physics ward that blasts and damages the intruder). No code in this ticket.

The grilling must settle, per ward type:
- what triggering it does, in the event (alert, damage, clock) and in a following fight (start state)
- how it's detected (which observation reads, and Prophet's Breath)
- which items and options counter it, and with what effect kind
- whether wards can differ from the faction's primary ore (bought, stolen, upgraded), and whether the player can ward their own veins
- whether any type needs a new fight condition, or fits existing ones

Output: a proposal in this folder, handed to the human for approval. Tickets only after approval.

**Blocked by:** 21 — Wards (the ward data shape and time ward exist).

**Relevant files:** `data/wards.json` (from 21), `data/factions.json` (`primaryOre`), `systems/events.gd` (`apply_effects()`), `systems/combat_rounds.gd` (fight conditions), `systems/observation.gd`, `.scratch/raid-events/raid-variants-proposal.md` §1.7, REFERENCE.md §3.7b Open/Guarded round combat, §3.9d Observation.

**Status:** ready-for-human

- [ ] Grilling session held; decisions recorded at the top of the proposal
- [ ] Proposal covers each ward type with the points above
- [ ] Human approval recorded in the proposal
- [ ] Not marked `_COMPLETED` before approval
