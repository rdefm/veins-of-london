# archie_motion — imported from data/events/archie_motion.json

```json
{
  "id": "archie_motion",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "archieMotionEventSeen",
      "value": true
    },
    {
      "op": "queue_pending_message",
      "contact": "james",
      "kind": "james_experiment",
      "text": "Overflow work, if you're capable of it. Come by."
    },
    {
      "op": "set_screen",
      "screen": "contacts"
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
          "label": "A message from Archie",
          "speaker": null,
          "text": "You've been moving product. It's working. Archie's text simply says: \"good output. call me.\""
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"So the consumables are going well. Got a buyer asking for more pearls and asking if there's anything else on offer. Which made me think — can you make anything else?\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"Not yet. James only taught me the pearls.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Yeah. Right. See, James knows how to make about forty different things and he's sitting on all of it. Which is his prerogative, obviously. But I'm thinking — have you got any sort of relationship with him yet? Because it might be worth asking.\""
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"Asking him to teach me more?\""
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Gently. James doesn't respond well to being asked for things directly. Try framing it as being useful to him. Which, actually, you could be — if he's got orders he can't fill, you could take the overflow. Might be the angle.\""
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Worth a try anyway. He's the only craftsman I know who isn't either retired or in prison, so options are limited.\""
        },
        {
          "key": "c8",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "He hangs up before you can ask anything else. You look up James's address in your phone."
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
    },
    "seq": [
      "c1",
      "c2",
      "c3",
      "c4",
      "c5",
      "c6",
      "c7",
      "c8"
    ],
    "elseKeys": []
  },
  "_liveSource": "archie_motion.json",
  "_liveHash": "5fdff4ca"
}
```
