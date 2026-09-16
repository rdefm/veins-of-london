# PRD — The Collective, Act 1: "Gift"

**Status:** Draft from a design session (2026-08-21). Every decision below was
put to the human and confirmed in conversation. Open items are listed in §14 and
must be resolved before the tickets that depend on them are worked.

**Written against `vein-redesign`**, the live development line. All references to
growth bands, `seedOreCost`, `terroirYieldMult` and the vein dict assume the
vein-growth-state model is in place (it is).

**Scope of authority:** this document is canonical for the mechanics and content
it defines. Where it conflicts with `docs/VISION.md`, `docs/REFERENCE.md` or
`plans/COLLECTIVE-QUESTLINE.md`, **this document wins**, and the conflicting
document must be amended in the same ticket that lands the conflicting code (per
the project constitution). §13 lists every amendment required.

**Terminology:** `plans/COLLECTIVE-QUESTLINE.md` calls this "Arc 1". This
document and all its tickets call it **Act 1**. Same content.

**All new prose in this document is `PROSE-REVIEW:` material.** Card text below
is a drafted first pass against `docs/CONTENT-GUIDE.md` §3, not approved copy.

---

## 1. Why

`plans/COLLECTIVE-QUESTLINE.md` is an agreed brainstorm with no build path. It
describes an arc that hangs off a relation ladder that **does not exist**: today
`state.factions[id].relation` is only ever *decremented* (raid penalties in
`systems/raiding.gd`) or hand-set by `systems/debug_start.gd`. Nothing in the
shipped game awards faction relation. The 25/50/80 spine gates in
`docs/VISION.md` §14 have nothing underneath them, for any faction.

There is also no way to trigger a story event on anything but a boolean flag
(`systems/map_pins.gd`), no way to deliver a message at runtime (the phone's
Messages app is a hardcoded list of two contact cards), no way to express a
player objective (`systems/todo.gd` is a hardcoded flag chain), and no way to
stop owning a vein except by losing it.

So Act 1 is two things at once, deliberately:

1. **The Collective's first act** — the content.
2. **The questline engine** — relation accrual, objectives-as-data, runtime
   message delivery, extended pin gating, and a vein exit lane. Every one of
   these is required by Arc 2 as already designed (§5 of the questline doc calls
   for "free-form objectives" by name), and by the four other faction
   storylines.

The engine parts are specified here because Act 1 is the smallest complete thing
that proves them. A spec that ships only the content produces tickets that
cannot land.

### 1.1 What Act 1 must achieve, in the questline's own terms

- Make the player like Des, Nadia and Hakim (§5: "Arc 1's job").
- Make Des's lessons quotable, so Arc 3 can re-read them as confession (§4.1).
- Establish that the player was **given more than they gave** (§5).
- Plant the Archie/Des decoy so the player files the antagonism and stops
  wondering (§4.5, §4.7).
- Show Firm friction as **weather, not plot** — no threat the player can act on
  (§5).
- Leave the player holding an unwritten, verbal, person-to-person way of doing
  business, so that Arc 2's formalisation has something specific to destroy
  (§3).

---

## 2. Scope

### In scope

| | |
|---|---|
| Content | 14 authored events, three contacts, one repeatable intel event, trade bark pools |
| Engine | Objectives system; Messages app + runtime message delivery; `MapPins` gate extension; generic faction trade lane; vein sale; relation accrual from trade; method log (opened, not exercised) |
| Balance | Archie's cut rebalanced; Collective lane rates; vein sale pricing |
| Docs | Amendments listed in §13 |

### Out of scope

- Arc 2 and Arc 3 content of any kind. The Network handler is **not** introduced,
  foreshadowed, or referenced.
- Raid intel from Hakim (held for Arc 2 by explicit decision).
- Migrating Archie's and James's bespoke SMS screens to the new Messages app
  (§7.2 — deferred to its own ticket).
- Making the other four factions' storylines. The engine is built so they can
  reuse it; no content is written for them.
- Recruiting any of the three new contacts (Nadia becomes recruitable at the end
  of Act 3; that is Act 3's spec).
- The barometer influence actions (unimplemented, M4).

---

## 3. Cast

Closes `plans/COLLECTIVE-QUESTLINE.md` §9 open question 1.

### 3.1 Desmond "Des" Ferrier — A, "Not at all"

- **40s. Prospector. Crystal Palace.** Card line: `Prospector · Crystal Palace`.
- Contact id: `des`.
- Grandchild of the Windrush generation. He **inherited** the lesson — mutual
  aid, informal networks, not being on anyone's list — rather than living
  through it, which is precisely why he holds it as *principle*: articulate,
  rigid, quotable, faintly precious about it.
- **Voice:** warm, unhurried, teacherly. Explains things one step further than
  you asked. Never raises his voice. Generous to the point of being slightly
  hard to accept things from.
- **Trek:** exactly one quotation, "The needs of the many outweigh the needs of
  the few," used once in Act 1 (§6.4) and once in Arc 3. No other Trek material
  anywhere, ever. No banter.
- **Football:** never mentions it, doesn't engage when Archie does, isn't
  interested. This is quietly the thing about him that grates.
- Not recruitable, in Act 1 or later. His recruit row must be **suppressed**,
  not shown disabled (§7.1).

### 3.2 Nadia Beckford — B, "Completely"

- **Late 60s. Fixer. Hackney.** Card line: `Fixer · Hackney`.
- Contact id: `nadia`.
- Windrush generation — came over as a child. **Lived it.** Has no romance about
  it whatsoever and will use a chair if a chair is what the situation calls for.
- **Voice:** fast, dry, four words where six would do. Texts like someone paying
  by the character. Warm in effect, never in phrasing.
- The generational inversion with Des is load-bearing: **the ideologue is the
  one who didn't have to survive it; the pragmatist is the one who did.**
- The permanent trading lane. Survives all three Act 3 futures. Recruitable only
  after Act 3 — until then her recruit row is **suppressed**.

### 3.3 Hakim Rahman — C, "I just want to go home"

- **40s. Newsagent. Whitechapel.** Card line: `Newsagent · Whitechapel`.
- Contact id: `hakim`.
- A shop, a kid, and a knackered vein in the yard that the calc quietly pays
  the rent with.
- **Voice:** tired, kind, not stupid. Knows everyone's business and repeats none
  of it. Apologises for asking for things.
- **He is an informal, verbal, unrecorded intelligence network offered free by a
  neighbour.** This is the thing the Network handler replaces with an invoice in
  Arc 2. Hakim is not betrayed in Arc 3; he is made *redundant*, hours earlier,
  by something the player chose because it was obviously better.
- Not recruitable. Recruit row suppressed.

### 3.4 Archie — the door, not a slot

Existing contact, existing relation track, no new anything. He appears in Act 1
**exactly twice**: the introduction (§6.1) and the pry scene (§6.13). Then he
steps back from this story until his one line in Arc 3.

**His reason for making the introduction:** Archie taught the player to work the
vein he gave them (`archie_cultivation`, shipped). One vein is not a business.
To have their own, the player has to **find ground and seed it** — and Archie
has never prospected anything in his life. He is a trader. Magic is stock to
shift. He is time-allergic, which is why he gave the time vein away. He knows
exactly one man who can read ground and he thinks that man owes him money. He
rings him anyway.

His stake is honest and needs no new mechanic: his lane already pays the player
`PLAYER_CUT_RATIO` and he keeps the rest. When he says he's doing this so they
both get paid, he is describing the existing economy accurately.

**Note for later arcs, not to be written now:** the player will eventually sell
through the Collective at better rates than Archie's cut. This quietly costs
Archie money, is never remarked on by anyone, and is the first thing the player
takes from someone without noticing.

### 3.5 Contact budget

Three new contacts exceeds `docs/VISION.md` §14's "+1–2 new contacts by 1.0".
This is a deliberate, human-approved deviation — §13 requires the amendment.
Rationale: all three must be real people with persistent surfaces because the
Collective *is* its people (§3 of the questline doc), and because the trading
lane runs through all three.

---

## 4. Act structure

```
cultivationTutorialSeen
        │
        ▼
  PHASE 1 — TUITION (linear, mandatory)
   S1  Archie introduces Des            [Archie text]
   S2  Des teaches prospecting          [map pin, Shoreditch]
   S3  Des teaches seeding              [map pin, Shoreditch]
   S4  The hub — three asks             [Des text]
        │
        ▼
  PHASE 2 — THREADS (parallel, player-ordered, all three required)
   ┌─ Des ────────────┐ ┌─ Nadia ───────────┐ ┌─ Hakim ──────────┐
   │ S5  weather: skirmish              │ │ S8  meet, consignment │ │ S11 the yard    │
   │ S6  weather: intimidation          │ │ S9  the vein ask      │ │ S12 handing back│
   │ S7  report the ground              │ │ S10 the sale          │ │                 │
   └────────────────────┘ └────────────────────┘ └──────────────────┘
        S13 Archie pry scene (optional, available throughout phase 2)
        │
        ▼  all three complete AND collective relation >= 25
  PHASE 3 — CLOSER
   S14 The yard, the tip, the gift, the invitation   [Hakim text]
        │
        ▼
  Act 1 complete. Membership taken or deferred.
```

### 4.1 Mandatory tuition, optional questline

Phase 1 fires unavoidably on tutorial completion. **Des's tuition is the game's
prospecting and seeding tutorial** — both are currently untaught, and writing a
second faction-neutral tutorial would mean writing the same lesson twice with
worse dialogue.

After S4, the player may simply not do the threads. They keep the knowledge, the
trading lane stays open, and the act sits there indefinitely. The Collective's
opinion of them never moves.

This lands the act's own thesis on a player who never plays it: **they were
given more than they gave, and they walked.** Arc 3 has every right to remember
that.

### 4.2 Consequence: the Collective gets first contact with every player

Accepted, not compromised. Shoreditch carries `factionPresence: "collective"`,
the player starts there, the Collective has the lowest join bar, and §1 of the
questline doc names it the pilot precisely because it is "the faction most
players meet first."

---

## 5. New machinery

### 5.1 `systems/objectives.gd` — objectives as data

The single most important structural decision in this spec. Objectives are
**data**, evaluated by a small set of typed evaluators.

**Definition schema** (`data/objectives.json`):

```json
{
  "id": "col_a1_des_sites",
  "title": "Find ground for the Collective",
  "detail": "One fate, one physics. Fair quality or better. Leave them unclaimed.",
  "type": "sites_discovered_matching",
  "params": { "requireEachOreType": ["fate", "physics"], "minTier": "fair", "unclaimed": true },
  "activateFlag": "colA1DesThreadActive",
  "completeFlag": "colA1DesSitesFound"
}
```

**Runtime state** (`state.objectives`, pure data):

```
state.objectives = {
  "<objectiveId>": { "active": bool, "complete": bool, "progress": { ... } }
}
```

**Evaluator types — exactly four. Do not add more for Act 1.**

| type | params | evaluates |
|---|---|---|
| `sites_discovered_matching` | `requireEachOreType: [String]`, `minTier: String`, `unclaimed: bool` | For each named ore type, at least one site in `state.world.sites` with that `oreType`, tier at or above `minTier` in `sites.json`'s `tierOrder`, and (if `unclaimed`) `claimed == false` and `factionVein == null` |
| `traded_with_faction` | `factionId`, `oreType`, `qty: int`, `minTransactions: int` | Cumulative units of `oreType` sold to `factionId`, and a separate count of distinct sale transactions containing it |
| `vein_sold_to_faction` | `factionId`, `oreType` | Boolean: has a vein of `oreType` been sold to `factionId` since the objective activated |
| `vein_growth_above` | `veinIdStatePath: String`, `threshold: int` | The vein whose id is stored at that state path has `growth >= threshold` |

**`Objectives.refresh()` — evaluation timing.** Objectives are *not* evaluated
on `EventBus.state_changed` (a system cannot connect to a signal, and doing it
from an autoload risks recursion). `refresh()` is called explicitly, and
idempotently, at these action boundaries and nowhere else:

- `Sites.prospect()` — at the end, after the site is created
- `Economy` sale completion (both the Archie lane and the faction lane)
- `VeinTrade.sell_to_faction()`
- `Cultivating.cultivate()` and `Cultivating.prune()`
- `TimeSystem.daily_tick()`

`refresh()` must not call anything that calls `refresh()`. It sets `complete`
and the `completeFlag`; **it never awards anything.**

**Awards live in authored content, never in objectives.** Completing an
objective lights the action-bar button on the relevant contact; the resolution
*event's* `on_complete` awards relation and everything else. This makes
double-awarding structurally impossible and keeps rewards where a writer can see
them.

**Notes app.** `systems/todo.gd` gains a Collective section that renders live
objective state (title, detail, done) rather than another hardcoded flag chain.
The existing tutorial chain is untouched.

### 5.2 Messages app

Today: `scenes/screens/phone.gd::_build_messages()` is a hardcoded list of two
contact cards; `_has_pending_messages()` is five hardcoded flag checks; SMS
threads are bespoke full screens (`sms_archie.gd` hardcodes
`THREAD_ID := "archie_1"`).

**New shape:**

- **Messages app** — a list of conversations, most recent activity first, unread
  dot per conversation. Contacts appear as they unlock.
- **Conversation screen** — scrolling text history (their messages left, the
  player's right), reusing the existing staged-reveal presentation for
  newly-arrived messages, with an **action bar pinned at the bottom** holding
  that contact's currently-available actions.
- **One person, one screen.** Trade, story beats and (later) reply options all
  live in the action bar. This is the shape the human's roadmap needs: "contact
  texts you and you choose a response" and "player initiates a chat" are both
  just more kinds of entry in the action bar.

**State:**

```
state.messages = {
  "<contactId>": [ { "from": "them"|"player", "text": String, "day": int, "read": bool } ]
}
```

Capped per conversation the way `state.notifications` and `state.bankLog`
already are, so saves do not grow without bound. Cap: **50 messages per
conversation**, evicting from the front.

**Trade stays a modal.** The action bar's Trade button opens the existing
`sell_menu` modal rather than rebuilding trade inside the conversation. One
trade UI in the game, not two.

**Archie and James are not migrated.** `sms_archie.gd` / `sms_archie_2.gd` and
the existing contact-card builders stay exactly as they are. They are finished,
tested M0 content and a regression there is expensive. Migration gets its own
ticket once the new renderer has proven itself. Archie's and James's
conversations therefore do **not** appear in the new Messages app in Act 1 —
their existing surfaces continue to work unchanged.

### 5.3 `state.pendingMessages` — runtime delivery

```
state.pendingMessages = [ { "contactId": String, "kind": String, "payload": { ... } } ]
```

A pending entry causes: an unread text to be appended to that contact's
conversation, the Messages app to badge, and an action-bar entry to appear that
opens the relevant event.

Runtime detail travels in `payload` and is passed into the event as
**`Events.start_event(id, context)`** — the same road `systems/raiding.gd`
already uses to hand a runtime `site_id` to the raid event
(`Events._event_site_id()`). No new mechanism.

Entries are removed when their action is taken.

### 5.4 `MapPins` gate extension

`systems/map_pins.gd::_flags_satisfied()` currently gates on booleans only. The
`pin` block gains two optional keys:

```json
"pin": {
  "district": "shoreditch",
  "showWhenFlagsTrue": ["colA1DesMet"],
  "showWhenFlagsFalse": ["colA1ProspectingTaught"],
  "minRelation": { "faction": "collective", "value": 25 },
  "minDay": 4
}
```

Both optional, both default to no constraint. `minRelation` reads
`state.factions[faction].relation`. This is the extension every later faction
storyline inherits.

### 5.5 Generic faction trade lane

`systems/economy.gd`'s Guild functions are generalised to take a faction id.
`get_guild_spread()` / `get_guild_buy_price()` / `get_guild_sell_price()` /
`execute_guild_purchase()` / `execute_guild_sale()` become
`get_faction_spread(faction_id)` etc., with the Guild as the first caller and
identical behaviour. Per-faction configuration moves to data
(`data/faction_trade.json`, §9.4).

**Asymmetric spreads.** The Guild's single spread applies to both directions.
The Collective needs them decoupled: its sell spread starts wide (they are a
network of neighbours moving ore, not a market), but its buy markup must stay
modest — they do not gouge their own. See §8.2.

**The Collective lane is unlocked pre-join**, at S1, and is gated on
`flags.collectiveLaneUnlocked` rather than on membership. This is deliberate and
is the mechanical expression of "low entry bar" in `data/factions.json`.

**Three cosmetic doors.** Des, Nadia and Hakim each offer the lane through their
action bar. **Identical terms, identical relation award.** They differ only in
the bark pool drawn on completing a trade (§9.5). Des is available from S1;
Nadia and Hakim from S4.

### 5.6 `systems/vein_trade.gd` — selling a vein

New. Nothing like it exists: veins leave the player only by being raided or
collapsing. `VeinList.actions_for()` offers cultivate/prune/security only.

```
VeinTrade.quote(vein) -> int
VeinTrade.sell_to_faction(vein_id, faction_id) -> Dictionary
```

**Price:**

```
price = round_epsilon(
    orePrice(vein.oreType)
  * terroir_yield_mult(vein)
  * VEIN_SALE_BASE_UNITS
  * (vein.growth / VEIN_GROWTH.neutral)
)
```

with `VEIN_SALE_BASE_UNITS = 35`. `orePrice` is the barometer-effective price
(`Barometer.get_effective_ore_price`), consistent with every other lane.

**Transfer:** the vein is removed from `state.player.veins` and re-created on its
site as `site.factionVein` via the existing `Factions.create_faction_vein()`,
preserving `growth`, `oreType` and `hospitability`. The map's faction stop and
routed line come for free. A `MapEvents.queue_seed_claim()` is pushed with the
buying faction as owner so the ownership change animates, matching how
rivalry transfers already behave.

**Guards:**
- **Quote, then confirm.** The price is shown in a confirmation modal before the
  player commits. Losing a vein must never be one tap.
- No same-day-sale rule is needed. `seedGrowth` is 20, so a fresh seed prices at
  `0.4×` on the growth factor and flipping it loses money (§8.3).

**Availability:** permanent from S9 onward, not just during Nadia's thread. This
is the first way in the game to *choose* to stop owning something.

**Relation:** the sale price counts toward `tradeProgress` like any other trade
(§8.4). Nothing extra.

### 5.7 Method log

```
state.methodLog = { }
```

A flat dictionary of pure-data counters. Act 1 writes **exactly one key**:

```
state.methodLog.firmFirstContact = "backed_off" | "held" | "fought"
```

written by S6's choice card. Arc 2 extends the dictionary; Act 1 defines the
container and nothing else.

**Rewind erases it.** The log is ordinary state and is restored by
`Events.rewind()` along with everything else. This is the deliberate decision
`plans/COLLECTIVE-QUESTLINE.md` §8.3 asks for. Rewind is a consumable with a
price tag and a crafting cost; a ledger that kept the receipt anyway would
betray a mechanic the player paid for, and would punish exactly the players
engaging most carefully with the game's flagship feature. In fiction the world
genuinely reset, nobody else saw it, and nothing happened.

*(Deferred, not decided: a neutral counter of rewinds used at choice points —
"you have changed your mind about this before" — is a strong idea with nothing
to observe yet. Arc 2's spec may add it. The schema leaves room.)*

### 5.8 Hakim's unprompted intel

**Push, not pull.** Hakim texts the player when he happens to hear something.
This is the mechanic the Arc 2 handler contrasts against: **the gift arrives
unasked; the commodity is ordered to spec.**

- **Unlocked by** completing Hakim's thread (S12).
- **Daily-tick roll: 15%**, with a minimum of **3 days** since the last text.
- **Suppressed** if both Shoreditch and Whitechapel are at `siteCap` (7 each).
- **Creates** an unclaimed site in Shoreditch or Whitechapel at tier `fair` or
  better, then pushes a `pendingMessages` entry carrying its `siteId`.
- **Free, permanently.** No cash, no favour, no cooldown purchase. The contrast
  with the handler's invoice is the entire point and must not be diluted.
- **No raid tips in Act 1.** Held for Arc 2 by explicit decision.

---

## 6. Content — every scene

Event ids are prefixed `col_a1_`. All are added to `GameData.EVENT_IDS` (not
`DISTRICT_EVENT_IDS` — none of these are deck-weighted).

**All card text below is `PROSE-REVIEW:` draft.**

### 6.1 S1 — `col_a1_intro` · "Ground"

**Delivery:** Archie text (`pendingMessages`), pushed the moment
`flags.cultivationTutorialSeen` becomes true.
**Text:** *"Come by the lock-up. Got someone you need to meet. Don't make a thing of it."*

**Cards:**

1. **narration** — *Shoreditch* — "The lock-up smells of damp cardboard and, distantly, of something that isn't cardboard. Archie is standing outside it with the expression of a man who has already had this conversation in his head and did not enjoy it."
2. **Archie** — "\"One vein. That's what you've got. One vein, which I gave you, which I'm now going to hear about for the rest of my life.\""
3. **Archie** — "\"One vein isn't a business, it's a hobby with rent. You want more, you have to go and find ground, and seed it, and I can't teach you that because I've never done it. I shift stock. I don't dig.\""
4. **narration** — "He fishes his keys out — a fat bunch, a Millennium Falcon keyring worn smooth at the edges — and lets you both into the lock-up." *(the keyring, one clause, never remarked on by anyone, ever)*
5. **Archie** — "\"So I called a bloke. He's good. He's the best I know at it, actually.\" A pause exactly long enough to be noticeable. \"He'll teach you. Then he'll go home.\""
6. **narration** — "The man who comes in is in his forties, unhurried, with a canvas bag over one shoulder and the air of somebody who has never once been late but has often waited. He looks genuinely pleased to be here, which nobody else in this story has managed."
7. **Des** — "\"Desmond. Des. You're the one with the Whitechapel time vein.\" He says it like a fact he's glad about rather than one he's checking."
8. **Archie** — "\"Right. He knows ground, I know buyers, and between us you might make rent. That's the arrangement.\""
9. **narration** — "Archie does not offer Des tea. Des does not appear to expect any. There is a silence with some history in it, and then Archie remembers somewhere else he needs to be."
10. **Des** — "\"He's all right, Archie. Bit of a transaction, but he's all right.\" He's already unpacking the bag. \"Right. Ground.\""
11. **resolution** — "You have a teacher. Neither of you has mentioned money, which is the first thing about today that will turn out to matter."

**`on_complete`:**
- unlock contact `des`
- `set_flag colA1DesMet true`
- `set_flag collectiveLaneUnlocked true`
- relation: `factions.collective +3`
- `set_flag colA1Stage "tuition"`

**Notes:**
- Archie's shortness about Des is visible here and in every later scene. The
  *reason* is gated behind S13.
- Des is added as a conversation and as a trade door in the same beat.

### 6.2 S2 — `col_a1_prospecting` · "Reading a street"

**Delivery:** map pin, Shoreditch. Gate: `showWhenFlagsTrue: ["colA1DesMet"]`,
`showWhenFlagsFalse: ["colA1ProspectingTaught"]`.

**Cards:**

1. **narration** — *Shoreditch — a service yard behind a coffee place* — "Des has brought you to the least interesting place in Shoreditch and is looking at it with open enthusiasm."
2. **Des** — "\"Everyone looks for the dramatic bit. Cracked stone, old church, that sort of thing. Mostly what you want is somewhere that's been left alone a long time and had something happen to it once.\""
3. **Des** — "\"Prospecting's a block of your day and a walk about. You'll turn up a patch or you won't. What you turn up depends on the ground round here and on how much of this you've done before — that's it, that's the whole system.\""
4. **Des** — "\"Patches come in grades. Poor, fair, rich, and once in a blue moon something that makes you sit down. Barren ones you leave; nothing takes in them.\""
5. **Des** — "\"Different parts of London run to different types. Round here it's whatever's going. Whitechapel's emotion, mostly. The City's fate, which tells you something about the City.\""
6. **narration** — "He does not tell you which of these facts is the important one. You get the sense this is on purpose."
7. **Des** — "\"Go on. Have a look about. I'll be here.\""
8. **resolution** — "You spend an hour looking at brickwork with a seriousness that would embarrass you if anyone you knew walked past. Somewhere under all of it, London is doing what it does."

**`on_complete`:** `set_flag colA1ProspectingTaught true`

**Design note:** the event does not force a prospect. It teaches, and S3's pin
requires `colA1ProspectingTaught` only. The act never hard-gates on the player
completing a prospect action in phase 1.

### 6.3 S3 — `col_a1_seeding` · "Putting something in"

**Delivery:** map pin, Shoreditch. Gate:
`showWhenFlagsTrue: ["colA1ProspectingTaught"]`,
`showWhenFlagsFalse: ["colA1SeedingTaught"]`, `minDay` = day of S2 + 1.

**Cards:**

1. **narration** — "Des has a jar in his bag. In the jar is about forty units of somebody's physics calc, and he is holding it the way other people hold a thermos."
2. **Des** — "\"Finding a patch is half of it. A patch is just good ground. It doesn't do anything until you put something in it.\""
3. **Des** — "\"Forty units of the right type. Has to match what the ground wants — you can't put fate in a life patch and hope. Costs you a block, and it doesn't always take. Better ground takes more often, and you get better at it.\""
4. **Des** — "\"When it takes, you've got a vein and the patch is yours. When it doesn't, you've lost the calc and the afternoon, and you have another go when you can afford one.\""
5. **narration** — "He says the last part without any particular weight, as a man describing weather."
6. **Des** — "\"Which is why nobody round here seeds alone if they don't have to. If I've got forty spare and you've found ground, that's not me lending you anything. That's the ground getting used.\""
7. **Des** — "\"The needs of the many outweigh the needs of the few.\"" *(first use — no eye-roll; Archie is not present)*
8. **narration** — "He does not appear to think he has said anything unusual, and moves straight on to the practical bit about matching types, which he has now explained twice."
9. **resolution** — "You know how to seed a patch. You do not yet have forty units of anything spare, which is a different problem and, Des would say, a smaller one."

**`on_complete`:** `set_flag colA1SeedingTaught true`; push Des text opening S4
(one day later).

### 6.4 S4 — `col_a1_hub` · "Your turn"

**Delivery:** Des text. *"When you've got a minute. Nothing urgent, but there are three things."*

**Cards:**

1. **narration** — "Des has bought you a coffee you didn't ask for and won't let you pay for, which is becoming a pattern."
2. **Des** — "\"Right. You've had a fortnight of me giving you things. That's fine, that's how it works, but it works both ways or it doesn't work.\""
3. **Des** — "\"Three things. Take them in whatever order suits. Or don't — I'm not your governor, nobody is.\""
4. **Des** — "\"One's mine. We've got people who can seed but haven't got ground. I need a fate patch and a physics patch, decent ones, and I need them left alone until I say. You find them, I'll do the rest.\""
5. **Des** — "\"Two's Nadia. Hackney. She moves more calc in a week than the rest of us see in a month and she's short on something. Go and be useful to her; she'll tell you how.\""
6. **Des** — "\"Three's Hakim. Newsagent, Whitechapel Road. He's got a vein in his yard that's on its way out and he hasn't got the hands for it. That one's not a favour to me, it's a favour to him, and he'll be embarrassed about it, so don't make it worse.\""
7. **narration** — "He writes two phone numbers on the back of a receipt, which is the only record of any of this that will ever exist."
8. **resolution** — "Three names, three problems, no deadline and no order. The Collective, as far as you can tell, is a group of people who have each independently decided to be helpful and have never once discussed it."

**`on_complete`:**
- unlock contacts `nadia`, `hakim`
- activate objectives `col_a1_des_sites`, `col_a1_nadia_supply`,
  `col_a1_hakim_rescue`
- `set_flag colA1Stage "hub"`
- `set_flag colA1ArchiePryAvailable true`

**Note:** card 7 is the act's quietest and most important line. The only record
is a receipt. Arc 2 replaces it with a spreadsheet.

### 6.5 S5 — `col_a1_firm_skirmish` · weather

**Trigger:** the **first** `Sites.prospect()` completion after
`colA1DesThreadActive`. Any district. Fires before the district deck draw; if it
fires, the deck draw is skipped for that action (§10.3).

**Cards:**

1. **narration** — "You come round the corner into the end of something. Four people, one of them on the floor, and the specific quiet that happens after shouting rather than before it."
2. **narration** — "Two of them are wearing the kind of coats that cost money. They are not hurrying. One is writing something down."
3. **narration** — "By the time you've decided whether to do anything, there are two people and one of them is being helped into a car by the other. Nobody looks at you. It has been arranged that there is nothing to look at."
4. **resolution** — "You ask Des about it later. He says \"Firm,\" the way you'd say \"rain,\" and asks whether you found anything."

**`on_complete`:** `set_flag colA1SkirmishSeen true`

**Note:** location-agnostic on purpose. Tying it to Camden or Battersea reads
better but the player might find their sites anywhere, and a beat that sometimes
doesn't fire is worse than one that fires somewhere slightly generic. "One is
writing something down" is a plant; nobody remarks on it.

### 6.6 S6 — `col_a1_firm_intimidation` · weather + the log opens

**Trigger:** the `Sites.prospect()` completion that produces the **second**
qualifying site for `col_a1_des_sites`. Same skip-the-deck rule.

**Cards:**

1. **narration** — "Three of them, waiting by your exit, in no particular hurry. The one in front has the patient look of somebody doing an errand."
2. **Firm Man** — "\"You've been busy. Fate, physics — bit ambitious for someone who was doing a rent-a-vein in Whitechapel a month ago.\""
3. **Firm Man** — "\"Nobody's asking you to stop. Just letting you know it's been noticed. There's a difference, and the difference is entirely up to you.\""
4. **choice** — text: "He hasn't threatened you. He's been very careful not to."
   - **"Back off"** → `result_text`: "You take the long way round. Nothing happens, which is the point — somebody wanted a face and now has one." · effects: `methodLog.firmFirstContact = "backed_off"`
   - **"Hold your ground"** → `result_text`: "You don't move and you don't say anything. He waits, decides it isn't worth the afternoon, and they go. He is slightly less pleasant on the way past." · effects: `methodLog.firmFirstContact = "held"`
   - **"Tell them where to go"** → `result_text`: "You tell him. There is a moment where it could still go either way, and then it doesn't." · effects: `methodLog.firmFirstContact = "fought"`, `start_street_mugging`
5. **resolution** — "The patches are still yours to give away. That was never what this was about."

**`on_complete`:** `set_flag colA1IntimidationSeen true`

**Rules:**
- **The player keeps both sites regardless.** Taking one would be cruel and
  would break Des's thread.
- **No mechanical consequence** — no relation change, no retaliation, nothing.
  `plans/COLLECTIVE-QUESTLINE.md` §5 is explicit that Act 1 offers "no threat the
  player can act on yet", and a consequence would make it one. The consequence
  is that it is remembered, and the player does not know that.
- This is where `state.methodLog` opens. Starting the ledger in Act 1, silently,
  with an entirely innocuous choice, is what makes it evidence rather than a
  scoring system. If it started in Arc 2 alongside the escalation events, the
  player would correctly infer they were being scored and start playing the
  meter.

### 6.7 S7 — `col_a1_des_report` · Des's thread resolves

**Delivery:** Des action bar, "Tell Des about the ground", enabled by
`colA1DesSitesFound`.

**Cards:**

1. **narration** — "You give Des two addresses. He writes neither of them down."
2. **Des** — "\"Fate in the City. Course it is.\" He's pleased in a way that takes a second to read as pleased. \"And physics. Good. That's two people who'll have something by the weekend.\""
3. **narration** — "You ask who. He tells you the first names and nothing else, and you realise a beat later that he has told you exactly as much as he'd tell anyone about you."
4. **Des** — "\"Nobody's ever raided a vein they didn't know about.\" He says it as a small joke about paperwork. \"That's the whole trick. That's it. That's the entire clever bit.\""
5. **resolution** — "By the end of the week, two patches you found have veins in them and neither of them is yours. You are, apparently, fine with this, which is itself new information."

**`on_complete`:**
- Collective seeds both sites: `Factions.create_faction_vein()` for each
  reported site, owner `collective`, at `VEIN_GROWTH.seedGrowth`; queue
  `seed_claim` + `join_line` map events for each
- relation: `factions.collective +8`
- `set_flag colA1DesThreadDone true`

**Note:** card 4 is the line Arc 3 re-reads as confession. It must be delivered
as a mild joke about admin and never underlined.

### 6.8 S8 — `col_a1_nadia_meet` · the consignment

**Delivery:** Nadia action bar, "Go and see Nadia", from S4.

**Cards:**

1. **narration** — *Hackney — the back of a shop that sells phone cases* — "Nadia Beckford is about seventy and is moving a crate that you would need help with. She does not accept help."
2. **Nadia** — "\"Des sent you. He's told you I'm short.\" She doesn't look up. \"He's right. I'm short.\""
3. **Nadia** — "\"Standing order. Emotion calc, every fortnight, same bloke, same amount, been running four years. It pays for a lot of things that need paying for.\""
4. **Nadia** — "\"Whitechapel's full of it and everyone round here has a bit and nobody has thirty units at once. So I spend three days on the phone every fortnight like it's 1974.\""
5. **choice** — text: "She finally looks up."
   - **"I can get you thirty"** → "\"Course you can.\" She goes back to the crate. \"Bring it when you've got it. Bring it in bits, I don't care.\""
   - **"What's in it for me?"** → "\"Market rate, same as anyone.\" A pause. \"You were expecting me to be offended. I'm not. Ask people what things cost, it saves everybody a fortnight.\""
6. **Nadia** — "\"And before you ask — no, I don't know who's holding what. Nobody does. If I knew who had what I'd have had this done Tuesday.\"" *(the information thesis, said innocently, by the person who opens the Network door in Arc 2)*
7. **resolution** — "Thirty units of emotion calc, no deadline, no paperwork, and a woman who has been doing this since before you were born treating it as entirely routine."

**`on_complete`:** activate `col_a1_nadia_supply`; `set_flag colA1NadiaMet true`

**Objective:** `traded_with_faction` — `oreType: "emotion"`, `qty: 30`,
`minTransactions: 3`. Sold through **any** of the three Collective doors; she is
the one who ends up with it either way.

### 6.9 S9 — `col_a1_nadia_vein` · the ask

**Delivery:** Nadia action bar, enabled by `colA1NadiaSupplied`.

**Cards:**

1. **Nadia** — "\"That's the order filled and I'm still doing three days on the phone every fortnight. That's not a solution, that's you being nice.\""
2. **Nadia** — "\"So. Different idea. You seed me an emotion vein and I buy it off you. Then it's mine, it produces, and the standing order fills itself.\""
3. **Nadia** — "\"You take the risk — the forty units, the seeding, whether it takes. I take a working vein and pay for it. That's not charity in either direction, that's just what things are worth.\""
4. **narration** — "It is the first time anyone in the Collective has proposed a transaction to you where both halves were named out loud, and it's oddly restful."
5. **Nadia** — "\"Grow it a bit first if you've any sense. I'll pay what it's worth on the day, and a hole in the ground with forty units in it isn't worth much yet.\""
6. **resolution** — "You now know that a vein is a thing that can be sold, which had genuinely not occurred to you."

**`on_complete`:**
- activate `col_a1_nadia_vein`
- `set_flag veinSaleUnlocked true` — the Sell option appears in
  `VeinList.actions_for()` from here on, permanently, for every vein
- `set_flag colA1NadiaAskSeen true`

**Objective:** `vein_sold_to_faction` — `factionId: "collective"`,
`oreType: "emotion"`.

**Note:** card 5 is the in-fiction explanation of the growth factor in the price
formula. The player is being told, in dialogue, why not to flip a fresh seed.

### 6.10 S10 — `col_a1_nadia_done` · Nadia's thread resolves

**Delivery:** fires automatically on the qualifying sale completing (from
`VeinTrade.sell_to_faction()`), not from the action bar — the sale itself is the
scene's trigger.

**Cards:**

1. **Nadia** — "\"Right. That's mine now.\" She counts out the money in a way that suggests she has counted out a great deal of money in her life. \"And that's three days a fortnight back.\""
2. **Nadia** — "\"You'll get offers, by the way. People who want to buy ground off you cheap because you're new. Don't take them. Ask me first, I'll tell you what it's worth, and I'll tell you straight even when I'm the one buying.\""
3. **narration** — "You believe her, and you notice that you believe her, and you file that away."
4. **resolution** — "You have sold a vein. There's more money in your account than there was and slightly less London that belongs to you, and it is not immediately obvious which of those is the good news."

**`on_complete`:** relation `factions.collective +8`; `set_flag colA1NadiaThreadDone true`

### 6.11 S11 — `col_a1_hakim_meet` · the yard

**Delivery:** map pin, Whitechapel. Gate: `showWhenFlagsTrue: ["colA1Stage" == hub]`
expressed as flag `colA1HubReached`, `showWhenFlagsFalse: ["colA1HakimMet"]`.

**Cards:**

1. **narration** — *Whitechapel Road* — "The shop sells newspapers, phone credit, four kinds of crisps and, if you know to ask, nothing else at all. There is a child's homework on the counter, half done, with a biro resting in the fold."
2. **Hakim** — "\"You're Des's. He said. Sorry — that came out like you're a dog.\""
3. **Hakim** — "\"There's a vein in the yard. Came with the shop. My uncle had it and he was good with it and I'm not, and it's been going backwards for about two years.\""
4. **narration** — "The yard is eleven feet of concrete, three bins and a vein that has clearly not been touched in a long time. It reads as sparse and dropping."
5. **Hakim** — "\"It does about a third of what it used to. Which is about a third of the rent, so.\" He stops there, having got closer to complaining than he intended.\""
6. **Hakim** — "\"Des says you're good at the growing part. I can't pay you properly. I can pay you something.\""
7. **choice** — text: "Behind him, through the doorway, somebody's homework is still half done."
   - **"I'll do it"** → "\"Right. Good. Thank you.\" He busies himself with the till so neither of you has to be looking at the other."
   - **"You don't have to pay me"** → "\"I do, though.\" He says it flatly, and it is the only time he has been immovable about anything. \"I'll pay you something. I'm not having it be a favour.\""
8. **resolution** — "You have taken on somebody's yard. It is not, in any measurable sense, a good use of your afternoons."

**`on_complete`:**
- Create Hakim's vein: an emotion vein in Whitechapel at **`growth: 18`**
  (`sparse` band, drift −2/day), tier `fair`, added to `state.player.veins` with
  its own site. Store its id at `state.collective.hakimVeinId`.
- `set_flag colA1HakimMet true`

**Why the player owns it during the thread:** `Cultivating.cultivate()` operates
on `state.player.veins` only. Hakim hands it over to be worked and gets it back
at S12. This is the cheapest correct shape and it is also better fiction than a
special-cased "cultivate someone else's vein" path.

**Balance:** from 18 to 60 is roughly four successful cultivates at skill 2
(`cultivate_gain` = `(10 + 4×skill) × (1 − growth/ceiling)`, so ~14 at growth 18
falling to ~9 near 50), against a 0.42 success chance — about nine to ten blocks,
three to four days, while drifting −2/day in `sparse` and −1/day in `thinning`.
A real job with mild time pressure and **no collapse risk** in the window
(collapse only rolls at growth 0). Do not start it lower.

### 6.12 S12 — `col_a1_hakim_done` · handing it back

**Delivery:** Hakim action bar, enabled by `colA1HakimRescued`
(`vein_growth_above`, threshold **60**).

**Cards:**

1. **narration** — "The yard looks exactly the same. The vein does not. It reads as taking, and rising."
2. **Hakim** — "\"That's better than my uncle had it.\" He says this and then looks slightly stricken, as though he has been disloyal.\""
3. **narration** — "He pays you. It is not very much and he has clearly thought about the amount, and there is no version of refusing it that isn't worse."
4. **Hakim** — "\"Listen. I hear things. Not — I'm not anybody, I just stand here and people talk. If I hear about ground going, round here, I'll text you. That's not me paying you back, that's just — I'll text you.\""
5. **resolution** — "You have made a newsagent's yard marginally more productive. Somewhere in the calculation of what you have spent your week on, this is either the least or the most important thing, and it won't be clear which for some time."

**`on_complete`:**
- Transfer the vein to the Collective at £0 via `VeinTrade` (no payment path;
  a direct transfer, same code path, price 0)
- `add cash` — a small, deliberately inadequate amount: **£120**
- relation `factions.collective +8`
- `set_flag colA1HakimThreadDone true`, `set_flag hakimIntelUnlocked true`

### 6.13 S13 — `col_a1_archie_pry` · the decoy (optional, missable)

**Delivery:** Archie's **existing** contact card, from `colA1ArchiePryAvailable`
until Act 1 completes. Not a text — the player has to go looking.

**Cards:**

1. **narration** — "You mention Des. Archie's face does the thing it does, which is nothing at all, quite deliberately."
2. **Archie** — "\"He's good at ground. Best I know. Leave it there.\""
3. **choice** — text: "He very obviously wants to leave it there."
   - **"Leave it"** → "You leave it. He looks briefly grateful and then annoyed with himself for looking grateful." · no effects
   - **"Push"** → sets `colA1AskedAboutDebt true`, continues to card 4
4. **Archie** — "\"Four hundred and twenty quid. Fourteenth of March, 2019. I know because I wrote it in the book, because that's what you do.\""
5. **Archie** — "\"He's had six years and about nine conversations to say 'here's your money' and instead I get — \" he does an impression that is unkind and quite accurate — \" 'we're all right, aren't we.'\""
6. **narration** — "It is four hundred and twenty pounds. Archie has, in the time you've known him, given away a vein."
7. **Archie** — "\"Also, he's Crystal Palace. Obviously untrustworthy.\" He says it in the specific tone of a man producing a joke because the real answer has run out."
8. **resolution** — "So that's what that is. A tenner's worth of grievance with six years of compound interest on it. You stop wondering about it, which is exactly what you were supposed to do."

**Rules:**
- **Player-pried only**, per §4.7. If the player never pushes, they never get the
  explanation. Archie's *dislike* remains visible in every scene regardless; only
  the reason is gated.
- `colA1AskedAboutDebt` is recorded so Arc 3 can play the reveal warm (a player
  who was told the tenner story) or cold (one who never asked).
- Des's counterpart — "settled up ages ago", no amount, no date, mild warmth —
  is in S3 card 6's neighbourhood. **It must not land in the same scene as the
  keyring or the debt** (§4.7). See §6.14 for exact placement.

### 6.14 Des's "ages ago" line — placement

Delivered **unprompted, in passing**, as an inserted card in S7
(`col_a1_des_report`) between cards 2 and 3, so it lands after the keyring (S1)
and before or after the debt (S13, player-timed) but never beside either:

> **Des** — "\"Archie all right? We go back — years, that. Had a bit of business
> once, sorted it out ages ago.\" He says it with the mild warmth of a man
> recalling a settled account, and moves on before you can ask which business."

**Neither man is lying.** Archie thinks in transactions, which clear, and recalls
the amount and the date. Des thinks in relationships, where itemising is gauche,
and recalls the *feeling* of having settled. The asymmetry is the point: **Des is
a man who sincerely believes things that are not true, when believing them is
more comfortable** — which is the exact psychology of the Arc 3 betrayal, planted
in Act 1 disguised as a joke about four hundred and twenty quid.

### 6.15 S14 — `col_a1_closer` · "There's no list"

**Delivery:** Hakim text, pushed when **all three thread-done flags are set**
AND `state.factions.collective.relation >= 25`.
**Text:** *"Are you about? Nothing's wrong. Come to the shop."*

**Cards:**

1. **narration** — "All three of them are in the yard, which has never happened before and is not, apparently, an occasion. Nadia is sitting on an upturned crate. Des has his bag."
2. **Hakim** — "\"So there's a spot behind the flats on the other side of the estate. Been looking at it for about a year, wondering.\""
3. **Hakim** — "\"It's life. Which is wrong for round here — round here is emotion, everyone knows that. But it's life, and it's good ground, and I don't know what to do with good ground.\""
4. **Hakim** — "\"You're the one who's good at putting things in. So.\""
5. **narration** — "Des has already got the jar out of his bag. He does not make a speech about it. He does not appear to have considered any other course of action."
6. **Des** — "\"Forty units, life. Had it about a month waiting for somewhere to put it.\""
7. **choice** — text: "You start to say something about paying him back."
   - **"Thank him"** → "\"You're all right,\" he says, and means it, and the subject is closed."
   - **"Insist on paying"** → "\"You can pay me back by doing this for somebody else in about a year.\" He hands you the jar. \"That's not me being nice, that's just how the accounting works round here.\""
8. **narration** — "It takes first time. The three of them watch you do it and then go straight back to talking about somebody's boiler."
9. **narration** — "Later, walking back, you ask Des how you'd actually join. Whether there's someone to ask."
10. **Des** — "\"There's no list. Nobody keeps one.\" He seems mildly amused you'd think there was. \"You've been doing this with us for a month. You're either one of us or you're not, and that's not really my call.\""
11. **Nadia** — "\"He means yes.\""
12. **choice** — text: "Behind you, Whitechapel does what it does."
    - **"I'm in"** → "\"Right,\" says Des, and that's the ceremony." · effects: `Factions.join("collective")`, `set_flag colA1Joined true`
    - **"Not yet"** → "\"Fair enough.\" He isn't offended and doesn't pretend not to be offended, which is worse and better at once. \"Offer doesn't expire. There's nothing to expire.\"" · effects: `set_flag colA1DeferredJoin true`
13. **resolution** — "You have a life vein in Whitechapel that a newsagent found and a prospector paid for, and no document anywhere records that any of this happened."

**`on_complete`:**
- `set_flag colA1Stage "complete"`, `set_flag colA1Complete true`
- Membership handled by the choice, not by `on_complete`

**Mechanics:**
- The site is **created by the event** — Whitechapel, tier `rich`, `oreType: life`
  — not found in the world, so it is guaranteed present. Guard: if Whitechapel is
  at `siteCap` (7), the event still creates it; the cap governs prospecting
  discovery, not scripted creation. Document this exception.
- **The seed is applied in-scene.** No ore passes through
  `state.player.orichalchum` at any point. This is not a `add_ore` followed by a
  seed; it is a single new effect op (§10.2) that creates the site, creates the
  vein, and claims the site, exactly as a successful `Sites.attempt_seed()` would.
  40 life calc is ~£2,800 of ore at base price against a starting cash of £40 —
  if it entered inventory the player could simply sell it and skip the early
  economy.
- The seed **always succeeds**. This is not a cheat: Des is the master seeder who
  has spent the entire act teaching the player, and the fiction is that he does it
  with them. A 50% roll (0.30 base + 0.20 `rich` tier mod at skill 1) eating the
  act's reward would be indefensible.
- **Declining is not a failure state.** `colA1DeferredJoin` leaves a permanent
  "Ask Des about joining" entry in Des's action bar which fires a two-card event
  granting membership.

**Why this is the closer.** The act ends with a named person explaining that the
absence of a list *is* the organisation. Arc 2's first requirement is somebody
writing one. The player will have been told, in so many words, why that is the
one thing that cannot be done — and will then help do it because it is obviously
sensible.

### 6.16 `col_hakim_intel` · repeatable, post-Act-1

**Delivery:** Hakim text via `pendingMessages`, carrying `siteId` in `payload`.

**Cards (2, deliberately short):**

1. **Hakim** — "\"Bloke came in for a Lucozade and wouldn't shut up about the yard behind the launderette. Might be nothing. Thought you'd want it before somebody else does.\""
2. **resolution** — "It is on your map now. He will not mention it again and will be embarrassed if you thank him twice."

**`on_complete`:** reveal the site (already created at roll time); clear the
pending message; set `state.collective.hakimIntelLastDay`.

Firing rules in §5.8.

---

## 7. Contacts — UI and surfaces

### 7.1 Suppressing the recruit row

`ContactCards.build_recruit_row()` is currently unconditional and renders
"⭐ Recruit X (N relation needed)" disabled. Des, Nadia and Hakim must show **no
recruit row at all** in Act 1. Add a per-contact `recruitable: bool` to
`data/constants.json`'s contact defaults, defaulting true so Archie and James are
unchanged, and skip the row when false.

Nadia flips to `recruitable: true` at the end of Act 3. That is Act 3's spec, not
this one.

### 7.2 Action bar contents

Per contact, in order:

| Contact | Story actions (conditional) | Standing actions |
|---|---|---|
| Des | tuition follow-ups, "Tell Des about the ground", "Ask about joining" (if deferred) | Trade |
| Nadia | "Go and see Nadia", the vein ask | Trade |
| Hakim | "Go and see Hakim", "Hakim's heard something" | Trade |

Trade opens the existing `sell_menu` modal, routed through the faction lane
rather than Archie's.

---

## 8. Economy

### 8.1 The Collective lane

Unlocked at S1, **pre-join**, gated on `flags.collectiveLaneUnlocked`.

| Relation | 0 | 25 | 50 | 80 | 90+ |
|---|---|---|---|---|---|
| **Sell rate** (× barometer-effective base) | 0.55× | 0.66× | 0.77× | 0.91× | 0.95× |

- Sell spread: **0.45 at relation 0 → 0.05 at relation 90**, linear, flat
  thereafter. Anchor relation **0** (not `joinRelation`, unlike the Guild).
- **The formula is authoritative; the table is derived from it.** The rates
  sketched during the design session (0.64 / 0.75 / 0.89 at 25 / 50 / 80) were
  approximations of this curve and are 1–2 points low; the values above are the
  exact linear results. If the intended curve is the sketched one instead, the
  spread must become piecewise and this table is what changes.
- Buy spread: **0.15 at relation 0 → 0.05 at relation 90**, linear. Decoupled
  from the sell spread deliberately — they do not gouge their own.
- **No mugging risk. No district `priceMod`.**

### 8.2 Archie, rebalanced

`PLAYER_CUT_RATIO` becomes relation-scaled:

| Archie relation | 10 (start) | 40 | 80 (recruit threshold) |
|---|---|---|---|
| **Cut** | 0.60× | 0.71× | 0.85× |

Linear between 10 and 80, flat outside. Everything else about his lane is
unchanged: district `priceMod` still applies (up to +15% in the City), the
`MUG_BASE_CHANCE` 0.20 + district `dangerMod` roll still fires, and a mugging is
still a *fight* that pays out in full on a win (`complete_mugged_sale()`).

**The choice is legible in one sentence:** *Archie pays more and might cost you a
fight; the Collective pays less and never will.* Early on Archie is better if the
player can handle themselves, which is a real decision at 100 HP and level 1. Late
on they converge and the player picks on temperament.

It also finally gives Archie's relation track a mechanical payoff — it currently
does nothing but gate recruitment at 80.

### 8.3 Vein sale prices

`VEIN_SALE_BASE_UNITS = 35`. Worked examples for life calc (`basePrice` £70):

| Vein | Growth factor | Terroir | Price |
|---|---|---|---|
| Fresh seed, `fair` | 0.4 | 1.0 | £980 |
| Fresh seed, `rich` | 0.4 | 1.6 | £1,568 |
| Neutral (Dormant), `rich` | 1.0 | 1.6 | £3,920 |
| Lush (85), `fair` | 1.7 | 1.0 | £4,165 |
| Lush (85), `rich` | 1.7 | 1.6 | £6,664 |
| Rampant (100), `rich` | 2.0 | 1.6 | £7,840 |
| Lush (85), `saturated` | 1.7 | 2.4 | £9,996 |

Against a seed cost of 40 ore — £2,800 of life calc at base, realistically
**~£1,700** once sold through a lane at a spread. So flipping a fresh seed
**loses money**; cultivating to Lush roughly **quadruples** the return. The one
leak is a fresh `saturated` seed (£2,352) — a 4% site roll, a windfall rather
than a farm, and allowed to stand.

### 8.4 Relation accrual — the one rule

> **Trade feeds the meter that owns the lane.**

The Collective lane feeds `state.factions.collective.relation`. Archie has no
faction — he *is* the lane — so his feeds `state.contacts.archie.relation`. Des,
Nadia and Hakim get **no personal trickle**, because the meter their lane feeds
already exists above them; their personal relation moves only when the story says
it does.

**Accumulate, never award per transaction** — otherwise a player farms +1 per £20
sale:

| Lane | Accumulator | Rate | Daily cap |
|---|---|---|---|
| Collective | `state.factions.collective.tradeProgress` | +1 relation per **£750** | **+3/day** |
| Archie | `state.contacts.archie.tradeProgress` | +1 relation per **£1,000** | **+2/day** |

The accumulator carries the remainder, so nothing is wasted and small trades
still count toward the next point. Daily caps reset on `daily_tick`.

**Vein sales count** toward `tradeProgress` at their sale price like any other
trade.

**Archie's pre-existing flat `ARCHIE_SALE_RELATION_GAIN` (+2 relation per
completed sale, mugged or not — bugfixes-63, R§3.6) stays, on top of this
accumulator, by explicit human decision.** It predates this ticket and isn't
the farm this rule is closing — it's a fixed, small, per-sale bump uncoupled
from sale size, not a rate that scales with how a sale is sliced. Ticket 06
(relation-accrual) briefly removed it on the reasoning that any per-transaction
award is the exact shape of farm this section forbids; that removal was
reverted on review. Keep both: `execute_sale` awards the flat +2 *before*
computing the cut (so the cut ratio reflects it, same as always), then accrues
`tradeProgress` on `gross` *after* the cut is computed (so a single large sale
crossing the £1,000 rate doesn't inflate its own cut on top of the flat
award's — see `systems/economy.gd`'s `execute_sale`).

### 8.5 Thread awards, and why the gate opens on favours

| Beat | Award |
|---|---|
| S1 — meeting Des | +3 |
| S7 — Des's thread | +8 |
| S10 — Nadia's thread | +8 |
| S12 — Hakim's thread | +8 |
| **Total from favours alone** | **27** |

A player who never sells the Collective a single unit still crosses 25. **The
gate opens because you helped three people**; trade is only the accelerant that
gets an efficient player there sooner.

The closer fires on *all three threads complete* **and** relation ≥ 25. The
second condition is guaranteed by the first, but it is stated that way so the
spine's "gate at 25" contract holds for the four factions that inherit the
engine.

At the +3/day cap, Arc 2's gate at 50 is roughly nine trading days past Act 1,
and Arc 3's at 80 another ten — before whatever those arcs award directly.

### 8.6 Joining

`data/factions.json` `collective.joinRelation`: **20 → 25**, so the data and the
fiction agree.

**The generic Join button is suppressed for the Collective.**
`ContactCards.build_faction_card()` shows no Join affordance for `collective`;
membership is granted only by S14's choice card (or the deferred-join follow-up).
The other four factions keep the button until their own storylines land.

Reason: `docs/VISION.md` §14 makes joining lock rivals' storylines — one of the
least reversible decisions in the game, currently a button attached to no fiction
at all.

**And the Collective is exempt from that lock.** Joining the Collective does
**not** gate the player out of engaging with or joining other factions, because
the Collective is not a formal organisation and there is nothing to be exclusive
about. This is a deliberate deviation from §14 (see §13) and it is what makes the
Collective the natural first faction rather than a trap.

*Deferred, not decided:* whether joining another faction later locks *the
Collective's* storyline. That is Arc 2's problem, since the Firm is Arc 2's
antagonist.

---

## 9. Data

### 9.1 New event files

`data/events/col_a1_{intro,prospecting,seeding,hub,firm_skirmish,firm_intimidation,des_report,nadia_meet,nadia_vein,nadia_done,hakim_meet,hakim_done,archie_pry,closer}.json`
plus `data/events/col_hakim_intel.json`. All added to `GameData.EVENT_IDS`.

### 9.2 `data/objectives.json`

Four objectives across the three threads — Nadia's thread is two sequential
objectives, activated in turn:

| id | type | key params |
|---|---|---|
| `col_a1_des_sites` | `sites_discovered_matching` | `requireEachOreType: ["fate","physics"]`, `minTier: "fair"`, `unclaimed: true` |
| `col_a1_nadia_supply` | `traded_with_faction` | `factionId: "collective"`, `oreType: "emotion"`, `qty: 30`, `minTransactions: 3` |
| `col_a1_nadia_vein` | `vein_sold_to_faction` | `factionId: "collective"`, `oreType: "emotion"` |
| `col_a1_hakim_rescue` | `vein_growth_above` | `veinIdStatePath: "collective.hakimVeinId"`, `threshold: 60` |

### 9.3 `data/constants.json` — contacts

Add `des`, `nadia`, `hakim` with `startRelation: 0`, `unlocked: false`,
`recruitable: false`, `recruitThreshold: 0`. Add `recruitable: true` to `archie`
and `james`.

### 9.4 `data/faction_trade.json` (new)

Per-faction lane configuration, replacing the hardcoded `GUILD_SPREAD_MAX` /
`GUILD_SPREAD_ZERO_RELATION` constants:

```json
{
  "guild":      { "anchorRelation": 40, "zeroRelation": 90, "sellSpreadMax": 0.15, "sellSpreadMin": 0.0,  "buySpreadMax": 0.15, "buySpreadMin": 0.0,  "memberOnly": true,  "applyDistrictPriceMod": false, "mugRisk": false },
  "collective": { "anchorRelation": 0,  "zeroRelation": 90, "sellSpreadMax": 0.45, "sellSpreadMin": 0.05, "buySpreadMax": 0.15, "buySpreadMin": 0.05, "memberOnly": false, "applyDistrictPriceMod": false, "mugRisk": false }
}
```

The Guild's row must reproduce today's behaviour exactly; a test asserts that.

### 9.5 `data/collective_barks.json` (new)

Per-vendor flavour lines drawn on completing a trade. **Cosmetic only** — the
three doors have identical terms. Minimum 6 lines each, no-repeat-until-exhausted
tracked in `state.collective.barkCursors`.

Register examples (`PROSE-REVIEW:`):

- **Des** — "\"That'll go to Sandra in Peckham, if you're wondering. She won't know it was you.\""
- **Nadia** — "\"Counted. Correct. Go on then.\""
- **Hakim** — "\"I'll put it under the counter with the other thing I'm not supposed to have under the counter.\""

### 9.6 `data/vein_growth.json`

Add `veinSaleBaseUnits: 35`.

---

## 10. State schema and effect ops

### 10.1 Additions to `GameState.new_game_state()`

```
"objectives": {},
"messages": {},
"pendingMessages": [],
"methodLog": {},
"collective": {
    "hakimVeinId": null,
    "hakimIntelLastDay": 0,
    "barkCursors": {},
},
```

Plus per-faction `tradeProgress: 0` in `_new_factions_state()`, per-contact
`tradeProgress: 0` and `recruitable: bool` in `_new_contacts_state()`, and daily
caps: `state.world.relationAwardedToday = {}` (reset on `daily_tick`).

**Everything is Dictionaries, Arrays and primitives.** No object references, no
Nodes, no Callables. Saves, snapshots and Rewind all work by construction.

**`SaveManager.backfill_defaults()` must seed every new key** so existing saves
load. `_restore_int_types()` must cover the new integer fields
(`tradeProgress`, `hakimIntelLastDay`, message `day`), since JSON round-trips
them to float.

### 10.2 New flags

`colA1Stage` (String), `colA1DesMet`, `colA1ProspectingTaught`,
`colA1SeedingTaught`, `colA1HubReached`, `colA1DesThreadActive`,
`colA1DesSitesFound`, `colA1DesThreadDone`, `colA1SkirmishSeen`,
`colA1IntimidationSeen`, `colA1NadiaMet`, `colA1NadiaSupplied`,
`colA1NadiaAskSeen`, `colA1NadiaThreadDone`, `colA1HakimMet`,
`colA1HakimRescued`, `colA1HakimThreadDone`, `colA1ArchiePryAvailable`,
`colA1AskedAboutDebt`, `colA1Complete`, `colA1Joined`, `colA1DeferredJoin`,
`collectiveLaneUnlocked`, `veinSaleUnlocked`, `hakimIntelUnlocked`.

### 10.3 New effect ops for `Events._apply_one()`

| op | does |
|---|---|
| `scripted_seed` | Creates a site (district, tier, oreType from the effect), creates a claimed vein on it at `seedGrowth`, appends both, queues the map events. **No ore cost, always succeeds.** Used only by S14. |
| `faction_seed_reported_sites` | For each site recorded in the `col_a1_des_sites` objective's progress, calls `Factions.create_faction_vein()` for `collective` and queues the map events |
| `grant_contact_vein` | Creates a vein and stores its id at a named state path. Used by S11 for Hakim's yard vein. |
| `log_method` | Writes `state.methodLog[key] = value` |
| `activate_objective` / `complete_objective` | Sets `active` / forces `complete` on a named objective |
| `unlock_contact` | Sets `state.contacts[id].unlocked = true` |
| `push_message` | Appends a text to a conversation and marks it unread |

### 10.4 Trigger ordering — the weather beats

S5 and S6 fire from the same place `DistrictDeck.maybe_trigger()` is called at
the end of `Sites.prospect()`. **The story beat is checked first**, and if it
fires, the deck draw is skipped for that action — otherwise two events would
queue on the same tap. Because the deck draw consumes a seeded RNG roll, the skip
must be a genuine early return, not a discarded draw, and this ordering must be
asserted by a test.

---

## 11. What the player sees — Notes

`systems/todo.gd` gains a Collective section rendering live objective state. The
existing hardcoded tutorial chain is untouched and still shows its last four
items. Collective objectives render below it, and disappear when Act 1 completes.

Without a visible list, "reach out to whoever you like, in any order" reads as
"nothing is happening."

---

## 12. Testing

Per the constitution: every touched `.gd` gets
`godot --headless -s scripts/check_runner.gd -- <file>`, and `scripts/run_tests.sh`
must pass.

### 12.1 The acceptance gate

**`tests/test_playthrough.gd`, extended.** The existing headless playthrough
drives the M0 tutorial through `Events.start_event` / `advance` / `choose`
directly. Act 1 continues that walk: tutorial end → S1 → S2 → S3 → S4 → all three
threads (driven by really calling `Sites.prospect()`, `Economy` sales,
`Cultivating.cultivate()`, `VeinTrade.sell_to_faction()`) → S14 → membership.

**One test proving the act is completable end to end and every flag lands.** This
is the acceptance criterion for the act as a whole; no ticket closes the act
without it green.

A second variant must walk the **decline** branch at S14 and confirm the deferred
join event grants membership later.

### 12.2 Unit seams

| Seam | Asserts |
|---|---|
| `Objectives` | Each of the four evaluator types against synthetic state. Idempotency of `refresh()`. That `refresh()` never awards. |
| `Economy` | The exact rate tables in §8.1 and §8.2. That the Guild's numbers are unchanged by the generalisation. |
| `VeinTrade` | `quote()` against the §8.3 table. `sell_to_faction()` removes the vein from `player.veins`, creates `site.factionVein`, credits cash, queues the map event. |
| Relation accrual | £750/£1,000 thresholds, remainder carry, daily caps, cap reset on `daily_tick`. |
| `pendingMessages` / `messages` | Append, unread, mark-read, 50-message cap eviction. |
| `MapPins` | `minRelation` and `minDay` gates, alone and combined with flags. |
| Trigger ordering | S5/S6 pre-empt the deck draw; the deck's RNG roll is genuinely not consumed. |
| Data validity | Every new event JSON loads; every flag, op and objective id referenced exists. Extend `GameData.validate()`. |
| Save compat | An old save loads through `backfill_defaults()` with every new key seeded and int types restored. |

### 12.3 Not tested headless

The conversation screen, the action bar and the Notes rendering. These go on the
per-ticket **manual QA list** the constitution requires, not into tests that
would need the scene tree.

---

## 13. Required document amendments

Each must land in the **same ticket** as the code that contradicts the current
text.

| Document | Amendment |
|---|---|
| `docs/VISION.md` §14 | Contact budget "+1–2 new contacts by 1.0" → accommodates three new Collective contacts |
| `docs/VISION.md` §14 | "Joining one faction locks its rivals' storylines at event 2" → **the Collective is exempt**, because it is not a formal organisation |
| `docs/VISION.md` §13 | Selling lanes "faction fronts (M5)" → the Collective front unlocks in Act 1, pre-join |
| `docs/REFERENCE.md` R§3.6 | `PLAYER_CUT_RATIO` 0.5 flat → relation-scaled 0.60–0.85 |
| `data/factions.json` | `collective.joinRelation` 20 → 25 |
| `plans/COLLECTIVE-QUESTLINE.md` §9 | Open questions **1** (names), **2** (spine reward) and **6** (which contacts get relation tracks) are closed by this document |
| `plans/COLLECTIVE-QUESTLINE.md` §5 | Arc 1's description is superseded by §4 and §6 here |
| `plans/COLLECTIVE-QUESTLINE.md` §8.1 | The `joinRelation` problem is resolved as described in §8.6 |
| `plans/COLLECTIVE-QUESTLINE.md` §8.3 | The Rewind/method-log question is decided: Rewind erases it |

---

## 14. Risks and open items

### 14.1 Balance — needs a playtest checkpoint

**Early income rises materially and from two directions at once:** Archie's cut
goes 0.5 → 0.60 on day one, and the Collective lane arrives at 0.55× with no
mugging risk immediately after the tutorial. The two push the same way.

The vein sale price in §8.3 is calibrated against "what 40 ore is really worth",
whose denominator is the Collective spread. **The lane's rates must be settled
and observed before `VEIN_SALE_BASE_UNITS` is treated as final.**

Ticket sequencing should put the economy changes before the vein sale, and the
spec's acceptance should include a human playtest of days 1–14, not just green
tests.

### 14.2 Deliberately deferred

- **Migrating Archie's and James's SMS screens** to the new Messages app.
- **A rewind-at-choice-point counter** in the method log (Arc 2 may want it).
- **Whether joining another faction later locks the Collective's storyline.**
- **Hakim's raid tips** — Arc 2.
- **Arc 2's free-form objectives** — the engine is built for them here; no
  evaluator types beyond the four in §5.1 should be added speculatively.

### 14.3 Prose

Every line in §6 and §9.5 is `PROSE-REVIEW:` draft. Specific things to audit
hardest, because the whole questline rests on them:

1. **Des must be the best-written character in the game and the one the player
   likes most** (§4.1 of the questline doc). If he reads as a plot device with a
   twist attached, Arc 3 fails.
2. **S7 card 4** — "Nobody's ever raided a vein they didn't know about" — must
   land as a mild joke about paperwork, never as a thesis statement.
3. **S14 card 10** — "There's no list. Nobody keeps one." — is the act's hinge.
4. **S6** must not read as a threat the player can act on.
5. **No fandom banter anywhere.** One keyring, mentioned once, in one clause. One
   Trek line, said once here and once in Arc 3. No exchanges about either.
6. **The record-keeping is never described as sinister** — there is barely any of
   it in Act 1, and the one mention (S4 card 7, the receipt) must read as
   charming.
