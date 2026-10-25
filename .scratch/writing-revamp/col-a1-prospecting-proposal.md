# col_a1_prospecting — imported from data/events/col_a1_prospecting.json

```json
{
  "id": "col_a1_prospecting",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "colA1ProspectingTaught",
      "value": true
    },
    {
      "op": "start_event",
      "event": "col_a1_seeding"
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
          "label": "Shoreditch - a service yard behind a coffee place",
          "speaker": null,
          "text": "Des has brought you to the least interesting place in Shoreditch and is looking at it with open enthusiasm."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Everyone looks for the dramatic bit. Cracked stone, old church, that sort of thing. Mostly what you want is somewhere that's been left alone a long time and had something happen to it once.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Prospecting mainly takes time, and a walk about. You'll turn up a patch or you won't. What you turn up depends on the ground round here and on how much of this you've done before - that's it, that's the whole system.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Patches come in grades. The higher the grade, the more room there is for a vein to grow, and create more calc. Barren ones you leave; nothing takes in them.\""
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Different parts of London tend to skew more to a specific type. Round here it's whatever's going. Whitechapel's emotion, mostly. The City's fate, which probably isn't much of a surprise.\""
        },
        {
          "key": "c6",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "He does not tell you which of these facts is the important one. You get the sense this is on purpose."
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Go on. Have a look about. I'll be here.\""
        },
        {
          "key": "c8",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You spend the better part of an hour looking at brickwork with a seriousness that would embarrass you if anyone you knew walked past. Somewhere under all of it, London is doing what it does."
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
      ]
    }
  },
  "_liveSource": "col_a1_prospecting.json",
  "_liveHash": "176cf1d8"
}
```
