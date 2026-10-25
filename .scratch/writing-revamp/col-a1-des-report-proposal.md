# col_a1_des_report — imported from data/events/col_a1_des_report.json

```json
{
  "id": "col_a1_des_report",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "colA1DesThreadDone",
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
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You give Des the last address. He still doesn't write it down."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"That's the pair, then.\" He's pleased in a way that takes a second to read as pleased. \"Two people who'll have something by the weekend.\""
        },
        {
          "key": "c4",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You ask who. He tells you the first names and nothing else, and you realise a beat later that he has told you exactly as much as he'd tell anyone about you."
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Nobody's ever raided a vein they didn't know about.\" He says it with a sly smile. \"That's how the Collective keeps safe; nothing written down, and no boss at the top who knows everything.\""
        },
        {
          "key": "c7",
          "type": "speaker",
          "text": "\"By the way, Archie doing all right? We go back years. Had a bit of business once, sorted it out ages ago.\" He says it with the mild warmth of a man recalling a settled account, and moves on before you can ask which business.",
          "speaker": "Des"
        },
        {
          "key": "c6",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "By the end of the week, both patches you found have veins in them and neither of them is yours."
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
      ],
      "c5": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c6": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "col_a1_des_report.json",
  "_liveHash": "e72ab043"
}
```
