# col_a1_intro — imported from data/events/col_a1_intro.json

```json
{
  "id": "col_a1_intro",
  "on_complete": [
    {
      "op": "unlock_contact",
      "contact": "des"
    },
    {
      "op": "set_flag",
      "flag": "colA1DesMet",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "collectiveLaneUnlocked",
      "value": true
    },
    {
      "op": "faction_relation",
      "faction": "collective",
      "value": 5
    },
    {
      "op": "set_flag",
      "flag": "colA1Stage",
      "value": "tuition"
    },
    {
      "op": "start_event",
      "event": "col_a1_prospecting"
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
          "label": "Shoreditch",
          "speaker": null,
          "text": "The footpath shines, wet from the recent rain. Archie is standing outside it with the expression of a man who has already had this conversation in his head and did not enjoy it."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"One vein. That's what we've got. One vein, which is nice, but it's not enough.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"One vein isn't a business, it's a hobby with rent. You want more, you have to go and find ground, and seed it, and I can't teach you that because I've never done it. I shift stock. I don't dig.\""
        },
        {
          "key": "c4",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "He fishes his keys out - a fat bunch, a Millennium Falcon keyring worn smooth at the edges - and lets you both into the lock-up."
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"So I called a bloke. He's good. He's the best I know at it, actually.\" A pause exactly long enough to be noticeable. \"He'll teach you. Then he'll go home.\""
        },
        {
          "key": "c6",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "The man who comes in is in his forties, unhurried, with a canvas bag over one shoulder and the air of somebody who has never once been late but has often waited. He looks genuinely pleased to be here, which nobody else in this story has managed."
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Desmond. Des. You're the one with the Whitechapel time vein.\" He says it like a fact he's glad about rather than one he's checking."
        },
        {
          "key": "c8",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Right. Des knows ground, I know buyers, and between us you might make rent. That's the arrangement.\""
        },
        {
          "key": "c9",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Archie does not offer Des tea. Des does not appear to expect any. There is a silence with some history in it, and then Archie remembers somewhere else he needs to be."
        },
        {
          "key": "c10",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"He's all right, Archie. Bit of a transaction, but he's all right.\" He's already unpacking the bag. \"Right. Ground.\""
        },
        {
          "key": "c11",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "You have a teacher. Neither of you has mentioned money, which, given your money troubles, is both a relief and slightly unsettling."
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
  "_liveSource": "col_a1_intro.json",
  "_liveHash": "b67d3409"
}
```
