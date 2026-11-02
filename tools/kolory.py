# colour variants of the glow, core and progress layers
import numpy as np
from PIL import Image
S=440; C=(S-1)/2.0; RI=196.0
rng=np.random.default_rng(7)
y,x=np.mgrid[0:S,0:S].astype(float); dx=x-C; dy=y-C; r=np.hypot(dx,dy)
def aa(e): return np.clip(e+0.5,0,1)
def save(rgb,alpha,name):
    im=np.dstack([np.clip(rgb,0,255),np.clip(alpha,0,1)[...,None]*255]).astype(np.uint8)
    Image.fromarray(im,'RGBA').save(name,optimize=True)
COLS={ # glow colour, hot centre colour, core dot
 'red':   ((235,12,8),(255,240,40),(255,255,120)),
 'green': ((20,215,55),(200,255,120),(235,255,200)),
 'blue':  ((25,110,255),(150,220,255),(225,245,255)),
 'amber': ((255,135,0),(255,225,110),(255,250,200)),
 'violet':((160,50,255),(235,170,255),(250,230,255)),
}
g=np.clip(1-r/(RI*0.86),0,1); glow_a=np.clip(g**1.15*1.15,0,1)
c=np.clip(1-r/(RI*0.22),0,1); core_a=np.clip(c**2.2*1.2,0,1); dot=aa(RI*0.045-r)
noise=rng.normal(0,2.5,(S,S,1)); anoise=rng.normal(0,0.010,(S,S))*(g>0)
for name,(gc,hc,dc) in COLS.items():
    gcol=np.array(gc,float); hot=np.array(hc,float); dcol=np.array(dc,float)
    col=gcol+(np.array([255,255,255])-gcol)*0.15*(g**6)[...,None]
    save(col+noise,(glow_a+anoise)*(r<RI),'poswiata-%s.png'%name)
    k=(c**1.5)[...,None]
    rgb=gcol*(1-k)+hot*k; rgb=rgb*(1-dot[...,None])+dcol*dot[...,None]
    save(rgb,np.maximum(core_a,dot),'rdzen-%s.png'%name)
    pa=aa(RI-2-r)*aa(r-(RI-12))*(dx>=0)
    pc=np.clip(gcol*0.95,0,255)
    save(np.ones((S,S,3))*pc,pa,'postep-%s.png'%name)
base=Image.open('pierscien.png'); ref=Image.open('odblaski.png')
row=Image.new('RGBA',(5*220,220))
for i,n in enumerate(COLS):
    b=Image.new('RGBA',(S,S),(0,0,0,255))
    for l in [base,Image.open('poswiata-%s.png'%n),Image.open('rdzen-%s.png'%n),ref]: b=Image.alpha_composite(b,l)
    row.paste(b.resize((220,220),Image.LANCZOS),(i*220,0))
row.save('kolory-podglad.png')
