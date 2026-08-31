# 12 — `docs/VISION.md` amendments (§12)

**What to build:** Per the project constitution's conflict rule
("Where it conflicts with `docs/VISION.md` on art direction, this document
wins and VISION.md must be amended in the same ticket that lands the first
pixel asset"), land the three amendments `docs/combat-animation-vision.md`
§12 specifies, now that a real pixel asset has landed (whichever of ticket
08's backdrop plates or ticket 09's idle sheets completed first):

| Line | Current text | Fix |
|---|---|---|
| `docs/VISION.md:103` | "One illustration + icon set = **the entire exploration art budget**." | Replace/qualify — the art budget now includes a sprite roster, backdrop plates, and an effect library |
| `docs/VISION.md:103` | "one stylised hand-drawn map — an occult A-Z, ink on paper" | Scope this to the Map tab specifically (still under its own review per §13 Q1), not stated as the game's overall art direction |
| `docs/VISION.md:12` | "a stylish, text-forward, menu-driven interface layered over a hand-drawn map of London" | Keep "text-forward, menu-driven"; drop/qualify "hand-drawn" |

Also land the **squad-combat M4 line amendment** flagged in the same §12:
`VISION.md`'s M4 line ("squad combat (2–3 enemies, per-enemy intent rows,
AoE targeting...) with T4 enemy content") should reflect that squad combat
already landed earlier than M4, per `squad-combat_COMPLETED` /
`REFERENCE.md` §3.7a — confirm the actual milestone placement with the
human rather than guessing a replacement line, per the vision doc's own
"needs its own milestone-planning conversation, not settled here."

This is deliberately a small, standalone, docs-only ticket rather than
folded into ticket 08 or 09, so neither art ticket is gated on documentation
review, and so it's unambiguous which ticket does this regardless of
whether backdrops or idle sheets land first.

**Blocked by:** 08 or 09, whichever lands its first real pixel asset first

**Assets needed:** none — documentation only.

**Status:** ready-for-agent

- [ ] `docs/VISION.md:103`'s "entire exploration art budget" line is
      corrected to reflect the actual combat art scope
- [ ] `docs/VISION.md:103`'s "hand-drawn map" line is scoped to the Map tab
      only, not stated as the game's general art direction
- [ ] `docs/VISION.md:12`'s "hand-drawn map of London" phrasing is corrected
      (keeping "text-forward, menu-driven")
- [ ] `docs/VISION.md`'s M4 squad-combat line is updated to reflect actual
      landed status/milestone, per a confirmed decision from the human (not
      a guessed replacement)
- [ ] No other `docs/VISION.md` line is touched — the vision doc is
      explicit these three (four, with M4) are the only lines this work
      invalidates
