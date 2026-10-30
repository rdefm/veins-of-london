# Vein raids as stage trees — proposal

Status: **approved**

Approval: Approved 2026-10-30 by the human, with the ticket changes in §6.

Scope: the rebuilt `vein_raid` (the Yard) and two new vein-raid events (the Arches, the Shop). No event JSON or prose here. Option labels below are working labels only; real prose comes from the per-beat prose tickets after approval. All numbers are placeholders until playtest.

---

## 1. Decisions (grilling session, 2026-10-30)

### 1.1 Shape
- **One branching event per location type.** It is not four top-level approach branches. Every obstacle card offers choices in several styles (loud, quiet, talk, luck, item), and the player can switch style between cards. A sneak that goes wrong can turn into a blast.
- **Routes diverge.** How you get in decides which rooms, guards and security you meet later. Detection changes how guards react from then on. Routes meet again only at the vein room.
- **Observations are tied to their subject, not to a style:**
  - **physics** = fabric: locks, windows, fire escapes, weak panels, hatches
  - **life** = people: guards and witnesses, where they are, what they're watching, who's flagging
  - **fate** = systems and chance: cameras, alarms, lucky breaks about to happen
  - **time** = cycles: patrols, camera sweeps, train timetables
  - **emotion** = mood: nerves, boredom, loyalty, how persuadable someone is
- An observation tier can **gate** an option (it only exists if you saw the thing), **add a mod** to an ungated option, or **open a route fork**.

### 1.2 Alert (ticket 16)

| Tier | Name | Reached by | Effect |
|---|---|---|---|
| 0 | **Unseen** | start | Full option set. |
| 1 | **Suspicious** | a failed quiet, bluff or luck check at Unseen; a ward trigger; a noise raise whose cover failed (from Unseen); `siteWary` at start | The next card is the zone's **window card**. Later quiet and bluff checks −0.10. |
| 2 | **Alarm** | going loud, Blast, a lost or failed window, a failed check at Suspicious | Guards hostile and searching. Most stealth options gated off. Bluff uses its own hard base (0.15). Quiet checks −0.25. Starts the reinforcement clock (if the site has an alarm line). |

- **Window card** (one per zone, outside and inside):
  - incapacitate: fight vs only the guard(s) who saw you, or an item
  - talk your way out: emotion and life help
  - duck out of sight: a quiet check to carry on deeper
  - run for it: abort the raid
  - Win: back to **Unseen**. A messy win (e.g. a fight) stays at **Suspicious**. Lose or fail: **Alarm**.
- **Fail ladder.** A failed check escalates one tier:
  - Unseen → Suspicious window
  - Suspicious → Alarm
  - Alarm → fight with the guards present (the full remaining pool on a guard-post card)
  - Only a **lost fight** ends the raid (player sent home, as today).
- **Reaching Alarm doesn't start a fight by itself.** The card the route lands on decides: a guard post means a fight, an empty corridor means searching at worse odds.
- **Cover roll** (ticket 17) applies only to **noise raises** (Blast, forcing a lock, Panic). It doesn't apply to being **seen**, which is a failed check. Be A Lady and fate reads add to cover.
- **De-escalation:**
  - Items that work on **people** lower alert: Pan's Rapture lowers it one tier.
  - **Cameras** can't be talked down. They're beaten only by preventing the detection (Time Pearl freezing the camera) or undoing it (Rewind).
- **Relation:**
  - **Loot** after a raid that ends at **Unseen** costs no relation. A Suspicious that was resolved back to Unseen counts as clean.
  - Ending at Suspicious or Alarm counts as caught (today's `raidCaught` relation hit, now derived from alert).
  - **Claim** always costs relation, as today.

### 1.3 Reinforcements
- Raising **Alarm** on a site with an **alarm line** (§1.6) starts a **reinforcement clock** counted in **cards**: each card resolved after the alarm ticks it once.
- At **3 ticks**, **+2 guards** join the remaining pool for every later fight, and the next card shows an arrival line. It fires **once** per raid.
- **In a fight:** if Alarm is up and the clock hasn't fired, the 2 arrive at **round 3** as the existing queued wave (`combat_rounds.gd` reinforcements). Once they've arrived either way, they're simply in the pool, so they never arrive twice.
- They're **extra bodies** from the owner's crew. They're not drawn from vein guard slots, cost the faction nothing and carry no guard kit. Template `veinGuard`.
- A future muscle system (ticket 29) will draw them from a faction's muscle pool instead.
- Loot-and-run can beat the clock. Claiming while they arrive forces a final fight.

### 1.4 Odds and calibration
Calibration targets for a route's **clean path** (every check passed, never leaving Unseen), at max skill (reliable tier-2 reads):

| Kit | Clean-run target |
|---|---|
| no items | **25%** |
| good items | **~70%** |
| full kit at every check, max-tier items | **90%** |

Per-check numbers for a **3-check** clean path:

| Option kind | Base | Mods |
|---|---|---|
| Observation-gated option | 0.50 | tier 2 +0.13 → **0.63** at a sharp read (0.63³ ≈ 0.25) |
| Ungated quiet / talk | 0.45 | a relevant non-gating read +0.05 per tier (max 0.55) |
| Luck (always offered) | 0.45 | fate read +0.05 per tier |
| Loud / force | 0.80 | raises alert (cover roll where it's noise) |
| Bluff at Alarm | 0.15 | emotion tier 2 +0.15 (max ~0.30) |
| Alert | — | Suspicious −0.10, Alarm −0.25 on quiet/bluff |
| Rolled item bonus (scales by tier, §1.5) | — | max tier ≈ +0.33 → ~0.96 |

- **Route rule.** Every route's clean path is tuned to the three targets. A **4-check** path (e.g. a warded vein room adds the ward as a check) uses gated base 0.58 + tier 2 0.13 = **0.71** (0.71⁴ ≈ 0.25).
- **Clamp.** `eventChecks.defaultMax` stays 0.95 for ordinary checks. Item-boosted checks clamp at **0.97**, so 90% is reachable on 3 checks. 4-check paths land at ~88%, which is accepted.
- Each event section below gives a **calibration line** per route.

### 1.5 Items

Effect kinds:
- `bonus`: + odds
- `unlock`: opens an option
- `bypass`: skips an obstacle, still rolls
- `remove`: takes N guards out
- `fightStart`: start state for a fight
- `no-roll`: the item just does it (ticket 15)
- `alert ±`

| Item | Offered at | Effect |
|---|---|---|
| **Enhancement Powder** | physical obstacles (locks, windows, climbs, hatches); running for it; slipping through a time ward | `bonus` (tier-scaled) and the action counts as **quiet**: a would-be noise raise is skipped. At a time ward: power vs freeze (§1.7). |
| **Blast** | any door, gate, window, lock, shutter; a guard in a window card | `no-roll`: opens the obstacle, alert → **Alarm** (cover roll). Against a guard: `fightStart` enemy hurt (1-HP floor). |
| **Be A Lady** | passive while active (existing) | +odds on every check (existing, by level) **and** + cover odds. No per-card option. |
| **Prophet's Breath** | guards-coming / patrol cards; window cards; **ward observation** | `no-roll` **avoid**: you know when and where, so you skip the encounter with no alert. In a window: `bonus` (tier-scaled) to talk out or incapacitate. On observing a ward: the read is **guaranteed** to reveal its type and effect (§1.7). |
| **Time Pearl** | guards-coming cards; cameras; wards | Three uses: (a) `no-roll` **freeze and rush past**: alert unchanged, but the *next* check takes −0.15; (b) **freeze the line guard**, then a fight vs that one guard only, who starts frozen (`fightStart`); (c) **camera**: `no-roll` freeze it, no detection. (Ward: see §1.7.) |
| **Wormhole** | perimeter or entry, **needs physics tier 2** (you know exactly where the vein is); time wards | `bypass` straight to the vein room (base 0.85, tier-scaled). Fail: you land inside, alert → Suspicious. At a ward: `bypass` past it with no trigger (still rolls). |
| **Pan's Rapture** | any card with people present, at **Suspicious or Alarm** | `no-roll`: guards go docile, alert **−1 tier**, and the guards present are `remove`d from the next fight. People only, never cameras. |
| **Panic** | guard cards, alarm cards | `remove` 1–2 guards (they flee). Then a **cover roll at base 0.5** (Be A Lady, fate reads and item tier add to it): success, they scatter quietly; fail, they shout and alert → **Alarm**. |
| **Pandemonium** | guard cards with 2+ guards present | `fightStart` infighting + enemy hurt (1-HP floor). Alert → **Alarm** (loud). |
| **Rewind** | anywhere (existing) | Unchanged. The only undo for camera detection. |

- **Tier scaling** (ticket 22):
  - Rolled effects scale with the tier spent: `bonus`, `bypass` base, cover odds. For example Powder: T1 +0.15 → max tier ≈ +0.33.
  - `no-roll` effects don't scale.
  - The toggle spends the **highest tier held**. No new UI.
- Same item can be used again at a later card if more are held. One item per option per use.
- Not offered in raids (combat only): Shield, Black Hole, Panger, Healing Salve, Healing Burst, Failsafe, Rejuvenation.

### 1.6 Security profile (ticket 20)
Each raid builds a **security profile** (pure data in the event context) from the vein:

| Vein tier | Adds | Raid effect |
|---|---|---|
| `none` | rickety gate, no lock; 1 lookout (existing floor) | perimeter checks +0.15; lock obstacles auto-pass |
| `basic` | locks on gate / doors / shutters | physical obstacles at normal odds |
| `warded` | + **ward** on the vein room threshold (§1.7) | ward obstacle appears; quiet −0.05 |
| `guarded` (+extras) | + guard posts; guard count = `vein_guard_count` | guard-post cards appear; bluff −0.05 per extra guard (cap −0.15) |

- **Cameras and alarm line** come from a new mutable variable on NPC veins: `factionVein.features = {cameras: int, alarm: bool}` (next to the existing `security` tier string). It's rolled at claim from faction flavour and vein value, like the tier roll. A later faction-upgrade tick may change it.
  - `cameras > 0`: camera cards appear on the routes that pass them.
  - `alarm`: Alarm starts the reinforcement clock. With no alarm line, Alarm has no clock (nobody to call).
- **Seeded per-site details** (from `siteId`, stable across visits) decide which route forks exist:
  - weak window / soft fence panel
  - fire escape (Yard)
  - neighbour arch connected (Arches)
  - cellar flap rotten (Shop)
  - which zone the camera covers
  - Observations **reveal** them: the read text varies by profile (ticket 25, observation text variants).
- New condition `{security: {feature, atLeast?}}` for `requires`, mods and conditional `goto`.
- `guardKit` is untouched here.

### 1.7 Wards (ticket 21)
- **Ward type = the owning faction's primary ore** (Collective life, Firm physics, **Guild time**, Network emotion, Conclave fate). Stored on the vein: `factionVein.features.ward`. Only `warded`+ veins have one.
- Wards are defined in data: `data/wards.json` `{type: {name, freezeRounds?, onTrigger: [effects], fightStart: {...}, counters: [...]}}`, using existing effect ops and fight conditions. A new ward type = data + at most one new fight condition.
- **Implemented now:**
  - **Time ward:** freeze **2 rounds**.
  - **Generic ward:** every other faction until the ward-types ticket (30). Trigger → alert Suspicious, nothing else.
- **Detecting a ward:** fate reads spot it. A ward-matching read helps (a **time** read sees the stillness around a time ward). **Prophet's Breath** on the ward read guarantees type and effect are revealed.
- **Triggering a time ward** (unread crossing or a failed check): you're frozen. Alert → **Suspicious** and the reinforcement clock **+1 tick** (or it starts). If a fight follows on that card, the **player starts frozen** for the freeze rounds (new player-side fight condition).
- **Time ward counters:**
  - **Enhancement Powder:** combat power by tier [1,1,2,2,3] vs freeze 2. Power ≥ freeze (T3+): you're through before it bites, no freeze, no alert. Lower: it still triggers, but the window card gets the Powder bonus.
  - **Decoy:** throw something to trip it, then wait out the freeze. A plain check, or any thrown item for a `bonus`. Costs a clock tick if the clock is running.
  - **Trick a guard into it:** a bluff check (emotion and life help). The guard is frozen and **removed from the next fight**, and you pass.
  - **Wormhole:** `bypass` past it with no trigger (still rolls).
  - **Time Pearl:** `no-roll` freeze the ward itself (people-vs-systems rule: it's a system, so freeze, don't talk).
  - **Rewind:** existing.

### 1.8 Retreat
- Every obstacle card has **Back out** (plain, no roll):
  - At **Unseen**: leave clean, no relation cost, reads kept.
  - At **Suspicious**: leave, relation −5, and **`siteWary`** on the site until day + 3. That site's next raid **starts at Suspicious** (quiet −0.10 from the first card).
  - At **Alarm**: it becomes **Run for it**, a check at base 0.6 (Powder `bonus`, Wormhole `bypass`). Fail: a fight with the guards present. Escaping still costs the caught relation hit and sets `siteWary`.
- **Run for it** in a window card means abort. Slipping deeper in is the separate "duck out of sight".
- The raid costs **one block**, however long the tree.

### 1.9 Fights mid-raid (tickets 14, 18)
- **Window fight:** only the guard(s) who saw you (preset `veinGuards`, count override).
- **Guard post:** the full remaining pool.
- **Reinforcements:** add 2 to the pool.
- **Win:** continue at the authored next card; guards beaten are removed from every later fight. No guards left = no fight.
- **Loss:** raid over, sent home (as today).

### 1.10 Event per location (ticket 09 amended)
- The raid event is picked **by the vein's location suffix**, stable per site, so site observation memory stays valid. The map lives in data:

| Event | Location suffixes |
|---|---|
| `vein_raid` (**the Yard**) | "in the car park", "by the bus stop" |
| **the Arches** | "under the railway arch" |
| **the Shop** | "near the off-licence", "behind the Tesco Metro", "beside the bookies" |

- An unmapped suffix falls back to `vein_raid`.

### 1.11 Size
Each event has:
- **3 routes**, ~22–26 choice cards, ~70–90 result lines.
- **Shared cards**, keyed and reachable from any route: window (outside), window (inside), alarm / searching, guard post, reinforcements arrive, ward, camera, vein room, claim/loot, getaway.
- **7 prose beats**, as sections of one prose ticket per event: (1) intro + observations, (2) perimeter, (3–5) one per route, (6) detection (windows, alarm, reinforcements, guard post), (7) security set pieces (ward, camera) + vein room, claim/loot, getaway.

---

## 2. Notation used below

- **[0.50 g / +0.13 t2]**: gated base 0.50, +0.13 at tier 2 of the gating ore.
- **[0.45 / life +0.05/t]**: ungated base, +0.05 per tier of a life read.
- **→S / →A**: alert to Suspicious / Alarm on fail (or on use, for loud options).
- **cover**: a noise raise with a cover roll (base 0.35 unless stated).
- **⟶ X**: goto card X.
- **sec:** a security-profile condition.
- Fail of any quiet option at Unseen ⟶ the zone's window card. At Suspicious → Alarm and continue. At Alarm → fight with those present.

### Shared cards (identical structure in all three events, own prose per event)

| Key | Card | Options |
|---|---|---|
| `winOut` / `winIn` | **Window**: someone saw you (outside / inside zone) | **Take him down**: fight vs the guard(s) who saw you; win → Suspicious, continue. **Talk it out** [0.45 / emotion +0.05/t, life +0.05/t; Prophet's Breath `bonus`] → Unseen. **Duck out of sight** [0.45 / time +0.05/t; Powder `bonus`] → Unseen, continue. **Pan's Rapture** `no-roll` → Unseen, guard removed. **Blast** him: `fightStart` hurt, →A. **Run for it** (abort, §1.8). Fail of talk/duck → Alarm. |
| `alarm` | **Alarm / searching**: lands here when an option at Alarm has no guard post | **Hide** [0.45 −0.25 alert; time +0.05/t] → continue at the route's next card. **Bluff them** [0.15 / emotion +0.15 t2]. **Pan's Rapture** → Suspicious. **Panic** (cover 0.5). **Run for it**. |
| `post` | **Guard post**: full remaining pool | **Fight**. **Prophet's Breath** avoid (no-roll, skip post). **Time Pearl** freeze-and-rush (next check −0.15) or freeze the line guard (1-guard fight, guard frozen). **Pandemonium** (2+ guards; `fightStart` infighting + hurt, →A). **Panic** (`remove` 1–2, cover 0.5). **Pan's Rapture** (at S/A; `remove` present, −1 tier). **Bluff past** [0.45 at Unseen / 0.15 at Alarm; emotion]. |
| `reinf` | **Reinforcements arrive**: auto-inserted when the clock fires (conditional `goto` on clock state) | Arrival line, +2 to the pool. Continue. |
| `ward` | **Ward** (sec: warded): on the vein-room threshold | **Step through** (unread: triggers). **Slip it** [0.58 g fate≥1 / +0.13 t2; time read +0.05/t on a time ward; Powder power vs freeze]. **Decoy** [0.55; thrown item `bonus`]. **Trick a guard into it** [0.50 g life≥1 / emotion +0.05/t] (guard frozen, removed). **Wormhole** `bypass`. **Time Pearl** `no-roll` freeze the ward. Trigger: →S, clock +1, player frozen if a fight follows. |
| `cam` | **Camera** (sec: cameras > 0, zone match) | **Time the sweep** [0.50 g time≥1 / +0.13 t2]. **Stay in its blind spot** [0.50 g fate≥1 / +0.13 t2]. **Hope it's on the blink** [luck 0.45 / fate +0.05/t]. **Time Pearl** `no-roll` freeze it. **Blast** it (→A, cover). Fail → Suspicious, and **cannot be talked down** (no Talk option in the window that follows; Rewind only). |
| `room` | **Vein room** | If guards are on the vein (guarded+): **Fight** / item options as `post`. Otherwise straight on to `claim`. |
| `claim` | **Claim / loot** (existing c5 prose kept) | **Claim it** (relation hit always). **Loot and leave** (relation hit only if caught, §1.2). At Alarm with the clock running, **Claim** gives a final fight with reinforcements. |
| `getaway` | **Getaway** (only at Alarm) | **Run** [0.6; Powder `bonus`, Wormhole `bypass`]. Fail → fight with those present, then home with loot if you win. |

---

## 3. `vein_raid`, rebuilt: **the Yard**

**Premise and location.** A fenced depot yard by a car park or bus stop: an open lot, a guard hut, a single-storey depot building with the vein inside. Existing intro prose kept ("Nobody has put a sign on this vein…").

**Who guards it.** The owner's vein guards in coats, working out of the hut. The guard post is the hut.

**What makes it distinct.** Open sightlines. Guards see a long way, so time and life reads (patrol gaps, who's watching) matter most. The loud route is cheapest here: there's no one around to hear it but the guards. The only event with a roof route.

### Observations (`raid`, all five ores, 2 tiers each)
Current texts kept where they fit. Extra security-profile variants in *italics* (ticket 25).

| Ore | Tier 1 (lower) reveals | Tier 2 (best) reveals |
|---|---|---|
| physics | a back window that might give (noisy); *fire escape on the depot's side wall, if seeded* | the rotten latch (gap to slide something in); *the soft fence panel*; exact vein position (**Wormhole gate**) |
| life | one guard flagging (end of a double shift) | which guard is asleep on his feet; who's in the hut and who's walking |
| emotion | one guard glancing at the door and his phone | the jumpy guard who flinches at his radio (easy to rattle, easy to bluff) |
| time | the rounds run roughly on the quarter hour | the forty-second patrol gap; *the camera sweep period* |
| fate | something about to go wrong for someone | the moment a guard will turn; *the camera that's on the blink*; *the ward on the depot door* |

### Perimeter card `y_gate`
| Option | Check / effect | Leads to |
|---|---|---|
| **Talk your way through the gate** | [0.45 / emotion +0.05/t] | Front route |
| **Rattle the jumpy guard** | [0.50 g emotion≥1 / +0.13 t2] | Front route (guard steps away) |
| **Gate's on the latch** (luck) | [0.45 / fate +0.05/t] | Front route |
| **Force the gate** | [0.80] cover →A | Front route at Alarm |
| **Blast the gate** | `no-roll` →A (cover) | Front route at Alarm |
| **Over the soft panel** | [0.50 g physics≥2 + sec: softPanel / +0.13 t2] | Back route |
| **Over the fence** | [0.45 / physics +0.05/t; Powder `bonus` + quiet] | Back route |
| **Up the fire escape** | gated sec: fireEscape + physics≥1 | Roof route |
| **Wormhole** | `bypass` [0.85] (physics≥2) | `room` |
| **Back out** | §1.8 | end |

Note: `none`-tier sites skip the lock, so Force/Blast become "walk in" at Unseen; a perimeter +0.15.

### Front route: across the yard, in the depot door
1. **`y_yard`: crossing the yard under the hut window.**
   - Patrol gap [0.50 g time≥1 / +0.13 t2]
   - Wait for the tired guard to nod [0.50 g life≥1 / +0.13 t2]
   - Walk like you belong [0.45 / emotion +0.05/t]
   - Luck: he looks away [0.45 / fate +0.05/t]
   - Prophet's Breath avoid
   - Time Pearl rush or line-guard fight
   - Fail ⟶ `winOut`. At Alarm ⟶ `post` (the hut).
2. **`y_door`: the depot door (lock).**
   - Pick it quiet [0.50 g physics≥1 / +0.13 t2; Powder `bonus` + quiet]
   - Lift the keys off the hut hook [0.50 g life≥2] (needs a sleeping guard)
   - Luck: it's not locked [0.45 / fate]
   - Force [0.80] cover →A
   - Blast `no-roll` →A
   - sec: none → open.
3. **`y_inside`: depot floor.**
   - sec: cameras ⟶ `cam` (zone: depot)
   - sec: warded ⟶ `ward`
   - then ⟶ `room`

**Calibration:** 3 checks (yard, door, camera or ward). If the vein has both a camera and a ward: 4 checks, so use the 0.58 bases.

### Back route: fence, back window, corridor
1. **`y_window`: the back window.**
   - Slide something in and lift the latch [0.50 g physics≥2 / +0.13 t2]
   - Ease it [0.45 / physics +0.05/t; Powder `bonus` + quiet]
   - Luck: a car backfires as you bash it [0.45 cover-style: the noise is covered on success / fate +0.05/t]
   - Blast it in `no-roll` →A (cover)
   - Fail ⟶ `winOut`.
2. **`y_corridor`: the back corridor.**
   - A guard on his round [time g / life g / luck; Prophet's Breath; Time Pearl]
   - sec: cameras (zone: corridor) ⟶ `cam` first
   - Fail ⟶ `winIn`.
3. sec: warded ⟶ `ward` ⟶ `room`

**Calibration:** 3 checks (window, corridor, ward or camera); 4 with both.

### Roof route: fire escape, skylight, drop in
Exists only on seeded `fireEscape` sites.
1. **`y_climb`: the fire escape.**
   - Climb quiet [0.50 g physics≥1 / +0.13 t2; Powder `bonus` + quiet]
   - Luck: the rung holds [0.45 / fate]
   - Fail ⟶ `winOut` (someone in the yard looks up).
2. **`y_skylight`: the skylight.**
   - Work the rusted catch [0.50 g physics≥2 / +0.13 t2; Powder `bonus` + quiet]
   - Blast `no-roll` →A (cover)
   - Luck [0.45]
3. **`y_drop`: drop into the vein room.**
   - Wait for the guard below to look away [0.50 g life≥1 / +0.13 t2]
   - Prophet's Breath avoid
   - Time Pearl freeze
   - Luck [0.45 / fate]
   - Fail ⟶ `winIn` (in the vein room itself).
   - **No ward, no camera:** the roof skips the threshold. That's the route's reward for a rarer, harder way in.
4. ⟶ `room`

**Calibration:** always 3 checks.

### Failure paths → claim/loot
- Every route ends at `room` ⟶ `claim`.
- At Alarm the order is `room` ⟶ `claim` ⟶ `getaway`.
- A lost fight anywhere ends the raid.
- **Going loud from the start** (Force or Blast the gate) runs `y_yard` as a hut guard-post fight with the full pool. A win means a straight run to `y_door` (Force or Blast open), then `room`. This is today's "Go in loud".

---

## 4. New event A: **the Arches**

**Premise and location.** A lockup workshop in a railway arch under a viaduct. The vein is in the back of the arch, behind a partition. A roller shutter on the front, the tracks above, a garage in the next arch along, and Network Rail fencing behind.

**Who guards it.** The vein guards, plus whoever's working the bench late. The guard post is the bench at the front of the arch. Fights are cramped: the arch fits only so many bodies at once, so the guard post fights the pool **in waves of 2** (a fight preset override; reinforcements still queue).

**What makes it distinct.** **The trains.** Every few minutes a train goes over and drowns everything. A **time** read gives the timetable, which adds an option to *wait for the train* on any loud action. That makes a cover roll at **+0.35**: noise is cheap if you time it. A **fate** read may also reveal the next one is late, so the bet goes the other way. Loud-but-covered is the signature play. The arch's single front is bluff-friendly: you could be from the garage next door.

### Observations (`raid`)
| Ore | Tier 1 | Tier 2 |
|---|---|---|
| physics | the shutter's motor housing is cheap | the shutter's manual release is reachable through the gap; *breeze-block wall shared with the next arch (seeded)*; *the back vent's mesh is rusted*; exact vein position (Wormhole gate) |
| life | someone's still on the bench | who's on the bench, who's in the back, and the mechanic in the next arch who knows everyone |
| emotion | the bench man is bored | he'll talk to anyone about the football; he resents his bosses |
| time | trains run often | the timetable to the minute (**wait-for-the-train** option); *camera sweep* |
| fate | a train is about to be late | exactly which train won't come; *the camera on the shutter*; *the ward at the partition* |

### Perimeter card `a_front`
| Option | Check / effect | Leads to |
|---|---|---|
| **Knock: "from next door"** | [0.45 / emotion +0.05/t, life +0.05/t] | Shutter route, let in |
| **Talk football with the bench man** | [0.50 g emotion≥2 / +0.13] | Shutter route, let in, guard distracted (next check +0.05) |
| **Release the shutter by hand** | [0.50 g physics≥2] | Shutter route, quiet |
| **Force the shutter** | [0.80] cover →A; with time≥2 "on the train" cover +0.35 | Shutter route |
| **Blast the shutter** | `no-roll` →A, cover (+0.35 on the train) | Shutter route |
| **Through the garage next door** | sec: neighbourArch | Neighbour route |
| **Round the back, over the railway fence** | [0.45 / physics +0.05/t; Powder `bonus` + quiet] | Trackside route |
| **Wormhole** | `bypass` (physics≥2) | `room` |
| **Back out** | §1.8 | end |

### Shutter route: the front of the arch
1. **`a_bench`: past the bench.**
   - Let in by bluff → keep the story going [0.45 / emotion; −0.05 per extra guard]
   - Wait for him to turn to the radio [0.50 g life≥1]
   - Luck [0.45 / fate]
   - Time Pearl rush
   - Prophet's Breath avoid
   - Unseen fail ⟶ `winIn`. At Alarm ⟶ `post` (the bench, waves of 2).
2. **`a_partition`: the partition door to the back.**
   - sec: cameras ⟶ `cam` (shutter camera faces in)
   - Lock [physics g; Powder; Force/Blast on the train]
   - sec: warded ⟶ `ward`
3. ⟶ `room`

**Calibration:** 3 checks (bench, partition lock, camera or ward); 4 with both.

### Neighbour route: through the next arch
1. **`a_garage`: the mechanic in the next arch.**
   - Talk him into turning a blind eye [0.50 g life≥2 / emotion +0.05/t]
   - Slip in while he's under a car [0.45 / time +0.05/t]
   - Luck: radio up loud [0.45]
   - Fail → he's a **witness**: ⟶ `winOut` (talk him down or run; incapacitating a civilian is not offered).
2. **`a_wall`: the shared breeze-block wall.**
   - Work the loose blocks quiet [0.50 g physics≥2; Powder `bonus` + quiet]
   - **Blast on the train** `no-roll` + cover (+0.35 with time≥2)
   - Blast without it `no-roll` →A
3. **You come out behind the partition: no ward, no camera.** ⟶ `room`

**Calibration:** 2 checks + `room`. The route trades a witness for skipping the threshold, so its bases drop to 0.40 gated / 0.36 ungated. Then 2 checks at ~0.50 at tier 2 gives ~25%.

### Trackside route: the tracks and the back vent
1. **`a_tracks`: along the line.**
   - Cross between trains [0.50 g time≥1 / +0.13 t2]
   - Luck: no track crew tonight [0.45 / fate]
   - Prophet's Breath avoid (track worker)
   - Fail ⟶ `winOut` (track worker shouts; he's a witness, not a guard).
2. **`a_vent`: the back vent.**
   - Mesh off quiet [0.50 g physics≥1 / +0.13 t2; Powder `bonus` + quiet]
   - Kick it in on the train [0.80] cover +0.35
   - Blast `no-roll` →A
3. **`a_crawl`: drop into the back of the arch.**
   - Guard in the back [life g / time g / luck; Prophet's Breath; Time Pearl]
   - sec: warded: the vent is past the ward, so no ward here
4. ⟶ `room`

**Calibration:** 3 checks.

### Failure paths → claim/loot
- All routes ⟶ `room` ⟶ `claim` (⟶ `getaway` at Alarm).
- `getaway` here adds **Along the tracks** [0.6; time +0.05/t].
- Loud from the front means waves of 2 at the bench, then the partition, then the room.

---

## 5. New event B: **the Shop**

**Premise and location.** A late-opening shopfront (off-licence, Tesco Metro, bookies). The vein is in the cellar under the back room. It's still trading: the front is **public**, with staff on the till and the odd customer.

**Who guards it.** The vein guards, posted in the back room as "stock". Staff are **witnesses, not fighters**: they raise alert, but you can't fight them. Talk or avoid only. The guard post is the back room.

**What makes it distinct.**
- **Bluff-heavy and public.** You can simply walk in as a customer. Most Unseen fails come from witnesses (staff, customers), not guards, and witnesses can always be talked down at the window.
- **Cameras are natural here.** CCTV over the till: if the site has cameras, the front route always meets one.
- **Going loud in public is extra-costly.** Alarm here also scatters the customers, so reinforcements come on a **2-card clock**, not 3.

### Observations (`raid`)
| Ore | Tier 1 | Tier 2 |
|---|---|---|
| physics | the back yard door is old | its hinge pins are on the outside; *the pavement cellar flap is rotten (seeded)*; exact vein position (Wormhole gate) |
| life | there's someone in the back besides the till | who's on the till, how many guards are "stocking" the back, and the regular who never leaves |
| emotion | the till worker hates this job | she'd look the other way for the right story; the guard in the back wants to be anywhere else |
| time | deliveries come round the back | the drayman's slot (the cellar flap is open for it); *the CCTV loop length* |
| fate | the CCTV's not right | the till camera records nothing; *the ward on the cellar stairs* |

### Perimeter card `s_front`
| Option | Check / effect | Leads to |
|---|---|---|
| **Walk in as a customer** | plain, no roll | Customer route |
| **Round the back** | plain | Yard-door route |
| **The cellar flap** | sec: cellarFlap + physics≥1 | Cellar route |
| **Wormhole** | `bypass` (physics≥2) | `room` |
| **Back out** | §1.8 | end |

### Customer route: through the shop, into the back
1. **`s_till`: get past the till into the back.**
   - "Toilet?" bluff [0.45 / emotion +0.05/t]
   - Spin her the story she wants [0.50 g emotion≥2 / +0.13]
   - Wait until she's serving the regular [0.50 g life≥1 / +0.13 t2]
   - Luck: the card machine goes down [0.45 / fate]
   - Prophet's Breath avoid
   - sec: cameras ⟶ `cam` (till camera) before this card
   - Fail ⟶ `winOut` (talk only, no fight)
2. **`s_back`: the back room.**
   - Guards present (guarded+) → `post`
   - Otherwise: past the stock [time g / life g / luck]
   - Pandemonium and Panic are strong here (cramped), but Panic's cover roll is **0.35** (staff hear it)
3. **`s_stairs`: the cellar stairs.**
   - sec: warded ⟶ `ward`
   - Otherwise a lock [physics g; Powder]
   - ⟶ `room`

**Calibration:** 3 checks (till, back, stairs). The camera adds a 4th, so use 0.58 bases when cameras > 0.

### Yard-door route: bins and deliveries
1. **`s_yard`: the back yard.**
   - Guard on a smoke [life g; Prophet's Breath; Time Pearl]
   - Pose as the delivery [0.45 / time +0.05/t; +0.13 with time≥2 in the drayman's slot]
   - Luck [0.45]
2. **`s_door`: the yard door.**
   - Pins out [0.50 g physics≥2 / +0.13]
   - Pick [0.45 / physics; Powder `bonus` + quiet]
   - Force [0.80] cover →A
   - Blast `no-roll` →A
3. **`s_back`** (shared with the customer route) ⟶ `s_stairs` ⟶ `room`

**Calibration:** 4 checks (yard, door, back, stairs), so use the 0.58 bases.

### Cellar route: the pavement flap
1. **`s_flap`: the cellar flap on the street.**
   - In the drayman's slot it's open [time≥2 → plain, no roll]
   - Lever the rotten flap [0.50 g physics≥1 / +0.13 t2; Powder `bonus` + quiet]
   - Luck: no one on the street looks down [0.45 / life +0.05/t (who's about)]
   - Fail ⟶ `winOut` (a passer-by, a witness)
2. **`s_cellar`: straight into the cellar.**
   - **Skips the back room and the stairs** (no ward, no camera)
   - Guard on the vein [life g / Prophet's Breath / Time Pearl]
   - ⟶ `room`

**Calibration:** 2 checks, so bases drop to 0.40 gated / 0.36 ungated, as for the Arches neighbour route.

### Failure paths → claim/loot
- All routes ⟶ `room` ⟶ `claim` (⟶ `getaway` at Alarm).
- `getaway` adds **Out through the shop** [0.6; emotion +0.05/t: walk out like a customer, even at Alarm].
- At Alarm, a till-worker witness means the reinforcement clock runs at 2 cards.

---

## 6. Tickets (written 2026-10-30, in `issues/`)

**Amended:**
- 09: event by location suffix
- 10: the Arches
- 11: the Shop
- 12: Dial pays tier-scaled effects; blockers loosened to 15 + 22
- 14: waves override + player-side start condition
- 15: next-check-only lasting mod
- 16: starting level from context + caught derived from alert
- 19: the Yard

**Deleted:** 06, 07 (superseded).

**New engine** (blocking 10, 11, 19):
- **20:** Site security profile (`factionVein.features`, seeded site details, `{security}` condition)
- **21:** Wards: time ward + generic, Powder vs freeze, Prophet's Breath on observe
- **22:** Item tier scaling + 0.97 clamp
- **23:** Reinforcement clock
- **24:** `siteWary`
- **25:** Observation text variants

**Prose:** one ticket per event, with the 7 beats (§1.11) as sections. Each references `docs/writing-guide.md` and is flagged `PROSE-REVIEW:`.
- 26: the Yard, blocked by 19
- 27: the Arches, blocked by 10
- 28: the Shop, blocked by 11

**End of the work:**
- **29:** Muscle grilling (after 10, 11, 19, 26–28)
- **30:** Ward types grilling (after 21, independent of 29)
- **31:** More raid locations grilling (after 10, 11, 19, 26–28)
