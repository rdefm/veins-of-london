# battersea_hum — imported from data/events/battersea_hum.json

```json
{
  "id": "battersea_hum",
  "on_complete": [
    {
      "op": "add_ore",
      "type": "physics",
      "qty": 1
    },
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "battersea",
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
          "label": "Battersea",
          "speaker": null,
          "text": "The old power station hasn't generated anything since before your parents were your age, and it still hums, very faintly, like a tooth that's been pulled but hasn't told the nerve yet."
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You put your hand flat against the brick for exactly as long as feels socially acceptable to touch a decommissioned building, and come away with a faint charge of physics-type static in your palm."
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
  "_liveSource": "battersea_hum.json",
  "_liveHash": "bfc3efbd"
}
```
