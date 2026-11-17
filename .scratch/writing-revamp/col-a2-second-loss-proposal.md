# col_a2_second_loss — imported from data/events/col_a2_second_loss.json

```json
{
  "id": "col_a2_second_loss",
  "on_complete": [
    {
      "op": "col_a2_force_vein_loss",
      "faction": "firm"
    },
    {
      "op": "set_flag",
      "flag": "colA2SecondLossSeen",
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
          "speaker": "Nadia",
          "text": "\"Another one's gone. Not one of the easy ones. One of ours — one we did everything for.\""
        },
        {
          "key": "c2",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "She has the ledger open. She runs a finger down the column for that vein and stops at the bottom, where nothing's missing."
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"That one shouldn't have gone. We did everything right for that one.\""
        },
        {
          "key": "c4",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "She isn't upset. She's doing the sum again, slower, like it might come out different."
        },
        {
          "key": "c5",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Des reads it over her shoulder, twice. He opens his mouth, closes it again, and goes back to the top of the column."
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"I don't know. I genuinely don't. It should've been the last one they tried.\""
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
    },
    "seq": [
      "c1",
      "c2",
      "c3",
      "c4",
      "c5",
      "c6"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a2_second_loss.json",
  "_liveHash": "8da77c37"
}
```
