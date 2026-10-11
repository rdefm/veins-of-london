# The Lift — random event proposal

The player is inside a shopping-centre lift on their route. A courier's trolley strap catches in the door sill; the player can see and address the cause. No impossible floor or calc.

**Card count:** 4 definition cards; two choice points; repeatable under the deck's normal no-repeat window.

Goals:
1. **Hook:** The lift cannot close because a strap is caught.
2. **Agency:** Check the sill or call the intercom, then free the strap or wait.
3. **Stakes:** A careful fix gets everyone moving; rushing risks a minor injury.

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 1 | `checkSill` | Check the sill | Improves the release roll. |
| 1 | `useIntercom` | Use the intercom | Calls staff; no roll bonus. |
| 2 | `freeStrap` | Free the strap | Crafting roll; failure hurts the player's hand. |
| 2 | `wait` | Wait | No roll or injury. |

```json
{
  "id": "missing_floor",
  "deck": {
    "district": "kensington",
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
      "title": "The stuck doors",
      "cards": [
        {
          "key": "arrival",
          "type": "narration",
          "label": "Kensington",
          "speaker": null,
          "text": "You take the shopping-centre lift up to the street. It stops at the landing, but the doors keep trying to close. A courier's trolley strap has slipped into the sill."
        },
        {
          "key": "preparation",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The courier holds the trolley still. You can look at the caught strap or use the intercom while he keeps it from moving.",
          "choices": [
            {
              "id": "checkSill",
              "label": "Check the sill",
              "effects": [],
              "result_text": "The strap is wound round a small roller. Pulling the trolley would tighten it."
            },
            {
              "id": "useIntercom",
              "label": "Use the intercom",
              "effects": [],
              "result_text": "A guard answers and says someone is coming. He asks you not to force the doors."
            }
          ]
        },
        {
          "key": "release",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The courier has a delivery deadline. The doors are level with the landing, but the strap will not come free on its own.",
          "choices": [
            {
              "id": "freeStrap",
              "label": "Free the strap",
              "check": {
                "base": 0.45,
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
                      "event": "missing_floor",
                      "card": 1,
                      "option": "checkSill"
                    },
                    "add": 0.1,
                    "label": "Checked the roller"
                  }
                ]
              },
              "success": {
                "result_text": "You ease the strap off the roller. The doors close properly after the courier wheels out. He thanks you and hurries on.",
                "effects": []
              },
              "fail": {
                "result_text": "The roller snaps back against your fingers. The guard arrives and releases it with a tool while you nurse your hand.",
              "effects": [
                {
                  "op": "add",
                  "path": "player.hp",
                  "value": -2
                }
              ]
              }
            },
            {
              "id": "wait",
              "label": "Wait",
              "effects": [],
              "result_text": "You leave the strap alone. A guard arrives with a release tool; the courier checks his watch throughout."
            }
          ]
        },
        {
          "key": "exit",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "At street level, the courier and you head in different directions."
        }
      ]
    }
  }
}
```

## Open points for review

- The 2 HP injury and check odds are draft balance values. Waiting has no separate block cost.
- The saved filename/id remain `missing_floor` for continuity; rename on approval if desired.

