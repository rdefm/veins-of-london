# heath_dogwalker — imported from data/events/heath_dogwalker.json

```json
{
  "id": "heath_dogwalker",
  "on_complete": [
    {
      "op": "add_ore",
      "type": "life",
      "qty": 2
    },
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "hampstead",
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
          "label": "Hampstead Heath",
          "speaker": null,
          "text": "An older woman with four dogs and the bearing of a small aristocracy nods at you like you're expected. One of the dogs sniffs your bag with professional interest."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Dogwalker",
          "text": "\"You're doing the ore thing, aren't you. Everyone up here can tell. Here - Wellington dug this up under an oak.\""
        },
        {
          "key": "c3",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "She's gone before you can ask which dog is Wellington. All four look equally capable of digging up the past."
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
  "_liveSource": "heath_dogwalker.json",
  "_liveHash": "1a2536ed"
}
```
