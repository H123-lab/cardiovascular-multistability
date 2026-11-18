import csv, itertools, math, os, time
import numpy as np
from numba import njit

DT=0.001; T=0.8; TSYS=0.3*T
EMAX=2.0; EMIN=0.06; V0=10.0
CA=1.5; CV=100.0; RAV=0.01; RMV=0.008
ALPHA=0.72
OUT="results/calibration"; os.makedirs(OUT,exist_ok=True)

@njit
def elast(t):
    if t <= TSYS:
        return 0.5*(1.0-math.cos(math.pi*t/TSYS))
    return 0.0

@njit
def rhs(y, phase, r, pcrit, ksig, beta, tau):
    v,pa,pv,pm=y
    z=(pm-beta*r-pcrit)/ksig
    # Numerically stable logistic for the expected physiological range.
    if z >= 0.0:
        s=1.0/(1.0+math.exp(-z))
    else:
        ez=math.exp(z); s=ez/(1.0+ez)
    perf=ALPHA+(1.0-ALPHA)*s
    e=EMIN+(EMAX*perf-EMIN)*elast(phase)
    plv=e*(v-V0)
    qmv=(pv-plv)/RMV if pv>plv else 0.0
    qav=(plv-pa)/RAV if plv>pa else 0.0
    qsys=(pa-pv)/r
    return np.array([qmv-qav,(qav-qsys)/CA,(qsys-qmv)/CV,(pa-pm)/tau])

@njit
def integrate(y0,r,seconds,pcrit,ksig,beta,tau):
    n=int(round(seconds/DT)); c=int(round(T/DT))
    rec_start=n-2*c
    rec=np.empty((4,2*c+1)); y=y0.copy()
    for k in range(n):
        t0=(k*DT)%T; th=((k+0.5)*DT)%T; t1=((k+1)*DT)%T
        k1=rhs(y,t0,r,pcrit,ksig,beta,tau)
        k2=rhs(y+0.5*DT*k1,th,r,pcrit,ksig,beta,tau)
        k3=rhs(y+0.5*DT*k2,th,r,pcrit,ksig,beta,tau)
        k4=rhs(y+DT*k3,t1,r,pcrit,ksig,beta,tau)
        y=y+(DT/6.0)*(k1+2*k2+2*k3+k4)
        j=k+1
        if j>=rec_start: rec[:,j-rec_start]=y
        if not np.all(np.isfinite(y)):
            return rec,y,False
    return rec,y,True

@njit
def metrics(rec):
    # Phase-aligned 801-sample cycles: previous 0..800 vs current 800..1600.
    d=0.0; area=0.0
    for j in range(801):
        for q in range(4):
            x=abs(rec[q,j+800]-rec[q,j])
            if x>d: d=x
        if j>0:
            area += 0.5*(rec[1,j+800]+rec[1,j+799])*DT
    return d,area/T

def run_candidate(vtot,pcrit,ksig,beta,tau,do_coexist=False):
    y0=np.array([120.0,135.0,(vtot-120.0-CA*135.0)/CV,135.0])
    rec300,end,ok=integrate(y0,1.40,300.0,pcrit,ksig,beta,tau)
    if not ok: return None
    d300,m300=metrics(rec300)
    if not (90.0<=m300<=105.0 and d300<1e-8):
        return {"MAP300":m300,"D300":d300,"MAP600":float("nan"),"D600":float("nan"),"coexist":False}
    rec600,end600,ok=integrate(y0,1.40,600.0,pcrit,ksig,beta,tau)
    if not ok: return None
    d600,m600=metrics(rec600)
    if not (90.0<=m600<=105.0 and d600<1e-8):
        return {"MAP300":m300,"D300":d300,"MAP600":m600,"D600":d600,"coexist":False}
    if not do_coexist:
        return {"MAP300":m300,"D300":d300,"MAP600":m600,"D600":d600,"coexist":False}
    # Full 61-point forward/reverse continuation; each step is 300 s.
    rs=np.round(np.arange(0.80,2.0001,0.02),4)
    fwd=np.empty((len(rs),4)); rev=np.empty((len(rs),4))
    y=y0.copy()
    for i,r in enumerate(rs):
        _,y,ok=integrate(y,float(r),300.0,pcrit,ksig,beta,tau)
        if not ok: return {"MAP300":m300,"D300":d300,"MAP600":m600,"D600":d600,"coexist":False}
        fwd[i]=y
    for i in range(len(rs)-1,-1,-1):
        _,y,ok=integrate(y,float(rs[i]),300.0,pcrit,ksig,beta,tau)
        if not ok: return {"MAP300":m300,"D300":d300,"MAP600":m600,"D600":d600,"coexist":False}
        rev[i]=y
    co=[]
    for r in (1.30,1.40,1.50):
        idx=int(np.argmin(np.abs(rs-r)))
        a,_,oka=integrate(fwd[idx],r,300.0,pcrit,ksig,beta,tau)
        b,_,okb=integrate(rev[idx],r,300.0,pcrit,ksig,beta,tau)
        if not (oka and okb): return {"MAP300":m300,"D300":d300,"MAP600":m600,"D600":d600,"coexist":False}
        da,ma=metrics(a); db,mb=metrics(b)
        sep=float(np.max(np.abs(a[1,800:1601]-b[1,800:1601])))
        co.append((r,ma,mb,da,db,sep))
    pass_co=all(x[3]<1e-8 and x[4]<1e-8 and x[5]>5.0 for x in co)
    return {"MAP300":m300,"D300":d300,"MAP600":m600,"D600":d600,"coexist":pass_co,"co":co}

def main():
    grid=list(itertools.product(
        [950.0,975.0,1000.0,1025.0],
        [2.5,3.0,3.5,4.0,4.5],
        [1.0,2.0],
        [25.0,30.0,35.0,40.0],
        [45.0,50.0,55.0,60.0]))
    # Requested grid ordering is preserved: V_total, k_sig, tau_p, P_crit, beta_R.
    rows=[]; winner=None; t0=time.time()
    for n,(vt,ks,tau,pc,be) in enumerate(grid,1):
        result=run_candidate(vt,pc,ks,be,tau,False)
        if result is None: result={"MAP300":float("nan"),"D300":float("inf"),"MAP600":float("nan"),"D600":float("nan"),"coexist":False}
        rows.append((vt,ks,tau,pc,be,result["MAP300"],result["D300"],result["MAP600"],result["D600"]))
        if 90.0<=result["MAP300"]<=105.0 and result["D300"]<1e-8 and 90.0<=result["MAP600"]<=105.0 and result["D600"]<1e-8:
            full=run_candidate(vt,pc,ks,be,tau,True)
            if full and full["coexist"]:
                winner=(vt,ks,tau,pc,be,full)
                break
        if n%20==0:
            print(f"PROGRESS {n}/{len(grid)} elapsed_s={time.time()-t0:.1f}",flush=True)
    with open(OUT+"/filtered_perfusion_grid_scan.csv","w",newline="") as f:
        w=csv.writer(f); w.writerow(["V_total_mL","k_sig_mmHg","tau_p_s","P_crit_mmHg","beta_R","MAP_300s_mmHg","Cycle_Diff_300s","MAP_600s_mmHg","Cycle_Diff_600s"]); w.writerows(rows)
    with open(OUT+"/filtered_perfusion_calibration_summary.txt","w") as f:
        f.write(f"Grid_size={len(grid)}; tested={len(rows)}; dt_s={DT}; alpha={ALPHA}; Rsys_baseline=1.40\n")
        f.write("Cycle_Diff is max absolute difference across all four states, comparing phase-aligned samples 0..800 and 800..1600.\n")
        f.write("Gates: MAP 90-105 at 300/600 s; Cycle_Diff < 1e-8 at 300/600 s; forward/reverse branch Cycle_Diff < 1e-8 and Pa trajectory separation > 5 mmHg at each Rsys 1.30/1.40/1.50.\n")
        if winner:
            vt,ks,tau,pc,be,full=winner
            f.write(f"WINNER: V_total={vt}, k_sig={ks}, tau_p={tau}, P_crit={pc}, beta_R={be}, alpha={ALPHA}\n")
            f.write(f"MAP300={full['MAP300']:.12g}; Cycle_Diff300={full['D300']:.12g}; MAP600={full['MAP600']:.12g}; Cycle_Diff600={full['D600']:.12g}\n")
            with open(OUT+"/winning_coexistence.csv","w",newline="") as fc:
                w=csv.writer(fc); w.writerow(["Rsys","MAP_forward","MAP_reverse","Cycle_Diff_forward","Cycle_Diff_reverse","Max_Traj_Sep_Pa_mmHg"]); w.writerows(full["co"])
            f.write("ALL_THREE_GATES_PASS=True\n")
        else:
            f.write("WINNER=NONE\nALL_THREE_GATES_PASS=False\n")
        f.write(f"Elapsed_s={time.time()-t0:.2f}\n")
    print(open(OUT+"/filtered_perfusion_calibration_summary.txt").read())
    print("Scan rows:",len(rows))
    print("Candidates passing baseline gates:",sum(1 for x in rows if 90<=x[5]<=105 and x[6]<1e-8 and 90<=x[7]<=105 and x[8]<1e-8))

if __name__=="__main__": main()
