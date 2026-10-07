# The Ticker — The Economy (draft v1)

Status: DRAFT for review. Nothing wired into `data/barometer.json` yet.
PROSE-REVIEW: all text below is new.

Scope: economic barometer states (stable, boom, recession, crisis, inflation). Headlines x2, deck, body, per state. Author hardcoded per section.

## Columnist: Hugh Marchbanks

- **Byline:** `HUGH MARCHBANKS · THE ECONOMY`
- **Author note (shown under byline):** *Hugh has covered the markets for the Ticker for thirty-one years and is owed several apologies.*
- **Personality:** Senior markets correspondent. Dry, weary, faintly pompous. Treats every state of the economy as confirming something he said earlier. Precise about figures, scornful of hype. Calls disaster "a correction", treats small indignities (a dear sandwich, a late train) as grave. Never panics, only sighs. Foil to Pip: she is cheerful and oblivious, he is gloomy and certain.
- **Register:** reported business-page prose. Lede says what the market did. Second paragraph says what it means for readers who trade or hold stock. Personality lives in word choice, quoted sources and one dry detail per piece.
- **Voice rules:**
  - Third person. No "I". Self-reference only as "this column" / "this correspondent", sparingly.
  - Says "orichalchum" in print; "calc" is street slang, quoted with distaste when someone else uses it.
  - Recurring source: "a man at the Exchange" (never named). Quotes and advice, at most once per piece.
  - Recurring details, reported as fact: the sandwich price, the café on Threadneedle Street, "as this column warned in the spring". At most one per piece.
  - Menace reported flatly, never denied. A crash is "unfortunate".
  - One joke per beat. No exclamation marks, no addressing the player, no fourth wall (addresses "readers" and "traders").
  - Body copy is voice only. Mechanics live in the "WHAT CHANGES IN LONDON" panel. Hint at the effect in-world, never quote numbers.

---

## Stable — "Markets function normally. Ore prices steady."

Effects: none.

**Headlines**
1. Markets steady; this column has nothing to add
2. Ore prices hold as London's traders find little to dispute

**Deck:** An unremarkable day on the floor, which this correspondent will take.

**Body:**
Orichalchum traded within a narrow band today and closed where it opened. Volumes were ordinary, tempers were ordinary, and the one trader seen shouting was shouting about a parking fine. A man at the Exchange described conditions as "fine", then looked faintly unwell at having said so.

Readers need do nothing. Holdings may be left alone, quotes need not be checked more than twice, and lunch may be taken at lunchtime. Steadiness of this kind rarely lasts, but this column has been wrong about that before, and hopes to be again.

---

## Economic Boom — "Demand up. Buyers flush with cash."

Effects: demand for all goods +10%, mugging -5 pts.

**Headlines**
1. Buyers flush, demand strong, Exchange in unfamiliar good humour
2. Boom lifts London's ore trade; caution advised, and ignored

**Deck:** Cash is plentiful and buyers are spending it, which this correspondent finds suspicious.

**Body:**
Demand for orichalchum and its products rose across the board today, with buyers arriving at the Exchange carrying more cash than sense. Prices firmed by the hour. Even the streets around the Bank were noticeably calmer, there being less need to push what people are happy to pay for.

Traders should sell into strength while it lasts. A man at the Exchange called the mood "sustainable", which in this column's experience is the word used about a month before it is not. Readers who sold early are advised to enjoy it quietly.

---

## Recession — "Buyers tighter. Prices softer."

Effects: demand for all goods -10%, mugging +5 pts.

**Headlines**
1. Recession deepens; buyers hold their purses, ore prices soften
2. As this column warned in the spring, demand has gone

**Deck:** Buyers are tight, prices are soft, and the streets are less patient than the markets.

**Body:**
Orichalchum fell again today on thin trade, with buyers arriving late, asking questions and leaving without buying. Prices softened across nearly every line. Traders described conditions as "challenging", a word this column has learned to read as "grim".

The cost is not confined to the floor. Where money is short, people take other people's, and incidents of street theft are up on the week. Readers carrying stock should price for patience and carry less of it in public. The warning was given in the spring. It is repeated now at no extra charge.

---

## Financial Crisis — "Market collapse. Some ore types in desperate demand."

Effects: mugging +12 pts, item demand for `beALady` 1.0.

**Headlines**
1. Markets suffer "a correction"; Exchange doors remain, for now, open
2. Financial crisis grips London; one product almost sells out entirely

**Deck:** The market has fallen and the streets have noticed. One item alone is in demand.

**Body:**
The market suffered what the Exchange is calling a correction, and what everyone outside it is calling something else. Readers may be heartened to hear that quotes only fell in the morning, and dismayed to hear they plumetted after lunch. A man at the Exchange confirmed that "there will be a statement", and was not seen again.

Desperate buyers are paying nearly anything for beALady, whose stock is gone from most shelves. The streets have grown rougher alongside, with muggings sharply up and fewer people willing to walk home with anything worth taking. Readers are advised to hold what they have, keep it close and avoid the Bank after dark. This is unfortunate.

---

## High Inflation — "Everything costs more. Daily costs up."

Effects: daily costs +30%, demand for all goods +5%.

**Headlines**
1. Prices rise again; the sandwich at Threadneedle Street now requires thought
2. Inflation bites London: everything costs more, orichalchum included

**Deck:** Day-to-day costs are climbing fast, though buyers are, perversely, still buying.

**Body:**
Prices rose again across London today, a movement this correspondent can confirm from the sandwich at the café on Threadneedle Street, which now costs what a full lunch used to. Orichalchum moved with the tide, and buyers kept buying, on the theory that anything bought today is cheaper than it will be tomorrow.

The daily cost of living is the real wound. Rent, fuel and food are all climbing faster than anyone's income, and the gap is paid for out of stock or savings. Traders may wish to sell a little more often than they otherwise would. 

---

## Open questions for review

1. Crisis body names `beALady` as product. Better as in-world product name in prose, or vaguer ("one product")? Check against ore/consumable naming in `data/`.
2. Gag distribution: Exchange source in stable/boom/crisis/inflation, "warned" in recession, sandwich in inflation. Fine, or spread differently?
3. Does Hugh sound too close to Pip in the "readers should do X" closing paragraphs?
4. "At no extra charge" / "unfortunate" signature closers: keep as recurring tics?
