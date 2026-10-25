# James's Dial — the repair (proposal)

New event proposed for `data/events/james_dial_repair.json`. It sits between `james_dial_evaluation-proposal.md` (James quotes `{calcQty}` time calc, two attempts' worth) and `james_dial_offer-proposal.md` (James shows the working Dial and unlocks seeding). The player crafts a time-attuned Recharge Movement for James's Dial. The first attempt fails; the second takes. Written against `docs/writing-guide.md`.

**Entry gate (proposed):** `jamesDialRepairRequested`, and the player holds at least the quoted `{calcQty}` time calc. Player-initiated (from James's thread or the map), not a summons.

**Context values:** `{calcQty}` and `{attemptCost}` are the figures quoted and stored at the evaluation. `{calcPay}` is James's payment for the calc. Proposed value: `ceil(calcQty × time basePrice / 10)`, £285 at the 38-unit quote.

## §1 goals

1. **Hook:** the player has carried {calcQty} calc across London in a lunchbox. James weighs it twice before saying hello.
2. **Focus:** James pays for the calc up front and in cash. The failed attempt burns a visible {attemptCost}. There is no third allowance.
3. **Brief:** 13 cards and two choices. The repair is one craft, once failed and once landed.
4. **Jokes:** (a) the laugh, then James checking the door in case anyone heard. (b) "And if I did, it was at the Guild." Neither touches the failure card.
5. **James as a person:**
   - Tell: weighing things twice, and the collar clicks.
   - Unspoken care: he cleaned the empty seat before the player arrived, and walks them to the shutter.
   - Want: his Dial back.
   - Exit: two collar clicks heard through the closed shutter.
6. **Memorable moment:** James laughs, and is visibly appalled at himself.

**The emotion beat (card 9):** a single, short, startled laugh. It's small and involuntary, and he immediately checks the door. It works because the player has never heard him laugh. The rest of the scene stays dry around it: "Adequate" and "Don't make me say it again". The optional "Ask James to hold the Dial" route adds hands that aren't quite steady, as a softer early hint.

```json
{
  "id": "james_dial_repair",
  "fillFromContext": true,
  "on_complete": [
    {
      "op": "spend_quoted_calc",
      "quote": "jamesDialRepair"
    },
    {
      "op": "add",
      "path": "player.cash",
      "value": "{calcPay}"
    },
    {
      "op": "recruit_contact",
      "contact": "james"
    },
    {
      "op": "set_flag",
      "flag": "jamesDialRestored",
      "value": true
    },
    {
      "op": "lose_time_block"
    },
    {
      "op": "set_screen",
      "screen": "phone"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": "Bermondsey — James's unit",
          "speaker": null,
          "text": "You've carried {calcQty} time calc across London in a lunchbox. James weighs it on the scales before he says hello. Then he weighs it again.",
          "key": "c1",
          "image": "res://assets/events/james_dial_repair/james_dial_repair_main_1.png"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Correct.\" He counts £{calcPay} into an envelope and slides it across. \"For the calc. We'll discuss the labour when there is some.\"",
          "key": "c2"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "The Dial lies on a cloth beside the tin. The broken Movement is gone. Its seat has been cleaned until it shines, recently and with care.",
          "key": "c3"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Recharge Movement, time-attuned. It can't hold much of a charge, but recharges quickly. When it works, that is.\"\n",
          "key": "c4"
        },
        {
          "key": "c14",
          "type": "narration",
          "text": "\"You look, you can touch, but be very, very careful. I'll tell you if you're about to do something stupid, and not before.\" He folds his arms and sits on the stool."
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You work the calc the way you would a pearl, only slower. A spring takes shape under your fingers. You seat it in the Dial and give the collar a turn.",
          "key": "c5"
        },
        {
          "type": "tension",
          "label": "It goes wrong",
          "speaker": null,
          "text": "Nothing. Then a dry crack. The spring loses its shape and the calc in it goes grey and dead, like cigarette ash. The Dial stays cold. That was {attemptCost} calc.",
          "key": "c6"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "He lifts the dead Movement out with tweezers and studies it. \"Too fast at the end. You were thinking about the result.\" He sets it aside. \"Try again.\"",
          "key": "c7"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The second allowance sits on the scales. If this one goes the same way, there is no third.",
          "choices": [
            {
              "id": "goSlower",
              "label": "Go slower",
              "effects": [],
              "result_text": "You take the spring a turn at a time. James doesn't speak. Halfway through, you notice he has stopped tapping his foot."
            },
            {
              "id": "askWhatWrong",
              "label": "Ask what you did wrong",
              "effects": [],
              "result_text": "\"You finished it before it was finished.\" He taps the bench. \"Again. Listen to it this time.\""
            },
            {
              "id": "askJamesHold",
              "label": "Ask James to hold the Dial",
              "effects": [],
              "result_text": "He picks it up without comment and holds it out in both hands. For possibly the first time ever, they aren't quite steady. You don't mention it."
            }
          ],
          "key": "c8"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "The spring holds. You seat the Movement and turn the collar. A tick. Another. The power reserve's needle slowly lifts off zero and keeps going.",
          "key": "c9"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "James laughs. Once, short, surprised. Then he glances at the door, in case anyone heard.",
          "key": "c10"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "He clears his throat and fits the Dial back onto the umbrella handle, taking longer than it needs. \"Adequate.\" A pause. \"Better than adequate. Don't make me say it again.\"",
          "key": "c11"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The collar ticks between you. James hasn't let go of the umbrella.",
          "choices": [
            {
              "id": "sayNothing",
              "label": "Say nothing",
              "effects": [],
              "result_text": "You say nothing. James appears grateful, as far as he is able."
            },
            {
              "id": "mentionLaugh",
              "label": "Point out that he laughed",
              "effects": [],
              "result_text": "\"I did not.\" He doesn't look up from the collar. \"It was a cough.\""
            },
            {
              "id": "askHowFeels",
              "label": "Ask how it feels",
              "effects": [],
              "result_text": "He turns the collar one click and listens. \"Familiar,\" he says, and leaves it there."
            }
          ],
          "key": "c12"
        },
        {
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "He walks you to the door, which he has never done. \"There's something else. I'll text you. And do turn up on time.\" The door closes down. Behind it, you hear the collar click twice.",
          "key": "c13",
          "image": "res://assets/events/james_dial_repair/james_dial_repair_main_14.png"
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "fillFromContext",
      "on_complete",
      "cards"
    ],
    "cards": {
      "c1": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c2": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c3": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c4": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c5": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c6": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c7": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c8": [
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c9": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c10": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c11": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c12": [
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c13": [
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  }
}
```

**Unchanged/changed:** new event; no live `data/events/*.json` touched. No art. Flat `cards`, forward-only flow; both choices are flavour (`result_text` only) and fall through.

## Open points for review

- **New ops:**
  - `spend_quoted_calc` doesn't exist. It would remove the quoted `{calcQty}` time calc.
  - `"value": "{calcPay}"` assumes `fillFromContext` reaches effects. Today it may only fill card text.
  - Either add both, or have the screen-side launcher pass resolved numbers.
- **Leftover calc:** the failure is scripted, so both allowances are always spent. If crafting skill has risen since the quote, `{attemptCost}` is smaller now, so either (a) spend only 2 × the current cost and leave the rest with the player (evaluation open point), or (b) spend the full quote.
- **Forced rolls:** attempt 1 always fails and attempt 2 always succeeds; this event doesn't call `Dial.attempt_craft_movement()`. Fits the "first roll forced" rule in spirit, here in the fail-then-succeed direction.
- **Recruitment:** `recruit_contact james` moves here from `biz_a1_partnership` (evaluation note: full recruitment waits for the repair). That event's recruit effect must then be gated or removed. On recruit, `grantDial` gives James his Dial.
- **Haft mismatch:** `data/constants.json` `grantDial` uses `firm_baton` (Service Baton). All three drafts use an umbrella, and `collective_brolly` (Market Umbrella) exists. Prose or data needs to change. The evaluation's c8 also says "baton".
- **Movement tier:** `grantDial`'s Movement is fixed at `tier: 1`. Since the player made it, its tier arguably should be the player's crafting skill at the time.
- **Simile:** "like cigarette ash" (card 5) is the scene's one simile.
- **Payment:** `{calcPay}` at base price is a proposal. A flat £300 matches his jobs, but would overpay at higher skill (lower quote).
- **Handoff:** the resolution's "I'll text you a time" leads into the offer's opening "Eight. Not ten past." The offer's card 1 ("your Movement ticks") matches.
