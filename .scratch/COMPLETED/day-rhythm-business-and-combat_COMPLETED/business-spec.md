# Business specification

Status: partially specified. The rules below are human-approved. Items in
"Open decisions" are deliberately not implementation authority.

## BizBrief and terminology

BizBrief gains two tabs: **Brief** (the existing morning-account view) and
**Manage**. Manage has three sections:

- **Sales:** pending offers, acceptance, active-contract reference/history,
  delegation, and contract priority.
- **Production:** crafted-item inventory targets and the option to cover
  accepted-contract needs.
- **Procurement:** the existing Vein Station selection/target controls.

All staff are recruited contacts. Archie, James, and future recruitable
contacts use the same contact, XP, and assignment model; there is no separate
employee or faction-member state model. A contact has at most one assignment:
a Sales, Production, or Procurement assignment replaces any room assignment,
and vice versa.

The role gates are the matching installed rooms, with one contact per room:

| Role | Required room | Skill |
|---|---|---|
| Sales | Operations Room | new `salesSkill` / `salesXP` |
| Production | Improved Lab | existing `craftingSkill` / `craftingXP` |
| Procurement | Vein Cultivation Station | existing `cultivatingSkill` / `cultivatingXP` |

## Inventory

The player has a shared stockpile and a personal stash for ore and crafted
items. Moving stock between them is instant and reversible. Personal-stash
stock is never available to contracts, Sales, Production, or Procurement.
There is no second per-item reserve setting: the personal stash is the sole
reserve mechanism.

## Offer and contract types

There are two contract types:

- **Recurring:** fixed request, weekly cadence, and a fixed weekday supplied
  by its template. It repeats after every settled period.
- **One-off:** one period only; completion or deadline settlement closes it.

Offers may be scripted or randomly generated from authored templates. The
player always explicitly accepts; Sales may source offers but never accepts
them. Pending, unaccepted offers are capped at four; accepting moves an offer
into the active Sales ledger and frees its pending-offer slot. Random offers
expire 3–14 days after appearing. Scripted-offer expiry is authored.

When fewer than four pending offers exist, at most one random offer may appear
per day. The chance is `20% + 10% × (salesSkill − 1)`, capped at 60%; an
unassigned Sales role uses skill 1. Declining or expiry frees the slot.

An accepted random one-off has a base deadline 3–7 days after acceptance.
Scripted one-offs author their own deadline. A recurring template's first due
date is the next occurrence of its weekday strictly after acceptance; accepting
on that weekday means the first due date is seven days later. The initial
recurring cadence is weekly only.

Requests normally contain one item type. Mixed requests are allowed only for
one-offs. Each requested type carries its own quantity; every extra type adds
two days to the one-off deadline and a 20% payment bonus. Initial quantity
bands are:

| Request | Units per requested type |
|---|---:|
| weekly recurring | 3–6 |
| single-type one-off | 4–10 |
| each type in a mixed one-off | 2–5 |

## Market quote and payment

Each offer snapshots every unit value and its total payment when the offer is
created. Acceptance and later settlement never reprice it.

- An ore unit uses the current Barometer-effective ore price.
- A crafted item's base is its `CONSUMABLE_PRICES` value. Its dynamic modifier
  is the ingredient-quantity-weighted average of the current modifiers of its
  recipe's ore types. Thus a single-ore recipe inherits that ore's modifier;
  mixed recipes reflect every ingredient proportionally.
- Crafted quality tiers do not affect contract eligibility or price; any tier
  may fulfil the requested crafted item.
- Total quoted payment is rounded to whole pounds after applying: requested
  live value, a 125% contract multiplier, +20% for each requested type after
  the first, and +5% for each Sales level above 1. Sales level 1 has no value
  bonus. The Sales bonus is determined at offer creation.

## Fulfilment and settlement

A contract tracks delivered quantity separately for every requested type.
Manual delivery costs no time, whatever its quantity or number of requested
types. It may be partial. Manual delivery is available only for non-delegated
contracts; delegation is an exclusive Sales automation assignment.

Any delivery (manual or Sales) that leaves nothing remaining settles the
period immediately for the full snapshotted quote: a one-off closes, a
recurring contract renews into its next weekly period. The due-day tick never
pays that period again.

Sales has no delivery-cap limit. It handles every delegated contract in its
player-set priority order. The player drag-reorders active contract cards; that
single order controls Production allocation and Sales partial delivery whenever
stock cannot satisfy every contract.

After every increase in shared stock (including crafting, Procurement, or
unstashing), paid Sales immediately rechecks delegated contracts. If all
remaining requested types for one can be supplied, it delivers them and closes
that period immediately. At daily rollover, Sales also makes partial deliveries
from available shared stock in priority order.

At deadline, an incomplete
contract settles for `quote × delivered proportion × 0.80`, rounded to whole
pounds; zero delivery pays £0. A recurring period then creates the next weekly
period even when the previous period was short. A one-off closes permanently.

For a mixed one-off, delivered proportion is quoted-value weighted:
`Σ(delivered_units × unit_value) / total_quote_value` across every requested
type, using each type's snapshotted per-unit value from offer creation.

## Production and Procurement

Procurement preserves the existing Vein Station behaviour: selected veins and
their growth targets are tended/pruned, and yield enters shared stock.

Production preserves the existing Lab's repeated-attempt model: it keeps
attempting configured crafted-item targets until all targets are met or shared
ore is exhausted. Each attempt uses the assigned contact's existing crafting
chance. Every successful NPC-produced item has quality tier equal to that
contact's `craftingSkill` (skill 1 produces tier 1, and so on).

Production supports personal inventory targets and a toggle to cover accepted
contract needs. Contract needs count only the undelivered quantities of active
current periods, never future recurring periods. When shared ore is scarce,
the contract-card priority order wins, then player-set inventory-target
priority.

Personal target and contract need are **additive and separately reserved**:
Production crafts toward personal-target + contract-need combined (a target
of 5 plus a contract need of 10 means Production crafts to 15). The
personal-target portion of stock is a protected buffer — Sales may only draw
from the contract-need portion to fulfil deliveries, never from the
personal-target reserve.

## Sales XP, wages, and payroll

Sales uses the existing skill threshold ladder `[0, 0, 80, 220, 500, 1000]`.
It earns 5 XP for sourcing an offer, 20 XP for a completed delegated contract,
and 10 XP for a penalised partial settlement. Declined and expired offers earn
no XP.

An assigned role's daily wage is `£100 + £50 × (role skill − 1)`, applied to
all three roles — Sales, Production, and Procurement (Production/Procurement
wages are new costs for assignments that are free before ticket 28; no
migration handling for existing saves). Living costs are paid first.

Grilling decision 1 (ticket 28) replaces this section's original mid-tick
"payroll popup" pause with a "default-then-review" model: if remaining cash
cannot cover every wage, affordable roles are paid automatically, in a fixed
priority order (Production, Procurement, Sales — hq_floorplan.gd's own
room-assignment order), for that rollover; a role that can't be afforded is
simply skipped for the whole rollover — no debt, remains assigned, retried
fresh next rollover — and the result is left as a reviewable summary rather
than a blocking popup the player must clear mid-tick.

The staff phase (after wages) is exactly:

1. Procurement processes Vein Station work.
2. Production crafts effective targets.
3. Sales completes any now-fully-stocked delegated periods, then makes partial
   deliveries in contract priority order.
4. Due periods settle; recurring periods renew.
5. Sales sources at most one new random offer.

This phase replaces the old Lab-then-Vein-Station ordering at daily-tick
step ⑥. It runs after the existing raid/faction processing and before Dial
regen, objectives, accounts completion, `day_ticked`, and autosave. Because
there is no mid-tick pause, there is nothing to resume on reload — payroll
state is just that rollover's serializable result, recomputed fresh every
rollover, so a reload cannot re-charge or re-skip a wage already resolved.

## Persistence and idempotency requirements

Offers, accepted contracts, periods, request-line progress, priority order,
delegation, payroll state, staff assignment, personal stash,
and all quote snapshots are pure serializable state. Every offer, contract,
period, and settlement has a stable id. Settlement records its id before cash
is credited, so a reload/resume/retry cannot pay twice or renew a recurring
period twice.

## Open decisions — do not implement yet

- Exact data catalogue: which scripted/templates exist, their request kinds,
  weekdays, quantity picks within the approved bands, and scripted expiry /
  deadlines.
- Exact migration defaults for saves made before contracts, staff roles,
  personal stash, and resumable payroll exist.
