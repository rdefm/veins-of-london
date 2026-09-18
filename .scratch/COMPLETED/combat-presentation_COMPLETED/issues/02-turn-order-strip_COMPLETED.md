# 02 — Turn-order strip: nameplates + swipe-to-target

**What to build:** A single horizontal carousel strip across the top of the
stage window (§2.4), ordered by current turn order (interleaving both
sides — whoever's state computes as "next" appears next, regardless of
side). This is the **one component** replacing three jobs the old card list
did separately: per-combatant nameplate, HP/status detail, and target
selection.

- **This replaces the per-card name/HP labels ticket 01 may still be
  carrying as an interim measure** — after this ticket, the stage (ticket
  01) shows only fanned placeholders + the target glow; all name/HP/status
  info lives in the strip, one source of truth.
- **Swiping the strip changes `combat.focusedEnemyIndex`** — this is the
  targeting mechanism the vision specifies (§2.2: "there is no separate
  tap-to-target step"). Swiping to an ally or the player card is inert for
  targeting (only enemies are valid attack targets) but still scrolls/
  inspects.
- **Card states** per §2.4:
  - *Collapsed* (every card except focused): name, small level badge,
    faction-colour border, HP bar by length only (no number).
  - *Focused* (centred/selected): adds exact HP number, status effects
    (frozen/shielded/motion-turns — pull from `combat.frozenTurns`,
    `player.shieldPool`, `combat.motionTurns`, or the relevant enemy's
    `ability.lockedTurns`), and reserves the slot where ticket 06's enemy
    telegraph will render (leave a labelled empty region if telegraph isn't
    landed yet).
- **Nameplate anatomy** (placeholder-art version): bold name top, small
  level-numeral top-right, the dividing rule line doubling as the
  faction-coloured HP bar (depletes by length, not hue), faction name (or
  "UNKNOWN" in dark grey) bottom in the faction's colour. Damage-decal tiers
  (crack lines / chipped corner / rust speckle at <60%/<30% HP) are a
  **placeholder** — a flat colour-shift or opacity step is fine; the real
  decal overlay set is authored once against the master palette (ticket 07)
  and can be swapped in later with no layout change.
- **Faction-colour mapping**, reusing `data/factions.json`'s existing
  `colour` field (already used by `systems/map_style.gd`): `defend_vein`/
  `home_raid` always dark grey/unknown; `raid` shows the target faction's
  real colour; `mugging`/`event_mugging` always dark grey (muggers have no
  faction).
- **Reflow:** when turn order changes mid-fight, an instant re-sort/snap is
  acceptable for this ticket — the animated tween reorder (§2.4's "the strip
  animates the reorder rather than snapping") is deferred to ticket 04 once
  the beat-queue/tween-director pattern exists; don't build a second
  animation system here.

**Blocked by:** 01 (needs the stage's fan layout and glow to target against)

**Assets needed:** none. Faction colours come from existing
`data/factions.json`. Damage-decal tiers render as a flat colour/opacity
step, not the authored decal art (that lands whenever someone authors the
decal set against the ticket 07 palette — no ticket currently scheduled for
it since §2.4 calls it "zero per-combatant art cost," it can be added to
ticket 07's scope or a follow-up at the human's discretion).

**Status:** ready-for-agent

- [ ] Strip renders one card per living combatant (player, allies, enemies),
      ordered by `Combat.build_turn_queue()`'s current ordering
      (`systems/combat.gd`), interleaving both sides
- [ ] Swiping the strip moves `combat.focusedEnemyIndex` to the swiped-to
      enemy card; swiping to a non-enemy card is a no-op for targeting
- [ ] Collapsed cards show name, level badge, faction-colour border, HP bar
      (length only, no number)
- [ ] The focused card shows exact HP number, active status effects, and a
      reserved (possibly empty for now) intent/telegraph region
- [ ] Faction colour follows the §2.4 table exactly: grey/unknown for
      `defend_vein`/`home_raid`, real faction colour for `raid`, grey for
      both mugging contexts
- [ ] HP bar pulses (or otherwise visibly signals urgency) below ~20% HP,
      independent of the length signal
- [ ] The old per-card name/HP labels from ticket 01 (if any were kept as an
      interim measure) are removed — the strip is the sole source of
      name/HP/status truth
- [ ] Turn order changing mid-fight (a kill, a Motion-boosted extra turn)
      re-sorts the strip's card order correctly, even if only by an instant
      snap rather than an animated tween
