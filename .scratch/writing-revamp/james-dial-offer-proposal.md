# James's Dial — the offer (proposal)

New event proposed for `data/events/james_dial_offer.json`. This follows the (not yet drafted) repair event, where the player's Recharge Movement brings James's Dial back. Here James shows it working, confirms the player could make their own, and unlocks seeding (`dialGiftGranted`). This is the Arc B capstone set-up (`docs/story-restructure.md`). Written against `docs/writing-guide.md`.

**Entry gate (proposed):** `jamesDialRestored`, set by the repair event. Summons by text, like the evaluation.

**James's motivation, layered:**
- **Stated: expedience** (card 7). He's past sixty, Movements wear, and the player is the only person who can make him another.
- **Real: protection** (card 8). Gifted makers get found and kept. This is the scene's threat, played straight.
- **Implied: the teacher's debt** (card 9). "I've met two. You're the second." This calls back to `james_meeting` without saying what happened to the first.
- **Being right** (card 5). One Plato line about what the trade has shrunk to.

## §1 goals

1. **Hook:** James's text named a time and the player is nine minutes late. He notices.
2. **Focus:** the seeding cost is stated in calc and handed over on paper. One Dial, refined through Movements, set out as stock.
3. **Brief:** 16 cards. The hub lets the player skip any or all of the three questions.
4. **Jokes:** (a) "That one was empty, before you ask," after the jar nearly breaks. (b) "You're not getting any younger…", next to the urgency line. The threat (card 8) gets no joke.
5. **James as a person:**
   - Tell: pushing up the bent arm of his glasses, and clicking the collar.
   - Unspoken care: he tears a page out of his ledger.
   - Want: someone to keep his Dial running.
   - Exit: the shutter comes down mid-goodbye.
6. **Memorable moment:** the jar hanging in mid-air. Then, on the torn ledger page, "Tell no one. Not even Archie."

```json
{
  "id": "james_dial_offer",
  "on_complete": [
    { "op": "set_flag", "flag": "dialGiftGranted", "value": true },
    { "op": "set_flag", "flag": "jamesDialOfferSeen", "value": true },
    { "op": "set_screen", "screen": "phone" }
  ],
  "cards": [
    {
      "type": "narration",
      "label": "Bermondsey — James's unit",
      "speaker": null,
      "text": "James's text said \"Eight. Not ten past.\" It is nine minutes past. The shutter is up a foot. You take that as an invitation. James, from the look of him, takes it as lateness."
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "The Dial is back on the umbrella handle. Under the collar, your Movement ticks, steady. James hasn't put the umbrella down since you came in."
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "Without a word he sweeps a jar off the shelf. Two clicks of the collar; he presses the catch. The jar stops a hand's width above the concrete and hangs there, perfectly still."
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "James",
      "text": "He takes the jar out of the air and puts it back. \"Forty years it's been with me. It knows how I stand, how I grip, how long I hesitate.\" He checks the label. \"That one was empty, before you ask.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "\"Could I make one?\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "James",
      "text": "\"You could. That is the problem.\" He pushes his glasses up by the bent arm. \"Plato's Atlanteans built temples from this metal. The Guild sells it by the gram with instructions. Ask what you're going to ask.\""
    },
    {
      "type": "choice",
      "label": null,
      "speaker": null,
      "text": "James sits on the stool with the umbrella across his knees, and waits.",
      "choices": [
        { "id": "askWhy", "label": "Ask why he's helping", "effects": [], "result_text": null, "goto": 7 },
        { "id": "askWhoKnows", "label": "Ask who else knows", "effects": [], "result_text": null, "goto": 8 },
        { "id": "askTeacher", "label": "Ask who taught him", "effects": [], "result_text": null, "goto": 9 },
        { "id": "askCost", "label": "Ask what it costs", "effects": [], "result_text": null, "goto": 10 }
      ]
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "James",
      "text": "\"I am past sixty, and Movements wear. You are the only person I know of who can make me another, and a careless one is no use to me.\" He says it flatly. It sounds rehearsed.",
      "goto": 6
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "James",
      "text": "\"Me. Keep it that way.\" He doesn't smile. \"People who can make these get found. Then someone offers them a bench, a salary and a door that locks from the outside. The ones who say no aren't asked twice.\"",
      "goto": 6
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "James",
      "text": "\"Someone the calc moved for.\" He turns the collar one click, then back. \"In forty years I've met two. You're the second.\" He doesn't say where the first one is now.",
      "goto": 6
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "James",
      "text": "\"Calc of all five types. Forty of each, eighty of life. It has to live with you, so it takes life.\" He tears a page from his ledger, which you have never seen him do. The figures are already written on it."
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "\"Why not make two? Keep a spare.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "James",
      "text": "\"Because it grows with you. Two would grow at half the pace, and neither would be worth carrying. Want it to do something else? Change the Movement.\" A pause. \"Start soon. You're not getting any younger, which I gather comes as a shock at your age.\""
    },
    {
      "type": "choice",
      "label": null,
      "speaker": null,
      "text": "James looks at you over his glasses, as though checking you for wear.",
      "choices": [
        { "id": "thankHim", "label": "Thank him", "effects": [], "result_text": "\"Don't.\" He is already looking at the shelf." },
        { "id": "startThisWeek", "label": "Say you'll start this week", "effects": [], "result_text": "\"Start when you can afford it. Not before. I'm not lending you calc.\"" },
        { "id": "pocketPage", "label": "Fold the page away", "effects": [], "result_text": "You fold the page into your wallet. James watches it go, and seems content with where it's kept." }
      ]
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "James",
      "text": "\"Your own bench, not mine. Fit it to something at least forearm-length that you can carry without explaining. I chose an umbrella. This is London.\" A pause. \"Bring it here when it's made. I'll tell you what you did wrong.\""
    },
    {
      "type": "resolution",
      "label": null,
      "speaker": null,
      "text": "The shutter comes down while you're still saying goodbye. On the street you unfold the page. Under the figures he has added one line: Tell no one. Not even Archie."
    }
  ]
}
```

**Unchanged/changed:** new event; no live `data/events/*.json` touched. No art. The flat `cards` + numeric `goto` hub (cards 7–9 loop back to the choice at card 6; card 10 is the forward exit) follows `tests/fixtures/demo_hub_questions.json`. The three question options are one-shot.

## Open points for review

- **Repair event missing.** This assumes the repair event exists and sets `jamesDialRestored`, with the player's Recharge Movement seated in James's Dial. That event still needs drafting, including James paying for the calc (evaluation open point).
- **Gift flag split:** `dialGiftGranted` is set here, not in the evaluation, which means REFERENCE §2 ("set only by the Collective Act 2 quest") needs updating to point at this event. `Dial.attempt_craft_movement()` still has no gift gate; the repair event needs a separate access route anyway (evaluation open point).
- **Hardcoded cost:** card 10 says "forty of each, eighty of life", which matches `data/dial.json` `seedCost` today. If seeding costs get tuned, either switch to `fillFromContext` placeholders or cut the figures and leave "it's all on the page".
- **Skippable threat:** a player who picks "Ask what it costs" straight away misses the protection reveal (card 8). Option: make card 8 common to all routes and drop `askWhoKnows`. That's stronger, but it loses the "drawn out" layering.
- **Joke count:** "This is London" (card 14) may count as a third joke. Cut it to "I chose an umbrella." if so.
- **Simile:** card 13's "as though checking you for wear" is the scene's one simile.
- **Time block:** no `lose_time_block`. This is a summons, not paid work. Confirm.
- **ToDo:** there's no objective for "Seed a Dial". If the Notes app needs one, it needs a flag-driven entry or a new op.
- **James's age:** "past sixty" and "forty years" are new specifics. CHARACTER-VOICE-GUIDE only says sixties, and the evaluation says the teacher made his Dial "when I was young".
