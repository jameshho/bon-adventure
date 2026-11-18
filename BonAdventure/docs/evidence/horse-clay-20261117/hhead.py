import sys, prof
prof.THRESH=34
from prof import polys, spans
from trace import trace
EV="/Users/james/Documents/Codex/Bon Adventure/BonAdventure/docs/evidence/horse-clay-20261117/"
trace(EV+"turnaround.png","model_fine.svg",hierarchical="stacked",color_precision=6,layer_difference=12)
ref=polys("ref_fine.svg",minarea=12)
allm=polys("model_fine.svg",minarea=12)
def view(off,rx,rw):
    out=[]
    for subs in allm:
        keep=[[((x-off)/2+rx,y/2+115) for x,y in pts] for pts in subs if off<=sum(p[0] for p in pts)/len(pts)<off+rw*2]
        if keep: out.append(keep)
    return out
def f(s): return ' '.join('%.0f-%.0f'%ab for ab in s)
side=view(1000,700,460); front=view(640,433,180)
print('SIDE rows  y: ref | model | dLeft')
for y in range(167,312,7):
    a=spans(ref,y,'y',700,900,0,0); b=spans(side,y,'y',700,900,0,0)
    print('y%4d %-22s | %-22s | %s'%(y,f(a),f(b),('%+.0f'%(b[0][0]-a[0][0])) if a and b else ''))
print('SIDE cols  x: ref | model | dTop dBottom')
for x in range(724,830,7):
    a=spans(ref,x,'x',160,325,0,0); b=spans(side,x,'x',160,325,0,0)
    print('x%5d %-26s | %-26s | %s'%(x,f(a),f(b),('%+.0f %+.0f'%(b[0][0]-a[0][0],b[-1][1]-a[-1][1])) if a and b else ''))
print('FRONT rows y: ref | model | dL dR')
for y in range(190,320,8):
    a=spans(ref,y,'y',455,595,0,0); b=spans(front,y,'y',455,595,0,0)
    print('y%4d %-22s | %-22s | %s'%(y,f(a),f(b),('%+.0f %+.0f'%(b[0][0]-a[0][0],b[-1][1]-a[-1][1])) if a and b else ''))
