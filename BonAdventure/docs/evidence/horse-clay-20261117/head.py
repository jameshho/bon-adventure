import sys, prof
prof.THRESH=int(__import__("os").environ.get("TH","38"))
from prof import polys, spans
regs=polys(sys.argv[1], minarea=12)
def f(s): return ' '.join('%.0f-%.0f'%ab for ab in s)
x0,x1,y0,y1=[float(v) for v in sys.argv[2:6]]
st=int(sys.argv[6]) if len(sys.argv)>6 else 6
print('rows')
for y in range(int(y0),int(y1),st): print('y%4d'%y, f(spans(regs,y,'y',x0,x1,0,0)))
print('cols')
for x in range(int(x0),int(x1),st):
    s=[(a,b) for a,b in spans(regs,x,'x',y0,y1,0,0)]
    print('x%5d'%x, f(s))
