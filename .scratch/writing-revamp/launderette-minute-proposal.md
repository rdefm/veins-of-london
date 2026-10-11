# The Launderette Minute — random event proposal

The player has stopped to dry a rain-soaked coat. The dryer stops with the coat inside, so the problem belongs to the player. The fault is mechanical, not a public calc anomaly.

**Card count:** 4 definition cards; two choice points; repeatable under the deck's normal no-repeat window.

Goals:
1. **Hook:** The player's coat is trapped in a paid dryer.
2. **Agency:** Inspect the release instructions or call the attendant, then try the latch or wait.
3. **Stakes:** A small repair fee against waiting for the service visit.

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 1 | `readNotice` | Read the notice | Improves the latch roll. |
| 1 | `callNumber` | Call the number | Confirms a service visit is due; no roll bonus. |
| 2 | `releaseLatch` | Release the latch | Crafting roll; failure incurs £5 damage fee. |
| 2 | `wait` | Wait | No cash risk. |

```json
{
  "id": "launderette_minute",
  "deck": {
    "district": "whitechapel",
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
      "title": "The locked dryer",
      "cards": [
        {
          "key": "arrival",
          "type": "narration",
          "label": "Whitechapel",
          "speaker": null,
          "text": "You stop to dry your rain-soaked coat. The dryer finishes, but its door stays locked with the coat inside. The number above it connects to an attendant covering two shops."
        },
        {
          "key": "preparation",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "A faded release notice is taped beside the coin slot. The attendant can send someone, though he will not promise when.",
          "choices": [
            {
              "id": "readNotice",
              "label": "Read the notice",
              "effects": [],
              "result_text": "The release tab sits beneath the door handle. The notice warns you not to pull the handle itself."
            },
            {
              "id": "callNumber",
              "label": "Call the number",
              "effects": [],
              "result_text": "The attendant confirms a service visit is due. He asks you not to damage the handle while you wait."
            }
          ]
        },
        {
          "key": "release",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Your coat is visible through the glass. You can try the tab, or wait for the attendant's service visit.",
          "choices": [
            {
              "id": "releaseLatch",
              "label": "Release the latch",
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
                      "event": "launderette_minute",
                      "card": 1,
                      "option": "readNotice"
                    },
                    "add": 0.1,
                    "label": "Read the release notice"
                  }
                ]
              },
              "success": {
                "result_text": "The tab gives. You take your coat and close the door gently. The attendant has one less call to make.",
                "effects": []
              },
              "fail": {
                "result_text": "You catch the handle instead of the tab. It cracks. The attendant takes your card details for the repair fee before he opens the dryer.",
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
                "reason": "Needs £5 for possible damage"
              }
            },
            {
              "id": "wait",
              "label": "Wait",
              "effects": [],
              "result_text": "The attendant arrives later, opens the dryer with a key, and leaves without charging you."
            }
          ]
        },
        {
          "key": "exit",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You put on the still-warm coat and get back to the street."
        }
      ]
    }
  }
}
```

## Open points for review

- The £5 fee, one-block wait, and odds are draft balance choices. The explicit wait gives a cash-free route.
- No ore or item modifier. This is an ordinary machine fault.

