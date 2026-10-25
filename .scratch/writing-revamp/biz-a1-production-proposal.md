# biz_a1_production — imported from data/events/biz_a1_production.json

```json
{
  "id": "biz_a1_production",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "bizA1ProductionSeen",
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
          "text": "James has cleared the second bench. On it: a scale, a tray of time ore, and his phone, open on BizBrief. Archie is leaning in the doorway, eating crisps."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"If I am to make the goods, someone has to tell me which goods. As with everything these days, there's an app for it,\" James says with exasperation."
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"In the BizBrief app, open the Staff tab. Put me in Production. After that I work throughout the day, the way Owen works the veins.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Every recipe I can craft has a target. Set a target per item in the Manage tab, and I keep that many in stock and not one more. Raise it and I make more. Leave it at nothing and I sit on my hands.\""
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"'Cover contract needs' means I also make whatever the open orders still want, on top of the target. Turn it on and I'll craft to cover any contracts you've taken on - provided it's Life or Time.\""
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"I work from the business's ore. No ore, no crafting. It's on you and Owen to ensure I have ore to craft with.\""
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Which is why I found him something to make. Five pearls a week. The offer is on BizBrief.\""
        },
        {
          "key": "c8",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Take it, put James on pearl production, and make sure Owen keeps the ore coming. One full week, all five handed over. Then I'll show you the good bit.\""
        },
        {
          "key": "c9",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"I suppose we'd better get on with it.\""
        },
        {
          "key": "c10",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "James sets the hourglass beside the scale and starts weighing out the first batch."
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
      ]
    }
  },
  "_liveSource": "biz_a1_production.json",
  "_liveHash": "30b1aa8f"
}
```
