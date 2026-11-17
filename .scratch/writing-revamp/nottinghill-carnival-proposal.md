# nottinghill_carnival — imported from data/events/nottinghill_carnival.json

```json
{
  "id": "nottinghill_carnival",
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
    "district": "nottinghill",
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
          "label": "Notting Hill",
          "speaker": null,
          "text": "A man on Portobello Road is hanging bunting from a window that isn't his. Nobody stops him. The street has the look of somewhere that is always about to throw a party and never quite admits it's already started."
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "He hands you a paper flag on the way past, as though you'd been on the guest list all along. The emotion-type in your bag warms by a degree."
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
  "_liveSource": "nottinghill_carnival.json",
  "_liveHash": "f5428a27"
}
```
