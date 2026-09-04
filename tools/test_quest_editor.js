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

console.log(passed + " test(s) passed");
