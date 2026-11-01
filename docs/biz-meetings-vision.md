# Board Meetings — vision

**Status:** Vision agreed in conversation; not an implementation spec. Use this to
write tickets and settle the open rules below before changing mechanics.

**Working title:** Board Meetings. The goal system and its cards have no final
in-world name yet.

## Purpose

After Business Empire Act 1, the player has a working business and a lot of
systems pulling at them: offers, contracts, favours, partner asks, the Ticker,
demand spikes, the Today card. Each system is fine on its own; together they are
messy and overwhelming, and none of them tells the player *what to aim for*.

Board Meetings give the post-Act-1 game **direction**. Once a week the founders
meet, pitch goals, and the player picks one. The goal wraps existing systems in a
clear target, a reason, flavour, and a reward. It replaces vague pressure with one
legible ambition per week.

Design pillars:

1. **The player chooses.** Goals are pitched, never assigned.
2. **No choice is a punishment.** Picking one goal costs nothing on the others.
   Tension is spice, not the core.
3. **The premise must be true.** Every goal is generated from real game state.
   If Archie says a district is hungry for fate ore, the market says so too.
4. **Goals follow the business.** Which goals are available depends on where the
   player and the business stand now, not on a fixed list.
5. **Human, not a quest log.** The meeting is a short, funny scene with three
   people who know each other. The whiteboard is the quest log.

## The weekly meeting

- **When:** Monday, alongside payday and contract renewal. It **does not cost a
  time block**.
- **Length:** a short scene, roughly 30–60 seconds.
- **Who:** the founders — the player, Archie, James — plus Owen (see Cast).
- **Where:** James's workshop at first, then the player's HQ office once built
  (see Venue).

### Running order

1. **Minutes.** Last week's result, with a reaction from whoever pitched it.
   Full success is celebrated; base-tier-only is ribbed affectionately; a miss
   is laughed off and the voice says "next week, then". Most of the humour lives
   here.
2. **Debate.** An opener, then per offered goal (up to three, each pitched by a
   different voice) a case, a response from another voice (back / challenge /
   wobble) and, after a challenge, the pitcher's rebuttal. Sometimes one clash
   between the two most-opposed voices. Then the vote: option labels are goal
   names with the pitcher, the prompt holds tiers and rewards, and the player
   picks one. The pitcher is pleased in a line; one other voice concedes.
3. **Any other business.** A light slot for one-line asides, running gags, and
   pointers to opportunities that don't need a full card.

### Skipping

If the player doesn't attend, Archie picks for them ("You weren't there, so
you're doing mine."). Light, not a penalty. The player always has a goal.

### Tone

Humour does not need to be dry all the time. Meetings can be warm, silly,
bickering, affectionate. Running gags are encouraged — they are cheap to write
and give the scene a personality (James correcting the minutes, Archie's
"catering", Owen bringing a question nobody asked). Writing still follows
`docs/CONTENT-GUIDE.md` and `docs/writing-guide.md`; this is a looser register,
not a different voice.

## Cast

- **Archie** — sales, growth, landmark deals, security, faction angles. Charming,
  persuasive, taking the Mickey.
- **James** — crafting, quality, money discipline. Proud, cautious, reluctant
  host.
- **Owen** — always there; nobody has thought to ask him to leave, and it would
  feel odd now. Pitches occasionally and nervously, only cultivation rungs.
  Running gag: Archie keeps announcing he'll poach Owen from James as his own
  apprentice. Owen wants to learn from everyone.
- **The player** — chairs the meeting by choosing.

The board does not grow with new attendees. A scripted character may be added
later; the Owen gag is built so it can develop if that happens.

## Goal cards

### Anatomy

Each card has:

- **Pitcher** — which voice proposes it.
- **Pitch** — one spoken line in that voice.
- **"Why this week"** — the real cause, pointing at state (a Ticker headline, a
  demand spike, a faction's relation, the business's own numbers).
- **Whiteboard label** — short (about 25 characters) for UI on the whiteboard.
- **Tiers** — base / target / stretch.
- **Reward preview** — shown up front on the card, per tier.
- **Length** — one week by default; occasionally a 2-week project, clearly marked.

### Tiers

- **Base** always pays something, so partial success still feels good.
- **Target** is the goal as pitched.
- **Stretch** pays extra, or lets the player choose between two rewards.
- Tier numbers scale to the player's own baseline (e.g. the business's recent
  10-day stats), never absolute, so goals don't go trivial or impossible as the
  business grows.

### Choosing without punishment

- An unpicked goal angers nobody. That voice just says "next week, then".
- Unpicked voices get a small weight bump the following week, so every
  character's goals keep coming round.
- Picking a voice's goal earns warmth with that character; not picking earns no
  coolness.
- Occasionally (no more than about one week in five) two pitches compete for the
  same thing, as a flavour beat ("James and Archie both want the same twenty
  units"). Never a trap.

### Mid-week twists

At most one per week, drawn from the simulation. Twists are **opportunities or
neutral, never setbacks** — e.g. "the buyer will take double if you can manage
it". Opt-in; ignoring one costs nothing.

### Availability vs. selection

- **Which goals can appear** is decided entirely by state, through the ladders
  below. A goal only appears if its premise is true and its rung is the next one
  the player qualifies for.
- **Which three of those are offered** is a seeded pick (save seed + week
  number), so Rewind to Monday shows the same cards. Rewinding and choosing a
  *different* card is allowed — that's a choice, not a reroll.

## Goal ladders

Each goal family is a ladder. A card offers the next rung the player qualifies
for. Rungs are not prerequisites for each other: ladders open from **real
state**, so if the player hits a rung's target without taking the goal, that rung
is skipped. Nobody feels railroaded.

| Ladder | Example rungs | Voice |
|---|---|---|
| **Market share** | x% of one ore's production → higher % → market leader → a second ore at x% | Archie |
| **Crafting** | x% of an item's crafting share → new recipe tier → quality streak → signature item | James |
| **Cultivation** | yield target → bring a new vein online → vein health streak → cultivate a second ore type | Owen |
| **Landmark deals** | a big named buyer, only via the meeting → bigger → recurring flagship deal | Archie |
| **Partner** | relation to x → partner status → district benefit / perk unlocked → deeper tie | Archie or James |
| **Defuse** | head off a coming clash with a faction: relation to x, trade pact, aggression cooldown | Archie or James |
| **Security** | add alarms → upgrade security → hire guards → fill guard kits | Archie (tbc) |
| **Financial** | reserve covers n weeks → margin target → expansion fund | James |
| **Office** | "Get a proper office" and later office tiers | Archie / James |

### Landmark deals — scripted recurring income

Landmark deals are the route to steady, almost-passive weekly income.

- Some rungs on Archie's ladders (market share, landmark deals) **unlock a
  specific recurring contract** as their reward. That contract is what drives the
  goals Archie suggests: hit the rung, get the deal.
- These contracts are **authored, not random**: buyer, volume, pay, and term
  are scripted per rung. This controls how many high-paying recurring contracts
  a player can ever hold.
- Big or important contracts can themselves be goals; offers/contracts are not
  excluded from the system.
- Balance is tuned in playtesting.

### Partner and Defuse — one detector, two framings

One detector watches how the business overlaps with each faction:

- the player has veins in the faction's district and its district benefits would
  help them;
- the player crafts a lot of an ore type the faction produces;
- the player produces an ore type the faction consumes;
- the player's share of the faction's turf or ore is approaching a level that
  would provoke it.

Depending on the overlap and current relation, it surfaces as:

- **Partner** — a synergy. Proactively raise the relationship to the next level
  for a stated reason ("They burn half the fate ore in Camden. We make half the
  fate ore in Camden.").
- **Defuse** — a coming clash. Get ahead of it before the faction takes
  aggressive action, gets its relation bonus away from you, or drifts towards
  war.

### Security

Security goals must stay opportunities, not chores. The premise must be true:
veins worth more than they're protected for, or a rival's aggression rising.

## How existing systems fold in

The rule is: **opportunities go to the meeting; threats stay live.**

| Existing | Under Board Meetings |
|---|---|
| Offers / contracts | Unchanged as the *means* of doing goals. Big/landmark contracts can be goals or rewards. |
| Archie side deals | **Stay as they are.** |
| Faction favours | Still arrive as texts. Partly folded in: goals give the player a reason to focus on a relationship (relation to x, unlock bonus y, avoid a clash). |
| Partner asks | Same as favours. |
| Ticker / demand spikes | Feed premises into goal cards ("why this week"). |
| Today card Story row | Shows this week's goal and progress. |
| Raid warnings, vein alarms, unpaid wages | **Stay live and reactive.** Never wait for Monday. |

## Rewards

Rewards are shown on the card before choosing. They come from a varied menu,
each voice leaning towards its own:

- **Business** — bigger offer sizes, new buyer type, better contract terms, a new
  ladder opens, **a scripted landmark recurring contract**.
- **Market** — a press bump (a Ticker article raises demand for the player's
  goods for a while), buyer loyalty discount, first refusal on scarce ore.
- **Staff** — a trait or technique for Owen or James, skill XP.
- **Office** — the office improves over time (coffee machine, better whiteboard,
  the first contract framed). Mostly cosmetic, sometimes a small function. The
  office becomes a visible record of achievement.
- **Faction** — relation gains, perks, intel tips, aggression cooldown.
- **Knowledge** — recipe knowledge, sense or intel reveals.
- **Consumables** — `timePearl`, `enhancementPowder`. `rewind` rare or excluded
  (flagship feature).
- **Story** — a small vignette, a character backstory moment. Cheap to write;
  makes completion feel human.
- **Cash** — sometimes, not by default.

**Permanence:**

- **Individual rungs** give per-goal rewards.
- **Some rungs and ladder completions** give **permanent** upgrades or badges
  (office objects, framed badges on the office wall or whiteboard).

## Venue

### James's workshop (before the office)

Meetings start in **James's workshop** straight after Act 1. James is not happy
about it. Archie is charming, convincing, and taking the Mickey about it.

### The HQ office

- Narratively, meetings belong in the player's HQ, but an HQ with a spare room
  comes late. So **"Get a proper office" is one of the first goal rungs** —
  a goal, a reward, and a visual progression in one.
- After that, office tiers are upgraded through rungs and rewards, and the
  meeting scene upgrades with them.

## Whiteboard

The whiteboard is how the player references goals, both in the meeting and
mid-week.

- **Chosen goal:** a post-it in the centre, with a progress marker and tier
  marks.
- **Unpicked goals:** post-its parked in a corner (e.g. circled, "NEXT WEEK?" in
  Archie's handwriting).
- **Doodles** add character, one style per person: Archie draws himself rich;
  James writes in neat capitals and corrects other people's spelling; Owen
  sketches little veins. Doodles come from an authored pool, picked by state
  (completed, missed, someone's mood), never generated.
- **Mid-week**, the whiteboard is viewable to check progress. Most of the "is
  this working" feedback lives here.

## Art and assets

Keep art cost flat as venues upgrade:

- **Fixed pose set**: about 4 poses (speaking, listening, laughing, despairing)
  × 3 characters (Archie, James, Owen).
- **Venues as background plates**: James's workshop + office tiers (about 3).
- **Characters composited** over plates (plate compositor), so poses are not
  redrawn per venue.
- **Post-its and doodles as a runtime overlay layer**, not baked into art. The
  art never shows actual goal writing; goal text lives in the UI on tap.
- Mostly the *text* varies week to week; the visuals vary with venue tier.

## Launch scope

- Voices: Archie, James, Owen (Owen pitching rarely).
- About 5 templates per voice to start.
- Three cards per meeting, from different voices.
- **Week 1** is a scripted beat at the close of Business Empire Act 1, handing
  the player into the system.

## Ticketing boundaries and open rules

Settle before ticketing:

- **Balance** of landmark recurring contracts — count, pay, term — tuned in
  playtesting; authored per rung.
- **Security voice** — tbc while drafting prose (Archie suggested).
- **Weight-bump and conflict frequency** numbers (unpicked-voice bump; competing
  pitches ≤ ~1 week in 5).
- **Tier scaling** — exact baseline metric(s) per ladder.
- **Which rungs grant permanent upgrades/badges**, and where badges display.
- **Detector thresholds** for Partner vs. Defuse.
- **Office rung** — what "a proper office" requires from the HQ and room systems.
- **Skipped meeting** — what Archie's default pick prefers.
- **Mid-week twist pool** — content and frequency.
- **Mid-week whiteboard access** — from the office, the phone, or both.
- **Interaction with Business Empire Act 2** (`.scratch/biz-empire-act2/spec.md`):
  dynamic market and faction rivalry would make market-share, Partner and Defuse
  ladders far richer; decide whether Board Meetings ships before, with, or after
  it.
- **State shape** — `state.boardMeetings` (or similar) must stay a pure data
  tree: chosen goal, offered cards, rung progress per ladder, history for
  minutes and memory lines.
