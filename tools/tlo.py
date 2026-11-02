import numpy as np
from PIL import Image
W,H=480,854
y,x=np.mgrid[0:H,0:W].astype(float)
d=np.hypot((x-240)/300.0,(y-380)/470.0)
v=np.clip(1-d,0,1)**1.5*52.0           # center ~ (52,50,52) like Lyrion
img=np.dstack([v,v*0.96,v])
# Floyd-Steinberg to RGB565
out=img.copy()
lv=[255/31.0,255/63.0,255/31.0]
for yy in range(H):
    for xx in range(W):
        old=out[yy,xx].copy()
        new=np.array([round(old[c]/lv[c])*lv[c] for c in range(3)])
        out[yy,xx]=new; e=old-new
        if xx+1<W: out[yy,xx+1]+=e*7/16
        if yy+1<H:
            if xx>0: out[yy+1,xx-1]+=e*3/16
            out[yy+1,xx]+=e*5/16
            if xx+1<W: out[yy+1,xx+1]+=e*1/16
Image.fromarray(np.clip(out,0,255).round().astype(np.uint8),'RGB').save('tlo.png')
