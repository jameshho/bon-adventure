#!/usr/bin/env python3
"""Report broken relative links in the project's Markdown files.

Usage (from BonAdventure/ or the repository root):
    python3 BonAdventure/tools/check_doc_links.py            # whole repository
    python3 BonAdventure/tools/check_doc_links.py docs/game  # only these paths

Checks every Markdown link and image ``[text](target)`` / ``![alt](target)``
whose target is a relative path: the file (or folder) must exist. ``#anchor``
fragments are checked against the headings of Markdown targets. Web links,
``mailto:`` and links inside code spans or fenced code blocks are skipped.
Exits 1 when anything is broken, so it can run in a hook or CI.
"""

import os
import re
import sys
from urllib.parse import unquote

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SKIP_DIRS = {".git", ".godot", ".claude", "node_modules", "build", "export"}
LINK_RE = re.compile(r"!?\[(?:[^\[\]]|\[[^\]]*\])*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
FENCE_RE = re.compile(r"^\s*(```|~~~)")
CODE_SPAN_RE = re.compile(r"`+[^`]*`+")
HTML_ANCHOR_RE = re.compile(r"<a\s+(?:name|id)=\"([^\"]+)\"")

_anchor_cache = {}


def slugify(heading):
    """GitHub-style heading anchor."""
    text = re.sub(r"<[^>]+>", "", heading).strip().lower()
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)  # link text only
    text = text.replace("`", "")
    text = re.sub(r"[^\w\- ]", "", text, flags=re.UNICODE)
    return text.replace(" ", "-")


def anchors_of(path):
    if path in _anchor_cache:
        return _anchor_cache[path]
    found = set()
    counts = {}
    in_fence = False
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if FENCE_RE.match(line):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            for name in HTML_ANCHOR_RE.findall(line):
                found.add(name)
            match = re.match(r"^\s{0,3}#{1,6}\s+(.*?)\s*#*\s*$", line)
            if match:
                slug = slugify(match.group(1))
                n = counts.get(slug, 0)
                counts[slug] = n + 1
                found.add(slug if n == 0 else "%s-%d" % (slug, n))
    _anchor_cache[path] = found
    return found


def markdown_files(paths):
    for start in paths:
        if os.path.isfile(start):
            yield start
            continue
        for folder, dirs, files in os.walk(start):
            dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
            for name in sorted(files):
                if name.lower().endswith(".md"):
                    yield os.path.join(folder, name)


def check_file(path):
    problems = []
    in_fence = False
    with open(path, encoding="utf-8", errors="replace") as handle:
        for number, line in enumerate(handle, 1):
            if FENCE_RE.match(line):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            for target in LINK_RE.findall(CODE_SPAN_RE.sub("", line)):
                if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I):
                    continue  # http:, https:, mailto:, res: ...
                file_part, _, fragment = target.partition("#")
                file_part = unquote(file_part)
                if file_part:
                    resolved = os.path.normpath(os.path.join(os.path.dirname(path), file_part))
                    if not os.path.exists(resolved):
                        problems.append((number, target, "missing file"))
                        continue
                else:
                    resolved = path
                if fragment and resolved.lower().endswith(".md") and os.path.isfile(resolved):
                    if unquote(fragment).lower() not in {a.lower() for a in anchors_of(resolved)}:
                        problems.append((number, target, "missing anchor"))
    return problems


def main(argv):
    os.chdir(ROOT)
    paths = []
    for arg in argv or ["."]:
        if os.path.exists(arg):
            paths.append(arg)
        elif os.path.exists(os.path.join("BonAdventure", arg)):
            paths.append(os.path.join("BonAdventure", arg))
        else:
            print("no such path: %s" % arg, file=sys.stderr)
            return 2
    total = 0
    checked = 0
    for md in markdown_files(paths):
        checked += 1
        for number, target, why in check_file(md):
            total += 1
            print("%s:%d: %s (%s)" % (os.path.relpath(md), number, target, why))
    print("%d broken link(s) in %d Markdown file(s)" % (total, checked))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
