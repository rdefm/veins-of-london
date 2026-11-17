# roman_brick — imported from data/events/roman_brick.json

```json
{
  "id": "roman_brick",
  "on_complete": [
    {
      "op": "add",
      "path": "flags.oddities",
      "value": 1
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
          "text": "Half-buried in the churned ground of wherever you're standing is a brick — old, red, unmistakably Roman — in a spot with no plausible Roman history whatsoever."
        },
        {
          "key": "c2",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You've seen one of these before. You didn't think anything of it then either. That's probably the point."
        },
        {
          "key": "c3",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You leave it where it is. Whatever's underneath London doesn't need your help finding daylight."
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
  "_liveSource": "roman_brick.json",
  "_liveHash": "fb141efb"
}
```
