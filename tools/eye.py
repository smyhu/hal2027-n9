# HAL 2027 eye layers, drawn from scratch (no film artwork). 440x440 px.
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
S=440; C=(S-1)/2.0; R=219.0; RI=196.0   # outer ring radius, lens radius
rng=np.random.default_rng(7)
y,x=np.mgrid[0:S,0:S].astype(float); dx=x-C; dy=y-C; r=np.hypot(dx,dy); a=np.arctan2(dy,dx)
def save(rgb,alpha,name):
    rgb=np.clip(rgb,0,255); alpha=np.clip(alpha,0,1)
    im=np.dstack([rgb,alpha[...,None]*255]).astype(np.uint8)
    Image.fromarray(im,'RGBA').save(name)
def aa(edge):  # antialiased step from signed distance (inside positive)
    return np.clip(edge+0.5,0,1)
# 1. ring + black lens
t=(r-RI)/(R-RI)                      # 0 inner .. 1 outer
light=0.55+0.30*np.cos(2*(a+np.pi/2))**2*np.sign(-dy).clip(0,1)+0.15*np.cos(a*2+0.6)
light=0.45+0.35*(np.cos(a+np.pi/2)**2)+0.18*np.cos(3*a+0.4)   # brushed metal look
bevel=np.where(t<0.18,0.55,np.where(t>0.85,0.6,1.0))
grey=(70+150*light*bevel)[...,None]*np.array([1,1,1.04])
grey+=rng.normal(0,2.0,(S,S,1))
ring_a=aa(R-r)*aa(r-RI+0.5)
lens=np.zeros((S,S,3))+np.array([3,1,1])
inner_shadow=np.clip((r-(RI-14))/14,0,1)[...,None]*np.array([-3,-1,-1])
rgb=np.where((r<RI)[...,None],lens+inner_shadow,grey)
alpha=np.maximum(ring_a,aa(RI-r))
save(rgb,alpha,'ring.png')
# 2. red glow (animated: opacity + scale), noise against 16-bit banding
g=np.clip(1-r/(RI*0.86),0,1)
glow_a=np.clip(g**1.15*1.15,0,1)
col=np.dstack([235*np.ones_like(r),12+40*g**6,8+10*g**6])
col+=rng.normal(0,3,(S,S,1)); glow_a=glow_a+rng.normal(0,0.012,(S,S))*(g>0)
save(col,glow_a*(r<RI),'glow.png')
# 3. hot core: yellow dot with orange halo
c=np.clip(1-r/(RI*0.22),0,1)
core_a=np.clip(c**2.2*1.2,0,1)
dot=aa(RI*0.045-r)
rgb=np.dstack([255*np.ones_like(r),110+130*c**3+15*dot,20+40*dot])
core_a=np.maximum(core_a,dot)
save(rgb+rng.normal(0,3,(S,S,1)),core_a,'core.png')
# 4. glass reflections (own shapes): wide top arc, side arcs, small inner arcs
im=Image.new('RGBA',(S,S),(0,0,0,0)); d=ImageDraw.Draw(im)
def arc(rad,a0,a1,w,alpha,col=(235,235,230)):
    bb=[C-rad,C-rad,C+rad,C+rad]; d.arc(bb,a0,a1,fill=col+(alpha,),width=w)
arc(RI*0.86,248,292,18,175)
arc(RI*0.92,200,232,9,120); arc(RI*0.92,308,340,9,120)
arc(RI*0.62,255,285,8,95,(240,200,200)); arc(RI*0.62,215,235,6,70,(240,190,190)); arc(RI*0.62,305,325,6,70,(240,190,190))
arc(RI*0.40,250,290,5,90,(255,170,150)); arc(RI*0.30,258,282,4,80,(255,180,150))
arc(RI*0.97,140,175,3,55); arc(RI*0.97,5,40,3,55)
im=im.filter(ImageFilter.GaussianBlur(1.2))
im.save('reflections.png')
# 5. progress ring half (red), for the recording arc: right half of an annulus
P0,P1=RI-2,RI-12
pa=aa(P0-r)*aa(r-P1)*(dx>=0)
save(np.dstack([225*np.ones_like(r),20*np.ones_like(r),15*np.ones_like(r)]),pa,'progress-red.png')
# preview composite
base=Image.new('RGBA',(S,S),(0,0,0,255))
for n in ['ring.png','glow.png','core.png','reflections.png']:
    base=Image.alpha_composite(base,Image.open(n))
base.save('eye-preview.png')
