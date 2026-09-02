"""Minimal pure-stdlib PNG reader/writer.

Supports exactly what the pixelize pipeline needs: 8-bit-per-channel,
non-interlaced RGB or RGBA. No external dependencies (no Pillow) so
tools/pixelize.py runs on a bare Python 3 install.

Pixel buffer format used throughout: a flat list of length width*height,
each entry a 4-tuple (r, g, b, a), 0-255.
"""

import struct
import zlib

_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def read_png(path: str):
    """Returns (width, height, pixels) where pixels is a flat RGBA list."""
    with open(path, "rb") as f:
        data = f.read()

    if data[:8] != _SIGNATURE:
        raise ValueError("%s: not a PNG file" % path)

    pos = 8
    width = height = None
    bit_depth = color_type = None
    idat = bytearray()

    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        chunk_type = data[pos + 4:pos + 8].decode("ascii")
        chunk_data = data[pos + 8:pos + 8 + length]
        pos += 8 + length + 4  # skip CRC

        if chunk_type == "IHDR":
            (width, height, bit_depth, color_type, _comp, _filt, interlace) = \
                struct.unpack(">IIBBBBB", chunk_data)
            if interlace != 0:
                raise NotImplementedError("%s: interlaced PNGs not supported" % path)
            if bit_depth != 8:
                raise NotImplementedError(
                    "%s: only 8-bit PNGs supported (got bit depth %d)" % (path, bit_depth))
            if color_type not in (2, 6):
                raise NotImplementedError(
                    "%s: only RGB/RGBA PNGs supported (got color type %d)" % (path, color_type))
        elif chunk_type == "IDAT":
            idat += chunk_data
        elif chunk_type == "IEND":
            break

    if width is None:
        raise ValueError("%s: missing IHDR" % path)

    channels = 4 if color_type == 6 else 3
    raw = zlib.decompress(bytes(idat))
    stride = width * channels

    pixels = [None] * (width * height)
    prev_row = bytearray(stride)
    offset = 0
    for y in range(height):
        filter_type = raw[offset]
        offset += 1
        row = bytearray(raw[offset:offset + stride])
        offset += stride

        for x in range(stride):
            a = row[x - channels] if x >= channels else 0
            b = prev_row[x]
            c = prev_row[x - channels] if x >= channels else 0
            if filter_type == 0:
                pass
            elif filter_type == 1:
                row[x] = (row[x] + a) & 0xFF
            elif filter_type == 2:
                row[x] = (row[x] + b) & 0xFF
            elif filter_type == 3:
                row[x] = (row[x] + ((a + b) >> 1)) & 0xFF
            elif filter_type == 4:
                row[x] = (row[x] + _paeth(a, b, c)) & 0xFF
            else:
                raise NotImplementedError("%s: unknown PNG filter type %d" % (path, filter_type))

        for x in range(width):
            base = x * channels
            if channels == 4:
                r, g, bch, al = row[base:base + 4]
            else:
                r, g, bch = row[base:base + 3]
                al = 255
            pixels[y * width + x] = (r, g, bch, al)

        prev_row = row

    return width, height, pixels


def write_png(path: str, width: int, height: int, pixels) -> None:
    """pixels: flat list of length width*height of (r, g, b, a) tuples."""
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # filter type 0 (None) — simplicity over compression ratio
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw += bytes((r, g, b, a))

    compressed = zlib.compress(bytes(raw), 9)

    def chunk(chunk_type: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + chunk_type
            + payload
            + struct.pack(">I", zlib.crc32(chunk_type + payload) & 0xFFFFFFFF)
        )

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)

    with open(path, "wb") as f:
        f.write(_SIGNATURE)
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", compressed))
        f.write(chunk(b"IEND", b""))
