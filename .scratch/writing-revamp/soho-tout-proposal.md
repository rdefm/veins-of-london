# soho_tout — imported from data/events/soho_tout.json

```json
{
  "id": "soho_tout",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "soho",
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
          "label": "Soho",
          "speaker": null,
          "text": "A man with a laminated card and the unkillable optimism of the professionally rejected steps into your path. \"Members' bar, love — and word is there's a proper market coming to Soho too. Ore, gear, all sorts. Not yet, but soon. You'll want to be first.\" He's gone before you can ask what \"soon\" means in Soho years."
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
    }
  },
  "_liveSource": "soho_tout.json",
  "_liveHash": "d8f7e320"
}
```
