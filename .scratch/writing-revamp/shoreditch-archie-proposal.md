# shoreditch_archie — imported from data/events/shoreditch_archie.json

```json
{
  "id": "shoreditch_archie",
  "on_complete": [
    {
      "op": "relation",
      "contact": "archie",
      "value": 2
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
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Archie appears the way he always does - already mid-sentence, as though the conversation started before you arrived and you're just catching up.",
          "key": "c1"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Hello hello. Fancy seeing you here. You look like someone currently doing something mildly reckless. Carry on. I'm not your mum.\"",
          "key": "c2"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"Comforting.\"",
          "key": "c3"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"I do try.\" He nods once, like that's the whole conversation, and drifts back into whatever he was doing before he clocked you.",
          "key": "c4"
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
      ],
      "c2": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c3": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c4": [
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "shoreditch_archie.json",
  "_liveHash": "f5c627ed"
}
```
