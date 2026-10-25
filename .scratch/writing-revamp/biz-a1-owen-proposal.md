# biz_a1_owen — imported from data/events/biz_a1_owen.json

```json
{
  "id": "biz_a1_owen",
  "on_complete": [
    {
      "op": "unlock_contact",
      "contact": "owen"
    },
    {
      "op": "recruit_contact",
      "contact": "owen"
    },
    {
      "op": "set_flag",
      "flag": "bizOwenCultivationRole",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "bizStaffTabOpen",
      "value": true
    },
    {
      "op": "activate_business"
    },
    {
      "op": "set_flag",
      "flag": "bizA1OwenJoined",
      "value": true
    },
    {
      "op": "issue_recurring_offers"
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
          "text": "There is a third person in the unit. He is young, standing very straight by the door with his hands behind his back, and he has clearly been there a while."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Three orders, in full. I am told people have started saying you are not completely hopeless. I have not corrected them.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"This is Owen. He cultivates. Carefully, every day, and without complaint, which already puts him ahead of most people I have trained.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Owen",
          "text": "\"Thanks for having me. Really. I don't get offered much like this. Whatever veins you've got, I'll look after them.\""
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"He is young, and has much to learn. But he is hardworking and has potential. Over time he will be a very good pair of hands, which you need more.\""
        },
        {
          "key": "c6",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Owen nods, as if he has heard this before and decided it was fair."
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Lovely. What's he cost?\""
        },
        {
          "key": "c8",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Two hundred and fifty a week. Paid by the business, not by me.\""
        },
        {
          "key": "c9",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"The business. So there is one.\""
        },
        {
          "key": "c10",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"You, Archie, and I split profits equally between us. For now I am a limited partner: I take my share and offer some advice. When you give me a reason, I will join properly and craft.\""
        },
        {
          "key": "c11",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Until then I keep my own work and my own clients. Neither of you will go near them.\""
        },
        {
          "key": "c12",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Right, so. From today orders pay into the pot, not your pocket. Owen's wages come out of it every week, and whatever's left splits three ways. Put him on your veins in BizBrief - there's a Staff tab now. And there's a weekly ore order on there. Take one, it pays his wages.\""
        },
        {
          "key": "c13",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Owen has already asked which veins are his. James turns the hourglass over and does not look up, which from James is a welcome."
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
      ],
      "c11": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c12": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c13": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "biz_a1_owen.json",
  "_liveHash": "4e65461c"
}
```
