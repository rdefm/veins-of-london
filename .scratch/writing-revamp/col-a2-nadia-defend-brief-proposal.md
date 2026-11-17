# col_a2_nadia_defend_brief — imported from data/events/col_a2_nadia_defend_brief.json

```json
{
  "id": "col_a2_nadia_defend_brief",
  "on_complete": [
    {
      "op": "col_a2_pick_nadia_defend_vein"
    },
    {
      "op": "set_flag",
      "flag": "colA2DefendBriefed",
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
          "text": "\"Kit's made — good. There's one place I want eyes on now, more than the rest. You'll get the alert same as ever; when it goes, you'll know why.\""
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"That's what you made it for.\""
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
  "_liveSource": "col_a2_nadia_defend_brief.json",
  "_liveHash": "8a165b62"
}
```
