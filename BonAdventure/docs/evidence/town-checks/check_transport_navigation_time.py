"""Static checks for travel, wayfinding and time vocabulary objects.

Run: python docs/evidence/town-checks/check_transport_navigation_time.py
Run Godot integration separately: godot --headless --path . --script res://docs/evidence/town-checks/check_transport_navigation_time.gd
"""
from pathlib import Path
import itertools
import json
import math
import re
import sys

P = Path(__file__).resolve().parents[3]
read_json = lambda f: json.loads((P / f).read_text(encoding="utf-8"))
sys.path.insert(0, str(P / 'tools'))
import word_data  # data/words.json is the only word source
_words = word_data.load()
vocab = word_data.vocabulary(_words)
categories = word_data.categories(_words)
catalog = word_data.catalog(_words)
aliases = _words['aliases']
manifest = read_json('docs/evidence/town-checks/TRANSPORT_NAV_TIME_ADDITIONS.json')
original_stop = 'la parada de autobús'
scene = (P / manifest['world_scene']).read_text(encoding='utf-8')
failures=[]
count=0

def check(condition, message):
 global count
 count+=1
 if not condition:
  failures.append(message)

new=manifest['added']
keys=list(new)
check(len(keys)==16 and len(set(keys))==16,'Expected 16 unique new keys')
check('bus stop' not in new,'Bus stop must be reused, not duplicated')
check(vocab.get('bus stop')==original_stop,'Bus stop original translation must be preserved')
check(categories.get('bus stop')=='Streets & Town','Bus stop original category must be preserved')
check(len(re.findall(r'^metadata/word_key = "bus stop"$',scene,re.M))==2,'Existing two bus-stop targets preserved')
check(all(k in vocab and k in catalog for k in keys),'Travel dictionary/catalog entries were removed')
check(not set(keys).intersection(aliases),'New dictionary entries accidentally shadow aliases')
check(set(vocab)==set(categories),'Vocabulary/category keys disagree')
check(scene.count('[node name="TravelLearningHub" type="Node3D" parent="."]')==1,'Missing new travel display')
check('travel_board' in scene and 'travel_pole' in scene,'Sign boards are absent')
check('type="StaticBody3D" parent="TravelLearningHub"' not in scene,'Avoid new solid blockers')
check(scene.count('instance=ExtResource("travel_')==16,'Exactly 16 new instances required')
check('la estación de policía' not in vocab['station'],'Train station must not mean police station')
check(vocab.get('tomorrow')=='mañana' and vocab.get('morning')=='la mañana','Tomorrow and morning need distinct contexts')
check(vocab.get('near')=='cerca' and vocab.get('far')=='lejos','Near/far adverbs must not receive articles')
check(all(categories[k]=='Time & Directions' for k in manifest['navigation_keys']),'Direction categories')
check(all(categories[k]=='Time & Directions' for k in manifest['time_keys']),'Time categories')

boxes=[]
for key,entry in new.items():
 span=entry['spanish']; cat=entry['category']; pos=entry['position']
 check(vocab.get(key)==span,'Translation mismatch: '+key)
 check(categories.get(key) in _words['categories'],'Category missing: '+key)
 check(catalog.get(key,{}).get('spanish')==span,'Catalog label mismatch: '+key)
 check(catalog.get(key,{}).get('category')==categories.get(key),'Catalog category mismatch: '+key)
 path=P/entry['prefab']; check(path.exists(),'Prefab does not exist: '+key)
 if not path.exists():continue
 raw=path.read_text(encoding='utf-8')
 check(raw.count('type="Area3D"')==1 and 'collision_layer = 2' in raw, 'Prefab does not have one interactive Area3D: '+key)
 check(raw.count('type="CollisionShape3D"')==1 and 'shape = SubResource("hit")' in raw,'Interactive hitbox missing: '+key)
 check('type="StaticBody3D"' not in raw,'Prefab must not add movement-blocking collision: '+key)
 check(raw.count('type="MeshInstance3D"')>=2,'Prefab must have recognisable 3D components: '+key)
 check(f'metadata/word_key = "{key}"' in raw,'Prefab key mismatch: '+key)
 check('metadata/spanish' not in raw and 'metadata/category' not in raw,'Prefab caches word data: '+key)
 check(re.search(r'^\[gd_scene load_steps=(\d+)',raw,re.M) is not None,'Missing load_steps: '+key)
 if re.search(r'^\[gd_scene load_steps=(\d+)',raw,re.M):
  load_steps=int(re.search(r'^\[gd_scene load_steps=(\d+)',raw,re.M).group(1))
  check(load_steps==1+len(re.findall(r'^\[sub_resource ',raw,re.M)),'Bad prefab load_steps: '+key)
 check(f'path="res://{entry["prefab"]}"' in scene,'World lacks external resource: '+key)
 # The instance can be located precisely with a node-block split.
 blocks=re.split(r'(?=^\[node )',scene,flags=re.M)
 matching=[b for b in blocks if f'instance=ExtResource("travel_{key.replace(chr(32), chr(95))}")' in b]
 check(len(matching)==1,'Exactly one world instance expected for '+key)
 if matching:
  block=matching[0]
  check('metadata/spanish' not in block and 'metadata/category' not in block,'World scene caches word data: '+key)
  check('metadata/learning_object = true' in block,'World instance is not discoverable: '+key)
  check(f'position = Vector3({", ".join(str(n) for n in pos)})' in block,'World prefab position mismatch: '+key)
 check(all(-32 <= v <= 0 for v in [pos[0]]) and 84 < pos[2] < 94,'Placement should be beside original bus stop: '+key)
 h=[1.06,.76,.28]
 if key=='train':h=[2.12,1.65,1.38]
 if key=='station':h=[1.36,.92,.30]
 if key=='ticket':h=[1.12,.82,.29]
 center=[pos[0],pos[1]+(.82 if key=='train' else 0),pos[2]]
 low=[c-s/2 for c,s in zip(center,h)]; high=[c+s/2 for c,s in zip(center,h)]
 boxes.append((key,(low,high)))
 # A learner can stand on the open side and reach the 8 m vocabulary ray.
 standing=[center[0],center[1],center[2]-2]
 check(math.dist(standing,center)<8,'Interaction unreachable: '+key)
for (ka,(lo_a,hi_a)),(kb,(lo_b,hi_b)) in itertools.combinations(boxes,2):
 overlap=all(lo_a[i]<hi_b[i]-.01 and lo_b[i]<hi_a[i]-.01 for i in range(3))
 check(not overlap,f'New hitboxes overlap: {ka}, {kb}')

# Pure geometric proxy for a learner aiming from two meters in front of each object.
# This is NOT a Godot engine or popup test. The matching runtime test is in the .gd file.
for key, (lower, upper) in boxes:
 center=[(lower[i]+upper[i])/2 for i in range(3)]
 eye_z=center[2]-2
 obstructors=[]
 for other, (other_lo,other_hi) in boxes:
  if other==key:continue
  # The aiming ray travels horizontally along +Z at the target center height.
  if other_lo[0]<=center[0]<=other_hi[0] and other_lo[1]<=center[1]<=other_hi[1]:
   if other_hi[2]>eye_z and other_lo[2]<lower[2]:
    obstructors.append(other)
 check(not obstructors,'Ray to '+key+' could hit nearer new vocabulary item(s): '+str(obstructors))

print(f'{count} transportation/navigation/time static checks; {len(failures)} failures; {len(new)} new targets and existing bus stop retained')
for failure in failures: print('FAIL',failure)
sys.exit(1 if failures else 0)
