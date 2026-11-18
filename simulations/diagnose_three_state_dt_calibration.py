import os, csv, json, math
from pathlib import Path
import numpy as np
from numba import njit

OUT=Path("results/diagnostics/three_state")
OUT.mkdir(parents=True, exist_ok=True)
T=0.8; TSYS=0.3*T
EMAX=2.0; EMIN=0.06; V0=10.0
CA=1.5; CV=100.0; RAV=0.01; RMV=0.008
ALPHA=0.72
DT_LIST=(0.001,0.0005,0.00025)
TARGET_R=(1.30,1.40,1.50)

@njit
def elast(t):
    if t <= TSYS: return 0.5*(1.0-math.cos(math.pi*t/TSYS))
    return 0.0

@njit
def deriv(v,pa,pv,t,R,pc,br,ks):
    perf=ALPHA+(1.0-ALPHA)/(1.0+math.exp(-(pa-(br*R+pc))/ks))
    plv=(EMIN+(EMAX*perf-EMIN)*elast(t))*(v-V0)
    qmv=(pv-plv)/RMV if pv>plv else 0.0
    qav=(plv-pa)/RAV if plv>pa else 0.0
    qsys=(pa-pv)/R
    return qmv-qav,(qav-qsys)/CA,(qsys-qmv)/CV

@njit
def run(v,pa,pv,R,dt,seconds,pc,br,ks, keep=False):
    n=int(round(seconds/dt)); c=int(round(T/dt))
    ring=np.zeros((3,2*c+1)); idx=0
    for k in range(n):
        t0=(k*dt)%T; th=((k+0.5)*dt)%T; t1=((k+1)*dt)%T
        a1,b1,c1=deriv(v,pa,pv,t0,R,pc,br,ks)
        a2,b2,c2=deriv(v+.5*dt*a1,pa+.5*dt*b1,pv+.5*dt*c1,th,R,pc,br,ks)
        a3,b3,c3=deriv(v+.5*dt*a2,pa+.5*dt*b2,pv+.5*dt*c2,th,R,pc,br,ks)
        a4,b4,c4=deriv(v+dt*a3,pa+dt*b3,pv+dt*c3,t1,R,pc,br,ks)
        v += dt*(a1+2*a2+2*a3+a4)/6
        pa += dt*(b1+2*b2+2*b3+b4)/6
        pv += dt*(c1+2*c2+2*c3+c4)/6
        ring[0,idx]=v; ring[1,idx]=pa; ring[2,idx]=pv
        idx=(idx+1)%(2*c+1)
    # chronological last two cycles + shared boundary sample
    start=idx
    arr=np.empty((3,2*c+1))
    for j in range(2*c+1):
        q=(start+j)%(2*c+1)
        for z in range(3): arr[z,j]=ring[z,q]
    cyc=arr[:,c:]; prev=arr[:,:c+1]
    dif=np.max(np.abs(cyc-prev))
    maps=np.sum(cyc[1,:]) * dt / T
    return v,pa,pv,dif,maps,cyc

@njit
def sweep(pc,br,ks,dt,seconds):
    rs=np.arange(1.10,1.701,0.05)
    f=np.zeros(len(rs)); rev=np.zeros(len(rs))
    v=120.; pa=100.; pv=(1000.-v-CA*pa)/CV
    for i in range(len(rs)):
        v,pa,pv,_,m,_=run(v,pa,pv,rs[i],dt,seconds,pc,br,ks)
        f[i]=m
    for i in range(len(rs)-1,-1,-1):
        v,pa,pv,_,m,_=run(v,pa,pv,rs[i],dt,seconds,pc,br,ks)
        rev[i]=m
    return rs,f,rev

def initial():
    v=120.; pa=100.; pv=(1000.-v-CA*pa)/CV
    return v,pa,pv

def main():
    # Coarse parameter calibration: 3-state model only, fixed total stressed volume.
    # A candidate must have normotensive mean MAP at all three requested Rsys points
    # and a nontrivial forward/reverse MAP split across the 1.30-1.50 interval.
    candidates=[]
    pcs=[10.,15.,20.,25.,30.,35.,40.,45.,50.]
    brs=[20.,25.,30.,35.,40.,45.,50.,55.,60.]
    for pc in pcs:
      for br in brs:
        rs,f,r=sweep(pc,br,1.2,0.001,20.0)
        ids=[int(np.argmin(np.abs(rs-x))) for x in TARGET_R]
        means=[0.5*(f[i]+r[i]) for i in ids]
        splits=[abs(f[i]-r[i]) for i in ids]
        # report broad screening; no pre-imposed claim that all points are bistable
        score=sum(max(0.,95.-m,m-102.) for m in means)+sum(max(0.,1.0-s) for s in splits)
        candidates.append((score,pc,br,means,splits,rs.tolist(),f.tolist(),r.tolist()))
    candidates.sort(key=lambda x:x[0])
    best=candidates[0]
    # Store full calibration ranking and sweep curves for the best coarse candidate.
    with (OUT/"calibration_ranking.csv").open("w",newline="") as f:
      w=csv.writer(f); w.writerow(["rank","score","P_crit","beta_R","MAP_mean_R130","MAP_mean_R140","MAP_mean_R150","split_R130","split_R140","split_R150"])
      for rank,x in enumerate(candidates,1):
        w.writerow([rank,x[0],x[1],x[2],*x[3],*x[4]])
    pc,br=best[1],best[2]
    with (OUT/"best_candidate_sweep.csv").open("w",newline="") as f:
      w=csv.writer(f); w.writerow(["Rsys","MAP_forward","MAP_reverse","abs_MAP_split"])
      for i,rval in enumerate(best[5]): w.writerow([rval,best[6][i],best[7][i],abs(best[6][i]-best[7][i])])
    # Time-step convergence and 100-s component-resolved drift. Start from identical
    # physiological state and use identical phase (t=0) for every dt.
    rows=[]
    for dt in DT_LIST:
      v,pa,pv=initial()
      for sec in range(100,1001,100):
        # integrate from current state in 100-s blocks; cycle diff from final two cycles
        v,pa,pv,diff,mapv,cyc=run(v,pa,pv,1.40,dt,100.0,pc,br,1.2)
        c=int(round(T/dt))
        # run() returns max across all components; calculate separate component diffs
        # by obtaining last-cycle pair in a dedicated return below is represented by cyc.
        # cyc has only final cycle, so compute prior cycle with a second full-window state capture.
        # Instead rerun to the same checkpoint from the original initial condition with record buffer.
        # The component values are emitted from the checkpoint integrator below.
        rows.append([dt,sec,diff,mapv])
    with (OUT/"dt_cycle_diff_overall.csv").open("w",newline="") as f:
      w=csv.writer(f); w.writerow(["dt_s","time_s","Cycle_Diff_max_all_states","MAP_final_cycle"]); w.writerows(rows)
    # Component-resolved checkpoints and dt comparison: one continuous integration,
    # recording full trajectory so cycle n and n-1 are aligned by cardiac phase.
    comp=[]
    for dt in DT_LIST:
      v,pa,pv=initial(); c=int(round(T/dt)); nmax=int(round(1000/dt))
      hist=np.zeros((3,nmax+1)); hist[:,0]=[v,pa,pv]
      for k in range(nmax):
        t0=(k*dt)%T; th=((k+.5)*dt)%T; t1=((k+1)*dt)%T
        a1,b1,c1=deriv(v,pa,pv,t0,1.40,pc,br,1.2)
        a2,b2,c2=deriv(v+.5*dt*a1,pa+.5*dt*b1,pv+.5*dt*c1,th,1.40,pc,br,1.2)
        a3,b3,c3=deriv(v+.5*dt*a2,pa+.5*dt*b2,pv+.5*dt*c2,th,1.40,pc,br,1.2)
        a4,b4,c4=deriv(v+dt*a3,pa+dt*b3,pv+dt*c3,t1,1.40,pc,br,1.2)
        v+=dt*(a1+2*a2+2*a3+a4)/6; pa+=dt*(b1+2*b2+2*b3+b4)/6; pv+=dt*(c1+2*c2+2*c3+c4)/6
        hist[:,k+1]=[v,pa,pv]
      for sec in range(100,1001,100):
        end=int(round(sec/dt)); a=hist[:,end-c:end+1]; b=hist[:,end-2*c:end-c+1]
        vals=np.max(np.abs(a-b),axis=1)
        comp.append([dt,sec,*vals,float(np.max(vals))])
    with (OUT/"component_cycle_drift_100s.csv").open("w",newline="") as f:
      w=csv.writer(f); w.writerow(["dt_s","time_s","Cycle_Diff_VLV_mL","Cycle_Diff_Pa_mmHg","Cycle_Diff_Pv_mmHg","Cycle_Diff_max"]); w.writerows(comp)
    # Compare final-cycle trajectories across dt after interpolation to common phase grid.
    # All steps divide T exactly, so select every 4th/2nd point for common dt=0.001 phase grid.
    # Include fixed Rsys=1.40 and, only if coarse sweep indicates a split in the bracket,
    # midpoint of largest adjacent branch-separation interval as "inside-window" test.
    with (OUT/"dt_convergence_summary.csv").open("w",newline="") as f:
      w=csv.writer(f); w.writerow(["dt_s","MAP_1000s","VLV_min","VLV_max","Pa_min","Pa_max","Pv_min","Pv_max","max_cycle_diff"])
      for dt in DT_LIST:
        v,pa,pv=initial(); v,pa,pv,diff,m,cyc=run(v,pa,pv,1.40,dt,1000.,pc,br,1.2)
        w.writerow([dt,m,np.min(cyc[0]),np.max(cyc[0]),np.min(cyc[1]),np.max(cyc[1]),np.min(cyc[2]),np.max(cyc[2]),diff])
    summary={
      "model":"3-state [V_LV, Pa, Pv]; no P_mean state",
      "V_total_mL":1000.0,"alpha":ALPHA,"k_sig_mmHg":1.2,
      "calibration_grid":{"P_crit":[10,15,20,25,30,35,40,45,50],"beta_R":[20,25,30,35,40,45,50,55,60],"Rsys_sweep":[1.1,1.7,0.05],"seconds_per_sweep_point":20},
      "selected_coarse_candidate":{"P_crit":pc,"beta_R":br,"score":best[0],"mean_MAP_at_Rsys_1.30_1.40_1.50":best[3],"forward_reverse_MAP_splits":best[4]},
      "candidate_is_proven_bistable":False,
      "interpretation":"Coarse screening only; continuation split and normotensive MAP are necessary screening criteria, not proof of two stable attractors. Inspect saved sweep and component-cycle files.",
      "dt_values":DT_LIST
    }
    (OUT/"diagnostic_summary.json").write_text(json.dumps(summary,indent=2))
    print(json.dumps(summary,indent=2))
    print("Wrote",*[str(p) for p in sorted(OUT.iterdir())],sep="\n")

if __name__=="__main__": main()
