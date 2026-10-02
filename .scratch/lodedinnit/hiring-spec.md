# LodedInnit — hiring app design spec (ticket 17)

Status: **approved by the human 2026-10-02.** Tickets are cut from this spec with the to-tickets skill.

PROSE-REVIEW: all names, headlines, posts and taglines are draft content against `docs/CONTENT-GUIDE.md`.

---

## 1. Decisions

| # | Decision |
|---|---|
| C1 | App name **LodedInnit** — LinkedIn parody: lode (ore vein) / loaded + London "innit". Mocks LinkedIn and how people use it. |
| C2 | Unlock: gated behind the Business Act 1 questline. The app unlocks when James joins (`bizA1JamesJoined`), so the pot already exists whenever hiring is possible. |
| C3 | Staff wages come from the business (pot, then float) once Owen is unlocked — **never from player cash**. |
| C4 | Fixed hand-written roster, always listed in the app. No hire requirements — **pay is the only gate**. |
| C5 | Each candidate's status flips at random between "Open to work" and "Employed at {faction}", roughly once every 2 weeks per person. |
| C6 | The player may poach an employed candidate at a premium wage, costing relation with that faction. |
| C7 | Factions try to poach the player's employees. Match or lose, with a capped counter and limited attempts per employee. |
| C8 | Multiple staff per role room. Capacity comes from room upgrades, gated by HQ tier. |
| C9 | Wage is per-candidate and rises with level. No signing fee. |
| C10 | Personality is mainly flavour (feed voice), sometimes backed by a trait with a gameplay effect. |
| C11 | Faux news feed: **one post per time block**, plus hire-status posts. Fake likes/comments as flavour. |
| C12 | Staff don't test the player by text. Humour and flavour live in the feed, not in Messages. |
| C13 | Let go is allowed; the person returns to the market. |
| C14 | The level cap is shown on profiles. |
| C15 | Security: registry slot reserved only, designed later. |
| C16 | Feed authors are **individuals only** (candidates and hires). Faction and faux-company posts come in a later pass. |

## 2. Role registry

`data/hiring.json` → `roles`; adding a role later is a data entry:

```json
"roles": {
  "cultivation": { "label": "Cultivator", "room": "veinStation", "skill": "cultivating", "enabled": true  },
  "production":  { "label": "Crafter",    "room": "lab",         "skill": "crafting",    "enabled": true  },
  "sales":       { "label": "Sales",      "room": "ops",         "skill": "sales",       "enabled": false },
  "security":    { "label": "Security",   "room": null,          "skill": null,          "enabled": false }
}
```

`Contacts.ROOM_ROLES` and `Payroll.ROLE_SKILL_KEYS` read this instead of hardcoding it. A disabled role's candidates are not listed. Adding the crafter role is a registry/data entry only (plus ticket 10's speciality rule); it needs no special-casing in code.

## 3. Candidates

Each candidate is a contact-defaults entry, merged into `CONTACTS_DEFAULTS` at boot and pre-seeded `unlocked:false, recruited:false` like Des/Nadia. It also carries a `hiring` block:

| Field | Meaning |
|---|---|
| `name`, `headline`, `about` | profile text (`Contacts.display_name()` falls back to `name`) |
| `role` | registry id |
| `startLevel` | role skill at hire (`<skill>Skill`, XP set to that rung of the ladder) |
| `skillCaps[skill]` | level cap (existing field, honoured by `award_contact_xp()`; shown on profile) |
| `specialities` | crafters: ore list, using ticket 10's rule and field name |
| `baseWage`, `wagePerLevel` | weekly wage = `baseWage + wagePerLevel × (level − startLevel)` |
| `trait` | optional, §7 |
| `voice` | post-pool tag for §6 |

Roster:

| id | Name | Role | Lvl → Cap | Specialities | £/wk base (+/lvl) | Trait | Headline |
|---|---|---|---|---|---|---|---|
| `marcia` | Marcia Odunsi | Cultivator | 2 → 4 | — | 300 (+60) | — | "Allotment secretary, 14 yrs. Open to discreet horticulture." |
| `tomasz` | Tomasz Wójcik | Cultivator | 1 → 5 | — | 200 (+60) | eager | "Landscaping grad. Hungry. Will learn anything." |
| `bernie` | Bernie Kale | Cultivator | 3 → 3 | — | 420 (—) | — | "Forty years in the trade. Not here to learn." |
| `saoirse` | Saoirse Flynn | Cultivator | 2 → 5 | — | 320 (+70) | distracted | "Ex-cooperative grower. Left on good terms. Mostly." |
| `priya` | Priya Sandhu | Crafter | 2 → 4 | physics | 320 (+60) | — | "Materials engineer, formerly of a firm she won't name." |
| `dot` | Dot Mayhew | Crafter | 1 → 4 | life, emotion | 220 (+60) | — | "Herbalist. Market stall, Deptford." |
| `gideon` | Gideon Achterberg | Crafter | 3 → 5 | time | 480 (+80) | — | "Horologist. Guild-trained. Expensive, and worth it." |
| `ray` | Ray Okafor-Bell | Crafter | 2 → 3 | fate, emotion, time | 300 (+50) | distracted | "Jack of all trades. Ask around." |

## 4. Market status, hiring, poaching

Numbers live in `data/hiring.json` `market`.

### 4.1 Status
`state.hiring.status[id] = { state: "open" | "employed" | "ours", employer: factionId | null, since: day }`.
- At each rollover, every non-`ours` candidate flips with chance `flipChancePerDay` = 1/14 (mean of about 2 weeks between flips).
- Employers are **factions only**. On a flip to employed, the faction is picked at random.
- Every status change generates a hire-status post (§6.3).

### 4.2 Hiring
- **Open:** wage = `baseWage`. Gate = the role room has a free seat (§5).
- **Employed (poach):** wage × (1 + `poachPremium` 0.25); relation with the employer faction −`poachRelationCost` 8.
- **Payment:** the first week's wage is drawn from the pot, then the float. If pot + float are short, the player is asked "Top up the float by £X to cover this hire?". Yes = `Business.donate(X)` from cash, then the hire goes through; No = no hire.
- **On hire:** `unlocked`/`recruited` set true; the skill is set to `startLevel`; they are seated in the role room; a `business.wages[id]` entry is created (Owen's mechanism: `weekly`, `owed`, `unpaid`, `hiredDay`, `daysWorked`, `promptPending`). They are paid at the Monday payday from the pot, then the float. `weekly` updates when they level.
- **Let go:** vacate the seat, release their `cultivatorVeins`, remove the wage entry (prorated owed settled at the next payday). Status → `open`.

### 4.3 Factions poaching your staff
- Per employee, a weekly chance `poachChance` 0.1 that one faction makes an offer. The faction is weighted toward Hostile / Business-rival stance. At most `maxPoachAttempts` 3 per employee, ever.
- Offer: +`poachOfferPct` 20%, raised as a BizBrief alert with 1 day to respond: "Match (£X/wk)" or "Let them go". The match is capped at `counterCapPct` 25% above the current wage; the offer never exceeds that cap, so the player can always match.
- Declined or unanswered after 1 day → the employee leaves; status `employed` at that faction; hire-status post.

## 5. Rooms and seats

- `state.home.roomSeats { roomId: int }`, default 1. Seat upgrades are defined in `data/home.json` `rooms.<id>.seatUpgrades: [{ seats, cost, minTier }]` and bought from the HQ room card.
- Max seats per HQ tier: Vein Cultivation Station — safehouse 1 / compound 2 / mansion 3. Improved Lab — compound 2 / mansion 3 (built with 1 seat; upgradable to 2 at compound). Each extra seat costs 50% of the room's build cost (Station £4,000, Lab £7,500).
- `Contacts.get_contact_in_room()` (single occupant) becomes `contacts_in_room()`; `assign_to_room()` stops evicting while seats are free.
- Founders are unaffected (they hold no seat).

## 6. Feed

### 6.1 Authors
- Individuals only: candidates and hires, each with their own `voice` pool and trait-flavoured variants (e.g. `distracted` posts trail off mid-thought). Comments come from other individuals.
- Each post records its author `kind`, so faction and faux-company posts can be added later without rework.

### 6.2 Cadence
One post per time block, rolled at the staff block step (`Rng`, Rewind-safe), from a weighted pool of authors whose posts aren't used up. A post isn't repeated until its author's pool is exhausted.

### 6.3 Hire-status posts
Triggered (in addition to the per-block post) by: hired by you, let go, poached by/from a faction, flip to employed or open. Templates per event kind, filled with `{name}`/`{employer}`.

### 6.4 Likes / comments
Each post gets a rolled likes count and 0–2 canned comments from other individuals. Display only — no gameplay.

### 6.5 Texts
Hires get no Messages threads or quiz texts. The ticket-11 random-texts system is not used for hires.

## 7. Traits

Data in `data/hiring.json` `traits`; one number each. Most candidates have no trait.

| Trait | Effect | Feed flavour |
|---|---|---|
| `distracted` | skips its block action with chance 0.2 | posts wander onto tangents |
| `eager` | role XP × 1.25 | over-enthusiastic hustle posts |

## 8. Wages and the business

- `Payroll.pay_wages()`'s room-wage path (player cash, Mondays) is **removed**. All staff wages go through the business payday.
- The payday shortfall prompt in BizBrief, "Pay from your own cash?" (`Business.pay_owed_from_cash`), is **replaced** by a prompt to top up the float, consistent with §4.2.

## 9. Save shape

```
hiring: {
  status: { id: { state, employer, since } },
  poach: { id: { attempts, pending: { factionId, offer, expiresDay } | null } },
  feed: [ { postId, authorKind, author, day, block, likes, comments: [commentId] } ],   # capped at 50
  feedSeen: int                                                                         # badge = entries after this
}
home.roomSeats: { roomId: int }
```

Pure data. Old saves are backfilled (status from data defaults, empty feed, 1 seat per room).

Integration: new `data/hiring.json`, `data/lodedinnit.json` (post pools), `systems/hiring.gd`, `systems/lodedinnit_feed.gd`, the app scene. Touched: `GameData`, `Contacts`, `Business`, `Payroll`, `Rooms`, `TimeSystem` (rollover flips, weekly poach rolls, per-block post), `PhoneApps`/`PhoneAppRegistry`/`PhoneNav`, the HQ room card (seats, let go), BizBrief (poach alert, float top-up prompt), REFERENCE §2/§3.10, CODEMAP.

## 10. Resolved at ticket cut (2026-10-02)

| # | Decision |
|---|---|
| R1 | Hire prepays the first week. The wage entry gets `paidThroughDay = hireDay + 7`; payday charges only the days worked after it. |
| R2 | The poach premium and a matched counter are permanent: `wageMult` on the wage entry; weekly = round(formula × wageMult). |
| R3 | Let go flags the wage entry `leaving`; the next payday pays the prorated owed, then deletes the entry. |
| R4 | Level persists after let go or poach. Re-hire wage = the full formula at current level (× premium if employed). |
| R5 | Employer pool = every faction in `state.factions` that isn't eliminated, Collective included. |
| R6 | Prose volume: ~6 posts per candidate, 2 trait variants each, 2 templates per hire-status kind, ~12 shared comments. |
| R7 | An unanswered poach alert resolves once a full day has passed: `expiresDay = offerDay + 2`, resolved at that rollover, so the player has all of the next day to answer. |
| R8 | Profiles show ore-speciality pips for every candidate. Cultivators get a `specialities` list too: flavour only for now, with a gameplay effect to be added later. Draft lists: marcia life · tomasz physics · bernie life, physics · saoirse fate, emotion (confirmed by the human 2026-10-02). |
| R9 | The app has two tabs, Feed and People, plus a profile view, in the phone visual family. |
| R10 | A `distracted` producer skips its whole block of crafting. Old saves have no non-founder room occupants, so removing the cash wage path needs no migration beyond dropping `payroll` state. |
