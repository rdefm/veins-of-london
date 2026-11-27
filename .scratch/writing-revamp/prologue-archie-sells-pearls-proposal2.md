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
          "label": null,
          "speaker": null,
          "text": "The buyer arrives, and gives Archie a nod. ",
          "observe": "archie_sells_pearls_obs2"
        },
        {
          "key": "c6",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "They turn the pearl over once, check something on their phone, and pay. A woman walks past with a plastic bag and doesn't look up."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"That's it. Job done, no biggie.\" He counts £120 into your hand. \"Most of them are that boring, luckily.\"",
          "observe": "archie_sells_pearls_obs3"
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
          "label": null,
          "speaker": null,
          "text": "With that, Archie strolls off with a smile, humming to himself."
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
  "_liveHash": "a8444a84",
  "observations": {
    "archie_sells_pearls_obs_1": {
      "blocks": {
        "life": {
          "tiers": [
            {
              "base": 0.25,
              "text": "Archie's eyes keep moving, and his smile was forced, like he's trying to convince himself as well as you that everything's ok. He's still a bit nervous after the chicken shop incident."
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
              "text": "There's a sense of humdrum calm, but also some nervousness in the air."
            }
          ],
          "miss": "Archie seems happy to see you."
        }
      }
    },
    "archie_sells_pearls_obs2": {
      "blocks": {
        "physics": {
          "tiers": [
            {
              "base": 0.25,
              "text": "One person, relaxed shoulders, casual nod to Archie. This isn't their first purchase from Archie, and won't be their last."
            },
            {
              "base": 0.55,
              "text": "He's alone, as far as you can tell."
            }
          ],
          "miss": "He gave you a nod. Should you say hi, or just nod back?"
        },
        "emotion": {
          "tiers": [
            {
              "base": 0.25,
              "text": "This feels very much like a chore to them, like picking up milk on the way home. You don't feel like trouble's brewing."
            },
            {
              "base": 0.55,
              "text": "They seem relaxed, almost disinterested."
            }
          ],
          "miss": "They seem almost disinterested. Are they planning something? Do they not like you? Maybe you should have tried to give more of a cool upwards-nod when they arrived."
        }
      }
    },
    "archie_sells_pearls_obs3": {
      "blocks": {
        "emotion": {
          "tiers": [
            {
              "base": 0.25,
              "text": "Archie is visibly more relaxed. Having a second sale go smoothly has done wonders for his nerves."
            },
            {
              "base": 0.55,
              "text": "You only now realise you had a feeling of tension, which is gone now after 2 smooth sales."
            }
          ],
          "miss": "Archie seems happy after the sale. Can't blame him - a couple of quid in your pocket is never a bad thing."
        }
      }
    }
  }
}
```
