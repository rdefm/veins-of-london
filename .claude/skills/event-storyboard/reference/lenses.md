# The three lenses

Work through them in order. Each one can veto the one before.

## 1. Producer — what the story needs seen, and what it costs

- **Beat map first.** One line per card: what changes for the player here (new information, a shift in power, a decision, a payoff). Cards that change nothing visible are holds.
- **What is this event for?** Name its single dramatic job in one sentence (the board's `logline`). Every shot should serve it. If a shot only illustrates a noun in the text, cut it.
- **Budget.** Each shot costs a generation session, QA and cleanup. Rough guide: 1 shot per 2–4 cards; a 2–4 card ambient event usually earns 1 shot; a quest set-piece earns more. More than 1 shot per 2 cards needs a reason written in `why`. Under-shooting a big moment is as much a failure as over-shooting a corridor conversation.
- **Spend on the turn.** The shot most worth making is the one where the event's meaning lands: the reveal, the decision, the cost. Put the strongest framing there, not on card 1.
- **Reuse is free.** Returning to an earlier shot (same file at a later card) costs nothing and reads as "back to the conversation". Prefer it to a near-duplicate new shot.
- **Series continuity.** A location, prop or character already drawn in a neighbouring event is canon. Match it, or flag it.

## 2. Director / DP — how the frame tells it

**Cut when** the visible situation changes enough to matter:
- location or time changes (always cut; usually a wider "establishing" frame);
- a decisive physical action (a door held open, a card slid across a desk, a weapon shown);
- a newly important prop or person enters;
- a power dynamic flips (who stands, who sits, who looks away);
- a reaction carries more than the line does.

**Hold when** the line is dialogue inside the same moment. A new speaker alone does not earn a cut. On a hold, check that the image still agrees with *every* card it covers. A still that shows someone mid-handshake can't hold through "then she leaves".

**Never reveal early.** The image sticks until the next shot, so don't show on card 3 what the text reveals on card 6.

**Shot grammar.** Vary it on purpose. Existing event art is almost all wide shots with a single small figure in a dense set. That's good for establishing; repeated, it flattens every event into the same picture. Use:
- WS / establishing: place, weather, scale. Usually the first shot of a location.
- MS (waist up): two people relating. Body language reads.
- MCU / CU: face and intent; use for the line that matters. Faces read at phone size only from MCU in.
- Insert: a hand, a prop, a phone screen with no legible text, a business card. Cheap to generate, high impact, great for payoffs.
- OTS (over-the-shoulder, from behind someone): confrontation, negotiation, being sized up.
- POV (the player's eyes): the player is being addressed directly, or something is being shown to them.
- Low / high angle: power. Looking up at someone gives them weight; looking down diminishes.

Across consecutive shots in one place, keep the **180° rule** (characters keep their screen sides) and a consistent light direction. Name both in the brief so the prompts carry them.

**The player.** The player picks their own sprite, so "you" stays faceless: POV, or seen from behind or partly in frame (a shoulder, a hand) with no identifying features. Flag it if the event's staging makes that impossible.

**The frozen instant.** A still is one moment. Pick the most pregnant one, just before or just after the action, not the middle of it. Say what is *unseen* (off-frame, behind a door, not yet arrived) as clearly as what is seen.

## 3. Game UI designer — the frame on the phone

- Frame: **390×544 portrait** at the baseline phone, centre-cropped to fill. The opaque text panel sits *below* the image, not over it. Small phones (≈375×667) crop the frame to near-square, so the top and bottom ~15% of a 2:3 source disappear. Tall phones show more.
- **Crop-safe zone:** faces, hands and the story prop sit in the central ~60% of height and ~80% of width. Sky, floor and set dressing go in the edges.
- **Read at a glance.** One focal subject, high contrast against its ground. The text is read in the panel below, and the image is taken in in under a second. Busy sets need a value break (light pool, silhouette) around the subject.
- **Continuity with the panel.** The speaker in the panel should be visible, or obviously present just off-frame (an OTS of them works), unless the cut is deliberately elsewhere (an insert, a reaction).
- **Choices.** On a choice card, the image must not pre-empt an option. Choice-result images are possible but need explicit JSON. Propose one only for a strongly divergent outcome, and mark it as a cost.
- **No baked text.** Signs, phones and paper show shapes, not words. Text belongs in the UI.
- **Mood:** grounded London colour (ui-vision §2): brick, shopfront paint, wet pavement, sodium and LED light. No neon, no fantasy glow. Calc (orichalchum) gold is the one warm accent, kept for calc.
