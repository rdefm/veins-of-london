# 04 — cold_open (observation variant): wire c20 "anything to worry about?"

**Status:** ready-for-agent

**What to build:** In the observation-intro variant of the cold open, card c20 (Archie: "So then, Holmes, anything we should worry about?") reacts to what the player saw on the c19 observation (`cold_into_observation1`). It becomes a 2-option choice card:

1. **Mention it** — an observation pick on `cold_into_observation1` covering all five ores (physics, life, emotion, time, fate). Mid tier (`atLeast: 1`) and top tier (`atLeast: 2`) each get an outcome. Greyed with a reason when nothing qualifies (e.g. the player rolled misses or never observed).
2. **"Nah. Probably fine."** — always available.

Outcomes (the human's decision):
- **Mid-tier mentions** — Archie brushes them off. The event goes on unchanged.
- **Top-tier mentions** — Archie gives the player a serious look and tells them to keep their eyes open. The event goes on (no branch). Whether this sets a flag for later (e.g. Archie remembering that the player called it) is not decided; ask before adding one.
- **"Nah"** — Archie carries on to c17 as now.

All outcomes rejoin at c17. Per-ore mention lines should match what that ore's tier text showed the player (e.g. a physics top read is about there being one way out).

Also in this ticket — prose pass on the observation text and nearby cards, from the review in the authoring session (human to confirm each; apply only the ones they accept):

| Ore | Tier | Issue | Suggestion |
|---|---|---|---|
| physics | top | Says the same thing twice; unclear whose door it is | "One way into the alley. The chicken shop's back door is stacked with boxes. If this goes wrong, you're going out past them." |
| physics | mid | Rain isn't set up anywhere else in the event | Set it up in c1, or change the line ("…bad for running, bad for fighting. Equally bad for everyone.") |
| physics | miss | Mild; trailing space | "You look straight into the strip light over the door. Now there's a purple blob wherever you look." |
| life | top | Comma splice; "suspiciously quiet" is stock | "No customers. The lad on the counter's asleep on his arms. No cars, nobody walking past. Whatever happens back here, nobody sees it." |
| life | mid | Same fact as top, just vaguer | Right fact, wrong conclusion: "Dead quiet. Nobody about. Handy, really — nobody to see you." |
| life | miss | Second smell joke if fate miss takes the fishy pun | "A pigeon's working on a chip bigger than its head. You watch it longer than you should." |
| emotion | top | Not informative; the mid line says more | Reveal something: "Archie's whistling the same four notes on loop. He does that when he's not telling you something." |
| emotion | mid / miss | Good | Keep |
| time | top | Good; trailing space | Keep |
| time | mid | A fact with no conclusion | "…still aren't here. Traffic on the A13, probably." |
| time | miss | Good | "You can just about see the footie on the chicken shop telly." |
| fate | top | Pun in the best tier; vague | Foreshadow Nick: "You count the people this needs: you, Archie, two buyers. Your gut keeps counting one more." |
| fate | mid | Typo "day" → "days" | Keep otherwise |
| fate | miss | Not funny; too close to mid | "Something smells fishy. On reflection, it's the chicken shop." |

Design rule for mid tiers: **right fact, wrong or missing conclusion**. Top tiers are useful intel. Misses are where the humour goes. Other typos: c13 "ae" → "age"; c14 "Craiglist" → "Craigslist" (full stop outside the closing quote, trailing space).

Replace the current c20 stub (6 options, one gated per ore plus "nah" — over the 4-option cap, fails lint).

All new prose follows `docs/writing-guide.md` and `docs/CONTENT-GUIDE.md`; flag every new/changed line `PROSE-REVIEW:`.

**Blocked by:** 01 — Observation pick: core mechanic; 03 — Storyboard tool: author pick options. (02's explainer is nice to have for this card, not required.)

**Relevant files:**
- `.scratch/writing-revamp/cold-open-proposal2.md` — storyboard draft (c19 `observe`, c20, `observations.cold_into_observation1`)
- `data/events/cold_open_observation.json` — live variant file (currently stale vs the draft; promote with the `implement-storyboard-event` skill)
- `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`, `docs/CHARACTER-VOICE-GUIDE.md` (Archie's voice)
- `docs/REFERENCE.md` §3.9d Observation

- [ ] c20 is a choice card with exactly 2 options: the mention pick and "Nah. Probably fine."
- [ ] Every ore has a mid and a top outcome; mid gets brushed off, top gets "keep your eyes open"; all rejoin at c17
- [ ] With no qualifying read, the mention option shows greyed with its reason
- [ ] Accepted prose fixes applied; storyboard lint and Godot event-content lint clean
- [ ] PROSE-REVIEW list in the report; on-device check: observe high / mid / miss runs through c20
