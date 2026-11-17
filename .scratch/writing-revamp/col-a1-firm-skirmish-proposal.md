# col_a1_firm_skirmish — imported from data/events/col_a1_firm_skirmish.json

```json
{
  "id": "col_a1_firm_skirmish",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "colA1SkirmishSeen",
      "value": true
    },
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
          "label": null,
          "speaker": null,
          "text": "You come round the corner into the end of something. Four people, one of them on the floor, and the specific quiet that happens after shouting rather than before it."
        },
        {
          "key": "c2",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Two of them are wearing the kind of coats that cost money. They are not hurrying. One is writing something down."
        },
        {
          "key": "c3",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "By the time you've decided whether to do anything, there are two people and one of them is being helped into a car by the other. Nobody looks at you. It has been arranged that there is nothing to look at."
        },
        {
          "key": "c4",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You ask Des about it later. He says \"Firm,\" the way you'd say \"rain,\" and asks whether you found anything."
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
    },
    "seq": [
      "c1",
      "c2",
      "c3",
      "c4"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a1_firm_skirmish.json",
  "_liveHash": "c7f98c88"
}
```
