# kx_delay — imported from data/events/kx_delay.json

```json
{
  "id": "kx_delay",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "kingscross",
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
          "label": "King's Cross",
          "speaker": null,
          "text": "The departures board changes its mind for the fourth time. Somewhere behind the barriers, a Tannoy voice apologises for something it clearly isn't sorry about."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Everyone's on the King's Cross deal. You are, for once, one of the delayed rather than the delighted.",
          "choices": [
            {
              "label": "Wait it out",
              "effects": [
                {
                  "op": "lose_time_block"
                }
              ],
              "result_text": "You wait. Time passes the way it only does in stations — all of it, somehow, at once."
            },
            {
              "label": "Pay for a cab (£30)",
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": -30
                }
              ],
              "result_text": "You pay. The driver has opinions about the Northern line. You did not ask for them."
            }
          ]
        },
        {
          "key": "c3",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Either way, you get where you're going. King's Cross remains, structurally, on its way somewhere else."
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
        "text",
        "choices"
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "kx_delay.json",
  "_liveHash": "8aa2614a"
}
```
