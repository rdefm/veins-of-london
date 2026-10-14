# Story Restructure — Questline Map

Status: draft — under discussion with the owner. Nothing here is decided until marked so.

A fresh, needs-first map of how the story teaches every feature. Existing quests are material to
reuse, rewrite or scrap — they don't constrain the structure.

## Flow

```
PROLOGUE "Rent Day" (linear, ~30 min)
        │
        ├──► ARC A  Collect   (veins)         ┐
        ├──► ARC B  Craft     (making)        ├ parallel, any order
        └──► ARC C  Sell      (business)      ┘
                     │  unlock: TBD (see Open questions)
        ┌────────────┴────────────┐
   ARC D  The Exchange       ARC E  The Register
   (market, Ticker)          (factions, turf, conflict)
                     │
              ACT 3  Endgame (pick a side / corner a market) — later
```

## Prologue — "Rent Day"

One goal on screen: **pay Monday's rent.** Each step is one verb with a guaranteed first success.

1. **Cold open fight** — mugged for Archie's calc. Teaches basic combat + **Rewind** (lose, rewind, win). Flagship feature in the first five minutes.
2. **What calc is** — Archie explains calc and veins in one breath, before you own any.
3. **First sale** via Archie. Cash goes up; the rent gap is visible.
4. **First craft** — James, one pearl, guaranteed success. Archie sells it for far more than raw calc: the reason to craft.
5. **First vein** — handed over. Cultivate, harvest, rest. Teaches the day loop (blocks, rest, morning report).
6. **Pay rent** — Reynard's, Harrow's, the ToDo app, BizBrief Today and the bills cycle, all taught in passing.

Ends: arcs A, B and C unlock, one text from each mentor.

## Act 1 — three parallel arcs

One pillar per arc. Mentors TBD (see Open questions).

| Arc | Teaches | Payoff |
|---|---|---|
| **A: Collect** | prospecting, seeding, site quality, deeper cultivation, locks/wards, being raided (Alarms, defend/leave), guards + guard kits, selling a vein | first defended raid; a second vein running safely |
| **B: Craft** | lab experiments, recipe discovery, item tiers, enhancement, loadout + consumables, then the **Dial**: earn, craft, use, level | your own Dial |
| **C: Sell** | BizBrief, contracts/orders, LodedInnit hiring (one cultivator, one crafter), production, delegation + recurring orders, payday/wages, HQ rooms (triggered by running out of seats), property upgrade | moving day: you upgrade property because the business outgrew the flat |

Why parallel: the player picks a flavour first, and the arcs feed each other — A supplies ore to B and C, B gives C better products, C's payroll pushes A to grow.

## Act 2 — London notices you

Unlock is a story event: you're big enough to appear on the Ticker and in the Register.

### Arc D — The Exchange

Stock market (prices, supply/demand, one-day lag), how your own selling moves prices, shares and market position, the Ticker (states, demand effects, influence). Payoff: you engineer a price spike and cash in.

### Arc E — The Register

- **E1 Diplomacy (first):** the Register app, faction identities, relations (what moves them, incl. ore/crafting overlap), points of contact (POCs) + dove/hawk steering, favours, partners, perks, turf benefits.
- **E2 Conflict (after E1):** intel levels + Network handler, raiding stockpiles/veins, turf control and flipping, harassment, grudges, ambushes, non-violent moves (complaint, police tip, Ticker leak), warmonger/coalitions.

Why late: factions only matter once you own things worth taking or trading. Taught any earlier, they're just abstract meters.

## Act 3 — outline only

Back a faction or go independent and corner an ore market. Built on the D and E systems.

## Reinforcement quests

After key beats, add follow-up quests that make the player *use* what was just taught, so a lesson becomes a habit rather than a cutscene. To be fleshed out per arc.

## Design rules

- One verb per beat, with a ToDo objective that verifies it. Show first, explain after in one card.
- First random roll is always forced: first seed, experiment, raid, prospect.
- Minor features arrive as **nudges** (contact text, BizBrief row, Ticker article), not events: Reynard's, guard costs, shares, Influence sheet.
- Every arc ends with a tangible payoff: an asset, a tool or a place.
- Each mentor owns one arc, so the player always knows who to ask.

## Reuse of existing content (indicative)

- `intro`, `buyer`, `james_meeting` → compressed into Prologue 1–4. Home raid → cold open.
- `archie_cultivation` → rewritten as Prologue 5.
- Collective act 1 (prospecting, seeding, Nadia, Hakim) → Arc A. The Collective as a faction → E1.
- Collective act 2 (defend, guards, intel, losses) → split between late A and E2.
- Business act 1 → Arc C, mostly intact.
- James dial evaluation proposal (`.scratch/writing-revamp/`) → Arc B capstone.

## Open questions

1. **Act 1 mentors.** Leaning towards introducing some faction characters as Act 1 mentors, so that by Act 2 the player already knows how these people fit into the world. Owner to think through.
2. **Act 2 mentors.** Existing contacts, new ones, or faction characters met in Act 1?
3. **E1 lead faction.** The faction controlling your first vein's district (varies by run), or fixed?
4. **Act 2 unlock.** Any 2 of A/B/C, all 3, or a net-worth threshold?
5. **Combat dependency.** The cold open teaches combat; does the combat rework land first, or is the fight kept minimal?
