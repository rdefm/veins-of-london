"""Image backends for art autogen.

Interface (both return `(images, cost)`; `images` is a list of PNG bytes):
  generate(prompt, references, size, n)
  edit(image, prompt, references, mask=None)
`references` is a list of (role, path). `cost` is a dict: amount, currency, units.
Only `FakeImageBackend` exists so far: fixture images, canned costs, no network.
"""
import io
import zlib


class ImageBackendError(Exception):
    pass


def fixture_png(size, seed):
    """A deterministic flat-colour PNG of `size` (w, h); the colour follows `seed`."""
    from PIL import Image
    w, h = size
    rgb = (zlib.crc32(("%d" % seed).encode()) & 0xFFFFFF).to_bytes(3, "big")
    buf = io.BytesIO()
    Image.new("RGB", (w, h), tuple(rgb)).save(buf, "PNG")
    return buf.getvalue()


class FakeImageBackend:
    name = "fake"
    supports_masks = True

    def __init__(self, cost_per_image=0.04, size=None):
        self.cost_per_image = cost_per_image
        self.size = size
        self.calls = []
        self._n = 0

    def _cost(self, n):
        return {"amount": round(self.cost_per_image * n, 6), "currency": "USD", "units": "%d image(s)" % n}

    def generate(self, prompt, references, size, n):
        self.calls.append({"op": "generate", "prompt": prompt, "references": list(references),
                           "size": list(size), "n": n})
        out = []
        for _ in range(n):
            self._n += 1
            out.append(fixture_png(self.size or size, self._n))
        return out, self._cost(n)

    def edit(self, image, prompt, references, mask=None):
        self.calls.append({"op": "edit", "prompt": prompt, "references": list(references), "mask": mask is not None})
        self._n += 1
        return [fixture_png(self.size or (8, 12), self._n)], self._cost(1)
