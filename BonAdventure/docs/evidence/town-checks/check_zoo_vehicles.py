"""Run: python docs/evidence/town-checks/check_zoo_vehicles.py
Static asset/reference checks only. Run check_zoo_vehicles.gd for engine tests.
"""
from pathlib import Path
import json,re,sys,zipfile
P=Path(__file__).resolve().parents[3]
checks=0
issues=[]
def check(ok,msg):
 global checks
 checks+=1
 if not ok:issues.append(msg)
def data(path):return json.loads((P/path).read_text())
sys.path.insert(0,str(P/'tools'))
import word_data  # data/words.json is the only word source
_words=word_data.load()
vocab=word_data.vocabulary(_words); categories=word_data.categories(_words); catalog=word_data.catalog(_words)
check(set(vocab)==set(categories),'Every dictionary entry should have a category')
for key,translation,category in [('gate','el portón / la puerta de la cerca','Building Parts'),('helicopter','el helicóptero','Vehicles')]:
 check(vocab.get(key)==translation,key+' translation missing')
 check(categories.get(key)==category,key+' category missing')
 check(catalog.get(key,{}).get('spanish')==translation,key+' learning-catalog translation missing')
zoo=(P/'scenes/world/park_zoo.tscn').read_text()
main=(P/'scripts/core/main.gd').read_text()
interaction=(P/'scripts/player/interaction_controller.gd').read_text()
player=(P/'scripts/player/player_controller.gd').read_text()
gate=(P/'scenes/world/zoo_gate.tscn').read_text()
check('Shelter roof2' not in zoo,'Stray canopy remains near giraffe')
for support in ['Shelter post3','Shelter post4','@StaticBody3D@346','@StaticBody3D@348']:
 check(support not in zoo,'Old shelter support/collider remains: '+support)
check('[node name="Giraffe"' in zoo,'Giraffe removed')
check('Fence post12' not in zoo,'Fence post blocks entrance')
for n in ('Fence rail','Fence rail3','Fence boundary2'):
 mat=re.search(r'\[node name="'+n+r'".*?transform = Transform3D\(([^)]+)\)',zoo,re.S)
 check(mat is not None and '0.33333333' in mat.group(1) and '-38,' in mat.group(1),'Left fence section not shortened: '+n)
for name in ('Fence rail right low','Fence rail right high','Fence boundary right','RightFenceSolid','RightFenceShape','ZooEntranceGate'):
 check('name="'+name+'"' in zoo,'Missing fence segment '+name)
check('position = Vector3(-34, 0, 69)' in zoo,'Gate not at opened fence gap')
check(gate.count('type="StaticBody3D"')==2,'Both gate leaves require solid collisions')
check(gate.count('type="CollisionShape3D"')==3,'Both solid leaves + pick zone required')
check('type="Area3D"' in gate and 'metadata/word_key = "gate"' in gate,'Gate vocabulary selection area missing')
check('toggle_gate' in (P/'scripts/world/zoo_gate.gd').read_text(),'Gate controller missing')
vehicles=list((P/'scenes/props/vehicles').glob('*.tscn'))
check(len(vehicles)==9,'Expected eight road vehicles and one helicopter')
for path in vehicles:
 s=path.read_text();n=path.stem
 check('res://scripts/world/driveable_vehicle.gd' in s,'No driving controller: '+n)
 check('script = ExtResource("drive_script")' in s,'Driver not attached: '+n)
 check(('helicopter = true' in s)==(n=='helicopter'),'Wrong aircraft setting '+n)
 check(bool(re.search(r'^metadata/word_key = ',s,re.M)),'Vehicle lost its vocabulary '+n)
 if (m:=re.search(r'\[gd_scene load_steps=(\d+)',s)):
  check(int(m[1])==1+len(re.findall(r'^\[(?:ext|sub)_resource ',s,re.M)),'Bad load_steps: '+n)
check('register_driveable_vehicles()' in main,'Vehicle registration not called')
check('toggle_zoo_gate_if_near()' in main and 'toggle_vehicle()' in main,'E-key actions not registered')
check('closest_vehicle()' in main and 'board_vehicle' in player and 'leave_vehicle' in player,'Vehicle seat handling missing')
check('set_meta("driveable_vehicle", true)' in (P/'scripts/world/driveable_vehicle.gd').read_text(),'Driver identification missing')
check('show_word(obj)' in interaction and 'word_studied.emit(key)' in interaction,'Vocabulary interaction broken')
print(f'{checks} zoo/vehicle static checks, {len(issues)} failures')
for i in issues:print('FAIL:',i)
sys.exit(bool(issues))
