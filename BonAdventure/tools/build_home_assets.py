"""Generate grouped, editable vocabulary furniture and low-poly tree species."""
from pathlib import Path
import math
from scene_writer import Scene,v
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'scenes/props/home';OUT.mkdir(exist_ok=True)
# These component labels were intentionally removed from the learning system.
NON_LEARNING_COMPONENTS = {"backrest", "armrest", "umbrella stand"}
def new(name,word):
 s=Scene()
 props = '' if word in NON_LEARNING_COMPONENTS else f'metadata/word_key = "{word}"'
 s.node(name,parent=None,props=props)
 return s
def hit(s,p,size,parent='.',solid=False):
 b=s.node('Body' if solid else 'StudyArea','StaticBody3D' if solid else 'Area3D',parent,'collision_layer = 1\ncollision_mask = 0')
 s.node('Shape','CollisionShape3D',b,'position = '+v(p)+'\nshape = '+s.res('BoxShape3D','size = '+v(size)))
def part(s,name,p,size,color,word='',parent='.',solid=False):
 n=s.node(name,parent=parent,props='position = '+v(p)+(f'\nmetadata/word_key = "{word}"' if word else ''))
 s.box('Visual',(0,0,0),size,color,n);hit(s,(0,0,0),size,n,solid);return n
def cyl(s,name,p,r,h,c,parent='.',rotation=None,top=None):
 s.node(name,'MeshInstance3D',parent,'position = '+v(p)+(('\nrotation = '+v(rotation)) if rotation else '')+'\nmesh = '+s.res('CylinderMesh',f'top_radius = {r if top is None else top}\nbottom_radius = {r}\nheight = {h}\nradial_segments = 12')+'\nmaterial_override = '+s.mat(c))
def save(s,name):s.save(OUT/(name+'.tscn'))
s=new('Sofa','sofa')
part(s,'Frame',(0,.38,0),(3.8,.48,1.35),'6f91a3',solid=True)
part(s,'Backrest',(0,.98,.49),(3.8,1.04,.3),'6f91a3',solid=True)
for x in [-1.77,1.77]:part(s,'Armrest',(x,.75,0),(.3,.9,1.35),'68899b',solid=True)
for x in [-1.08,0,1.08]:part(s,'SeatCushion',(x,.70,-.12),(1.03,.22,.96),'9bb8c6','cushion')
for x,c in [(-1.22,'d9aa93'),(1.22,'d4c790')]:
 n=part(s,'ThrowPillow',(x,1.02,.23),(.5,.48,.20),c,'pillow');s.box('Seam',(0,0,-.108),(.42,.40,.012),'eadcc3',n)
for x in [-1.5,1.5]:
 for z in [-.45,.45]:s.box('Foot',(x,.10,z),(.12,.2,.12),'75553e',solid=True)
save(s,'sofa')
# Hollow cabinet carcass: moving trays have real space behind their faces.
s=new('DrawerCabinet','cabinet')
for x in [-.85,.85]:s.box('Side',(x,.69,.62),(.07,1.35,1.24),'8db3a8',solid=True)
s.box('Back',(0,.69,1.21),(1.7,1.35,.06),'8db3a8',solid=True)
s.box('Base',(0,.13,.62),(1.7,.12,1.24),'648c83',solid=True)
s.box('Divider',(0,.77,.62),(.06,1.1,1.16),'8db3a8',solid=True)
s.box('LowerFront',(0,.40,.015),(1.64,.46,.07),'8db3a8',solid=True)
for x in [-.43,.43]:
 n=s.node('Drawer',props='position = '+v((x,.96,-.015))+'\nmetadata/word_key = "drawer"\nmetadata/door_state = {"open": false, "type": "slide", "shift": Vector3(0, 0, -0.62)}')
 s.box('Face',(0,0,0),(.75,.47,.07),'a8cec3',n,True)
 s.box('Handle',(0,0,-.065),(.27,.035,.06),'cd9b57',n)
 s.box('TrayBottom',(0,-.19,.43),(.70,.04,.80),'e9d5ad',n)
 for dx in [-.34,.34]:s.box('TraySide',(dx,-.08,.43),(.03,.22,.80),'e9d5ad',n)
 s.box('TrayBack',(0,-.08,.82),(.70,.22,.035),'e9d5ad',n)
 for dx in [-.18,0,.18]:s.box('Utensil',(dx,-.16,.35),(.035,.018,.32),'c4cbd0',n)
save(s,'drawer_cabinet')
s=new('Guitar','guitar')
# Two bouts and a narrow waist produce the familiar acoustic silhouette.
s.orb('LowerBout',(0,.38,0),(.63,.66,.18),'b77c43');s.orb('UpperBout',(0,.73,0),(.48,.43,.18),'b77c43')
s.orb('SoundboardLower',(0,.38,.07),(.57,.60,.055),'dfb778');s.orb('SoundboardUpper',(0,.73,.07),(.43,.38,.055),'dfb778')
s.orb('SoundHole',(0,.70,.106),(.19,.19,.015),'382c27')
s.box('Neck',(0,1.12,0),(.105,.64,.075),'79543b');s.box('Fingerboard',(0,1.12,.045),(.108,.65,.018),'44352d')
s.box('Headstock',(0,1.53,0),(.15,.22,.07),'9d7046');s.box('Bridge',(0,.36,.11),(.25,.055,.035),'49382b')
for i in range(6):s.box('String',(-.037+i*.015,.91,.126),(.003,1.12,.003),'e3d4af')
for y in [1.01,1.10,1.19,1.28,1.37]:s.box('Fret',(0,y,.058),(.11,.007,.005),'cbbca3')
for x in [-.1,.1]:
 for y in [1.47,1.53,1.59]:s.orb('TuningPeg',(x,y,0),(.06,.035,.04),'dbd4c2')
s.box('StandFoot',(0,.035,0),(.58,.07,.4),'495459');s.box('StandPost',(0,.40,-.14),(.045,.75,.045),'495459')
hit(s,(0,.82,0),(.65,1.64,.30));save(s,'guitar')
s=new('UmbrellaStand','umbrella stand')
# Open basket with a visible rim rather than a solid block swallowing the umbrellas.
s.box('Base',(0,.035,0),(.34,.07,.31),'71978e',solid=True)
for x in [-.16,.16]:s.box('Side',(x,.36,0),(.025,.65,.31),'88aaa1')
for z in [-.145,.145]:s.box('Side',(0,.36,z),(.34,.65,.025),'88aaa1')
hit(s,(0,.35,0),(.35,.7,.32),solid=True)
for i,c in enumerate(['c17d68','647eaa','dfb854']):
 n=s.node('Umbrella',props='position = '+v((-.10+i*.10,0,(-.06 if i%2 else .05)))+f'\nrotation = Vector3(0,0,{(i-1)*.08})\nmetadata/word_key = "umbrella"')
 cyl(s,'Shaft',(0,.75,0),.012,1.16,'c4c9c6',n)
 cyl(s,'FoldedCanopy',(0,.81,0),.055,.62,c,n,top=.015)
 # Curved crook made from a light 10-segment arc.
 for j in range(10):
  a=j*math.pi/9;s.orb('Handle',(math.cos(a)*.045+.045,1.31+math.sin(a)*.055,0),(.025,.025,.025),'675244',n)
 hit(s,(0,1,0),(.10,.69,.12),n)
save(s,'umbrella_stand')
s=new('CoatRack','coat rack');cyl(s,'Base',(0,.055,0),.32,.11,'795940');cyl(s,'Post',(0,1.03,0),.045,1.95,'b18b62')
for i in range(4):
 a=i*math.pi/2;n=s.node('Branch',props=f'rotation = Vector3(0,{a},0)')
 s.box('HookArm',(.16,1.68,0),(.34,.05,.055),'b18b62',n,rotation=(0,0,.4))
 cyl(s,'HookTip',(.30,1.77,0),.035,.14,'b18b62',n)
 s.orb('Cap',(.30,1.85,0),(.09,.09,.09),'c4a57d',n)
hit(s,(0,1,0),(.65,2,.65),solid=True);save(s,'coat_rack')
s=new('Curtains','curtain');cyl(s,'Rod',(0,2.02,0),.022,2.25,'957857',rotation=(0,0,math.pi/2))
for side in [-1,1]:
 n=s.node('Panel',props='position = '+v((side*.89,1.04,0)))
 for j in range(5):s.box('Fold',((j-2)*.068,0,math.sin(j*math.pi/2)*.035),(.077,1.9,.045),'e4cdb9',n)
 hit(s,(0,0,0),(.36,1.9,.12),n)
save(s,'curtains')
for key,c,label in [('rice','e9dfc0','ARROZ'),('pasta','789b77','PASTA'),('cereal','dfa852','CEREAL')]:
 s=new(key.title(),key)
 s.box('Package',(0,.21,0),(.30,.42,.18),c)
 s.box('Label',(0,.29,-.096),(.26,.15,.012),'f8edd5')
 s.text('Name',label,(0,.29,-.105),rot=math.pi,size=12)
 # Contents visible through the display panel; geometry distinguishes grains, spaghetti, cereal.
 s.box('DisplayWindow',(0,.12,-.098),(.25,.13,.012),'685c48')
 if key=='pasta':
  for i in range(9):s.box('Spaghetti',(-.104+i*.026,.12,-.113),(.013,.11,.014),'e7ca74')
 else:
  for i in range(18):s.orb('Grain' if key=='rice' else 'Flake',((i%6-2.5)*.037,.078+(i//6)*.037,-.114),(.025,.012,.012) if key=='rice' else (.03,.028,.014),'f7ebcb' if key=='rice' else 'e9bf69')
 hit(s,(0,.21,0),(.30,.42,.20));save(s,key)
for key in ['apple_tree','orange_tree','maple_tree']:
 s=new(''.join(w.title() for w in key.split('_')),'tree');maple=key=='maple_tree'
 cyl(s,'Trunk',(0,1.08,0),.17,2.16,'886244',top=.12);hit(s,(0,1.08,0),(.34,2.16,.34),solid=True)
 for i in range(5):
  a=i*math.tau/5
  n=s.node('Branch',props=f'rotation = Vector3(0,{a},0)');cyl(s,'Wood',(.35,1.92,0),.065,1.1,'886244',n,rotation=(0,0,-.65),top=.025)
  x,z=math.cos(a)*.70,math.sin(a)*.70
  s.orb('Foliage',(x,2.65+(i%2)*.3,z),(1.6,1.7,1.5),['c8763d','d89a48','b95937'][i%3] if maple else ('569354' if key=='apple_tree' else '3f8052'))
  if not maple:
   for j in range(3):
    a2=a+j*.7;x2,z2=x+math.cos(a2)*.64,z+math.sin(a2)*.64
    n=s.node('Fruit',props='position = '+v((x2,2.42+j*.29,z2))+f'\nmetadata/word_key = "{"apple" if key=="apple_tree" else "orange"}"')
    s.orb('FruitMesh',(0,0,0),(.22,.23,.22),'cf493e' if key=='apple_tree' else 'f39928',n);hit(s,(0,0,0),(.24,.25,.24),n)
    s.box('Stem',(0,.135,0),(.025,.06,.025),'6e593b',n)
 hit(s,(0,2.8,0),(2.8,1.6,2.8))
 s.save(ROOT/'scenes/props/nature'/f'{key}.tscn')
print('Generated 9 home assets and 3 tree species')
s=new('BedsideLamp','lamp')
cyl(s,'Base',(0,.025,0),.15,.05,'a78a61')
cyl(s,'Stem',(0,.21,0),.025,.35,'a78a61')
cyl(s,'Shade',(0,.47,0),.22,.26,'f0dfb6',top=.14)
cyl(s,'Bulb',(0,.37,0),.065,.06,'fff4cc')
hit(s,(0,.30,0),(.44,.60,.44));save(s,'bedside_lamp')
