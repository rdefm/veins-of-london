# Story Restructure — Questline Map

Status: draft — under discussion with the owner. Nothing here is decided until marked so. The motivation spine, Prologue and early Act 1 beats were decided 2026-10-19. The Act 1 shape is parked (Open question 6).

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

## Motivation spine (decided 2026-10-19)

Problem: after "pay rent" the player has no reason to care, and drifts after the first few Collective quests. Fix: a chain of concrete money goals, each handing off to the next before the last one runs out, plus a face to resent and people to protect.

**Goal chain:** pay rent (Prologue) → save a **deposit to move somewhere safer** (after the flat raid; Des/Hakim/Nadia quests are tuned to earn it quickly) → by moving day the player is fond of Hakim, and the Firm leans on his yard. Two reasons to help him: he's a friend, and he's how you got your money.

**Antagonist layers:**

- **The squeeze (unseen, Act 2/3 reveal):** someone bigger is quietly cornering calc in East London, starting with emotion. It shows up first as Ticker prices and articles, not exposition. It mirrors Act 3 ("corner a market"): the player later learns to do the thing that started all this. Who the buyer is: TBD, later.
- **The Firm (Act 1 opposition):** it owes product upstream at old prices. The squeeze sets off an internal succession fight. To meet commitments, and not look weak to rival claimants, the Firm goes hard after small dealers' calc and veins. Archie and Hakim are collateral.
- **The lieutenant — Nick (Act 1 face, not the endgame villain):** low-level Firm, backing the hawkish side of the succession. He throws the cold-open sucker punch. He's distinctive and memorable, petty, enjoys it slightly too much, and is written so the player wants revenge. He doesn't stalk the player: he's absent from the rest of the Prologue and returns at Hakim's yard in Act 1. Not everything ties back to him.
- **The Firm boss:** old-school, with debts upstream and people to pay. Sees the Collective as freeloaders on ground the Firm has protected for decades. Carries the "justifiable from where they stand" argument. The Collective-vs-Firm arc ends with the player **influencing the boss** (POC dove/hawk steering, pulled forward from E1). One event needs both the lieutenant and the boss.

**Theme rule for the Firm:** villain-coded early, understood later. They aren't evil for its own sake. They're people under different pressures, with tools and approaches shaped by their experience and personalities.

**The lieutenant's crack (the mirror):** he started where the player is. His dad was the family's breadwinner; the family was never loaded but got by, until the dad was incapacitated and went into a care home. The family struggled, and he stepped up the only way that ever let him climb. Going hard is how he keeps his family off the bottom. The player should come away thinking "you're still a bully and you're wrong, but I see why you thought it was right", and feel uncomfortable asking whether they'd be any different. Keep it understated, no pity party:

- **Early tell:** he takes a call mid-shakedown and his voice changes completely.
- **After you beat him at Hakim's:** you see him somewhere ordinary (care-home reception), paying in cash. Echo the cold open's Tesco bag. One line at most.
- **The sting:** his Monday is the player's Monday.

**The gym owner — Arnie:** Archie's mate. Real name **Reginald**, revealed later (not in the Prologue); he just thinks "Arnie" suits a gym owner. Belly with muscle under it: he calls it a "dad bod", his waistline disagrees. Runs a calc fighters' gym under a railway arch, **Flip Reverse**, named after the Blazing Squad song: he was a big fan in his youth and proudly recalls getting into a punch-up with some of the band. The "Flip" has fallen off the sign, so it reads "Reverse". Secretly ex-Firm, and **not revealed until Act 1**: the player trusts and likes him first, which gives a sympathetic view of the Firm from someone they know. He trained Nick as a teenager, so he's the natural source of his backstory ("Good kid. Then his dad went into the home."). He never excuses him ("He knows better. I taught him better."). Later route to the Firm boss. **Neither the ex-Firm past nor training Nick is hinted in the Prologue**; both are Act 1 reveals.

## Prologue — "Rent Day" (decided 2026-10-19, pending playtest timings)

One goal on screen: **pay Monday's rent.** Arc: lose → learn → make → win → pay. Draft the whole Prologue, playtest it with per-step timings, then cut.

1. **Cold open — scripted loss + Rewind.** Archie hands you a Rewind (a T5, one of James's): "If it goes bad, break it." The buyers arrive; event text sets up the lieutenant. Combat opens and his **sucker punch is the first beat of round 1**, inside the fight, so an in-combat Rewind can undo it. Scripted crit, and Archie goes down. All moves stay open, with one-line coach marks. The fight can't be won. When the player drops below X HP, the action bar locks to the Rewind with Archie's line as a guided prompt. The **player taps it**. Break animation, then the fight rewinds to its start (T5 depth). Event cards: you warn Archie, he guards the sucker punch, throws a Time Pearl (freeze animation), and you leg it.
2. **Pub — what calc is.** The current `intro` pub half, mostly intact.
3. **First sale** — Marcus (`buyer`). Cash goes up; the rent gap is visible.
4. **First craft** — James, pearls, guaranteed success. James can own the Rewind ("That was one of mine.").
5. **Gym** — Archie: "just in case". 2–3 intro cards. **One guided spar**, a **practice scripted fight** (`practice: true`: spar rules — free unlimited Rewinds, no HP carried out, Combat XP + win bonus, move XP, no loot; Rewind lock and post-Rewind script optional; resumes the event on any outcome; doesn't use a free spar session). One lesson per round via coach marks: R1 Guard (read the intent, block), R2 Feint → Strike, R3 Stun on an Open target. Leg it gets one line. The gym's free Rewind is introduced ("House rules."). Then a **demo**: the owner spars Archie for 1–2 auto-resolving rounds, showing Feint L5 (autoguard → retaliate), with one line on levels. Exit: Spar unlocked, 3 free sessions.
6. **Archie sells your pearls — clean, very short.** Shows that most deals are boring. He keeps a couple back for you ("Just in case."), which teaches loadout/stash in one line. The irony lands in character (Archie: most of them are boring), never as a narrator wink. The raid comes that night.
7. **Flat raid — first win.** `home_raid_intro`, kept. A lone burglar with no Firm link. Won with your own crafted pearls: "that first fight was brutal, but I won this one with something I made." **Debrief:** Archie says the flat's a liability. You need cash to move somewhere safer, and he'll line up help (Des). Sets the **deposit goal**.
8. **First vein** — Archie's cultivate lesson (`archie_cultivation`). Teaches the day loop.
9. **Pay rent** — Reynard's, Harrow's, the ToDo app, BizBrief Today and the bills cycle, taught in passing.

**Ending:** rent paid, then: (a) next Monday's already on the calendar; (b) the first Ticker article on emotion calc prices, with Archie uneasy ("Buyers are twitchy."). It's a headline **and** a real, timed rise in emotion calc demand (placeholder +20% for 7 days, TBC at the playtest pass); Archie mentions The Ticker articles and suggests the player keep an eye on it to see what's going on in the calc world; (c) **one clear next step**: Archie's text to meet Des. The other arcs' texts land a day later as nudges.

## Early Act 1 beats (decided 2026-10-19)

- **Deposit progress:** a visible "Deposit: £X / £Y" (ToDo/BizBrief) while playing the Collective quests. Moving day comes once the player is endeared to Hakim.
- **Be A Lady lesson — Des's prospecting/seeding event.** Des gives you a T5 Be A Lady for your first try. It finds a really good site, and the seed takes first time thanks to Lady (the first seed is forced anyway; tuning makes the attribution plausible). Des: anything with luck in it, Lady helps. That nudges a **guided craft** with the ore, where the result card says explicitly that Lady's bonus tipped you into the next rung, permanently unlocking a higher-tier recipe.
- **"Find your playstyle" quest (Arc B opener, post-Prologue).** Archie: your crafting is your edge in a fight, so learn which items suit you. Try every item from the gym's practice rack, pick 1–2, get the recipes, craft a batch, equip it, and put the rest in your stash, so the business can't sell them and you can't trade them away by accident.
- **The lieutenant returns at Hakim's yard.** You beat him, then the mirror reveal.

## Features to build and test before writing story specifics

In dependency order. Each is headless-tested before any prose depends on it.

1. **Rewind tiers.** In-combat Rewind depth in rounds by tier: T1 1, T2 2, T3 3, T4 4, T5 to fight start. One unit = one jump of its **full** tier depth (the player doesn't choose). Needs round-boundary snapshots plus a fight-start frame, replacing the 1-pick/cap-2 stack (REFERENCE §3.7b). Failsafe, the bench Rewind and the time-block Rewind are unchanged.
2. **Scripted-fight support.** Fixed enemy plans and forced crits, an HP-threshold trigger that locks the bar to Rewind with a prompt, per-move coach marks, scripted post-Rewind resolution (ally guards, pearl freeze, leg it), and a scripted auto-resolving demo fight (NPC vs NPC).
3. **Gym + Spar.** A new location. A Spar action (1 block) against 3 partners (easy/even/hard, scaled to Combat Skill). **Practice rack**: every loadout item at T1, free, gym-only. Free unlimited Rewinds. Combat XP plus a win bonus, normal move XP, no HP loss carried out, no loot. **3 free sessions** used whenever, then a small £ per session (TBC). Home `train()` stays as the cheap fallback.
4. **Be A Lady expansion.** Prospecting site-quality best-of-two, seeding chance +X/level, and a % bonus on event choice `check`s. Numbers TBC.
5. **Move deposit + progress bar.** A deposit on rented moves (N weeks' rent, returned on move-out, TBC), the progress display, and a higher starting-HQ raid chance so moving feels needed.
6. **Prologue timing log.** Debug per-event/step start/end timestamps, for the playtest cut pass.

Also: REFERENCE §1 property table / ADR 0006 still describe rent as `dailyCost`; check them against the current bills model.

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

- `intro` → split: the Mile End fight becomes the scripted cold open (Prologue 1), and the pub half becomes Prologue 2. `buyer`, `james_meeting` → Prologue 3–4.
- `home_raid_intro` + debriefs → Prologue 7 (first win). The debrief is rewritten to set the deposit goal.
- `archie_cultivation` → Prologue 8.
- Collective act 1 (prospecting, seeding, Nadia, Hakim) → Arc A. The Collective as a faction → E1.
- Collective act 2 (defend, guards, intel, losses) → split between late A and E2.
- Business act 1 → Arc C, mostly intact.
- James dial evaluation proposal (`.scratch/writing-revamp/`) → Arc B capstone.

## Open questions

1. **Act 1 mentors.** Leaning towards introducing some faction characters as Act 1 mentors, so that by Act 2 the player already knows how these people fit into the world. Owner to think through.
2. **Act 2 mentors.** Existing contacts, new ones, or faction characters met in Act 1?
3. **E1 lead faction.** The faction controlling your first vein's district (varies by run), or fixed?
4. **Act 2 unlock.** Any 2 of A/B/C, all 3, or a net-worth threshold?
5. ~~Combat dependency~~ — resolved: the combat rework has landed, and the Prologue needs build items 1–3 above first.
6. **Act 1 shape (parked until the Prologue is right).** Proposal: replace "three parallel arcs" with a **spine**, "The Firm comes for Whitechapel" (Hakim/Nadia humanising → the lieutenant at the yard → escalation → beat him → mirror reveal → boss meeting/influence). Each spine beat is gated on something from A/B/C (a crafted kit from B, an affordable guard from C, a second safe vein from A). The player picks the order inside a gate.
7. **The squeeze buyer's identity.** Another faction, the Conclave, a City firm? Decide before Act 2.
8. ~~Names~~ — resolved for the lieutenant (**Nick**) and the gym owner (**Arnie**/Reginald); see Motivation spine. The Firm boss is still unnamed.
