# pigeon_omen — imported from data/events/pigeon_omen.json

```json
{
  "id": "pigeon_omen",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "luckyOmen",
      "value": true
    },
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
          "text": "A pigeon lands directly on your bag, considers you with the flat, ancient judgement pigeons reserve for people who look like they're up to something, and doesn't move."
        },
        {
          "key": "c2",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You've heard the stories — fate-types collect near omens the way flies collect near anything else. You have no idea if this counts. The pigeon, notably, does not clarify."
        },
        {
          "key": "c3",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "It flies off eventually, satisfied or bored, impossible to say which. You feel, absurdly, like your next piece of luck has already been decided somewhere above you."
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
        "text"
      ]
    },
    "seq": [
      "c1",
      "c2",
      "c3"
    ],
    "elseKeys": []
  },
  "_liveSource": "pigeon_omen.json",
  "_liveHash": "060b2492"
}
```
