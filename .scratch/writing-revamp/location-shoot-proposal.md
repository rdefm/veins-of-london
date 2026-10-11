# Location Shoot — random event proposal

A small film crew is missing a background walker. The player is already crossing its route; a runner offers clearly stated pay for a short walk-on. No calc or mystical item.

**Card count:** 4 definition cards; two choice points; repeatable under the deck's normal no-repeat window.

Goals:
1. **Hook:** The player is stopped at a filming crossing they need to use.
2. **Agency:** Watch the marks or read the release, then take the paid walk or continue their journey.
3. **Stakes:** The player is paid for time even when the take is unusable.

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 1 | `watchMark` | Watch the mark | Improves the usable-take roll. |
| 1 | `readRelease` | Read the release | Confirms the pay; no roll bonus. |
| 2 | `takePart` | Do the walk | Stealth roll; £10 base pay, plus £10 for a usable take. |
| 2 | `pass` | Pass | No roll or payment. |

```json
{
  "id": "location_shoot",
  "deck": {
    "district": "shoreditch",
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
      "title": "The walk-on",
      "cards": [
        {
          "key": "arrival",
          "type": "narration",
          "label": "Shoreditch",
          "speaker": null,
          "text": "A small crew has blocked the crossing you need. Their booked background walker has not turned up. A runner asks whether you can cross on camera instead, for £10."
        },
        {
          "key": "preparation",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "They need one walk at the next take. The runner says there is another £10 if the shot is usable. You can watch the mark or read the release form.",
          "choices": [
            {
              "id": "watchMark",
              "label": "Watch the mark",
              "effects": [],
              "result_text": "The camera follows a cyclist, not the walkers. The runner shows you the point where you should enter frame."
            },
            {
              "id": "readRelease",
              "label": "Read the release",
              "effects": [],
              "result_text": "The form says what the runner said: £10 for the walk, another £10 if they can use it."
            }
          ]
        },
        {
          "key": "performance",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The crossing opens for the crew's next take. You can do the walk or use the other side of the street.",
          "choices": [
            {
              "id": "takePart",
              "label": "Do the walk",
              "check": {
                "base": 0.5,
                "show": "odds",
                "mods": [
                  {
                    "path": "player.stealthSkill",
                    "perPoint": 0.05,
                    "above": 1,
                    "label": "Blending in"
                  },
                  {
                    "choice": {
                      "event": "location_shoot",
                      "card": 1,
                      "option": "watchMark"
                    },
                    "add": 0.1,
                    "label": "Watched the mark"
                  }
                ]
              },
              "success": {
                "result_text": "You cross without looking at the camera. The director keeps the take. The runner pays both amounts and removes the temporary barrier.",
                "effects": [
                  {
                    "op": "add",
                    "path": "player.cash",
                    "value": 10
                  }
                ]
              },
              "fail": {
                "result_text": "You enter frame early. They use another take, but the runner still pays the agreed £10 for your time.",
                "effects": []
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 10
                }
              ]
            },
            {
              "id": "pass",
              "label": "Pass",
              "effects": [],
              "result_text": "You take the open pavement on the other side. The runner turns to the next passer-by."
            }
          ]
        },
        {
          "key": "exit",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "The crew moves the barrier. The street resumes pretending it was never closed."
        }
      ]
    }
  }
}
```

## Open points for review

- £10 base and £10 usable-take bonus are draft balance values. The base pay sits on the rolled option's own effects, so it applies to success and failure.
- No magic or item bonus; ordinary paid work should stay ordinary.

