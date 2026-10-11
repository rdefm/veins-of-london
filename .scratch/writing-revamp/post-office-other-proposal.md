# Post Office: Parcel Size — random event proposal

The player is posting their own ordinary packet. The obstacle is a real size gauge and a cost choice; nobody else hands the player a mystery parcel. No calc is shown or discussed.

**Card count:** 4 definition cards; two choice points; repeatable under the deck's normal no-repeat window.

Goals:
1. **Hook:** A taped corner catches in the letter gauge.
2. **Agency:** Read the gauge, then repack, pay the higher rate, or take the packet back.
3. **Stakes:** A small postage surcharge; no invented buyer or quest lead.

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 1 | `readGauge` | Read the gauge | Improves the repack roll. |
| 1 | `askClerk` | Ask the clerk | Explains the rate; no bonus. |
| 2 | `repack` | Repack it | Crafting roll; success posts at the lower rate, failure pays £5 higher rate. |
| 2 | `payRate` | Pay £5 extra | Guaranteed higher rate. |
| 2 | `takeBack` | Take it back | No charge or roll. |

```json
{
  "id": "post_office_other",
  "deck": {
    "district": "any",
    "weight": 1,
    "excludeIfFlag": null,
    "barometerState": null
  },
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "At the counter",
      "cards": [
        {
          "key": "arrival",
          "type": "narration",
          "label": "Post Office",
          "speaker": null,
          "text": "You queue to post a small packet. The clerk tries it in the letter gauge. One corner catches on the tape, so she quotes the higher parcel rate."
        },
        {
          "key": "preparation",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "She hands it back. You can step aside and check the gauge or ask her exactly where it caught.",
          "choices": [
            {
              "id": "readGauge",
              "label": "Read the gauge",
              "effects": [],
              "result_text": "The packet fits except at one folded edge. You could retape it without opening the contents."
            },
            {
              "id": "askClerk",
              "label": "Ask the clerk",
              "effects": [],
              "result_text": "She points to the corner. The next person in the queue moves forward by half a step."
            }
          ]
        },
        {
          "key": "postage",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The clerk offers you the end of the counter. If you try again and it still catches, you agree to pay the higher rate.",
          "choices": [
            {
              "id": "repack",
              "label": "Repack it",
              "check": {
                "base": 0.5,
                "show": "odds",
                "mods": [
                  {
                    "path": "player.craftingSkill",
                    "perPoint": 0.05,
                    "above": 1,
                    "label": "Crafting skill"
                  },
                  {
                    "choice": {
                      "event": "post_office_other",
                      "card": 1,
                      "option": "readGauge"
                    },
                    "add": 0.1,
                    "label": "Checked the gauge"
                  }
                ]
              },
              "success": {
                "result_text": "You fold the loose tape flat. The packet passes through the gauge. The clerk prints the lower-rate label and calls the next customer.",
                "effects": []
              },
              "fail": {
                "result_text": "The corner still catches. You pay the extra postage you agreed to, and the clerk takes the packet.",
                "effects": [
                  {
                    "op": "add",
                    "path": "player.cash",
                    "value": -5
                  }
                ]
              },
              "requires": {
                "cash": {
                  "atLeast": 5
                },
                "display": "disable",
                "reason": "Needs £5 for the higher rate"
              }
            },
            {
              "id": "payRate",
              "label": "Pay £5 extra",
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": -5
                }
              ],
              "result_text": "You pay the higher rate. The clerk takes the packet without further argument.",
              "requires": {
                "cash": {
                  "atLeast": 5
                },
                "display": "disable",
                "reason": "Needs £5 for the higher rate"
              }
            },
            {
              "id": "takeBack",
              "label": "Take it back",
              "effects": [],
              "result_text": "You keep the packet and leave the queue. The tape can wait."
            }
          ]
        },
        {
          "key": "exit",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Outside, you peel a strip of tape from your thumb."
        }
      ]
    }
  }
}
```

## Open points for review

- £5 and check odds are draft balance values. Base postage happens offscreen; only the avoidable surcharge is modelled.
- No item modifier: spending calc on a routine postage problem would distort the scene. Rewind remains available through the event runner.

