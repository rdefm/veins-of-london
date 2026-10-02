# LodedInnit — hiring app design spec (ticket 17)

Status: **draft, awaiting human approval.** Ticket 18 does not start until §11 is resolved.

Convention: items marked **CONFIRMED** are the human's decisions (2026-10-02). Items marked **PROPOSED** are drafts awaiting sign-off — nothing PROPOSED is decided.

PROSE-REVIEW: all names, headlines, posts and taglines are draft content against `docs/CONTENT-GUIDE.md`.

---

## 1. Confirmed decisions

| # | Decision |
|---|---|
| C1 | App name **LodedInnit** — LinkedIn parody: lode (ore vein) / loaded + London "innit". Mocks LinkedIn and how people use it. |
| C2 | Unlock: gated behind the Business Act 1 questline — the app unlocks when James joins (`bizA1JamesJoined`), so the pot already exists whenever hiring is possible. |
| C3 | **All staff wages come from the business pot.** |
| C4 | Fixed hand-written roster, always listed in the app. No hire requirements — **pay is the only gate**. |
| C5 | Each candidate's status flips at random over time between "Open to work" and "Employed at X". |
| C6 | The player may poach an employed candidate at a premium wage. Poaching from a faction costs relation with that faction. |
| C7 | Factions try to poach the player's employees. Flow = match or lose: the faction offers +X%; the player may raise the wage up to a capped %, or the employee leaves. Attempts per employee are limited. |
| C8 | Multiple staff per role room. Capacity comes from room upgrades, and the upgrades are gated by HQ tier. |
| C9 | Wage is per-candidate and rises with level. No signing fee. |
| C10 | Personality is mainly flavour (feed voice). Sometimes it is backed by a trait with a gameplay effect, e.g. `distracted` lowers efficiency and their posts wander off on tangents. |
| C11 | Faux news feed: posts from candidates, faux businesses and factions, **one post per time block**, plus hire-status posts. Fake likes/comments as flavour. |
| C12 | Staff don't test the player by text. Humour and flavour live in the feed, not in Messages. |
| C13 | Let go is allowed; the person returns to the market. |
| C14 | The level cap is shown on profiles. |
| C15 | Security: registry slot reserved only, designed later. |

## 2. Role registry (PROPOSED shape)

`data/hiring.json` → `roles`; adding a role later is a data entry:

```json
"roles": {
  "cultivation": { "label": "Cultivator", "room": "veinStation", "skill": "cultivating", "enabled": true  },
  "production":  { "label": "Crafter",    "room": "lab",         "skill": "crafting",    "enabled": true  },
  "sales":       { "label": "Sales",      "room": "ops",         "skill": "sales",       "enabled": false },
  "security":    { "label": "Security",   "room": null,          "skill": null,          "enabled": false }
}
```

`Contacts.ROOM_ROLES` / `Payroll.ROLE_SKILL_KEYS` then read this instead of hardcoding it. A disabled role's candidates are not listed.

## 3. Candidates (PROPOSED shape + roster)

Each candidate is a contact-defaults entry (merged into `CONTACTS_DEFAULTS`, pre-seeded `unlocked:false, recruited:false` like Des/Nadia) plus a `hiring` block:

| Field | Meaning |
|---|---|
| `name`, `headline`, `about` | profile text |
| `role` | registry id |
| `startLevel` | role skill at hire (`<skill>Skill`, XP set to that rung) |
| `skillCaps[skill]` | level cap (existing field, shown on profile per C14) |
| `specialities` | crafters: ore list, per ticket 10's rule/field name |
| `baseWage`, `wagePerLevel` | weekly wage = `baseWage + wagePerLevel × (level − startLevel)` (C9) |
| `trait` | optional, §5 |
| `voice` | post-pool tag for §6 |

Draft roster (all PROPOSED: names, levels, wages):

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

Owen's £250 is the reference point for wages.

## 4. Market status, hiring, poaching

### 4.1 Status (C5)
`state.hiring.status[id] = { state: "open" | "employed" | "ours", employer: factionId | businessId | null, since: day }`.
- **PROPOSED:** on each Monday rollover, every non-`ours` candidate flips with chance `flipChance` (0.25). On a flip to employed, the employer is a random faction or faux business.
- Changes of status generate hire-status posts (§6.3).

### 4.2 Hire (C4, C6)
- **Open:** Hire = wage at `baseWage`. Gate = the pot can cover the first week (**PROPOSED** check; C3) and the role room has a free seat (C8).
- **Employed:** Poach = wage × (1 + `poachPremium`) (**PROPOSED** 0.25). If the employer is a faction, relation with it −`poachRelationCost` (**PROPOSED** 8). If the employer is a faux business, there is no relation effect (no such stat).
- On hire: `unlocked/recruited = true`, the skill is set, they are seated in the role room, and a `business.wages[id]` entry is created (Owen's mechanism: `weekly`, `owed`, `unpaid`, `hiredDay`, `daysWorked`, `promptPending`) — paid at the Monday payday from the pot (C3). `weekly` updates when they level.
- Let go (C13): vacate the seat, release `cultivatorVeins`, remove the wage entry (prorated owed settled at the next payday). Status → `open`.

### 4.3 Factions poaching your staff (C7)
- **PROPOSED:** per employee, a weekly chance `poachChance` (0.1) that one faction makes an offer. The faction is weighted toward Hostile/Business-rival stance (fits Pressure/Escalation). Max `maxPoachAttempts` (3) per employee, ever.
- Offer: +`poachOfferPct` (**PROPOSED** 20%). Notification and LodedInnit inbox card: "Match (£X/wk)" or "Let them go". The player may match up to `counterCapPct` (**PROPOSED** 25%) above the current wage — the offer never exceeds that cap, so the match is always possible if the player wants it.
- Decline → the employee leaves; status `employed` at that faction. Feed post (§6.3).
- **Open:** does the offer expire after N blocks, and what happens if it is ignored (OQ-4)?

## 5. Rooms and seats (C8)

- **PROPOSED:** `state.home.roomSeats { roomId: int }`, default 1. Upgrade costs and max seats per HQ tier go in `data/home.json` `rooms.<id>.seatUpgrades: [{ seats, cost, minTier }]`, bought from the HQ room card.
- Impact: `Contacts.get_contact_in_room()` (single occupant) becomes `contacts_in_room()`; `assign_to_room()` stops evicting while seats are free; Payroll's room-keyed wage records stop applying to hires (all hire wages go through the pot, C3).
- Founders are unaffected (they hold no seat).

## 6. Feed (C10–C12)

### 6.1 Authors
- Candidates (their `voice` pool; trait-flavoured variants, e.g. `distracted` posts trail off mid-thought).
- Factions (speaker-voiced, or as the corporate faction account — OQ-6).
- Faux businesses: **PROPOSED** a small set of parody London firms in `data/lodedinnit.json` `businesses` (names TBD — OQ-7). They are also employers for §4.1.

### 6.2 Cadence (C11)
One post per time block, rolled at the staff block step (`Rng`, Rewind-safe), from a weighted pool of authors whose posts aren't used up. **PROPOSED:** a post isn't repeated until its author's pool is exhausted.

### 6.3 Hire-status posts
Triggered (in addition to the per-block post) by: candidate hired by you, let go, poached by/from a faction, flip to employed or open. Templates per event kind with a `{name}`/`{employer}` fill.

### 6.4 Likes / comments (flavour)
Each post gets a rolled likes count and 0–2 canned comments from other authors (comment pool per author). Display only — no gameplay.

### 6.5 Texts
Hires get no Messages threads or quiz texts (C12). The ticket-11 random-texts system is not used for hires.

## 7. Traits (C10, PROPOSED list)

Data in `data/hiring.json` `traits`; one number each:

| Trait | Effect | Feed flavour |
|---|---|---|
| `distracted` | skips its block action with chance 0.2 | posts wander onto tangents |
| `eager` | role XP × 1.25 | over-enthusiastic hustle posts |

Most candidates have no trait.

## 8. Save shape (PROPOSED)

```
hiring: {
  status: { id: { state, employer, since } },
  poach: { id: { attempts, pending: { factionId, offer, expiresDay } | null } },
  feed: [ { postId, author, day, block, likes, comments: [commentId] } ],   # capped (e.g. 50)
  feedSeen: int                                                             # badge = feed entries after this
}
home.roomSeats: { roomId: int }
```

Pure data; old saves are backfilled (status from data defaults, empty feed).

## 9. Integration summary

New: `data/hiring.json`, `data/lodedinnit.json` (feed/businesses), `systems/hiring.gd`, `systems/lodedinnit_feed.gd`, the app scene. Touched: `GameData`, `Contacts` (registry read, multi-seat rooms, `name` fallback in `display_name`), `Business` (hire wage entries, level-up wage update), `Rooms` (seats), `TimeSystem` (Monday flips/poach rolls; per-block feed post), `PhoneApps`/`PhoneAppRegistry`/`PhoneNav`, the HQ room card (seats, let go), REFERENCE §2/§3.10, CODEMAP.

## 10. Ticket split (PROPOSED re-cut)

The current 18/19 split doesn't cover the feed, poaching or seats. Suggested:
- 18 Cultivator hire end to end (registry, roster data, open-status hire, pot wages, let go, one seat)
- 19 Crafter role (data only + specialities)
- new: Room seat upgrades
- new: Market status flips + player poaching
- new: Faction poaching + match-or-lose
- new: LodedInnit feed (block posts, hire-status posts, likes/comments)

## 11. Open questions

| # | Question |
|---|---|
| OQ-1 | All the PROPOSED numbers: flip chance, poach premium, relation cost, faction poach chance/offer/cap/attempts, wages. |
| OQ-2 | Roster: names, levels, caps, specialities, wages in §3 OK? Size (4+4) OK? |
| OQ-3 | Payroll's room-wage path now has no users (founders draw no room wage; hires are pot-paid). Retire it? |
| OQ-4 | Faction poach offer: expiry window, and what happens if ignored (they leave? they stay?) |
| OQ-5 | Hire gate when the pot is short: block the hire, or allow and let payday shortfall rules apply? |
| OQ-6 | Faction posts: from the speaker key member (Nadia etc.) or a faceless faction account? (CONTEXT.md: faction messages always come from the speaker.) |
| OQ-7 | Faux business names: want to supply them, or should I draft a list for review? |
| OQ-8 | Seat upgrade costs/max seats per tier. |
| OQ-9 | Ticket re-cut in §10 OK? |
