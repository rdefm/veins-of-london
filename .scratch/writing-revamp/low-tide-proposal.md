# Low Tide — random event proposal

The player notices a rare exposed calc fragment while travelling beside a river wall. Nobody points it out or publicly identifies it. Retrieval is risky because the tide is turning.

**Card count:** 4 definition cards; two choice points; repeatable under the deck's normal no-repeat window.

Goals:
1. **Hook:** Low tide exposes a fragment where the player can reach it.
2. **Agency:** Read the tide marks or inspect the steps, then retrieve or leave.
3. **Stakes:** One small private find against a real slip risk.

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 1 | `readMarks` | Read the tide marks | Improves the retrieval roll. |
| 1 | `checkSteps` | Check the steps | Shows the route, no tide bonus. |
| 2 | `takeChip` | Take the chip | Cultivating roll; success one physics ore, failure minor injury. |
| 2 | `leaveChip` | Leave it | No roll or injury. |

```json
{
  "id": "low_tide",
  "deck": {
    "district": "battersea",
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
      "title": "The river wall",
      "cards": [
        {
          "key": "arrival",
          "type": "narration",
          "label": "Battersea",
          "speaker": null,
          "text": "The tide has dropped below the Battersea river wall. From the path, you spot a loose, dark fragment in an exposed joint. Nobody else on the path gives it a second look."
        },
        {
          "key": "preparation",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The last few steps are wet. You can watch how fast the water is returning or test the handrail and footing.",
          "choices": [
            {
              "id": "readMarks",
              "label": "Read the tide marks",
              "effects": [],
              "result_text": "Water reaches the lower stain while you watch. You have time for one careful attempt, not a search."
            },
            {
              "id": "checkSteps",
              "label": "Check the steps",
              "effects": [],
              "result_text": "The handrail is sound. The final step is slick with river mud."
            }
          ]
        },
        {
          "key": "retrieval",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The fragment is close enough to reach. You can take the steps down or carry on along the path.",
          "choices": [
            {
              "id": "takeChip",
              "label": "Take the chip",
              "check": {
                "base": 0.4,
                "show": "odds",
                "mods": [
                  {
                    "path": "player.cultivatingSkill",
                    "perPoint": 0.05,
                    "above": 1,
                    "label": "Cultivating skill"
                  },
                  {
                    "choice": {
                      "event": "low_tide",
                      "card": 1,
                      "option": "readMarks"
                    },
                    "add": 0.1,
                    "label": "Watched the water"
                  }
                ]
              },
              "success": {
                "result_text": "You loosen the fragment and return to the path before the water reaches the step. In your hand, it is one piece of physics calc.",
                "effects": [
                  {
                    "op": "add_ore",
                    "type": "physics",
                    "qty": 1
                  }
                ]
              },
              "fail": {
                "result_text": "Your foot slips on the last step. You catch the rail and climb back without the fragment. The tide covers it a minute later.",
                "effects": [
                  {
                    "op": "add",
                    "path": "player.hp",
                    "value": -3
                  }
                ]
              }
            },
            {
              "id": "leaveChip",
              "label": "Leave it",
              "effects": [],
              "result_text": "You keep walking. By the time you look back, the water has reached the joint."
            }
          ]
        },
        {
          "key": "exit",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "The river takes the lower steps back. The path remains open."
        }
      ]
    }
  }
}
```

## Open points for review

- The ore, injury and odds are draft balance values. Only the player identifies the fragment; this is an uncommon exposed find, not evidence that calc is publicly familiar.
- No mudlark, sealed tin, or item bonus.

