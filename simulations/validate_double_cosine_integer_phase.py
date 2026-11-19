import csv, itertools, json, math, time
from pathlib import Path
import numpy as np
from numba import njit

OUT=Path("double_cosine_results"); OUT.mkdir(exist_ok=True)
DT=0.001; T=0.80; C_STEPS=800; SYS_STEPS=240
EMAX=2.0; EMIN=0.06; V0=10.0; CA=1.5; CV=100.0
RAV=0.01; RMV=0.008; PERIODICITY=1e-8
TARGETS=(1.24,1.32,1.40)
# Retest the beta_R=40 candidate with independent reverse continuation.
ALPHAS=(0.50,)
K_SIGS=(2.0,)
V_TOTALS=(1000.0,)
P_CRITS=(50.0,)
BETAS=(40.0,)

@njit
def elastance_shape(step_phase):
    # step_phase is measured in integer-step units; half steps are represented by .5.
    if step_phase <= SYS_STEPS:
        return 0.5*(1.0-math.cos(2.0*math.pi*step_phase/SYS_STEPS))
    return 0.0

@njit
def sigmoid(z):
    if z>50.0: return 1.0
    if z < -50.0: return 0.0
    return 1.0/(1.0+math.exp(-z))

@njit
def rhs(v,pa,pv,phase_step,rsys,pcrit,beta,ksig,alpha):
    perf=alpha+(1.0-alpha)*sigmoid((pa-beta*rsys-pcrit)/ksig)
    elast=EMIN+(EMAX*perf-EMIN)*elastance_shape(phase_step)
    plv=elast*(v-V0)
    # Strict original ideal-diode valves.
    qmv=(pv-plv)/RMV if pv>plv else 0.0
    qav=(plv-pa)/RAV if plv>pa else 0.0
    qsys=(pa-pv)/rsys
    return qmv-qav,(qav-qsys)/CA,(qsys-qmv)/CV

@njit
def step_rk4(v,pa,pv,k,rsys,pcrit,beta,ksig,alpha):
    base=float(k % C_STEPS)
    p0=base
    ph=base+0.5
    p1=(base+1.0) % C_STEPS
    k1=rhs(v,pa,pv,p0,rsys,pcrit,beta,ksig,alpha)
    k2=rhs(v+0.5*DT*k1[0],pa+0.5*DT*k1[1],pv+0.5*DT*k1[2],ph,rsys,pcrit,beta,ksig,alpha)
    k3=rhs(v+0.5*DT*k2[0],pa+0.5*DT*k2[1],pv+0.5*DT*k2[2],ph,rsys,pcrit,beta,ksig,alpha)
    k4=rhs(v+DT*k3[0],pa+DT*k3[1],pv+DT*k3[2],p1,rsys,pcrit,beta,ksig,alpha)
    v += DT*(k1[0]+2*k2[0]+2*k3[0]+k4[0])/6.0
    pa += DT*(k1[1]+2*k2[1]+2*k3[1]+k4[1])/6.0
    pv += DT*(k1[2]+2*k2[2]+2*k3[2]+k4[2])/6.0
    return v,pa,pv

@njit
def integrate_capture(seed,rsys,pcrit,beta,ksig,alpha,total_steps):
    v,pa,pv=seed
    a300=np.empty((3,1601)); a600=np.empty((3,1601))
    for k in range(total_steps):
        v,pa,pv=step_rk4(v,pa,pv,k,rsys,pcrit,beta,ksig,alpha)
        n=k+1
        if 298400<=n<=300000:
            j=n-298400; a300[0,j]=v; a300[1,j]=pa; a300[2,j]=pv
        if 598400<=n<=600000:
            j=n-598400; a600[0,j]=v; a600[1,j]=pa; a600[2,j]=pv
    return a300,a600,(v,pa,pv)

@njit
def integrate_short(seed,rsys,pcrit,beta,ksig,alpha,steps):
    v,pa,pv=seed
    for k in range(steps):
        v,pa,pv=step_rk4(v,pa,pv,k,rsys,pcrit,beta,ksig,alpha)
    return v,pa,pv

def metrics(arr):
    prev=arr[:,:801]; last=arr[:,800:1601]
    d=float(np.max(np.abs(last-prev)))
    mapv=float(np.trapezoid(last[1],dx=DT)/T)
    return d,mapv,last

def initial(vtotal):
    v,pa=120.0,135.0
    pv=(vtotal-v-CA*pa)/CV
    return (v,pa,pv)

def sweep_branch(vtotal,pcrit,beta,ksig,alpha):
    # 20-s continuation over Rsys=0.80..2.00 in 0.02 steps.
    rs=np.round(np.arange(0.80,2.0001,0.02),2)
    targets={1.24,1.32,1.40}
    forward={}; reverse={}
    state=initial(vtotal)
    for r in rs:
        state=integrate_short(state,float(r),pcrit,beta,ksig,alpha,20000)
        if float(r) in targets: forward[float(r)]=state
    # Independent reverse continuation: initialize at the high-Rsys endpoint,
    # rather than reusing the final state of the forward sweep.
    state=initial(vtotal)
    state=integrate_short(state,2.00,pcrit,beta,ksig,alpha,20000)
    for r in rs[::-1]:
        state=integrate_short(state,float(r),pcrit,beta,ksig,alpha,20000)
        if float(r) in targets: reverse[float(r)]=state
    return forward,reverse

def evaluate(params):
    alpha,ksig,vtotal,pcrit,beta=params
    seed=initial(vtotal)
    # Primary baseline trajectory at Rsys=1.40.
    a300,a600,_=integrate_capture(seed,1.40,pcrit,beta,ksig,alpha,600000)
    d300,m300,_=metrics(a300); d600,m600,_=metrics(a600)
    result={"alpha":alpha,"k_sig_mmHg":ksig,"V_total_mL":vtotal,
            "P_crit_mmHg":pcrit,"beta_R":beta,
            "baseline_Cycle_Diff_300":d300,"baseline_Cycle_Diff_600":d600,
            "baseline_MAP_300":m300,"baseline_MAP_600":m600,
            "baseline_periodic":d300<PERIODICITY and d600<PERIODICITY,
            "baseline_MAP_pass":90.0<=m300<=105.0 and 90.0<=m600<=105.0,
            "full_gate_pass":False,"branch_results":[]}
    if not result["baseline_periodic"] or not result["baseline_MAP_pass"]:
        result["failure_reason"]="baseline_periodicity" if not result["baseline_periodic"] else "baseline_MAP"
        return result
    fwd,rev=sweep_branch(vtotal,pcrit,beta,ksig,alpha)
    all_ok=True
    for r in TARGETS:
        af300,af600,_=integrate_capture(fwd[r],r,pcrit,beta,ksig,alpha,600000)
        ar300,ar600,_=integrate_capture(rev[r],r,pcrit,beta,ksig,alpha,600000)
        df300,mf300,lf300=metrics(af300); df600,mf600,lf600=metrics(af600)
        dr300,mr300,lr300=metrics(ar300); dr600,mr600,lr600=metrics(ar600)
        sep=float(np.max(np.abs(lf600[1]-lr600[1])))
        periodic=max(df300,df600,dr300,dr600)<PERIODICITY
        separated=sep>5.0
        branch={"Rsys":r,"forward_Cycle_Diff_300":df300,"forward_Cycle_Diff_600":df600,
                "reverse_Cycle_Diff_300":dr300,"reverse_Cycle_Diff_600":dr600,
                "forward_MAP_600":mf600,"reverse_MAP_600":mr600,
                "Max_Traj_Sep_mmHg":sep,"periodic_both_branches":periodic,
                "separation_pass":separated}
        result["branch_results"].append(branch)
        all_ok &= periodic and separated
    result["full_gate_pass"]=all_ok
    result["failure_reason"]="" if all_ok else "branch_periodicity_or_separation"
    return result

def main():
    t0=time.time()
    grid=list(itertools.product(ALPHAS,K_SIGS,V_TOTALS,P_CRITS,BETAS))
    rows=[]; winner=None
    for i,p in enumerate(grid,1):
        r=evaluate(p); rows.append(r)
        print(f"{i}/{len(grid)} {p} periodic={r['baseline_periodic']} MAP={r['baseline_MAP_600']:.6f} pass={r['full_gate_pass']}")
        if r["full_gate_pass"]:
            winner=r
            break
    flat_fields=["alpha","k_sig_mmHg","V_total_mL","P_crit_mmHg","beta_R",
      "baseline_Cycle_Diff_300","baseline_Cycle_Diff_600","baseline_MAP_300","baseline_MAP_600",
      "baseline_periodic","baseline_MAP_pass","full_gate_pass","failure_reason"]
    with (OUT/"double_cosine_parameter_scan.csv").open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=flat_fields); w.writeheader()
        for x in rows: w.writerow({k:x.get(k,"") for k in flat_fields})
    (OUT/"double_cosine_full_results.json").write_text(json.dumps(rows,indent=2))
    summary={"waveform":"0.5*(1-cos(2*pi*phase/T_sys)) on [0,T_sys], zero outside",
      "phase_indexing":"integer step modulo c_steps; half-step RK4 phases use integer+0.5",
      "model":"original 3-state [V_LV,Pa,Pv], strict ideal-diode valves, no P_mean",
      "dt_s":DT,"T_s":T,"T_sys_s":0.24,"periodicity_threshold":PERIODICITY,
      "baseline_MAP_range_mmHg":[90.0,105.0],"coexistence_Rsys":list(TARGETS),
      "Max_Traj_Sep_threshold_mmHg":5.0,
      "grid":{"alpha":list(ALPHAS),"k_sig_mmHg":list(K_SIGS),
              "V_total_mL":list(V_TOTALS),"P_crit_mmHg":list(P_CRITS),
              "beta_R":list(BETAS),"combinations":len(grid)},
      "tested":len(rows),"candidate_found":winner is not None,"candidate":winner,
      "elapsed_seconds":time.time()-t0}
    (OUT/"summary.json").write_text(json.dumps(summary,indent=2))
    with (OUT/"double_cosine_validation.log").open("w") as f:
        f.write("DOUBLE-COSINE ELASTANCE + INTEGER PHASE VALIDATION\n")
        f.write("Original 3-state ideal-diode model; no tanh; no P_mean. Single-candidate retest with independent forward/reverse continuation.\n")
        f.write(f"Tested {len(rows)} / {len(grid)} parameter combinations.\n")
        f.write(f"Candidate found: {winner is not None}\n")
        if winner: f.write(json.dumps(winner,indent=2)+"\n")
        else: f.write("No tested set passed baseline periodicity/MAP and branch coexistence gates.\n")
        f.write(f"Elapsed seconds: {time.time()-t0:.3f}\n")
    print(json.dumps(summary,indent=2))
if __name__=="__main__": main()
