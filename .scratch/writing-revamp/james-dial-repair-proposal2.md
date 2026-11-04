# james_dial_repair — imported from data/events/james_dial_repair.json

```json
{
  "id": "james_dial_repair",
  "fillFromContext": true,
  "on_complete": [
    {
      "op": "sell_ore_at_market",
      "type": "time",
      "qtyContextKey": "calcQty",
      "label": "James — Dial repair calc"
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
          "image": "res://assets/events/james_dial_repair/james_dial_repair_main_1.png",
          "observe": "james_dial_repair1"
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
          "text": "\"It's a time-attuned Recharge Movement. It can't hold much of a charge, but recharges quickly. When it works, that is.\"\n",
          "key": "c4"
        },
        {
          "key": "c14",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "\"You look, you can touch, but be very, very careful. I'll tell you if you're about to do something stupid, and not before.\" He folds his arms and sits on the stool.",
          "observe": "james_dial_repair2"
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
          "key": "c6",
          "observe": "james_dial_repair3"
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
          "text": "The second allowance of calc sits on the scales. If this one goes the same way, there is no third.",
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
              "result_text": "He turns the collar one click and listens. \"Familiar,\" he says. \"Comfortable.\""
            }
          ],
          "key": "c12"
        },
        {
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "He walks you to the door, which he has never done. \"There's something else. I'll text you. And do turn up on time, please.\" The door closes down. Behind it, you hear the collar click twice.",
          "key": "c13",
          "image": "res://assets/events/james_dial_repair/james_dial_repair_main_14.png",
          "observe": "james_dial_repair_end"
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
        "text",
        "key",
        "image"
      ],
      "c2": [
        "type",
        "label",
        "speaker",
        "text",
        "key"
      ],
      "c3": [
        "type",
        "label",
        "speaker",
        "text",
        "key"
      ],
      "c4": [
        "type",
        "label",
        "speaker",
        "text",
        "key"
      ],
      "c14": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c5": [
        "type",
        "label",
        "speaker",
        "text",
        "key"
      ],
      "c6": [
        "type",
        "label",
        "speaker",
        "text",
        "key"
      ],
      "c7": [
        "type",
        "label",
        "speaker",
        "text",
        "key"
      ],
      "c8": [
        "type",
        "label",
        "speaker",
        "text",
        "choices",
        "key"
      ],
      "c9": [
        "type",
        "label",
        "speaker",
        "text",
        "key"
      ],
      "c10": [
        "type",
        "label",
        "speaker",
        "text",
        "key"
      ],
      "c11": [
        "type",
        "label",
        "speaker",
        "text",
        "key"
      ],
      "c12": [
        "type",
        "label",
        "speaker",
        "text",
        "choices",
        "key"
      ],
      "c13": [
        "type",
        "label",
        "speaker",
        "text",
        "key",
        "image"
      ]
    }
  },
  "_liveSource": "james_dial_repair.json",
  "_liveHash": "834f6304",
  "observations": {
    "james_dial_repair1": {
      "blocks": {
        "physics": {
          "tiers": [
            {
              "base": 0.25,
              "text": "His hands tremble ever so slightly. He's not berated you as you usually does. James is nervous - this must be very important to him."
            },
            {
              "base": 0.55,
              "text": "His hands are trembling ever so slightly. You've never seen James's handles tremble before."
            }
          ],
          "miss": "James seems... different somehow. You're not sure if he's annoyed, nervous, or excited."
        },
        "emotion": {
          "tiers": [
            {
              "base": 0.25,
              "text": "James is usually confident, considered, and calmly decisive. Right now, there's a nervous energy about his movements."
            },
            {
              "base": 0.55,
              "text": "Something about his movements is very unlike James. His foot keeps tapping nervously at the floor when his hands aren't doing something."
            }
          ],
          "miss": "James is tapping some tune with his foot. You think it might be Flight of the Bumblebee. That, or Seven Nation Army."
        }
      }
    },
    "james_dial_repair2": {
      "blocks": {
        "life": {
          "tiers": [
            {
              "base": 0.25,
              "text": "You notice he's started a breathing technique to calm down. His foot continually tapping away suggests it's not working."
            },
            {
              "base": 0.55,
              "text": "He folded his arms to stop himself fidgeting. And to not show that his hands are shaking with anticipation."
            }
          ],
          "miss": "He doesn't look very comfortable on the stool."
        }
      }
    },
    "james_dial_repair3": {
      "blocks": {
        "emotion": {
          "tiers": [
            {
              "base": 0.25,
              "text": "You feel the anticipation and nervousness that had been building in the James slowly deflate, replaced by disappointment and annoyance that he let himself hope."
            },
            {
              "base": 0.55,
              "text": "James breathes out loudly, like he's trying to expel the nervousness and disappointment. His expression doesn't change, though."
            }
          ],
          "miss": "James breathes out slowly from his mouth. You consider offering him a mint."
        }
      }
    },
    "james_dial_repair_end": {
      "blocks": {
        "physics": {
          "tiers": [
            {
              "base": 0.25,
              "text": "James's footsteps as he walks away from the door sound lighter then usual, and not as rhythmic. Almost like he's dancing back to his workshop."
            },
            {
              "base": 0.55,
              "text": "James didn't push the door shut with as much force as he usually does. "
            }
          ],
          "miss": "Something small and wet hits you in the face. Was that rain? You hope so."
        }
      }
    }
  }
}
```
