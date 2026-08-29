# 02 — Movement crafting, seating, and attunement bonus

**What to build:** Movements as a craftable, seatable item on the Dial.
Crafting a Movement goes through the existing recipe pipeline (ingredients
always spent, `craftChance` gates success) with the player's chosen ore type
recorded as the resulting Movement's attunement; Movement tier is set by
`Crafting.quality_tier()` at craft time exactly like every other recipe.
Each of the four archetypes (Recharge, Capacitor, Impact, Spread) gets its
own tier-indexed bonus array and downside array (mirrors `effectPower`'s
array-of-arrays shape) — placeholder numbers per the PRD's Out of Scope
note, not a balance pass. A seated Movement can be unseated back to
inventory intact (fully reversible) or swapped for a different one.

A seated Movement's attuned ore type grants a flat, tier-scaled bonus to
whichever chance formula the current action uses — `cultChance`,
`craftChance`, and the Dial's own `seedSuccessChance`-style term from ticket
01 — whenever that action's ore type matches. The bonus is driven only by
what's currently seated, never by loaded Complications (those don't exist
yet — ticket 03), and updates immediately on reseat.

**Blocked by:** 01 (needs `player.dial` to seat into).

**Status:** ready-for-agent

- [ ] Movement crafting follows the existing recipe cost/chance contract:
      ingredients always spent, `craftChance` gates success
- [ ] A successful craft records the chosen ore type as the Movement's
      attunement and sets its tier from `Crafting.quality_tier()`
- [ ] Each archetype has a tier-indexed bonus array and downside array;
      low tier is a small bonus with essentially no downside, tier 5 is a
      much bigger bonus with a real, moderate trade-off
- [ ] Seating and unseating are fully reversible — unseating returns the
      Movement to inventory intact, not destroyed
- [ ] Attunement bonus applies to a matching-ore-type `cultChance`/
      `craftChance`/seed-chance action and does not apply to a mismatched one
- [ ] Attunement bonus changes immediately when a different Movement is
      seated, and disappears when none is seated
- [ ] Attunement bonus is unaffected by anything in `loadedComplications`
