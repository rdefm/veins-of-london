# biz_a1_partnership — imported from data/events/biz_a1_partnership.json

```json
{
  "id": "biz_a1_partnership",
  "on_complete": [
    {
      "op": "recruit_contact",
      "contact": "james"
    },
    {
      "op": "set_james_crafting_skill"
    },
    {
      "op": "set_flag",
      "flag": "bizJamesProductionRole",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "bizA1JamesJoined",
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
          "text": "Owen is at the bench with a cutting board of his own, labelled in James's handwriting. He looks up, then back down, very quickly."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"His cultivation skills are coming along nicely,\" James says to you quietly. \"Slower than a gifted student, faster than I told him he would. I did not tell him that.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"And you have built a workshop. With your own money, in your own home, where you have to look at it every morning. That is what I meant by serious.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"So we've proven we can find and deliver contracts, and we've put in our own money. You said that's what you need for a full partnership.\""
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"I know what I said.\""
        },
        {
          "key": "c6",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "He turns the hourglass over and watches it run out before he answers."
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Very well. I join properly. I stop taking a share for nothing and start making goods. Give me ore and a target in Production and I will meet it.\""
        },
        {
          "key": "c8",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"My own business and clients remain mine. I will do their work on my own time. If either of you so much as offers them a discount, I will know.\""
        },
        {
          "key": "c9",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Full partner. Look at that. I'd hug you, but.\""
        },
        {
          "key": "c10",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"You would not.\""
        },
        {
          "key": "c11",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "James writes his own name on Owen's board, one line above Owen's. It is the closest thing to a contract anyone is going to get."
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
      ]
    }
  },
  "_liveSource": "biz_a1_partnership.json",
  "_liveHash": "d699e426"
}
```
