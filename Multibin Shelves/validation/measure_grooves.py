from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
REF='E:/OneDrive/My Actual Documents/3D Printer/Multibuild/Multibin Shells/2x2x0.5 LU - Topped Rail - MultiBin Shell.stl'
t=np.fromfile(REF,dtype=np.dtype([('n','<f4',(3,)),('v','<f4',(3,3)),('a','<u2')]),offset=84)['v'].astype(float)
def section(axis,level):
    tri=t[(t[:,:,axis].min(1)<level)&(t[:,:,axis].max(1)>level)]
    lines=[]
    for v in tri:
        points=[]
        for i,j in [(0,1),(1,2),(2,0)]:
            if (v[i,axis]-level)*(v[j,axis]-level)<0:
                points.append(v[i]+(v[j]-v[i])*(level-v[i,axis])/(v[j,axis]-v[i,axis]))
        if len(points)==2: lines.append(points)
    return np.array(lines)
im=Image.new('RGB',(1500,1100),'white'); d=ImageDraw.Draw(im)
for k,z in enumerate([0.01,0.5,1.01,2,3.01,4,5,5.21]):
    seg=section(2,z)
    ox=(k%4)*375; oy=(k//4)*550
    d.text((ox+10,oy+10),f'Z = {z} mm',fill='black')
    for line in seg:
        p=[(ox+25+(v[0]+25)*3.2,oy+60+(v[1]+25)*3.2) for v in line]
        d.line(p,fill='black',width=1)
    # Foot boundary at y=7, away from its threaded holes and side notches.
    xs=[]
    for a,b in seg:
        if (a[1]-7)*(b[1]-7)<0: xs.append(a[0]+(b[0]-a[0])*(7-a[1])/(b[1]-a[1]))
    print('z',z,'x boundaries at y=7:',np.round(sorted(xs),5).tolist())
im.save(Path(__file__).with_name('groove_sections.png'))
# Vertical section through a foot, excluding its holes and notches.
seg=section(1,7)
im=Image.new('RGB',(1600,650),'white'); d=ImageDraw.Draw(im)
for a,b in seg:
    if min(a[2],b[2])<6:
        d.line([(40+(a[0]+26)*14,550-a[2]*70),(40+(b[0]+26)*14,550-b[2]*70)],fill='black',width=2)
for a,b in seg:
    if max(a[2],b[2])<=5.21 and min(a[0],b[0])>15 and max(a[0],b[0])<35:
        print('profile',np.round([a,b],4).tolist())
im.save(Path(__file__).with_name('groove_profile.png'))
