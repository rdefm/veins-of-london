# prologue_archie_sells_pearls — imported from data/events/prologue_archie_sells_pearls.json

```json
{
  "id": "prologue_archie_sells_pearls",
  "on_complete": [
    {
      "op": "add_item",
      "item": "timePearl",
      "qty": -1
    },
    {
      "op": "add",
      "path": "player.cash",
      "value": 120
    },
    {
      "op": "add_item",
      "item": "timePearl",
      "qty": 2,
      "equip": true
    },
    {
      "op": "set_flag",
      "flag": "archieSoldPearls",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "canSellConsumables",
      "value": true
    },
    {
      "op": "relation",
      "contact": "archie",
      "value": 5
    },
    {
      "op": "add_ore",
      "type": "time",
      "qty": 20
    },
    {
      "op": "set_flag",
      "flag": "homeRaidEventPending",
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
          "label": "Stratford — a car park",
          "speaker": null,
          "text": "The buyer turns the pearl over once, checks something on his phone, and pays. A woman walks past with a Lidl bag and doesn't look up."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"That's it. That's the whole deal.\" He counts £120 into your hand. \"Most of them are that boring. Don't get used to it.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "He holds two more pearls out at arm's length, eyes streaming. \"Keep 'em on you, just in case.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "text": "\"Listen, I did a favour for a guy, he gave me a Time vein as payment. It's only a small one, but with my allergy I've not been able to do much with it.\"",
          "speaker": "Archie"
        },
        {
          "key": "c5",
          "type": "speaker",
          "text": "\"I don't want to sell it; I want you to manage it, and craft time pearls with it. I'll then line up the buyers, and we split everything 50/50.\"",
          "speaker": "Archie"
        },
        {
          "key": "c6",
          "type": "speaker",
          "text": "\"Let me check on the vein, then I'll bring you there tomorrow, show you the ropes.\"",
          "speaker": "Archie"
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "on_complete",
      "cards"
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
      ]
    }
  },
  "_liveSource": "prologue_archie_sells_pearls.json",
  "_liveHash": "703c50e5"
}
```
