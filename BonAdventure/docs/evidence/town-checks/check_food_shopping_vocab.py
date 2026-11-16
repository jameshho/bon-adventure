"""Static integrity and geometry regression for the everyday-food expansion.

Run: python docs/evidence/town-checks/check_food_shopping_vocab.py
This is not an engine runtime test. For 3D physics and interactive popup checks
use: godot --headless --path . --script res://docs/evidence/town-checks/check_food_shopping_vocab.gd
"""
import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DATA = ROOT / 'data'
sys.path.insert(0, str(ROOT / 'tools'))
import word_data  # data/words.json is the only word source
_words = word_data.load()
words = word_data.vocabulary(_words)
categories = word_data.categories(_words)
catalog = word_data.catalog(_words)
manifest = json.loads((ROOT / 'docs/evidence/town-checks/FOOD_SHOPPING_VOCAB_ADDITIONS.json').read_text())
failures = []
checks = 0


def test(ok, why):
    global checks
    checks += 1
    if not ok:
        failures.append(why)


def scene_blocks(path):
    return re.split(r'(?=^\[node )',path.read_text(encoding='utf-8'),flags=re.M)


def parse_xyz(value):
    return [float(s) for s in value.split(',')]


def aabb_for(position, size):
    return [[p-s/2 for p,s in zip(position,size)], [p+s/2 for p,s in zip(position,size)]]


def boxes_overlap(first, second):
    return all(first[0][i] < second[1][i] - 0.001 and second[0][i] < first[1][i] - 0.001 for i in range(3))


all_new = set(manifest['added'])
found = set()
for room, children in manifest['scenes'].items():
    path = ROOT / 'scenes/buildings' / (room+'.tscn')
    content = path.read_text(encoding='utf-8')
    objects = []
    keys = []
    for child in children:
        key = child['word_key']
        position = child['position']
        found.add(key)
        test(key not in keys, f'{room}: duplicate new vocabulary key {key}')
        keys.append(key)
        test(key in words, f'Missing main dictionary key: {key}')
        test(key in categories and key in catalog, f'Missing category/catalog: {key}')
        test(words.get(key) == manifest['added'][key]['spanish'], f'Wrong Spanish: {key}')
        test(catalog[key]['spanish'] == words[key], f'Catalog label mismatched: {key}')
        test(catalog[key]['category'] == categories[key], f'Category mismatched: {key}')
        name = key.replace(' ','_')
        prefab = ROOT / 'scenes/props/vocabulary' / (name+'.tscn')
        test(prefab.is_file(), f'Missing prefab: {key}')
        if not prefab.is_file():continue
        s = prefab.read_text(encoding='utf-8')
        test(f'metadata/word_key = "{key}"' in s, f'Prefab key wrong: {key}')
        test('metadata/spanish' not in s and 'metadata/category' not in s, f'Prefab caches word data: {key}')
        test(s.count('type="Area3D"') == 1 and 'collision_layer = 2' in s, f'Prefab needs one detectable Area3D: {key}')
        test(s.count('type="MeshInstance3D"') >= 2, f'Prefab needs recognizable geometry: {key}')
        test('type="StaticBody3D"' not in s and 'script = ' not in s, f'New prefab must not block movement or modify scripts: {key}')
        test(s.count('[node name="Shape" type="CollisionShape3D" parent="Interaction"]') == 1, f'Prefab shape missing: {key}')
        test(f'path="res://scenes/props/vocabulary/{name}.tscn"' in content,f'Scene missing prefab reference: {key}')
        # Parse this exact instance to ensure it has a word key and location.
        nodes = [b for b in scene_blocks(path) if f'instance=ExtResource("fv_{name}")' in b]
        test(len(nodes)==1,f'{room}: prefab not instantiated exactly once: {key}')
        if len(nodes)==1:
            test(f'metadata/word_key = "{key}"' in nodes[0],f'Scene key wrong: {key}')
            test('metadata/spanish' not in nodes[0],f'Scene caches word data: {key}')
            test(f'metadata/learning_object = true' in nodes[0],f'Not a discovery object: {key}')
            match=re.search(r'position = Vector3\(([^)]+)\)',nodes[0])
            test(bool(match) and parse_xyz(match.group(1))==position,f'Unexpected scene position: {key}')
        # Colliders are 1.1m cubes, centered .45m above prefab bases.
        collider=aabb_for([position[0],position[1]+.45,position[2]], [1.10,.94,1.10])
        objects.append((key,collider))
        test(abs(position[0])>4 and abs(position[0])<6, f'{key}: display must be at room side')
        test(position[1]>2 and position[1]<3, f'{key}: shelf level must be accessible')
        from_aisle=[math.copysign(1.5, position[0]), position[1]+.45, position[2]-.7]
        distance=math.dist(from_aisle,[position[0],position[1]+.45,position[2]])
        test(distance < 8, f'{key}: outside player interaction distance: {distance}')
    for i,(ka,a) in enumerate(objects):
        for kb,b in objects[i+1:]:
            test(not boxes_overlap(a,b), f'{room}: {ka} and {kb} interact hitboxes overlap')
    test('EverydayVocabularyLeftShelf' in content and 'EverydayVocabularyRightShelf' in content,
         f'{room}: new assets must rest on wall mounted shelves')

test(found == all_new, 'At least one requested term is not placed in an active scene')
for older in ['coffee maker', 'steak', 'cash', 'receipt', 'price tag', 'cup','plate']:
    test(older in words and older not in all_new, f'Preexisting concept overwritten or aliased: {older}')

print(f'{checks} food-and-shopping static checks, {len(failures)} failures, {len(all_new)} independent words placed in two existing stores')
for error in failures: print('FAIL:',error)
sys.exit(1 if failures else 0)
