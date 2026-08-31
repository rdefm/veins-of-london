# 06 — Enemy telegraph

**What to build:** Per §4.2, surface the wind-up before an enemy acts —
Slay the Spire's intent icon, in this game's shape. The state layer already
carries everything needed per enemy: `ability` (`{id, lockedTurns}`),
`evadeChance`, and `weapon`, via `Combat._enemy_capabilities_from_template()`
(`systems/combat.gd:147`). This converts a fight from a dice roll into a
decision, and is what finally makes `prophetsBreath` (which reveals enemy
intent, per `docs/combat-animation-vision.md` §5) legible.

When an enemy is about to act (its turn is next in the beat queue from
ticket 04, before that beat resolves), its turn-order-strip focused-card
slot (reserved in ticket 02) shows its telegraphed intent — for now this is
its `ability.id` as text/a simple glyph if it has one and isn't locked
(`Combat.is_ability_locked()`), otherwise a generic "attacking" indicator.
This only needs to render when that enemy's card is focused; swiping to
inspect a not-yet-acted enemy should also reveal its pending intent, not
just the currently-acting one.

**Blocked by:** 02 (needs the strip's focused-card intent slot), 04 (needs
beat-queue timing to show the tell *before* the enemy's beat resolves,
rather than only in the post-resolution log line)

**Assets needed:** none for this ticket — intent renders as text/a simple
glyph. Real asset for later (ticket 10 or a follow-up): 1 held ability-tell
pose per enemy template that has an `ability` (§3's frame table: "Ability
tell: 1 pose, held").

**Status:** ready-for-agent

- [ ] Any enemy with a non-null, non-locked `ability` shows its telegraphed
      intent on its turn-order-strip card before its beat resolves
- [ ] An enemy with a locked ability (`is_ability_locked()` true) or no
      ability shows a generic "about to attack" indicator instead, not a
      blank slot
- [ ] Telegraph is visible whether the card is focused because it's the
      acting enemy this beat, or because the player swiped to inspect it
      ahead of its turn
- [ ] `prophetsBreath`'s evade-buff effect (§5: "the enemy's next pose
      ghosts in at ~30% alpha before it happens") is deferred to ticket 10
      (needs the real pose art) — this ticket only needs the telegraph slot
      to exist and read correctly, not that specific visual treatment
