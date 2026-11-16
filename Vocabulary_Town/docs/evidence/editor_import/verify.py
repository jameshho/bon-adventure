"""Check source identities using Godot's ignored-directory convention."""
from pathlib import Path
import re
from collections import defaultdict

root = Path(__file__).resolve().parents[3]
assert (root / 'backups/.gdignore').is_file(), 'Backups must stay outside Godot import'
identities = defaultdict(list)
classes = defaultdict(list)
for path in root.rglob('*'):
    if not path.is_file() or '.godot' in path.parts:
        continue
    if any((parent / '.gdignore').exists() for parent in path.parents if parent != root.parent):
        continue
    if path.suffix in ('.tscn', '.tres'):
        match = re.search(r'\buid="([^"]+)"', path.open().readline())
        if match:
            identities[match[1]].append(str(path.relative_to(root)))
    elif path.suffix == '.gd':
        for name in re.findall(r'^class_name\s+(\w+)', path.read_text(), re.M):
            classes[name].append(str(path.relative_to(root)))
assert not {k:v for k,v in identities.items() if len(v)>1}, 'Duplicate scene/resource UIDs'
assert not {k:v for k,v in classes.items() if len(v)>1}, 'Duplicate global script classes'
assert classes['DriveableVehicle'] == ['scripts/world/driveable_vehicle.gd']
print('PASS: backups ignored; scene/resource UIDs unique; global classes unique; vehicle class canonical')
