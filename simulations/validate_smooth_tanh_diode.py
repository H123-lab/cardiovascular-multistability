import csv, json, math
from pathlib import Path
import numpy as np
from numba import njit

OUT=Path("results/smooth_tanh_validation")
OUT.mkdir(parents=True,exist_ok=True)
T=0.8; TSYS=0.3*T
EMAX=2.0; EMIN=0.06; V0=10.0
CA=1.5; CV=100.0; RAV=0.01; RMV=0.008
VTOT=1000.0; PCRIT=50.0; BETA=45.0; KSIG=1.2; ALPHA=0.72
EPS=0.05; DT=0.001
TARGETS=(1.30,1.40,1.50)
RGRID=np.round(np.arange(1.10,1.701,0.025),6)

@njit
def rhs(v,pa,pv,t,R):
    perf=ALPHA+(1.0-ALPHA)/(1.0+math.exp(-(pa-(BETA*R+PCRIT))/KSIG))
    phase=(0.5*(1.0-math.cos(math.pi*(t%T)/TSYS))) if (t%T)<=TSYS else 0.0
    plv=(EMIN+(EMAX*perf-EMIN)*phase)*(v-V0)
    dp_mv=pv-plv
    dp_av=plv-pa
    gate_mv=0.5*(1.0+math.tanh(dp_mv/EPS))
    gate_av=0.5*(1.0+math.tanh(dp_av/EPS))
    qmv=(dp_mv/RMV)*gate_mv
    qav=(dp_av/RAV)*gate_av
    qsys=(pa-pv)/R
    return qmv-qav,(qav-qsys)/CA,(qsys-qmv)/CV

@njit
def advance(v,pa,pv,t,R,dt):
    a1,b1,c1=rhs(v,pa,pv,t,R)
    a2,b2,c2=rhs(v+.5*dt*a1,pa+.5*dt*b1,pv+.5*dt*c1,t+.5*dt,R)
    a3,b3,c3=rhs(v+.5*dt*a2,pa+.5*dt*b2,pv+.5*dt*c2,t+.5*dt,R)
    a4,b4,c4=rhs(v+dt*a3,pa+dt*b3,pv+dt*c3,t+dt,R)
    return (v+dt*(a1+2*a2+2*a3+a4)/6,
            pa+dt*(b1+2*b2+2*b3+b4)/6,
            pv+dt*(c1+2*c2+2*c3+c4)/6)

@njit
def integrate(v,pa,pv,R,seconds,dt):
    n=int(round(seconds/dt)); c=int(round(T/dt)); ring=np.zeros((3,2*c+1)); idx=0
    for k in range(n):
        v,pa,pv=advance(v,pa,pv,k*dt,R,dt)
        ring[0,idx]=v; ring[1,idx]=pa; ring[2,idx]=pv
        idx=(idx+1)%(2*c+1)
    start=idx; arr=np.empty((3,2*c+1))
    for j in range(2*c+1):
        q=(start+j)%(2*c+1)
        for z in range(3): arr[z,j]=ring[z,q]
    prev=arr[:,:c+1]; last=arr[:,c:]
    diffs=np.zeros(3)
    for z in range(3):
        diffs[z]=np.max(np.abs(last[z,:]-prev[z,:]))
    mapv=(0.5*last[1,0]+np.sum(last[1,1:-1])+0.5*last[1,-1])*dt/T
    sep=0.0
    return v,pa,pv,diffs,mapv,last

@njit
def sweep():
    f=np.zeros((len(RGRID),3)); r=np.zeros((len(RGRID),3))
    vf=120.; paf=95.; pvf=(VTOT-vf-CA*paf)/CV
    for i in range(len(RGRID)):
        vf,paf,pvf,d,m,last=integrate(vf,paf,pvf,RGRID[i],300.,DT)
        f[i,:]=[m,vf,paf]
    vr,par,pvr=vf,paf,pvf
    for i in range(len(RGRID)-1,-1,-1):
        vr,par,pvr,d,m,last=integrate(vr,par,pvr,RGRID[i],300.,DT)
        r[i,:]=[m,vr,par]
    return f,r

def main():
    fw,rv=sweep()
    with (OUT/"smooth_tanh_sweep.csv").open("w",newline="") as f:
        w=csv.writer(f); w.writerow(["Rsys","MAP_forward","MAP_reverse","abs_MAP_difference"])
        for i,R in enumerate(RGRID): w.writerow([R,fw[i,0],rv[i,0],abs(fw[i,0]-rv[i,0])])
    rows=[]
    # branch-seeded states are re-integrated at the exact requested Rsys for 600 s.
    # Since sweep grid contains all targets exactly, the state after each continuation
    # point is not retained in the sweep arrays; reconstruct directional continuation.
    states_f={}; states_r={}
    vf=120.; paf=95.; pvf=(VTOT-vf-CA*paf)/CV
    for i,R in enumerate(RGRID):
        vf,paf,pvf,_,_,_=integrate(vf,paf,pvf,R,300.,DT)
        if any(abs(R-x)<1e-9 for x in TARGETS): states_f[float(R)]=(vf,paf,pvf)
    vr,par,pvr=vf,paf,pvf
    for i in range(len(RGRID)-1,-1,-1):
        R=RGRID[i]
        vr,par,pvr,_,_,_=integrate(vr,par,pvr,R,300.,DT)
        if any(abs(R-x)<1e-9 for x in TARGETS): states_r[float(R)]=(vr,par,pvr)
    for R in TARGETS:
        results=[]
        for label,state in [("forward",states_f[R]),("reverse",states_r[R])]:
            v,pa,pv=state
            # integrate in 300 s chunks to inspect both 300s and 600s
            v,pa,pv,d300,m300,cyc300=integrate(v,pa,pv,R,300.,DT)
            d300max=float(np.max(d300))
            v,pa,pv,d600,m600,cyc600=integrate(v,pa,pv,R,300.,DT)
            d600max=float(np.max(d600))
            results.append((label,m300,m600,d300,d600,cyc600))
            rows.append([R,label,m300,*d300,d300max,m600,*d600,d600max])
        sep=float(np.max(np.abs(results[0][5]-results[1][5])))
        rows[-2].append(sep); rows[-1].append(sep)
    with (OUT/"target_cycle_and_coexistence.csv").open("w",newline="") as f:
        w=csv.writer(f); w.writerow(["Rsys","branch_init","MAP_300s","CycleDiff_VLV_300","CycleDiff_Pa_300","CycleDiff_Pv_300","CycleDiff_max_300","MAP_600s","CycleDiff_VLV_600","CycleDiff_Pa_600","CycleDiff_Pv_600","CycleDiff_max_600","max_branch_trajectory_separation"]); w.writerows(rows)
    # Gate consistency spot checks over physiologically relevant pressure differences
    dps=[-1.,-0.1,-0.05,0.,0.05,0.1,1.]
    with (OUT/"tanh_gate_values.csv").open("w",newline="") as f:
        w=csv.writer(f); w.writerow(["dp_mmHg","gate"])
        for dp in dps: w.writerow([dp,.5*(1+math.tanh(dp/EPS))])
    summary={
      "model":"3-state smooth-tanh diode; [V_LV, Pa, Pv]",
      "parameters":{"V_total_mL":VTOT,"P_crit_mmHg":PCRIT,"beta_R":BETA,"k_sig_mmHg":KSIG,"alpha":ALPHA,"dt_s":DT,"valve_smoothing_scale_mmHg":EPS},
      "valve_law":"gate(dp)=0.5*(1+tanh(dp/0.05)); q=(dp/R)*gate(dp)",
      "sweep":{"Rsys_min":float(RGRID[0]),"Rsys_max":float(RGRID[-1]),"step":0.025,"seconds_per_point":300},
      "targets":list(TARGETS),
      "cycle_threshold":1e-8,
      "all_cycle_checks_pass":bool(all(max(row[6],row[11])<1e-8 for row in rows)),
      "hysteresis_at_all_targets":bool(all(abs(fw[int(round((R-RGRID[0])/.025)),0]-rv[int(round((R-RGRID[0])/.025)),0])>1.0 for R in TARGETS)),
      "branch_sweep_MAPs_at_targets":{str(R):{"forward":float(fw[int(round((R-RGRID[0])/.025)),0]),"reverse":float(rv[int(round((R-RGRID[0])/.025)),0])} for R in TARGETS},
      "caveat":"A forward/reverse sweep difference is path dependence, not by itself proof of two stable periodic orbits. The cycle checks and branch persistence results must be interpreted separately."
    }
    (OUT/"validation_summary.json").write_text(json.dumps(summary,indent=2))
    print(json.dumps(summary,indent=2))
if __name__=="__main__": main()
