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
          "text": "Archie is there already, an easy smile on his lips. He gives you a nod, then his eyes go back to scanning the car park.",
          "observe": "archie_sells_pearls_obs_1"
        },
        {
          "key": "c5",
          "type": "narration",
          "text": "The buyer arrives, turns the pearl over once, checks something on his phone, and pays. A woman walks past with a Lidl bag and doesn't look up."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"That's it. Job done, no biggie.\" He counts £120 into your hand. \"Most of them are that boring, luckily.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "He holds two more pearls out at arm's length, eyes streaming. \"Take these, just in case. Keep 'em on you, so you've got them when you need them.\""
        },
        {
          "key": "c4",
          "type": "narration",
          "text": "What that, Archie strolls off with a smile, humming to himself."
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
    },
    "seq": [
      "c1",
      "c2",
      "c3"
    ],
    "elseKeys": []
  },
  "_liveSource": "prologue_archie_sells_pearls.json",
  "_liveHash": "1311956e",
  "observations": {
    "archie_sells_pearls_obs_1": {
      "blocks": {
        "life": {
          "tiers": [
            {
              "base": 0.25,
              "text": "Archie's smile was forced. His eyes are never resting; he's nervous without a Time Pearl or some ace up his sleeve."
            },
            {
              "base": 0.55,
              "text": "Archie's smile came and went instantly. His eyes keep roving the car park; you're unsure if he's worried, nervous, or excited."
            }
          ],
          "miss": "Archie's got an energy in his movements, and keeps running his hand through his hair. Maybe he's born with it. Maybe he had too many energy drinks."
        },
        "emotion": {
          "tiers": [
            {
              "base": 0.25,
              "text": "There's nervousness and excitement, but it's all coming from Archie. The rest of the car park is as lively as a pub at 10 in the morning."
            },
            {
              "base": 0.55,
              "text": "There's a sense of humdrum calm, but also some nervousness in th air."
            }
          ],
          "miss": "Archie seems happy to see you."
        }
      }
    }
  }
}
```
