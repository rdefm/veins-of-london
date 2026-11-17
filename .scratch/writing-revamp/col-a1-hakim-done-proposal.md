# col_a1_hakim_done — imported from data/events/col_a1_hakim_done.json

```json
{
  "id": "col_a1_hakim_done",
  "on_complete": [
    {
      "op": "sell_contact_vein_to_faction",
      "veinIdStatePath": "collective.hakimVeinId",
      "faction": "collective",
      "price": 0
    },
    {
      "op": "add",
      "path": "player.cash",
      "value": 120
    },
    {
      "op": "faction_relation",
      "faction": "collective",
      "value": 10
    },
    {
      "op": "set_flag",
      "flag": "colA1HakimThreadDone",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "hakimIntelUnlocked",
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
          "label": null,
          "speaker": null,
          "text": "The yard looks exactly the same. The vein does not. It reads as taking, and rising."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Hakim",
          "text": "\"That's better than my uncle had it.\" He says this and then looks slightly stricken, as though he has been disloyal."
        },
        {
          "key": "c3",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "He pays you. It is not very much and he has clearly thought about the amount, and there is no version of refusing it that isn't worse."
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Hakim",
          "text": "\"Listen. I hear things. Not — I'm not anybody, I just stand here and people talk. If I hear about ground going, round here, I'll text you. That's not me paying you back, that's just — I'll text you.\""
        },
        {
          "key": "c5",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You have made a newsagent's yard marginally more productive. Somewhere in the calculation of what you have spent your week on, this is either the least or the most important thing, and it won't be clear which for some time."
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
      ]
    },
    "seq": [
      "c1",
      "c2",
      "c3",
      "c4",
      "c5"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a1_hakim_done.json",
  "_liveHash": "beb43b4a"
}
```
