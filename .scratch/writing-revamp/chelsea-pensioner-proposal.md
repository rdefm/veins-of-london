# chelsea_pensioner — imported from data/events/chelsea_pensioner.json

```json
{
  "id": "chelsea_pensioner",
  "on_complete": [
    {
      "op": "add_ore",
      "type": "fate",
      "qty": 1
    },
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "chelsea",
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
          "label": "Chelsea",
          "speaker": null,
          "text": "A man in a scarlet coat sits on a bench by the river and watches you pass with the patience of someone who has seen every kind of debt come due. He doesn't nod. He does, very slightly, un-nod."
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Somewhere behind you a bell rings once, for no one. The fate-type in your bag lands a touch heavier than it should."
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
  "_liveSource": "chelsea_pensioner.json",
  "_liveHash": "6b32ae6c"
}
```
