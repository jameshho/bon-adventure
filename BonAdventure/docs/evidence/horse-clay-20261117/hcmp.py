import sys
from trace import trace
from prof import polys, spans
EV="/Users/james/Documents/Codex/Bon Adventure/BonAdventure/docs/evidence/horse-clay-20261117/"
RECTS=[("f34",60,320),("front",433,180),("side",700,460),("back",1250,180),("r34",1520,390)]
if "notrace" not in sys.argv: trace(EV+"turnaround.png","model.svg",hierarchical="stacked",color_precision=6,layer_difference=12)
ref=polys("ref.svg")
allm=polys("model.svg")
want=sys.argv[1:]
off=0
def fmt(s): return ' '.join('%.0f-%.0f'%ab for ab in s)
for name,rx,rw in RECTS:
    if name in want:
        mod=[]
        for subs in allm:
            keep=[]
            for pts in subs:
                cx=sum(p[0] for p in pts)/len(pts)
                if off<=cx<off+rw*2: keep.append([((x-off)/2+rx,y/2+115) for x,y in pts])
            if keep: mod.append(keep)
        print('==',name,'rows  y: ref | model')
        for y in range(128,582,12):
            a=spans(ref,y,'y',rx,rx+rw,0,0); b=spans(mod,y,'y',rx,rx+rw,0,0)
            if a or b:
                d=''
                if a and b: d=' | d %+.0f %+.0f'%(b[0][0]-a[0][0], b[-1][1]-a[-1][1])
                print('y%4d  %-34s | %-34s%s'%(y,fmt(a),fmt(b),d))
        if name=='side':
            print('--',name,'cols  x: ref | model')
            for x in range(rx+12,rx+rw,14):
                a=spans(ref,x,'x',110,585,0,0); b=spans(mod,x,'x',110,585,0,0)
                if a or b:
                    d=''
                    if a and b: d=' | d %+.0f %+.0f'%(b[0][0]-a[0][0], b[-1][1]-a[-1][1])
                    print('x%5d  %-30s | %-30s%s'%(x,fmt(a),fmt(b),d))
    off+=rw*2
