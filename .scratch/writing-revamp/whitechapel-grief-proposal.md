# whitechapel_grief — imported from data/events/whitechapel_grief.json

```json
{
  "id": "whitechapel_grief",
  "on_complete": [
    {
      "op": "add_ore",
      "type": "emotion",
      "qty": 1
    },
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "whitechapel",
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
          "label": "Whitechapel",
          "speaker": null,
          "text": "Whitechapel keeps its grief the way other places keep street furniture — permanent, load-bearing, mostly ignored. You feel it anyway, a low hum under the emotion-type in your bag."
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "It passes, the way all inherited grief eventually does — not gone, just filed. The emotion-type in your bag sits heavier when you stand up, like it's been listening the whole time."
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
      ]
    },
    "seq": [
      "c1",
      "c2"
    ],
    "elseKeys": []
  },
  "_liveSource": "whitechapel_grief.json",
  "_liveHash": "3517a069"
}
```
