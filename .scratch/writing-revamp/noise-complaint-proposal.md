# Noise Complaint — random event proposal

The player stops because they sense a possible site from the public pavement. A caretaker challenges the apparent loitering; residents think the noise is plumbing. Two successful private investigations can discover an unclaimed vein site.

**Card count:** 4 definition cards; two choice points; repeatable under the deck's normal no-repeat window.

Goals:
1. **Hook:** The player is examining a wall when the caretaker asks why.
2. **Agency:** Ask about the complaint or read the exterior service markings, then trace either route or leave.
3. **Stakes:** A site discovery, with no free claim and no public revelation of calc.

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 1 | `askCaretaker` | Ask about noise | Improves the cultivating approach. |
| 1 | `readMarkings` | Read service marks | Improves the crafting approach. |
| 2 | `followHum` | Follow the hum | Cultivating roll; success discovers an unclaimed site. |
| 2 | `tracePipes` | Trace the pipes | Crafting roll; success discovers an unclaimed site. |
| 2 | `leave` | Leave | No roll or discovery. |

```json
{
  "id": "noise_complaint",
  "deck": {
    "district": "any",
    "weight": 1,
    "excludeIfFlag": null,
    "barometerState": null,
    "requireEventSiteRoom": true
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
      "title": "The wall",
      "cards": [
        {
          "key": "arrival",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "A low vibration stops you beside a block of flats. You study the outside wall from the pavement. The caretaker comes out and asks whether you are from the council. You say no."
        },
        {
          "key": "preparation",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Residents have reported a hum, the caretaker says. He thinks it is the boiler. The service markings are visible on the wall beside you.",
          "choices": [
            {
              "id": "askCaretaker",
              "label": "Ask about noise",
              "effects": [],
              "result_text": "He tells you which flats hear it and when. The complaints agree on a stretch of wall, not a time of day."
            },
            {
              "id": "readMarkings",
              "label": "Read service marks",
              "effects": [],
              "result_text": "The painted pipe route turns away before it reaches the noisy part of the wall."
            }
          ]
        },
        {
          "key": "investigation",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The caretaker is waiting for you to move on. You can take one last reading from the pavement, following the sound or the service route.",
          "choices": [
            {
              "id": "followHum",
              "label": "Follow the hum",
              "check": {
                "base": 0.3,
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
                      "event": "noise_complaint",
                      "card": 1,
                      "option": "askCaretaker"
                    },
                    "add": 0.15,
                    "label": "Located the complaint"
                  },
                  {
                    "item": "prophetsBreath",
                    "optional": true,
                    "consume": true,
                    "add": 0.15,
                    "label": "Prophet's Breath"
                  }
                ]
              },
              "success": {
                "result_text": "The vibration narrows beneath the foundations. You mark an unclaimed site on your private map. To the caretaker, you suggest he still have the boiler checked.",
                "effects": [
                  {
                    "op": "discover_event_site",
                    "district": "current",
                    "minTier": "fair"
                  }
                ]
              },
              "fail": {
                "result_text": "Traffic shakes the wall again, and you lose the thread. You have no location worth marking.",
                "effects": []
              }
            },
            {
              "id": "tracePipes",
              "label": "Trace the pipes",
              "check": {
                "base": 0.3,
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
                      "event": "noise_complaint",
                      "card": 1,
                      "option": "readMarkings"
                    },
                    "add": 0.15,
                    "label": "Read the service route"
                  },
                  {
                    "item": "prophetsBreath",
                    "optional": true,
                    "consume": true,
                    "add": 0.15,
                    "label": "Prophet's Breath"
                  }
                ]
              },
              "success": {
                "result_text": "The service route rules out the pipes. A separate line runs beneath the block. You mark the unclaimed site privately and leave the caretaker with his boiler report.",
                "effects": [
                  {
                    "op": "discover_event_site",
                    "district": "current",
                    "minTier": "fair"
                  }
                ]
              },
              "fail": {
                "result_text": "Too many service lines cross here. You cannot separate the source from the building's ordinary noise.",
                "effects": []
              }
            },
            {
              "id": "leave",
              "label": "Leave",
              "effects": [],
              "result_text": "You tell the caretaker you were only looking. He returns to his clipboard; you continue down the street."
            }
          ]
        },
        {
          "key": "exit",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "The caretaker calls a boiler engineer. Your map stays in your pocket."
        }
      ]
    }
  }
}
```

## Open points for review

- `discover_event_site` and `requireEventSiteRoom` are proposed, not implemented. Eligibility is below district siteCap; success creates one unclaimed current-district site using normal tier/ore rolls with a proposed fair-tier floor, no second block, XP, or deck draw.
- The fair floor, odds, and choice modifiers need balance approval. This is the sole proposed site reward in the set.

