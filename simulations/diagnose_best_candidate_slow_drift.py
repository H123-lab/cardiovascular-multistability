import csv, json, math, time
from pathlib import Path
import numpy as np
from numba import njit

DT=0.001; T=0.8; TSYS=0.3*T
VTOT=950.0; KSIG=2.5; TAU=2.0; PCRIT=25.0; BETA=45.0; ALPHA=0.72
EMAX=2.0; EMIN=0.06; V0=10.0; CA=1.5; CV=100.0
RAV=0.01; RMV=0.008
TARGETS=(1.30,1.40,1.50)
CHECKPOINTS=(300,600,1200,2000)
OUT=Path("results/diagnostic/slow_drift_best_candidate"); OUT.mkdir(parents=True,exist_ok=True)

@njit
def elast(phase):
    if phase<=TSYS:
        return 0.5*(1.0-math.cos(math.pi*phase/TSYS))
    return 0.0

@njit
def rhs(y,phase,r):
    v,pa,pv,pm=y
    z=(pm-BETA*r-PCRIT)/KSIG
    if z>=0.0:
        sig=1.0/(1.0+math.exp(-z))
    else:
        ez=math.exp(z); sig=ez/(1.0+ez)
    perf=ALPHA+(1.0-ALPHA)*sig
    e=EMIN+(EMAX*perf-EMIN)*elast(phase)
    plv=e*(v-V0)
    qmv=(pv-plv)/RMV if pv>plv else 0.0
    qav=(plv-pa)/RAV if plv>pa else 0.0
    qsys=(pa-pv)/r
    return np.array([qmv-qav,(qav-qsys)/CA,(qsys-qmv)/CV,(pa-pm)/TAU])

@njit
def step(y,t,r):
    phase=t%T
    k1=rhs(y,phase,r)
    k2=rhs(y+0.5*DT*k1,(t+0.5*DT)%T,r)
    k3=rhs(y+0.5*DT*k2,(t+0.5*DT)%T,r)
    k4=rhs(y+DT*k3,(t+DT)%T,r)
    return y+(DT/6.0)*(k1+2*k2+2*k3+k4)

@njit
def integrate_checkpoints(y0,r,seconds):
    n=int(round(seconds/DT)); cyc=int(round(T/DT))
    ring=np.zeros((4,2*cyc+1))
    snaps=np.zeros((len(CHECKPOINTS),4,2*cyc+1))
    cpidx=0
    y=y0.copy()
    for k in range(n):
        y=step(y,k*DT,r)
        j=(k+1)%(2*cyc+1)
        ring[:,j]=y
        elapsed=k+1
        if cpidx<len(CHECKPOINTS) and elapsed==int(round(CHECKPOINTS[cpidx]/DT)):
            # Reorder ring chronologically, oldest -> newest; exactly 1601 samples.
            start=(j+1)%(2*cyc+1)
            for q in range(4):
                for m in range(2*cyc+1):
                    snaps[cpidx,q,m]=ring[q,(start+m)%(2*cyc+1)]
            cpidx+=1
        if not np.all(np.isfinite(y)):
            return snaps,y,False
    return snaps,y,True

@njit
def integrate_short(y0,r,seconds):
    n=int(round(seconds/DT)); y=y0.copy()
    for k in range(n):
        y=step(y,k*DT,r)
        if not np.all(np.isfinite(y)): return y,False
    return y,True

def initial_state():
    v=120.0; pa=135.0
    pv=(VTOT-v-CA*pa)/CV
    return np.array([v,pa,pv,pa],dtype=np.float64)

def cycle_metrics(snap):
    # Two phase-aligned 801-sample cycles, indices 0..800 and 800..1600.
    d=float(np.max(np.abs(snap[:,800:1601]-snap[:,0:801])))
    mean=float(np.trapezoid(snap[1,800:1601],dx=DT)/T)
    return d,mean

def continuation_seeds(direction):
    grid=np.round(np.arange(0.80,2.0001,0.10),2)
    if direction=="reverse": grid=grid[::-1]
    y=initial_state(); seeds={}
    for r in grid:
        y,ok=integrate_short(y,float(r),120.0)
        if not ok: raise RuntimeError(f"nonfinite during {direction} continuation at Rsys={r}")
        if any(abs(float(r)-t)<1e-8 for t in TARGETS): seeds[float(r)]=y.copy()
    return seeds

def main():
    t0=time.time()
    fseeds=continuation_seeds("forward")
    rseeds=continuation_seeds("reverse")
    rows=[]; snapshots={}
    for r in TARGETS:
        for direction,seeds in (("forward",fseeds),("reverse",rseeds)):
            sn,final,ok=integrate_checkpoints(seeds[r],r,2000.0)
            if not ok: raise RuntimeError(f"nonfinite integration {direction} Rsys={r}")
            for i,sec in enumerate(CHECKPOINTS):
                d,m=cycle_metrics(sn[i])
                rows.append({"Rsys":r,"initialization":direction,"elapsed_s":sec,
                             "MAP_mmHg":m,"Cycle_Diff_all_4_states":d,
                             "tau_v_s":r*CV,"elapsed_over_tau_v":sec/(r*CV)})
                if sec in (1500,2000):
                    snapshots[(r,direction,sec)]=sn[i].copy()
            print(f"COMPLETE Rsys={r:.2f} init={direction} CycleDiff_2000={rows[-1]['Cycle_Diff_all_4_states']:.12g}",flush=True)
    sep_rows=[]
    for r in TARGETS:
        for sec in (1500,2000):
            a=snapshots[(r,"forward",sec)][1,800:1601]
            b=snapshots[(r,"reverse",sec)][1,800:1601]
            sep_rows.append({"Rsys":r,"elapsed_s":sec,
                             "Max_Traj_Sep_Pa_mmHg":float(np.max(np.abs(a-b))),
                             "RMS_Traj_Sep_Pa_mmHg":float(np.sqrt(np.mean((a-b)**2)))})
    with (OUT/"cycle_drift_checkpoints.csv").open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    with (OUT/"forward_reverse_separation_1500_2000s.csv").open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=list(sep_rows[0].keys())); w.writeheader(); w.writerows(sep_rows)
    # Fit log-linear decay only when all observed cycle differences are positive.
    fits={}
    for r in TARGETS:
        for direction in ("forward","reverse"):
            subset=[x for x in rows if x["Rsys"]==r and x["initialization"]==direction]
            ts=np.array([x["elapsed_s"] for x in subset],dtype=float)
            ds=np.array([x["Cycle_Diff_all_4_states"] for x in subset],dtype=float)
            slope,intercept=np.polyfit(ts,np.log(np.maximum(ds,1e-300)),1)
            fits[f"{r:.2f}_{direction}"]={"log_slope_per_s":float(slope),
                "apparent_decay_tau_s":float(-1.0/slope) if slope<0 else None,
                "log_linear_R2":float(1.0-np.sum((np.log(ds)-(slope*ts+intercept))**2)/np.sum((np.log(ds)-np.mean(np.log(ds)))**2))}
    summary={"parameters":{"V_total_mL":VTOT,"k_sig_mmHg":KSIG,"tau_p_s":TAU,"P_crit_mmHg":PCRIT,
              "beta_R":BETA,"alpha":ALPHA,"dt_s":DT},
             "method":"Forward/reverse continuation over Rsys 0.80..2.00 in 0.10 steps, 120 s per step; each target then integrated for 2000 s from its directional continuation state. Cycle_Diff is max absolute difference across all four states between phase-aligned cycles [0..800] and [800..1600] at each checkpoint.",
             "cycle_decay_log_fits":fits,"branch_separation":sep_rows,
             "elapsed_wall_s":time.time()-t0}
    (OUT/"diagnostic_summary.json").write_text(json.dumps(summary,indent=2))
    print("SUMMARY",json.dumps(summary,indent=2),flush=True)
    print("CYCLE_CHECKPOINTS_CSV")
    with (OUT/"cycle_drift_checkpoints.csv").open() as f: print(f.read())
    print("BRANCH_SEPARATION_CSV")
    with (OUT/"forward_reverse_separation_1500_2000s.csv").open() as f: print(f.read())

if __name__=="__main__": main()
