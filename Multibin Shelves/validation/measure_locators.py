from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
s=Path(__file__).with_name('measure_grooves.py').read_text()
exec(s[:s.index('im=Image.new')])
im=Image.new('RGB',(1600,1000),'white'); d=ImageDraw.Draw(im)
for k,z in enumerate([0.001,0.401,0.801,1.5,3.001,3.599,4.001,5.099]):
    seg=section(2,z)
    seg=seg[(seg[:,:,:2].min((1,2))>-24.9)&(seg[:,:,:2].max((1,2))<24.9)]
    ox=k%4*400+200; oy=k//4*500+250
    d.text((ox-180,oy-230),f'Z={z}',fill='black')
    for a,b in seg: d.line([(ox+a[0]*7,oy-a[1]*7),(ox+b[0]*7,oy-b[1]*7)],fill='black',width=2)
    print('\nZ',z)
    # Intersect the right edge at multiple offsets through the midpoint notch.
    for y in [0,1,2,2.5,3,3.5,4,4.5,5,6,15,16,17,18,19,20,21]:
        xs=[]
        for a,b in seg:
            if (a[1]-y)*(b[1]-y)<0:
                x=a[0]+(b[0]-a[0])*(y-a[1])/(b[1]-a[1])
                if x>17: xs.append(x)
        print(y,np.round(sorted(xs),4).tolist(),end='; ')
    print()
im.save(Path(__file__).with_name('locator_sections.png'))
