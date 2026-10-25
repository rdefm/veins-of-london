# col_a1_nadia_vein — imported from data/events/col_a1_nadia_vein.json

```json
{
  "id": "col_a1_nadia_vein",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "veinSaleUnlocked",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "colA1NadiaAskSeen",
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
          "text": "\"That's the order filled and I'm still doing three days on the phone every fortnight. That's not a solution, that's you being nice.\""
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"So. Different idea. You seed me a time vein and I buy it off you. Then it's mine, it produces, and the standing order fills itself.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"You take the risk - the forty units, the seeding, whether it takes. I take a working vein and pay for it.\""
        },
        {
          "key": "c4",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "It is the first time anyone in the Collective has proposed a transaction to you where both halves were named out loud, and it's oddly restful."
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"Grow it a bit first if you've any sense. I'll pay what it's worth on the day, and a hole in the ground with forty units in it isn't worth as much as something you've cultivated.\""
        },
        {
          "key": "c6",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You now know that a vein is a thing that can be sold, which had genuinely not occurred to you."
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
  "_liveSource": "col_a1_nadia_vein.json",
  "_liveHash": "48e9c9bb"
}
```
