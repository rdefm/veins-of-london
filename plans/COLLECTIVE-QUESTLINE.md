# THE COLLECTIVE — QUESTLINE DESIGN

*Status: agreed brainstorm output. Not a build spec — no ticket breakdown, no event
JSON, no final prose. Read `docs/VISION.md` §14 and `docs/CONTENT-GUIDE.md` before
implementing anything here.*

*Milestone home: M5 (faction storylines). Some hooks land earlier — see §8.*

---

## 1. Scope decision — deep pilot, portable spine

`docs/VISION.md` §14 budgets every faction a **3-event storyline at relation
25/50/80**, each event delivering one mechanical reward. This questline is
larger than that. It is structured so the excess is optional:

| Layer | Content | Ships for |
|---|---|---|
| **Spine** | 3 gate events at rel 25 / 50 / 80, one mechanical reward each | All five factions — this is the §14 template |
| **Branches** | Recurring characters, choice events, free-form objectives, the climax fork | The Collective first; other factions later or never |

The Collective is the pilot because it is the faction most players meet first —
lowest `joinRelation` (20), strong in East and South London, and the player
starts in Shoreditch. Whatever proves out here becomes the shape the other four
inherit.

**The spine must remain playable and coherent with every branch stripped out.**
If cutting the branches breaks the story, the split has been done wrong.

---

## 2. Thesis

> Adapting to survive a conflict changes you and your organisation in ways that
> are uncomfortable to admit and face.

Corollaries that are binding on the writing:

- **Nobody in the cast is wrong on purpose.** No villain inside the Collective.
  Every position is held sincerely and is defensible out loud.
- **The accusation in Arc 3 is partly right and partly wrong.** It is not the
  author's verdict delivered through a character's mouth. The player must be
  able to argue back and win points.
- **The thesis applies to the player and to Archie too**, not only to the
  faction. Everyone in this story is changed by it.
- **Arc 2's victories are real.** The player is not being set up. The wins
  happen, the veins are held, the balance genuinely shifts. The cost is
  concurrent, not retrospective.

---

## 3. The information thesis (the arc's central mechanism)

The Collective's identity in `data/factions.json` is decentralised, no admitted
hierarchy, `securityBias: -2`, `resourceLevel: 1`. Read that as a design
statement rather than a weakness:

> **A decentralised trust network has almost no attack surface because it keeps
> almost no records.** You cannot raid a vein you have not been told about.

So the ideological crime of Arc 2 is **not violence — it is surveillance.**

To use bought intelligence, the Collective has to know where its own veins are.
Which means writing them down. Which means a list exists. Which means the list
can be taken, sold, subpoenaed, or simply consulted by the wrong member.

**The Collective does not fall to the Firm. It falls to a spreadsheet.**

Every member can feel this happening and none of them can articulate why it is
bad, which is exactly why character **A** has to say it for them — and why A is
easy to dismiss as a sentimentalist right up until they are proven correct.

This register is squarely on-tone for the game: the ancient administrated,
secrets kept via filing, wonder leaking through the mundane. See
`docs/CONTENT-GUIDE.md` §3 rules 5 and 6.

---

## 4. Cast

Three new Collective characters, each a different answer to the arc's question —
*how much do we change in order to survive?*

### 4.1 Des — "Not at all"
**Function:** mentor, ideologue, **the leak.**

- Finds the player in Arc 1 when the player and Archie are struggling. Teaches
  prospecting and seeding. Gives far more than they take.
- Believes the Collective's softness *is* its armour, and that a Collective which
  wins this war has already lost.
- Drags on every escalation in Arc 2. Keeps being right about small things.
- In Arc 3: accuses the player — **and has been feeding the Firm.** Not for
  money. To make the escalation fail.

**Des's defence is good, and must be written as good:** in a faction whose stated
practice is sharing yields and moving ore through trusted contacts, talking to
other operators is not obviously betrayal. Des did not think of it as treachery.
Des thought of it as brakes.

> "You think I sold you. I slowed you down. There's a difference, and you're too
> far gone to see it."

**Writing constraint — this is the load-bearing one:** Des must be the best-written
character in the questline and the one the player likes most. Every lesson Des
gives in Arc 1 must be re-readable in Arc 3 as their thesis. Prospecting tuition
that is later a confession:

> "Nobody's ever raided a vein they didn't know about."

If Des is merely a plot device with a twist attached, the entire arc fails.

**Fair-play requirement:** Des's sabotage must have been visible as data before the
reveal — a Firm raid that arrived too accurate, a Firm claim on a site only three
people knew about, a loss that beat the odds. Telegraphed loudly, noticed
quietly. A player keeping notes should be able to catch it.

### 4.2 Nadia — "Completely"
**Function:** fixer, escalation engine, **the door to the Network.**

- Moves ore, finds buyers, knows people. The practical one.
- Pushes hardest to escalate in Arc 2. Feeds the player targets. Loves what the
  player is building.
- **Introduces the Network handler** as a solution to the war effort — buy the
  intel, stop losing veins. Presented as obvious, cheap, sensible. It is all
  three.
- In Arc 3: wants the player to formalise it. Structure, roles, a chain of
  command, the player at the top. Does not understand that this is the same
  funeral Des is mourning, just with better catering.

Ambition, not malice. Nadia's ending is a genuinely good outcome for everyone in it
except the thing they were trying to save.

### 4.3 Hakim — "I just want to go home"
**Function:** the stakes.

- Has a shop, a kid, a life the calc quietly pays for. **The person the whole
  thing is nominally for.**
- Takes the hits in Arc 2. Loses a vein. Loses a tooth. Does not become a
  soldier.
- In Arc 3: does not know what to do. Has no thesis, only a life.

**Hakim's vote is what the player is actually fighting over.** Des and Nadia are arguing
about principles; Hakim is the person the principles are supposedly in aid of. Any
climax that does not make Hakim's position matter has missed the point.

### 4.4 Archie — the door, not a slot
Existing canon (`docs/CONTENT-GUIDE.md` §3): cockney, blunt, bitingly funny,
generous in deed not word, time-allergic, magic is stock to shift.

- Loosely Collective, the way everyone in East London is loosely Collective. He
  takes **none of the three character slots and gets no new relation track** —
  he already has one, and the contact budget (§14: "+1–2 new contacts by 1.0")
  will not stretch.
- He is how the player meets **Des** in Arc 1. Then he steps back.
- **Archie has his own ambition, and it is not the Collective's.** He wants to
  build a thing *with the player*: a respectable enterprise, run properly, with
  whispered hopes of an empire that makes life easier for the downtrodden and
  unlucky — people like the two of them used to be — and turns a tidy profit
  while it is at it.

**The buried knife:** Archie's dream is structurally identical to **Nadia's**
formalisation, with Archie and the player at the top instead of the Collective.
Therefore:

- When the player chooses **Nadia's future**, **Archie is delighted.** His approval
  is the most unsettling beat in the questline and should be played completely
  straight — warm, pleased, no irony, no wink.
- **Des and Archie dislike each other from Arc 1.** The player is given a false but
  complete explanation for it (§4.5) and should stop wondering. It is not
  temperament and it is not the tenner.

Archie's Arc 3 function is barometer: he says the quiet thing about what the
player has built, **once**, and then changes the subject. One dry line. He does
not bring it up again. (`docs/CONTENT-GUIDE.md` §3 rule 2: one line per threat,
never two.)

### 4.5 The Archie / Des decoy

The antagonism between Archie and Des is real and ideological, and is revealed as
such in Arc 3. Before then the player gets a **decoy** — a false but complete
explanation they will accept and stop interrogating. An unexplained dislike makes
players suspicious; a mundane explanation makes them file it and move on.

The decoy is a **disputed debt**, and it is not decoration: it is the Arc 3
reveal rehearsed at small stakes.

**Archie**, when Des comes up, is reluctant. If the player pries, he produces
**the exact amount and the exact date**, and the view that Des has been wriggling
out of it for years. Tag line, delivered as a joke Archie knows is not a reason:

> "Also, he's Crystal Palace. Obviously untrustworthy."

**Des**, unprompted, mentions that he and Archie go way back — and speaks as a man
who settled up **ages ago**. No amount, no date. Mild warmth about it.

**Neither is lying.** The asymmetry is the point:

| | Thinks in | Recalls | Player concludes |
|---|---|---|---|
| Archie | transactions, which clear | amount and date | he's probably right |
| Des | relationships, where itemising is gauche | the *feeling* of having settled | he believes it |

So **Des is a man who sincerely believes things that are not true, when believing
them is more comfortable.** That is the exact psychology of the Arc 3 betrayal —
Des will not experience the leak as treachery either. The twist's fair-play setup
is planted in Arc 1 disguised as a joke about a tenner.

**Football notes.** West Ham (East, Archie) versus Crystal Palace (South, A) is
deliberately **not** a real rivalry. Millwall would have been — genuine history,
genuine violence — and would have made the antagonism read as dangerous rather
than petty. Low stakes are required here. **Des never mentions football back**:
doesn't engage, doesn't know, isn't interested. Funnier, and quietly the thing
about Des that grates.

### 4.6 The fandom layer — encoding without banter

Star Wars (Archie) and Star Trek (Des) are not arbitrary: the Federation is a
post-scarcity mutual-aid society with no money between members; Han Solo is a
smuggler with debts who does the right thing and then invoices you. The fandoms
**encode the two ideologies**. That is the whole reason they are here.

**Rule: keep the encoding, cut the banter.** The moment two Londoners start doing
Star Wars versus Trek bits, the scene dies on `docs/CONTENT-GUIDE.md` §3 rule 4.
No back-and-forth, no running gag, no catchphrase.

**Archie — one unremarked prop.** A Millennium Falcon keyring on his keys. Noted
in **one clause of one Arc 1 description**. Never joked about, never explained,
never mentioned by another character. Optional quiet callback: it is on the desk
in the new office if the player picks Nadia's Formalise ending.

**Des — one line, said twice.** Des gets exactly one quotation, and it is:

> "The needs of the many outweigh the needs of the few."

- **Arc 1:** said about sharing yields. A mild geeky throwaway. Archie rolls his
  eyes. The player files it under *Des is a bit of a nerd*.
- **Arc 3:** said again. Same words, no emphasis, no acknowledgement that it is a
  repeat. It is now the justification for feeding the Firm — and it always was.

**No other Trek material.** No hails, no catchphrases, no second quotation. Des
must carry enough gravity for the Arc 3 accusation to land, and a character who
does bits on the phone cannot. One line, twice, and nothing else.

### 4.7 Staging the decoy

Do not land the keyring, the football and the debt in the same scene — three
pieces of business about one relationship becomes a comedy set piece, which this
game does not do.

| Beat | Where | Trigger |
|---|---|---|
| Falcon keyring | Arc 1, one clause of one description | Ambient |
| The debt (amount, date) | Arc 1 | **Player pries** — must be player-initiated |
| "Obviously untrustworthy" | Same scene as the debt | Tag on the above |
| Des's version ("ages ago") | Arc 1, a later scene | Unprompted, in passing |
| "The needs of the many" (1) | Arc 1 | About sharing yields |
| "The needs of the many" (2) | Arc 3 | Defending the leak |

### 4.8 The Network handler
**Function:** the price of knowing things. Introduced in Arc 2 by Nadia.

Consistent with `data/factions.json`: *"Information is the resource"*, *"They are
interested in you, which should be flattering and is mostly unsettling."*

**The handler's rule, and it is absolute: the handler never lies.** Everything
sold is true, fairly priced, and ruinous. Politeness with an invoice. No
double-cross, no hidden agenda, no dramatic betrayal — the horror is that the
transaction is entirely honest and the player keeps choosing it.

This makes the handler frightening without menace, and keeps them tonally
distinct from the Conclave's liveried understatement (VISION §14).

---

## 5. Arc structure

### Arc 1 — Gift (spine gate: relation ~25)

**Superseded (collective1-08): this brainstorm section is no longer the build
spec.** `.scratch/collective-act1/spec.md` §4 and §6 are canonical for Act 1's
structure and content — cast names (Des/Nadia/Hakim for A/B/C), the exact
scene beats, and the engine (objectives, Messages app, faction trade lane)
Act 1 was built to prove. Kept below for the arc's original brainstorm intent
and thesis, which the spec still honours.

The player and Archie are struggling. **Des** finds them.

- Des teaches **prospecting and seeding** — mechanically real tuition, not a
  cutscene about tuition.
- The player is given far more than they give. This is deliberate and inverts the
  usual outsider-fixes-your-organisation shape: the player's debt is real.
- Introductions to **Nadia** (buyers, moving ore) and **Hakim** (the shop, the kid, the
  normal life).
- Relations build across several small events. Collective districts (East and
  South) start feeling inhabited rather than tagged.
- **Firm friction appears as weather, not plot** — a skirmish overheard, a member
  down a vein, a shrug about it. No threat the player can act on yet.

**Arc 1's job:** make the player like these people, and make A's lessons quotable.

### Arc 2 — Conflict (spine gate: relation ~50)

**Superseded (2026-09-05): this brainstorm section is no longer the build
spec.** `.scratch/collective-act2/spec.md` is canonical for Act 2's structure
and content — the four-phase shape (Call / Hardening / Crack / Meet), the
exact scene beats, and the engine (Nadia's ledger objectives, the Network
handler's Targets/Sourcing products, Hakim's vein loss and ruin) Act 2 is
built to prove. Kept below for the arc's original brainstorm intent and
thesis, which the spec still honours.

The Firm is openly raiding Collective veins and hurting members.

**Phase 1 — scripted choice events.** Teach the vocabulary of the choice. Each is
authored, each has a hard line and a soft line, each cost lands **in the same
scene as the win**:

| Choice | Hard | Soft |
|---|---|---|
| A contested vein | Retake by force | Buy it back, eat the loss |
| A vulnerable site | Post a permanent lookout | Stay soft and fast |
| A hostile member | Make an example | Absorb it |

**Phase 2 — free-form objectives.** The player is given targets, not scripts:
*hold X veins across Collective districts*, *retake site ABC*, *keep the
Collective's losses under N for a week*. The player solves them with the systems
already in the game — raiding, security, cultivating, trading.

**The method is logged, not just the outcome.** How the player got there is what
Arc 3 reads back.

**The Network thread opens here.** Nadia brings the player to the handler: buy intel
to stop losing veins. It works. It keeps working. To act on it the Collective
must know where its own veins are — and starts keeping records. The
record-keeping should be shown as *relief* — finally, some organisation around
here — and never commented on as sinister.

**The balance genuinely shifts in the Collective's favour.** Veins are held and
reclaimed. This is a real win and should feel like one.

### Arc 3 — The bill (spine gate: relation ~80)

The conflict stops going well. Tension inside the Collective is the subject; the
Firm is a pressure system, not a character.
To get their edge back, Archie suggests going to James for help. James introduces the player to Dials; after doing some jobs / quests for James, he agrees to help you build one (building a Dial requires 'the gift', which is incredibly rare. It's what James suspected the player had in their first interaction).
The player is able to then use the dial to turn the tide by claiming back stolen veins for the Collective. As this begins to turn the tide in the Collective's favour, there's a crisis meeting.

- **Des accuses the player.** This is not the reveal — it comes first, on its
  merits, and the player can argue.
- **Des is the leak.** And the player learns it **by buying it from the handler.**
  The only route to the truth is the exact sin Des was trying to prevent. Des does
  not get to be surprised.
- **Nadia** wants formalisation and wants the player leading it.
- **Hakim** does not know.
- **Archie** says his one line.

**On the Firm:** they are an escalation engine here, not a villain with a plan.
They get their own storyline elsewhere in VISION §14 and do not need to be
interesting in this one.

---

## 6. Climax — three futures, plus a hidden overlay

### The public choice — always available
Which character's vision wins. Each **rewires the faction's actual data**, so
each is a different economic lane for the rest of the game, not a different
cutscene.

| Future | Champion | What happens | Mechanical shape |
|---|---|---|---|
| **Disperse** | Des | The Collective goes back to being unraidable by being unmappable. Gains released, records burned. | Security and resources fall back toward baseline. Rewards route through sourcing, prospecting quality, and relation — not territory. |
| **Formalise** | Nadia | The Collective becomes an organisation with a (loose) chain of command, and the Nadia is at the top of it (with the player and Archie). | Security and resources climb. It is now the Firm with better manners. Strongest material outcome, and the thesis's death. |
| **Settle** | Hakim | A negotiated split with the Firm. Territory ceded, peace bought, rent paid. Nobody dies. | Smaller, stable, safe. Nobody is proud. |

Each future must be defensible in-fiction by an intelligent person. None is
flagged good or bad by the game.

### The private choice — gated on Network relation
Layered on top of any of the three: **a private answer that differs from the
public one.** The player's declared alignment and their actual one come apart.

This is the entry to the **Network questline** and where the double/triple-agent
fantasy lives. It is deliberately housed there rather than as a fourth Collective
ending, because VISION §14 states that joining one faction locks its rivals'
storylines at event 2 — a literal dual membership would break that rule. Brokering
through the Network does not.

The Arc 2 handler events are the setup for this. A player who never engaged with
the handler should not see the overlay at all.

---

## 7. Tone guardrails

Per `docs/CONTENT-GUIDE.md` §3, and worth restating for this arc specifically:

1. **No lectures.** The accusation is a character's position, not a verdict. If a
   line reads as the author scolding the player for enjoying Arc 2, cut it.
2. **One dry line per threat.** Especially Archie's Arc 3 beat. One.
3. **Deaths, if any, are mundane and awful** — administrative, not operatic. This
   game's menace is quiet.
4. **The record-keeping is never described as sinister.** It is described as a
   relief. The player should notice on their own, weeks later.
5. **The handler is polite.** Always. No leaning on anyone. The invoice does the
   work.
6. **A's dislike of Archie, and Archie's of A, is explained falsely** (§4.5) and
   never truthfully until Arc 3, where it doesn't need to be.
7. **No fandom banter.** The Star Wars / Star Trek layer is encoding, not
   material (§4.6). One prop, one line said twice. No exchanges about it.

All new prose from this document ships flagged `PROSE-REVIEW:` per the project
constitution. Sample lines in §4 are illustrative drafts, not approved copy.

---

## 8. Technical notes for implementation

Three findings from the current codebase that shape how this gets built.

### 8.1 `joinRelation: 20` sits below the first spine gate

**Resolved by `.scratch/collective-act1/spec.md` §8.6 (collective1-16):**
`data/factions.json`'s `collective.joinRelation` is raised 20 → 25, so the
data and the fiction agree exactly with Arc 1's gate. The generic Join button
is also suppressed for the Collective specifically (`ContactCards.
build_faction_card()`) — membership is granted only by S14's "I'm in" choice
(`col_a1_closer`) or its deferred-join follow-up, never by relation crossing a
threshold on its own. A player literally cannot join before meeting Des,
Nadia and Hakim: the three thread-resolution favours alone total +27,
already past the new 25 gate, and the closer itself is what offers
membership.

*(Original finding, superseded above: `systems/factions.gd::can_join()` read
`joinRelation` directly at 20, below the Arc 1 gate of ~25, so a player could
in principle join before the questline's first event fired.)*

### 8.2 Hardening the Collective is already implemented
`systems/factions.gd::_security_opulence()` reads `securityBias` **statically**
from `GameData.FACTIONS`, but reads the faction's balance from **live state**
(`state.factions[id].resources`) — with `RESOURCE_OPULENCE_BASELINE = 660.0` and
`RESOURCE_OPULENCE_DIVISOR = 360.0` tuned so the starting spread produces a
meaningful tilt.

Therefore: **Arc 2 funnelling resources into `state.factions.collective.resources`
makes Collective veins genuinely roll harder security tiers.** No new field, no
new formula. The thesis expresses itself through a mechanism that already ships.

If the climax needs to move `securityBias` itself (Disperse pushing it back
toward −2, Formalise pushing it up), that requires a new **state-side override**,
since the current value is static data. Prefer the resources lever where it
suffices.

### 8.3 The method log must be pure data
Per the project constitution, `GameState.state` is a pure data tree —
Dictionaries, Arrays, primitives, no object references. The Arc 2 method log is
therefore a Dictionary of counters under state.

Two consequences:

- It saves and snapshots for free.
- **Rewind can undo it.** A player can rewind away a hard-line choice and the log
  will forget. This is worth a deliberate decision rather than an accident —
  there is a good design in either direction, and the flagship feature interacting
  with the game's moral ledger is a feature, not a bug.

**Resolved by `.scratch/collective-act1/spec.md` §5.7 (collective1-09):** Rewind
erases the log. It is ordinary state (`state.methodLog`), restored by
`Events.rewind()` like everything else — Rewind is a consumable with a price tag
and a crafting cost, and a ledger that kept the receipt anyway would betray a
mechanic the player paid for. In fiction the world genuinely reset, nobody else
saw it, and nothing happened. A neutral counter of rewinds used at choice points
remains deferred, not decided, for Arc 2.

---

## 9. Open questions

Unresolved. None block starting on the spine.

1. ~~**Names, ages, districts and voices for A, B and C.**~~ **Closed by
   `.scratch/collective-act1/spec.md` §3 (collective1-08 onward):** A, B and C
   are Des, Nadia and Hakim — cast, voice and district are all spec.md §3's
   canonical answer for Act 1.
2. ~~**One mechanical reward per spine event.**~~ **Closed by
   `.scratch/collective-act1/spec.md` §8.5 (collective1-16):** for Act 1's own
   spine gate, the reward *is* the favour itself, not a discrete unlock —
   the four thread beats (S1/S7/S10/S12) award +3/+8/+8/+8 relation, a
   cumulative +27 that alone clears the 25 gate, verified end to end by this
   ticket's closer test. A player who never trades with the Collective still
   gets in on favours alone; trade only gets an efficient player there
   sooner. **Act 2's own gate (50) is now closed too, by `.scratch/
   collective-act2/spec.md` §5.6: the reward extends Hakim's existing free
   intel roll to occasionally flag a weak enemy vein, not just fresh ground —
   the arc's information thesis restated as a menu, sitting next to the
   Network handler's paid equivalent, rather than a discrete unlock bolted on
   separately.** Arc 3's own gate (80) remains undecided.
3. **What happens to A** — exile, death in combat, they leave on their own, or the
   player covers for them. Death is available (danger is sincere) but must be
   mundane per §7.3. Covering for them is the least explored and possibly the most
   interesting.
4. **Does the Collective survive in all three futures?** Currently assumed yes, in
   three different conditions. Worth testing whether one future should be able to
   end them.
5. ~~**Does the Arc 2 log gate the futures or only flavour them?**~~ **Closed
   (2026-09-05, `.scratch/collective-act2/spec.md` §5.5): flavour only.** All
   three Act 3 futures stay reachable regardless of `state.methodLog`'s
   contents; the log exists so Act 3's dialogue can react to how the player
   got here, not to lock climax options a player may have been aiming at for
   hours.
6. ~~**Which contacts get real relation tracks.**~~ **Closed by
   `.scratch/collective-act1/spec.md` §3/§8.4 (collective1-07):** all three —
   Des, Nadia and Hakim — get real contact entries, exceeding the "+1–2 new
   contacts by 1.0" budget by explicit human decision (VISION §14 amended).
   None of the three gets a *personal* trickle from trade, though: §8.4's "the
   meter that owns the lane" rule means Collective trade feeds
   `state.factions.collective.relation` directly, and a contact's own
   relation only moves when a story beat says it does.
7. **The Collective's endgame stance** (VISION §15) under each of the three
   futures.
