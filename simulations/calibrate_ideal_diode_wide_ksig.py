import csv
import itertools
import json
import math
import time
from pathlib import Path
import numpy as np
from numba import njit

OUT = Path("calibration_results")
OUT.mkdir(exist_ok=True)
DT=0.001
T=0.80
T_SYS=0.3*T
EMAX=2.0
EMIN=0.06
V0=10.0
CA=1.5
CV=100.0
RAV=0.01
RMV=0.008
TARGET_R=(1.30,1.40,1.50)
DWELL_S=20.0
PERIODICITY_LIMIT=1.0e-8
K_SIG_VALUES=(3.0,3.5,4.0,4.5,5.0)
V_TOTAL_VALUES=(1000.0,1025.0,1050.0)
ALPHA_VALUES=(0.65,0.685,0.72)
P_CRIT_VALUES=(30.0,40.0,50.0)
BETA_R_VALUES=(45.0,55.0,65.0)

@njit
def sigmoid(z):
    if z>50.0: return 1.0
    if z < -50.0: return 0.0
    return 1.0/(1.0+math.exp(-z))

@njit
def shape(tmod):
    if tmod<=T_SYS:
        return 0.5*(1.0-math.cos(math.pi*tmod/T_SYS))
    return 0.0

@njit
def rhs(v,pa,pv,phase,rsys,pcrit,ksig,alpha,beta):
    perf=alpha+(1.0-alpha)*sigmoid((pa-beta*rsys-pcrit)/ksig)
    elastance=EMIN+(EMAX*perf-EMIN)*shape(phase)
    plv=elastance*(v-V0)
    dp_mv=pv-plv
    qmv=dp_mv/RMV if dp_mv>0.0 else 0.0
    dp_av=plv-pa
    qav=dp_av/RAV if dp_av>0.0 else 0.0
    qsys=(pa-pv)/rsys
    return qmv-qav,(qav-qsys)/CA,(qsys-qmv)/CV

@njit
def advance(v,pa,pv,rsys,seconds,pcrit,ksig,alpha,beta):
    n=int(round(seconds/DT))
    for i in range(n):
        t0=(i*DT)%T
        th=((i+0.5)*DT)%T
        t1=((i+1)*DT)%T
        k1v,k1a,k1p=rhs(v,pa,pv,t0,rsys,pcrit,ksig,alpha,beta)
        k2v,k2a,k2p=rhs(v+0.5*DT*k1v,pa+0.5*DT*k1a,pv+0.5*DT*k1p,th,rsys,pcrit,ksig,alpha,beta)
        k3v,k3a,k3p=rhs(v+0.5*DT*k2v,pa+0.5*DT*k2a,pv+0.5*DT*k2p,th,rsys,pcrit,ksig,alpha,beta)
        k4v,k4a,k4p=rhs(v+DT*k3v,pa+DT*k3a,pv+DT*k3p,t1,rsys,pcrit,ksig,alpha,beta)
        v+=(DT/6.0)*(k1v+2*k2v+2*k3v+k4v)
        pa+=(DT/6.0)*(k1a+2*k2a+2*k3a+k4a)
        pv+=(DT/6.0)*(k1p+2*k2p+2*k3p+k4p)
    return v,pa,pv

@njit
def run_checkpoints(v,pa,pv,rsys,pcrit,ksig,alpha,beta):
    c300=np.empty((3,1601),dtype=np.float64)
    c600=np.empty((3,1601),dtype=np.float64)
    n=int(round(600.0/DT))
    for i in range(n):
        t0=(i*DT)%T
        th=((i+0.5)*DT)%T
        t1=((i+1)*DT)%T
        k1v,k1a,k1p=rhs(v,pa,pv,t0,rsys,pcrit,ksig,alpha,beta)
        k2v,k2a,k2p=rhs(v+0.5*DT*k1v,pa+0.5*DT*k1a,pv+0.5*DT*k1p,th,rsys,pcrit,ksig,alpha,beta)
        k3v,k3a,k3p=rhs(v+0.5*DT*k2v,pa+0.5*DT*k2a,pv+0.5*DT*k2p,th,rsys,pcrit,ksig,alpha,beta)
        k4v,k4a,k4p=rhs(v+DT*k3v,pa+DT*k3a,pv+DT*k3p,t1,rsys,pcrit,ksig,alpha,beta)
        v+=(DT/6.0)*(k1v+2*k2v+2*k3v+k4v)
        pa+=(DT/6.0)*(k1a+2*k2a+2*k3a+k4a)
        pv+=(DT/6.0)*(k1p+2*k2p+2*k3p+k4p)
        step=i+1
        if 298400<=step<=300000:
            j=step-298400
            c300[0,j],c300[1,j],c300[2,j]=v,pa,pv
        if 598400<=step<=600000:
            j=step-598400
            c600[0,j],c600[1,j],c600[2,j]=v,pa,pv
    return c300,c600,v,pa,pv

def cycle_metrics(pair):
    first=pair[:,:801]
    second=pair[:,800:1601]
    diff=float(np.max(np.abs(second-first)))
    mapv=float(np.trapezoid(second[1],dx=DT)/T)
    return diff,mapv,second[1].copy()

def initial_state(vtotal):
    v=120.0
    pa=135.0
    pv=(vtotal-v-CA*pa)/CV
    return v,pa,pv

def branch_seeds(params):
    pcrit,ksig,alpha,beta,vtotal=params
    v,pa,pv=initial_state(vtotal)
    fwd={}
    for r in TARGET_R:
        v,pa,pv=advance(v,pa,pv,r,DWELL_S,pcrit,ksig,alpha,beta)
        fwd[r]=(v,pa,pv)
    v,pa,pv=fwd[1.50]
    rev={}
    for r in (1.50,1.40,1.30):
        v,pa,pv=advance(v,pa,pv,r,DWELL_S,pcrit,ksig,alpha,beta)
        rev[r]=(v,pa,pv)
    return fwd,rev

def evaluate_branch(seed,rsys,params):
    pcrit,ksig,alpha,beta,_=params
    c300,c600,*_=run_checkpoints(*seed,rsys,pcrit,ksig,alpha,beta)
    d300,m300,_=cycle_metrics(c300)
    d600,m600,pa600=cycle_metrics(c600)
    return {"d300":d300,"d600":d600,"m300":m300,"m600":m600,"pa600":pa600}

def main():
    t0=time.time()
    grid=list(itertools.product(K_SIG_VALUES,V_TOTAL_VALUES,ALPHA_VALUES,P_CRIT_VALUES,BETA_R_VALUES))
    rows=[]
    winner=None
    checked=0
    for ksig,vtotal,alpha,pcrit,beta in grid:
        checked+=1
        params=(pcrit,ksig,alpha,beta,vtotal)
        seed=initial_state(vtotal)
        c300,c600,*_=run_checkpoints(*seed,1.40,pcrit,ksig,alpha,beta)
        d300,m300,_=cycle_metrics(c300)
        d600,m600,_=cycle_metrics(c600)
        screen=(d300<PERIODICITY_LIMIT and d600<PERIODICITY_LIMIT
                and 90.0<=m300<=110.0 and 90.0<=m600<=110.0)
        row={"k_sig_mmHg":ksig,"V_total_mL":vtotal,"alpha":alpha,
             "P_crit_mmHg":pcrit,"beta_R":beta,
             "screen_cycle_diff_300":d300,"screen_cycle_diff_600":d600,
             "screen_MAP_300":m300,"screen_MAP_600":m600,
             "screen_pass":screen,"full_gate_pass":False,
             "max_traj_sep_1_30_mmHg":"","max_traj_sep_1_40_mmHg":"",
             "max_traj_sep_1_50_mmHg":"","failure_reason":""}
        if screen:
            fwd,rev=branch_seeds(params)
            all_periodic=True
            all_maps=True
            all_separated=True
            seps={}
            details=[]
            for r in TARGET_R:
                fa=evaluate_branch(fwd[r],r,params)
                rb=evaluate_branch(rev[r],r,params)
                periodic=(fa["d300"]<PERIODICITY_LIMIT and fa["d600"]<PERIODICITY_LIMIT
                          and rb["d300"]<PERIODICITY_LIMIT and rb["d600"]<PERIODICITY_LIMIT)
                maps=all(90.0<=x<=110.0 for x in (fa["m300"],fa["m600"],rb["m300"],rb["m600"]))
                sep=float(np.max(np.abs(fa["pa600"]-rb["pa600"])))
                separated=sep>5.0
                all_periodic &= periodic
                all_maps &= maps
                all_separated &= separated
                seps[r]=sep
                details.append({"Rsys":r,
                    "forward":{"Cycle_Diff_300":fa["d300"],"Cycle_Diff_600":fa["d600"],"MAP_300":fa["m300"],"MAP_600":fa["m600"]},
                    "reverse":{"Cycle_Diff_300":rb["d300"],"Cycle_Diff_600":rb["d600"],"MAP_300":rb["m300"],"MAP_600":rb["m600"]},
                    "Max_Traj_Sep_mmHg":sep,"periodicity_pass":periodic,"MAP_pass":maps,"separation_pass":separated})
            full=all_periodic and all_maps and all_separated
            row["full_gate_pass"]=full
            row["max_traj_sep_1_30_mmHg"]=seps[1.30]
            row["max_traj_sep_1_40_mmHg"]=seps[1.40]
            row["max_traj_sep_1_50_mmHg"]=seps[1.50]
            row["failure_reason"]="" if full else ("branch_periodicity" if not all_periodic else "MAP_out_of_range" if not all_maps else "branch_separation")
            row["branch_details"]=details
            if full and winner is None:
                winner=row.copy()
        else:
            reasons=[]
            if d300>=PERIODICITY_LIMIT or d600>=PERIODICITY_LIMIT: reasons.append("screen_periodicity")
            if not (90.0<=m300<=110.0 and 90.0<=m600<=110.0): reasons.append("screen_MAP")
            row["failure_reason"]=";".join(reasons)
        rows.append(row)
        if winner is not None: break
        if checked%25==0: print(f"Checked {checked}/{len(grid)} sets; elapsed={time.time()-t0:.1f}s")

    fields=["k_sig_mmHg","V_total_mL","alpha","P_crit_mmHg","beta_R",
            "screen_cycle_diff_300","screen_cycle_diff_600","screen_MAP_300","screen_MAP_600",
            "screen_pass","full_gate_pass","max_traj_sep_1_30_mmHg",
            "max_traj_sep_1_40_mmHg","max_traj_sep_1_50_mmHg","failure_reason"]
    with (OUT/"ideal_diode_wide_ksig_calibration.csv").open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=fields); w.writeheader()
        for row in rows: w.writerow({k:row.get(k,"") for k in fields})

    summary={"model":"original 3-state ideal-diode model [V_LV, Pa, Pv]",
        "valves":"strict one-way pressure-gradient diode; no tanh; no P_mean",
        "dt_s":DT,"period_s":T,
        "parameter_grid":{"k_sig_mmHg":list(K_SIG_VALUES),"V_total_mL":list(V_TOTAL_VALUES),
            "alpha":list(ALPHA_VALUES),"P_crit_mmHg":list(P_CRIT_VALUES),
            "beta_R":list(BETA_R_VALUES),"total_combinations":len(grid)},
        "tested_parameter_sets":checked,"candidate_found":winner is not None,
        "candidate":winner,"periodicity_threshold":PERIODICITY_LIMIT,
        "coexistence_Rsys":list(TARGET_R),"MAP_range_mmHg":[90.0,110.0],
        "trajectory_separation_threshold_mmHg":5.0,
        "elapsed_seconds":time.time()-t0,
        "interpretation":("All numerical gates passed for the first qualifying set; this is persistent periodic branch-coexistence evidence under the specified protocol, not a formal Floquet/fold proof."
          if winner else "No tested set passed all gates. Do not change production model files or merge based on this calibration.")}
    (OUT/"summary.json").write_text(json.dumps(summary,indent=2))
    with (OUT/"calibration_execution_transcript.log").open("w") as f:
        f.write("ORIGINAL 3-STATE IDEAL-DIODE CALIBRATION\nNo P_mean; no tanh valve smoothing.\n")
        f.write(f"dt={DT:.6f}; Cycle_Diff threshold={PERIODICITY_LIMIT:.1e}\n")
        f.write(f"Tested {checked}/{len(grid)} parameter sets.\nCandidate found: {winner is not None}\n")
        if winner: f.write(json.dumps(winner,indent=2)+"\n")
        else: f.write("No parameter set passed periodicity, MAP, and branch-separation gates.\n")
        f.write(f"Elapsed seconds: {time.time()-t0:.3f}\n")
    print(json.dumps(summary,indent=2))

if __name__=="__main__":
    main()
