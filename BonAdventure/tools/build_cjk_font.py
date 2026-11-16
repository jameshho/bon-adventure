#!/usr/bin/env python3
"""Regenerates fonts/NotoSansTC-SemiBold-subset.ttf, the Chinese fallback of the game font.

Why (13 Nov 2026): the game font fonts/NotoSans-SemiBold.ttf is Latin only. Desktop Godot falls
back to system fonts for Chinese, but browsers give the web build none, so every Chinese label
showed empty boxes. The game font's import (fonts/NotoSans-SemiBold.ttf.import "fallbacks")
now lists this subset, and project.godot makes the game font the default for every Label,
Button, Label3D and RichTextLabel.

The subset holds only the characters the game can show: every character in data/, scripts/
and scenes/ (.json/.gd/.tscn/.tres) that NotoSans-SemiBold.ttf lacks (Chinese, full-width
punctuation, arrows, stars...). The full Noto Sans TC is ~12 MB; the subset is a few hundred KB.

Run it again whenever Chinese text is added or changed (words, phrases, signs, names, grammar,
dialogue); `--check` only lists Chinese characters (and CJK punctuation) the subset lacks (exit 1).

Usage (from BonAdventure/, needs `pip install fonttools`):
  python3 tools/build_cjk_font.py [--source NotoSansTC[wght].ttf] [--check]

Without --source the variable Noto Sans TC (SIL OFL 1.1, docs/guides/licenses/noto-sans-tc-OFL.txt)
is downloaded from the google/fonts repository into a temporary folder. It is instanced at
weight 600 to match the SemiBold game font, then subset.
"""
import argparse
import os
import sys
import tempfile
import urllib.request

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

SOURCE_URL = "https://github.com/google/fonts/raw/main/ofl/notosanstc/NotoSansTC%5Bwght%5D.ttf"
PRIMARY = "fonts/NotoSans-SemiBold.ttf"
OUTPUT = "fonts/NotoSansTC-SemiBold-subset.ttf"
SCAN_DIRS = ("data", "scripts", "scenes")
SCAN_EXT = (".json", ".gd", ".tscn", ".tres")
WEIGHT = 600


def needed_characters(project: str) -> set:
    covered = set(TTFont(os.path.join(project, PRIMARY)).getBestCmap())
    found = set()
    for top in SCAN_DIRS:
        for root, _dirs, files in os.walk(os.path.join(project, top)):
            for name in files:
                if name.endswith(SCAN_EXT):
                    with open(os.path.join(root, name), encoding="utf-8", errors="ignore") as handle:
                        found.update(ord(c) for c in handle.read() if ord(c) > 0x7F)
    return {c for c in found - covered if c not in (0xFEFF,) and not 0xFE00 <= c <= 0xFE0F}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source", help="Noto Sans TC variable TTF (default: download it)")
    parser.add_argument("--check", action="store_true", help="only report characters the current subset lacks")
    args = parser.parse_args()
    project = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    wanted = needed_characters(project)
    output = os.path.join(project, OUTPUT)

    if args.check:
        # Only Chinese characters and CJK punctuation count: a few symbols (e.g. ✕ ✗ ☾) are in
        # neither font and are reported by a full run instead.
        have = set(TTFont(output).getBestCmap()) if os.path.exists(output) else set()
        missing = sorted(c for c in wanted - have if 0x2E80 <= c <= 0x9FFF or 0xF900 <= c <= 0xFAFF or 0xFF00 <= c <= 0xFFEF)
        print(f"build_cjk_font: {len(wanted)} characters needed, {len(missing)} missing from {OUTPUT}")
        if missing:
            print("".join(chr(c) for c in missing))
        return 1 if missing else 0

    source = args.source
    if not source:
        source = os.path.join(tempfile.mkdtemp(prefix="notosanstc-"), "NotoSansTC.ttf")
        print(f"build_cjk_font: downloading {SOURCE_URL}")
        urllib.request.urlretrieve(SOURCE_URL, source)
    font = TTFont(source)
    if "fvar" in font:
        font = instancer.instantiateVariableFont(font, {"wght": WEIGHT})
    available = set(font.getBestCmap())
    keep = sorted(wanted & available)
    absent = sorted(wanted - available)
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]  # keep copyright/licence names (OFL)
    options.notdef_outline = True
    options.hinting = False  # Godot renders with its own hinting; saves ~20%
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=keep)
    subsetter.subset(font)
    font.save(output)
    print(f"build_cjk_font: {len(keep)} characters -> {OUTPUT} ({os.path.getsize(output) / 1e3:.0f} KB)")
    if absent:
        print(f"build_cjk_font: {len(absent)} characters not in Noto Sans TC either: " + "".join(chr(c) for c in absent))
    return 0


if __name__ == "__main__":
    sys.exit(main())
