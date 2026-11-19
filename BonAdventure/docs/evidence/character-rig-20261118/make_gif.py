#!/usr/bin/env python3
"""EXPERIMENT (18 Nov 2026): turns showcase.gd's raw walk frames into looping GIFs, no libraries.
   python3 make_gif.py <frames_dir> <width> <height> <out_dir> <name> [<name> ...]
Reads <frames_dir>/<name>-NN.rgb (RGB8) and writes <out_dir>/5-walk-<name>.gif at 30 fps."""
import struct
import sys
import os
import re
from collections import Counter


def palette_for(frames):
    counts = Counter()
    for data in frames:
        for i in range(0, len(data), 3 * 7):
            counts[(data[i] >> 3, data[i + 1] >> 3, data[i + 2] >> 3)] += 1
    top = [k for k, _ in counts.most_common(256)]
    while len(top) < 256:
        top.append((0, 0, 0))
    return [(r << 3 | 4, g << 3 | 4, b << 3 | 4) for r, g, b in top]


def indexer(pal):
    cache = {}

    def index(r, g, b):
        key = (r >> 3, g >> 3, b >> 3)
        hit = cache.get(key)
        if hit is None:
            best, bd = 0, 1 << 30
            for i, (pr, pg, pb) in enumerate(pal):
                d = (pr - r) ** 2 + (pg - g) ** 2 + (pb - b) ** 2
                if d < bd:
                    best, bd = i, d
            cache[key] = hit = best
        return hit
    return index


def lzw(indices, min_size=8):
    clear, end = 1 << min_size, (1 << min_size) + 1
    out, bits, nbits = bytearray(), 0, 0
    size = min_size + 1

    def emit(code):
        nonlocal bits, nbits
        bits |= code << nbits
        nbits += size
        while nbits >= 8:
            out.append(bits & 255)
            bits >>= 8
            nbits -= 8
    table = {(i,): i for i in range(clear)}
    nxt = end + 1
    emit(clear)
    w = (indices[0],)
    for k in indices[1:]:
        wk = w + (k,)
        if wk in table:
            w = wk
            continue
        emit(table[w])
        if nxt < 4096:
            table[wk] = nxt
            nxt += 1
            if nxt > (1 << size) and size < 12:
                size += 1
        else:
            emit(clear)
            table = {(i,): i for i in range(clear)}
            nxt = end + 1
            size = min_size + 1
        w = (k,)
    emit(table[w])
    emit(end)
    if nbits:
        out.append(bits & 255)
    return bytes(out)


def write_gif(path, frames, w, h, delay_cs=3):
    pal = palette_for(frames)
    index = indexer(pal)
    with open(path, "wb") as f:
        f.write(b"GIF89a" + struct.pack("<HHBBB", w, h, 0xF7, 0, 0))
        f.write(bytes(c for rgb in pal for c in rgb))
        f.write(b"\x21\xFF\x0BNETSCAPE2.0\x03\x01\x00\x00\x00")
        for data in frames:
            idx = [index(data[i], data[i + 1], data[i + 2]) for i in range(0, len(data), 3)]
            f.write(b"\x21\xF9\x04\x04" + struct.pack("<H", delay_cs) + b"\x00\x00")
            f.write(b"\x2C" + struct.pack("<HHHHB", 0, 0, w, h, 0) + b"\x08")
            stream = lzw(idx)
            for i in range(0, len(stream), 255):
                chunk = stream[i:i + 255]
                f.write(bytes([len(chunk)]) + chunk)
            f.write(b"\x00")
        f.write(b"\x3B")


def main():
    src, w, h, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    for name in sys.argv[5:]:
        files = sorted(p for p in os.listdir(src) if re.fullmatch(re.escape(name) + r"-\d+\.rgb", p))
        frames = [open(os.path.join(src, p), "rb").read() for p in files]
        target = os.path.join(out, "5-walk-%s.gif" % name.lower())
        write_gif(target, frames, w, h)
        print(target, len(frames), "frames")


if __name__ == "__main__":
    main()
