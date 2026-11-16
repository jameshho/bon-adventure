"""Read-only Spanish translation integrity audit for Vocabulary Town v27.

Run from any directory with: python docs/evidence/town-checks/check_vocabulary_translations.py
This verifies data/schema, not whether Godot can execute the whole game.
"""
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
DATA = ROOT / 'data'
sys.path.insert(0, str(ROOT / 'tools'))
import word_data  # data/words.json is the only word source
_words = word_data.load()
words = word_data.vocabulary(_words)
categories = word_data.categories(_words)
catalog = word_data.catalog(_words)
aliases = _words['aliases']
errors = []
scene_tags = 0
translated_tags = 0
scene_count = 0

if set(words) != set(categories):
    errors.append('Vocabulary and category keys are different')
if not (ROOT / 'scenes/main.tscn').is_file():
    errors.append('Main scene is missing')

# Directions and temporal adverbs are phrases, not nouns and must not receive an article.
articleless_phrases = {"left", "right", "straight ahead", "near", "far", "today", "tomorrow", "yesterday", "now", "later"}
# 4 Nov 2026: months (enero ... diciembre), before/after (antes, después) and the age
# comparisons older/younger (mayor, menor) are used without an article too.
articleless_phrases |= {"january", "february", "march", "april", "may", "june", "july", "august",
                        "september", "october", "november", "december", "before", "after", "older", "younger"}
# One primary Mexican translation per word: ' / ' is only for masculine/feminine person forms and fish.
# 5 Nov 2026 (warehouse): verbs (infinitives), colours and descriptions (adjectives) and
# position phrases (encima de, arriba...) take no article either.
articleless_phrases |= {key for key, category in categories.items() if category in ("Actions", "Colors & Descriptions")}
articleless_phrases |= {"on top of", "under", "in front of", "behind", "inside", "outside", "next to", "on",
                        "on the top shelf", "on the bottom shelf", "at the top", "at the bottom", "up", "down"}
# 7 Nov 2026 (airport flight game words, ef87fc9): country names, flight statuses and time
# expressions (weekdays as written on the departure board, "a las dos", "esta noche") take no article.
articleless_phrases |= {key for key, category in categories.items() if category == "Countries"}
articleless_phrases |= {"canceled", "delayed", "on time",
                        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
                        "at midnight", "at night", "at noon", "at one o'clock", "at two o'clock", "at what time",
                        "day after tomorrow", "day before yesterday", "half past", "in one hour", "in one week",
                        "in the afternoon", "in the morning", "in two days", "last night", "o'clock",
                        "one hour ago", "one week ago", "soon", "this afternoon", "this month", "this morning",
                        "this week", "this year", "tonight", "two days ago", "when"}
multi_option_allowed = {"banker", "cashier", "cook", "doctor", "driver", "nurse", "pilot", "police officer", "salesperson", "cousin",
                        "teacher", "waiter", "fish", "boss", "employee", "suspect",
                        "hair"}  # hair: approved synonyms el pelo / el cabello (user, 31 Oct 2026; note in words.json)
by_spanish = {}
for key, spanish in words.items():
    by_spanish.setdefault(spanish, []).append(key)
    if ' / ' in spanish and key not in multi_option_allowed:
        errors.append(f'More than one Spanish translation (keep one primary Mexican option): {key}: {spanish}')
for spanish, keys in by_spanish.items():
    if len(keys) > 1:
        errors.append(f'Two English words share one Spanish translation: {keys}: {spanish}')
for key, spanish in words.items():
    if not isinstance(spanish, str) or not spanish.strip():
        errors.append(f'Invalid Spanish text: {key}')
        continue
    for option in spanish.split(' / '):
        if key not in articleless_phrases and not option.startswith(('el ', 'la ', 'los ', 'las ')):
            errors.append(f'Spanish option missing definite article: {key}: {option}')
    if any(c in spanish for c in ('\n', '\r', '[', ']')):
        errors.append(f'Unescaped control or formatting token: {key}')

for key, item in catalog.items():
    if key not in words:
        errors.append(f'Learning catalog key not in vocabulary: {key}')
    elif item.get('spanish') != words[key]:
        errors.append(f'Learning catalog translation not synchronized: {key}')
    if categories.get(key) != item.get('category'):
        errors.append(f'Learning catalog category mismatch: {key}')

for alias, target in aliases.items():
    if alias in words or target not in words:
        errors.append(f'Broken vocabulary alias: {alias} -> {target}')

for scene in (ROOT / 'scenes').rglob('*.tscn'):
    scene_count += 1
    contents = scene.read_text(encoding='utf-8')
    for node in re.split(r'(?=^\[node\s)', contents, flags=re.M):
        word = re.search(r'^metadata/word_key = "([^"]+)"', node, flags=re.M)
        if not word:
            continue
        key = word.group(1)
        scene_tags += 1
        if aliases.get(key, key) not in words and key not in _words.get('removed_with_objects', []):
            errors.append(f'Unknown word key: {scene.relative_to(ROOT)}: {key}')
        if re.search(r'^metadata/spanish = ', node, flags=re.M):
            translated_tags += 1
            errors.append(f'Cached Spanish copy (words.json is the only source): {scene.relative_to(ROOT)}: {key}')

if words.get('fish') != 'el pez (animal) / el pescado (comida)':
    errors.append('Fish needs both animal and food senses')
print(f'Checked {len(words)} dictionary translations, {len(catalog)} catalog records, '
      f'{scene_tags} word tags including {translated_tags} Spanish tags, '
      f'{len(aliases)} aliases in {scene_count} Godot scenes.')
if errors:
    print(f'FAIL: {len(errors)} issues')
    for err in errors[:50]:
        print('ERROR:', err)
    sys.exit(1)
print('PASS: words.json translations, catalog, aliases and articles are consistent; scenes hold only word keys.')
