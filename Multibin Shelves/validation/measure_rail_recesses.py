from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
REF='E:/OneDrive/My Actual Documents/3D Printer/Multibuild/Board Connections/Pegboard Click - Multipoint Rail (Supported).stl'
t=np.fromfile(REF,dtype=np.dtype([('n','<f4',(3,)),('v','<f4',(3,3)),('a','<u2')]),offset=84)['v'].astype(float)
step=.1
ys=np.arange(-33,8.01,step); zs=np.arange(0,14.801,step)
front=np.full((len(ys),len(zs)),np.inf)
for v in t:
    if v[:,0].min() < -3.001 or v[:,0].min()>0: continue
    a,b,c=v
    det=(b[1]-a[1])*(c[2]-a[2])-(c[1]-a[1])*(b[2]-a[2])
    if abs(det)<1e-9:continue
    iy=np.where((ys>=v[:,1].min()-1e-6)&(ys<=v[:,1].max()+1e-6))[0]
    iz=np.where((zs>=v[:,2].min()-1e-6)&(zs<=v[:,2].max()+1e-6))[0]
    if not len(iy) or not len(iz):continue
    Y,Z=np.meshgrid(ys[iy],zs[iz],indexing='ij')
    u=((Y-a[1])*(c[2]-a[2])-(Z-a[2])*(c[1]-a[1]))/det
    w=((b[1]-a[1])*(Z-a[2])-(b[2]-a[2])*(Y-a[1]))/det
    valid=(u>=-1e-5)&(w>=-1e-5)&(u+w<=1.00001)
    x=a[0]+u*(b[0]-a[0])+w*(c[0]-a[0])
    area=front[np.ix_(iy,iz)]
    front[np.ix_(iy,iz)]=np.minimum(area,np.where(valid,x,np.inf))
grey=np.where(np.isfinite(front),np.clip(60+(front+3)*160,0,245),255).astype('uint8')
im=Image.fromarray(grey).convert('RGB').resize((len(zs)*3,len(ys)*3))
d=ImageDraw.Draw(im)
for y in [0,-12.5,-25]:
    py=int((y+33)/step*3)
    d.line([(0,py),(im.width,py)],fill='red');d.text((5,py+2),str(y),fill='red')
im.save(Path(__file__).with_name('rail_front_depth.png'))
mask=(front> -2.85)&(front<-.01)
mask[:,:15]=False;mask[:,-15:]=False
for y in [-28,-27.25,-25,-22.75,-22,-15.5,-14.75,-12.5,-10.25,-9.5,-3,-2.25,0,2.25,3]:
    i=np.argmin(abs(ys-y)); intervals=zs[mask[i]]
    print('y',y,'recess width coordinates',np.round(intervals[::max(1,len(intervals)//8)],2).tolist())
np.savez(Path(__file__).with_name('rail_front_depth.npz'),ys=ys,zs=zs,front=front)
