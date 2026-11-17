# camden_shakedown — imported from data/events/camden_shakedown.json

```json
{
  "id": "camden_shakedown",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "camden",
    "weight": 1,
    "excludeIfFlag": null,
    "barometerState": null
  },
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "c1",
          "type": "narration",
          "label": "Camden",
          "speaker": null,
          "text": "Two lads corner you near the lock, doing their best impression of menace between a falafel stall and a man selling knock-off headphones. It's not entirely unconvincing."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "One of Them",
          "text": "\"Toll for using this bit of pavement. Fifty quid, and we all have a nice afternoon.\""
        },
        {
          "key": "c3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The third one just stands there, which is somehow worse.",
          "choices": [
            {
              "label": "Pay £50",
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": -50
                }
              ],
              "result_text": "You pay. They seem almost disappointed not to have to do anything. You walk on with your dignity roughly 90% intact."
            },
            {
              "id": "refuse",
              "label": "Refuse",
              "effects": [
                {
                  "op": "chance",
                  "p": 0.4,
                  "on_success": [
                    {
                      "op": "start_street_mugging"
                    }
                  ],
                  "on_fail": []
                }
              ],
              "result_text": "You refuse. For a second, nobody moves - whatever happens next happens fast."
            }
          ]
        },
        {
          "key": "c4",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Camden closes back over you like nothing happened. Somewhere, a man is still selling headphones that don't work."
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "cards",
      "on_complete",
      "deck"
    ],
    "cards": {
      "c1": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c2": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c4": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    },
    "seq": [
      "c1",
      "c2",
      "c3",
      "c4"
    ],
    "elseKeys": []
  },
  "_liveSource": "camden_shakedown.json",
  "_liveHash": "4ed9751c"
}
```
