# Intro event — proposal 3 (choices)

Revision of applied `intro-proposal2.md` (= current `data/events/intro.json`), adding the three intro beats from review §18.4 / spec "opening-choices" ticket 11. Under the spec's beat table, which supersedes "keep existing `choices[].effects`" for opening events (see writing-guide note).

**Card count:** 16 definition cards (was 18). With one resolution card per choice, the player sees **19** (was 18). Saved by: merging Archie's Vinnie/Mr Bean cards into the pitch choice, making the Wetherspoons card the question choice, and folding the old "What was that?" card plus Archie's calc explainer into the answers.

Goals:

1. **Hook + focus.** Same money-first opening. Each choice is about the job: how much you know, what you're paid, what you risk. "How much is it worth?" gives the first real price (time-type `basePrice` 75 → "seventy-odd quid a chip", ten = £750).
2. **Brevity.** Choices replace cards. They don't add cards. Every branch rejoins the same spine, with no extra cards per branch.
3. **Humour beside danger.** Anchors unchanged: Vinnie Jones / Mr Bean before the threat, "Somewhere with lights. And witnesses." after it. New lines are deadpan, and a player only sees one result per choice.
4. **Archie as a person.** He still steps into the gap before you choose (care, done not said). Freeze lets him keep doing it. "I want half" annoys him, and he gives you more anyway. "Who are the buyers?" gets the cousin he's never met, which pays off as a check modifier.
5. **Continuity.** "Rent's due Monday" (spec default; bills land Monday per ADR 0006). The fixed label `{today} — Whitechapel` resolves to "Tonight — Whitechapel" (no "Earlier tonight" flashback drift). "Half ten" is cut from the prose, so it can't fight the phone clock (Evening = 20:07). `at` stays Tuesday Evening (`evening`, `advance: true`; day 1 = Tuesday).

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 3 pitch | `stand` | "I'll stand there." | none |
| | `askBuyers` | "Who are the buyers?" | `introAskedQuestions` (later +15% spotting/haggling; +15% on `stepIn` below) |
| | `wantHalf` | "I want half." | Archie −3, `introWantsHalf` (buyer split 60/40 your way) |
| 6 knife | `freeze` | Freeze | Archie +5 |
| | `stepIn` | Step in front of Archie | check 45%, +15% "You knew about the cousin", min 15%, `show: odds`. Success: `introBrave`, Archie +10. Fail: `player.hp` −10, `introInjured` |
| | `grabBag` | Go for the bag | check 30%, min 15%, `show: odds`. Success: +2 time ore, `introGrabbedCalc`. Fail: shoved down, as Freeze (Archie +5) |
| 10 pub | `whatIsIt` | "What was that stuff?" | none (calc explainer + allergy) |
| | `howMuch` | "How much is it worth?" | none (£ explainer: ~£75/chip, ten = £750) |
| | `whereFrom` | "Where does it come from?" | `introAskedSource` (introduces "vein"; the catch-up handover branches on it) |

Max odds: `stepIn` 60% with the cousin modifier, `grabBag` 30%. No failure blocks: every path reaches card 7 and the pub.

```json
{
  "id": "intro",
  "at": { "block": "evening", "advance": true },
  "cards": [
    {
      "type": "narration",
      "label": "{today} — Whitechapel",
      "speaker": null,
      "text": "Rent's due Monday. You have £40, and this morning's interviewer has promised to keep your details on file. Archie, an old mate, said he might have work. So: Tuesday night, behind a chicken shop on Mile End Road.",
      "image": "res://assets/events/intro/intro_card1.png"
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "He's whistling, a Tesco bag hooked on one finger. \"Two blokes, cash, in and out before the chicken shop shuts. You just stand there looking like you'd be a pain to fight. If I say leg it, you leg it. Don't wait for me.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "\"I don't look like I'd be a pain to fight.\""
    },
    {
      "type": "choice",
      "label": null,
      "speaker": "Archie",
      "text": "\"Pretend, then. Vinnie Jones in his prime.\" He looks you up and down. \"Bit more of a Mr Bean vibe, but you make do with what you've got.\" He holds out a fist. \"You in?\"",
      "image": "res://assets/events/intro/intro_card5.png",
      "choices": [
        {
          "id": "stand",
          "label": "\"I'll stand there.\"",
          "effects": [],
          "result_text": "You bump the fist. \"Lovely,\" says Archie, and goes back to whistling."
        },
        {
          "id": "askBuyers",
          "label": "\"Who are the buyers?\"",
          "effects": [
            { "op": "set_flag", "flag": "introAskedQuestions", "value": true }
          ],
          "result_text": "Archie lowers the fist. \"Two lads from Romford. Bought off me twice. Pay cash, don't chat.\" He thinks about it. \"One of them's got a cousin. Never met the cousin.\""
        },
        {
          "id": "wantHalf",
          "label": "\"I want half.\"",
          "effects": [
            { "op": "relation", "contact": "archie", "value": -3 },
            { "op": "set_flag", "flag": "introWantsHalf", "value": true }
          ],
          "result_text": "\"You were getting half.\" Archie looks at you for a long second, fist still out. \"Sixty-forty, then. Your way. Don't make a habit of it.\""
        }
      ]
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "The buyers arrive in a grey Vauxhall. Three of them. That's one more than Archie mentioned. He stops whistling.",
      "image": "res://assets/events/intro/intro_card6.png"
    },
    {
      "type": "tension",
      "label": "It goes wrong",
      "speaker": null,
      "text": "The nearest one opens a Stanley knife and comes at you, not Archie. Archie shifts his weight, and is suddenly standing in the gap between you. The third man stays at the mouth of the alley, which is somehow worse.",
      "image": "res://assets/events/intro/intro_card7.png"
    },
    {
      "type": "choice",
      "label": null,
      "speaker": null,
      "text": "The blade is a foot from Archie's chest. The second man has a hand on the Tesco bag.",
      "choices": [
        {
          "id": "freeze",
          "label": "Freeze",
          "effects": [
            { "op": "relation", "contact": "archie", "value": 5 }
          ],
          "result_text": "You don't move. Archie doesn't either, and he's wider than you. He stays exactly in the gap."
        },
        {
          "id": "stepIn",
          "label": "Step in front of Archie",
          "check": {
            "base": 0.45,
            "mods": [
              { "flag": "introAskedQuestions", "add": 0.15, "label": "You knew about the cousin" }
            ],
            "min": 0.15,
            "show": "odds"
          },
          "success": {
            "result_text": "You step past Archie's shoulder, into the knife's way. The man checks, just for a second, as if this wasn't the plan for him either. A second is enough for Archie.",
            "effects": [
              { "op": "set_flag", "flag": "introBrave", "value": true },
              { "op": "relation", "contact": "archie", "value": 10 }
            ]
          },
          "fail": {
            "result_text": "You step past Archie's shoulder, into the knife's way. The blade opens your forearm before you feel it. Archie hauls you back behind him by the collar.",
            "effects": [
              { "op": "add", "path": "player.hp", "value": -10 },
              { "op": "set_flag", "flag": "introInjured", "value": true }
            ]
          }
        },
        {
          "id": "grabBag",
          "label": "Go for the bag",
          "check": {
            "base": 0.30,
            "mods": [],
            "min": 0.15,
            "show": "odds"
          },
          "success": {
            "result_text": "You grab the bag and yank. The handle tears; Archie catches the rest, and two small chips of calc land in your palm. You close your fist on them.",
            "effects": [
              { "op": "add_ore", "type": "time", "qty": 2 },
              { "op": "set_flag", "flag": "introGrabbedCalc", "value": true }
            ]
          },
          "fail": {
            "result_text": "You grab for the bag. The second man puts a hand flat on your chest and shoves, and you sit down hard on the tarmac. Archie steps over your legs and stays in the gap.",
            "effects": [
              { "op": "relation", "contact": "archie", "value": 5 }
            ]
          }
        }
      ]
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Alright, lads. No need for all that.\" He lifts the bag high, and every eye follows it. \"It's all here. Have a look.\""
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "His other hand flicks out of his back pocket. Something small hits the tarmac between the men and breaks. They slow. Not stopped — slow, like a video buffering. The knife is still coming. It will take a while."
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Coming, or what?\""
    },
    {
      "type": "choice",
      "label": "Fifteen minutes later — a Wetherspoons",
      "speaker": null,
      "text": "Archie buys two pints and chips, puts the chips on your side of the table, and sits facing the door. His eyes are streaming. You have about four questions. He looks good for one.",
      "image": "res://assets/events/intro/3.png",
      "choices": [
        {
          "id": "whatIsIt",
          "label": "\"What was that stuff?\"",
          "effects": [],
          "result_text": "\"Calc. Orichalchum, if you're being posh about it. That one was time-type. Slows everything round it for a few seconds.\" He dabs his eyes with a napkin. \"Last one I had, and all. Allergic to the stuff, before you ask. Don't.\""
        },
        {
          "id": "howMuch",
          "label": "\"How much is it worth?\"",
          "effects": [],
          "result_text": "\"The calc? Depends who's buying. Bit of time-type like that, seventy-odd quid a chip.\" He dabs his eyes with a napkin. \"Ten chips, you're looking at seven hundred and fifty. Which is why that lot brought a knife.\""
        },
        {
          "id": "whereFrom",
          "label": "\"Where does it come from?\"",
          "effects": [
            { "op": "set_flag", "flag": "introAskedSource", "value": true }
          ],
          "result_text": "\"Calc grows. Don't laugh.\" He dabs his eyes with a napkin. \"There's a crack in a wall in Whitechapel that grows the stuff, if you're patient. Vein, they call it. Most of them, someone's already sitting on.\""
        }
      ]
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"It's stock, innit. Someone finds it, someone makes it useful, someone pays through the nose for it. People like us stand in the middle and take a cut.\" He nods at the chips. \"Eat. You're no use to me keeling over.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Normally nobody gets a knife out. Still got tonight's calc, ain't I. I'll find a proper buyer. Somewhere with lights. And witnesses. You come along, you get a cut. You've seen how it goes wrong, so no hard feelings if it's a no.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "You look at the door, at the chips, then think about your bank balance. \"I'll come.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Lovely. I'll text you.\" He's out the door before you can thank him, for the chips or the knife."
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "Rent's still due Monday. But somewhere on Mile End Road, in a Tesco bag, is the calc that might pay it.",
      "image": "res://assets/events/intro/4.png"
    }
  ],
  "on_complete": [
    { "op": "set_flag", "flag": "metArchie", "value": true },
    { "op": "set_stage", "value": "buyer_event" },
    { "op": "set_screen", "screen": "phone" }
  ]
}
```

## What changed vs. current `intro.json`

- `id`, `at` and `on_complete` are unchanged.
- **Images.** The composited art is preserved. Convention art maps card *index* to `intro_card<N>`, and the cards before the knife shift by one, so this proposal pins the shifted ones with explicit `image` keys: card 3 → `intro_card5` (Mr Bean), card 4 → `intro_card6` (Vauxhall), card 5 → `intro_card7` (knife). Card 0's `intro_card1` is explicit for safety. Cards 6–8 pick up `intro_card7/8/9` by convention, as intended: card 6 is the knife choice (shares the knife art), card 7 is "Alright, lads", card 8 is the slowdown. `3.png` moves from the old resolution card onto the pub choice card. `4.png` is unchanged. Alternative at apply time: rename the asset files to the new indices instead of using explicit keys.
- **Card types.** The pitch and pub beats become `choice` cards. The pitch has `speaker: "Archie"` (the event screen renders a choice card's speaker). The pub card loses `resolution` styling for `choice` styling.
- **Cut cards.** "Imagine you're Vinnie Jones" (merged into the pitch). "What was that?" ("You"). Archie's calc explainer (now the `whatIsIt` answer).
- **New flags** (camelCase, matching `metArchie`): `introAskedQuestions`, `introWantsHalf`, `introBrave`, `introInjured`, `introGrabbedCalc`, `introAskedSource`. Choice memory also records every pick (ids above), so later events can use either.
- **Rent day.** Friday → Monday, in two places.

## Cards needing new art (→ event-storyboard)

None are needed to ship: every new card falls back to the art before it. Candidate plates, in priority order:

1. `stepIn` fail: the cut forearm, Archie hauling you back (resolution-card `image`).
2. `grabBag` success: the torn handle, two chips in your palm.
3. `stepIn` success: you in the gap, the knife man checking.
4. `grabBag` fail: sat on the tarmac, Archie stepping over.
5. `whereFrom` answer (optional): an insert of the Whitechapel crack/vein.

## Open points for review

- **Knife target.** The tension card is unchanged (the knife comes at you, Archie steps into the gap). So the choice is framed *after* Archie covers you: "Step in front of Archie" means taking the knife back off him. The alternative, rewriting the tension card so the knife goes for Archie and the bag, would lose proposal 2's unprompted act of care.
- **`grabBag` fail = Freeze effects.** I read "as Freeze" as the same Archie +5. Drop it if a failed grab shouldn't earn relation.
- **Injury size.** −10 of 40 HP. The `add` op doesn't clamp, which is fine at 40, but the home raid comes later at 30 if the HP hasn't regenerated.
- **Mod label.** "You knew about the cousin" is only true if the `askBuyers` answer mentions the cousin, which it does. A generic alternative is "You asked about the buyers".
- **"You have about four questions. He looks good for one."** This is a new line explaining why you get only one question. It may read as a third joke; if it does, cut it to just the setup sentence.
- **"Calc grows. Don't laugh."** "Grows" is the canon verb for veins (no gardening words). Check that "Vein, they call it" doesn't collide with a fuller vein introduction in `archie_cultivation`.
- **`howMuch` figures.** "Seventy-odd quid a chip" and "seven hundred and fifty" are pinned to `ore_types.json` time `basePrice` 75. The buyer still pays £80 for the bag, which reads as roughly one chip.
