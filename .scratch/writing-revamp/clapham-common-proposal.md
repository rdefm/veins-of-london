# clapham_common — imported from data/events/clapham_common.json

```json
{
  "id": "clapham_common",
  "on_complete": [
    {
      "op": "add_ore",
      "type": "life",
      "qty": 1
    },
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "clapham",
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
          "label": "Clapham",
          "speaker": null,
          "text": "The Common is a single hungover organism in lycra. Someone is doing yoga beside a bin with total conviction. A dog is doing something to a hedge, also with total conviction."
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You find a clean fleck of life-type in the grass where the yoga was. It is, on balance, the most Clapham thing that could have happened."
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
  "_liveSource": "clapham_common.json",
  "_liveHash": "419fa108"
}
```
