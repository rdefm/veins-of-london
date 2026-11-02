---
name: observation-prose
description: Draft observation prose (high/mid/low insight rolls per ore lens) for a Vein event JSON, cold-open style, and propose it in chat for review. Use when the user says "observation-prose <event>" or asks for observations for an event.
disable-model-invocation: true
---

<what-to-do>

The user names an event JSON (e.g. `james_meeting`, or a path under `data/events/`). Draft observations for it and **propose them in chat for the user to review, edit and approve. Do not code anything into the game** — no JSON edits, no new files, no tickets — until the user approves and explicitly asks.

1. **Read the event** at `data/events/<id>.json` (or the given path) in full: every card, speaker, choice and outcome, so you know what is actually happening — and what is about to happen — on each card.
2. **Read the style reference**: the `observations` block of `data/events/prologue_cold_open.json` (cold open). Match its shape and voice. If the event already has observations, read them too and build on rather than duplicate — existing observations and their texts stay untouched; only propose new ones. If a storyboard proposal exists (`.scratch/writing-revamp/<event>-proposal*.md`), read it: build on its voice, characters and anchors, don't replace them.
3. **Read the voice rules**: `docs/writing-guide.md` (characters, humour) and `docs/CONTENT-GUIDE.md` (tone). Grep for any character in the event to get their established voice and traits.
4. **Pick the observe cards.**
   - Card 1 always gets an observation.
   - Later cards get one only where there is something genuinely worth observing — a new arrival, a shift in mood, a tell, a hidden stake, something the player could act on. Skip cards where nothing new is happening. Say briefly why each chosen card earns one.
   - **Reads carry forward.** An active observation is inherited by every later card in file *array* order (not by route) until another card sets `observe`. For each new read, say where it should stop — which later card needs its own `observe` (or the event's existing default read put back) so stale reads don't leak onto unrelated cards.
5. **Draft each observation** across the five ore lenses — `time`, `physics`, `life`, `fate`, `emotion` — using 2-3 lenses per card, only where narratively fitting. No filler lenses. Each lens has three tiers:
   - **High roll (`base 0.25`)** — good, valuable insight. Concrete and useful: something the player could act on or that reframes the scene. Never spoils outright; it notices, it doesn't narrate the plot.
   - **Mid roll (`base 0.55`)** — a hint / vague insight. Points in the right direction without landing it.
   - **Low roll (`miss`)** — funny, clueless, and/or dangerously incorrect. Distracted, confidently wrong, or reads the room backwards.
   - **Lines describe what is there, never what to do about it.** A high roll states the fact; the player draws the conclusion. No advice, no "you could…".
6. **Propose hooks** where they make narrative sense — never forced. Aim for a mix across the event of informative, mechanical and funny reads. A mechanical read is either:
   - an **unlock**: a high-tier read gates a new option (an `observed` condition in that option's `requires`), or
   - an **odds mod**: an `observed` check mod on an existing option's roll.

   Reuse existing mod values (+0.05 / +0.13) and shapes already in the event file; if a new number seems needed, ask. Choice cards cap at 4 options (`Events.MAX_OPTIONS`) — a new option goes on the `…2` follow-up card. List each hook under the read it hangs off.
7. **Tone**: what a real person would actually say or think in that moment. Second person, plain London speech, short. One dry line, not three; if a line winks at the camera, cut it. No exposition dumps, no game-speak.
8. **Present** in chat, grouped per card:

   ```
   ### c<N> — <one-line what's happening> (why observe here; read stops at c<M>)
   **physics**
   - High: ...
   - Mid: ...
   - Low: ...
   - Hook (optional): unlocks "<option>" / +0.05 on "<option>"
   **emotion**
   ...
   ```

   End with any open questions (e.g. a lens you weren't sure fits, a fact about a character you inferred). Then stop and wait for edits/approval.

</what-to-do>

<supporting-info>

## Lens cheat-sheet

- **time** — timing, schedules, who's early/late, what hour it is and what that implies, how long something has been going on.
- **physics** — bodies, space, exits, objects, hands, footing, what's physically in reach.
- **life** — who else is around, health, fatigue, crowds or the lack of them, living things in the scene.
- **fate** — gut feeling, odds, things that don't add up, the shape of what's coming.
- **emotion** — what people are feeling and hiding; tells, tension, mood shifts.

## Schema (for later, once approved)

Observations live in the event's top-level `observations` map, keyed `<event>_observation_c<N>`, each `{ "blocks": { "<ore>": { "tiers": [ {"base": 0.25, "text": high}, {"base": 0.55, "text": mid} ], "miss": low } } }`, with the card carrying `"observe": "<key>"`. Lint (REFERENCE.md §3.9d): tiers best-first, a `miss` text on every block, `atLeast` within tiers. Only write this when the user approves and asks for it.

</supporting-info>
