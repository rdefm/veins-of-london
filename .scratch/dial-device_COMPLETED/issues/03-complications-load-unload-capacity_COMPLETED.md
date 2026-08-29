# 03 — Complications: load, unload, and capacity budget

**What to build:** Loading an existing crafted consumable recipe into the
Dial as a Complication — no new item category, just moving one unit out of
`Crafting`'s tier-bucketed inventory into `player.dial.loadedComplications`
(recipe key, tier, capacity cost, detent position), unchanged in tier;
unloading reverses it exactly. Each recipe gets a new fixed capacity-cost
field in its data definition, independent of the crafted quality tier of the
unit loaded — crafting a better version of something already loaded is
never a footprint downside. Total loaded capacity cost can never exceed the
Dial's capacity budget, which comes from a Dial-level lookup table (added as
data here) and is independent of which Movement is seated or even whether
one is seated at all.

**Blocked by:** 01 (needs `player.dial` to load into; does not need a seated
Movement).

**Status:** ready-for-agent

- [ ] Loading a Complication decrements the regular tiered inventory by
      exactly one unit and appends it to `loadedComplications` at the
      recipe's fixed capacity cost, regardless of crafted tier
- [ ] Unloading reverses loading exactly — unit returns to the same tier
      bucket it came from, not duplicated or destroyed
- [ ] Loading is refused once it would push `capacityUsed` past
      `capacityMax`
- [ ] `capacityMax` comes from a Dial-level lookup table only — unaffected
      by which Movement (if any) is currently seated
- [ ] Loading/unloading works identically with no Movement seated
