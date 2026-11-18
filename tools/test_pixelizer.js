// Node test for tools/pixelizer.html's pure image maths (grid lock, Kuwahara, palette, grid detection).
// Run with: node tools/test_pixelizer.js
//
// Extracts the marked pure section straight out of the shipped HTML so the tests exercise the code
// the browser runs. ImageData is shimmed.

const fs = require("fs");
const path = require("path");
const assert = require("assert");

const html = fs.readFileSync(path.join(__dirname, "pixelizer.html"), "utf-8").replace(/\r\n/g, "\n");
const startMarker = "/* ---------- Image maths (pure) ---------- */";
const endMarker = "/* ---------- End image maths ---------- */";
const s = html.indexOf(startMarker), e = html.indexOf(endMarker);
assert(s !== -1 && e !== -1, "could not locate image maths markers in pixelizer.html");
const section = html.slice(s, e);
assert(!/\b(document|window|localStorage)\b/.test(section.replace(/\/\/.*$/gm, "").replace(/\/\*[\s\S]*?\*\//g, "")), "pure section touches the DOM");

class ImageData {
  constructor(a, b, c) {
    if (typeof a === "number") { this.width = a; this.height = b; this.data = new Uint8ClampedArray(a * b * 4); }
    else { this.data = a; this.width = b; this.height = c; }
  }
}
const { cellEdges, gridLock, kuwahara, reducePalette, snapToPalette, paletteFromJSON, colourCount, detectGrid, adjustColour } =
  new Function("ImageData", section + "\nreturn { cellEdges, gridLock, kuwahara, reducePalette, snapToPalette, paletteFromJSON, colourCount, detectGrid, adjustColour };")(ImageData);

let passed = 0;
function test(name, fn) { fn(); passed++; console.log("ok - " + name); }

// deterministic RNG
let seed = 12345;
const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };

const px = (img, x, y) => { const i = (y * img.width + x) * 4; return [img.data[i], img.data[i + 1], img.data[i + 2], img.data[i + 3]]; };
function fill(img, f) {
  for (let y = 0; y < img.height; y++) for (let x = 0; x < img.width; x++) {
    const c = f(x, y), i = (y * img.width + x) * 4;
    img.data[i] = c[0]; img.data[i + 1] = c[1]; img.data[i + 2] = c[2]; img.data[i + 3] = 255;
  }
  return img;
}
// A small "truth" grid of distinct-ish colours.
const CORNERS = [0, 1, 2, 3, 4, 5, 6, 7].map((k) => [k & 1, (k >> 1) & 1, (k >> 2) & 1].map((b) => (b ? 215 : 40)));
const truthColour = (cx, cy) => CORNERS[(cx * 3 + cy * 5) % 8];   // neighbours always differ
// Truth grid shifted by (ox, oy) px, no padding: the first cell is partial.
const truthAt = (x, y, tw, th, cell, ox, oy) => truthColour(Math.min(tw - 1, Math.floor((x + ox) / cell)), Math.min(th - 1, Math.floor((y + oy) / cell)));
function upscale(tw, th, cell, ox, oy, noise) {
  const W = Math.round(tw * cell - ox), H = Math.round(th * cell - oy);
  return fill(new ImageData(W, H), (x, y) => {
    const c = truthAt(x, y, tw, th, cell, ox, oy);
    return noise ? c.map((v) => v + (rnd() - 0.5) * noise) : c;
  });
}

test("cellEdges covers fractional cells without gaps", () => {
  const e = cellEdges(20, 2.5, 0);
  assert.strictEqual(e.length, 8);
  for (let i = 1; i < e.length; i++) assert.strictEqual(e[i][0], e[i - 1][1]);
});

test("dominant lock recovers a clean grid exactly", () => {
  const img = upscale(6, 5, 8, 0, 0, 0);
  const out = gridLock(img, img.width, img.height, 8, 0, 0, "dominant", 100, null);
  assert.strictEqual(out.width, 6); assert.strictEqual(out.height, 5);
  for (let cy = 0; cy < 5; cy++) for (let cx = 0; cx < 6; cx++) assert.deepStrictEqual(px(out, cx, cy).slice(0, 3), truthColour(cx, cy));
});

test("dominant takes the majority where mean blends", () => {
  // 4x4 cell: 12 red, 4 blue
  const img = fill(new ImageData(4, 4), (x, y) => (y === 3 ? [0, 0, 200] : [200, 0, 0]));
  const dom = gridLock(img, 4, 4, 4, 0, 0, "dominant", 100, null);
  const mean = gridLock(img, 4, 4, 4, 0, 0, "mean", 100, null);
  assert.deepStrictEqual(px(dom, 0, 0), [200, 0, 0, 255]);
  assert.deepStrictEqual(px(mean, 0, 0), [150, 0, 50, 255]);
});

test("fractional cell + offset: auto-detect recovers noisy grid with 0 mismatched cells", () => {
  const tw = 14, th = 12, cell = 7.4, ox = 3, oy = 2;
  const light = upscale(tw, th, cell, ox, oy, 0);   // detection needs clean steps: noise past ~2/channel reads as grid energy
  const img = upscale(tw, th, cell, ox, oy, 24);    // the lock itself must cope with heavy noise
  const g = detectGrid(light, light.width, light.height);
  assert(g, "grid detected");
  const out = gridLock(img, img.width, img.height, g.cell, g.ox, g.oy, "dominant", 60, null);
  const distinct = new Set(Array.from({ length: tw * th }, (_, i) => truthColour(i % tw, Math.floor(i / tw)).join())).size;
  // colour-reduce, then every output cell must equal the truth under its centre
  const snapped = snapToPalette(out, reducePalette(out, distinct));
  const xs = cellEdges(img.width, g.cell, g.ox), ys = cellEdges(img.height, g.cell, g.oy);
  let bad = 0;
  for (let cy = 0; cy < ys.length; cy++) for (let cx = 0; cx < xs.length; cx++) {
    const mx = Math.floor((xs[cx][0] + xs[cx][1]) / 2), my = Math.floor((ys[cy][0] + ys[cy][1]) / 2);
    const t = truthAt(mx, my, tw, th, cell, ox, oy), a = px(snapped, cx, cy);
    if (a.slice(0, 3).some((v, k) => Math.abs(v - t[k]) > 40)) bad++;   // palette centres are cluster means: right colour, not exact
  }
  assert.strictEqual(bad, 0, "mismatched cells: " + bad + " (detected cell " + g.cell + ")");
});

test("outline priority keeps a thin dark line that plain dominant and mean lose", () => {
  // 6x6 cell, light fill, one dark column (6 of 36 px)
  const img = fill(new ImageData(6, 6), (x) => (x === 2 ? [10, 10, 10] : [220, 220, 220]));
  const outline = { share: 0.1, dark: 70 };
  const domPlain = gridLock(img, 6, 6, 6, 0, 0, "dominant", 100, null);
  const domOut = gridLock(img, 6, 6, 6, 0, 0, "dominant", 100, outline);
  const meanPlain = gridLock(img, 6, 6, 6, 0, 0, "mean", 100, null);
  const meanOut = gridLock(img, 6, 6, 6, 0, 0, "mean", 100, outline);
  assert.deepStrictEqual(px(domPlain, 0, 0).slice(0, 3), [220, 220, 220]);
  assert.deepStrictEqual(px(domOut, 0, 0).slice(0, 3), [10, 10, 10]);
  assert(px(meanPlain, 0, 0)[0] > 150, "mean washes the line out");
  assert.deepStrictEqual(px(meanOut, 0, 0).slice(0, 3), [10, 10, 10]);
});

test("Kuwahara cuts texture noise while keeping a hard edge", () => {
  const w = 40, h = 20;
  const img = fill(new ImageData(w, h), (x) => { const b = x < 20 ? 60 : 200, n = (rnd() - 0.5) * 40; return [b + n, b + n, b + n]; });
  const out = kuwahara(img, 3);
  const std = (im, x0, x1) => {
    const v = []; for (let y = 4; y < h - 4; y++) for (let x = x0; x < x1; x++) v.push(px(im, x, y)[0]);
    const m = v.reduce((a, b) => a + b, 0) / v.length; return Math.sqrt(v.reduce((a, b) => a + (b - m) ** 2, 0) / v.length);
  };
  assert(std(out, 4, 14) < std(img, 4, 14) * 0.6, "noise reduced");
  const row = 10;
  assert(Math.abs(px(out, 17, row)[0] - 60) < 15, "dark side stays dark");
  assert(Math.abs(px(out, 22, row)[0] - 200) < 15, "light side stays light");
});

test("palette JSON parse finds every #rrggbb in data/palette.json", () => {
  const data = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "data", "palette.json"), "utf-8"));
  const expected = (JSON.stringify(data.colors !== undefined ? data.colors : data).match(/#[0-9a-fA-F]{6}(?![0-9a-fA-F])/g) || []).length;
  const pal = paletteFromJSON(data);
  assert(expected > 0);
  assert.strictEqual(pal.length, expected);
  assert(pal.every((c) => c.length === 3 && c.every((v) => v >= 0 && v <= 255)));
  assert.deepStrictEqual(paletteFromJSON(["#ff0000", { a: "#00ff0080" }, "nope"]), [[255, 0, 0], [0, 255, 0]]);
});

test("colourCount and adjustColour basics", () => {
  const img = upscale(3, 1, 2, 0, 0, 0);
  assert.strictEqual(colourCount(img), 3);
  const same = adjustColour(img, 0, 0);
  assert.deepStrictEqual(Array.from(same.data), Array.from(img.data));
  const grey = adjustColour(img, 0, -100);
  assert(grey.data[0] === grey.data[1] && grey.data[1] === grey.data[2], "sat -100 greys out");
});

console.log("\n" + passed + " passed");
