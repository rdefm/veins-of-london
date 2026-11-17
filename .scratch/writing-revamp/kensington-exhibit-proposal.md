# kensington_exhibit — imported from data/events/kensington_exhibit.json

```json
{
  "id": "kensington_exhibit",
  "on_complete": [
    {
      "op": "add_ore",
      "type": "time",
      "qty": 1
    },
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "kensington",
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
          "label": "Kensington",
          "speaker": null,
          "text": "A museum guard holds a side door open and doesn't look at you. Inside, a case of Victorian clocks tick slightly out of step with the building, and a laminated sign apologises for the inconvenience."
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "The door closes behind you with the soft administrative click of something being logged. You leave with a splinter of spare time in your pocket and no receipt."
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
  "_liveSource": "kensington_exhibit.json",
  "_liveHash": "eb8101b6"
}
```
