# 05 — T7: Hostile member

**What to build:** The third Phase 1 choice — a three-way response to a member
quietly paying off the Firm. Full detail in `.scratch/collective-act2/spec.md`
§6.7 — read it before starting.

**Blocked by:** 02 (Phase 0 must have activated Phase 1 pins/objectives).

**Status:** ready-for-agent

- [ ] `col_a2_hostile_member` event, three branches:
  - [ ] **Absorb** — small hit to `state.factions.collective.relation` (no
        cost to the named member).
  - [ ] **Make an example** — temporary spike in Firm aggression toward
        `collective` (timed multiplier on rivalry-initiation weighting, or
        direct hit to `factionRelations[firm][collective]` — implementer's
        call which lever, per spec).
  - [ ] **Offer protection** — funds that member's own vein security (T6's
        hard-option lever, retargeted) plus a relation/trust gain.
- [ ] `on_complete`: `state.methodLog.a2HostileMember = "absorbed" | "example" | "protected"`.
- [ ] Event id added to `GameData.EVENT_IDS`; `data/events/col_a2_hostile_member.json`.
- [ ] `methodLog.a2HostileMember` added to `GameState` schema.
- [ ] PROSE-REVIEW flag raised.
