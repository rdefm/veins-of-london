// Node test for tools/quest-editor.html's JSON parser + save-splice logic.
// Run with: node tools/test_quest_editor.js
//
// Extracts the pure parser functions straight out of the shipped HTML file
// (between the two comment markers below) so the tests always exercise the
// exact code the browser runs, not a hand-copied duplicate.

const fs = require("fs");
const path = require("path");
const assert = require("assert");

const htmlPath = path.join(__dirname, "quest-editor.html");
const html = fs.readFileSync(htmlPath, "utf-8");

const startMarker = "/* ---------- Minimal JSON parser with source-offset tracking ---------- */";
const endMarker = "/* ---------- App state ---------- */";
const startIdx = html.indexOf(startMarker);
const endIdx = html.indexOf(endMarker);
assert(startIdx !== -1 && endIdx !== -1, "could not locate parser markers in quest-editor.html");

const parserSource = html.slice(startIdx, endIdx);
const loaded = new Function(parserSource + "\nreturn { parseJSONWithPositions, nodeGet, nodeToPlain, applyEdits };")();
const { parseJSONWithPositions, nodeGet, nodeToPlain, applyEdits } = loaded;

// Same extraction trick for the ticket-02 "New quest builder" section. Its
// pure functions (validateNewQuestId, buildQuestObject, normProse) close
// over a `state` identifier for the collision check, so the factory takes
// one and returns it bound — the DOM-touching functions in the same block
// (renderBuilder etc.) are defined but never invoked here.
const builderStartMarker = "/* ---------- New quest builder ---------- */";
const builderEndMarker = "/* ---------- Save ---------- */";
const bStart = html.indexOf(builderStartMarker);
const bEnd = html.indexOf(builderEndMarker);
assert(bStart !== -1 && bEnd !== -1, "could not locate new-quest-builder markers in quest-editor.html");
const builderSource = html.slice(bStart, bEnd);
const builderFactory = new Function(
  "state",
  builderSource +
    "\nreturn { validateNewQuestId, buildQuestObject, normProse, defaultCard, defaultChoice, CARD_TYPES };"
);
function loadBuilder(files) {
  return builderFactory({ files });
}

let passed = 0;

function test(name, fn) {
  try {
    fn();
    passed++;
    console.log("ok - " + name);
  } catch (err) {
    console.error("FAIL - " + name);
    console.error(err);
    process.exitCode = 1;
  }
}

const eventsDir = path.join(__dirname, "..", "data", "events");
const files = fs.readdirSync(eventsDir).filter((f) => f.endsWith(".json"));
assert(files.length > 0, "expected quest fixtures under data/events/");

test("parses every quest file and round-trips to the same plain value as JSON.parse", () => {
  for (const f of files) {
    const raw = fs.readFileSync(path.join(eventsDir, f), "utf-8");
    const root = parseJSONWithPositions(raw);
    const plain = nodeToPlain(root);
    const expected = JSON.parse(raw);
    assert.deepStrictEqual(plain, expected, f + ": nodeToPlain(root) should equal JSON.parse(raw)");
  }
});

test("zero edits splice returns the byte-identical original text", () => {
  for (const f of files) {
    const raw = fs.readFileSync(path.join(eventsDir, f), "utf-8");
    const out = applyEdits(raw, []);
    assert.strictEqual(out, raw, f + ": no-op splice must not change the file");
  }
});

test("editing a single narration card's text changes only that field", () => {
  const f = "busker_greenwich.json";
  const raw = fs.readFileSync(path.join(eventsDir, f), "utf-8");
  const root = parseJSONWithPositions(raw);
  const cards = nodeGet(root, "cards");
  const firstCardText = nodeGet(cards.items[0], "text");

  const newValue = "REPLACED NARRATION TEXT";
  const edited = applyEdits(raw, [{ start: firstCardText.start, end: firstCardText.end, text: JSON.stringify(newValue) }]);

  const editedParsed = JSON.parse(edited);
  const originalParsed = JSON.parse(raw);

  assert.strictEqual(editedParsed.cards[0].text, newValue);
  // Everything else must be untouched, including key order.
  editedParsed.cards[0].text = originalParsed.cards[0].text;
  assert.deepStrictEqual(editedParsed, originalParsed);
  assert.deepStrictEqual(Object.keys(editedParsed), Object.keys(originalParsed));
  assert.deepStrictEqual(Object.keys(editedParsed.cards[0]), Object.keys(originalParsed.cards[0]));
});

test("editing a choice's label and result_text leaves effects/deck/on_complete untouched", () => {
  const f = "col_a1_closer.json";
  const raw = fs.readFileSync(path.join(eventsDir, f), "utf-8");
  const root = parseJSONWithPositions(raw);
  const cards = nodeGet(root, "cards");
  const choiceCard = cards.items.find((c) => nodeGet(c, "choices"));
  assert(choiceCard, f + " fixture must contain a choice card");
  const choices = nodeGet(choiceCard, "choices");
  const firstChoice = choices.items[0];
  const labelNode = nodeGet(firstChoice, "label");
  const resultTextNode = nodeGet(firstChoice, "result_text");

  const newLabel = "EDITED LABEL";
  const newResult = "EDITED RESULT TEXT";
  const edited = applyEdits(raw, [
    { start: labelNode.start, end: labelNode.end, text: JSON.stringify(newLabel) },
    { start: resultTextNode.start, end: resultTextNode.end, text: JSON.stringify(newResult) },
  ]);

  const editedParsed = JSON.parse(edited);
  const originalParsed = JSON.parse(raw);
  const editedFirstChoice = editedParsed.cards.find((c) => c.choices).choices[0];
  const originalFirstChoice = originalParsed.cards.find((c) => c.choices).choices[0];

  assert.strictEqual(editedFirstChoice.label, newLabel);
  assert.strictEqual(editedFirstChoice.result_text, newResult);
  assert.deepStrictEqual(editedFirstChoice.effects, originalFirstChoice.effects);
  assert.deepStrictEqual(editedParsed.on_complete, originalParsed.on_complete);
  assert.deepStrictEqual(editedParsed.deck, originalParsed.deck);
});

test("string escaping and unicode round-trip through JSON.stringify like the source file", () => {
  const raw = fs.readFileSync(path.join(eventsDir, "city_suit.json"), "utf-8");
  const root = parseJSONWithPositions(raw);
  const cards = nodeGet(root, "cards");
  const speakerCard = cards.items.find((c) => nodeGet(c, "type").value === "speaker");
  const textNode = nodeGet(speakerCard, "text");
  assert(textNode.value.includes("—"), "fixture should contain an em dash to exercise unicode passthrough");

  const withQuotesAndUnicode = 'He says "quite so" — £200, no less.';
  const edited = applyEdits(raw, [{ start: textNode.start, end: textNode.end, text: JSON.stringify(withQuotesAndUnicode) }]);
  const editedParsed = JSON.parse(edited);
  const editedSpeakerCard = editedParsed.cards.find((c) => c.type === "speaker");
  assert.strictEqual(editedSpeakerCard.text, withQuotesAndUnicode);
});

/* ---------- Author-intent notes sidecar (ticket 03) ---------- */

const notesStartMarker = "/* ---------- Author-intent notes sidecar (ticket 03) ---------- */";
const notesEndMarker = "/* ---------- New quest builder ---------- */";
const nStart = html.indexOf(notesStartMarker);
const nEnd = html.indexOf(notesEndMarker);
assert(nStart !== -1 && nEnd !== -1, "could not locate notes-sidecar markers in quest-editor.html");
const notesSource = html.slice(nStart, nEnd);
const { notesFileName } = new Function(notesSource + "\nreturn { notesFileName };")();

test("notesFileName keys the sidecar to the quest id with a .notes.md suffix", () => {
  assert.strictEqual(notesFileName("camden_new_lead"), "camden_new_lead.notes.md");
  assert.strictEqual(notesFileName("col_a1_intro"), "col_a1_intro.notes.md");
});

test("every real event id maps to a distinct sidecar filename (no collisions across ids)", () => {
  const ids = files.map((f) => f.replace(/\.json$/, ""));
  const names = new Set(ids.map(notesFileName));
  assert.strictEqual(names.size, ids.length, "sidecar filenames must be unique per quest id");
});

/* ---------- New quest builder (ticket 02) ---------- */

test("card type dropdown roster matches ticket 02 exactly", () => {
  assert.deepStrictEqual(loadBuilder([]).CARD_TYPES, ["narration", "speaker", "choice", "resolution", "craft"]);
});

test("validateNewQuestId rejects blank/non-snake_case/collisions, accepts a fresh id", () => {
  const { validateNewQuestId } = loadBuilder([{ name: "busker_greenwich.json" }]);
  assert.notStrictEqual(validateNewQuestId(""), "");
  assert.notStrictEqual(validateNewQuestId("CamelCase"), "");
  assert.notStrictEqual(validateNewQuestId("trailing_"), "");
  assert.notStrictEqual(validateNewQuestId("_leading"), "");
  assert.notStrictEqual(validateNewQuestId("double__underscore"), "");
  assert.notStrictEqual(validateNewQuestId("busker_greenwich"), "", "must reject a filename collision");
  assert.strictEqual(validateNewQuestId("camden_new_lead"), "");
});

test("every real event id under data/events/ validates as a legal, collision-free new id", () => {
  const { validateNewQuestId } = loadBuilder([]); // no existing files -> only checks the id shape itself
  for (const f of files) {
    const id = f.replace(/\.json$/, "");
    assert.strictEqual(validateNewQuestId(id), "", id + " (a real event id) should be valid snake_case");
  }
});

test("buildQuestObject matches the real event schema: id/cards/on_complete, effects:[], no deck key", () => {
  const { buildQuestObject } = loadBuilder([]);
  const obj = buildQuestObject({
    id: "test_new_quest",
    cards: [
      { type: "narration", label: "Somewhere", speaker: "", text: "It happens.", choices: [] },
      {
        type: "choice",
        label: "",
        speaker: "",
        text: "Pick one.",
        choices: [
          { label: "Option A", result_text: "A happens." },
          { label: "", result_text: "" },
        ],
      },
    ],
  });

  assert.deepStrictEqual(Object.keys(obj), ["id", "cards", "on_complete"]);
  assert.strictEqual(obj.id, "test_new_quest");
  assert(!("deck" in obj), "a new quest must never carry a deck key (ticket 02)");

  assert.deepStrictEqual(Object.keys(obj.cards[0]), ["type", "label", "speaker", "text"]);
  assert.strictEqual(obj.cards[0].label, "Somewhere");
  assert.strictEqual(obj.cards[0].speaker, null, "a blank prose field is written as null, not an empty string");

  assert.deepStrictEqual(Object.keys(obj.cards[1]), ["type", "label", "speaker", "text", "choices"]);
  assert.strictEqual(obj.cards[1].choices[0].label, "Option A");
  assert.deepStrictEqual(obj.cards[1].choices[0].effects, []);
  assert.strictEqual(obj.cards[1].choices[1].label, null);
  assert.strictEqual(obj.cards[1].choices[1].result_text, null);

  assert(
    Array.isArray(obj.on_complete) && obj.on_complete.some((op) => op.op === "set_screen"),
    "on_complete needs a navigating op or GameData._validate_events() rejects the file once registered"
  );
});

test("normProse trims prose and blanks to null", () => {
  const { normProse } = loadBuilder([]);
  assert.strictEqual(normProse("  hi  "), "hi");
  assert.strictEqual(normProse(""), null);
  assert.strictEqual(normProse("   "), null);
  assert.strictEqual(normProse(undefined), null);
});

test("a freshly built quest's saved JSON round-trips through the tool's own parser", () => {
  const { buildQuestObject } = loadBuilder([]);
  const obj = buildQuestObject({
    id: "smoke_test_quest",
    cards: [{ type: "narration", label: "X", speaker: "", text: "Y", choices: [] }],
  });
  const text = JSON.stringify(obj, null, 2) + "\n";
  const root = parseJSONWithPositions(text);
  assert.deepStrictEqual(nodeToPlain(root), JSON.parse(text));
  assert.deepStrictEqual(nodeToPlain(root), obj);
});

console.log(passed + " test(s) passed");
