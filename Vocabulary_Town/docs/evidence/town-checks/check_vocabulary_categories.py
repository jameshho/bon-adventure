"""Read-only vocabulary category integrity checker. Run: python docs/evidence/town-checks/check_vocabulary_categories.py"""
from pathlib import Path
import collections
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
DATA = ROOT / 'data'
sys.path.insert(0, str(ROOT / 'tools'))
import word_data  # data/words.json is the only word source
_words = word_data.load()
vocabulary = word_data.vocabulary(_words)
categories = word_data.categories(_words)
aliases = _words['aliases']
catalog = word_data.catalog(_words)
allowed = set(_words['categories'])
failures = []
checks = 0

def require(condition, detail):
    global checks
    checks += 1
    if not condition:
        failures.append(detail)

for issue in word_data.problems(_words):
    require(False, issue)
require(set(vocabulary) == set(categories), 'Categories must have exactly one mapping per vocabulary key')
require(set(categories.values()) <= allowed, 'Unrecognized category labels')
for alias, canonical in aliases.items():
    require(alias not in vocabulary and canonical in vocabulary, f'Invalid alias: {alias}')
for key, record in catalog.items():
    require(key in vocabulary, f'Asset without vocabulary translation: {key}')
    require(record.get('category') == categories.get(key), f'Asset category differs from dictionary: {key}')
for excluded in ['couch', 'exam bed', 'science', 'skeleton', 'student desk', 'petri dish', 'microscope']:
    require(excluded not in vocabulary and excluded not in categories, f'Previously deleted term restored: {excluded}')
scene_count = 0
word_count = 0
category_tags = 0
for scene in sorted((ROOT / 'scenes').rglob('*.tscn')):
    scene_count += 1
    raw = scene.read_text(encoding='utf-8')
    for block in re.split(r'(?=^\[node\s)', raw, flags=re.M):
        match = re.search(r'^metadata/word_key = "([^"]+)"$', block, re.M)
        tag = re.search(r'^metadata/category = "([^"]+)"$', block, re.M)
        if not match:
            continue
        key = match.group(1)
        if not key:
            continue
        word_count += 1
        canonical = aliases.get(key, key)
        # removed_with_objects tags are intentional: the game removes those objects at load.
        require(canonical in vocabulary or key in _words.get('removed_with_objects', []), f'Missing interactive word: {scene.relative_to(ROOT)} / {key}')
        if tag:
            category_tags += 1
            require(False, f'Cached category copy (words.json is the only source): {scene.relative_to(ROOT)} / {key}')
    # Godot subresources and external IDs must be resolvable within the saved scene.
    externals = set(re.findall(r'\[ext_resource .*?\bid="([^"]+)"', raw))
    internals = set(re.findall(r'\[sub_resource .*?\bid="([^"]+)"', raw))
    for reference in re.findall(r'ExtResource\("([^"]+)"\)', raw):
        require(reference in externals, f'Missing external ID: {scene.relative_to(ROOT)} / {reference}')
    for reference in re.findall(r'SubResource\("([^"]+)"\)', raw):
        require(reference in internals, f'Missing subresource ID: {scene.relative_to(ROOT)} / {reference}')
    for asset_path in re.findall(r'\[ext_resource [^\n]*?\bpath="res://([^\"]+)"', raw):
        require((ROOT / asset_path).exists(), f'Missing external resource: {scene.relative_to(ROOT)} -> {asset_path}')
print(f'{checks} read-only checks, {len(failures)} failures; {len(vocabulary)} words, '
      f'{len(categories)} categories, {len(catalog)} prefab records, {scene_count} scenes, '
      f'{word_count} scene word keys, {category_tags} embedded category labels')
if failures:
    for failure in failures[:50]:
        print('ERROR:', failure)
    sys.exit(1)
print('PASS: vocabulary, scenes, learning catalog and aliases are consistent')
