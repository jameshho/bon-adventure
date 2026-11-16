"""Replace legacy single-shape school/hospital items with coherent prefab roots."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
for building in ['school','hospital']:
    path=ROOT/f'scenes/buildings/{building}.tscn';text=path.read_text()
    chunks=re.split(r'(?=\[node )',text);header=chunks.pop(0);result=[];skip=None;refs={};count=0
    keys={'microscope','notebook','pencil','globe'} if building=='school' else {'medicine','thermometer','stethoscope','bandage','iv stand','wheelchair','crutches'}
    for chunk in chunks:
        match=re.match(r'\[node name="([^"]+)"[^\n]*parent="([^"]+)"',chunk)
        if not match:result.append(chunk);continue
        name,parent=match.groups()
        if parent!='.':
            if skip and (parent==skip or parent.startswith(skip+'/')):continue
            result.append(chunk);continue
        skip=None
        key=re.search(r'metadata/word_key = "([^"]+)"',chunk)
        if not key or key[1] not in keys:result.append(chunk);continue
        key=key[1];skip=name
        # The former wheelchair and crutches were spread over several targets.
        if name in ['WheelchairWheel','WheelchairWheel_2','Crutches_2']:continue
        ref='clear_'+key.replace(' ','_');refs[ref]=key
        pos=re.search(r'position = Vector3\(([^)]+)\)',chunk);xyz=[float(n) for n in pos[1].split(',')]
        if key in ['microscope','notebook','pencil']:xyz[1]=.88
        if key=='globe':xyz[1]=1.75
        if key=='iv stand':xyz[1]=.09
        if key=='wheelchair':xyz[1]=.08
        if key=='crutches':xyz[0]=3.75;xyz[1]=.08
        if key=='thermometer':xyz=[2.85,1.05,-3.6]
        if key=='stethoscope':xyz=[3.65,1.05,-3.6]
        if key=='bandage':xyz=[3.3,1.05,-4.05]
        if key=='medicine':xyz[1]-=.2
        result.append(f'[node name="{name}" parent="." instance=ExtResource("{ref}")]\nposition = Vector3('+', '.join(map(str,xyz))+')\n\n');count+=1
    if refs:
        idx=header.index('[sub_resource')
        header=header[:idx]+''.join(f'[ext_resource type="PackedScene" path="res://scenes/props/vocabulary/{key.replace(" ","_")}.tscn" id="{ref}"]\n' for ref,key in refs.items())+'\n'+header[idx:]
        path.write_text(header+''.join(result))
    print(building,':',count,'recognizable replacements')
