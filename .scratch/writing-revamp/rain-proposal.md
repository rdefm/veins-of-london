# rain — imported from data/events/rain.json

```json
{
  "id": "rain",
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
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "It starts raining the specific, personal way London rain does — not weather so much as a verdict. Nobody around you reacts; rain is not news here. You're soaked by the time you find shelter, mildly impressed at how quickly the city returns to pretending it didn't just do that.",
          "key": "c1"
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
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "rain.json",
  "_liveHash": "1970ada7"
}
```
