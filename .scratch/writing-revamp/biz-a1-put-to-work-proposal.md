# biz_a1_put_to_work — imported from data/events/biz_a1_put_to_work.json

```json
{
  "id": "biz_a1_put_to_work",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "bizA1DelegationUnlocked",
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
          "text": "Archie has taken the end of James's bench, his phone propped against a jar of powder. James is pretending not to be annoyed; he's not doing a very good job."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Up to now you've run every order yourself. Mine it, craft it, hand it over. That's a job, not a business.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"The pearl order comes every week. Say yes once and it keeps coming. That's a recurring order.\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Now the clever bit. End of every stretch I check the stock against the orders you've accepted. I hand over whatever we have, chase the money. Anything you want kept, stash it before I come round.\""
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Owen mines, I craft. As long as you've set up the orders and told us what to do, we will sort it out without you having to micromanage.\""
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"So here's the test. Two recurring contracts, each running a full week with no help from you. Start whenever.\""
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Help means making the thing it asks for, tending any of Owen's veins, moving what it wants out of your stash, or buying the calc it wants. Do any of that and that week doesn't count.\""
        },
        {
          "key": "c8",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Everything else is yours. Other veins, other crafting, the Collective, whoever you're fighting this week. And if I buy calc for an order out of the pot, that's the business doing its job. Doesn't count against you.\""
        },
        {
          "key": "c9",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"If you've not taken a weekly ore order yet, six time or six life is still on BizBrief. Pick whichever you can keep up with.\""
        },
        {
          "key": "c10",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "James goes back to his bench. Archie puts his phone face down beside the hourglass and leaves it there."
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
  "_liveSource": "biz_a1_put_to_work.json",
  "_liveHash": "520a0514"
}
```
