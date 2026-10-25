# biz_a1_closing — imported from data/events/biz_a1_closing.json

```json
{
  "id": "biz_a1_closing",
  "fillFromContext": true,
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "bizA1Complete",
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
          "label": "Bermondsey - James's unit",
          "speaker": null,
          "text": "BizBrief is open on Archie's phone, propped against the hourglass. Owen has been given a chair for the occasion and is not sure what to do with it."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Right. Two orders, a full week each, and none of us laid a finger on them. {periodOne}. {periodTwo}.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"This payday the pot took {receipts}. Owen's wages come out first: {owenWage}.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Owen",
          "text": "\"That's me. Thanks.\""
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"What's left splits three ways. {archieShare} to me, {jamesShare} to James, {playerShare} to you.\""
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"It ran without us. You get that? Money made while you were off doing something else.\""
        },
        {
          "key": "c7",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "James takes a long time to put his cup down."
        },
        {
          "key": "c8",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"The pearls were within tolerance, the buyer paid on time, and nobody needed anything explained twice. I will call that adequate.\""
        },
        {
          "key": "c9",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Adequate. From him. Frame that.\""
        },
        {
          "key": "c10",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Owen goes back to his veins, James to his crafting. On Archie's phone, next week's orders are already coming in."
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
      ],
      "c7": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c8": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c9": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c10": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "biz_a1_closing.json",
  "_liveHash": "3963f2f1"
}
```
