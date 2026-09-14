# 21 — Contact roles: Sales skill + unified role assignment

**What to build:** Any recruited contact can be assigned to a Sales role, on
the same one-contact-per-room footing as the existing Lab/Vein Station
assignments, gated by the Operations Room.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Contacts gain `salesSkill`/`salesXP`, using the same skill-threshold-
  ladder mechanism as `craftingSkill`/`cultivatingSkill`
  (`[0, 0, 80, 220, 500, 1000]` per business-spec.md).
- [ ] A Sales, Production or Procurement assignment replaces any room
  assignment on that contact, and vice versa — one assignment per contact,
  reusing the existing `assignedRoom` one-contact-per-room mechanism rather
  than adding a parallel state model.
- [ ] The Operations Room becomes the Sales gate. Its data-file description
  is rewritten from the current "faction contact operations" text (that
  future faction-passive use is retired, not merely deprioritised — see
  business-spec.md grilling decision 4) to describe staffing a Sales
  contact.
- [ ] The Rooms screen lets the player assign/unassign a contact to Sales the
  same way it does Lab and Vein Station today.
- [ ] No offer, contract, or automation behaviour is wired yet — this ticket
  is the assignment model only.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
