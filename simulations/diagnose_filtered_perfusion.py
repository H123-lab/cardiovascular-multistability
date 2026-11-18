import csv, math, os
import numpy as np
from numba import njit

# Diagnostic only: existing main-branch feedback parameters, with perfusion
# driven by a first-order filtered arterial-pressure state.
T=0.8; TSYS=0.3*T; EMAX=2.0; EMIN=0.06; V0=10.0
CA=1.5; CV=100.0; RAV=0.01; RMV=0.008
P_CRIT=54.0; K_SIG=1.2; ALPHA=0.72; BETA_R=70.0
TAU_P=2.0; V_TOTAL=1452.50; DT=0.001
OUT="results/diagnostic"; os.makedirs(OUT,exist_ok=True)

@njit
def elast(t):
    if t <= TSYS: return 0.5*(1.0-math.cos(math.pi*t/TSYS))
    return 0.0

@njit
def rhs(y, phase, r):
    v,pa,pv,pm=y
    perf=ALPHA+(1.0-ALPHA)/(1.0+math.exp(-((pm-BETA_R*r)-P_CRIT)/K_SIG))
    e=EMIN+(EMAX*perf-EMIN)*elast(phase)
    plv=e*(v-V0)
    qmv=(pv-plv)/RMV if pv>plv else 0.0
    qav=(plv-pa)/RAV if plv>pa else 0.0
    qsys=(pa-pv)/r
    return np.array([qmv-qav,(qav-qsys)/CA,(qsys-qmv)/CV,(pa-pm)/TAU_P])

@njit
def integrate(y0,r,seconds):
    n=int(round(seconds/DT)); c=int(round(T/DT))
    # Last two full cycles plus their shared boundary: exactly 1601 samples.
    rec_start=n-2*c
    rec=np.empty((4,2*c+1)); y=y0.copy()
    if rec_start==0: rec[:,0]=y
    for k in range(n):
        t0=(k*DT)%T; th=((k+0.5)*DT)%T; t1=((k+1)*DT)%T
        k1=rhs(y,t0,r)
        k2=rhs(y+0.5*DT*k1,th,r)
        k3=rhs(y+0.5*DT*k2,th,r)
        k4=rhs(y+DT*k3,t1,r)
        y=y+(DT/6.0)*(k1+2*k2+2*k3+k4)
        j=k+1
        if j>=rec_start: rec[:,j-rec_start]=y
        if not np.all(np.isfinite(y)): return rec,y,False
    return rec,y,True

def cycle_metrics(rec):
    # Both cycles contain 801 points, same cardiac phase, shared boundary:
    # previous = samples 0..800; current = samples 800..1600.
    prev=rec[:,:801]; cyc=rec[:,800:1601]
    diff=float(np.max(np.abs(cyc-prev)))
    mapv=float(np.trapezoid(cyc[1],dx=DT)/T)
    return diff,mapv,cyc

def main():
    y0=np.array([120.0,135.0,(V_TOTAL-120.0-CA*135.0)/CV,135.0])
    # Baseline at Rsys=1.40, independently from 300 s and 600 s.
    base={}
    for sec in (300.0,600.0):
        rec,end,ok=integrate(y0,1.40,sec)
        if not ok: raise RuntimeError("non-finite baseline integration")
        d,m,_=cycle_metrics(rec); base[int(sec)]=(d,m)
    # Full continuation, 61 points, 300 s per point each direction.
    rs=np.round(np.arange(0.80,2.0001,0.02),4)
    fwd=np.empty((len(rs),4)); rev=np.empty((len(rs),4))
    fm=np.empty(len(rs)); rm=np.empty(len(rs))
    y=y0.copy()
    for i,r in enumerate(rs):
        rec,y,ok=integrate(y,float(r),300.0)
        if not ok: raise RuntimeError(f"non-finite forward sweep at Rsys={r}")
        _,fm[i],cyc=cycle_metrics(rec); fwd[i]=y
    for i in range(len(rs)-1,-1,-1):
        rec,y,ok=integrate(y,float(rs[i]),300.0)
        if not ok: raise RuntimeError(f"non-finite reverse sweep at Rsys={rs[i]}")
        _,rm[i],cyc=cycle_metrics(rec); rev[i]=y
    # Re-equilibrate each branch initialization at each target and compare
    # pressure trajectories over one final cycle.
    rows=[]
    for r in (1.30,1.40,1.50):
        i=int(np.argmin(np.abs(rs-r)))
        ra,ya,oka=integrate(fwd[i],r,300.0)
        rb,yb,okb=integrate(rev[i],r,300.0)
        if not (oka and okb): raise RuntimeError(f"non-finite coexistence run at Rsys={r}")
        da,ma,ca=cycle_metrics(ra); db,mb,cb=cycle_metrics(rb)
        sep=float(np.max(np.abs(ca[1]-cb[1])))
        rows.append((r,ma,mb,da,db,sep))
    with open(OUT+"/filtered_perfusion_coexistence.csv","w",newline="") as f:
        w=csv.writer(f); w.writerow(["Rsys","MAP_forward_mmHg","MAP_reverse_mmHg","Cycle_Diff_forward","Cycle_Diff_reverse","Max_Traj_Sep_Pa_mmHg"]); w.writerows(rows)
    with open(OUT+"/filtered_perfusion_summary.txt","w") as f:
        f.write(f"tau_p_s={TAU_P}; dt_s={DT}; parameters=Pcrit:{P_CRIT}, k_sig:{K_SIG}, alpha:{ALPHA}, beta_R:{BETA_R}, V_total:{V_TOTAL}\\n")
        f.write("Cycle comparison: previous samples 0..800 vs current samples 800..1600; 801 points each, same phase.\\n")
        for sec,(d,m) in base.items(): f.write(f"baseline_{sec}s_MAP_mmHg={m:.12g}; Cycle_Diff={d:.12g}\\n")
        for r,ma,mb,da,db,sep in rows: f.write(f"Rsys={r:.2f}: MAP_F={ma:.12g}, MAP_R={mb:.12g}, Cycle_Diff_F={da:.12g}, Cycle_Diff_R={db:.12g}, Max_Traj_Sep_Pa={sep:.12g}\\n")
        passed=(90<=base[300][1]<=105 and 90<=base[600][1]<=105 and base[300][0]<1e-9 and base[600][0]<1e-9 and all(x[3]<1e-9 and x[4]<1e-9 and x[5]>5 for x in rows))
        f.write("ALL_CRITERIA_PASS="+str(passed)+"\\n")
    print(open(OUT+"/filtered_perfusion_summary.txt").read())
    print(open(OUT+"/filtered_perfusion_coexistence.csv").read())
    # Diagnostic should complete successfully even when the scientific gates fail.
if __name__=="__main__": main()
