# col_a1_hub — imported from data/events/col_a1_hub.json

```json
{
  "id": "col_a1_hub",
  "on_complete": [
    {
      "op": "unlock_contact",
      "contact": "nadia"
    },
    {
      "op": "unlock_contact",
      "contact": "hakim"
    },
    {
      "op": "set_flag",
      "flag": "colA1DesThreadActive",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "colA1HubReached",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "colA1Stage",
      "value": "hub"
    },
    {
      "op": "set_flag",
      "flag": "colA1ArchiePryAvailable",
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
          "text": "Des has bought you a coffee you didn't ask for and won't let you pay for, which is becoming a pattern."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Right. You've had a the better part of a day with me giving you things. That's fine, that's how it works, but it works both ways or it doesn't work.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Three things. Take them in whatever order suits. Or don't - I'm not your governor, nobody is.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"One's mine. We've got people who can seed but haven't got ground. I need a fate patch and a physics patch, decent ones, and I need them left alone until I say. You find them, I'll do the rest.\""
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Two's Nadia. Hackney. She moves more calc in a week than the rest of us see in a month and she's short on something. Go and be useful to her; she'll tell you how.\""
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"Three's Hakim. Newsagent, Whitechapel Road. He's got a vein in his yard that's on its way out and he hasn't got the hands for it. That one's not a favour to me, it's a favour to him, and he'll be embarrassed about it, so don't make it worse.\""
        },
        {
          "key": "c7",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "He writes two phone numbers on the back of a receipt, which is the only record of any of this that will ever exist."
        },
        {
          "key": "c8",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Three names, three problems, no deadline and no order. The Collective, as far as you can tell, is a group of people who have each independently decided to be helpful and have never once discussed it."
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
  "_liveSource": "col_a1_hub.json",
  "_liveHash": "31326c20"
}
```
