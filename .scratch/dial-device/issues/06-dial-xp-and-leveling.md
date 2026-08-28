# 06 — Dial XP and leveling

**What to build:** Casting a loaded Complication (ticket 05) awards Dial XP,
mirroring the old device-activation XP award. Leveling up grows `maxCharge`
and `capacityMax` as the primary per-level curves (reusing the existing
`DEVICE_XP_LEVELS`-style table mechanism), while `rechargeRate` grows on a
sparser, occasional curve — leveling reads as "bigger reserve now, refills
faster as a rarer milestone." Movements never modify capacity; capacity
growth stays Dial-level-only, structurally separate from any future
second-Movement-slot milestone (explicitly out of scope for v1).

**Blocked by:** 05 (needs a cast event to award XP from).

**Status:** ready-for-agent

- [ ] Casting a loaded Complication awards Dial XP
- [ ] A level-ladder test (same shape as the existing device XP ladder test)
      shows `maxCharge`/`capacityMax` growing on the primary curve and
      `rechargeRate` growing on a visibly sparser curve
- [ ] Leveling up never changes which Movement is seated or its attunement
