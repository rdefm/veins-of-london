# foxes — imported from data/events/foxes.json

```json
{
  "id": "foxes",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "any",
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
          "label": null,
          "speaker": null,
          "text": "A fox crosses your path at the exact midpoint between two streetlights, pauses to look at you with total lack of interest, and continues on business you'll never be briefed on. London's real nightshift clocks on. You're not on the rota."
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
      ]
    },
    "seq": [
      "c1"
    ],
    "elseKeys": []
  },
  "_liveSource": "foxes.json",
  "_liveHash": "18159c38"
}
```
