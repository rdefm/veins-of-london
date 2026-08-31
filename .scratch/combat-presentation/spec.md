# PRD — Combat presentation: stage, strip, deck, and the animation pipeline

**Status:** ready-for-agent

**Written against** `combat-redesign`, synthesised from a fresh comparison
pass between `docs/combat-animation-vision.md` and the current codebase
(2026-08-31). `docs/combat-animation-vision.md` remains canonical for every
number, layout rule and asset spec below — this PRD is the buildable ticket
breakdown of that document, not a replacement for it. The mechanics half of
the vision (`squad-combat_COMPLETED`, landed via `REFERENCE.md` §3.7a) is
done; this PRD is the presentation half only.

**Scope of authority:** what to build and in what order. No number, layout
rule or asset spec here overrides `docs/combat-animation-vision.md` — read
the referenced section of that doc before starting any ticket below.

---

## Problem statement

`scenes/screens/combat.gd` still renders combat exactly as it did before
squad combat landed: a plain vertical list of cards, rebuilt from scratch
(`queue_free()` on every child) on every `state_changed`, showing only
`combat.enemies[focusedEnemyIndex]` — a second or third enemy in the roster
is invisible in the UI today, and there is no control anywhere to change
focus. None of `docs/combat-animation-vision.md`'s presentation layer (stage,
turn-order strip, command deck, beat queue, juice, art pipeline) has been
started.

## Strategy: placeholders now, real art later

Every ticket below that touches rendering ships with **placeholder
visuals only** — colour-coded boxes, plain vector shapes, flat palette
fills — never blocked on art production. Each ticket's **Assets needed**
line states exactly what would replace its placeholder, so art production
can run in parallel and swap in per `data/combat_visuals.json` (introduced
in ticket 08) without further code changes. Tickets 07–11 are the ones that
actually consume produced art; everything before them is placeholder-only
and independently shippable today.

## Ticket order (dependency-sorted)

1. `01` — Stage: multi-enemy fan rendering
2. `02` — Turn-order strip: nameplates + swipe-to-target
3. `03` — Command deck: 3 action cards + Dial widget
4. `04` — Beat queue director + persistent combatant nodes
5. `05` — Juice layer
6. `06` — Enemy telegraph
7. `07` — ART-BIBLE, master palette, `tools/pixelize.py`
8. `08` — Backdrop plates (6 contexts) + render/import settings
9. `09` — Idle sheets (7 subjects)
10. `10` — Attack/hit/KO keyposes + transform motion
11. `11` — Effect sheets per consumable
12. `12` — `docs/VISION.md` amendments (§12)

Tickets `07` and `01` have no blockers and can start in parallel with
everything else. Ticket `12` is blocked by whichever of `08`/`09` lands
first pixel art (per the project constitution: the ticket that lands the
first pixel asset must also land the VISION.md amendments — kept as its own
ticket here rather than folded into `08` or `09` so neither art ticket is
gated on the other for ordering).

## Out of scope (flagged in the vision doc, not ticketed here)

- §13 Q1: whether the Map tab becomes a pixel-art Underground diagram
- §13 Q2: where to commit AI-generated reference plates (`docs/art-refs/`
  vs. `.scratch/`)
- §13 Q7: 2nd/3rd combat-eligible ally content — the fan geometry these
  tickets build is sized for 3 regardless
