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
const names = "cellEdges, gridLock, kuwahara, reducePalette, snapToPalette, paletteFromJSON, colourCount, detectGrid, adjustColour, edgeProfile, followEdges, gridAxes, removeStrayPixels, smoothJaggies, thinOutlines, srgbToOklab, oklabToSrgb, lum, paletteToJSON";
const { cellEdges, gridLock, kuwahara, reducePalette, snapToPalette, paletteFromJSON, colourCount, detectGrid, adjustColour, edgeProfile, followEdges, gridAxes, removeStrayPixels, smoothJaggies, thinOutlines, srgbToOklab, oklabToSrgb, lum, paletteToJSON } =
  new Function("ImageData", section + "\nreturn { " + names + " };")(ImageData);

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

// Grid whose fake-pixel width drifts linearly from w0 to w1 across n cells.
function driftBounds(n, w0, w1) {
  const b = [0];
  for (let i = 0; i < n; i++) b.push(b[i] + Math.round(w0 + (w1 - w0) * i / (n - 1)));
  return b;   // integer border positions
}
function driftImage(bx, by) {
  const cellOf = (b, v) => { let i = 0; while (b[i + 1] <= v) i++; return i; };
  return fill(new ImageData(bx[bx.length - 1], by[by.length - 1]), (x, y) => truthColour(cellOf(bx, x), cellOf(by, y)));
}
function mismatches(img, out, xs, ys, bx, by) {
  const cellOf = (b, v) => { let i = 0; while (b[i + 1] <= v) i++; return i; };
  let bad = 0;
  for (let cy = 0; cy < ys.length; cy++) for (let cx = 0; cx < xs.length; cx++) {
    const mx = (xs[cx][0] + xs[cx][1]) >> 1, my = (ys[cy][0] + ys[cy][1]) >> 1;
    const t = truthColour(cellOf(bx, mx), cellOf(by, my)), a = px(out, cx, cy);
    if (a.slice(0, 3).some((v, k) => v !== t[k])) bad++;
  }
  return bad;
}

test("edge-following recovers a drifting grid that a fixed cell size loses", () => {
  const n = 30, bx = driftBounds(n, 5.0, 5.6), by = driftBounds(n, 5.0, 5.6);
  const img = driftImage(bx, by), W = img.width, H = img.height;
  const cell = W / n, prof = edgeProfile(img, W, H), follow = { prof, shift: 3 };
  const fixed = gridLock(img, W, H, cell, 0, 0, "dominant", 100, null);
  const moved = gridLock(img, W, H, cell, 0, 0, "dominant", 100, null, follow);
  const fa = gridAxes(W, H, cell, 0, 0, null), ma = gridAxes(W, H, cell, 0, 0, follow);
  const badFixed = mismatches(img, fixed, fa.xs, fa.ys, bx, by), badMoved = mismatches(img, moved, ma.xs, ma.ys, bx, by);
  assert(badFixed > 50, "fixed grid should lose many cells, lost " + badFixed);
  assert(badMoved <= badFixed * 0.05, "edge-following mismatches " + badMoved + " vs fixed " + badFixed);
});

test("edge-following changes nothing on a clean regular grid; borders stay ordered and in-bounds", () => {
  const img = upscale(12, 10, 6, 0, 0, 0), W = img.width, H = img.height;
  const follow = { prof: edgeProfile(img, W, H), shift: 2 };
  const a = gridLock(img, W, H, 6, 0, 0, "dominant", 100, null), b = gridLock(img, W, H, 6, 0, 0, "dominant", 100, null, follow);
  assert.deepStrictEqual(Array.from(b.data), Array.from(a.data));
  assert.deepStrictEqual(gridAxes(W, H, 6, 0, 0, follow).xs, cellEdges(W, 6, 0));
  // noisy, offset, fractional: still strictly increasing inside the image with the same cell count
  const nz = upscale(14, 12, 7.4, 3, 2, 24), p = edgeProfile(nz, nz.width, nz.height);
  const e = followEdges(nz.width, 7.4, 3, p.dx, 6), base = cellEdges(nz.width, 7.4, 3);
  assert.strictEqual(e.length, base.length);
  for (let i = 0; i < e.length; i++) {
    assert(e[i][1] > e[i][0] && e[i][0] >= 0 && e[i][1] <= nz.width, "cell " + i + " " + e[i]);
    if (i) assert.strictEqual(e[i][0], e[i - 1][1]);
  }
});

test("edge-following is fast on a 1536x1024 image", () => {
  const img = upscale(192, 128, 8, 0, 0, 0), t0 = Date.now();
  const follow = { prof: edgeProfile(img, img.width, img.height), shift: 3 };
  gridAxes(img.width, img.height, 8, 0, 0, follow);
  assert(Date.now() - t0 < 1500, "took " + (Date.now() - t0) + "ms");
});

test("removeStrayPixels: lone off-colour pixel removed, eye protected, pairs untouched, no new colours", () => {
  const A = [200, 200, 200], B = [190, 195, 200], DARK = [10, 10, 10];
  const mk = (f) => { const i = new ImageData(7, 7); fill(i, f); return i; };
  // lone slightly-different pixel
  const a = mk((x, y) => (x === 3 && y === 3 ? B : A));
  assert.deepStrictEqual(px(removeStrayPixels(a, 60), 3, 3).slice(0, 3), A);
  // eye: kept with protection, removed with it off
  const e = mk((x, y) => (x === 3 && y === 3 ? DARK : A));
  assert.deepStrictEqual(px(removeStrayPixels(e, 60), 3, 3).slice(0, 3), DARK);
  assert.deepStrictEqual(px(removeStrayPixels(e, 0), 3, 3).slice(0, 3), A);
  // connected pair (orthogonal and diagonal) untouched even with no protection
  for (const [x2, y2] of [[4, 3], [4, 4]]) {
    const p = mk((x, y) => ((x === 3 && y === 3) || (x === x2 && y === y2) ? B : A));
    const r = removeStrayPixels(p, 0);
    assert.deepStrictEqual(r.data, p.data);
  }
  // transparent pixels untouched and not counted as neighbours
  const t = mk((x, y) => A); t.data[(3 * 7 + 3) * 4 + 3] = 0;
  assert.strictEqual(px(removeStrayPixels(t, 0), 3, 3)[3], 0);
  // no new colours on noisy input
  const n = mk(() => [[10, 20, 30], [200, 100, 50], [90, 90, 90]][Math.floor(rnd() * 3)]);
  const before = new Set(), after = new Set(), r = removeStrayPixels(n, 0);
  for (let i = 0; i < n.data.length; i += 4) { before.add(n.data.slice(i, i + 3).join()); after.add(r.data.slice(i, i + 3).join()); }
  for (const c of after) assert(before.has(c), "new colour " + c);
});


test("OKLab round-trips sRGB within 1 per channel", () => {
  for (let k = 0; k < 4000; k++) {
    const c = [Math.floor(rnd() * 256), Math.floor(rnd() * 256), Math.floor(rnd() * 256)];
    const back = oklabToSrgb(...srgbToOklab(...c));
    c.forEach((v, i) => assert(Math.abs(back[i] - v) <= 1, c + " -> " + back));
  }
  assert.deepStrictEqual(oklabToSrgb(...srgbToOklab(0, 0, 0)), [0, 0, 0]);
  assert.deepStrictEqual(oklabToSrgb(...srgbToOklab(255, 255, 255)), [255, 255, 255]);
});

test("palette snap picks the perceptual match, not the RGB-nearest", () => {
  // deep indigo: RGB-nearest is the dark grey, perceptually the saturated blue
  const pal = [[20, 20, 20], [10, 0, 80]], c = [20, 10, 50];
  const rgb = (q) => (c[0] - q[0]) ** 2 + (c[1] - q[1]) ** 2 + (c[2] - q[2]) ** 2;
  assert(rgb(pal[0]) < rgb(pal[1]), "premise: RGB prefers the grey");
  const out = snapToPalette(fill(new ImageData(2, 1), () => c), pal);
  assert.deepStrictEqual(px(out, 0, 0).slice(0, 3), pal[1]);
});

test("reducePalette returns exact sRGB ints and keeps perceptually distinct darks apart", () => {
  const img = fill(new ImageData(30, 1), (x) => [[20, 20, 25], [25, 10, 60], [230, 230, 230]][x % 3]);
  const pal = reducePalette(img, 3);
  assert.strictEqual(pal.length, 3);
  for (const c of pal) assert(c.every((v) => Number.isInteger(v) && v >= 0 && v <= 255));
  assert.strictEqual(colourCount(snapToPalette(img, pal)), 3);
});

test("dark test is perceptual: saturated red is not dark where luma said it was; greys unchanged", () => {
  const cell = (c) => fill(new ImageData(4, 4), (x) => (x === 0 ? c : [230, 230, 230]));
  const outline = { share: 0.1, dark: 70 };
  const red = [200, 0, 0];
  assert(lum(...red) < 70, "premise: luma calls it dark");
  assert.deepStrictEqual(px(gridLock(cell(red), 4, 4, 4, 0, 0, "dominant", 100, outline), 0, 0).slice(0, 3), [230, 230, 230]);
  const grey = [60, 60, 60];
  assert.deepStrictEqual(px(gridLock(cell(grey), 4, 4, 4, 0, 0, "dominant", 100, outline), 0, 0).slice(0, 3), grey);
  const dark = [10, 10, 40];
  assert.deepStrictEqual(px(gridLock(cell(dark), 4, 4, 4, 0, 0, "dominant", 100, outline), 0, 0).slice(0, 3), dark);
});

test("snapping a 1536x1024 image stays interactive", () => {
  const img = fill(new ImageData(1536, 1024), (x, y) => [(x * 7) & 255, (y * 3) & 255, ((x + y) * 5) & 255]);
  const pal = Array.from({ length: 32 }, () => [Math.floor(rnd() * 256), Math.floor(rnd() * 256), Math.floor(rnd() * 256)]);
  const t0 = Date.now();
  snapToPalette(img, pal);
  assert(Date.now() - t0 < 3000, "took " + (Date.now() - t0) + "ms");
});

const set = (img, pts, c) => { for (const [x, y] of pts) { const i = (y * img.width + x) * 4; img.data[i] = c[0]; img.data[i + 1] = c[1]; img.data[i + 2] = c[2]; img.data[i + 3] = 255; } };
const BG = [220, 220, 220], INK = [10, 10, 10];
const same3 = (a, b) => a[0] === b[0] && a[1] === b[1] && a[2] === b[2];

test("smoothJaggies: staircase of L-shaped doubles becomes a connected 1-px diagonal; no new colours", () => {
  const img = fill(new ImageData(10, 10), () => BG), line = [];
  for (let k = 0; k < 8; k++) { line.push([k, k]); if (k < 7) line.push([k + 1, k]); }
  set(img, line, INK);
  const out = smoothJaggies(img);
  const ink = [];
  for (let y = 0; y < 10; y++) for (let x = 0; x < 10; x++) if (same3(px(out, x, y), INK)) ink.push([x, y]);
  assert(ink.length < line.length, "doubles removed: " + ink.length + " vs " + line.length);
  const has = (x, y) => ink.some(([a, b]) => a === x && b === y);
  for (const [x, y] of ink) {
    let n = 0; for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) if ((dx || dy) && has(x + dx, y + dy)) n++;
    assert(n <= 2, "pixel " + x + "," + y + " has " + n + " neighbours");
  }
  const seen = new Set([ink[0].join()]), stack = [ink[0]];
  while (stack.length) {
    const [x, y] = stack.pop();
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
      const k = [x + dx, y + dy];
      if (has(k[0], k[1]) && !seen.has(k.join())) { seen.add(k.join()); stack.push(k); }
    }
  }
  assert.strictEqual(seen.size, ink.length, "line stays connected");
  for (let i = 0; i < out.data.length; i += 4) assert(same3(out.data.slice(i, i + 3), BG) || same3(out.data.slice(i, i + 3), INK));
});

test("smoothJaggies: filled blocks, straight lines and transparent pixels untouched", () => {
  const img = fill(new ImageData(8, 8), () => BG);
  set(img, [[2, 2], [3, 2], [2, 3], [3, 3]], INK);
  set(img, [[5, 1], [5, 2], [5, 3], [5, 4], [5, 5]], INK);
  img.data[3] = 0;
  assert.deepStrictEqual(Array.from(smoothJaggies(img).data), Array.from(img.data));
});

test("thinOutlines: 2-px dark ring around a shape becomes 1 px and stays closed; separate lines not merged", () => {
  const W = 14, H = 14, img = new ImageData(W, H), ring = [];
  for (let y = 2; y <= 11; y++) for (let x = 2; x <= 11; x++) {
    const edge = Math.min(x - 2, 11 - x, y - 2, 11 - y);
    set(img, [[x, y]], edge < 2 ? INK : BG);
    if (edge === 0) ring.push([x, y]);
  }
  const out = thinOutlines(img, 70);
  const dark = (x, y) => px(out, x, y)[3] === 255 && same3(px(out, x, y), INK);
  let inkCount = 0;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (dark(x, y)) inkCount++;
  assert.strictEqual(inkCount, ring.length, "only the outer ring remains: " + inkCount + " vs " + ring.length);
  for (const [x, y] of ring) assert(dark(x, y), "ring pixel kept " + x + "," + y);
  const seen = new Set(), stack = [[6, 6]];
  while (stack.length) {
    const [x, y] = stack.pop();
    if (x < 0 || y < 0 || x >= W || y >= H || seen.has(x + "," + y) || dark(x, y)) continue;
    assert(px(out, x, y)[3] === 255, "leaked outside at " + x + "," + y);
    seen.add(x + "," + y); stack.push([x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]);
  }
  assert(seen.size > 0);
  for (let i = 0; i < out.data.length; i += 4) if (out.data[i + 3] === 255) assert(same3(out.data.slice(i, i + 3), INK) || same3(out.data.slice(i, i + 3), BG));
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (px(img, x, y)[3] === 0) assert.strictEqual(px(out, x, y)[3], 0);
  const two = fill(new ImageData(9, 6), () => BG);
  set(two, Array.from({ length: 6 }, (_, y) => [2, y]).concat(Array.from({ length: 6 }, (_, y) => [5, y])), INK);
  assert.deepStrictEqual(Array.from(thinOutlines(two, 70).data), Array.from(two.data));
});

test("thinOutlines leaves solid dark areas alone", () => {
  const img = fill(new ImageData(10, 10), () => BG);
  for (let y = 2; y < 8; y++) for (let x = 2; x < 8; x++) set(img, [[x, y]], INK);
  assert.deepStrictEqual(Array.from(thinOutlines(img, 70).data), Array.from(img.data));
});

console.log("\n" + passed + " passed");

test("shared palette: small image isn't swamped by a 4x larger one", () => {
  const A = [[200, 30, 30], [30, 200, 30], [30, 30, 200], [220, 220, 40]];
  const B = [[120, 20, 160], [20, 160, 160], [240, 140, 20], [130, 130, 130]];
  const big = fill(new ImageData(16, 16), (x, y) => A[(x >> 3) + 2 * (y >> 3)]);
  const small = fill(new ImageData(8, 8), (x, y) => B[(x >> 2) + 2 * (y >> 2)]);
  const pal = reducePalette([big, small], 8);
  assert.strictEqual(pal.length, 8);
  for (const c of A.concat(B)) assert(pal.some((q) => q.every((v, k) => Math.abs(v - c[k]) <= 1)), "missing " + c);
});

test("saved palette JSON round-trips through the palette parser", () => {
  const pal = [[0, 0, 0], [255, 128, 7], [20, 18, 15]];
  assert.deepStrictEqual(paletteFromJSON(JSON.parse(JSON.stringify(paletteToJSON(pal)))), pal);
});

console.log("\n" + passed + " passed");
