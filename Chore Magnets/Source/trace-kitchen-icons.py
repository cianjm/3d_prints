from PIL import Image
from pathlib import Path
from collections import defaultdict
import math
base=Path(__file__).resolve().parent.parent
items={'clean_counters':('kitchen-approved-concepts.png',(45,45,610,525)), 'dishwasher':('kitchen-approved-concepts.png',(680,45,1200,535)), 'clean_dishes':('clean-dishes-reference.png',(110,100,865,885)), 'drying_dishes':('kitchen-approved-concepts.png',(655,685,1200,1155))}
def inside(pt,poly):
 x,y=pt; hit=False
 for i,(x1,y1) in enumerate(poly):
  x2,y2=poly[(i+1)%len(poly)]
  if (y1>y)!=(y2>y) and x < (x2-x1)*(y-y1)/(y2-y1)+x1:hit=not hit
 return hit
def trace(name, item):
 file,box=item;frame=Image.open(base/'Design'/file).convert('RGB').crop(box);frame.thumbnail((240,240),Image.Resampling.LANCZOS);w,h=frame.size
 a=[[(lambda v: max(v)<115 if name == 'clean_dishes' else v[2]>v[0]*1.15 and v[0]<100 and v[1]<130)(frame.getpixel((x,y))) for x in range(w)] for y in range(h)]
 edges=defaultdict(list)
 def add(p,q):edges[p].append(q)
 for y in range(h):
  for x in range(w):
   if not a[y][x]:continue
   if y==0 or not a[y-1][x]:add((x,y),(x+1,y))
   if x==w-1 or not a[y][x+1]:add((x+1,y),(x+1,y+1))
   if y==h-1 or not a[y+1][x]:add((x+1,y+1),(x,y+1))
   if x==0 or not a[y][x-1]:add((x,y+1),(x,y))
 loops=[]
 while edges:
  start=next(iter(edges));cur=start;loop=[]
  while True:
   loop.append(cur); nxt=edges[cur].pop()
   if not edges[cur]:del edges[cur]
   cur=nxt
   if cur==start:break
   if cur not in edges:raise ValueError((name,'broken contour'))
  points=[]
  for i,b in enumerate(loop):
   aa=loop[i-1];c=loop[(i+1)%len(loop)]
   if (b[0]-aa[0])*(c[1]-b[1]) != (b[1]-aa[1])*(c[0]-b[0]):points.append(b)
  if len(points)<3:continue
  area=sum(points[i][0]*points[(i+1)%len(points)][1]-points[(i+1)%len(points)][0]*points[i][1] for i in range(len(points)))/2
  if abs(area)<2:continue
  p,q=points[0],points[1];dx=q[0]-p[0];dy=q[1]-p[1];mag=math.hypot(dx,dy);sign=1 if area>0 else -1
  probe=((p[0]+q[0])/2-sign*dy/mag*.2,(p[1]+q[1])/2+sign*dx/mag*.2)
  loops.append({'p':points,'area':area,'probe':probe})
 for item in loops:
  ancestors=[other for other in loops if abs(other['area'])>abs(item['area']) and inside(item['probe'],other['p'])]
  item['parent']=min(ancestors,key=lambda it:abs(it['area'])) if ancestors else None
 def poly(points):return 'polygon(points=['+','.join('[%.5f,%.5f]'%((x-w/2)/w,(h/2-y)/w) for x,y in points)+']);'
 pieces=[]
 for item in loops:
  if item['area']<=0:continue
  holes=[x for x in loops if x['parent'] is item and x['area']<0]
  pieces.append('difference() {'+poly(item['p'])+' union() {'+''.join(poly(x['p']) for x in holes)+'}}')
 print(name,w,h,'components',len(pieces))
 return 'module icon_'+name+'() { union() {\n'+'\n'.join(pieces)+'\n} }\n'
modules=''.join(trace(k,v) for k,v in items.items())
(base/'Source/kitchen-icon-contours.scad').write_text(modules)
