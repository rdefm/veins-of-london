# 01 — Dial state shape, gift gate, and seeding

**What to build:** A new `systems/dial.gd` (static funcs, same discipline as
`sites.gd`/`crafting.gd`) that introduces `player.dial: {...} | null` per the
PRD's Implementation Decisions state-shape bullet — including the cosmetic
`haftId` field (any whitelisted haft id, no stat lookup ever reads it,
validation is "haft exists" only). A gift-gated `Dial.attempt_seed()` lets a
player with the (already-existing-elsewhere) gift flag pay a mixed
five-ore-type cost, roll once at a chance equal to the average of the
existing `craftChance`-style and `cultChance`-style terms, and on success
produce an inert (no Movement, no charge, no regen) Dial. Failure consumes
the full cost with no partial state. Once `player.dial` is non-null, seeding
is refused outright — no second Dial ever.

A save-migration step converts a pre-Dial save's `devicesInProgress`/
`devicesCompleted`/`equipment.device` into a null `player.dial`, leaving
`craftingUnlocked`/`enhancementUnlocked` untouched.

This ticket does NOT delete `systems/devices.gd`/`data/devices.json` or
rewire `combat.gd`/`time_system.gd` — those still call the old system until
ticket 07's cutover, once the Dial has full feature parity.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Seeding is refused with no gift flag; succeeds once the flag is set
- [ ] Seeding cost is a mixed five-ore-type amount, consumed in full on both
      success and failure; failure leaves no partial Dial state
- [ ] Seeding success chance = average of the craftChance-style and
      cultChance-style terms (existing formulas, not a new one)
- [ ] A successful seed produces `player.dial` with no Movement seated, no
      charge, no regen — a visibly inert state
- [ ] Seeding is refused outright once `player.dial` is already non-null
- [ ] `haftId` can be set to any whitelisted haft with no other validation
- [ ] A save with populated `devicesInProgress`/`devicesCompleted`/
      `equipment.device` and no `player.dial` loads without error into a
      null-Dial state, with `craftingUnlocked`/`enhancementUnlocked` intact
