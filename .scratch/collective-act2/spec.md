# PRD — The Collective, Act 2: "Conflict"

**Status:** Draft from a design session (2026-09-05). Every decision below was
put to the human and confirmed in conversation. Open items are listed in §12
and must be resolved before tickets that depend on them are worked.

**Written against the live development line, on top of Act 1**
(`.scratch/collective-act1_COMPLETED/spec.md`, henceforth "the Act 1 spec").
Everything Act 1 built — `Objectives`, the Messages app, `pendingMessages`,
`MapPins` gating, the generic faction trade lane, `VeinTrade`, `state.methodLog`
— is assumed live and is reused, not rebuilt.

**Terminology:** `plans/COLLECTIVE-QUESTLINE.md` calls this "Arc 2". This
document and all its tickets call it **Act 2**. Same content, matching Act 1's
own renaming.

**Scope of authority:** canonical for the mechanics and content it defines.
Where it conflicts with `docs/VISION.md`, `docs/REFERENCE.md` or
`plans/COLLECTIVE-QUESTLINE.md`, **this document wins**, and the conflicting
document must be amended in the same ticket that lands the conflicting code.
§11 lists every amendment required.

**All new prose in this document is `PROSE-REVIEW:` material.** Sample lines
below are a drafted first pass against `docs/CONTENT-GUIDE.md` §3, not
approved copy.

---

## 1. Why

Act 1 ended on a thesis stated out loud: *"There's no list. Nobody keeps
one."* Act 2's entire job is to be the arc where that stops being true, and to
make the player complicit in why.

**The key finding that shapes this spec:** the Firm-vs-Collective war is not
new content to invent. `systems/factions.gd`'s rivalry sim
(`roll_rivalry_attempts` / `resolve_rivalry_outcome`) already runs every faction
against every other faction on a daily tick, weighted by industry — the Firm's
`raiding` industry (`INDUSTRY_AGGRESSION.raiding = 0.35`) makes it by far the
most aggressive attacker in the game, and it has been quietly raiding the
Collective's veins since day one of every save. It is also, per the code's own
comment, **completely silent** — "the player only discovers changes by
looking at the map." Act 2's job is to make an already-running background
process visible, felt, and actionable — not to build a war from scratch.

**The information thesis, mechanically stated:** the Collective's own veins
already exist as a queryable list in `state` (every site with
`factionVein.factionId == "collective"`) — they always have, because ownership
has to be represented somehow. What Act 1 kept true was that *nobody player-
facing ever saw that list rendered as a list*. Act 2's actual sin is not a new
data structure; it is **exposing an existing one to the player as UI for the
first time**, and dramatizing why that exposure is exploitable. This is
deliberately budgeted as a small change (§5.5), because the point is that the
temptation was always cheap.

**What Act 2 must achieve, in the questline's own terms** (`plans/
COLLECTIVE-QUESTLINE.md` §5): make the Firm's pressure legible and actionable;
let the player win for real, with the balance genuinely shifting; open the
Network thread through Nadia, and make the record-keeping read as relief, not
dread; and land Hakim's cost in a way that gives Act 3 real ammunition against
Des without making Des's position collapse.

---

## 2. Scope

### In scope

| | |
|---|---|
| Content | 15 authored events/scenes across four phases, one repeatable spine-reward extension |
| Engine | 3 new `Objectives` evaluator types (Nadia's mission dispatch); 2 new Network-handler effect ops + supporting state; 3 one-off scripted vein-transfer/ruin effect ops (Hakim's vein, the second loss, the ruin); Notes-app "Collective ledger" section; `methodLog` extensions |
| Balance | Handler pricing (first-pass, playtest-pending per §12.1); relation award table for Act 2's own gate |
| Docs | Amendments listed in §11 |

### Out of scope

- **Dials, James, or "going outside the Collective."** Per `plans/
  COLLECTIVE-QUESTLINE.md` §5, that escalation belongs to Act 3 — Act 2 is
  "we handled this with what we already had, plus the Network"; Act 3 opens
  precisely because that stops being enough. Nothing here should make James
  necessary yet.
- **Des's leak being confirmed, hinted mechanically, or named.** Act 2 plants
  fair-play data (two losses that beat the odds — §6, T10 and T11) and nothing
  more. No flag, no UI, no dialogue line so much as gestures at Des specifically.
- **A general "vein exhaustion" or "site can be permanently ruined" system.**
  Explicit human decision: Hakim's vein's ruin (§5.4, T13) is a one-off
  scripted effect on one site id, the same shape Act 1's `scripted_seed` was a
  one-off used only by S14. No new tier, no new field on the generic vein
  schema, no code path any other site can ever hit.
- **A named, relation-tracked Firm contact.** Explicit human decision: the
  Firm's negotiating face (§3.2) stays a procedural, unnamed role — dialogue
  only, no Contacts-app card, no relation track. It is not spending any of the
  Firm's own future M5 storyline budget.
- **Fixing the rivalry sim's general silence.** Ambient Firm pressure (Phase 2's
  free-form loss/hold objectives) stays exactly as silent as it is today —
  discoverable via the map and the new Collective ledger, same as any other
  faction's territory changes. Only Act 2's two *named* losses (T10, T11) are
  guaranteed and delivered as messages, and they are scripted, not sim-driven,
  specifically so they don't require touching the general Notify pipeline.

---

## 3. Cast

No new relation-tracked contacts. Des, Nadia and Hakim are exactly the Act 1
cast; their voices are Act 1 spec §3's canon.

### 3.1 Recap — voices to hold

- **Des** — warm, unhurried, teacherly, never raises his voice. In Act 2 he is
  *right about small things and behind on the big one*: right that "don't
  jump to extremes" was the correct call at T4, right to be uneasy about
  Nadia's ledger at T8-T9 — and still wrong that caution alone would be enough,
  which Act 2 proves at T10-T11 without ever making him say so.
- **Nadia** — fast, dry, practical. Act 2 is her arc more than anyone's: she
  goes from "buy the intel" (deferred at T4) to "get organised ourselves"
  (T8) to "something's wrong here, go and ask" (T11-T12) — three different
  routes to the same instinct, each one more reasonable than the last, each
  one a little further from how the Collective used to work.
- **Hakim** — tired, kind, apologises for asking for things. Act 2 takes
  something from him that cannot be given back, and he does not get an
  ideology about it. He gets a family, a shop, and a hole in the ground where
  his uncle's vein used to be.

### 3.2 The Firm's face — procedural, not a contact

**Deliberately unnamed.** Appears in event text as "the Firm's man" or
similar — same register as Act 1 S6's "Firm Man" — at every scene where the
player transacts or negotiates with the Firm directly (T5's buyback, T13's
retake if bought rather than fought). No Contacts-app card, no relation track,
no `data/constants.json` entry.

**Voice, first pass:** professional, unhurried, transactional — the Firm's
"old money, new methods" flavor read as *a person who has never once needed to
raise his voice because the numbers already do the threatening*. Deliberately
rhymes with the Network handler (§3.3) rather than with a stock enforcer:
**everyone else in this world runs a business; only the Collective runs on
favours.** That contrast is doing real thematic work and should not be
softened into generic menace.

> PROSE-REVIEW: "You want it back, that's a price, same as anyone's. We're not
> precious about it. It was never really ours, was it — three weeks in a
> ledger doesn't make it family."

### 3.3 The Network handler — recap, unchanged from the brainstorm

Introduced properly at T12. Per `plans/COLLECTIVE-QUESTLINE.md` §4.8: the
handler never lies, everything sold is true, fairly priced, and ruinous.
Nothing in this spec changes that contract; it only decides what, concretely,
gets sold (§5.3).

---

## 4. Act structure

```
Act 2 opens: colA1Complete AND state.factions.collective.relation >= 25
        │
        ▼
  PHASE 0 — THE CALL (linear, mandatory)
   T1  Des texts, urgent, no detail            [Des text]
   T2  The shop — Hakim hurt                   [Des+Nadia present]
   T3  The pattern — others under pressure too [hub]
   T4  Nadia raises the handler; Des: not yet; agreed [choice, low-stakes]
        │
        ▼
  PHASE 1 — HARDENING (legitimate toolkit only, player-ordered)
   T5  Contested vein   — hard: claim / soft: buy back           [choice]
   T6  Vulnerable site  — hard: permanent lookout / soft: as-is  [choice]
   T7  Hostile member   — absorb / make an example / protect     [choice]
   T8  Nadia's ledger — she documents the Collective properly for
       the first time; dispatches missions                      [hub, activates objectives]
        │  (col_a2_nadia_reseed runs in parallel with T5-T7, player-ordered;
        │   col_a2_nadia_supplies must be done before its follow-up below)
   T8a col_a2_nadia_defend_brief — fires on supplies complete;
       names the vein, activates col_a2_nadia_defend, pre-fight
       reminder card fires when that encounter opens              [scene → gated combat]
        │
        ▼
   T9  "It's working" — scripted checkpoint. Des disgruntled, doesn't push [scene]
        │
        ▼
  PHASE 2 — THE CRACK (scripted, gated on T8/T9 progress)
   T10 Hakim's vein taken — scripted, despite everything           [Hakim text → scene]
   T11 A hardened site also falls — Nadia clocks the anomaly       [scene]
        │
        ▼
  PHASE 3 — THE MEET (closer)
   T12 Nadia organises a sit-down with the handler; Des objects,
       doesn't block it. Handler intro — Targets & Sourcing unlock [scene]
   T13 Hakim's vein retaken (force or buy, using bought intel) —
       ruined ground either way                                    [choice + scripted effect]
        │
        ▼  gate: T5, T6, T7 and T13 all resolved AND relation >= 50
  PHASE 4 — SETTLE
   T14 Spine reward — the grapevine starts flagging weak enemy
       veins too, not just fresh ground                            [silent unlock + one text]
   T15 Closer — the ledger read as relief, not dread. Des's unease
       surfaces once, briefly, and is dropped                      [scene]
```

### 4.1 Why the phases are ordered this way

The original brainstorm had Nadia's handler pitch land immediately and
uncontested. The human's correction is the better story: **the Collective
tries the honest, legitimate version first, and it actually works for a
while** (T5-T9). That is Act 2's real victory per `plans/
COLLECTIVE-QUESTLINE.md` §2 — "Arc 2's victories are real" — and it is what
makes Des's caution at T4 look *vindicated* right up until T10-T11 prove it
insufficient rather than wrong. Nobody's argument gets refuted; events simply
outrun it.

### 4.2 T8/T9 relationship to T10/T11 — the trap being set

T10 and T11 must land as **despite**, not **because of**, T8's hardening.
T11 specifically should target whichever vein T8's "defend" mission was
actually protecting, or — if the player never completed that mission —
the Collective's single highest-security vein at the time T11 fires. The
point is precision: this is not a random loss among many, it is the loss that
should have been the least likely one, and Nadia has to be the one who notices
that arithmetic doesn't add up (§6, T11).

---

## 5. New machinery

### 5.1 Nadia's ledger & directed missions

`col_a2_nadia_ledger` (T8) activates exactly **three** new objectives,
mirroring Act 1's "exactly four, do not add more" discipline — three new
evaluator types, one per mission archetype the human specified:

| id | type (new) | params | evaluates |
|---|---|---|---|
| `col_a2_nadia_defend` | `alarm_defend_wins` | `minCount: int` | Count of `Raiding.resolve_defend_outcome(won=true)` calls against a Collective-owned vein since activation |
| `col_a2_nadia_reseed` | `faction_vein_seeded_count` | `factionId: "collective"`, `minCount: int` | Count of new Collective-owned veins created (via `Factions.create_faction_vein()` or `VeinTrade.sell_to_faction()`) since activation |
| `col_a2_nadia_supplies` | `items_crafted_set` | `recipeKeys: ["blast","shield","pansPrank"]`, `minEach: 1` | At least one successful craft of **each** named recipe since activation — requires a small persistent counter added at craft-success (none currently exists; smallest correct addition is a flat `state.player.craftedCounts[recipeKey]` dict, incremented in `Crafting.attempt_craft()`'s success branch alongside its existing `inventory_add()` call, mirroring how `state.bankLog`/`state.notifications` are capped-and-flat elsewhere) |

**Nadia funds these, not the player.** Activating T8 should hand over enough
resources (cash and/or ore, exact figures §7.2) to make at least the first
mission attemptable immediately — this is "Nadia gets organised and it helps,"
not "Nadia asks a favour." For `col_a2_nadia_supplies` specifically, the grant
should include enough physics and emotion calc to attempt one of each named
recipe at least once.

**Why a checklist, not a quantity.** `Crafting.can_craft()` gates only on
having the ore for a recipe — there is no recipe-discovery/unlock system live
yet (VISION §9a's Discovery is future M3 scope), so any player could already
craft Blast or Shield today if something ever pointed them at it. Nothing
currently does: most players reach Act 2 having only ever touched Time Pearl
and Enhancement Powder, both taught in the M0 tutorial. `col_a2_nadia_supplies`
exists specifically to be that push — a small, named checklist across
different ore types and effect shapes (**Blast**: physics, direct damage,
ignores Brace; **Shield**: physics, absorbs hits, negates Heavy/Grab;
**Pan's Prank**: emotion, forces Panic/Rage or grants self-Confidence against
a crowd) rather than a quantity target the player could satisfy by spamming
whichever one recipe they already know. This is a content/direction beat, not
a new mechanic — every recipe involved already exists, fully implemented, in
`data/recipes.json`.

**Alarm-defend as authored content, not a new mechanic.** `col_a2_nadia_defend`
is the existing Direction B mechanic (`.scratch/
7-vein-raiding_COMPLETED/issues/07-direction-b-alarm-defend-encounter_
COMPLETED.md`, `Cultivating.ALARM_UPGRADE_ID`, `vein["alarmUpgrades"]`) applied
to a named Collective vein, stored at `state.collective.nadiaDefendVeinId`.
Nothing new required except pointing the mission's target at a specific site
and funding the Alarm upgrade itself as part of T8's resource grant so the
mission is completable without a detour through unrelated cultivating.

**Sequencing: supplies before defend, not parallel.** Human decision this
session — `col_a2_nadia_defend` does not activate at T8 alongside the other
two. It activates only once `col_a2_nadia_supplies` (§ above) completes, via
a short follow-up scene, `col_a2_nadia_defend_brief` (T8a, §6.8a). This turns
the crafting checklist into a lesson the very next mission tests, rather than
two unrelated to-do items the player might tackle in either order or never
connect. `col_a2_nadia_reseed` is unaffected and stays parallel with T5-T7,
since it isn't a combat beat.

**The pre-fight note.** When the alarm-defend encounter tied to
`nadiaDefendVeinId` actually triggers (`Raiding.trigger_defend()`), and only
for that specific vein and only once, its card sequence gets one extra
narration card prepended ahead of the fight — Nadia's voice, brief, naming
the kit rather than lecturing about it:

> PROSE-REVIEW: "Go on then. That's what the Blast and the Shield were for —
> use them properly this time, not for luck."

This is content on one specific scripted encounter, not a change to the
generic alarm-defend system — every other alarm-defend fight in the game,
before or after this one, is unaffected. Exact hook point (a flag-gated extra
card on this one vein's defend-trigger event vs. a small conditional in the
raid-entry card builder) is the implementing ticket's call; either satisfies
the fiction.

### 5.2 The Collective ledger — Notes app

New section in `systems/todo.gd`'s Notes rendering (same pattern as Act 1's
Collective objectives section): a live-rendered list of every site where
`factionVein.factionId == "collective"` — district, ore type, rough security
read. **This is the entire mechanical expression of "the Collective starts
keeping records."** No new state: the data already exists in
`state.world.sites`; this is a rendering change, unlocked by `colA2Stage`
reaching `"hardening"` (i.e., from T8 onward), never described in its own UI
copy as anything but useful.

### 5.3 The Network handler — Targets & Sourcing

Two products, both requiring the player to name a specific vein or a specific
target profile — the disclosure *is* the surveillance, one transaction at a
time, per `plans/COLLECTIVE-QUESTLINE.md` §3's information thesis.

**State:**

```
state.collective.networkIntel = {
  "<siteId>": { "expiresDay": int, "effect": "claim_bonus" | "security_freeze", "magnitude": float }
}
```

**Targets** — player names an existing vein (any faction's) believed weak.
Handler always tells the truth: either confirms it's genuinely soft and
applies a timed `claim_bonus` (a flat addition to `Raiding.claim_chance()` /
`Factions.rivalry_success_chance()` for that site, expiring after N days), or
confirms it isn't and the player has paid for a "no" — the handler is honest,
not lucky. `security_freeze` variant ("delay the guard swap"): the named site
is skipped by `Factions.apply_security_upgrades()` for N days, i.e. its
current (weaker) security tier is locked in rather than allowed to improve —
mechanically the same lever, framed as sabotage-by-omission rather than a
buff.

**Sourcing** — player names an ore type and a minimum tier. Handler rolls and
places a fresh unclaimed site of that spec on the map (reuses
`Sites.roll_new_site()` / `Sites.roll_tier()` exactly as Hakim's intel does),
revealed the same way — a `pendingMessages` entry, not an instant reveal, so
the beat still reads as "the handler got back to you" rather than a vending
machine.

**Pricing** — first pass, needs a playtest checkpoint (§12.1) same as Act 1's
own economy did: scale to the ore type's `basePrice` and the target tier,
landing somewhere adjacent to what `VeinTrade.quote()` already prices a vein
of that rough value at — the handler should feel expensive relative to normal
trade, not free intel with a UI wrapper.

**Relation feed:** every handler transaction nudges `state.factions.network.
relation` by a small flat amount, same shape as Archie's flat
`ARCHIE_SALE_RELATION_GAIN` (Act 1 spec §8.4) — the mechanism `plans/
COLLECTIVE-QUESTLINE.md` §6 needs already gating the Act 3 private-choice
overlay.

### 5.4 Hakim's vein — three one-off scripted effects

None of these are general mechanics. Each is a narrow effect op that exists
to be called by exactly one authored scene, the same shape Act 1's
`scripted_seed` (used only by S14) established.

| op | fires at | does |
|---|---|---|
| `col_a2_force_vein_loss` | T10 | Forced ownership transfer of the vein at `state.collective.hakimVeinId` from `collective` to `firm` — same bookkeeping shape as `Factions.resolve_rivalry_outcome()`'s transfer branch, but unconditional and story-triggered, not rolled. Pushes Hakim's `pendingMessages` entry. |
| `col_a2_force_vein_loss` (reused, parameterised) | T11 | Same op, targeting whichever site T8's `col_a2_nadia_defend` mission named (or the Collective's current highest-security vein if that mission was never started). Different delivery text (Nadia's, not Hakim's). |
| `col_a2_ruin_site` | T13 | **One-off only, never generalised.** Sets a single narrow flag on the *named site id* stored at `state.collective.hakimVeinId`'s former site — e.g. `site.ruinedByFirm = true` — and `Sites.attempt_seed()` gains a two-line guard rejecting that one flag. No new tier, no new field on the general vein/site schema beyond this one boolean, and it is set by nothing else anywhere in the game. Whether ownership returns to the player as an inert claimed-but-unseedable site, or the site is simply removed from `state.world.sites` after the retake plays out, is an implementation choice for the ticket — either satisfies the fiction; the removal path is probably cheaper. |

**T13's retake itself** is a real choice, not scripted: force (`Raiding.
claim_vein()`) or buy (`VeinTrade.buy_from_faction(vein_id, "firm")` — already
generic on `faction_id`, requires no new code per the current
`systems/vein_trade.gd`). **Both paths lead to the same ruin.** This is
deliberate: neither ideology gets there fast enough to save the ground, only
the people. Fire `col_a2_ruin_site` as part of *either* choice's resolution,
immediately after the ownership transfer completes.

### 5.5 Method log extensions

```
state.methodLog.a2ContestedVein = "force" | "bought"       # T5
state.methodLog.a2VulnerableSite = "lookout" | "soft"       # T6
state.methodLog.a2HostileMember = "absorbed" | "example" | "protected"  # T7
```

Per the human's decision this session: **the log is flavor, not a gate.** Act
3's futures (`plans/COLLECTIVE-QUESTLINE.md` §6) all remain reachable
regardless of what's recorded here; the log exists so Act 3's dialogue can
react specifically to how the player got here, not to lock content. This
closes `plans/COLLECTIVE-QUESTLINE.md` §9 open question 5.

### 5.6 Spine reward — extending Hakim's intel

Act 1 spec §5.8's `col_hakim_intel` (15%/day roll, 3-day minimum, unlocked at
Act 1's S12) currently only ever creates an unclaimed *site*. At T14 (Act 2's
own relation-50 gate), extend the roll: past this point, the same roll may
instead flag an existing **enemy-held vein reading unusually weak** — the
free, rare, vague counterpart sitting right next to the handler's paid,
instant, precise Targets product (§5.3). This closes `plans/
COLLECTIVE-QUESTLINE.md` §9 open question 2 for Act 2's own gate: the reward
*is* the arc's information thesis restated as a menu, not a discrete unlock
bolted on separately.

---

## 6. Content — every scene

Event ids prefixed `col_a2_`. All added to `GameData.EVENT_IDS`.

### 6.1 T1 — `col_a2_intro` · "Now"

**Delivery:** Des text, `pendingMessages`, gated on Act 2's open condition.
**Text:** *"Get over here. Now. It's Hakim. He's all right — he's not all
right, but he's not — just come."*

No cards drafted yet beyond the hook above; tone note: **urgency without
melodrama.** Des texting in fragments, dropping his usual unhurried cadence,
is itself the signal something's wrong — his voice breaking register is doing
the work, not exclamation marks.

### 6.2 T2 — `col_a2_shop` · the aftermath

**Cards, beat outline (not final text):**
1. Narration — the shop, mid-afternoon, closed with the blind half down.
2. Hakim, sitting, a split lip, ice from the freezer cabinet wrapped in a tea
   towel. He is more embarrassed than hurt, which is worse to watch.
3. Des and Nadia are already there. Des is the angriest anyone has seen him;
   he does not raise his voice — he goes quieter, which is new.
4. What happened, plainly, administratively: two men, an offer to buy the shop
   and the vein "for a fair price," Hakim said no, it got physical when he
   didn't change his mind. Nobody named is on-screen. **Tone rule 3** —
   mundane and awful, not operatic. One beat of dry observation is permitted,
   no more (rule 3.3 of the tone bible).
5. `on_complete`: `set_flag colA2ShopSeen true`.

### 6.3 T3 — `col_a2_pattern` · the hub

**Cards, beat outline:**
1. Nadia: this isn't isolated. Names two or three others by first name and
   one detail each (a threat over the phone, a smashed window, a "friendly"
   visit) — unnamed beyond that, per the contact-budget discipline.
2. Des: pattern means it's a decision somewhere, not temper. Someone above
   the men who hit Hakim decided the Collective was worth leaning on.
3. Hub line, matching Act 1 S4's shape: "something needs to be done," no
   prescribed order.
4. `on_complete`: activate the Phase 1 objectives/pins for T5-T7; `set_flag
   colA2Stage "call"`.

### 6.4 T4 — `col_a2_handler_deferred` · not yet

**Cards, beat outline:**
1. Nadia raises the handler directly, plainly, as the obvious fix — "there's
   a way to know before it happens. Costs money. Costs the right kind of
   money, mind, not the kind we're short of."
2. Des: no. Not because it's wrong in principle yet — because it's too soon.
   "You start with 'just this once' and you don't notice the year it stopped
   being once." This is the version of his thesis stated in the register of
   caution, not doctrine — should not yet sound like a speech.
3. Nadia doesn't fight it — she's not committed to the handler specifically,
   only to results. "Fine. We do it the hard way first." This matters: her
   later pivot at T11-T12 must read as earned, not as her losing an argument.
4. `on_complete`: `set_flag colA2HandlerDeferred true` (referenced narratively
   at T11-T12 — "we agreed not yet").

### 6.5 T5 — `col_a2_contested_vein` · choice

**Setup:** a named Collective vein has been taken by the Firm since T3 (a
scripted or sim-driven loss — either is acceptable here since this beat is
abstract/teaching, unlike T10-T11 which must be precise).

- **Force** → `Raiding.claim_vein()`. Relation hit per that function's
  existing constant; no additional penalty.
- **Buy it back** → `VeinTrade.buy_from_faction(vein_id, "firm")`. The Firm's
  face appears here (§3.2) — one scene, transactional, no threat, because
  there's no need for one; they got paid.

`on_complete`: `log_method a2ContestedVein <force|bought>`.

### 6.6 T6 — `col_a2_vulnerable_site` · choice

- **Permanent lookout** → funds a security upgrade on a named vein (reuses
  the resources→`securityBias` mechanism already implemented per `plans/
  COLLECTIVE-QUESTLINE.md` §8.2 — no new formula, just directing an existing
  spend at a specific site rather than the faction's general pool).
- **Stay soft and fast** → no structural change; the vein's fate rides the
  sim's existing odds.

`on_complete`: `log_method a2VulnerableSite <lookout|soft>`.

### 6.7 T7 — `col_a2_hostile_member` · three-way choice

Unnamed member, mentioned once, never a fourth cast slot. They've been quietly
paying the Firm to be left alone — sincerely defensible from their side
(they're scared, not malicious), which is the point.

- **Absorb** — no cost to them; a quiet trust hit inside the Collective
  itself, expressed as a small hit to `state.factions.collective.relation`
  (the community noticing softness) rather than to any named person.
- **Make an example** — harsh; provokes rather than deters. Mechanically, a
  temporary spike in Firm aggression toward the Collective — e.g. a timed
  multiplier on the Firm's rivalry-initiation weighting against `collective`
  specifically, or a direct hit to `factionRelations[firm][collective]`.
- **Offer protection** — funds that member's own vein security (same lever as
  T6's hard option, retargeted) plus a relation/trust gain. This is Nadia's
  entire "formalise" pitch in miniature and should read that way on a second
  playthrough, without underlining it on the first.

`on_complete`: `log_method a2HostileMember <absorbed|example|protected>`.

### 6.8 T8 — `col_a2_nadia_ledger` · getting organised

**Cards, beat outline:**
1. Nadia, practically: "I've started writing it down. Who's got what, where.
   Not for anyone else — for me, so I stop finding out we've lost something
   a week after everyone else does."
2. Des present, uneasy, says something small and gets talked past — not
   argued down, just outpaced by the room's relief. This is his real
   introduction to the arc's central danger and it should land as almost
   nothing, the way the real one usually does.
3. Nadia hands over resources and three jobs (§5.1's three objectives),
   framed as sensible division of labour, not command.
4. Card for `col_a2_nadia_supplies` specifically: Nadia, practical, pointing
   out that half the Collective's been carrying the exact same two things
   since they started ("Time Pearl and a bit of Enhancement Powder, like it's
   still your first fortnight") and handing over physics and emotion calc
   with a short, unglamorous list — something that hits, something that
   holds, something that talks a crowd down before it needs either. No
   lecture on variety for its own sake; it reads as her being sensible about
   stock, not the game teaching a systems lesson.

   > PROSE-REVIEW: "You can't fight and you can't calm anyone down, you can
   > just get hit slightly slower than you used to. Make some Blast. Make a
   > Shield. And do one of the Prank — not because I think you'll need it,
   > because I think you won't reach for it, and you should have the option
   > sat there anyway."

5. `on_complete`: activate `col_a2_nadia_reseed`, `col_a2_nadia_supplies`;
   `set_flag colA2LedgerStarted true`; unlock the Notes-app Collective ledger
   section (§5.2). **`col_a2_nadia_defend` is not activated here** — see T8a.

**Note:** card 2 is this arc's version of Act 1's S7 card 4 — the line that
means nothing on a first read and everything on a second. It must not be
underlined.

### 6.8a T8a — `col_a2_nadia_defend_brief` · "go on then"

**Delivery:** Nadia action bar or text, enabled by `col_a2_nadia_supplies`
completing.

**Cards, beat outline:**
1. Nadia, brief — acknowledges the kit's made, names a specific Collective
   vein she wants watched (picks the one that reads most exposed at this
   point in the player's game, or defaults to whichever vein has the Alarm
   upgrade if one already does).
2. One line making the connection explicit without lecturing — the point of
   the last mission was this one.
3. `on_complete`: `state.collective.nadiaDefendVeinId` set to the chosen site;
   activate `col_a2_nadia_defend`; `set_flag colA2DefendBriefed true`.

When that vein's alarm-defend encounter later fires, it carries the pre-fight
reminder card described in §5.1. If the vein is raided and lost before the
player ever responds, `col_a2_nadia_defend` should re-target a different
Collective vein rather than dead-end — the mission is "defend one, well,"
not "defend this exact one or fail."

### 6.9 T9 — `col_a2_checkpoint` · "it's working"

**Delivery:** fires once all three T8 missions are complete, or a day
threshold passes, whichever first (avoid gating on 100% mission completion
alone — a player who does two of three should still see the beat).

**Cards, beat outline:**
1. Numbers, stated plainly: fewer losses this fortnight than the one before,
   a vein successfully defended, one newly seeded. Real, not spun.
2. Nadia, satisfied, already thinking about what's next.
3. Des, asked directly if he's happy: doesn't say no. Says something adjacent
   — "it's working" is not the same question as "it's fine" — and lets it
   go, because everyone else in the room is glad, and he isn't sure yet that
   he's right to not be.
4. `on_complete`: `set_flag colA2CheckpointSeen true`.

### 6.10 T10 — `col_a2_hakim_vein_lost` · despite everything

**Delivery:** Hakim text, `pendingMessages`, scripted (not sim-driven) —
timed to fire after T9, on the next opportunity that doesn't clash with
another pending story beat.
**Text:** *"They've had the yard. I'm — it's fine. Everyone's fine. Come by
when you can."* (Everyone is not fine; he says it anyway, which is the point.)

Effect: `col_a2_force_vein_loss` targeting `state.collective.hakimVeinId`
(§5.4). Cards should sit with the family/shop specifically — the point of
this beat is that it is *not* an abstraction the way T5's contested vein was.

### 6.11 T11 — `col_a2_second_loss` · the anomaly

**Delivery:** Nadia text or action-bar beat, following T10 by a short delay.

**Cards, beat outline:**
1. Nadia states the fact flatly: a second vein gone, one of the ones they'd
   specifically hardened at T8.
2. "That one shouldn't have gone. We did everything right for that one." Not
   panic — arithmetic. This is the moment the arc's mystery actually opens,
   though nobody frames it that way yet.
3. Des has no answer for this either, and — importantly — does not perform
   suspicion of anyone, including of the eventual truth about himself. His
   unease has always been about the *practice* (the ledger existing at all),
   never a hint that he suspects the mechanism. He is as genuinely baffled by
   the anomaly as anyone, which is exactly right for a man who does not
   experience his own leak as sabotage.
4. `on_complete`: `col_a2_force_vein_loss` fires on the target described in
   §5.4's table; `set_flag colA2SecondLossSeen true`.

### 6.12 T12 — `col_a2_handler_meet` · the sit-down

**Delivery:** Nadia action bar, "Go with Nadia," enabled by
`colA2SecondLossSeen`.

**Cards, beat outline:**
1. Nadia has arranged it herself — not asking permission, informing. "I know
   we said not yet. That was before something we couldn't explain took a
   vein we'd done everything right by. I'm done waiting for an explanation
   to turn up on its own."
2. Des attends. Objects once, on the record, precisely, and does not block
   it — the room has moved past the point where his caution alone is enough
   of an answer, and he knows it, which should read as the most uncomfortable
   thing that's happened to him so far in the story.
3. The handler — polite, unhurried, an invoice's worth of manner. Introduces
   Targets and Sourcing (§5.3) exactly as advertised: true, fair, ruinous.
   No pressure — the handler never needs to apply any.
4. `on_complete`: `set_flag networkHandlerUnlocked true`; unlock the Targets
   and Sourcing action-bar entries wherever the handler's surface lives.

### 6.13 T13 — `col_a2_hakim_retake` · getting it back

**Delivery:** enabled once the player has bought at least one piece of
Targets intel on the Firm-held site from T10 (small gate — makes the handler
feel used, not decorative, at the exact moment it matters most).

- **Force** → `Raiding.claim_vein()`.
- **Buy** → `VeinTrade.buy_from_faction(vein_id, "firm")` — the Firm's face
  reappears, unmoved; the vein was never precious to them either.

Either way, `col_a2_ruin_site` fires immediately after (§5.4): the ground is
back, the family's safe, the vein does not come back with it.

**Cards, beat outline:** Hakim's reaction should carry the whole beat — the
relief of the yard being his again, undercut immediately by what's actually
left of it. No dialogue should explain the significance; the site reading as
permanently empty is the explanation.

`on_complete`: relation `+15` (arc's single largest personal-beat award, see
§7.2); `set_flag colA2HakimRetaken true`.

### 6.14 T14 — Spine reward, silent

Fires automatically once T5, T6, T7 and T13 are all resolved and relation
crosses 50 (§7.3's gate). No scene of its own required beyond one short Hakim
text acknowledging it, e.g.:

> PROSE-REVIEW: "Started keeping half an ear out further afield, since. Don't
> get excited, I'm still mostly hearing about washing machines."

`on_complete`: extends `col_hakim_intel`'s roll per §5.6.

### 6.15 T15 — `col_a2_closer` · the ledger, read as relief

**Cards, beat outline:**
1. Someone — Nadia, plausibly — remarks on how much easier things are now
   that there's a proper record. Said warmly, genuinely, and correctly, by
   the standard of everything visible so far.
2. Des's one beat of unease, delivered once, briefly, per `docs/
   CONTENT-GUIDE.md` §3 rule 2 — and then dropped, not returned to. He does
   not get to litigate it here; that's Act 3's scene.
3. Resolution line closing the arc on the thesis, understated: the Collective
   has never been safer, and never been more findable, and nobody currently
   in the room thinks those are the same sentence.
4. `on_complete`: `set_flag colA2Complete true`.

---

## 7. Economy

### 7.1 Buyback and retake pricing

Both reuse existing formulas with zero new math:
- **Buy back a vein** (T5 soft, T13 buy) — `VeinTrade.quote()`, unchanged.
- **Force a retake** (T5 hard, T13 force) — `Raiding.claim_vein()`'s existing
  relation-penalty constant, unchanged.

### 7.2 Handler pricing — first pass, playtest-pending

Propose anchoring both Targets and Sourcing to the same ballpark
`VeinTrade.quote()` already uses for a vein of comparable tier/ore, so the
handler reads as "roughly what the thing would be worth anyway, paid up
front for certainty" rather than either a bargain or a fantasy tax. Exact
multiplier is a tuning question for playtest, same caveat Act 1 spec §14.1
raised for its own economy — **do not treat these as final before a
human plays days 1-20 of Act 2.**

### 7.3 Relation award table

| Beat | Award |
|---|---|
| T8 — Nadia's three missions, each on completion | +4 each (+12 total) |
| T13 — Hakim's vein retaken | +15 |
| Successful alarm-defend win (ongoing, Phase 1-2) | +2, capped **+4/day** |
| **Explicit total from scripted beats alone** | **+27** |

Matches Act 1 spec §8.5's own pattern (its total was +27 crossing a 25 gate)
scaled to a 50 gate starting from an Act-1 baseline that should already sit
at or above 25-30 for most players. **This needs the same playtest checkpoint
Act 1 flagged for its own numbers** — if players are arriving at Act 2's gate
well short of 50, the fix is almost certainly widening the alarm-defend daily
cap or Phase 2's ambient trade accrual, not inflating the scripted awards,
per the "accumulate, don't award per transaction" discipline Act 1 §8.4
established.

### 7.4 Gate condition

Act 2 is complete when: `methodLog.a2ContestedVein`, `a2VulnerableSite` and
`a2HostileMember` are all set, AND `colA2HakimRetaken` is true, AND
`state.factions.collective.relation >= 50`. Stated as a dual condition for
engine consistency with the other four factions' future storylines, per Act 1
spec §8.5's own reasoning — in practice T13's award alone should usually be
enough to clear the gate for a player who's reached this point at all.

---

## 8. Data

### 8.1 New event files

`data/events/col_a2_{intro,shop,pattern,handler_deferred,contested_vein,
vulnerable_site,hostile_member,nadia_ledger,nadia_defend_brief,checkpoint,
hakim_vein_lost,second_loss,handler_meet,hakim_retake,closer}.json`. Added to
`GameData.EVENT_IDS`.

### 8.2 `data/objectives.json` additions

| id | type | key params |
|---|---|---|
| `col_a2_nadia_defend` | `alarm_defend_wins` | `minCount` |
| `col_a2_nadia_reseed` | `faction_vein_seeded_count` | `factionId: "collective"`, `minCount` |
| `col_a2_nadia_supplies` | `items_crafted_set` | `recipeKeys: ["blast","shield","pansPrank"]`, `minEach: 1` |

### 8.3 New flags

`colA2Stage`, `colA2ShopSeen`, `colA2HandlerDeferred`, `colA2LedgerStarted`,
`colA2DefendBriefed`, `colA2CheckpointSeen`, `colA2SecondLossSeen`,
`networkHandlerUnlocked`, `colA2HakimRetaken`, `colA2Complete`.

`state.collective.nadiaDefendVeinId` (String, nullable) — the site currently
targeted by `col_a2_nadia_defend`; re-set if that vein is lost before being
defended (§6.8a).

### 8.4 New effect ops

| op | does |
|---|---|
| `col_a2_force_vein_loss` | Forced ownership transfer, faction→faction, given a site/vein id (§5.4) |
| `col_a2_ruin_site` | Sets the one-off `ruinedByFirm` flag on a named site; `Sites.attempt_seed()` guard rejects it (§5.4) |
| `network_reveal_vulnerable_vein` | Writes a timed entry to `state.collective.networkIntel` (§5.3) |
| `network_reveal_site` | Rolls and places a fresh unclaimed site per a named ore type/tier (§5.3) |

### 8.5 State schema additions

```
"collective": {
    ...,                          # existing Act 1 fields unchanged
    "networkIntel": {},
    "nadiaDefendVeinId": null,
},
"player": {
    ...,
    "craftedCounts": {},          # recipeKey -> int, needed for items_crafted_set
},
"methodLog": {
    ...,
    "a2ContestedVein": null,
    "a2VulnerableSite": null,
    "a2HostileMember": null,
},
```

Plus `state.factions.network.relation` accrual wiring per §5.3 (reuses the
existing per-faction `tradeProgress`/relation-accrual pattern; no schema
change beyond what already exists for every faction).

---

## 9. Testing

Per the constitution: every touched `.gd` gets `godot --headless -s
scripts/check_runner.gd -- <file>`, and `scripts/run_tests.sh` must pass.

**Acceptance gate:** extend `tests/test_playthrough.gd` to walk Act 2 end to
end — T1 through T15 including T8a, driving the three Phase 1 choices down at
least one branch each, completing `col_a2_nadia_supplies` before
`col_a2_nadia_defend` activates (asserting the sequencing itself, not just the
end state) via the real systems (`Crafting.attempt_craft` for each of the
three recipe keys, `Raiding.resolve_defend_outcome`, `Cultivating`), and
confirming the gate condition (§7.4) is met and `col_a2_closer` fires.

**Unit seams:**

| Seam | Asserts |
|---|---|
| New `Objectives` evaluators | Each of the three against synthetic state — `items_crafted_set` specifically against a partial-checklist state (two of three crafted) to confirm it doesn't complete early; idempotency; `refresh()` never awards |
| `col_a2_force_vein_loss` | Ownership transfer is unconditional, targets exactly the named site, no-ops safely if the site's already changed hands |
| `col_a2_ruin_site` | `Sites.attempt_seed()` rejects the flagged site and no other; the flag never gets set anywhere else in the codebase (a grep-based data-validity test, not just a unit test) |
| Handler ops | `network_reveal_vulnerable_vein`'s timed entry expires correctly; `network_reveal_site` reuses `Sites.roll_new_site()` without duplicating its logic |
| Relation award table | The £/count thresholds and caps in §7.3, daily cap reset on `daily_tick` |
| Data validity | Every new event JSON loads; every new flag/op/objective id referenced exists |

**Not tested headless:** the Collective ledger's Notes rendering, the
handler's action-bar surface. Manual QA list per ticket, per the constitution.

---

## 10. Document amendments required

Applied in this same session alongside this spec (not deferred to a ticket,
since no code lands from this document alone yet):

| Document | Amendment |
|---|---|
| `plans/COLLECTIVE-QUESTLINE.md` §5 (Arc 2) | Superseded note added, pointing here — same pattern as Act 1's own supersession |
| `plans/COLLECTIVE-QUESTLINE.md` §9 open question 2 | Act 2's own spine reward closed (§5.6 here) |
| `plans/COLLECTIVE-QUESTLINE.md` §9 open question 5 | Closed: the method log is flavor, not a gate |

---

## 11. Risks and open items

### 11.1 Balance — needs a playtest checkpoint

Same caveat Act 1 flagged for its own economy: handler pricing (§7.2) and the
relation award table (§7.3) are first-pass numbers, not final. Sequence
ticket work so a human plays Act 2 start to finish on real numbers before
either is treated as settled.

### 11.2 Deliberately deferred to Act 3

- Des's leak — no mechanical trace beyond the two fair-play losses (T10, T11)
  planted here. Confirming, naming, or hinting further is explicitly Act 3's
  job.
- Dials, James, "going outside the Collective" — per `plans/
  COLLECTIVE-QUESTLINE.md` §5, Act 3 material, not touched here.
- The Network private-choice overlay itself (`plans/COLLECTIVE-QUESTLINE.md`
  §6) — this spec only opens the door (T12) and starts the relation feed
  (§5.3); the overlay's own content is a later spec's problem.
- A rewind-at-choice-point counter in the method log — still just an idea,
  still no consumer.

### 11.3 Prose

Every line in §3.2 and §6 is `PROSE-REVIEW:` draft. Hardest things to get
right, because the arc rests on them:

1. **T2 (the shop)** must stay administrative, not operatic, per tone rule 3
   — one beat of dry observation at most, and it should not come from Hakim.
2. **T8 card 2** (Des's small, talked-past objection) is this arc's
   highest-leverage single line. If it reads as a clear warning the room
   ignores, it's too loud — it has to read as almost nothing on a first pass.
3. **T11 card 3** — Des must read as genuinely baffled by the anomaly, not
   performing innocence. He does not know he's the mechanism.
4. **T13** — no line should explain that the vein is permanently gone. The
   site reading as empty, forever, is the whole statement.
5. **The Firm's face (§3.2)** must never tip into stock-villain menace — dry,
   transactional, unbothered, per §3.2's voice note.
6. **The pre-fight reminder card (§5.1, T8a)** must read as Nadia being brief
   and practical, not as the game surfacing a tutorial tooltip through her
   voice. One line, no bullet-pointed kit list, no "remember to press X."

---

## 12. Open questions carried to Act 3

Unresolved here; do not block Act 2 tickets.

1. **What happens to Des** — still Act 3's, per `plans/COLLECTIVE-
   QUESTLINE.md` §9 open question 3. This spec plants exactly two pieces of
   fair-play data (T10, T11) and no more.
2. **Whether the second loss (T11) should itself be revisited on a second
   playthrough** as more legible once the player knows about Des — no
   mechanical hook needed now, but Act 3's spec should decide whether either
   loss gets a dialogue callback confirming it retroactively.
3. **Exact Targets/Sourcing pricing** (§7.2) and **the relation award table**
   (§7.3) — first-pass numbers, playtest-pending per §11.1.
