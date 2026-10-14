"""Adds finger bones (Thumb/Index/Middle/Ring/Pinky x3 per hand) to a Meshy 24-joint GLB.
Fingers are fused in the low-poly mesh, so vertices are assigned by position with soft blending."""
import numpy as np, sys, json
from glb import GLB
FINGERS=['Index','Middle','Ring','Pinky']
SEG=[0.0,0.42,0.72]   # bone starts along finger (fraction of length)

def quat_from_matrix(R):
    m=R; tr=m[0,0]+m[1,1]+m[2,2]
    if tr>0:
        s=np.sqrt(tr+1.0)*2; w=0.25*s; x=(m[2,1]-m[1,2])/s; y=(m[0,2]-m[2,0])/s; z=(m[1,0]-m[0,1])/s
    elif m[0,0]>m[1,1] and m[0,0]>m[2,2]:
        s=np.sqrt(1+m[0,0]-m[1,1]-m[2,2])*2; w=(m[2,1]-m[1,2])/s; x=0.25*s; y=(m[0,1]+m[1,0])/s; z=(m[0,2]+m[2,0])/s
    elif m[1,1]>m[2,2]:
        s=np.sqrt(1+m[1,1]-m[0,0]-m[2,2])*2; w=(m[0,2]-m[2,0])/s; x=(m[0,1]+m[1,0])/s; y=0.25*s; z=(m[1,2]+m[2,1])/s
    else:
        s=np.sqrt(1+m[2,2]-m[0,0]-m[1,1])*2; w=(m[1,0]-m[0,1])/s; x=(m[0,2]+m[2,0])/s; y=(m[1,2]+m[2,1])/s; z=0.25*s
    q=np.array([x,y,z,w]); return (q/np.linalg.norm(q)).tolist()

def kmeans1d(x,k,iters=30):
    c=np.quantile(x,np.linspace(0.12,0.88,k))
    for _ in range(iters):
        lab=np.argmin(np.abs(x[:,None]-c[None]),1)
        c=np.array([x[lab==i].mean() if (lab==i).any() else c[i] for i in range(k)])
    return np.sort(c)

OVERRIDE={}
SMOOTH_ITERS=4
def rig(path_in, path_out):
    g=GLB(path_in); j=g.j
    p=j['meshes'][0]['primitives'][0]
    P=g.acc(p['attributes']['POSITION'])[0]
    (J,joff)=g.acc(p['attributes']['JOINTS_0']); (W,woff)=g.acc(p['attributes']['WEIGHTS_0'])
    J=J.copy().astype(np.int32); W=W.copy()
    sk=j['skins'][0]; names=[j['nodes'][k]['name'] for k in sk['joints']]
    IBM=list(g.acc(sk['inverseBindMatrices'])[0].reshape(-1,4,4).transpose(0,2,1))
    report={}
    for side in ['Left','Right']:
        h=names.index(side+'Hand'); hnode=sk['joints'][h]; Wh=g.world(hnode)
        wh=(W*(J==h)).sum(1); hv=np.where(wh>0.3)[0]
        o=Wh[:3,3]
        dist=np.linalg.norm(P[hv]-o,axis=1); far=hv[dist>np.quantile(dist,0.95)]
        d=P[far].mean(0)-o; L=np.linalg.norm(d); d/=L
        rel=P[hv]-o; t=rel@d/L; perp=rel-np.outer(rel@d,d)
        zone=(t>0.12)&(t<0.5)
        e=perp[zone][np.argmax(np.linalg.norm(perp[zone],axis=1))]; e/=np.linalg.norm(e)   # thumb direction
        n=np.cross(d,e)*(1.0 if side=='Left' else -1.0); n/=np.linalg.norm(n)                # palm normal
        a=e   # lateral axis: thumb side positive
        lat=rel@a/L
        # thumb side: biggest lateral protrusion below the fingertip zone
        low=(t<0.45)&(t>0.1)
        side_sign=1.0
        tips=(t>0.64)&(side_sign*lat<np.quantile(side_sign*lat[t>0.64],0.97))
        centers=kmeans1d(lat[tips],4)
        finger_half=(centers[-1]-centers[0])/6.0
        edge=centers.max() if side_sign>0 else -centers.min()
        thumb_mask=(side_sign*lat>edge+finger_half*0.6)&(t<0.62)&(t>0.08)
        # order fingers from thumb side: index first
        order=np.argsort(-side_sign*centers); centers=centers[order]
        k_t=0.56   # knuckle line
        new_bones=[]  # (name, parent_name, world_pos, dir)
        chains={}
        for fi,fname in enumerate(FINGERS):
            sel=tips&(np.abs(lat-centers[fi])<finger_half*1.2)
            tip_t=np.quantile(t[sel],0.97) if sel.any() else 1.0
            base=o+d*L*k_t+a*L*centers[fi]*0.85
            tip=o+d*L*tip_t+a*L*centers[fi]
            chains[fname]=(base,tip)
        tv=np.where(thumb_mask)[0]
        tq=rel[tv]
        tip_i=np.argmax(side_sign*lat[tv]*0.6+t[tv])
        ttip=P[hv[tv[tip_i]]]
        tbase=o+d*L*0.18+a*L*side_sign*(edge*0.9)
        chains['Thumb']=(tbase,ttip)
        # weights
        newW=[]
        for fname,(b,e) in chains.items():
            seg=e-b; ln=np.linalg.norm(seg); fd=seg/ln
            ca=np.cross(fd,n); ca/=np.linalg.norm(ca)
            for si,s0 in enumerate(SEG):
                new_bones.append((f'{side}Hand{fname}{si+1}', f'{side}Hand' if si==0 else f'{side}Hand{fname}{si}', b+seg*s0, fd, ca))
        # soft finger assignment for each hand vertex
        nf=len(FINGERS)
        def along(fname,X):
            b,e=chains[fname]; seg=e-b; ln=np.linalg.norm(seg); s=((X-b)@seg)/ln**2
            closest=b+np.clip(s,0,1)[:,None]*seg; return s, np.linalg.norm(X-closest,axis=1)
        X=P[hv]
        sF=[];dF=[]
        for fname in FINGERS+['Thumb']:
            s,dd=along(fname,X); sF.append(s); dF.append(dd)
        sF=np.array(sF); dF=np.array(dF)
        sigma=L*0.045
        aff=np.exp(-(dF/sigma)**2)
        in_fingers=(t>k_t-0.06)
        aff[:4,~in_fingers]=0
        aff[4,~thumb_mask & (t>0.25)]=aff[4,~thumb_mask & (t>0.25)]*0.0
        aff[4,thumb_mask]=np.maximum(aff[4,thumb_mask],1.0)
        aff[:4,thumb_mask]=0
        weak=in_fingers & ~thumb_mask & (aff[:4].sum(0)<0.05)
        nearest=np.argmin(dF[:4],0)
        aff[nearest[weak],np.where(weak)[0]]=1.0
        tot=aff.sum(0)
        name_to_new={nb[0]:i for i,nb in enumerate(new_bones)}
        base_index=len(names)
        for vi_local,vi in enumerate(hv):
            if tot[vi_local]<1e-3: continue
            fw=aff[:,vi_local]/tot[vi_local]
            infl={}
            for k,fname in enumerate(FINGERS+['Thumb']):
                if fw[k]<0.05: continue
                s=sF[k,vi_local]
                # blend to hand near the base
                root=np.clip(s/0.12,0,1)
                infl[h]=infl.get(h,0)+fw[k]*(1-root)
                # segments
                segw=np.zeros(3)
                for si in range(3):
                    lo=SEG[si]; hi=SEG[si+1] if si<2 else 9
                    segw[si]=np.clip(min(s-lo+0.05, hi-s+0.05)/0.1,0,1)
                if segw.sum()==0: segw[0]=1
                segw/=segw.sum()
                for si in range(3):
                    ji=base_index+name_to_new[f'{side}Hand{fname}{si+1}']
                    infl[ji]=infl.get(ji,0)+fw[k]*root*segw[si]
            keep=sorted(infl.items(),key=lambda x:-x[1])[:4]
            sw=sum(w for _,w in keep)
            if sw<=0: continue
            J[vi]=0; W[vi]=0
            for slot,(ji,w) in enumerate(keep): J[vi,slot]=ji; W[vi,slot]=w/sw
        # add nodes
        for (nm,parent_nm,pos,fd,ca) in new_bones:
            pidx=sk['joints'][names.index(parent_nm)] if parent_nm in names else None
            if pidx is None:
                pidx=[i for i,nd in enumerate(j['nodes']) if nd.get('name')==parent_nm][0]
            Wp=g.world(pidx); spar=np.cbrt(abs(np.linalg.det(Wp[:3,:3])))
            R=np.stack([ca,fd,np.cross(ca,fd)],1)
            Wb=np.eye(4); Wb[:3,:3]=R*spar; Wb[:3,3]=pos
            Lc=np.linalg.inv(Wp)@Wb
            Rl=Lc[:3,:3]/np.cbrt(abs(np.linalg.det(Lc[:3,:3])))
            node={'name':nm,'translation':Lc[:3,3].tolist(),'rotation':quat_from_matrix(Rl)}
            j['nodes'].append(node); ni=len(j['nodes'])-1
            j['nodes'][pidx].setdefault('children',[]).append(ni); g.parent[ni]=pidx
            sk['joints'].append(ni); names.append(nm); IBM.append(np.linalg.inv(g.world(ni)))
        report[side]=dict(thumb=int(thumb_mask.sum()), centers=np.round(centers,3).tolist(), thumb_side=side_sign)
    # --- weight smoothing over welded mesh neighbours (removes spikes on fused fingers)
    I=g.acc(p['indices'])[0].reshape(-1,3)
    _,weld=np.unique(np.round(P,4),axis=0,return_inverse=True); weld=weld.ravel()
    hand_joints=set(names.index(s_+'Hand') for s_ in ['Left','Right'])|set(range(len(names)-30,len(names)))
    touched=np.where(np.isin(J,list(hand_joints)).any(1))[0]
    tset=set(touched.tolist())
    nb={}
    for tri in I:
        wt=[weld[v] for v in tri]
        for x in range(3):
            for y in range(3):
                if x!=y: nb.setdefault(wt[x],set()).add(wt[y])
    jl=sorted(set(J[touched].ravel().tolist()))
    col={jj:i for i,jj in enumerate(jl)}
    D=np.zeros((len(P),len(jl)))
    for v in touched:
        for sl in range(4): D[v,col[J[v,sl]]]+=W[v,sl]
    # weld-level averaging
    nwe=weld.max()+1
    for it in range(SMOOTH_ITERS):
        acc=np.zeros((nwe,len(jl))); cnt=np.zeros(nwe)
        np.add.at(acc,weld[touched],D[touched]); np.add.at(cnt,weld[touched],1)
        Wd=acc/np.maximum(cnt,1)[:,None]
        newD=D.copy()
        for v in touched:
            ns=[q for q in nb.get(weld[v],()) if cnt[q]>0]
            if not ns: continue
            avg=Wd[ns].mean(0)
            newD[v]=0.5*Wd[weld[v]]+0.5*avg
        D=newD
    for v in touched:
        order=np.argsort(-D[v])[:4]; ws=D[v,order]; ws=np.maximum(ws,0)
        if ws.sum()<=0: continue
        ws/=ws.sum(); J[v]=[jl[o] for o in order]; W[v]=ws
    assert J.max()<256
    g.B[joff:joff+J.size]=J.astype(np.uint8).tobytes()
    g.B[woff:woff+W.size*4]=W.astype(np.float32).tobytes()
    # new IBM accessor
    data=np.array([m.T for m in IBM],dtype=np.float32).tobytes()
    g.B=bytearray(bytes(g.B))
    while len(g.B)%4: g.B.append(0)
    j['bufferViews'].append({'buffer':0,'byteOffset':len(g.B),'byteLength':len(data)}); g.B+=data
    j['accessors'].append({'bufferView':len(j['bufferViews'])-1,'componentType':5126,'count':len(IBM),'type':'MAT4'})
    sk['inverseBindMatrices']=len(j['accessors'])-1
    g.save(path_out)
    return report

if __name__=='__main__':
    print(rig(sys.argv[1], sys.argv[2]))
