# 01 — Stage: multi-enemy fan rendering

**What to build:** Replace `scenes/screens/combat.gd`'s single enemy card
with a 390×360 stage window showing **every living combatant on both sides**
at once, per `docs/combat-animation-vision.md` §2 and §2.2. Enemy band upper
third, player+ally band lower — each band's up-to-3 combatants laid out on
the near/far diagonal fan (front slot large/foreground, other two smaller
and staggered behind), not flat left-to-right. This fixes the concrete bug
today: `combat.enemies[1]`/`[2]` exist in state (per squad combat,
`squad-combat_COMPLETED`) but nothing in the UI ever renders them.

Each fanned slot is a **placeholder** — a coloured, labelled box/silhouette
keyed by template id, not real art (ticket 09 swaps these in later via the
manifest that ticket 08 introduces). The currently-focused enemy
(`combat.focusedEnemyIndex`) gets a thin outline/glow around its placeholder
(a `Control`-level border draw, not a shader yet — shader polish is fine to
defer). This ticket is **read-only** with respect to targeting: the glow
reflects `focusedEnemyIndex`, it does not yet let the player change it —
that's ticket 02's job (the vision is explicit that target-switching lives
on the turn-order strip, not as a second tap-target gesture on the stage
itself, per §2.2's "there is no separate tap-to-target step").

The stage sits in the recessed dark inset described in §9 (hard 2px border,
slight inner vignette) so it visually reads as a distinct window even before
any backdrop art exists — background is a flat placeholder fill for now
(ticket 08 adds the real backdrop-per-context plates).

Multiple concurrent instances of the same template (e.g. two Muggers) are
two placements of the same placeholder at different fan positions — no new
state or per-instance art is needed, this is a pure rendering fan-out over
the existing `combat.enemies`/`combat.allies` arrays.

**Blocked by:** None — can start immediately

**Assets needed:** none. Placeholder is a coloured `ColorRect`/`Panel` per
combatant slot, labelled with the combatant's name. Real per-template
sprites land in ticket 09 via `data/combat_visuals.json` (introduced in
ticket 08) — no code change needed here to accept them later.

**Status:** ready-for-agent

- [ ] Stage window renders all non-koed entries in `combat.enemies` (up to
      `Combat.SQUAD_MAX` = 3) in the upper-third enemy band, and all non-koed
      entries in `combat.allies` plus the player in the lower player+ally
      band
- [ ] Each band's combatants are laid out on the diagonal fan (front
      slot large/foreground; remaining slots smaller, staggered behind) —
      not a flat horizontal row
- [ ] A fight with 1 enemy renders identically in spirit to today (no visual
      regression for the common case); a fight with 2–3 enemies (e.g. a hard
      mugger roll, or a multi-guard raid) shows every entry simultaneously
- [ ] The entry at `combat.focusedEnemyIndex` has a visible outline/glow
      distinguishing it from the other fanned enemies
- [ ] Stage sits in a recessed dark inset (2px border + inner vignette) per
      §9, embedded in the existing parchment/vector chrome below it
- [ ] Placeholder rendering is driven by template id (name/key), not
      hardcoded per enemy — swapping in real art later (ticket 09) requires
      no change to this ticket's fan-layout or glow logic
- [ ] Existing single-enemy fights (muggings, home raid, most raids) are
      demonstrably unaffected in outcome/log — this is a pure rendering
      change, `GameState.state` is untouched
