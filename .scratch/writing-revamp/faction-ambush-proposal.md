# faction_ambush — imported from data/events/faction_ambush.json

```json
{
  "id": "faction_ambush",
  "fillFromContext": true,
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "c1",
          "type": "narration",
          "label": "Ambush",
          "speaker": null,
          "text": "A few {faction} faces have been waiting for you. They don't pretend otherwise."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Their Leader",
          "text": "\"Nothing personal. Well. Some of it's personal.\""
        },
        {
          "key": "c3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "There's only one way out of this, and it has elbows in it.",
          "choices": [
            {
              "label": "Fight",
              "effects": [
                {
                  "op": "start_faction_ambush_combat"
                }
              ],
              "result_text": "You square up."
            }
          ]
        },
        {
          "key": "c4",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "It's over, one way or another. The street goes back to pretending nothing happened."
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "fillFromContext",
      "cards",
      "on_complete"
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
        "text",
        "choices"
      ],
      "c4": [
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
      "c3",
      "c4"
    ],
    "elseKeys": []
  },
  "_liveSource": "faction_ambush.json",
  "_liveHash": "8f5c7195"
}
```
