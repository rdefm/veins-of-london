# col_a1_nadia_done — imported from data/events/col_a1_nadia_done.json

```json
{
  "id": "col_a1_nadia_done",
  "on_complete": [
    {
      "op": "faction_relation",
      "faction": "collective",
      "value": 10
    },
    {
      "op": "set_flag",
      "flag": "colA1NadiaThreadDone",
      "value": true
    },
    {
      "op": "set_screen",
      "screen": "vein_list"
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
          "speaker": "Nadia",
          "text": "\"Right. That's mine now.\" She counts out the money in a way that suggests she has counted out a great deal of money in her life. \"And that's three days a fortnight back.\""
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"You'll get offers, by the way. People who want to buy ground off you cheap because you're new. Don't take them. Ask me first, I'll tell you what it's worth, and I'll tell you straight even when I'm the one buying.\""
        },
        {
          "key": "c3",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You notice that you actually believe her."
        },
        {
          "key": "c4",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You have sold a vein. There's more money in your account than there was, and slightly less London that belongs to you. Feels like progress."
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
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c4": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "col_a1_nadia_done.json",
  "_liveHash": "011509ce"
}
```
