import json,struct,numpy as np
from numpy.linalg import inv
class GLB:
    def __init__(s,f):
        d=open(f,'rb').read(); l=struct.unpack('<I',d[12:16])[0]; s.j=json.loads(d[20:20+l]); bl=struct.unpack('<I',d[20+l:24+l])[0]; s.B=bytearray(d[28+l:28+l+bl])
        s.parent={}
        for i,n in enumerate(s.j['nodes']):
            for c in n.get('children',[]): s.parent[c]=i
    def acc(s,i):
        j=s.j; a=j['accessors'][i]; bv=j['bufferViews'][a['bufferView']]; off=bv.get('byteOffset',0)+a.get('byteOffset',0)
        k={'VEC3':3,'VEC2':2,'VEC4':4,'SCALAR':1,'MAT4':16}[a['type']]; dt={5126:np.float32,5125:np.uint32,5123:np.uint16,5121:np.uint8}[a['componentType']]
        return np.frombuffer(s.B,dt,a['count']*k,off).reshape(-1,k), off
    def local(s,i):
        n=s.j['nodes'][i]; M=np.eye(4)
        if 'matrix' in n: return np.array(n['matrix']).reshape(4,4).T
        t=n.get('translation',[0,0,0]); x,y,z,w=n.get('rotation',[0,0,0,1]); sc=n.get('scale',[1,1,1])
        R=np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
        M[:3,:3]=R*np.array(sc); M[:3,3]=t; return M
    def world(s,i):
        M=s.local(i)
        while i in s.parent: i=s.parent[i]; M=s.local(i)@M
        return M
    def save(s,f):
        js=json.dumps(s.j,separators=(',',':')).encode()
        while len(js)%4: js+=b' '
        while len(s.B)%4: s.B.append(0)
        s.j['buffers'][0]['byteLength']=len(s.B)
        js=json.dumps(s.j,separators=(',',':')).encode()
        while len(js)%4: js+=b' '
        o=struct.pack('<III',0x46546C67,2,12+8+len(js)+8+len(s.B))+struct.pack('<II',len(js),0x4E4F534A)+js+struct.pack('<II',len(s.B),0x004E4942)+bytes(s.B)
        open(f,'wb').write(o)
