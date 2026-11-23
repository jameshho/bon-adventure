"""The single word source: data/words.json.

    from word_data import load, save
    data = load()                  # {"categories": {...}, "aliases": {...}, "words": {...}}
    data["words"]["kite"] = {"text": {"en": "kite", "es": "el papalote"}, "category": "Sports & Play"}
    save(data)                     # validates, then rewrites in the canonical layout

"removed_with_objects" lists deleted words whose tagged objects the game removes
from town at load (world_refinements.gd::apply_word_list).

"sold_in" (optional) lists the store ids (keys of "stores" in data/shop_dialogue.json) whose
"customer order" minigame may ask for the word; only real, clickable products get it.

Each word's "text" holds its display text in EVERY language listed in data/languages.json
(the key is only a permanent id; saves use it). Optional "forms" holds per-language
grammar data for words that fill a {slot:form} in data/phrases.json; the shape belongs
to that language's rules module and is checked by tools/language_check.gd, not here.

`python3 tools/word_data.py` re-formats the file and prints a summary; it exits
non-zero when the data is inconsistent. Each word is one line, grouped by category
in the order the categories are listed, so the file stays easy to read and diff.
"""
import json
import sys
from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / "data" / "words.json"
LANGUAGES_PATH = Path(__file__).resolve().parents[1] / "data" / "languages.json"
FIELDS = ("text", "forms", "category", "prefab_size", "picture", "note", "sold_in")


def load(path=PATH):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def languages():
    """data/languages.json: {"native": code, "foreign": code, "languages": {code: {...}}}."""
    return json.loads(LANGUAGES_PATH.read_text(encoding="utf-8"))


def vocabulary(data, lang=None):
    """key -> display text in `lang` (default: the foreign language being taught)."""
    lang = lang or languages()["foreign"]
    return {key: entry["text"][lang] for key, entry in data["words"].items()}


def categories(data):
    return {key: entry["category"] for key, entry in data["words"].items()}


def catalog(data):
    """Words with a generated prefab, in the old learning_catalog shape."""
    # "spanish" is the legacy name of the foreign display text in this derived shape.
    foreign = languages()["foreign"]
    return {key: {"spanish": e["text"][foreign], "category": e["category"], "size": e["prefab_size"]}
            for key, e in data["words"].items() if "prefab_size" in e}


def problems(data):
    found = []
    rules = data["categories"]
    words = data["words"]
    codes = list(languages()["languages"])
    # A draft language (languages.json "status": "draft") may still lack words.
    drafts = {c for c, spec in languages()["languages"].items() if spec.get("status") == "draft"}
    for key, entry in words.items():
        if key != key.strip() or not key:
            found.append(f"bad key {key!r}")
        text = entry.get("text", {})
        if not isinstance(text, dict):
            found.append(f"{key}: text must map language codes to display text")
            text = {}
        for code in codes:
            if not str(text.get(code, "")).strip() and code not in drafts:
                found.append(f"{key}: missing {code} text")
        for code in text:
            if code not in codes:
                found.append(f"{key}: text for unknown language {code!r}")
        forms = entry.get("forms", {})
        if not isinstance(forms, dict) or not all(c in codes and isinstance(f, dict) for c, f in forms.items()):
            found.append(f"{key}: forms must map language codes to objects")
        if entry.get("category") not in rules:
            found.append(f"{key}: unknown category {entry.get('category')!r}")
        for field in entry:
            if field not in FIELDS:
                found.append(f"{key}: unknown field {field!r}")
        if "picture" in entry and entry["picture"] is not False:
            found.append(f"{key}: picture may only be false (no journal picture)")
        sold_in = entry.get("sold_in", [])
        if not isinstance(sold_in, list) or not all(isinstance(s, str) and s for s in sold_in) or len(set(sold_in)) != len(sold_in):
            found.append(f"{key}: sold_in must be a list of unique store ids")
    for alias, target in data["aliases"].items():
        if target not in words:
            found.append(f"alias {alias!r} -> missing word {target!r}")
        if alias in words:
            found.append(f"alias {alias!r} is also a word")
    for name in rules:
        if not any(e["category"] == name for e in words.values()):
            found.append(f"category {name!r} has no words")
    for key in data.get("removed_with_objects", []):
        if key in words or key in data["aliases"]:
            found.append(f"removed word {key!r} is still a word or alias")
    return found


def dumps(data):
    order = list(data["categories"])
    words = sorted(data["words"].items(),
                   key=lambda item: (order.index(item[1]["category"]) if item[1]["category"] in order else len(order), item[0].lower()))
    one = lambda value: json.dumps(value, ensure_ascii=False)
    lines = ["{", '  "about": ' + one(data.get("about", "")) + ",", '  "categories": {']
    lines += [f"    {one(name)}: {one(rule)}," for name, rule in data["categories"].items()]
    lines[-1] = lines[-1].rstrip(",")
    lines += ["  },", '  "aliases": {']
    lines += [f"    {one(alias)}: {one(target)}," for alias, target in sorted(data["aliases"].items(), key=lambda a: a[0].lower())]
    lines[-1] = lines[-1].rstrip(",")
    lines += ["  },", '  "removed_with_objects": ' + one(sorted(data.get("removed_with_objects", []))) + ",", '  "words": {']
    for key, entry in words:
        ordered = {field: entry[field] for field in FIELDS if field in entry}
        lines.append(f"    {one(key)}: {one(ordered)},")
    lines[-1] = lines[-1].rstrip(",")
    lines += ["  }", "}", ""]
    text = "\n".join(lines)
    json.loads(text)
    return text


def save(data, path=PATH):
    issues = problems(data)
    if issues:
        raise ValueError("words.json problems:\n" + "\n".join(issues))
    Path(path).write_text(dumps(data), encoding="utf-8")


if __name__ == "__main__":
    data = load()
    issues = problems(data)
    for issue in issues:
        print("PROBLEM:", issue)
    if not issues:
        save(data)
    counts = {name: sum(1 for e in data["words"].values() if e["category"] == name) for name in data["categories"]}
    print(f"{len(data['words'])} words, {len(data['aliases'])} aliases, {len(counts)} categories")
    for name, count in counts.items():
        print(f"  {count:4d}  {name}")
    sys.exit(1 if issues else 0)
