"""Hospital: delegates to build_hospital_remodel.py. --school: three storeys plus the school's rear learning wing."""
from pathlib import Path
import math, sys
SCHOOL = "--school" in sys.argv
if not SCHOOL:
    import build_hospital_remodel
    build_hospital_remodel.build()
    sys.exit(0)
ROOT = Path(__file__).resolve().parents[1]
from scene_writer import Scene, v
s=Scene();s.node('School' if SCHOOL else 'Hospital',parent=None,props='metadata/multistorey = true\nmetadata/floors = 3')
s.node('InteriorDetails')
H=5.6
colors=['b58c58','659b91','b5829d'] if SCHOOL else ['478e91','668eb9','a17b9b']
# Ground-floor rear wing remains connected at the original location.
s.node('LearningWing',props='position = Vector3(0,0,12.2)',instance=s.external('res://scenes/buildings/'+('school' if SCHOOL else 'hospital')+'_learning_wing.tscn'))
for level in range(3):
    y=level*H; accent=colors[level]; f=s.node('Floor'+str(level+1),props='position = '+v((0,y,0)))
    s.box('Slab',(0,-.1,0),(18,.2,24.4),'e7e9e3',f,True)
    s.box('HallRunner',(0,.012,0),(2.8,.018,24),'a7c9c4',f)
    s.box('StairLink',(8,.015,0),(16,.02,2.8),accent,f)
    # Window bands: solid sills, window glazing and upper lintels.
    for side in [-1,1]:
        for z in [-7,7]:
            s.box(f'Sill{side}_{z}',(side*9,.7,z),(.18,1.4,10),'d6e2df',f,True)
            s.box(f'Glass{side}_{z}',(side*9,2.65,z),(.08,2.5,10),'aac9d0',f,True,glass=True)
            s.box(f'Lintel{side}_{z}',(side*9,4.65,z),(.18,1.5,10),'edf0e8',f,True)
        if side==-1:s.box('WestCenter',(-9,2.7,0),(.18,5.4,4),'edf0e8',f,True)
    # Front facade has a ground-floor entry and wide upstairs window.
    for x in [-5.4,5.4]:
        s.box('FrontSill'+str(x),(x,.65,-12.2),(7.2,1.3,.18),'edf0e8',f,True)
        s.box('FrontLintel'+str(x),(x,4.65,-12.2),(7.2,1.5,.18),'edf0e8',f,True)
        s.box('FrontWindow'+str(x),(x,2.6,-12.2),(4.8,2.6,.08),'aac9d0',f,True,glass=True)
        for edge in [-3,3]:s.box('FrontPier'+str(x)+str(edge),(x+edge,2.6,-12.2),(1.2,2.6,.18),'edf0e8',f,True)
    s.box('FrontHeader',(0,4.6,-12.2),(3.6,1.6,.18),accent,f,True)
    if level:
        s.box('FrontSill',(0,.65,-12.2),(3.6,1.3,.18),'edf0e8',f,True)
        s.box('FrontGlass',(0,2.55,-12.2),(3.6,2.5,.08),'aac9d0',f,True,glass=True)
    # Ground rear opening leads to the existing learning wing.
    for x in [-5.4,5.4]:s.box('Rear'+str(x),(x,2.7,12.2),(7.2,5.4,.18),'edf0e8',f,True)
    if level:s.box('RearCenter',(0,2.7,12.2),(3.6,5.4,.18),'edf0e8',f,True)
    else:s.box('RearHeader',(0,4.5,12.2),(3.6,1.8,.18),'edf0e8',f,True)
    # Four rooms, each with a wide door onto the central corridor; cross-hall at z=0.
    for side in [-1,1]:
        for front in [-1,1]:
            x=side*1.8; z=front*7
            for offset,length in [(-3.6,2.8),(3.6,2.8)]:
                s.box(f'Partition{side}_{front}_{offset}',(x,2.7,z+offset),(.15,5.4,length),'e2e9e4',f,True)
            s.box(f'DoorHeader{side}_{front}',(x,4.4,z),(.15,2,4.4),accent,f,True)
            s.box(f'RoomCrossWall{side}_{front}',(side*5.4,2.7,front*2),(7.2,5.4,.14),'e2e9e4',f,True)
            s.box(f'RoomBorder{side}_{front}',(side*5.4,.025,z),(6.8,.025,9.5),'d2dedb',f)
    # Continuous trim and bump rails make the rooms feel like a finished hospital.
    for side in [-1,1]:
        for z in [-10.6,-3.4,3.4,10.6]:
            s.box('HallBumper',(side*1.7,.95,z),(.06,.13,2.6),accent,f)
        for z in [-7,7]:
            s.box('WindowTrim',(side*8.88,1.42,z),(.08,.08,10),'fbf5e8',f)
            s.box('WallBase',(side*8.87,.15,z),(.06,.28,10),accent,f)
            for offset in [-3.3,0,3.3]:
                s.box('WindowMullion',(side*8.9,2.7,z+offset),(.12,2.6,.08),'e8ede6',f)
    # Lighting and hallway wayfinding are readable from both directions.
    for x in [-5.3,0,5.3]:
        for z in [-7,7]:
            s.box(f'LightPanel{x}_{z}',(x,5.25,z),(2.5,.07,1),'fff4d9',f)
            s.node(f'Light{x}_{z}','OmniLight3D',f,'position = '+v((x,3.9,z))+'\nlight_color = Color(0.94,1,0.97,1)\nlight_energy = 0.7\nomni_range = 8')
    departments=[['RECEPCIÓN','URGENCIAS','CONSULTAS','ENFERMERÍA'],['PEDIATRÍA','CARDIOLOGÍA','CONSULTAS INFANTILES','DIAGNÓSTICO'],['HABITACIONES','REHABILITACIÓN','DESCANSO','FISIOTERAPIA']][level]
    if SCHOOL: departments=[['AULAS','RECEPCIÓN','LECTURA','MATEMÁTICAS'],['CIENCIAS','GEOGRAFÍA','LABORATORIO','TECNOLOGÍA'],['ARTE','MÚSICA','TALLER CREATIVO','ENSAYO']][level]
    for idx,(x,z) in enumerate([(-5.4,-2.13),(5.4,-2.13),(-5.4,12.08),(5.4,12.08)]):
        s.sign('Department'+str(idx),departments[idx],(x,3.7,z),5.7,f,accent,size=32)
    for idx,z in enumerate([-8,5]):
        left,right=departments[idx*2:idx*2+2]
        # Facing into the building (+Z), the west rooms appear on the right.
        s.sign('DepartmentArrows'+str(idx),'← '+right+'\n'+left+' →',(0,3.55,z),3.5,f,accent,size=28,height=1.15)
        s.box('SignHanger'+str(idx),(0,4.55,z),(.06,1.45,.06),'819d99',f)
    title='PLANTA BAJA · 1' if level==0 else 'PLANTA '+str(level+1)
    s.sign('FloorDirectory','← ESCALERAS  |  '+title,(0,3.9,-2),3.5,f,accent,size=22)
    s.sign('ReturnDirectory',title+'  |  ESCALERAS →',(0,3.9,2),3.5,f,accent,rot=0,size=22)
    s.sign('StairArrow','← ESCALERAS',(5.5,2.8,-1.88),5,f,accent,size=34)
    # Furnish rooms according to department, leaving central aisles and doors clear.
    for idx,(x,z) in enumerate([(-6,-7),(6,-7),(-6,7),(6,7)]):
        room=s.node('DepartmentRoom'+str(idx),parent=f,props='position = '+v((x,0,z)))
        if SCHOOL:
            if level==0:
                if idx==1:
                    s.box('OfficeDesk',(0,.65,1.7),(3,1.3,.9),'b59872',room,True)
                    s.prop('computer',(0,1.3,1.7),room,.65)
                    for dx in [-1,1]:s.prop('chair',(dx,0,-2),room,.85)
                else:
                    for dx in [-1.4,1.4]:
                        for dz in [-2,1.4]:
                            s.prop('desk',(dx,0,dz),room,.85)
                            s.prop('chair',(dx,0,dz-1),room,.75)
                            s.prop('notebook',(dx,.89,dz),room,.55)
                    s.box('ClassBoard',(0,2.5,4.78),(4,1.5,.06),'48796b',room)
                    s.text('Lesson','¡HOLA, CLASE!\nA B C   ·   1 2 3',(0,2.5,4.71),room,size=28)
            elif level==1:
                for dx in [-1.5,1.5]:
                    s.box('LabBench',(dx,.8,1),(1.6,1.6,3),'b7cabd',room,True)
                    s.prop('microscope' if idx%2==0 else 'globe',(dx,1.6,.3),room,.8)
                    s.prop('beaker' if idx%2==0 else 'compass',(dx,1.6,1.8),room,.65)
                s.prop('bookshelf',(0,0,4),room,.8)
            else:
                if idx%2==0:
                    for dx in [-1.5,1.5]:s.prop('easel',(dx,0,1),room)
                    s.box('ArtTable',(0,.7,-2),(3,.15,1),'c9b18c',room,True)
                    for dx in [-1.3,1.3]:s.box('ArtTableLeg',(dx,.35,-2),(.12,.7,.7),'a78b68',room)
                    s.prop('paint_tube',(-.7,.8,-2),room,.75)
                    s.prop('paintbrush',(.5,.8,-2),room,.75)
                else:
                    s.prop('piano',(0,0,2.5),room,.8)
                    s.prop('guitar',(-1.7,0,-1),room)
                    s.prop('drum',(1.5,0,-1),room,.8)
                    s.prop('chair',(0,0,.5),room,.8)
            s.plant((2.1,0,4),room)
        else:
            if level==0 and idx==0:
                s.box('ReceptionDesk',(0,.65,1.7),(3,1.3,.9),'72a6a4',room,True)
                s.prop('computer',(0,1.3,1.7),room,.65)
                s.box('DeskTop',(0,1.34,1.7),(3.2,.1,1.1),'e9dec7',room)
                s.box('ReceptionReturn',(-1.4,.65,2.6),(.4,1.3,1.7),'72a6a4',room,True)
                for i in range(4):s.prop('chair',(-1.8+i*1.2,0,-3.5),room,.85)
                s.box('WaitingRug',(0,.045,-3),(5.6,.02,2.4),'c9d7cd',room)
                s.plant((2.1,0,3.8),room)
                s.box('TicketDispenser',(2.1,1.1,-1),(.4,.5,.35),'486e76',room)
                s.box('TicketPost',(2.1,.5,-1),(.1,1,.1),'839992',room)
                s.text('ReceptionDeskLabel','RECEPCIÓN',(0,.8,1.23),room,size=30)
                s.sign('Welcome','BIENVENIDOS',(0,2.8,4.7),4,room,accent,size=34)
            elif (level==1 and idx==0):
                s.box('PlayMat',(0,.04,0),(3.3,.04,3.3),'cfb77c',room)
                for i,c in enumerate(['e1a085','81b5c3','b6c28b']):s.box('ToyBlock'+str(i),(-1+i,.4,1),(.65,.7,.65),c,room,True)
                s.prop('chair',(-1,0,-2.6),room)
                for dx,c in [(-.8,'8cb7bc'),(.8,'dda88e')]:
                    s.box('ChildStool',(dx,.28,1.8),(.55,.55,.55),c,room,True)
                s.text('AlphabetMural','A B C   ·   1 2 3',(0,2.8,4.75),room,size=46)
                for i,c in enumerate(['e0a58b','e5c87b','93b6a3','87aabe']):
                    s.box('MuralStripe',(-1.2+i*.8,1.75,4.79),(.65,.16,.025),c,room)
                s.plant((2.1,0,4),room)
                s.prop('book',(0,.8,2.8),room,.8)
                s.box('ReadingTable',(0,.65,2.8),(2,.3,1),'d1b690',room,True)
                for dx in [-.8,.8]:
                    for dz in [2.5,3.1]:s.box('TableLeg',(dx,.25,dz),(.12,.5,.12),'a78c69',room)
            elif level==2 and idx in [1,3]:
                s.prop('walker',(-1,0,1),room)
                s.prop('crutches',(1,0,2.5),room)
                s.prop('wheelchair',(-1,0,-2),room)
                for dx in [-1,1]:
                    s.box('TherapyRail'+str(dx),(dx,1.1,0),(.08,.1,3),'8b9f9b',room)
                    for dz in [-1.4,1.4]:s.box('TherapyPost',(dx,.55,dz),(.07,1.1,.07),'8b9f9b',room)
                s.box('TherapyMat',(0,.045,0),(2.5,.02,3.8),'c3b0c4',room)
                for dz in [-1,0,1]:
                    s.box('GaitMarker',(.22,.065,dz),(.25,.015,.4),'ede6d9',room)
                    s.box('GaitMarker',(-.22,.065,dz+.45),(.25,.015,.4),'ede6d9',room)
                s.plant((2.1,0,4),room)
            else:
                s.node('HospitalBed',parent=room,props='position = Vector3(0,0,1)',instance=s.external('res://scenes/props/furniture/hospital_bed.tscn'))
                s.prop('medical_monitor',(-1.9,1.0,2.7),room,.8)
                s.box('MonitorStand',(-1.9,.5,2.7),(.8,1,.7),'9dbbb8',room,True)
                s.prop('iv_stand',(1.6,0,2.5),room,.85)
                s.prop('chair',(-1.2,0,-2.5),room,.85)
                s.box('BedsideCabinet',(1.8,.55,.4),(.9,1.1,.7),'cbb695',room,True)
                for dy in [.35,.75]:
                    s.box('DrawerFront',(1.8,dy,.025),(.78,.3,.04),'e8ddc6',room)
                    s.box('DrawerHandle',(1.8,dy,-.01),(.28,.035,.05),'718884',room)
                s.box('Headwall',(0,1.65,4.8),(3.3,.45,.07),accent,room)
                for dx in [-.7,0,.7]:s.orb('MedicalOutlet',(dx,1.65,4.74),(.12,.12,.04),'f5f0e1',room)
                if level==2:s.plant((2.1,0,4),room)
            if (level==0 and idx==1) or (level==1 and idx==1):
                s.box('ExamCounter',(1.8,.85,-2.5),(1.2,1.7,1.5),'a9c7c4',room,True)
                s.prop('stethoscope',(1.8,1.7,-2.9),room,.65)
                s.prop('thermometer',(1.8,1.7,-2.2),room,.65)
        # Colorful wall art and a simple cabinet add detail away from walking paths.
        s.box('ArtFrame',(0,2.7,4.85),(2.2,1.1,.06),'ba9d74',room)
        s.box('Art',(0,2.7,4.8),(2,.9,.025),accent,room)
        if not SCHOOL and level==1 and idx==1:
            # ECG trace gives cardiology a recognizable identity.
            points=[(-.85,2.6),(-.5,2.6),(-.35,2.8),(-.15,2.35),(0,3.03),(.2,2.6),(.85,2.6)]
            for (ax,ay),(bx,by) in zip(points,points[1:]):
                s.box('ECG',((ax+bx)/2,(ay+by)/2,4.76),(math.hypot(bx-ax,by-ay),.035,.025),'f4f2df',room,rotation=(0,0,math.atan2(by-ay,bx-ax)))
        elif not (level==1 and idx==0):
            s.orb('ArtSun',(.55,2.9,4.76),(.3,.3,.025),'f1d9a2',room)
            s.box('ArtHorizon',(0,2.45,4.76),(1.9,.25,.025),'aac6b1',room)
    # Stair entrance landing; no slab crosses the flights above.
    if level==0:s.box('StairGroundFloor',(12.5,-.1,7),(7,.2,10),'dfe5dc',f,True)
    s.box('StairEntranceLanding',(12.5,-.1,-.5),(7,.2,3),'dfe5dc',f,True)
    s.box('StairOuterWall',(16,2.7,5),(.18,5.4,14),'dce6df',f,True)
    s.box('StairFrontWall',(12.5,2.7,-2),(7,5.4,.18),'dce6df',f,True)
    s.box('StairBackWall',(12.5,2.7,12),(7,5.4,.18),'dce6df',f,True)
    s.node('StairLight','OmniLight3D',f,'position = '+v((12.5,4.5,4))+'\nlight_color = Color(1,0.98,0.9,1)\nlight_energy = 1.0\nomni_range = 11')
    s.sign('StairFloor',title,(12.5,2.8,-1.88),6,f,accent,rot=0,size=36)
    stair_destinations = ['2 ↑ PEDIATRÍA · CARDIOLOGÍA\n3 ↑ HABITACIONES · REHABILITACIÓN','1 ↓ RECEPCIÓN · URGENCIAS\n3 ↑ HABITACIONES · REHABILITACIÓN','1 ↓ RECEPCIÓN · URGENCIAS\n2 ↓ PEDIATRÍA · CARDIOLOGÍA'][level]
    if SCHOOL: stair_destinations = ['2 ↑ CIENCIAS · GEOGRAFÍA\n3 ↑ ARTE · MÚSICA','1 ↓ AULAS · RECEPCIÓN\n3 ↑ ARTE · MÚSICA','1 ↓ AULAS · RECEPCIÓN\n2 ↓ CIENCIAS · GEOGRAFÍA'][level]
    s.text('StairDestinations',stair_destinations,(12.5,1.9,-1.87),f,0,24)
    if level<2:
        # Visible treads sit below a continuous collision ramp, so no jumping is needed.
        for flight,(x,reverse) in enumerate([(10.7,False),(14.2,True)]):
            rise=H/2;run=8.4;base=0 if not reverse else rise
            angle=math.atan2(rise,run)*(1 if reverse else -1)
            s.box('WalkRamp'+str(flight),(x,base+rise/2-.07,5.2),(2.8,.14,math.hypot(run,rise)),'c2ccc7',f,True,(angle,0,0),visible=False)
            for step in range(24):
                z=1+(step+.5)*run/24 if not reverse else 9.4-(step+.5)*run/24
                top=base+step*rise/24
                s.box(f'Tread{flight}_{step}',(x,top-.055,z),(2.8,.11,run/24),'d4ded8',f)
                s.box(f'Nosing{flight}_{step}',(x,top+.003,z-.14 if not reverse else z+.14),(2.8,.015,.035),accent,f)
            for side in [-1,1]:
                # Solid sloping guards follow the flights, with contrasting handrails.
                s.box(f'Guard{flight}_{side}',(x+side*1.43,base+rise/2+.52,5.2),(.08,1.04,math.hypot(run,rise)),'9cb5af',f,True,(angle,0,0))
                s.box(f'Handrail{flight}_{side}',(x+side*1.43,base+rise/2+1.1,5.2),(.12,.1,math.hypot(run,rise)),'4b7274',f,False,(angle,0,0))
        s.box('HalfLanding',(12.5,H/2-.1,10.7),(7,.2,2.6),'dfe5dc',f,True)
        s.sign('HalfLandingSign','↑ PLANTA '+str(level+2)+'  ·  GIRA Y SIGUE',(12.5,H/2+2,11.88),6.6,f,accent,size=23)
    if level > 0:
        s.box('LandingGapGuard',(12.45,.55,1),(.7,1.1,.1),'9cb5af',f,True)
    if level==2:
        # Close the stairwell beyond the top landing while keeping the arrival open.
        s.box('TopLandingGuard',(10.7,.55,1),(3,.95,.1),'9cb5af',f,True)
# Roof and strong exterior floor bands.
if not SCHOOL:s.box('MedicalCrossVertical',(0,14.2,-12.4),(.35,1.6,.14),'478e91')
if not SCHOOL:s.box('MedicalCrossHorizontal',(0,14.2,-12.41),(1.4,.35,.14),'478e91')
s.box('MainRoof',(0,16.8,0),(18.4,.25,24.8),'87a7a5',solid=True)
s.box('StairRoof',(12.5,16.8,5),(7.2,.25,14.2),'87a7a5',solid=True)
for y in [5.5,11.1,16.7]:s.box('FacadeBand'+str(y),(0,y,-12.35),(18.4,.26,.22),'478e91')
s.box('EntranceCanopy',(0,3.9,-13),(5,.18,2.3),'6f9694')
s.box('DirectoryBoard',(-2.7,2.15,-12.4),(2.1,2.9,.12),'386f78')
s.text('DirectoryHeading','DIRECTORIO',(-2.7,3.22,-12.48),size=24)
s.text('DirectoryText',('3  ARTE · MÚSICA\n\n2  CIENCIAS\n    GEOGRAFÍA\n\n1  AULAS\n    RECEPCIÓN' if SCHOOL else '3  HABITACIONES\n    REHABILITACIÓN\n\n2  PEDIATRÍA\n    CARDIOLOGÍA\n\n1  RECEPCIÓN\n    URGENCIAS'),(-2.7,2.05,-12.48),size=19)
s.sign('BuildingSign','ESCUELA' if SCHOOL else 'HOSPITAL  +',(0,4.55,-12.38),8,color='386f78',size=52)
s.sign('GroundRear','↑ AULAS DE APRENDIZAJE' if SCHOOL else '↑ IMAGEN · EXÁMENES\nURGENCIAS · REHABILITACIÓN',(0,3.7,11.8),3.5,size=20,height=1.1)
s.save(ROOT/'scenes/buildings'/('school.tscn' if SCHOOL else 'hospital.tscn'))
print('Built editable three-floor '+('school' if SCHOOL else 'hospital')+' with switchback stairs')
