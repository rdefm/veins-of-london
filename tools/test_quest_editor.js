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

// The option/event mechanics section both editors share; every extraction
// below prepends it, since the parser and builder sections call into it.
const sharedStartMarker = "/* ---------- Choice mechanics (shared) ---------- */";
const sharedEndMarker = "/* ---------- End choice mechanics ---------- */";
function sharedSection(source, label) {
  const s = source.indexOf(sharedStartMarker);
  const e = source.indexOf(sharedEndMarker);
  assert(s !== -1 && e !== -1, "could not locate shared mechanics markers in " + label);
  return source.slice(s, e + sharedEndMarker.length);
}
const sharedSource = sharedSection(html, "quest-editor.html");

const parserSource = html.slice(startIdx, endIdx);
const loaded = new Function(
  sharedSource +
    parserSource +
    "\nreturn { parseJSONWithPositions, nodeGet, nodeToPlain, applyEdits, formatJSON, objectEdits, collectModelEdits," +
    " optionToCheck, optionToPlain, setConditionKind, conditionKind, deepClone };"
)();
const {
  parseJSONWithPositions,
  nodeGet,
  nodeToPlain,
  applyEdits,
  formatJSON,
  objectEdits,
  collectModelEdits,
  optionToCheck,
  optionToPlain,
  setConditionKind,
  conditionKind,
  deepClone,
} = loaded;

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
  sharedSource +
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

/* ---------- Checks, gating, branches and timing (opening-choices 10) ---------- */

const mobilePath = path.join(__dirname, "quest-editor-mobile.html");
const mobileHtml = fs.readFileSync(mobilePath, "utf-8");
const bundleStartMarker = "/* ---------- Draft bundle ---------- */";
const bundleEndMarker = "/* ---------- State ---------- */";
const mbStart = mobileHtml.indexOf(bundleStartMarker);
const mbEnd = mobileHtml.indexOf(bundleEndMarker);
assert(mbStart !== -1 && mbEnd !== -1, "could not locate draft-bundle markers in quest-editor-mobile.html");
const mobile = new Function(
  sharedSection(mobileHtml, "quest-editor-mobile.html") +
    mobileHtml.slice(mbStart, mbEnd) +
    "\nreturn { draftFromParsed, buildBundle, defaultChoice };"
)();

// Every REFERENCE §3.9a/§3.9b field: option id, check with each mod type,
// min/max/show/attempts, success/fail outcomes with goto, requires with
// display + reason, plain-option goto, bySuccesses/perSuccess, event `at`.
const ALL_FIELDS_EVENT = {
  id: "all_fields_fixture",
  at: { block: "evening", advance: true },
  cards: [
    { type: "narration", label: "{today}", speaker: null, text: "It starts." },
    {
      type: "choice",
      label: null,
      speaker: null,
      text: "Pick one.",
      choices: [
        {
          label: "Talk him down",
          id: "talk",
          requires: { flag: "metJames", display: "disable", reason: "You don't know him yet." },
          effects: [{ op: "add", path: "player.cash", value: -5 }],
          check: {
            base: 0.4,
            mods: [
              { flag: "metJames", add: 0.1, label: "You know him" },
              { choice: { event: "intro", card: 3, option: "ask" }, add: 0.05, label: "You asked" },
              { choice: { event: "intro", card: 3, option: 1 }, add: -0.05, label: "You walked off" },
              { path: "player.level", perPoint: 0.02, above: 1, label: "Experience" },
              { relation: "james", atLeast: 2, add: 0.1, label: "He likes you" },
              { cash: { atLeast: 100 }, add: 0.05, label: "Flush" },
              { item: "knuckleduster", add: 0.05, label: "Held" },
              { item: "knuckleduster", equipped: true, add: 0.1, label: "Equipped" },
              { item: "timePearl", optional: true, consume: true, add: 0.2, label: "Pearl" },
            ],
            min: 0.1,
            max: 0.9,
            show: "hint",
            attempts: 2,
            perSuccess: [{ op: "add", path: "player.cash", value: 10 }],
          },
          success: { result_text: "He backs off.", effects: [], goto: 3 },
          fail: { result_text: "He doesn't.", effects: [{ op: "set_flag", flag: "jamesAngry", value: true }] },
          bySuccesses: { 2: { result_text: "Both land.", effects: [], goto: 3 } },
        },
        {
          label: "Leave",
          requires: { cash: { atLeast: 50 } },
          effects: [],
          result_text: "You go.",
          goto: 3,
        },
        { label: "Hold", requires: { path: "player.level", atLeast: 2 }, effects: [], result_text: "You hold." },
        { label: "Call", requires: { relation: "james", atLeast: 1 }, effects: [], result_text: "You call." },
        { label: "Show", requires: { item: "knuckleduster", equipped: true }, effects: [], result_text: "You show." },
        { label: "Flash", requires: { item: "knuckleduster" }, effects: [], result_text: "You flash." },
        {
          label: "Remind",
          requires: { choice: { event: "intro", card: 3, option: "ask" }, display: "hide" },
          effects: [],
          result_text: "You remind.",
        },
      ],
    },
    { type: "resolution", label: null, speaker: null, text: "Skipped." },
    { type: "resolution", label: null, speaker: null, text: "Landed." },
  ],
  on_complete: [{ op: "set_screen", screen: "map" }],
};

function saveModel(raw, model) {
  const root = parseJSONWithPositions(raw);
  return applyEdits(raw, collectModelEdits(raw, root, nodeToPlain(root), model));
}

test("the shared mechanics section is byte-identical in both editors and the storyboard tool", () => {
  assert.strictEqual(sharedSection(mobileHtml, "quest-editor-mobile.html"), sharedSource);
  const storyboardHtml = fs.readFileSync(path.join(__dirname, "storyboard.html"), "utf-8");
  assert.strictEqual(sharedSection(storyboardHtml, "storyboard.html"), sharedSource);
});

test("desktop: an event with every new field loads and saves (no edits) to identical bytes", () => {
  for (const raw of [JSON.stringify(ALL_FIELDS_EVENT, null, 2) + "\n", formatJSON(ALL_FIELDS_EVENT, "") + "\n"]) {
    const root = parseJSONWithPositions(raw);
    const model = nodeToPlain(root);
    assert.deepStrictEqual(model, JSON.parse(raw));
    assert.deepStrictEqual(collectModelEdits(raw, root, nodeToPlain(root), model), []);
    assert.strictEqual(saveModel(raw, model), raw);
  }
});

test("desktop: every legacy event saves unchanged when nothing is edited", () => {
  for (const f of files) {
    const raw = fs.readFileSync(path.join(eventsDir, f), "utf-8");
    assert.strictEqual(saveModel(raw, nodeToPlain(parseJSONWithPositions(raw))), raw, f);
  }
});

test("formatJSON output parses back to the same value at any indent", () => {
  for (const indent of ["", "  ", "          "]) {
    assert.deepStrictEqual(JSON.parse(formatJSON(ALL_FIELDS_EVENT, indent)), ALL_FIELDS_EVENT);
  }
  assert.strictEqual(formatJSON({ block: "evening", advance: true }, "  "), '{ "block": "evening", "advance": true }');
});

test("desktop: authoring every new field onto a legacy event saves exactly the model, touching nothing else", () => {
  const raw = fs.readFileSync(path.join(eventsDir, "busker_greenwich.json"), "utf-8");
  const original = JSON.parse(raw);
  const model = deepClone(original);
  model.at = { block: "afternoon", advance: false };
  const card = model.cards.find((c) => c.choices);
  const [opt, other] = card.choices;
  opt.id = "tip";
  opt.requires = {};
  setConditionKind(opt.requires, "cash", false);
  opt.requires.cash.atLeast = 20;
  opt.requires.display = "disable";
  opt.requires.reason = "Skint.";
  optionToCheck(opt);
  opt.check.min = 0.2;
  opt.check.max = 0.8;
  opt.check.show = "hidden";
  opt.check.attempts = 3;
  for (const kind of ["flag", "choice", "path", "relation", "cash", "item", "itemEquipped", "itemOptional"]) {
    const mod = {};
    setConditionKind(mod, kind, true);
    assert.strictEqual(conditionKind(mod), kind);
    opt.check.mods.push(mod);
  }
  opt.success.goto = 2;
  opt.fail.result_text = "He shrugs.";
  other.goto = 2;

  const saved = saveModel(raw, model);
  assert.deepStrictEqual(JSON.parse(saved), model);
  assert.deepStrictEqual(Object.keys(JSON.parse(saved)), ["id", "at", "cards", "on_complete", "deck"].filter((k) => k in model));
  // The second option's untouched keys keep their original bytes.
  assert(saved.includes(JSON.stringify(other.result_text)), "untouched result_text must survive verbatim");
  // Reload + save again with no edits is a no-op.
  assert.strictEqual(saveModel(saved, JSON.parse(saved)), saved);

  // Reverting everything (check -> plain, drop id/requires/goto/at) restores the original value.
  const back = JSON.parse(saved);
  delete back.at;
  const backCard = back.cards.find((c) => c.choices);
  optionToPlain(backCard.choices[0]);
  delete backCard.choices[0].id;
  delete backCard.choices[0].requires;
  delete backCard.choices[0].goto;
  delete backCard.choices[1].goto;
  backCard.choices[0].effects = original.cards.find((c) => c.choices).choices[0].effects;
  const reverted = saveModel(saved, back);
  assert.deepStrictEqual(JSON.parse(reverted), original);
});

test("objectEdits: dropping the first key rewrites the object; inserts land after the preceding ordered key", () => {
  const raw = '{\n  "id": "x",\n  "cards": []\n}\n';
  const root = parseJSONWithPositions(raw);
  const withAt = applyEdits(raw, objectEdits(raw, root, { id: "x", at: { block: "night", advance: false }, cards: [] }, ["id", "at", "cards"]));
  assert.strictEqual(withAt, '{\n  "id": "x",\n  "at": { "block": "night", "advance": false },\n  "cards": []\n}\n');
  const noId = applyEdits(raw, objectEdits(raw, root, { cards: [] }, ["id", "cards"]));
  assert.deepStrictEqual(JSON.parse(noId), { cards: [] });
  // A deletion and an insertion sharing a start offset both apply.
  const swapped = applyEdits(raw, objectEdits(raw, root, { id: "x", at: { block: "night", advance: true } }, ["id", "at", "cards"]));
  assert.deepStrictEqual(JSON.parse(swapped), { id: "x", at: { block: "night", advance: true } });
});

test("optionToCheck / optionToPlain carry result_text, goto and effects across the switch", () => {
  const opt = { label: "Go", effects: [{ op: "set_flag", flag: "a", value: true }], result_text: "Gone.", goto: 4 };
  optionToCheck(opt);
  assert.deepStrictEqual(opt, {
    label: "Go",
    effects: [{ op: "set_flag", flag: "a", value: true }],
    check: { base: 0.5, mods: [] },
    success: { result_text: "Gone.", effects: [], goto: 4 },
    fail: { result_text: null, effects: [] },
  });
  optionToPlain(opt);
  assert.deepStrictEqual(opt, { label: "Go", effects: [{ op: "set_flag", flag: "a", value: true }], result_text: "Gone.", goto: 4 });
});

test("setConditionKind keeps a mod's add/label and a requirement's display/reason", () => {
  const mod = { flag: "x", add: 0.2, label: "L" };
  setConditionKind(mod, "relation", true);
  assert.deepStrictEqual(mod, { relation: "", atLeast: 0, add: 0.2, label: "L" });
  setConditionKind(mod, "path", true);
  assert.deepStrictEqual(mod, { path: "", perPoint: 0, label: "L" });
  const req = { flag: "x", display: "disable", reason: "R" };
  setConditionKind(req, "item", false);
  assert.deepStrictEqual(req, { item: "", display: "disable", reason: "R" });
});

test("builder: a new quest with a check option, requires, goto and at builds the runtime schema", () => {
  const { buildQuestObject } = loadBuilder([]);
  const checkOpt = { label: " Try ", result_text: "Win." };
  optionToCheck(checkOpt);
  checkOpt.id = "try";
  checkOpt.fail.result_text = "  ";
  const obj = buildQuestObject({
    id: "new_check_quest",
    at: { block: "morning", advance: true },
    cards: [
      {
        type: "choice",
        label: "",
        speaker: "",
        text: "Go?",
        choices: [checkOpt, { label: "No", result_text: "Fine.", requires: { flag: "f" }, goto: 1 }],
      },
      { type: "resolution", label: "", speaker: "", text: "End.", choices: [] },
    ],
  });
  assert.deepStrictEqual(Object.keys(obj), ["id", "at", "cards", "on_complete"]);
  assert.deepStrictEqual(obj.at, { block: "morning", advance: true });
  assert.deepStrictEqual(obj.cards[0].choices[0], {
    label: "Try",
    id: "try",
    check: { base: 0.5, mods: [] },
    success: { result_text: "Win.", effects: [] },
    fail: { result_text: null, effects: [] },
  });
  assert.deepStrictEqual(obj.cards[0].choices[1], { label: "No", requires: { flag: "f" }, effects: [], result_text: "Fine.", goto: 1 });
});

test("mobile: a quest with every new field round-trips through a draft without loss", () => {
  const draft = mobile.draftFromParsed(deepClone(ALL_FIELDS_EVENT));
  const bundle = mobile.buildBundle(draft);
  assert.deepStrictEqual(bundle.at, ALL_FIELDS_EVENT.at);
  assert.deepStrictEqual(bundle.cards, ALL_FIELDS_EVENT.cards);
  // ...and the saved bundle reopens to the same bundle.
  const again = mobile.buildBundle(mobile.draftFromParsed(JSON.parse(JSON.stringify(bundle))));
  assert.deepStrictEqual(again.cards, bundle.cards);
  assert.deepStrictEqual(again.at, bundle.at);
  assert.strictEqual(again.notes, bundle.notes);
});

// The mobile editor trims prose and writes blank prose as null (its normProse
// convention), so legacy prose comes back normalized; everything else is exact.
const PROSE_KEYS = ["label", "speaker", "text", "result_text"];
function blankProseToNull(v) {
  if (Array.isArray(v)) return v.map(blankProseToNull);
  if (!v || typeof v !== "object") return v;
  const out = {};
  for (const [k, x] of Object.entries(v)) {
    out[k] = PROSE_KEYS.includes(k) && typeof x === "string" ? x.trim() || null : blankProseToNull(x);
  }
  return out;
}

test("mobile: every legacy event's cards survive a draft round-trip", () => {
  for (const f of files) {
    const quest = JSON.parse(fs.readFileSync(path.join(eventsDir, f), "utf-8"));
    const bundle = mobile.buildBundle(mobile.draftFromParsed(deepClone(quest)));
    assert.deepStrictEqual(bundle.cards, blankProseToNull(quest.cards), f);
    assert.deepStrictEqual(bundle.at, quest.at, f);
  }
});

test("mobile: a fresh choice still saves as {label, effects: [], result_text}", () => {
  const draft = { id: "x", cards: [{ type: "choice", label: "", speaker: "", text: "", choices: [mobile.defaultChoice()] }], notesText: "" };
  assert.deepStrictEqual(mobile.buildBundle(draft).cards[0].choices, [{ label: null, effects: [], result_text: null }]);
});

console.log(passed + " test(s) passed");
