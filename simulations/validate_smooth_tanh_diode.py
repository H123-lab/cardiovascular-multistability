import csv,json,math
from pathlib import Path
import numpy as np
from numba import njit
OUT=Path("results/validation/smooth_tanh"); OUT.mkdir(parents=True,exist_ok=True)
T=.8; TSYS=.24; EMAX=2.; EMIN=.06; V0=10.; CA=1.5; CV=100.; RAV=.01; RMV=.008
VTOT=1000.; PCRIT=50.; BETA=45.; KSIG=1.2; ALPHA=.72; DT=.001; EPS=.05
TARGETS=(1.30,1.40,1.50)
@njit
def elast(t):
    return .5*(1-math.cos(math.pi*t/TSYS)) if t<=TSYS else 0.
@njit
def rhs(v,pa,pv,t,R):
    perf=ALPHA+(1-ALPHA)/(1+math.exp(-((pa-BETA*R)-PCRIT)/KSIG))
    plv=(EMIN+(EMAX*perf-EMIN)*elast(t))*(v-V0)
    dm=pv-plv; da=plv-pa
    gm=.5*(1+math.tanh(dm/EPS)); ga=.5*(1+math.tanh(da/EPS))
    qm=(dm/RMV)*gm; qa=(da/RAV)*ga; qs=(pa-pv)/R
    return qm-qa,(qa-qs)/CA,(qs-qm)/CV
@njit
def one_step(v,pa,pv,k,R):
    t0=(k*DT)%T; th=((k+.5)*DT)%T; t1=((k+1)*DT)%T
    a,b,c=rhs(v,pa,pv,t0,R)
    d,e,f=rhs(v+.5*DT*a,pa+.5*DT*b,pv+.5*DT*c,th,R)
    g,h,i=rhs(v+.5*DT*d,pa+.5*DT*e,pv+.5*DT*f,th,R)
    j,l,m=rhs(v+DT*g,pa+DT*h,pv+DT*i,t1,R)
    return (v+DT*(a+2*d+2*g+j)/6,pa+DT*(b+2*e+2*h+l)/6,pv+DT*(c+2*f+2*i+m)/6)
@njit
def short_run(v,pa,pv,R,seconds):
    c=int(round(T/DT)); n=int(round(seconds/DT)); hist=np.zeros((3,c+1)); idx=0
    for k in range(n):
        v,pa,pv=one_step(v,pa,pv,k,R)
        hist[0,idx]=v; hist[1,idx]=pa; hist[2,idx]=pv; idx=(idx+1)%(c+1)
    arr=np.zeros((3,c+1))
    for z in range(3):
        for q in range(c+1): arr[z,q]=hist[z,(idx+q)%(c+1)]
    mapv=0.
    for q in range(c): mapv+=.5*(arr[1,q]+arr[1,q+1])*DT/T
    return v,pa,pv,mapv
@njit
def long_run(v,pa,pv,R):
    c=int(round(T/DT)); n=int(round(600/DT)); ring=np.zeros((3,2*c+1)); idx=0
    diffs=np.zeros((2,3)); maps=np.zeros(2); cyc_out=np.zeros((3,c+1))
    checkpoints=(int(round(300/DT)),n)
    for k in range(n):
        v,pa,pv=one_step(v,pa,pv,k,R)
        ring[0,idx]=v; ring[1,idx]=pa; ring[2,idx]=pv; idx=(idx+1)%(2*c+1)
        if k+1==checkpoints[0] or k+1==checkpoints[1]:
            ci=0 if k+1==checkpoints[0] else 1
            arr=np.zeros((3,2*c+1))
            for z in range(3):
                for q in range(2*c+1): arr[z,q]=ring[z,(idx+q)%(2*c+1)]
            for z in range(3):
                mx=0.
                for q in range(c+1):
                    d=abs(arr[z,c+q]-arr[z,q])
                    if d>mx: mx=d
                diffs[ci,z]=mx
            for q in range(c+1):
                cyc_out[0,q]=arr[0,c+q]; cyc_out[1,q]=arr[1,c+q]; cyc_out[2,q]=arr[2,c+q]
            maps[ci]=0.
            for q in range(c): maps[ci]+=.5*(arr[1,c+q]+arr[1,c+q+1])*DT/T
    return v,pa,pv,diffs,maps,cyc_out
@njit
def do_sweep():
    rs=np.arange(1.10,1.70001,.025); n=len(rs)
    f=np.zeros((n,4)); r=np.zeros((n,4))
    v=120.; pa=95.; pv=(VTOT-v-CA*pa)/CV
    for i in range(n):
        v,pa,pv,m=short_run(v,pa,pv,rs[i],20.)
        f[i,:]=[m,v,pa,pv]
    v=120.; pa=95.; pv=(VTOT-v-CA*pa)/CV
    for i in range(n-1,-1,-1):
        v,pa,pv,m=short_run(v,pa,pv,rs[i],20.)
        r[i,:]=[m,v,pa,pv]
    return rs,f,r
def main():
    rs,f,r=do_sweep()
    with (OUT/"smooth_tanh_forward_reverse_sweep.csv").open("w",newline="") as fp:
        w=csv.writer(fp); w.writerow(["Rsys","MAP_forward_mmHg","MAP_reverse_mmHg","MAP_abs_split_mmHg"])
        for i,x in enumerate(rs): w.writerow([x,f[i,0],r[i,0],abs(f[i,0]-r[i,0])])
    rows=[]; sep_rows=[]
    for target in TARGETS:
        idx=int(np.argmin(np.abs(rs-target)))
        branches=[]
        for name,arr in (("forward",f),("reverse",r)):
            v,pa,pv=arr[idx,1],arr[idx,2],arr[idx,3]
            v,pa,pv,diffs,maps,cyc=long_run(v,pa,pv,target)
            branches.append((name,diffs,maps,cyc))
            for ci,sec in enumerate((300,600)):
                rows.append([target,name,sec,maps[ci],diffs[ci,0],diffs[ci,1],diffs[ci,2],max(diffs[ci,0],diffs[ci,1],diffs[ci,2])])
        A=branches[0][3]; B=branches[1][3]
        d=np.abs(A-B)
        sep_rows.append([target,abs(branches[0][2][1]-branches[1][2][1]),float(np.max(d[0])),float(np.max(d[1])),float(np.max(d[2]))])
    with (OUT/"smooth_tanh_cycle_convergence.csv").open("w",newline="") as fp:
        w=csv.writer(fp); w.writerow(["Rsys","branch_init","time_s","MAP_last_cycle_mmHg","Cycle_Diff_VLV_mL","Cycle_Diff_Pa_mmHg","Cycle_Diff_Pv_mmHg","Cycle_Diff_max"]); w.writerows(rows)
    with (OUT/"smooth_tanh_branch_separation.csv").open("w",newline="") as fp:
        w=csv.writer(fp); w.writerow(["Rsys","MAP_abs_split_after_600s_mmHg","Max_cycle_VLV_separation_mL","Max_cycle_Pa_separation_mmHg","Max_cycle_Pv_separation_mmHg"]); w.writerows(sep_rows)
    max300=max(x[7] for x in rows if x[2]==300); max600=max(x[7] for x in rows if x[2]==600)
    maxsep=max(x[1] for x in sep_rows)
    summary={"model":"3-state smooth tanh valve gate","gate":"0.5*(1+tanh(dp/0.05))","gate_pressure_scale_mmHg":EPS,"V_total_mL":VTOT,"P_crit_mmHg":PCRIT,"beta_R":BETA,"k_sig_mmHg":KSIG,"alpha":ALPHA,"dt_s":DT,"cycle_diff_threshold":1e-8,"max_cycle_diff_300s":max300,"max_cycle_diff_600s":max600,"max_MAP_branch_split_after_600s":maxsep,"all_periodicity_checks_pass":bool(max300<1e-8 and max600<1e-8),"hysteresis_at_all_three_Rsys_pass":bool(min(x[1] for x in sep_rows)>1.0),"candidate_pass":False,"interpretation":"A sweep split is not sufficient proof of stable coexistence. Review final-cycle separation and independent stability before any production merge."}
    (OUT/"summary.json").write_text(json.dumps(summary,indent=2))
    print(json.dumps(summary,indent=2))
    print("Wrote",*[str(p) for p in sorted(OUT.iterdir())],sep="\n")
if __name__=="__main__": main()
