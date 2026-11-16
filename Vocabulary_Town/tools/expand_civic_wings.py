"""Author themed, walkable school/hospital extensions and vocabulary prefabs.
Does not regenerate existing shop scenes or modify existing vocabulary assets.
"""
from pathlib import Path
import json, math, re
ROOT=Path(__file__).resolve().parents[1]
# Reuse the scene serializer without running the shop asset generator.
serializer=(ROOT/'tools/build_learning_assets.py').read_text().split('CATALOG={}')[0]
exec(compile(serializer,str(ROOT/'tools/build_learning_assets.py'),'exec'))
CATALOG=word_data.catalog(word_data.load())
NEW={}
def asset(key,es,category,fn,size):
    es=CANONICAL_TRANSLATIONS.get(key, es)  # Preserve reviewed Spanish on rebuild.
    s=Scene(slug(key).title(),key,es,category);fn(s)
    s.hit((0,size[1]/2,0),size)
    if size[1]>.85 and size[0]>.7:s.hit((0,.35,0),(size[0]*.9,.7,size[2]*.9),True,'Footprint')
    s.save(OUT/(slug(key)+'.tscn'));NEW[key]={'spanish':es,'category':category,'size':size};CATALOG[key]=NEW[key]
def table(s,w=1.4,d=.8,h=.9):
    s.box('Top',(0,h,0),(w,.08,d),WOOD)
    for x in [-w/2+.08,w/2-.08]:
        for z in [-d/2+.08,d/2-.08]:s.box('Leg',(x,h/2,z),(.08,h,.08),WOOD)
def easel(s):
    for x in [-.48,.48]:s.rod('FrontLeg',(x,0,0),(x*.6,1.9,.15),.035,WOOD)
    s.rod('RearLeg',(0,0,.7),(0,1.8,.15),.035,WOOD);s.box('Canvas',(0,1.22,.07),(.95,1.02,.08),W);s.box('Rest',(0,.68,-.03),(1.15,.06,.19),WOOD)
    s.ball('PaintedSun',(.22,1.5,.015),(.22,.22,.025),'dfb84d');s.mesh('PaintedMountain',(0,1.03,.015),(.8,.5,.025),'6b9582','PrismMesh','size = Vector3(0.8, 0.5, 0.025)')
def palette(s):
    s.ball('Wood',(0,.06,0),(.85,.1,.65),WOOD);s.cyl('ThumbHole',(.2,.12,.14),.07,.012,DARK)
    for x,z,c in [(-.22,-.1,'bb493c'),(0,-.18,'dbb547'),(.22,-.08,'447d9e'),(-.25,.12,'55935d')]:s.ball('Paint',(x,.125,z),(.14,.025,.13),c)
def brush(s):s.cyl('Handle',(0,.33,0),.025,.6,WOOD);s.cyl('Ferrule',(0,.66,0),.04,.12,METAL);s.box('Bristles',(0,.8,0),(.1,.2,.045),'966b41')
def scissors(s):
    for x in [-.13,.13]:
        s.ring('FingerLoop',(x,.18,0),.12,.028,'b14d42',scale=(.8,1,1.15))
        s.box('Blade',(x*.4,.49,0),(.05,.5,.025),METAL,rot=(0,0,18 if x<0 else -18))
    s.cyl('Pivot',(0,.37,-.025),.03,.025,DARK,(90,0,0))
def ruler(s):
    s.box('Wood',(0,.035,0),(1,.05,.2),'d0b17a')
    for i in range(11):s.box('Mark',(-.45+i*.09,.064,-.03),(.012,.006,.1 if i%5==0 else .06),DARK)
def painttube(s):
    s.box('Tube',(0,.3,0),(.23,.5,.14),W);s.cyl('Cap',(0,.59,0),.065,.11,DARK);s.box('ColorBand',(0,.31,-.08),(.2,.2,.015),'b84b40');s.box('Crimp',(0,.04,0),(.25,.05,.14),METAL)
def piano(s):
    s.box('Case',(0,.8,.12),(1.85,1.5,.6),DARK);s.box('KeyboardBed',(0,.79,-.37),(1.85,.12,.5),DARK)
    for i in range(21):s.box('IvoryKey',(-.83+i*.083,.87,-.43),(.077,.05,.33),W)
    for i in range(20):
        if i%7 not in [2,6]:s.box('BlackKey',(-.79+i*.083,.92,-.32),(.045,.06,.19),'101c24')
    for x in [-.72,.72]:s.box('FrontLeg',(x,.35,-.45),(.1,.7,.12),DARK)
    for x in [-.12,.12]:s.box('Pedal',(x,.08,-.42),(.07,.035,.18),'b69b59')
def guitar(s,violin=False):
    c='9c5937' if violin else 'b98b49'
    s.ball('LowerBout',(0,.4,0),(.65,.65,.16),c);s.ball('UpperBout',(0,.72,0),(.48,.44,.15),c);s.box('Neck',(0,1.1,0),(.1,.7,.07),'67462e');s.box('Headstock',(0,1.52,0),(.15,.2,.08),c)
    if violin:
        for x in [-.15,.15]:s.box('Fhole',(x,.52,-.09),(.03,.18,.012),DARK,rot=(0,0,15 if x<0 else -15))
        s.rod('Bow',(.43,.2,-.08),(.43,1.5,-.08),.015,WOOD)
    else:s.cyl('SoundHole',(0,.6,-.09),.12,.015,DARK,(90,0,0))
    for x in [-.03,0,.03]:s.rod('String',(x,.3,-.1),(x,1.58,-.07),.004,METAL)
def trumpet(s):
    s.cyl('Bell',(0,.5,0),.2,.28,'ccab50',(0,0,-90),top=.06);s.cyl('BellOpening',(-.15,.5,0),.16,.014,'685932',(0,0,90));s.rod('LeadPipe',(.15,.5,0),(.7,.5,0),.035,'ccab50');s.ring('ValveLoop',(.38,.34,0),.18,.035,'ccab50',scale=(1.4,1,.6))
    for x in [.25,.38,.51]:s.cyl('Valve',(x,.54,0),.03,.25,'ccab50');s.cyl('Button',(x,.69,0),.045,.03,W)
    s.cyl('Mouthpiece',(.75,.5,0),.055,.1,METAL,(0,0,90))
def drum(s):
    s.cyl('Shell',(0,.4,0),.43,.65,'a2493e');s.cyl('DrumHead',(0,.75,0),.44,.04,W)
    for y in [.08,.72]:s.ring('Rim',(0,y,0),.43,.022,METAL,rot=(0,0,0))
    for x in [-.38,.38]:s.rod('TensionRod',(x,.12,-.1),(x,.7,-.1),.012,METAL)
    s.rod('StickA',(-.3,.8,-.25),(.3,.8,.25),.018,WOOD);s.rod('StickB',(-.3,.83,.25),(.3,.83,-.25),.018,WOOD)
def microphone(s):
    s.cyl('Base',(0,.05,0),.3,.1,DARK);s.cyl('Stand',(0,.75,0),.025,1.4,METAL);s.cyl('Handle',(0,1.55,0),.055,.25,DARK);s.ball('MeshHead',(0,1.75,0),(.18,.23,.18),METAL)
    for y in [1.7,1.75,1.8]:s.ring('Grille',(0,y,0),.08,.008,DARK,rot=(0,0,0))
def book(s):
    s.box('Spine',(-.28,.12,0),(.06,.23,.8),'8e4c41');s.box('Pages',(0,.12,0),(.53,.17,.75),W)
    for y in [.015,.225]:s.box('Cover',(0,y,0),(.62,.04,.82),'8e4c41')
    for y in [.07,.12,.17]:s.box('PageEdge',(.269,y,0),(.004,.005,.7),'bfb9aa')
def backpack(s):
    s.ball('Bag',(0,.5,0),(.7,.9,.35),BLUE);s.box('FrontPocket',(0,.35,-.22),(.5,.35,.16),'7298aa');s.ring('CarryLoop',(0,.99,0),.1,.025,DARK)
    for x in [-.22,.22]:s.ring('ShoulderStrap',(x,.5,.18),.25,.025,DARK,rot=(90,90,0),scale=(.5,1,1.4))
    s.box('Zip',(0,.55,-.31),(.44,.02,.025),METAL)
def compass(s):
    s.cyl('Case',(0,.07,0),.32,.14,METAL);s.cyl('Face',(0,.15,0),.29,.02,W)
    for a,c in [(0,'b24c42'),(180,DARK)]:s.mesh('Needle',(0,.18,0),(.14,.025,.42),c,'PrismMesh','size = Vector3(0.14, 0.42, 0.025)',rot=(90,0,a))
    for x,z in [(0,.24),(0,-.24),(.24,0),(-.24,0)]:s.box('Tick',(x,.17,z),(.025,.015,.025),DARK)
def worldmap(s):
    s.box('Frame',(0,.85,0),(1.6,1.3,.1),WOOD);s.box('Ocean',(0,.85,-.06),(1.45,1.15,.025),'6f9eb3')
    for p,sz in [((-.42,1.05,-.08),(.42,.28,.025)),((-.26,.62,-.08),(.22,.4,.025)),((.3,1.05,-.08),(.55,.22,.025)),((.13,.78,-.08),(.28,.4,.025)),((.52,.48,-.08),(.23,.14,.025))]:s.ball('Continent',p,sz,'7d9f62')
    s.box('Stand',(0,.18,.1),(.1,.35,.2),WOOD)
def telescope(s):
    for x,z in [(-.4,-.25),(.4,-.25),(0,.45)]:s.rod('Tripod',(x,0,z),(0,1.05,0),.025,METAL)
    s.cyl('OpticalTube',(0,1.2,0),.13,1,BLUE,(60,0,0));s.cyl('Lens',(0,1.46,.46),.12,.03,GLASS,(60,0,0));s.cyl('Eyepiece',(0,.91,-.48),.05,.16,DARK,(60,0,0))
def beaker(s):
    s.cyl('Glass',(0,.28,0),.25,.54,'bacfd2');s.cyl('Liquid',(0,.17,0),.255,.26,'519b9e');s.ring('Rim',(0,.56,0),.25,.018,W,rot=(0,0,0))
    for y in [.2,.3,.4]:s.box('Graduation',(.12,y,-.23),(.08,.015,.02),DARK)
def testtube(s):
    s.box('RackBase',(0,.05,0),(.75,.1,.3),WOOD);s.box('RackTop',(0,.4,0),(.75,.07,.3),WOOD)
    for x in [-.25,0,.25]:s.cyl('Tube',(x,.38,0),.065,.6,'b3ccd0');s.ball('RoundedBottom',(x,.1,0),(.13,.13,.13),'659d9c');s.cyl('Liquid',(x,.2,0),.067,.22,'659d9c');s.ring('Lip',(x,.69,0),.065,.012,W,rot=(0,0,0))
def magnet(s):
    for x,c in [(-.22,'b24d45'),(.22,BLUE)]:s.box('Arm',(x,.4,0),(.16,.6,.15),c);s.box('Pole',(x,.73,0),(.16,.12,.15),METAL)
    s.box('Bend',(0,.1,0),(.6,.18,.15),'b24d45')
def magnifier(s):s.ring('LensFrame',(0,.61,0),.25,.035,METAL);s.cyl('Lens',(0,.61,0),.21,.02,'acc8cf',(90,0,0));s.box('Handle',(0,.2,0),(.08,.4,.08),DARK)
def atom(s):
    s.ball('Nucleus',(0,.55,0),(.25,.25,.25),'b74c41')
    for rot in [(90,0,0),(45,0,45),(45,0,-45)]:s.ring('Orbit',(0,.55,0),.45,.014,METAL,rot)
    for p in [(.45,.55,0),(-.25,.8,.25),(0,.2,-.25)]:s.ball('Electron',p,(.1,.1,.1),BLUE)

school_assets=[('easel','el caballete',easel,(1.2,2,.9)),('palette','la paleta',palette,(.95,.17,.75)),('paintbrush','el pincel',brush,(.2,.95,.2)),('scissors','las tijeras',scissors,(.6,.8,.15)),('ruler','la regla',ruler,(1.05,.12,.25)),('paint tube','el tubo de pintura',painttube,(.3,.7,.2)),('piano','el piano',piano,(1.95,1.6,1.2)),('guitar','la guitarra',guitar,(.75,1.7,.25)),('violin','el violín',lambda s:guitar(s,True),(1,1.7,.25)),('trumpet','la trompeta',trumpet,(1.15,.85,.5)),('drum','el tambor',drum,(1,.9,1)),('microphone','el micrófono',microphone,(.7,1.9,.7)),('book','el libro',book,(.7,.3,.9)),('backpack','la mochila',backpack,(.85,1.15,.6)),('compass','la brújula',compass,(.75,.25,.75)),('world map','el mapamundi',worldmap,(1.7,1.55,.3)),('telescope','el telescopio',telescope,(.9,1.7,1.3)),('beaker','el vaso de precipitados',beaker,(.6,.65,.6)),('test tube','el tubo de ensayo',testtube,(.85,.8,.4)),('magnet','el imán',magnet,(.7,.9,.25)),('magnifying glass','la lupa',magnifier,(.65,.95,.2)),('atom model','el modelo atómico',atom,(1.1,1.1,1.1))]
for k,es,fn,size in school_assets:asset(k,es,'School',fn,size)

def firstaid(s):
    s.box('Case',(0,.4,0),(.8,.6,.3),W);s.ring('Handle',(0,.79,0),.15,.025,DARK);s.box('Cross',(0,.4,-.17),(.12,.4,.025),'b24b42');s.box('Cross',(0,.4,-.17),(.4,.12,.025),'b24b42')
def syringe(s):
    s.cyl('Barrel',(0,.42,0),.065,.42,'b9ccd0');s.cyl('Needle',(0,.09,0),.008,.23,METAL);s.cyl('Plunger',(0,.74,0),.025,.25,BLUE);s.cyl('ThumbPad',(0,.88,0),.09,.03,BLUE);s.box('FingerFlange',(0,.65,0),(.27,.04,.08),W)
    for y in [.32,.4,.48]:s.box('Graduation',(.02,y,-.066),(.065,.009,.012),DARK)
def oxygen(s):
    s.cyl('Tank',(0,.69,0),.24,1.2,'77a191');s.ball('Shoulder',(0,1.29,0),(.48,.3,.48),'77a191');s.cyl('Valve',(0,1.51,0),.055,.22,METAL);s.box('Tap',(0,1.63,0),(.25,.04,.06),DARK);s.cyl('Gauge',(.16,1.53,-.06),.11,.05,W,(90,0,0));s.box('GaugeNeedle',(.16,1.54,-.1),(.01,.13,.01),DARK,rot=(0,0,30));s.ring('Tubing',(.25,1.05,0),.33,.018,DARK,scale=(.6,1,1.5))
def medicalmonitor(s,defib=False):
    s.box('Case',(0,.4,0),(.85,.7,.25),W);s.box('Screen',(-.1,.45,-.14),(.55,.42,.025),DARK)
    points=[(-.34,.43),(-.22,.43),(-.17,.51),(-.12,.28),(-.06,.6),(0,.43),(.12,.43)]
    for i in range(len(points)-1):s.rod('ECG',(points[i][0],points[i][1],-.16),(points[i+1][0],points[i+1][1],-.16),.009,'6fbb79')
    for y in [.27,.43,.59]:s.cyl('Control',(.32,y,-.15),.04,.03,BLUE,(90,0,0))
    if defib:
        s.ring('CarryHandle',(0,.88,0),.18,.035,BLUE)
        for x in [-.48,.48]:s.box('Paddle',(x,.35,0),(.15,.3,.12),DARK);s.ring('Cable',(x,.14,.04),.14,.015,DARK)
    else:s.box('Stem',(0,.12,.05),(.08,.22,.08),METAL);s.box('Foot',(0,.04,0),(.55,.07,.4),METAL)
def mask(s):
    s.box('Fabric',(0,.24,0),(.55,.36,.08),'8cbdb6')
    for y in [.15,.24,.33]:s.box('Pleat',(0,y,-.055),(.5,.012,.02),'b9d6ce')
    for x in [-.35,.35]:s.ring('EarLoop',(x,.24,0),.14,.012,W,scale=(.7,1,1))
def pressure(s):
    s.box('Base',(0,.17,0),(.45,.34,.4),W);s.box('LCD',(0,.27,-.21),(.3,.16,.02),'a2b9a9');s.cyl('Start',(0,.11,-.22),.045,.025,BLUE,(90,0,0));s.ring('Cuff',(.45,.25,0),.18,.07,BLUE);s.rod('Hose',(.15,.08,0),(.43,.08,0),.015,DARK)
def hammer(s):s.cyl('Handle',(0,.35,0),.025,.65,METAL);s.mesh('RubberHead',(0,.75,0),(.3,.18,.1),'ad6655','PrismMesh','size = Vector3(0.3, 0.18, 0.1)')
def clipboard(s):
    s.box('Board',(0,.43,0),(.55,.8,.06),WOOD);s.box('Paper',(0,.43,-.04),(.47,.7,.015),W);s.box('Clip',(0,.83,-.06),(.22,.12,.05),METAL)
    for y in [.22,.34,.46,.58]:s.box('Writing',(0,y,-.053),(.34,.012,.008),'7d8f96')
def stretcher(s):
    s.box('Frame',(0,.66,0),(.8,.08,2.1),METAL);s.box('Mattress',(0,.77,0),(.76,.17,2),BLUE)
    for x in [-.34,.34]:
        s.rod('Rail',(x,.95,-.7),(x,.95,.7),.025,METAL)
        for z in [-.7,.7]:s.rod('Leg',(x,.12,z),(x,.64,-z),.025,METAL);s.ball('Caster',(x,.09,z),(.16,.17,.16),DARK)
    s.box('Pillow',(0,.9,.65),(.6,.13,.4),W)
def xray(s):
    s.box('Base',(0,.07,0),(1.3,.14,1.1),W);s.box('Column',(.4,1.2,.2),(.2,2.3,.2),METAL);s.box('Arm',(0,2.25,.2),(1,.14,.2),METAL);s.box('TubeHead',(-.4,2.05,.2),(.45,.35,.45),W);s.cyl('Collimator',(-.4,1.82,.2),.09,.15,DARK);s.box('Detector',(0,1.15,-.3),(.9,1.2,.14),DARK)
    s.box('Spine',(0,1.15,-.38),(.07,.85,.02),'bac7c8')
    for y in [.9,1.03,1.16,1.29,1.42]:s.box('Rib',(0,y,-.39),(.5,.035,.02),'bac7c8')
def mri(s):
    s.ring('ScannerBore',(0,1.5,.5),1.03,.32,W);s.ring('InnerBore',(0,1.5,.37),.74,.055,'8ba5b0');s.box('Pedestal',(0,.24,.5),(2.25,.48,1.1),W);s.box('SlidingTable',(0,.68,-.7),(.7,.14,2.8),BLUE);s.box('TableSupport',(0,.3,-.9),(.45,.6,1.9),W)
    for x in [-1.08,1.08]:s.box('ControlStrip',(x,1.4,.12),(.14,.45,.045),BLUE)
def walker(s):
    for x in [-.4,.4]:
        for z in [-.3,.3]:s.rod('Leg',(x,0,z),(x,.95,z),.025,METAL);s.cyl('RubberFoot',(x,.04,z),.04,.08,DARK)
        s.rod('HandGrip',(x,.95,-.3),(x,.95,.3),.035,DARK)
    for y in [.4,.85]:s.rod('Crossbar',(-.4,y,.3),(.4,y,.3),.025,METAL)
def prosthesis(s):
    s.cyl('Socket',(0,1,0),.13,.35,'d1b08e',top=.17);s.ball('Knee',(0,.76,0),(.17,.17,.17),METAL);s.rod('Shin',(0,.7,0),(0,.2,0),.05,METAL);s.ball('Foot',(0,.1,-.12),(.27,.19,.48),DARK)
for k,es,fn,size in [('first aid kit','el botiquín de primeros auxilios',firstaid,(.9,1,.4)),('syringe','la jeringa',syringe,(.3,.95,.2)),('oxygen tank','la bombona de oxígeno',oxygen,(.95,1.7,.6)),('medical monitor','el monitor médico',medicalmonitor,(.95,.82,.5)),('defibrillator','el desfibrilador',lambda s:medicalmonitor(s,True),(1.2,1.12,.5)),('surgical mask','la mascarilla quirúrgica',mask,(1,.5,.2)),('blood pressure monitor','el tensiómetro',pressure,(.95,.55,.5)),('reflex hammer','el martillo de reflejos',hammer,(.35,.9,.2)),('clipboard','el portapapeles',clipboard,(.65,.95,.2)),('stretcher','la camilla',stretcher,(.95,1.1,2.2)),('x ray machine','la máquina de rayos X',xray,(1.4,2.5,1.2)),('MRI scanner','el equipo de resonancia magnética',mri,(2.9,2.95,3.2)),('walker','el andador',walker,(.95,1.05,.75)),('prosthetic leg','la prótesis de pierna',prosthesis,(.45,1.25,.65))]:
    asset(k,es,'Hospital',fn,size)

def part(s,name,p,size,c='e9e4d9'):
    s.box(name,p,size,c);s.hit(p,size,True,name+'Body')
def wing(kind,width,themes):
    # Parent's rear wall is at local Z=12.2; the new wing starts there.
    s=Scene(kind+'LearningWing');s.nodes.append('metadata/expanded_wing = true')
    part(s,'Floor',(0,.035,12),(width,.09,24),'e0d8c7')
    part(s,'Rear',(0,2.6,24),(width,5.2,.18))
    for x in [-width/2,width/2]:part(s,'OuterWall'+str(int(x)).replace('-','L'),(x,2.6,12),(.18,5.2,24))
    s.box('Roof',(0,5.3,12),(width+.15,.15,24.1),'9facac' if kind=='Hospital' else 'b49982')
    # Inner corridor walls have two 2.6m-wide openings on each side.
    for side in [-1,1]:
        for j,(z,length) in enumerate([(2,4),(12,10),(22,4)]):part(s,f'CorridorWall{side}_{j}',(side*1.8,2.6,z),(.14,5.2,length))
        for j,z in enumerate([5.5,18.5]):part(s,f'DoorHeader{side}_{j}',(side*1.8,4.5,z),(.14,1.4,3))
        # Room divider around a cross corridor spanning Z=11..13.
        cx=side*(width/4+.9);rw=width/2-1.8
        for z in [11,13]:part(s,f'CrossHall{side}_{z}',(cx,2.6,z),(rw,5.2,.14))
    for z in [3,9,15,21]:
        s.nodes += [f'\n[node name="HallLight{z}" type="OmniLight3D" parent="."]','position = '+vec((0,4.2,z)),'omni_range = 9.0','light_energy = 0.75','shadow_enabled = false']
    s.label('NEW CLASSROOMS' if kind=='School' else 'CLINICAL LEARNING WING',(0,3.8,.4),.006)
    roomwidth=width/2-1.8
    for i,(name,title,keys) in enumerate(themes):
        side=-1 if i%2==0 else 1;row=i//2;zcenter=5.5 if row==0 else 18.5
        room=Scene(name);room.nodes.append(f'metadata/theme = "{title}"')
        # Six well separated display bays along front/rear walls. The center
        # cross-aisle connects the open door to every display.
        spacing=min(2.6,(roomwidth-2)/2)
        for j,key in enumerate(keys):
            x=(j%3-1)*spacing;z=-3.55 if j<3 else 3.55
            size=CATALOG.get(key,{}).get('size',[1,1.6,1])
            y=.09
            if key=='MRI scanner':z=2.9
            if title=='IMAGING' and key in ['clipboard','headphones']:z=1.15
            if size[1]<1.35 and key not in ['walker','stretcher','wheelchair','crutches','hospital bed']:
                room.box('DisplayTop'+slug(key),(x,.94,z),(1.25,.08,1.25),'c4af91')
                room.hit((x,.94,z),(1.25,.08,1.25),True,'TableBody'+slug(key))
                for dx in [-.44,.44]:room.box('DisplayLeg',(x+dx,.46,z),(.08,.92,.9),WOOD)
                y=.99
            if key=='hospital bed':
                path='res://scenes/props/furniture/hospital_bed.tscn';room.ext[path]='bed'
                room.nodes += [f'\n[node name="HospitalBed" parent="." instance=ExtResource("bed")]','position = '+vec((x,y,z)),'scale = Vector3(0.85,0.85,0.85)']
            else:room.instance(key,(x,y,z),180 if j<3 else 0)
        room.label(title,(0,3.1,-4.9),.007)
        room.nodes += ['\n[node name="RoomLight" type="OmniLight3D" parent="."]','position = Vector3(0,4,0)','omni_range = 9.0','light_energy = 0.9','shadow_enabled = false']
        roompath=ROOT/f'scenes/buildings/rooms/{kind.lower()}_{slug(name).lower()}.tscn';roompath.parent.mkdir(exist_ok=True);room.save(roompath)
        resource='res://scenes/buildings/rooms/'+roompath.name;s.ext[resource]=f'room{i}'
        s.nodes += [f'\n[node name="{name}" parent="." instance=ExtResource("room{i}")]','position = '+vec((side*(width/4+.9),0,zcenter))]
        # Corridor-side plaque faces into the corridor, without labelling props.
        s.label(title,(side*1.65,3.1,zcenter),.0045);s.nodes.append('billboard = 1')
    s.save(ROOT/f'scenes/buildings/{kind.lower()}_learning_wing.tscn')
    # Replace only the previous rear wall with a proper full-width doorway.
    conn=Scene(kind+'RearConnection');panelwidth=(width-3.6)/2
    for side in [-1,1]:part(conn,'Pier'+str(side).replace('-','L'),(side*(1.8+panelwidth/2),2.6,0),(panelwidth,5.2,.18))
    part(conn,'Lintel',(0,4.5,0),(3.6,1.4,.18));conn.save(ROOT/f'scenes/buildings/{kind.lower()}_rear_connection.tscn')
    target=ROOT/f'scenes/buildings/{kind.lower()}.tscn';text=target.read_text()
    # Parse node blocks so none of the old rear-wall collision survives.
    chunks=re.split(r'(?=\[node )',text);header=chunks.pop(0);result=[];skip=False
    for chunk in chunks:
        m=re.match(r'\[node name="([^"]+)"[^\n]*parent="([^"]+)"',chunk)
        if m and m[2]=='.':
            skip=m[1]=='RearWall'
            if skip:result.append('[node name="RearWall" parent="." instance=ExtResource("wing_connection")]\nposition = Vector3(0, 0, 12.2)\n\n');continue
        elif m and (m[2]=='RearWall' or m[2].startswith('RearWall/')):continue
        result.append(chunk)
    if 'id="wing_extension"' not in header:
        idx=header.index('[sub_resource')
        header=header[:idx]+f'[ext_resource type="PackedScene" path="res://scenes/buildings/{kind.lower()}_learning_wing.tscn" id="wing_extension"]\n[ext_resource type="PackedScene" path="res://scenes/buildings/{kind.lower()}_rear_connection.tscn" id="wing_connection"]\n\n'+header[idx:]
        result.append('[node name="LearningWing" parent="." instance=ExtResource("wing_extension")]\nposition = Vector3(0,0,12.2)\n')
    target.write_text(header+''.join(result))

school=[('ScienceLab','SCIENCE LAB',['microscope','beaker','test tube','magnet','magnifying glass','atom model']),('ArtStudio','ART STUDIO',['easel','palette','paintbrush','scissors','ruler','paint tube']),('MusicRoom','MUSIC ROOM',['piano','guitar','violin','trumpet','drum','microphone']),('GeographyRoom','GEOGRAPHY & READING',['globe','world map','compass','book','backpack','telescope'])]
hospital=[('EmergencyRoom','EMERGENCY',['stretcher','defibrillator','first aid kit','oxygen tank','syringe','surgical mask']),('ExaminationRoom','EXAMINATION',['hospital bed','stethoscope','thermometer','blood pressure monitor','reflex hammer','medicine']),('ImagingRoom','IMAGING',['x ray machine','medical monitor','computer','clipboard','MRI scanner','headphones']),('RehabilitationRoom','REHABILITATION',['wheelchair','crutches','walker','prosthetic leg','bandage','medicine'])]
wing('School',20,school);wing('Hospital',18,hospital)
data=word_data.load()
for key,record in NEW.items():data['words'][key]={'spanish':record['spanish'],'category':record['category'],'prefab_size':record['size']}
word_data.save(data)
print('Authored',len(NEW),'vocabulary assets and eight themed rooms, 48 learning displays')
