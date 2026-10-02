# Hiring app — design spec (ticket 17)

Status: **draft, awaiting human approval** — ticket 18 must not start until §12's open questions are answered or the recommended defaults are accepted.

PROSE-REVIEW: everything in quotes or in the Voice/Headline/About columns below is draft prose against `docs/CONTENT-GUIDE.md`.

---

## 1. What it is

A phone app parodying LinkedIn. The player browses a board of named candidates who are "open to work", checks whether they meet each candidate's requirements, and hires one. A hire becomes an ordinary staff **contact**: it takes a role room (Vein Cultivation Station / Improved Lab), works at the staff block step like any room hire, levels through the existing contact-XP ladder up to its own cap, and draws a weekly wage through the existing Payroll path.

No new economy loop. The app is a front door onto machinery that already exists (`Contacts`, `Payroll`, `Rooms`), plus a roster and a board.

## 2. Name and branding

| | Recommended | Alternates |
|---|---|---|
| App label / wordmark | **Graft** | Clocked In · Endorsed · Linkedout |
| Tagline (app header) | "Graft. For people who get things done." | — |
| Registry id | `hiring` (icon at `assets/phone/icons/hiring.png`, ADR 0003) | — |

"Graft" is British slang for hard work and, quietly, for corruption — the right register for hiring people to farm illicit calc. Follows the Reynard's / Harrow's convention: stable functional id, parody brand as label.

Chrome: shared Family 2 dark chrome (`docs/ui-vision.md` §10), `ui_action_red` for Hire, no brand-colour exception. (A Harrow's-style brand exception is possible later; not requested here.)

LinkedIn beats we parody, mapped to real data so none of it is decorative:

| LinkedIn thing | Graft field | Real data behind it |
|---|---|---|
| Headline | `headline` | prose |
| "Open to work" banner | board membership | `state.hiring.board` |
| Skills + endorsements | "Cultivating · 2 endorsements" | start level |
| "Potential" (no LinkedIn equivalent — the joke) | "Ceiling" | `levelCap` |
| Speciality tags | ore chips | `specialities` (crafters) |
| "Looking for" | requirement lines | `requirements` |
| About | `about` | prose |
| Salary expectation | "Expects £X/week" | Payroll wage at start level |

## 3. Role registry

New file `data/hiring.json`, block `roles`. Each role is one entry; code never switches on role id except where a role's *work* already lives (Rooms for cultivation/production).

```json
"roles": {
  "cultivation": { "label": "Cultivator", "room": "veinStation", "skill": "cultivating", "assign": "veins",   "enabled": true  },
  "production":  { "label": "Crafter",    "room": "lab",         "skill": "crafting",    "assign": "recipes", "enabled": true  },
  "sales":       { "label": "Sales",      "room": "ops",         "skill": "sales",       "assign": "none",    "enabled": false },
  "security":    { "label": "Security",   "room": null,          "skill": null,          "assign": "guardPost","enabled": false }
}
```

- `room` → the role room a hire occupies. Today `Contacts.ROOM_ROLES` and `Payroll.ROLE_SKILL_KEYS` hardcode the same mapping; ticket 18 makes both read the registry so there is one source.
- `skill` → which `<skill>Skill`/`<skill>XP` pair is the hire's level and drives their wage.
- `assign` → which existing assignment UI follows a hire (`veins` = cultivatorVeins list, `recipes` = Production list). Purely a pointer for the UI; no new assignment systems.
- `enabled: false` → the role's candidates never appear on the board. Turning on Sales later is a data flip (its work path already exists). Security needs a real design (guards today are anonymous counts, `GuardUpkeep`) — the registry just reserves the slot; see OQ-9.
- Ticket 19's "crafter role as registry/data entry only" acceptance check is met by this shape: production differs from cultivation only in `room`/`skill`/`assign` plus the candidate's `specialities`.

## 4. Candidate roster

Candidates live in `data/hiring.json` block `candidates`, keyed by a stable contact id. Each is a full contact-defaults entry (same fields as `constants.json` `contacts.*`) plus a `hiring` block:

```json
"marcia": {
  "name": "Marcia Odunsi",
  "startRelation": 0, "unlocked": false, "recruitThreshold": 0, "recruitable": false,
  "combatHpMax": 0,
  "skillCaps": { "cultivating": 4 },
  "hiring": {
    "role": "cultivation",
    "startLevel": 2,
    "trait": "steady",
    "headline": "…", "about": "…",
    "requirements": [ { "kind": "room", "room": "veinStation" } ]
  }
}
```

- `GameData` merges `candidates` into `CONTACTS_DEFAULTS` at boot, so `skillCaps`, `specialities` (ticket 10), `roomFreeRoles` etc. are read by existing code unchanged. Candidates have no `roomFreeRoles` — they are room hires, never founders.
- `name` is a new optional contact-defaults field; `Contacts.display_name()` falls back to it before `capitalize()`.
- **Level** = the role skill. On hire, `<skill>Skill = startLevel`, `<skill>XP = ladder[startLevel]`; other skills stay 1. `levelCap` *is* `skillCaps[skill]` — no new field, reuses the cap `award_contact_xp()` already honours (Owen's mechanism).
- **Specialities** (crafters): exactly the field and rule ticket 10 defines for James (a crafter may make an unlocked recipe whose inputs are all within their ore list). This spec assumes ticket 10 names it `specialities: [oreType]` on the contact defaults; if 10 lands with a different name/location, candidates follow 10. Cultivators: none (OQ-6).

### 4.1 Roster (draft — numbers and prose for human sign-off)

Ore-type reach check against `data/recipes.json`: physics → blast/shield/blackHole; fate → beALady; emotion → pansPrank; time+life → pearl/rewind/prophetsBreath/powder/salve + the four dual-ore recipes.

**Cultivators** (role `cultivation`, room `veinStation`)

| id | Name | Lvl → Cap | Trait | Requirements | Headline | Voice |
|---|---|---|---|---|---|---|
| `marcia` | Marcia Odunsi | 2 → 4 | steady | Station built | "Allotment secretary (Lewisham, 14 yrs). Open to discreet horticulture." | Brisk, practical, signs off "M." |
| `tomasz` | Tomasz Wójcik | 1 → 5 | fastLearner | Station built | "Landscaping graduate. Hard worker. Will learn anything." | Eager, over-explains, apologises |
| `bernie` | Bernie Kale | 3 → 3 | steady | Station built; home tier ≥ compound | "Forty years in the trade. Not looking to learn new tricks." | Laconic, one-word replies |
| `saoirse` | Saoirse Flynn | 2 → 5 | nightOwl | Station built; Collective relation ≥ 20 | "Ex-cooperative grower. Left on good terms. Mostly." | Dry, wary of factions |

**Crafters** (role `production`, room `lab`)

| id | Name | Lvl → Cap | Specialities | Trait | Requirements | Headline | Voice |
|---|---|---|---|---|---|---|---|
| `priya` | Priya Sandhu | 2 → 4 | physics | steady | Lab built | "Materials engineer, formerly of a firm she won't name." | Precise, numbered lists |
| `dot` | Dot Mayhew | 1 → 4 | life, emotion | fastLearner | Lab built | "Herbalist. Market stall, Deptford. References on request." | Warm, chatty, calls you "love" |
| `gideon` | Gideon Achterberg | 3 → 5 | time | precise | Lab built; Guild relation ≥ 20 | "Horologist. Guild-trained. Expensive, and worth it." | Formal, faintly superior |
| `ray` | Ray Okafor-Bell | 2 → 3 | fate, emotion, time | steady | Lab built; flag `bizJamesProductionRole` | "Jack of all trades. Ask around." | Easy-going, name-drops James |

**Security** (role `security`, disabled): no candidates authored until OQ-9 is answered. The registry slot and requirement kinds are enough that adding them later is data only.

### 4.2 Traits (personality → gameplay)

One trait per candidate, from a closed set implemented in a small `Hiring.trait_*` helper. Every trait is a single number in `data/hiring.json` `traits`, so tuning is data:

| Trait | Effect | Number |
|---|---|---|
| `steady` | none — baseline | — |
| `fastLearner` | role XP gained × mult | `xpMult 1.5` |
| `precise` (crafter) | crafting XP × 1.25 (placeholder; a craft-failure effect is an option, OQ-7) | `xpMult 1.25` |
| `nightOwl` (cultivator) | acts in the Evening block twice, skips Morning (same 3 actions/day, shifted) — default: **cut for v1**, listed so the human can kill or keep | — |

Recommendation: ship v1 with `steady` and `fastLearner` only; other traits are a follow-up. Text voice is separate from trait (§7).

### 4.3 Requirement kinds

`requirements` is an AND list. Kinds (each one predicate in `Hiring.requirement_met()`):

| kind | Params | Met when | Board text when unmet (draft) |
|---|---|---|---|
| `room` | `room` | `room` is built at the current HQ | "Looking for: a proper {roomName}." |
| `homeTier` | `min` | home tier index ≥ `min` | "Looking for: somewhere with a bit more space." |
| `flag` | `flag`, `hidden?` | `state.flags[flag]` true | per-candidate `unmetText` |
| `factionRelation` | `faction`, `min` | `FactionAI.relation_toward(faction, "player") ≥ min` | "Wants references from {faction}." |

"Reputation" from the ticket: the game has no player-reputation stat, so faction relation stands in (OQ-5). A requirement with `hidden: true` keeps the candidate off the board entirely until met (questline reveals).

## 5. Cost

- **Wage only, no signing fee.** Weekly wage = existing `Payroll.wage_for_room()`: `(£100 + £50 × (skill − 1)) × 7` — £700/wk at level 1, £1,400 at level 3. Rises as the hire levels. First part-week is prorated via `Payroll.note_hire()` (already happens on `assign_to_room`).
- Shown on the profile as "Expects £X/week" at current level.
- **Open — OQ-1/OQ-2**: (a) the formula is 3–5× Owen's flat £250 business wage; (b) once the business pot is active, Owen is paid from the pot (`Business` wages) but room hires are still paid from player cash by `Payroll.pay_wages()`. Hires inherit whichever answer the human picks; this spec does not change payroll.

## 6. Availability and refresh

- **Eligible pool** = candidates whose role is `enabled`, who are not currently hired, not in a let-go cooldown, and have no unmet `hidden` requirement.
- **Board** = up to `boardSize` (4) candidates drawn from the pool via `Rng` (seeded → Rewind-safe). Requirement-failing candidates *can* be on the board, shown greyed with their "Looking for" lines — the LinkedIn joke is that you can see who you can't afford yet.
- **Refresh**: the board re-rolls on the Monday rollover (fits payroll's weekly cadence), keeping any candidate the player has hired out of it. Board also rolls on first app open if empty (old saves / first unlock).
- **Hire** removes the candidate from the board immediately; the slot stays empty until Monday.
- **Let go** (from the hire's HQ room card or their Graft profile): vacates the room (existing `assign_to_room("none", …)`), releases their `cultivatorVeins` list, sets `recruited = false`. They re-enter the pool after `rehireCooldownDays` (14) with level/XP kept. No severance; the prorated part-week is billed as Payroll already does.
- Badge: count of board candidates not yet viewed (`state.hiring.seen`).

## 7. Integration

| System | Change |
|---|---|
| `data/hiring.json` (new) | `roles`, `candidates`, `traits`, `boardSize 4`, `rehireCooldownDays 14` |
| `GameData` | load `hiring.json`; merge `candidates` into `CONTACTS_DEFAULTS` |
| `systems/hiring.gd` (new) | `board()`, `roll_board()`, `requirement_met()`, `can_hire(id) -> {ok, reasons}`, `hire(id)`, `let_go(id)`, `weekly_tick()` |
| `Contacts` | `ROOM_ROLES` read from registry; `display_name()` falls back to defaults `name` |
| `Payroll` | `ROLE_SKILL_KEYS` read from registry; otherwise unchanged |
| `Rooms` | unchanged for cultivators; crafters use ticket 10's speciality rule unchanged |
| `TimeSystem.daily_tick()` | `Hiring.weekly_tick()` on the Monday rollover, after ⑥ wages |
| `PhoneApps.apps()` + `PhoneAppRegistry` + `PhoneNav.APPS` | `hiring` / "Graft" entry; locked until any role room is built (OQ-3) |
| HQ floorplan room card | "Let go" button for a hired occupant; Assign list unchanged (hires are already assigned) |
| Contacts app | hire appears in the directory (unlocked + recruited); intro SMS on hire |
| `data/contact_texts.json` (ticket 11) | one random-texts entry per candidate in their voice; gate = "hired and working" (needs a `gateRecruited` option alongside `gateFlag` — small 11-system addition) |

`hire(id)`:
1. `can_hire` — candidate on board, role enabled, all requirements met, target room built **and empty** (one contact per room today; OQ-4).
2. `unlocked = true`, `recruited = true`, skill/XP set to `startLevel`.
3. `Contacts.assign_to_room(id, role.room)` → Payroll hire note.
4. Drop from board, push notification "{Name} starts today. Their desk is in the {roomName}.", queue intro SMS.

## 8. Save shape

```
hiring: {
  board: [contactId],          # current Open-to-work candidates, in display order
  boardRolledDay: int,         # -1 = never rolled (old saves); next open/Monday rolls
  seen: [contactId],           # board entries viewed (badge)
  cooldowns: { contactId: day } # let-go: re-enters pool on/after this day
}
```

- Candidate contacts are pre-seeded in `state.contacts` exactly like Des/Nadia/Owen (`unlocked:false, recruited:false`) — `SaveManager._backfill_new_contacts()` already adds new ids for old saves once `CONTACTS_DEFAULTS` includes them.
- Pure data only (ids, ints); Rewind/snapshots unaffected.
- REFERENCE.md §2 gains the `hiring` block and a §3.10 "Hiring" rules paragraph (ticket 18).

## 9. UI sketch (Family 2 list/detail)

- **Board (master)**: header "Graft" + tagline; row per candidate: name, headline (muted), trailing role chip ("Cultivator"/"Crafter"); greyed row + "Not yet" if any requirement fails.
- **Profile (detail)**: name, headline, role · "Level 2 · Ceiling 4", speciality ore chips (ore accents are allowed as data chips), "Expects £1,050/week", About, "Looking for" lines with ✓/✗, Hire button (`ui_action_red`, disabled with first unmet reason).
- **Hired tab**: current hires with role, level, room, "Let go".

## 10. Scope split

- **18** (cultivator): everything in §§3–9 with only cultivation candidates enabled in data; `steady`/`fastLearner` traits; requirement kinds `room`/`homeTier`/`flag`/`factionRelation`.
- **19** (crafter): crafter candidates + their speciality data. Must be a data-only addition per §3 — if 19 needs code beyond ticket 10's rule, 18's registry was wrong.

## 11. Out of scope

Signing fees, interviews/negotiation, poaching by factions, hires joining combat (`combatHpMax 0`), hires as founders/partners, multiple staff per room (pending OQ-4).

## 12. Open questions for the human

| # | Question | Recommended default |
|---|---|---|
| OQ-1 | Wage level: keep Payroll's £700/wk-at-L1 formula for hires, or a cheaper per-candidate weekly wage like Owen's £250? | Per-candidate `weeklyWage` in data, scaled by level; current formula is far above Owen's |
| OQ-2 | Once the business pot is active, should hires be paid from the pot (like Owen) instead of player cash? | Yes — route via `Business` wages when `potActive`; separate ticket |
| OQ-3 | When does Graft unlock? | Once any role room (Station/Lab/Ops) is built |
| OQ-4 | One contact per room means at most one hired cultivator and one hired crafter (beside founders). Want multiple seats per room (e.g. by HQ tier)? | Keep one per room for 18/19; seats are a later ticket |
| OQ-5 | "Reputation" requirement: no such stat exists. Faction relation OK as stand-in? | Yes |
| OQ-6 | Cultivator specialities: none, or an ore affinity (bonus on matching veins)? | None for v1 |
| OQ-7 | Which traits ship in v1? | `steady` + `fastLearner` only |
| OQ-8 | App name: Graft / Clocked In / Endorsed / Linkedout? | Graft |
| OQ-9 | Security role: named hires that replace/augment anonymous guards, or a different mechanic? | Defer; registry slot only |
| OQ-10 | Show level cap ("Ceiling") on profiles, or hide it as a surprise? | Show — it's the hiring decision |
| OQ-11 | Let-go rules: cooldown 14 days, level kept, no severance — OK? | Yes |
| OQ-12 | Roster: 4 + 4 above — names, levels, caps, requirements OK? | — |
