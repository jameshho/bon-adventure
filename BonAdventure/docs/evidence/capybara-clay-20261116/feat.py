import sys
from trace import trace, regions
EV="/Users/james/Documents/Codex/Bon Adventure/BonAdventure/docs/evidence/capybara-clay-20261116/"
RECTS=[("f34",20,360),("front",381,290),("side",695,450),("back",1192,290),("r34",1521,450)]
kw=dict(layer_difference=14, color_precision=6, filter_speckle=6)
trace(EV+"reference.png","ref_f.svg",**kw); trace(EV+"turnaround.png","model_f.svg",**kw)
def show(tag, rs, conv, lo, hi, minarea):
    rows=[]
    for r in rs:
        b=conv(r['bbox'])
        if b is None: continue
        if r['area']*conv.scale<minarea: continue
        if lo<=b[0] and b[2]<=hi and 200<b[1]<530:
            w=b[2]-b[0]; h=b[3]-b[1]
            if w>200 or h>200: continue
            rows.append((b[1],"%s %s x %4.0f-%4.0f y %3.0f-%3.0f (w%3.0f h%3.0f) area %5.0f"%(tag,r['fill'],b[0],b[2],b[1],b[3],w,h,r['area']*conv.scale)))
    for _,t in sorted(rows): print(t)
want=sys.argv[1:]
refs=regions("ref_f.svg"); mods=regions("model_f.svg")
off=0
for name,rx,rw in RECTS:
    if name in want:
        print("=====",name)
        c=lambda b:b
        c.scale=1.0
        show("ref  ",refs,c,rx,rx+rw,60)
        def mc(b,off=off,rx=rx): return ((b[0]-off)/2+rx, b[1]/2+195, (b[2]-off)/2+rx, b[3]/2+195)
        mc.scale=0.25
        show("model",mods,mc,rx,rx+rw,60)
    off+=rw*2
