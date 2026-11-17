# col_a1_deferred_join — imported from data/events/col_a1_deferred_join.json

```json
{
  "id": "col_a1_deferred_join",
  "on_complete": [
    {
      "op": "join_faction",
      "faction": "collective"
    },
    {
      "op": "set_flag",
      "flag": "colA1Joined",
      "value": true
    },
    {
      "op": "set_screen",
      "screen": "phone"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "c1",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Right,\" he says, like you've asked him what time it is. \"You're in. Don't need a form for it.\""
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "That's it. That's the whole thing. Nobody hands you anything to prove it, and you walk out fractionally more a part of something than you were an hour ago."
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
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
      ]
    },
    "seq": [
      "c1",
      "c2"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a1_deferred_join.json",
  "_liveHash": "2dd4fb66"
}
```
