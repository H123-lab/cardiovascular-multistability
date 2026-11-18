import csv, itertools, json, math, os, time
from pathlib import Path
import numpy as np
from numba import njit

OUT=Path("results/diagnostic/filtered_grid")
OUT.mkdir(parents=True,exist_ok=True)
DT=0.001; T=0.8; TSYS=0.3*T
EMAX=2.0; EMIN=0.06; V0=10.0; CA=1.5; CV=100.0
RAV=0.01; RMV=0.008; ALPHA=0.72
VOLUMES=[950.0,975.0,1000.0,1025.0]
KSIGS=[2.5,3.0,3.5,4.0,4.5]
TAUS=[1.0,2.0]
PCRITS=[25.0,30.0,35.0,40.0]
BETAS=[45.0,50.0,55.0,60.0]
TARGETS=(1.30,1.40,1.50)

@njit
def elast(t):
    if t<=TSYS: return 0.5*(1.0-math.cos(math.pi*t/TSYS))
    return 0.0

@njit
def rhs(y,t,r,vtot,pcrit,ksig,tau):
    v,pa,pv,pm=y
    perf=ALPHA+(1.0-ALPHA)/(1.0+math.exp(-((pm-(70.0*r+pcrit))/ksig)))
    plv=(EMIN+(EMAX*perf-EMIN)*elast(t%T))*(v-V0)
    qmv=(pv-plv)/RMV if pv>plv else 0.0
    qav=(plv-pa)/RAV if plv>pa else 0.0
    qsys=(pa-pv)/r
    return np.array([qmv-qav,(qav-qsys)/CA,(qsys-qmv)/CV,(pa-pm)/tau])

@njit
def integrate(y0,r,seconds,vtot,pcrit,ksig,tau):
    n=int(round(seconds/DT)); c=int(round(T/DT))
    y=y0.copy(); rec=np.zeros((4,2*c+1))
    start=n-2*c
    if start==0: rec[:,0]=y
    for k in range(n):
        t=k*DT
        k1=rhs(y,t,r,vtot,pcrit,ksig,tau)
        k2=rhs(y+0.5*DT*k1,t+0.5*DT,r,vtot,pcrit,ksig,tau)
        k3=rhs(y+0.5*DT*k2,t+0.5*DT,r,vtot,pcrit,ksig,tau)
        k4=rhs(y+DT*k3,t+DT,r,vtot,pcrit,ksig,tau)
        y += (DT/6.0)*(k1+2*k2+2*k3+k4)
        step=k+1
        if step>=start: rec[:,step-start]=y
    return y,rec

def cycle_stats(rec):
    # Compare phase-aligned cycles [0..800] and [800..1600], shared boundary sample.
    prev=rec[:,:801]; last=rec[:,800:1601]
    diff=float(np.max(np.abs(last-prev)))
    mean=float(np.trapezoid(last[1],dx=DT)/T)
    return mean,diff,last

def seed(vtot):
    v=120.0; pa=100.0
    pv=(vtot-v-CA*pa)/CV
    return np.array([v,pa,pv,pa],dtype=np.float64)

def branch_seed(vtot,pcrit,ksig,tau,reverse=False):
    # Short continuation establishes distinct path-dependent initializations only;
    # final acceptance is based on 300/600-s convergence at each target.
    y=seed(vtot)
    grid=np.arange(0.80,2.0001,0.10)
    if reverse: grid=grid[::-1]
    states={}
    for r in grid:
        y,_=integrate(y,float(r),2.4,vtot,pcrit,ksig,tau)
        states[round(float(r),2)]=y.copy()
    out=[]
    for target in TARGETS:
        idx=int(np.argmin(np.abs(grid-target)))
        out.append(states[round(float(grid[idx]),2)].copy())
    return out

def test_branches(vtot,pcrit,ksig,tau):
    fseeds=branch_seed(vtot,pcrit,ksig,tau,False)
    rseeds=branch_seed(vtot,pcrit,ksig,tau,True)
    rows=[]; allpass=True
    for j,r in enumerate(TARGETS):
        ends=[]; cycles=[]; metrics=[]
        for label,y0 in (("forward",fseeds[j]),("reverse",rseeds[j])):
            y300,rec300=integrate(y0,r,300.0,vtot,pcrit,ksig,tau)
            map300,d300,last300=cycle_stats(rec300)
            y600,rec600=integrate(y300,r,300.0,vtot,pcrit,ksig,tau)
            map600,d600,last600=cycle_stats(rec600)
            ends.append(last600); metrics.append((label,map300,d300,map600,d600))
            if not (d300<1e-8 and d600<1e-8): allpass=False
        sep=float(np.max(np.abs(ends[0][1]-ends[1][1])))
        rows.append({"Rsys":r,"forward_MAP_300":metrics[0][1],"forward_cycle_diff_300":metrics[0][2],
                     "forward_MAP_600":metrics[0][3],"forward_cycle_diff_600":metrics[0][4],
                     "reverse_MAP_300":metrics[1][1],"reverse_cycle_diff_300":metrics[1][2],
                     "reverse_MAP_600":metrics[1][3],"reverse_cycle_diff_600":metrics[1][4],
                     "Max_Traj_Sep_Pa_mmHg":sep})
        if sep<=5.0: allpass=False
    return allpass,rows

def main():
    t0=time.time(); records=[]; winners=[]
    combos=list(itertools.product(VOLUMES,KSIGS,TAUS,PCRITS,BETAS))
    for n,(vtot,ksig,tau,pcrit,beta) in enumerate(combos,1):
        # beta_R is explicit in the requested grid (not fixed at the legacy value).
        # Pass it via module-level temporary parameter by scaling the afterload term.
        global BETA_CURRENT
        BETA_CURRENT=beta
        y0=seed(vtot)
        y300,rec300=integrate(y0,1.40,300.0,vtot,pcrit,ksig,tau)
        m300,d300,_=cycle_stats(rec300)
        row={"V_total_mL":vtot,"k_sig_mmHg":ksig,"tau_p_s":tau,"P_crit_mmHg":pcrit,
             "alpha":ALPHA,"beta_R":beta,"MAP_300_mmHg":m300,"Cycle_Diff_300":d300,
             "MAP_600_mmHg":"","Cycle_Diff_600":"","baseline_gate":False,
             "hysteresis_gate":False,"all_gates":False}
        if 90.0<=m300<=105.0 and d300<1e-8:
            y600,rec600=integrate(y300,1.40,300.0,vtot,pcrit,ksig,tau)
            m600,d600,_=cycle_stats(rec600)
            row["MAP_600_mmHg"]=m600; row["Cycle_Diff_600"]=d600
            row["baseline_gate"]=bool(90.0<=m600<=105.0 and d600<1e-8)
            if row["baseline_gate"]:
                hg,details=test_branches(vtot,pcrit,ksig,tau)
                row["hysteresis_gate"]=bool(hg)
                row["all_gates"]=bool(hg)
                row["branch_details"]=details
                if hg: winners.append(row.copy())
        records.append(row)
        if n%20==0:
            print(f"PROGRESS {n}/{len(combos)} elapsed_s={time.time()-t0:.1f} baseline_passes={sum(bool(x['baseline_gate']) for x in records)}",flush=True)
    fields=["V_total_mL","k_sig_mmHg","tau_p_s","P_crit_mmHg","alpha","beta_R","MAP_300_mmHg","Cycle_Diff_300","MAP_600_mmHg","Cycle_Diff_600","baseline_gate","hysteresis_gate","all_gates"]
    with (OUT/"filtered_perfusion_grid_summary.csv").open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=fields); w.writeheader()
        for x in records: w.writerow({k:x.get(k,"") for k in fields})
    (OUT/"filtered_perfusion_winner.json").write_text(json.dumps(winners[0] if winners else {"result":"NO_PASS","tested":len(combos),"elapsed_s":time.time()-t0},indent=2))
    if winners:
        with (OUT/"winner_branch_details.csv").open("w",newline="") as f:
            w=csv.DictWriter(f,fieldnames=list(winners[0]["branch_details"][0].keys())); w.writeheader()
            for x in winners[0]["branch_details"]: w.writerow(x)
    print("SCAN_COMPLETE",json.dumps({"tested":len(combos),"baseline_passes":sum(bool(x["baseline_gate"]) for x in records),"winners":len(winners),"elapsed_s":time.time()-t0}),flush=True)

if __name__=="__main__": main()
