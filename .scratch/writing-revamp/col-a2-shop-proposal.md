# col_a2_shop — imported from data/events/col_a2_shop.json

```json
{
  "id": "col_a2_shop",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "colA2ShopSeen",
      "value": true
    },
    {
      "op": "set_screen",
      "screen": "contacts"
    },
    {
      "op": "start_event",
      "event": "col_a2_pattern"
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
          "label": "Whitechapel",
          "speaker": null,
          "text": "The shop's shutter is halfway down. The blind on the door is turned to closed."
        },
        {
          "key": "c2",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Hakim's on the stool behind the till, holding a tea towel full of ice from the freezer cabinet against his mouth. His lip's split. He keeps trying to talk properly around it."
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Hakim",
          "text": "\"I'm fine,\" he says."
        },
        {
          "key": "c4",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Des and Nadia are already there. Des isn't shouting. He's gone quiet instead, which nobody in the room has seen him do before. It makes everything feel even more serious."
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Two of them. Made an offer for the shop and what's under it. A fair price, they said.\""
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Hakim",
          "text": "\"I said no.\" He tries to shrug and thinks better of it halfway through. \"They didn't love that.\""
        },
        {
          "key": "c7",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Nobody involved has a name yet. From the way Nadia's talking, you think that will change soon - this attack won't go unanswered."
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
      ]
    },
    "seq": [
      "c1",
      "c2",
      "c3",
      "c4",
      "c5",
      "c6",
      "c7"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a2_shop.json",
  "_liveHash": "a1fa80ff"
}
```
