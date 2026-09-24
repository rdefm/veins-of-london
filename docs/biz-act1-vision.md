# Business Empire, Act 1 — vision

**Status:** Vision agreed in conversation; not an implementation spec. Use this to
write tickets and settle the open rules below before changing mechanics.

**Working title:** Business Empire, Act 1. The business has no in-world company
name yet.

## Purpose

Turn the player's second vein into the start of a business that works while the
player does other things. The arc teaches a three-part operation: Owen maintains
the supply, James makes products, and Archie finds buyers and fulfils contracts.
The player chooses veins, contracts, assignments, and investments. The ending
proves the operation can complete two recurring contracts without player labour.

This arc starts after Collective Act 1 and runs **in parallel** with Collective
Act 2. The Collective gave the second vein without conditions; this business
creates no conflict with that gift. Guild involvement is reserved for a possible
next business act.

## Story spine and quest progression

| Beat | Story | Player goal / unlock |
|---|---|---|
| 1. The proposition | After Collective Act 1, Archie points to the second vein: two sources could support a business rather than another job for the player. He takes the player to James. Archie proposes that he handle sales, James production, and the player sourcing and cultivation. James turns an **ordinary** small hourglass while considering it. He wants proof of a reliable market reputation and a serious investment before agreeing. | Opens the business quest. Existing BizBrief contract completions already count toward James's test. |
| 2. Market proof | Archie introduces BizBrief offers and contracts. He sources work; the player accepts and delivers the goods. | Complete **any three** BizBrief contracts. Earlier completions count. Archie supplies reliable starter offers so random offer rolls cannot strand a new player. Before the partnership, existing contract proceeds belong to the player. |
| 3. James's answer | James has heard that the player is building a reputation for being less than completely hopeless. He introduces Owen, a young, keen Guild apprentice placed in cultivation. James has quietly arranged this work outside Owen's usual Guild path. | Recruit Owen through this story, not a relation threshold. Open BizBrief's **Staff** tab and introduce cultivation assignments. |
| 4. A working supply | Archie shows the player how to assign Owen to owned veins in BizBrief. Owen gains experience by working, gradually becoming more capable. | Raise Owen's cultivating skill to **level 2** and own the existing **Workshop** room (the £800 room available in a flat). A Workshop built earlier counts. |
| 5. The partnership | Seeing completed contracts, Owen's progress, and the Workshop, James agrees. The agreement is informal: player, Archie, and James each take one third of the business's distributable contract proceeds. James joins as a recruited contact through this event. | Unlock James's BizBrief production role, the partnership settlement rule, and Archie's explanation of recurring contracts. James's old relation-based recruitment gate is replaced by this quest. |
| 6. Put it to work | Archie demonstrates a recurring order and delegation. The first guaranteed recurring offer is for **Time Pearls**, requiring Owen's supply, James's production, and Archie's delivery. A suitable second recurring offer must also be reliably available, with player choice of which offer to take. | Accept, configure, and delegate two recurring BizBrief contracts. Each must complete and pay out **at least one period** through the assigned team, with no manual sourcing, cultivation, crafting, stock top-up, or delivery in the qualifying period. |
| 7. Proof | BizBrief shows both completed periods, Owen's wage, and the resulting three-way payout. Archie is excited that they are building something bigger. James gives minimal acknowledgement beneath his usual grumpiness. | Arc complete. The operation remains running; future expansion has a clear purpose. No Guild contract channel or invitation is granted here. |

The three-contract test recognises work the player did before Archie's pitch.
The story should acknowledge an already proven reputation rather than demand
three repeat contracts. Owen's level and Workshop checks are likewise live
state checks, not forced repetitions.

## Owen

Owen is a named, recurring character, not a generic hire. He is young, eager,
reliable, and grateful for a wider opportunity; his dialogue **alludes** to
that gratitude without explaining the Guild hierarchy. James's blunt
assessment of Owen's limited technical ceiling is substantially correct. His
value lies in persistence and eventual versatility. On the game's existing
five-level ladder, Owen caps at **level 3 in cultivating and crafting**. The
quest needs level 2 cultivating, not level 3.

James's arrangement is quiet, not a formal Guild placement for the player's
business. Owen initially works in cultivation. He may later train for and be
assigned to crafting only after **all three** conditions hold: cultivating
level 2, James recruited, and the existing **Vein Cultivation Station** bought.
That transition merits its own event card. It is a later progression beat, not
a requirement for this act's ending. Owen can hold only one role at a time.

**Background for later Guild stories, not exposition for Owen in Act 1:** the
Guild's pecking order runs from secretive Dials, through calc research and calc
crafting, down to cultivation. Few people know enough about Dials to describe
that top rung. Traditional cultivation apprenticeship offers Owen little path
upward. James's side arrangement can eventually teach him crafting. Guild
consequences and contacts belong to a later business act.

## The starter operation

The first team operates through BizBrief **without** requiring the Operations
Room, Vein Cultivation Station, or Improved Lab. Archie works Sales, Owen
Cultivation, and James Production after he joins. The existing Workshop is a
partnership milestone, not the gate for Archie or Owen to start working.
Later facilities allow more staff and expand sales, cultivation, and production
capacity; their precise scaling belongs in later tickets.

Each of Archie, James, and Owen has **three independent daily work blocks**.
Their work does not consume the player's three blocks. James uses his blocks
for production; Archie uses his for sourcing and delivery. Exact per-block
actions, offer timing, and ordering need specification.

Owen works across **any veins the player assigns**, with no fixed vein-count
cap. For each work block he re-evaluates the assigned veins and prioritises
the one with the lowest growth. He cultivates when needed and harvests what he
can without leaving a vein at or below **50 growth**. His skill determines how
much progress the three blocks can achieve; a weak apprentice may not keep up
with many veins. The detailed cultivate/harvest chooser and tie breaks need a
ticket against the existing growth and prune rules in `docs/REFERENCE.md`.

BizBrief gains a **Staff** tab showing recruited people, current roles, skills,
experience, caps, and pay terms, drawing from the existing contact state. It
does not create a second employee roster. Archie is recruited by the home raid
tutorial; James by this arc; Owen by James's introduction. Future contacts may
still use relation-based recruitment. Owen has no combat role in this vision.

## Contracts and money

Archie guarantees enough starter offers to teach BizBrief and keep the
three-completion test possible, but **any** three completed BizBrief contracts
count. Acceptance stays the player's decision. The first guaranteed recurring
offer is a Time Pearl order; at least one of the two qualifying contracts must
need James's production. The second can be selected by the player, with a
reliable suitable offer available. Their exact quantities, cadence, deadlines,
and prices must be balanced and specified in tickets.

Once James joins, **all BizBrief contract settlements** enter the partnership
calculation. Independent sales outside BizBrief do not. Archie and James take
shares rather than wages. Owen costs **£250 per week** while assigned; later
hireable NPCs also have wages, with their rates left for future design.
Actual cash expenses of the business, including wages and calc purchased for a
contract, are deducted before the remainder is divided equally among player,
Archie, and James. Calc produced from the player's own veins is **not** bought
from the player or assigned an imputed cash cost.

BizBrief keeps an **automatic weekly ledger**: contract receipts, paid business
expenses, and the resulting split. It pays the player their share at weekly
settlement. There is no player-managed business bank account, retained-earnings
control, or reinvestment slider in this act. The existing payroll principle
continues: if a worker cannot be paid, they do not work; they stay assigned
and incur **no wage debt**. Weekly wage timing, any player cash advance and its
reimbursement, and how a short week is displayed need exact ticket rules.
Introductory contract values must be tested against Owen's £250 weekly wage so
two realistically completable recurring contracts can produce a positive
player payout.

## Narrative and interface guardrails

- The partnership is a practical, informal arrangement, not a named company.
- The hourglass James turns is an ordinary object, not Rewind or a Dial reveal.
- Archie is visibly excited by scale. James cares but shows it through precise,
  grudging approval rather than enthusiasm.
- Owen's gratitude and ambition are legible through behaviour. His full Guild
  background remains reference material for later quests.
- Keep the BizBrief teaching in the action: offer, acceptance, delivery,
  assignment, production, delegation, settlement. Avoid exposition that
  merely recites the interface.
- New dialogue and event prose are drafts subject to `docs/CONTENT-GUIDE.md`
  and the character voice guide. This document fixes beats, not final lines.

## Ticketing boundaries and open rules

This vision intentionally leaves implementation details for a follow-on spec
and tickets. In particular:

1. Replace Archie and James's relation recruitment gates with their story
   events, including safe handling of saves where either is already recruited.
2. Decide how the starter roles coexist with the current room-based assignment
   model and daily `£100 + £50 × (skill − 1)` payroll, without changing future
   recruits accidentally.
3. Specify each worker's block actions, order, XP awards, Owen's growth/harvest
   chooser, production attempts, and sales delivery limits.
4. Specify the starter and recurring offer catalogue, guaranteed delivery,
   expiry/replacement, balance, and how historical completions are counted.
5. Specify weekly settlement day, expense attribution, wage advance/recovery,
   shortage presentation, rounding, and save-safe accounting. The vision's
   economic outcome is authoritative; the arithmetic belongs in the spec.
6. Define the exact objective checks for a fully unattended completed contract
   period, including how manual intervention is tracked and how the recurring
   period renews after a qualifying completion.
7. Add Staff presentation and event beats; preserve one-way data flow and the
   existing single contact state tree.
8. Test the full path alongside Collective Act 2, including players who built
   a Workshop or completed three contracts before the pitch.

Guild-sourced contracts, higher-volume and quality-sensitive orders, Guild
membership, more hires, expanded facilities, retained earnings, and Owen's
crafting event are **later business-arc material**. They are not unlocks or
completion requirements of Act 1.
