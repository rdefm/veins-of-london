# James's Dial — evaluation proposal

New event proposed for `data/events/james_dial_evaluation.json`. This is a paid bench job, not the repair. James has already seen the TIME jar answer the player; now he needs evidence that the player can make his still-living Dial's broken Movement answer too. He ends certain the player could craft a replacement, but spends no repair calc and does not recruit or teach the player to seed a Dial here. The teacher made James's Dial when James was young; his fate stays unstated.

**Entry gate:** `jamesMotionEventSeen`, player crafting skill ≥ 2, and `archiePartnerSeen` (Archie's time vein transferred). No completed James job requirement. James sends a guaranteed paid-work summons once these are true. Existing completed work may colour a line, but cannot delay the invitation.

**Calc request:** a time-attuned Recharge Movement costs `Dial.movement_calc_cost("recharge", player.craftingSkill)` per attempt. James asks for twice that figure, quoted and stored when this event starts: `{attemptCost}` and `{calcQty}`. At crafting level 2, that is 19 per attempt and **38 time calc** to bring back. The second allowance lets the follow-up script one failed attempt without asking the player to go away again. No calc is taken in this event.

**Card count:** 16 definition cards across six branches; a player sees 14 of them, plus one choice-result card. No art is assigned. The present event runner uses flat `cards` and forward numeric `goto`; the branch form below follows `archie-craft-chat-proposal.md` and must be flattened when promoted.

## Beats → options

| Beat | Option id | What changes |
|---|---|---|
| Ask before the test | `askMaker` | James says his teacher made the Dial for him when he was young. No explicit account of what happened to the teacher. |
| | `askRisk` | James confirms the Dial is intact, its Movement broken, and the uncharged instrument is safe to handle. |
| | `followDirections` | The player gets only the handling instructions. James keeps the personal history to himself. |
| Respond to the Movement | `holdSteady` | The player lets it turn one tooth; James stops the test. |
| | `drawBack` | The player refuses to force a reaction; James approves the restraint. |
| | `askControl` | James repeats the test with his own hand. Nothing happens; the player sees the difference without a lecture. |

Every route proves the same capacity and reaches the same request. The test cannot fail, does not repair anything, and consumes none of the requested calc. Today's job takes one time block and pays £300, matching James's existing flat-pay job; he undertakes to pay for the calc the player sources for the later repair. The price and transfer belong to that follow-up event.

```json
{
  "id": "james_dial_evaluation",
  "fillFromContext": true,
  "on_complete": [
    {
      "op": "lose_time_block"
    },
    {
      "op": "add",
      "path": "player.cash",
      "value": 300
    },
    {
      "op": "set_flag",
      "flag": "jamesDialRepairRequested",
      "value": true
    },
    {
      "op": "set_screen",
      "screen": "phone"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Paid work",
      "cards": [
        {
          "type": "narration",
          "label": "Bermondsey — James's unit",
          "speaker": null,
          "text": "James has cleared a square of bench and set an envelope beside it. There are three trays of pearls. The tray marked REJECTS is nearly empty, which strikes you as optimistic.",
          "key": "c1"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Made by my assistant. I haven't had a chance to review them. Grade them and confirm they're in the right trays. Three hundred pounds for the afternoon. Gloves.\"",
          "key": "c2"
        },
        {
          "type": "narration",
          "label": "Later",
          "speaker": null,
          "text": "One pearl looks sound until you turn it under the lamp. A hairline crack reaches the calc. You put it with the rejects. James checks it, then raises an eyebrow slightly. You almost thought you saw a hint of an approving smile at the corner of James's lips. Almost. ",
          "key": "c3"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "James takes his umbrella and looks at the handle. A brass collar turns around its handle with a neat series of clicks. There is a dial at the end of the handle, but it doesn't seem to be a clock. James places it on the table beside a tin containing a watch-sized mechanism.",
          "key": "c4"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"There is another job. This stays between us - understood?\" Something about his look makes you nod reflexively. \"Good.\"",
          "key": "c5"
        },
        {
          "key": "c17",
          "type": "speaker",
          "text": "This is known as a Dial. Few know about them, and even fewer have them. They are incredibly rare, keyed to an individual, and enhance the effect of orichalchum items.",
          "speaker": "James"
        },
        {
          "key": "c18",
          "type": "narration",
          "text": "They also recharge, providing stronger and, to a point, renewable orichalchum effects. Unfortunately, this one is broken, and crafting expertise alone can't fix it."
        },
        {
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "\"Look first. Touch it when I tell you.\" He opens a jar of time calc and measures a pinch onto a glass slide. James keeps the tin between you. He is watching your hands, not the work you have just finished.",
          "choices": [
            {
              "id": "askMaker",
              "label": "Ask whose it is",
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "maker"
              }
            },
            {
              "id": "askRisk",
              "label": "Ask if it's safe",
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "risk"
              }
            },
            {
              "id": "followDirections",
              "label": "Wait for instructions",
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "directions"
              }
            }
          ],
          "key": "c6"
        }
      ]
    },
    "maker": {
      "title": "Its maker",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Mine. My teacher made the Dial for me when I was young. The collar still works. The Movement doesn't.\" He closes the tin before you can get a better look at the damage. \"That answers the relevant part of your question.\"",
          "key": "c7"
        }
      ],
      "then": {
        "branch": "test"
      }
    },
    "risk": {
      "title": "The risk",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"The Dial is sound. Its Movement is broken, so it holds no charge. I wouldn't let you put a hand over it otherwise.\" He moves the slide clear of the baton. \"A sensible question. Don't make a habit of surprising me.\"",
          "key": "c8"
        }
      ],
      "then": {
        "branch": "test"
      }
    },
    "directions": {
      "title": "The instructions",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Good. Hold your hand above the slide. No pressure, and don't touch the metal.\" He puts the crooked mechanism beside the calc and folds his arms.",
          "key": "c9"
        }
      ],
      "then": {
        "branch": "test"
      }
    },
    "test": {
      "title": "The test",
      "cards": [
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You hold a hand above the slide. The calc gathers under your fingers and you apply it to the Dial. The crooked wheel gives a dry click and turns a fraction. It stops before it can turn again. James has not looked away.",
          "key": "c10"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The wheel is still. You feel resistance if you try to move it further. James has not told you to stop.",
          "choices": [
            {
              "id": "forceIt",
              "label": "Keep forcing it",
              "effects": [],
              "result_text": "You press further. The wheel moves one more tooth, then catches. James slides the tin away. \"Enough.\"",
              "goto": {
                "branch": "conclusion"
              }
            },
            {
              "id": "drawBack",
              "label": "Draw back",
              "effects": [],
              "result_text": "You take your hand away. The calc settles at once. \"Quite right,\" James says. \"Force is how that wheel got bent.\"",
              "goto": {
                "branch": "conclusion"
              }
            },
            {
              "id": "askControl",
              "label": "Ask James to try",
              "effects": [],
              "result_text": "James puts his hand where yours was. The calc stays flat; the wheel doesn't move. ",
              "goto": {
                "branch": "conclusion"
              }
            }
          ],
          "key": "c11"
        }
      ]
    },
    "conclusion": {
      "title": "James's answer",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Crafting or fixing a Dial requires both skill and a natural gift. You demonstrated the gift when I first saw you and the calc moved. You've since proven you could develop the skill\"",
          "key": "c12"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"A time-attuned Recharge Movement. At your present skill, one attempt takes {attemptCost} units of time calc. Bring {calcQty}. I am allowing for a failure, not expecting one.\"",
          "key": "c13"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"It's your Dial. Am I paying for the calc?\"",
          "key": "c14"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"No. You find it; I pay for it when you bring it. The bench is mine as well. Come back when you have the full amount.\"",
          "key": "c15"
        },
        {
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "James counts out the promised pay and puts the Dial back in its drawer. The repair can wait for the calc. The figure is already on your phone by the time you reach the street.",
          "key": "c16"
        }
      ]
    }
  }
}
```

## What this changes

- **New event:** no live `data/events/*.json` is changed. The early evaluation pays off the jar in `james_meeting` and follows the paid assistant arrangement in `james_motion`.
- **Information branches:** the maker, the immediate risk, or neither is explained at the player's request. The test and request are common to every route; no choice pretends the player can fail the gift check.
- **Recruitment:** this event does not recruit James or activate his Dial. Per the owner's decision, full recruitment waits for the later repair event; the current `biz_a1_partnership` recruitment effect must be gated when these drafts are implemented.
- **Player's own Dial:** not offered here. The player can ask James about one after restoring his Movement, with seeding left to a later desperate beat or questline.

## Open points for review

- **Gift flag timing:** the evaluation proves the gift in fiction, but `dialGiftGranted` currently unlocks player seeding immediately. This draft sets only `jamesDialRepairRequested`; a later implementation must separate recognition/repair access from the player's own seeding unlock. The current `Dial.attempt_craft_movement()` also lacks the newly confirmed gift gate.
- **Time:** the event must be offered only while a block remains; `lose_time_block` then makes its £300 payment match James's ordinary flat-pay work.
- **Quote and follow-up objective:** pass `{attemptCost}` and `{calcQty}` in event context and save the quoted `calcQty` for the follow-up. If crafting skill rises after this scene, honour James's quoted amount and let any unspent calc stay with the player.
- **James's payment for repair calc:** the scene commits him to paying, but the valuation and timing of the transfer need specification with the follow-up event.
- **Art:** new event, no images yet. The baton/collar/tin are the continuity objects for the follow-up.
